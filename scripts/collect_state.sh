#!/usr/bin/env bash
set -euo pipefail

UTC_TS="$(date -u +%Y%m%dT%H%M%SZ)"
SHORT_SHA="$(git rev-parse --short HEAD)"
OUT_DIR="state/${UTC_TS}_${SHORT_SHA}"
mkdir -p "${OUT_DIR}"

REPO_URL="$(git config --get remote.origin.url || echo 'unknown')"
BRANCH_NAME="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"

mkdir -p "${OUT_DIR}/files"
git ls-files > "${OUT_DIR}/files/tracked.txt" || true
{ command -v tree >/dev/null && tree -a -I ".git" -n; } > "${OUT_DIR}/files/tree.txt" 2>/dev/null || \
  { find . -not -path "*/\.git/*" -print | sed 's|^\./||' > "${OUT_DIR}/files/tree.txt"; }

cat > "${OUT_DIR}/STATE.md" <<EOF
# Project State — ${UTC_TS} (${SHORT_SHA})
- Repo: ${REPO_URL}
- Branch: ${BRANCH_NAME}
- Commit: ${SHORT_SHA}

Collected: files, deps, env templates, docker, DB, API, indexes, checksums.
EOF

mkdir -p "${OUT_DIR}/deps"
if [ -f package.json ]; then
  { npm ls --depth=1 || true; } > "${OUT_DIR}/deps/npm-ls.txt"
  [ -f package-lock.json ] && cp package-lock.json "${OUT_DIR}/deps/" || true
  [ -f pnpm-lock.yaml ] && cp pnpm-lock.yaml "${OUT_DIR}/deps/" || true
  [ -f yarn.lock ] && cp yarn.lock "${OUT_DIR}/deps/" || true
fi
if [ -f requirements.txt ] || ls **/*.py >/dev/null 2>&1; then
  python3 -V > "${OUT_DIR}/deps/python-version.txt" 2>/dev/null || true
  { python3 -m pip freeze || true; } > "${OUT_DIR}/deps/pip-freeze.txt"
  [ -f requirements.txt ] && cp requirements.txt "${OUT_DIR}/deps/" || true
fi
if [ -f go.mod ]; then
  go version > "${OUT_DIR}/deps/go-version.txt" 2>/dev/null || true
  { go list -m all || true; } > "${OUT_DIR}/deps/go-mod-list.txt"
  cp go.mod "${OUT_DIR}/deps/" || true
  [ -f go.sum ] && cp go.sum "${OUT_DIR}/deps/" || true
fi

mkdir -p "${OUT_DIR}/docker"
[ -f Dockerfile ] && cp Dockerfile "${OUT_DIR}/docker/" || true
[ -f docker-compose.yml ] && cp docker-compose.yml "${OUT_DIR}/docker/" || true
[ -f compose.yaml ] && cp compose.yaml "${OUT_DIR}/docker/" || true

mkdir -p "${OUT_DIR}/env"
[ -f .env.example ] && cp .env.example "${OUT_DIR}/env/" || true
grep -RhoE '[A-Z0-9_]{3,}=(.+)?' -- . 2>/dev/null | cut -d= -f1 | sort -u | \
  awk '{print $0"="}' > "${OUT_DIR}/env/guessed.env.example" || true

mkdir -p "${OUT_DIR}/db"
if [ -n "${DATABASE_URL:-}" ]; then
  { psql "$DATABASE_URL" -c "\dt+" -c "\dn+" -c "\df+" -c "\dv+" -c "\dD+" || true; } > "${OUT_DIR}/db/psql-introspect.txt"
  { pg_dump --schema-only "$DATABASE_URL" || true; } > "${OUT_DIR}/db/schema.sql"
fi
[ -f schema.sql ] && cp schema.sql "${OUT_DIR}/db/" || true
[ -f seed.sql ] && cp seed.sql "${OUT_DIR}/db/" || true

mkdir -p "${OUT_DIR}/api"
[ -f openapi.yaml ] && cp openapi.yaml "${OUT_DIR}/api/" || true
[ -f openapi.yml ] && cp openapi.yml "${OUT_DIR}/api/" || true
[ -f openapi.json ] && cp openapi.json "${OUT_DIR}/api/" || true

mkdir -p "${OUT_DIR}/index"
if command -v ctags >/dev/null 2>&1; then
  ctags -R -f "${OUT_DIR}/index/tags" .
fi
if command -v rg >/dev/null 2>&1; then
  rg --files > "${OUT_DIR}/index/rg-files.txt" || true
fi

if command -v sha256sum >/dev/null 2>&1; then
  git ls-files | xargs -I{} sha256sum "{}" > "${OUT_DIR}/checksums.sha256" || true
elif command -v shasum >/dev/null 2>&1; then
  git ls-files | xargs -I{} shasum -a 256 "{}" > "${OUT_DIR}/checksums.sha256" || true
fi

echo "STATE collected at: ${OUT_DIR}"
