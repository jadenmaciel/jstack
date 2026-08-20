#!/usr/bin/env bash
# Drop into consumer repos as .cursor/install-jstack-skills.sh
# Public jstack clones without a token. Optional personal overlay uses CURSOR_CLOUD_HOME_TOKEN.
set -euo pipefail

# Prefer running from a checkout of jstack when available (start/install already cloned),
# otherwise clone public core then run pack installer (which also handles personal overlay).
if [[ -f "${HOME}/.cursor/jstack-src/install-on-cloud.sh" ]] && [[ "${JSTACK_REUSE_CLONE:-}" == "1" ]]; then
  SKILLS_PACK_SRC="${HOME}/.cursor/jstack-src" bash "${HOME}/.cursor/jstack-src/install-on-cloud.sh"
  exit 0
fi

REPO="${CURSOR_CLOUD_HOME_REPO:-jadenmaciel/jstack}"
BRANCH="${CURSOR_CLOUD_HOME_BRANCH:-main}"
CLONE="${HOME}/.cursor/jstack-src"

rm -rf "$CLONE"
mkdir -p "$(dirname "$CLONE")"
GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$CLONE"

SKILLS_PACK_SRC="$CLONE" bash "$CLONE/install-on-cloud.sh"
