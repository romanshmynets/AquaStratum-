#!/usr/bin/env bash
set -euo pipefail

# Input:
#   $1 = path to schema.sql (dump from Supabase CLI)
#   $2 = OUT_DIR (e.g. state/<ts>_<sha>/db)
# Output:
#   TABLES.md/json, INDEXES.md/json, FK.md/json, VIEWS.md/json, FUNCTIONS.md/json

SCHEMA_SQL="${1:-}"
OUT_DIR="${2:-}"
if [ -z "${SCHEMA_SQL}" ] || [ -z "${OUT_DIR}" ] || [ ! -f "${SCHEMA_SQL}" ]; then
  echo "Usage: $0 <schema_sql_path> <out_dir>"
  exit 1
fi

mkdir -p "${OUT_DIR}"

TABLES_MD="${OUT_DIR}/TABLES.md"
TABLES_JSON="${OUT_DIR}/TABLES.json"
INDEXES_MD="${OUT_DIR}/INDEXES.md"
INDEXES_JSON="${OUT_DIR}/INDEXES.json"
FK_MD="${OUT_DIR}/FK.md"
FK_JSON="${OUT_DIR}/FK.json"
VIEWS_MD="${OUT_DIR}/VIEWS.md"
VIEWS_JSON="${OUT_DIR}/VIEWS.json"
FUN_MD="${OUT_DIR}/FUNCTIONS.md"
FUN_JSON="${OUT_DIR}/FUNCTIONS.json"

