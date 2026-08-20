#!/usr/bin/env bash
# Shared Cloud skills install for jstack (public core) + optional jstack-personal.
# Lands:
#   $HOME/.cursor/skills/jstack/
#   $HOME/.cursor/skills/jstack-personal/  (if CURSOR_CLOUD_HOME_TOKEN set)
#
# Env:
#   SKILLS_PACK_SRC — fixture: use this dir as public pack root (skip git for core)
#   SKILLS_PERSONAL_SRC — fixture: use this dir as personal overlay (skip git for overlay)
#   CURSOR_CLOUD_HOME_TOKEN — optional; required only to clone private jstack-personal
#   CURSOR_CLOUD_HOME_REPO — default jadenmaciel/jstack (public core)
#   JSTACK_PERSONAL_REPO — default jadenmaciel/jstack-personal
#   CURSOR_CLOUD_HOME_BRANCH / JSTACK_PERSONAL_BRANCH — default main
set -euo pipefail

CORE_SUBTREE="${HOME}/.cursor/skills/jstack"
PERSONAL_SUBTREE="${HOME}/.cursor/skills/jstack-personal"
CORE_REPO="${CURSOR_CLOUD_HOME_REPO:-jadenmaciel/jstack}"
PERSONAL_REPO="${JSTACK_PERSONAL_REPO:-jadenmaciel/jstack-personal}"
CORE_BRANCH="${CURSOR_CLOUD_HOME_BRANCH:-main}"
PERSONAL_BRANCH="${JSTACK_PERSONAL_BRANCH:-main}"
CORE_CLONE="${HOME}/.cursor/jstack-src"
PERSONAL_CLONE="${HOME}/.cursor/jstack-personal-src"

install_skills_tree() {
  local src="$1"
  local dest="$2"
  local label="$3"
  local skills_src="${src}/skills"
  if [[ ! -d "$skills_src" ]]; then
    echo "ERROR: missing ${skills_src}" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -a "${skills_src}/." "$dest/"
  # Drop legacy subtree name from older installs
  rm -rf "${HOME}/.cursor/skills/cursor-cloud-home"
  echo "${label} skills: $(find "$dest" -name SKILL.md | wc -l | tr -d ' ') -> ${dest}"
}

clone_repo() {
  local repo="$1"
  local branch="$2"
  local dest="$3"
  local with_token="$4"
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  if [[ "$with_token" == "1" ]]; then
    if [[ -z "${CURSOR_CLOUD_HOME_TOKEN:-}" ]]; then
      echo "ERROR: CURSOR_CLOUD_HOME_TOKEN missing for private clone ${repo}" >&2
      return 1
    fi
    local auth
    auth="$(printf 'x-access-token:%s' "$CURSOR_CLOUD_HOME_TOKEN" | base64 | tr -d '\n')"
    GIT_TERMINAL_PROMPT=0 git -c credential.helper= \
      -c "http.extraHeader=Authorization: Basic ${auth}" \
      clone --depth 1 --branch "$branch" "https://github.com/${repo}.git" "$dest"
  else
    GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "$branch" "https://github.com/${repo}.git" "$dest"
  fi
}

# --- public core ---
if [[ -n "${SKILLS_PACK_SRC:-}" ]]; then
  install_skills_tree "$SKILLS_PACK_SRC" "$CORE_SUBTREE" "jstack"
else
  clone_repo "$CORE_REPO" "$CORE_BRANCH" "$CORE_CLONE" "0"
  install_skills_tree "$CORE_CLONE" "$CORE_SUBTREE" "jstack"
fi

# --- private overlay (optional) ---
if [[ -n "${SKILLS_PERSONAL_SRC:-}" ]]; then
  install_skills_tree "$SKILLS_PERSONAL_SRC" "$PERSONAL_SUBTREE" "jstack-personal"
elif [[ -n "${CURSOR_CLOUD_HOME_TOKEN:-}" ]]; then
  if clone_repo "$PERSONAL_REPO" "$PERSONAL_BRANCH" "$PERSONAL_CLONE" "1"; then
    install_skills_tree "$PERSONAL_CLONE" "$PERSONAL_SUBTREE" "jstack-personal"
  else
    echo "WARN: jstack-personal clone failed; continuing with public core only" >&2
  fi
else
  echo "WARN: CURSOR_CLOUD_HOME_TOKEN unset; skipping jstack-personal overlay" >&2
  rm -rf "$PERSONAL_SUBTREE"
fi
