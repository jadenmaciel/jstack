#!/usr/bin/env bash
# Drop into consumer repos as .cursor/install-cloud-home-skills.sh
# Requires dashboard secret CURSOR_CLOUD_HOME_TOKEN.
set -euo pipefail

if [[ -z "${CURSOR_CLOUD_HOME_TOKEN:-}" ]]; then
  echo "ERROR: CURSOR_CLOUD_HOME_TOKEN missing; Cloud skills install aborted" >&2
  exit 1
fi

REPO="${CURSOR_CLOUD_HOME_REPO:-jadenmaciel/cursor-cloud-home}"
# Until skills-pack-rebuild is on main, pin the feature branch.
BRANCH="${CURSOR_CLOUD_HOME_BRANCH:-skills-pack-rebuild}"
CLONE="${HOME}/.cursor/cloud-home"
AUTH="$(printf 'x-access-token:%s' "$CURSOR_CLOUD_HOME_TOKEN" | base64 | tr -d '\n')"

rm -rf "$CLONE"
mkdir -p "$(dirname "$CLONE")"
GIT_TERMINAL_PROMPT=0 git -c credential.helper= \
  -c "http.extraHeader=Authorization: Basic ${AUTH}" \
  clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$CLONE"

SKILLS_PACK_SRC="$CLONE" bash "$CLONE/install-on-cloud.sh"