# --- TABLES + COLUMNS + PK ---
awk '
BEGIN{ IGNORECASE=1 }
/^[[:space:]]*CREATE[[:space:]]+TABLE[[:space:]]/ {
  in_table=1; cols=""; pk="";
  schema="public"; table=""; line=$0;
  if (match(line, /CREATE[[:space:]]+TABLE[[:space:]]+"?([A-Za-z0-9_]+)"?[.]"?([A-Za-z0-9_]+)"?[[:space:]]*\(/, m)) {
    schema=m[1]; table=m[2];
  } else if (match(line, /CREATE[[:space:]]+TABLE[[:space:]]+([A-Za-z0-9_]+)[.]+([A-Za-z0-9_]+)[[:space:]]*\(/, m2)) {
    schema=m2[1]; table=m2[2];
  }
  current=schema "." table; gsub(/"/,"",current);
  next
}
in_table && /^\)/ { in_table=0; if (table!="") tables[current]=cols "|" pk; next }
in_table {
  line=$0
  if (line ~ /PRIMARY[[:space:]]+KEY/) {
    if (match(line, /\(([^\)]+)\)/, m)) { pk=m[1]; gsub(/"/,"",pk); gsub(/[[:space:]]/,"",pk); }
    next
  }
  gsub(/^[[:space:]]+/,"",line); sub(/,[[:space:]]*$/,"",line);
  if (line ~ /^(CONSTRAINT|UNIQUE|CHECK|FOREIGN[[:space:]]+KEY)/i) next
  col=""
  if (match(line, /^"([^"]+)"/, c)) col=c[1]; else if (match(line, /^([A-Za-z0-9_]+)/, c2)) col=c2[1];
  if (col!="") { if (cols=="") cols=col; else cols=cols ", " col; }
}
END{
  print "# Tables" > "'"${TABLES_MD}"'"
  print "" >> "'"${TABLES_MD}"'"
  print "{" > "'"${TABLES_JSON}"'"
  first=1
  for (t in tables) {
    split(tables[t], parts, /\|/); columns=parts[1]; pk=parts[2];
    printf("## %s\n\n- columns: %s\n", t, columns) >> "'"${TABLES_MD}"'"
    if (pk!="") printf("- primary key: %s\n", pk) >> "'"${TABLES_MD}"'"
    printf("\n") >> "'"${TABLES_MD}"'"
    if (!first) printf(",\n") >> "'"${TABLES_JSON}"'"; first=0
    printf("  \"%s\": {\"columns\": [", t) >> "'"${TABLES_JSON}"'"
    n=split(columns, arr, /,[[:space:]]*/)
    for (i=1;i<=n;i++){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[i]); printf("%s\"%s\"", (i>1?",":""), arr[i]) >> "'"${TABLES_JSON}"'" }
    printf("]") >> "'"${TABLES_JSON}"'"
    if (pk!="") printf(", \"primary_key\": \"%s\"", pk) >> "'"${TABLES_JSON}"'"
    printf("}") >> "'"${TABLES_JSON}"'"
  }
  print "\n}" >> "'"${TABLES_JSON}"'"
}
' "${SCHEMA_SQL}"

# --- INDEXES ---
awk '
BEGIN{ IGNORECASE=1 }
/^[[:space:]]*CREATE[[:space:]]+INDEX[[:space:]]/ {
  name=""; target=""; cols="";
  line=$0
  if (match(line, /CREATE[[:space:]]+INDEX[[:space:]]+"?([A-Za-z0-9_]+)"?/, n)) name=n[1];
  if (match(line, /ON[[:space:]]+"?([A-Za-z0-9_]+)"?[.]"?([A-Za-z0-9_]+)"?[[:space:]]*\(([^\)]+)\)/, t)) {
    target=t[1] "." t[2]; cols=t[3];
    gsub(/"/,"",target); gsub(/[[:space:]]/,"",cols);
    idx[name]=target "|" cols;
  }
}
END{
  print "# Indexes" > "'"${INDEXES_MD}"'"
  print "" >> "'"${INDEXES_MD}"'"
  print "{" > "'"${INDEXES_JSON}"'"
  first=1
  for (k in idx) {
    split(idx[k], p, /\|/); target=p[1]; cols=p[2];
    printf("## %s\n\n- on: %s\n- columns: %s\n\n", k, target, cols) >> "'"${INDEXES_MD}"'"
    if (!first) printf(",\n") >> "'"${INDEXES_JSON}"'"; first=0
    printf("  \"%s\": {\"on\": \"%s\", \"columns\": [", k, target) >> "'"${INDEXES_JSON}"'"
    n=split(cols, a, /,[[:space:]]*/)
    for (i=1;i<=n;i++){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[i]); printf("%s\"%s\"", (i>1?",":""), a[i]) >> "'"${INDEXES_JSON}"'"}
    printf("]}") >> "'"${INDEXES_JSON}"'"
  }
  print "\n}" >> "'"${INDEXES_JSON}"'"
}
' "${SCHEMA_SQL}"

# --- FOREIGN KEYS ---
awk '
BEGIN{ IGNORECASE=1 }
/^[[:space:]]*ALTER[[:space:]]+TABLE[[:space:]]/ && /ADD[[:space:]]+CONSTRAINT/ && /FOREIGN[[:space:]]+KEY/ {
  src=""; cols=""; ref=""; rcols=""; line=$0
  if (match(line, /ALTER[[:space:]]+TABLE[[:space:]]+"?([A-Za-z0-9_]+)"?[.]"?([A-Za-z0-9_]+)"/, s)) {
    src=s[1] "." s[2]; gsub(/"/,"",src);
  }
  if (match(line, /FOREIGN[[:space:]]+KEY[[:space:]]*\(([^\)]+)\)/, c)) { cols=c[1]; gsub(/[[:space:]]/,"",cols) }
  if (match(line, /REFERENCES[[:space:]]+"?([A-Za-z0-9_]+)"?[.]"?([A-Za-z0-9_]+)"?[[:space:]]*\(([^\)]+)\)/, r)) {
    ref=r[1] "." r[2]; rcols=r[3]; gsub(/"/,"",ref); gsub(/[[:space:]]/,"",rcols)
  }
  if (src!="" && cols!="" && ref!="" && rcols!="") { fk[src "|" cols "|" ref "|" rcols]=1 }
}
END{
  print "# Foreign Keys" > "'"${FK_MD}"'"
  print "" >> "'"${FK_MD}"'"
  print "[" > "'"${FK_JSON}"'"
  first=1
  for (k in fk) {
    n=split(k, a, /\|/); s=a[1]; sc=a[2]; r=a[3]; rc=a[4];
    printf("- %s (%s) → %s (%s)\n\n", s, sc, r, rc) >> "'"${FK_MD}"'"
    if (!first) printf(",\n") >> "'"${FK_JSON}"'"; first=0
    printf("  {\"source\":\"%s\",\"source_cols\":[", s) >> "'"${FK_JSON}"'"
    ns=split(sc, sca, /,/); for (i=1;i<=ns;i++){ printf("%s\"%s\"", (i>1?",":""), sca[i]) >> "'"${FK_JSON}"'"}
    printf("],\"target\":\"%s\",\"target_cols\":[", r) >> "'"${FK_JSON}"'"
    nr=split(rc, rca, /,/); for (i=1;i<=nr;i++){ printf("%s\"%s\"", (i>1?",":""), rca[i]) >> "'"${FK_JSON}"'"}
    printf("]}") >> "'"${FK_JSON}"'"
  }
  print "\n]" >> "'"${FK_JSON}"'"
}
' "${SCHEMA_SQL}"

# --- VIEWS ---
awk '
BEGIN{ IGNORECASE=1 }
/^[[:space:]]*CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?VIEW[[:space:]]/ {
  schema="public"; view=""; line=$0
  if (match(line, /VIEW[[:space:]]+"?([A-Za-z0-9_]+)"?[.]"?([A-Za-z0-9_]+)"/, m)) { schema=m[1]; view=m[2] }
  else if (match(line, /VIEW[[:space:]]+([A-Za-z0-9_]+)[.]+([A-Za-z0-9_]+)/, m2)) { schema=m2[1]; view=m2[2] }
  current=schema "." view; gsub(/"/,"",current); views[current]=1
}
END{
  print "# Views" > "'"${VIEWS_MD}"'"
  print "" >> "'"${VIEWS_MD}"'"
  print "[" > "'"${VIEWS_JSON}"'"
  first=1
  for (v in views) {
    printf("- %s\n", v) >> "'"${VIEWS_MD}"'"
    if (!first) printf(",\n") >> "'"${VIEWS_JSON}"'"; first=0
    printf("  \"%s\"", v) >> "'"${VIEWS_JSON}"'"
  }
  print "\n]" >> "'"${VIEWS_JSON}"'"
}
' "${SCHEMA_SQL}"

# --- FUNCTIONS (signatures only) ---
awk '
BEGIN{ IGNORECASE=1 }
/^[[:space:]]*CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?FUNCTION[[:space:]]/ {
  sig=$0
  sub(/[[:space:]]+RETURNS.*/,"",sig)
  sub(/[[:space:]]+AS.*/,"",sig)
  gsub(/^[[:space:]]+/,"",sig)
  funcs[sig]=1
}
END{
  print "# Functions" > "'"${FUN_MD}"'"
  print "" >> "'"${FUN_MD}"'"
  print "[" > "'"${FUN_JSON}"'"
  first=1
  for (f in funcs) {
    printf("- %s\n", f) >> "'"${FUN_MD}"'"
    if (!first) printf(",\n") >> "'"${FUN_JSON}"'"; first=0
    printf("  \"%s\"", f) >> "'"${FUN_JSON}"'"
  }
  print "\n]" >> "'"${FUN_JSON}"'"
}
' "${SCHEMA_SQL}"

echo "Inventory generated under ${OUT_DIR}"
