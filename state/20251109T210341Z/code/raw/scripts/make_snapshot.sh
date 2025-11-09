#!/usr/bin/env bash
set -euo pipefail

UTC_TS="$(date -u +%Y%m%dT%H%M%SZ)"
SHORT_SHA="$(git rev-parse --short HEAD)"

SNAP_DIR="snapshots"
SNAP_FILE="${SNAP_DIR}/${UTC_TS}_${SHORT_SHA}.md"
mkdir -p "${SNAP_DIR}"

REPO_URL="$(git config --get remote.origin.url || echo 'unknown')"
BRANCH_NAME="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
GIT_USER="$(git config user.name || echo 'unknown')"
GIT_EMAIL="$(git config user.email || echo 'unknown')"

OS_INFO="$(uname -a || true)"
GIT_VER="$(git --version || true)"

FILE_LIST="$(git ls-files)"

checksums () {
  if command -v sha256sum >/dev/null 2>&1; then
    echo "${FILE_LIST}" | xargs -I{} sha256sum "{}" 2>/dev/null || true
  elif command -v shasum >/dev/null 2>&1; then
    echo "${FILE_LIST}" | xargs -I{} shasum -a 256 "{}" 2>/dev/null || true
  else
    echo "No sha256 tool found."
  fi
}

GIT_LOG="$(git log --graph --decorate=short --oneline -n 20 || true)"
SIZES="$(git ls-files -z | xargs -0 -I{} du -b {} 2>/dev/null | sort -nr | head -n 200 || true)"

cat > "${SNAP_FILE}" <<EOF
# Repo Snapshot — ${UTC_TS} (${SHORT_SHA})

- **Repo:** ${REPO_URL}
- **Branch:** ${BRANCH_NAME}
- **Commit:** ${SHORT_SHA}
- **Runner:** \`${OS_INFO}\`
- **Git:** \`${GIT_VER}\`
- **Actor:** \`${GIT_USER} <${GIT_EMAIL}>\`

---

## Files (tracked)
\`\`\`
${FILE_LIST}
\`\`\`

## Top ~200 largest files (bytes)
\`\`\`
${SIZES}
\`\`\`

## SHA256 checksums
\`\`\`
$(checksums)
\`\`\`

## Last 20 commits (graph)
\`\`\`
${GIT_LOG}
\`\`\`
EOF

echo "Snapshot generated at: ${SNAP_FILE}"
