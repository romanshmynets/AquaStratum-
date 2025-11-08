#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/inventory_db.sh <schema_sql_path> <out_dir>
# Example:
#   scripts/inventory_db.sh state/20250101T000000Z_abc123/db/schema.sql state/20250101T000000Z_abc123/db

SCHEMA_SQL="${1:-}"
OUT_DIR="${2:-}"

if [ -z "${SCHEMA_SQL}" ] || [ -z "${OUT_DIR}" ]; then
  echo "Usage: $0 <schema_sql_path> <out_dir>"
  exit 1
fi

mkdir -p "${OUT_DIR}"

TABLES_MD="${OUT_DIR}/TABLES.md"
TABLES_JSON="${OUT_DIR}/TABLES.json"

# Parse CREATE TABLE statements from schema dump (covers quoted/unquoted names)
# Produces schema.table and column list (first-level only)
awk '
BEGIN{
  IGNORECASE=1
}
# capture CREATE TABLE lines like:
# CREATE TABLE public.users (
# CREATE TABLE "app"."users" (
/^[[:space:]]*CREATE[[:space:]]+TABLE[[:space:]]/ {
  in_table=1
  cols=""
  schema="public"; table=""
  line=$0
  # try to capture schema and table with quotes
  if (match(line, /CREATE[[:space:]]+TABLE[[:space:]]+"?([A-Za-z0-9_]+)"?[.]"?([A-Za-z0-9_]+)"?[[:space:]]*\(/, m)) {
    schema=m[1]; table=m[2]
  } else if (match(line, /CREATE[[:space:]]+TABLE[[:space:]]+([A-Za-z0-9_]+)[.]+([A-Za-z0-9_]+)[[:space:]]*\(/, m2)) {
    schema=m2[1]; table=m2[2]
  }
  if (table=="") next
  current=schema "." table
  gsub(/"/, "", current)
  tables[current]=""
  next
}
in_table && /^\)/ {
  in_table=0
  next
}
in_table {
  # collect column names before first space or quoted
  col=$0
  gsub(/^[[:space:]]+/, "", col)
  if (col ~ /^--/ || col ~ /^CONSTRAINT/ || col ~ /^PRIMARY KEY/ || col ~ /^UNIQUE/ || col ~ /^CHECK/ || col ~ /^FOREIGN KEY/ ) next
  # strip trailing comma
  sub(/,[[:space:]]*$/, "", col)
  # column name in quotes or plain
  if (match(col, /^"([^"]+)"/, c)) {
    colname=c[1]
  } else if (match(col, /^([A-Za-z0-9_]+)/, c2)) {
    colname=c2[1]
  } else {
    next
  }
  if (current!="") {
    if (tables[current]=="") tables[current]=colname; else tables[current]=tables[current] ", " colname
  }
}
END{
  # Markdown
  print "# Tables inventory" > "'"${TABLES_MD}"'"
  print "" >> "'"${TABLES_MD}"'"
  # JSON
  print "{" > "'"${TABLES_JSON}"'"
  first=1
  for (t in tables) {
    # markdown row
    printf("## %s\n\n- columns: %s\n\n", t, tables[t]) >> "'"${TABLES_MD}"'"
    # json item
    if (!first) { printf(",\n") >> "'"${TABLES_JSON}"'" } else { first=0 }
    printf("  \"%s\": [", t) >> "'"${TABLES_JSON}"'"
    # split columns by comma into JSON array
    n=split(tables[t], arr, /,[[:space:]]*/)
    for (i=1;i<=n;i++){
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", arr[i])
      printf("%s\"%s\"", (i>1?",":""), arr[i]) >> "'"${TABLES_JSON}"'"
    }
    printf("]") >> "'"${TABLES_JSON}"'"
  }
  print "\n}" >> "'"${TABLES_JSON}"'"
}
' "${SCHEMA_SQL}"

echo "Inventory written to:"
echo " - ${TABLES_MD}"
echo " - ${TABLES_JSON}"
