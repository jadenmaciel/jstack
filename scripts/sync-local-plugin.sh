#!/usr/bin/env bash
# Sync this checkout into ~/.cursor/plugins/local/jstack (real copy; no symlink).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${HOME}/.cursor/plugins/local/jstack"
mkdir -p "$DEST"
# Drop a leftover symlink from older installs.
if [[ -L "$DEST" ]]; then
  rm -f "$DEST"
  mkdir -p "$DEST"
fi
rsync -a --delete \
  --exclude '.git/' \
  --exclude 'graphify-out/' \
  --exclude '.DS_Store' \
  "${ROOT}/" "${DEST}/"
echo "synced -> ${DEST} ($(find "${DEST}/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ') skills)"
