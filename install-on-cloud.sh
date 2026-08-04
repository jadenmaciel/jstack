#!/usr/bin/env bash
# ponytail: Mac SSOT stays ~/.cursor/skills; cloud clones this private mirror
set -euo pipefail
DEST="${HOME}/.cursor/skills"
SRC_DIR="${HOME}/.cursor/cloud-home"
rm -rf "$SRC_DIR"

clone_https_token() {
  git clone --depth 1 "https://x-access-token:${CURSOR_CLOUD_HOME_TOKEN}@github.com/jadenmaciel/cursor-cloud-home.git" "$SRC_DIR"
}

clone_deploy_key() {
  local keyfile
  keyfile="$(mktemp)"
  printf '%s\n' "$CURSOR_CLOUD_HOME_DEPLOY_KEY" >"$keyfile"
  chmod 600 "$keyfile"
  GIT_SSH_COMMAND="ssh -i $keyfile -o StrictHostKeyChecking=accept-new" \
    git clone --depth 1 "git@github.com:jadenmaciel/cursor-cloud-home.git" "$SRC_DIR"
  rm -f "$keyfile"
}

if [ -n "${CURSOR_CLOUD_HOME_DEPLOY_KEY:-}" ]; then
  clone_deploy_key
elif [ -n "${CURSOR_CLOUD_HOME_TOKEN:-}" ]; then
  clone_https_token
else
  git clone --depth 1 "https://github.com/jadenmaciel/cursor-cloud-home.git" "$SRC_DIR"
fi

mkdir -p "$DEST"
rsync -a --delete "$SRC_DIR/skills/" "$DEST/"
echo "cloud-home: $(find "$DEST" -name SKILL.md | wc -l | tr -d ' ') skills -> $DEST"
