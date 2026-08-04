#!/usr/bin/env bash
# ponytail: Mac SSOT stays ~/.cursor/skills; cloud clones this private mirror
set -euo pipefail
DEST="${HOME}/.cursor/skills"
SRC_DIR="${HOME}/.cursor/cloud-home"
rm -rf "$SRC_DIR"
if [ -n "${CURSOR_CLOUD_HOME_TOKEN:-}" ]; then
  git clone --depth 1 "https://x-access-token:${CURSOR_CLOUD_HOME_TOKEN}@github.com/jadenmaciel/cursor-cloud-home.git" "$SRC_DIR"
else
  git clone --depth 1 "https://github.com/jadenmaciel/cursor-cloud-home.git" "$SRC_DIR" \
    || git clone --depth 1 "git@github.com:jadenmaciel/cursor-cloud-home.git" "$SRC_DIR"
fi
mkdir -p "$DEST"
rsync -a --delete "$SRC_DIR/skills/" "$DEST/"
echo "cloud-home: $(find "$DEST" -name SKILL.md | wc -l | tr -d ' ') skills -> $DEST"
