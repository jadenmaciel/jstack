#!/usr/bin/env bash
# Shared Cloud skills install for cursor-cloud-home.
# Syncs pack skills into $HOME/.cursor/skills/cursor-cloud-home/ (idempotent).
# Env:
#   SKILLS_PACK_SRC  — if set, use this dir as the pack root (skip git)
#   CURSOR_CLOUD_HOME_TOKEN — required when SKILLS_PACK_SRC unset
#   CURSOR_CLOUD_HOME_REPO — default jadenmaciel/cursor-cloud-home
#   CURSOR_CLOUD_HOME_BRANCH — default main (use skills-pack-rebuild until merged)
set -euo pipefail

PACK_SUBTREE="${HOME}/.cursor/skills/cursor-cloud-home"
REPO="${CURSOR_CLOUD_HOME_REPO:-jadenmaciel/cursor-cloud-home}"
BRANCH="${CURSOR_CLOUD_HOME_BRANCH:-main}"
CLONE_DIR="${HOME}/.cursor/cloud-home"

install_from_src() {
  local src="$1"
  local skills_src="${src}/skills"
  if [[ ! -d "$skills_src" ]]; then
    echo "ERROR: missing ${skills_src}" >&2
    return 1
  fi
  mkdir -p "$(dirname "$PACK_SUBTREE")"
  rm -rf "$PACK_SUBTREE"
  mkdir -p "$PACK_SUBTREE"
  cp -a "${skills_src}/." "$PACK_SUBTREE/"
  echo "cloud-home skills: $(find "$PACK_SUBTREE" -name SKILL.md | wc -l | tr -d ' ') -> ${PACK_SUBTREE}"
}

clone_pack() {
  if [[ -z "${CURSOR_CLOUD_HOME_TOKEN:-}" ]]; then
    echo "ERROR: CURSOR_CLOUD_HOME_TOKEN missing; Cloud skills install aborted" >&2
    return 1
  fi
  rm -rf "$CLONE_DIR"
  mkdir -p "$(dirname "$CLONE_DIR")"
  local auth
  auth="$(printf 'x-access-token:%s' "$CURSOR_CLOUD_HOME_TOKEN" | base64 | tr -d '\n')"
  GIT_TERMINAL_PROMPT=0 git -c credential.helper= \
    -c "http.extraHeader=Authorization: Basic ${auth}" \
    clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$CLONE_DIR"
  install_from_src "$CLONE_DIR"
}

if [[ -n "${SKILLS_PACK_SRC:-}" ]]; then
  install_from_src "$SKILLS_PACK_SRC"
else
  clone_pack
fi
