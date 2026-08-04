#!/bin/bash

# Git Worktree Manager
# Handles creating, listing, switching, and cleaning up Git worktrees
# KISS principle: Simple, interactive, opinionated

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the MAIN repo root (the source of the local agent docs). Resolve via the
# common git dir so this stays correct even when invoked from inside a linked
# worktree -- the parent of the common .git dir is always the primary worktree.
# (--show-toplevel would return the current worktree, breaking the docs source
# and current-dir sync resolution.)
GIT_ROOT=$(cd "$(dirname "$(git rev-parse --git-common-dir)")" && pwd)
WORKTREE_DIR="$GIT_ROOT/.worktrees"

# Every worktree under .worktrees, at any nesting depth.
#
# git already tracks these, so ask it instead of globbing. "$WORKTREE_DIR"/*
# only reaches one level down, so a slashed branch name like docs/COM-29-x
# lands two levels deep and the glob yields the bare namespace dir
# (.worktrees/docs), which has no .git and gets skipped. That made both list
# and cleanup silently blind: cleanup printed "No inactive worktrees" while
# every real worktree went unexamined.
#
# Paths are compared through `pwd -P` because git records physical paths while
# $PWD stays logical -- on macOS /var vs /private/var alone breaks a string
# compare. Emit git's own path, which is what `git worktree remove` expects.
worktree_paths() {
  local base path real
  base=$(cd "$WORKTREE_DIR" 2>/dev/null && pwd -P) || return 0
  while IFS= read -r path; do
    real=$(cd "$path" 2>/dev/null && pwd -P) || continue
    case "$real" in
      "$base"/*) printf '%s\n' "$path" ;;
    esac
  done < <(git worktree list --porcelain | sed -n 's/^worktree //p')
}

# Display name for a worktree: its path relative to .worktrees, so nested
# worktrees read as "docs/COM-29-x" -- the same string `create` and `switch`
# take. basename alone would print "COM-29-x", which switch cannot resolve.
worktree_label() {
  local real base
  real=$(cd "$1" 2>/dev/null && pwd -P) || { basename "$1"; return; }
  base=$(cd "$WORKTREE_DIR" 2>/dev/null && pwd -P) || { basename "$1"; return; }
  printf '%s\n' "${real#"$base"/}"
}

# True when $PWD is inside the given worktree. Both sides resolved; see the
# path note on worktree_paths.
is_current_worktree() {
  local real
  real=$(cd "$1" 2>/dev/null && pwd -P) || return 1
  local here
  here=$(pwd -P)
  [[ "$here" == "$real" || "$here" == "$real"/* ]]
}

# Ensure private worktree/agent artifacts are ignored without touching tracked .gitignore.
ensure_local_exclude() {
  local exclude_file
  exclude_file="$(git rev-parse --git-common-dir)/info/exclude"
  mkdir -p "$(dirname "$exclude_file")"

  local patterns=(
    "/.worktrees/"
    "/.claude/"
    "/.code-review-graph/"
    "/.omx/"
    "/.env"
    "/.env.*"
    "/AGENTS.md"
    "/CLAUDE.md"
    "/DEV_ENVIRONMENT.local.md"
    "/company-docs/"
    # graphify output: the tool's default, plus the hidden form used by repos
    # that set GRAPHIFY_OUT.
    "/graphify-out/"
    "/.graphify-out/"
    # teach workspace. Inside a git repo the teach skill always writes here,
    # so the old root-level MISSION.md/NOTES.md/lessons/... are not listed.
    "/docs/teach/"
    "/lib/config.inc.php"
  )

  local added=0
  for pattern in "${patterns[@]}"; do
    if ! grep -qxF "$pattern" "$exclude_file" 2>/dev/null; then
      if [[ "$added" -eq 0 ]]; then
        printf '\n# epayment local-only agent/dev files\n' >> "$exclude_file"
      fi
      printf '%s\n' "$pattern" >> "$exclude_file"
      added=1
    fi
  done
}

# Copy .env files from main repo to worktree
copy_env_files() {
  local worktree_path="$1"

  echo -e "${BLUE}Copying environment files...${NC}"

  # Find all .env* files in root (excluding .env.example which should be in git)
  local env_files=()
  for f in "$GIT_ROOT"/.env*; do
    if [[ -f "$f" ]]; then
      local basename=$(basename "$f")
      # Skip .env.example (that's typically committed to git)
      if [[ "$basename" != ".env.example" ]]; then
        env_files+=("$basename")
      fi
    fi
  done

  if [[ ${#env_files[@]} -eq 0 ]]; then
    echo -e "  ${YELLOW}ℹ️  No .env files found in main repository${NC}"
    return
  fi

  local copied=0
  for env_file in "${env_files[@]}"; do
    local source="$GIT_ROOT/$env_file"
    local dest="$worktree_path/$env_file"

    if [[ -f "$dest" ]]; then
      echo -e "  ${YELLOW}⚠️  $env_file already exists, backing up to ${env_file}.backup${NC}"
      cp "$dest" "${dest}.backup"
    fi

    cp "$source" "$dest"
    echo -e "  ${GREEN}✓ Copied $env_file${NC}"
    copied=$((copied + 1))
  done

  echo -e "  ${GREEN}✓ Copied $copied environment file(s)${NC}"
}

# Copy safe local agent context into a worktree. Secrets-bearing Claude local
# settings (settings.local.json) are intentionally not copied. Pass mode
# "docs-only" to also skip DEV_ENVIRONMENT.local.md (the plaintext SFTP
# credentials) -- used by syncs that run automatically on every session start.
copy_agent_files() {
  local worktree_path="$1"
  local mode="${2:-full}"

  echo -e "${BLUE}Copying agent context files...${NC}"

  local agent_items=(
    "AGENTS.md"
    "CLAUDE.md"
    "DEV_ENVIRONMENT.local.md"
    "company-docs"
    # The teach workspace (docs/teach/) is deliberately not copied: personal
    # learning notes are not agent context worth duplicating per worktree.
    ".claude/settings.json"
    ".claude/hooks/epayment-guardrails.sh"
  )

  local copied=0
  for item in "${agent_items[@]}"; do
    # docs-only syncs must not propagate the plaintext SFTP credential file.
    # The only recursively-copied item is company-docs/ (redacted wiki digest);
    # docs-only relies on it holding no secrets, and /company-docs/ + /.env* in
    # the worktree's git exclude keep any stray file from ever being pushed.
    if [[ "$mode" == "docs-only" && "$item" == "DEV_ENVIRONMENT.local.md" ]]; then
      continue
    fi
    local source="$GIT_ROOT/$item"
    local dest="$worktree_path/$item"

    if [[ ! -e "$source" ]]; then
      continue
    fi

    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" && "${EPAYMENT_AGENT_SYNC_OVERWRITE:-0}" != "1" ]]; then
      echo -e "  ${YELLOW}ℹ️  $item already exists, leaving it in place${NC}"
      continue
    fi

    if [[ -d "$source" ]]; then
      if [[ -d "$dest" ]]; then
        cp -R "$source"/. "$dest"
      else
        cp -R "$source" "$dest"
      fi
    else
      cp "$source" "$dest"
    fi
    echo -e "  ${GREEN}✓ Copied $item${NC}"
    copied=$((copied + 1))
  done

  if [[ $copied -eq 0 ]]; then
    echo -e "  ${YELLOW}ℹ️  No new agent context files copied${NC}"
  else
    echo -e "  ${GREEN}✓ Copied $copied agent context item(s)${NC}"
  fi
}

# Resolve the repository default branch, falling back to main when origin/HEAD
# is unavailable (for example in single-branch clones).
get_default_branch() {
  local head_ref
  head_ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)

  if [[ -n "$head_ref" ]]; then
    echo "${head_ref#refs/remotes/origin/}"
  else
    echo "main"
  fi
}

# Auto-trust is only safe when the worktree is created from a long-lived branch
# the developer already controls. Review/PR branches should fall back to the
# default branch baseline and require manual direnv approval.
is_trusted_base_branch() {
  local branch="$1"
  local default_branch="$2"

  [[ "$branch" == "$default_branch" ]] && return 0

  case "$branch" in
    develop|dev|trunk|staging|release/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Trust development tool configs in a new worktree.
# Worktrees get a new filesystem path that tools like mise and direnv
# have never seen. Without trusting, these tools block with interactive
# prompts or refuse to load configs, which breaks hooks and scripts.
#
# Safety: auto-trusts only configs unchanged from a trusted baseline branch.
# Review/PR branches fall back to the default-branch baseline, and direnv
# auto-allow is limited to trusted base branches because .envrc can source
# additional files that direnv does not validate.
#
# TOCTOU between hash-check and trust is acceptable for local dev use.
trust_dev_tools() {
  local worktree_path="$1"
  local base_ref="$2"
  local allow_direnv_auto="$3"
  local trusted=0
  local skipped_messages=()
  local manual_commands=()

  # mise: trust the specific config file if present and unchanged
  if command -v mise &>/dev/null; then
    for f in .mise.toml mise.toml .tool-versions; do
      if [[ -f "$worktree_path/$f" ]]; then
        if _config_unchanged "$f" "$base_ref" "$worktree_path"; then
          if (cd "$worktree_path" && mise trust "$f" --quiet); then
            trusted=$((trusted + 1))
          else
            echo -e "  ${YELLOW}Warning: 'mise trust $f' failed -- run manually in $worktree_path${NC}"
          fi
        else
          skipped_messages+=("mise trust $f (config differs from $base_ref)")
          manual_commands+=("mise trust $f")
        fi
        break
      fi
    done
  fi

  # direnv: allow .envrc
  if command -v direnv &>/dev/null; then
    if [[ -f "$worktree_path/.envrc" ]]; then
      if [[ "$allow_direnv_auto" != "true" ]]; then
        skipped_messages+=("direnv allow (.envrc auto-allow is disabled for non-trusted base branches)")
        manual_commands+=("direnv allow")
      elif _config_unchanged ".envrc" "$base_ref" "$worktree_path"; then
        if (cd "$worktree_path" && direnv allow); then
          trusted=$((trusted + 1))
        else
          echo -e "  ${YELLOW}Warning: 'direnv allow' failed -- run manually in $worktree_path${NC}"
        fi
      else
        skipped_messages+=("direnv allow (.envrc differs from $base_ref)")
        manual_commands+=("direnv allow")
      fi
    fi
  fi

  if [[ $trusted -gt 0 ]]; then
    echo -e "  ${GREEN}✓ Trusted $trusted dev tool config(s)${NC}"
  fi

  if [[ ${#skipped_messages[@]} -gt 0 ]]; then
    echo -e "  ${YELLOW}Skipped auto-trust for config(s) requiring manual review:${NC}"
    for item in "${skipped_messages[@]}"; do
      echo -e "    - $item"
    done
    if [[ ${#manual_commands[@]} -gt 0 ]]; then
      local joined
      joined=$(printf ' && %s' "${manual_commands[@]}")
      echo -e "  ${BLUE}Review the diff, then run manually: cd $worktree_path${joined}${NC}"
    fi
  fi
}

# Check if a config file is unchanged from the base branch.
# Returns 0 (true) if the file is identical to the base branch version.
# Returns 1 (false) if the file was added or modified by this branch.
#
# Note: rev-parse returns the stored blob hash; hash-object on a path applies
# gitattributes filters. A mismatch causes a false negative (trust skipped),
# which is the safe direction.
_config_unchanged() {
  local file="$1"
  local base_ref="$2"
  local worktree_path="$3"

  # Reject symlinks -- trust only regular files with verifiable content
  [[ -L "$worktree_path/$file" ]] && return 1

  # Get the blob hash directly from git's object database via rev-parse
  local base_hash
  base_hash=$(git rev-parse "$base_ref:$file" 2>/dev/null) || return 1

  local worktree_hash
  worktree_hash=$(git hash-object "$worktree_path/$file") || return 1

  [[ "$base_hash" == "$worktree_hash" ]]
}

# Create a new worktree
create_worktree() {
  local branch_name="$1"
  local from_branch="${2:-$(get_default_branch)}"

  if [[ -z "$branch_name" ]]; then
    echo -e "${RED}Error: Branch name required${NC}"
    exit 1
  fi

  local worktree_path="$WORKTREE_DIR/$branch_name"

  # Check if worktree already exists
  if [[ -d "$worktree_path" ]]; then
    echo -e "${YELLOW}Worktree already exists at: $worktree_path${NC}"
    echo -e "Switch to it instead? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
      switch_worktree "$branch_name"
    fi
    return
  fi

  echo -e "${BLUE}Creating worktree: $branch_name${NC}"
  echo "  From: $from_branch"
  echo "  Path: $worktree_path"

  # Fetch the base branch without changing the current checkout.
  echo -e "${BLUE}Updating $from_branch...${NC}"
  if ! git fetch origin "$from_branch" --quiet; then
    echo -e "  ${YELLOW}Warning: could not fetch origin/$from_branch -- using a verified local ref if available${NC}"
  fi

  local start_ref
  if git rev-parse --verify "origin/$from_branch" &>/dev/null; then
    start_ref="origin/$from_branch"
  elif git rev-parse --verify "$from_branch" &>/dev/null; then
    start_ref="$from_branch"
  else
    echo -e "${RED}Error: Base branch not found: $from_branch${NC}"
    exit 1
  fi

  # Create worktree
  mkdir -p "$WORKTREE_DIR"
  ensure_local_exclude

  echo -e "${BLUE}Creating worktree...${NC}"
  git worktree add -b "$branch_name" "$worktree_path" "$start_ref"

  # Copy environment files
  copy_env_files "$worktree_path"
  copy_agent_files "$worktree_path"

  # Trust dev tool configs (mise, direnv) so hooks and scripts work immediately.
  # Long-lived integration branches can use themselves as the trust baseline,
  # while review/PR branches fall back to the default branch and require manual
  # direnv approval.
  local default_branch
  default_branch=$(get_default_branch)
  local trust_branch="$default_branch"
  local allow_direnv_auto="false"
  if is_trusted_base_branch "$from_branch" "$default_branch"; then
    trust_branch="$from_branch"
    allow_direnv_auto="true"
  fi

  if ! git fetch origin "$trust_branch" --quiet; then
    echo -e "  ${YELLOW}Warning: could not fetch origin/$trust_branch -- trust check may use stale data${NC}"
  fi
  # Skip trust entirely if the baseline ref doesn't exist locally.
  if git rev-parse --verify "origin/$trust_branch" &>/dev/null; then
    trust_dev_tools "$worktree_path" "origin/$trust_branch" "$allow_direnv_auto"
  else
    echo -e "  ${YELLOW}Skipping dev tool trust -- origin/$trust_branch not found locally${NC}"
  fi

  echo -e "${GREEN}✓ Worktree created successfully!${NC}"
  echo ""
  echo "To switch to this worktree:"
  echo -e "${BLUE}cd $worktree_path${NC}"
  echo ""
}

# List all worktrees
list_worktrees() {
  echo -e "${BLUE}Available worktrees:${NC}"
  echo ""

  if [[ ! -d "$WORKTREE_DIR" ]]; then
    echo -e "${YELLOW}No worktrees found${NC}"
    return
  fi

  local count=0
  local worktree_path name branch
  while IFS= read -r worktree_path; do
    count=$((count + 1))
    name=$(worktree_label "$worktree_path")
    branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    if is_current_worktree "$worktree_path"; then
      echo -e "${GREEN}✓ $name${NC} (current) → branch: $branch"
    else
      echo -e "  $name → branch: $branch"
    fi
  done < <(worktree_paths)

  if [[ $count -eq 0 ]]; then
    echo -e "${YELLOW}No worktrees found${NC}"
  else
    echo ""
    echo -e "${BLUE}Total: $count worktree(s)${NC}"
  fi

  echo ""
  echo -e "${BLUE}Main repository:${NC}"
  # -C $GIT_ROOT, not cwd: run from inside a worktree this reported that
  # worktree's branch as the main repo's, which is actively misleading when
  # the primary checkout is parked on something else.
  local main_branch=$(git -C "$GIT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  echo "  Branch: $main_branch"
  echo "  Path: $GIT_ROOT"
}

# Switch to a worktree
switch_worktree() {
  local worktree_name="$1"

  if [[ -z "$worktree_name" ]]; then
    list_worktrees
    echo -e "${BLUE}Switch to which worktree? (enter name)${NC}"
    read -r worktree_name
  fi

  local worktree_path="$WORKTREE_DIR/$worktree_name"

  if [[ ! -d "$worktree_path" ]]; then
    echo -e "${RED}Error: Worktree not found: $worktree_name${NC}"
    echo ""
    list_worktrees
    exit 1
  fi

  echo -e "${GREEN}Switching to worktree: $worktree_name${NC}"
  cd "$worktree_path"
  echo -e "${BLUE}Now in: $(pwd)${NC}"
}

# Copy env files to an existing worktree (or current directory if in a worktree)
copy_env_to_worktree() {
  local worktree_name="$1"
  local worktree_path

  if [[ -z "$worktree_name" ]]; then
    # Check if we're currently in a worktree
    local current_dir=$(pwd)
    if [[ "$current_dir" == "$WORKTREE_DIR"/* ]]; then
      worktree_path="$current_dir"
      worktree_name=$(basename "$worktree_path")
      echo -e "${BLUE}Detected current worktree: $worktree_name${NC}"
    else
      echo -e "${YELLOW}Usage: worktree-manager.sh copy-env [worktree-name]${NC}"
      echo "Or run from within a worktree to copy to current directory"
      list_worktrees
      return 1
    fi
  else
    worktree_path="$WORKTREE_DIR/$worktree_name"

    if [[ ! -d "$worktree_path" ]]; then
      echo -e "${RED}Error: Worktree not found: $worktree_name${NC}"
      list_worktrees
      return 1
    fi
  fi

  copy_env_files "$worktree_path"
  copy_agent_files "$worktree_path"
  echo ""
}

# Sync agent context docs (AGENTS.md, CLAUDE.md, company-docs, etc.) into a
# worktree without copying .env files or the DEV_ENVIRONMENT.local.md SFTP
# credentials (docs-only mode). Idempotent -- safe to run on an already-synced
# worktree, and safe to run on every session start.
sync_agent_docs() {
  local target="$1"
  local worktree_path

  if [[ -z "$target" ]]; then
    # Check if we're currently in a worktree
    local current_dir=$(pwd)
    if [[ "$current_dir" == "$WORKTREE_DIR"/* ]]; then
      worktree_path="$current_dir"
    else
      echo -e "${YELLOW}Usage: worktree-manager.sh sync-agent-docs [worktree-name|path]${NC}"
      echo "Or run from within a worktree to sync to current directory"
      return 1
    fi
  elif [[ "$target" == /* && -d "$target" ]]; then
    worktree_path="$target"
  else
    worktree_path="$WORKTREE_DIR/$target"
  fi

  if [[ ! -d "$worktree_path" ]]; then
    echo -e "${RED}Error: Worktree not found: $worktree_path${NC}"
    return 1
  fi

  ensure_local_exclude
  copy_agent_files "$worktree_path" docs-only
}

# Clean up completed worktrees
cleanup_worktrees() {
  if [[ ! -d "$WORKTREE_DIR" ]]; then
    echo -e "${YELLOW}No worktrees to clean up${NC}"
    return
  fi

  echo -e "${BLUE}Checking for completed worktrees...${NC}"
  echo ""

  local found=0
  local to_remove=()
  # Prints the live session PID and returns 0 when <worktree>/.cc-session.lock
  # names a process that is alive AND whose recorded cwd is inside this
  # worktree. PID alive with cwd elsewhere = PID reuse or a moved session ->
  # stale, removal allowed (warned).
  live_session_pid() {
    local wt="$1" git_dir lock pid cwd
    git_dir=$(git -C "$wt" rev-parse --git-dir 2>/dev/null) || return 1
    [[ "$git_dir" != /* ]] && git_dir="$wt/$git_dir"
    lock="$git_dir/.cc-session.lock"
    [[ -f "$lock" ]] || return 1
    IFS='|' read -r pid _ _ cwd < "$lock" || true # no trailing newline is fine
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    # Resolve both sides: the lock records whatever $PWD the session had
    # (logical), git reports physical, and on macOS /var vs /private/var alone
    # makes a live session look stale -- which would remove it out from under
    # itself. A cwd that no longer resolves is genuinely gone, so it stays a
    # non-match.
    local wt_real cwd_real
    wt_real=$(cd "$wt" 2>/dev/null && pwd -P) || wt_real="$wt"
    cwd_real=$(cd "$cwd" 2>/dev/null && pwd -P) || cwd_real="$cwd"
    case "$cwd_real" in
      "$wt_real"|"$wt_real"/*) printf '%s' "$pid"; return 0 ;;
    esac
    echo -e "${YELLOW}(stale/moved lock on $(basename "$wt"): pid $pid alive but cwd $cwd)${NC}" >&2
    return 1
  }

  local worktree_path worktree_name live_pid
  while IFS= read -r worktree_path; do
    worktree_name=$(worktree_label "$worktree_path")

    # Skip if current worktree (or a subdir of it)
    if is_current_worktree "$worktree_path"; then
      echo -e "${YELLOW}(skip) $worktree_name - currently active${NC}"
      continue
    fi

    # Skip if a live Claude Code session still sits in this worktree.
    # session-worktree-lock.sh writes <pid>|<ts>|<session>|<cwd> to the
    # worktree git dir on every SessionStart; removing the directory under
    # a live session breaks every hook in it with posix_spawn ENOENT walls.
    if live_pid=$(live_session_pid "$worktree_path"); then
      echo -e "${YELLOW}(skip) $worktree_name - live Claude session pid $live_pid${NC}"
      continue
    fi

    # Data-loss net: uncommitted/untracked changes need a human decision,
    # not --force. (A lock only proves a live session, not a clean tree.)
    if [[ -n "$(git -C "$worktree_path" status --porcelain 2>/dev/null)" ]]; then
      echo -e "${YELLOW}(skip) $worktree_name - uncommitted changes (remove manually if intended)${NC}"
      continue
    fi

    found=$((found + 1))
    to_remove+=("$worktree_path")
    echo -e "${YELLOW}• $worktree_name${NC}"
  done < <(worktree_paths)

  if [[ $found -eq 0 ]]; then
    echo -e "${GREEN}No inactive worktrees to clean up${NC}"
    return
  fi

  echo ""
  echo -e "Remove $found worktree(s)? (y/n)"
  read -r response

  if [[ "$response" != "y" ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    return
  fi

  echo -e "${BLUE}Cleaning up worktrees...${NC}"
  for worktree_path in "${to_remove[@]}"; do
    worktree_name=$(worktree_label "$worktree_path")
    # Re-check the lock at removal time: a session can start while the user
    # sits on the y/n prompt (TOCTOU).
    local late_pid
    if late_pid=$(live_session_pid "$worktree_path"); then
      echo -e "${YELLOW}(skip) $worktree_name - live Claude session pid $late_pid appeared${NC}"
      continue
    fi
    if git worktree remove "$worktree_path" --force 2>/dev/null; then
      echo -e "${GREEN}✓ Removed: $worktree_name${NC}"
    else
      echo -e "${RED}✗ Failed to remove: $worktree_name${NC}"
    fi
  done

  # `git worktree remove` deletes the leaf but leaves the namespace dirs a
  # slashed branch name created (.worktrees/docs/ after docs/COM-29-x goes).
  # Prune those, innermost first, then the root if it ends up empty.
  find "$WORKTREE_DIR" -mindepth 1 -depth -type d -empty -exec rmdir {} + 2>/dev/null || true
  if [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
    rmdir "$WORKTREE_DIR" 2>/dev/null || true
  fi

  echo -e "${GREEN}Cleanup complete!${NC}"
}

# Main command handler
main() {
  local command="${1:-list}"

  case "$command" in
    create)
      create_worktree "$2" "$3"
      ;;
    list|ls)
      list_worktrees
      ;;
    switch|go)
      switch_worktree "$2"
      ;;
    copy-env|env)
      copy_env_to_worktree "$2"
      ;;
    sync-agent-docs|sync-docs)
      sync_agent_docs "$2"
      ;;
    cleanup|clean)
      cleanup_worktrees
      ;;
    selftest|--selftest)
      run_selftest
      ;;
    help)
      show_help
      ;;
    *)
      echo -e "${RED}Unknown command: $command${NC}"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

show_help() {
  cat << EOF
Git Worktree Manager

Usage: worktree-manager.sh <command> [options]

Commands:
  create <branch-name> [from-branch]  Create new worktree (copies .env files automatically)
                                      (from-branch defaults to main)
  list | ls                           List all worktrees
  switch | go [name]                  Switch to worktree
  copy-env | env [name]               Copy .env files from main repo to worktree
                                      (if name omitted, uses current worktree)
  sync-agent-docs | sync-docs [name|path]  Sync agent docs into a worktree (no .env copy)
  cleanup | clean                     Clean up inactive worktrees
                                      (skips live-session-locked and dirty worktrees)
  selftest                            Non-interactive cleanup-safety scenario test
  help                                Show this help message

Environment Files:
  - Automatically copies .env, .env.local, .env.test, etc. on create
  - Skips .env.example (should be in git)
  - Creates .backup files if destination already exists
  - Use 'copy-env' to refresh env files after main repo changes

Dev Tool Trust:
  - Trusts mise config (.mise.toml, mise.toml, .tool-versions) and direnv (.envrc)
  - Uses trusted base branches directly (main, develop, dev, trunk, staging, release/*)
  - Other branches fall back to the default branch as the trust baseline
  - direnv auto-allow is skipped on non-trusted base branches; review manually first
  - Modified configs are flagged for manual review
  - Only runs if the tool is installed and config exists
  - Prevents hooks/scripts from hanging on interactive trust prompts

Examples:
  worktree-manager.sh create feature-login
  worktree-manager.sh create feature-auth develop
  worktree-manager.sh switch feature-login
  worktree-manager.sh copy-env feature-login
  worktree-manager.sh copy-env                   # copies to current worktree
  worktree-manager.sh cleanup
  worktree-manager.sh list

EOF
}

# Non-interactive scenario test for the cleanup safety rails:
# live-session lock -> kept, dirty tree -> kept, dead/moved lock -> removed.
run_selftest() {
  local tmp repo upstream create_base_ok=0 create_local_ok=0 create_primary_ok=0 pass=0 fail=0
  tmp=$(mktemp -d) || exit 1
  repo="$tmp/repo"
  mkdir -p "$repo" && cd "$repo"
  git init -q --initial-branch=main
  printf 'base\n' > tracked.txt
  git add tracked.txt
  git -c user.email=t@t -c user.name=t commit -q -m init
  git init -q --bare "$tmp/origin.git"
  git remote add origin "$tmp/origin.git"
  git push -q -u origin main
  upstream="$tmp/upstream"
  git clone -q "$tmp/origin.git" "$upstream"
  printf 'remote\n' > "$upstream/tracked.txt"
  git -C "$upstream" -c user.email=t@t -c user.name=t add tracked.txt
  git -C "$upstream" -c user.email=t@t -c user.name=t commit -q -m remote
  git -C "$upstream" push -q
  printf 'dirty\n' > tracked.txt
  echo y | bash "$0" create wt-create main >/dev/null 2>&1 || true
  if [[ -d "$repo/.worktrees/wt-create" ]] \
    && [[ "$(git -C "$repo/.worktrees/wt-create" rev-parse HEAD)" == "$(git -C "$repo" rev-parse origin/main)" ]] \
    && [[ "$(git -C "$repo" rev-parse HEAD)" != "$(git -C "$repo" rev-parse origin/main)" ]]; then
    create_base_ok=1
  fi
  if [[ "$(git -C "$repo" branch --show-current)" == "main" && "$(<tracked.txt)" == "dirty" ]]; then
    create_primary_ok=1
  fi
  git branch local-only
  echo y | bash "$0" create wt-local local-only >/dev/null 2>&1 || true
  if [[ -d "$repo/.worktrees/wt-local" ]] \
    && [[ "$(git -C "$repo/.worktrees/wt-local" rev-parse HEAD)" == "$(git -C "$repo" rev-parse local-only)" ]]; then
    create_local_ok=1
  fi
  git worktree add -q .worktrees/wt-live -b wt-live
  git worktree add -q .worktrees/wt-dead -b wt-dead
  git worktree add -q .worktrees/wt-moved -b wt-moved
  git worktree add -q .worktrees/wt-dirty -b wt-dirty
  printf '%s|ts|sid|%s\n' "$$" "$repo/.worktrees/wt-live" > .git/worktrees/wt-live/.cc-session.lock
  printf '99999|ts|sid|%s\n' "$repo/.worktrees/wt-dead" > .git/worktrees/wt-dead/.cc-session.lock
  printf '%s|ts|sid|/nowhere/else\n' "$$" > .git/worktrees/wt-moved/.cc-session.lock
  echo dirty > .worktrees/wt-dirty/uncommitted.txt
  # Slashed branch name -> worktree two levels down. This is the shape the old
  # single-level glob could not see at all.
  git worktree add -q .worktrees/feat/nested -b feat/nested
  local list_out nested_listed=0 nested_labelled=0
  list_out=$(bash "$0" list 2>/dev/null || true)
  grep -q 'feat/nested' <<< "$list_out" && nested_listed=1
  # The label must be the path under .worktrees, not basename: `switch` takes
  # this string back, and "nested" alone does not resolve. Assert the label
  # positively -- "basename absent" also holds when nothing was listed at all.
  grep -q 'feat/nested →' <<< "$list_out" && nested_labelled=1
  echo y | bash "$0" cleanup >/dev/null 2>&1 || true
  check() { # check <desc> <want-exists 1|0> <path>
    local desc="$1" want="$2" p="$3" got=0
    [[ -d "$p" ]] && got=1
    if [[ "$got" == "$want" ]]; then
      pass=$((pass+1)); echo "ok: $desc"
    else
      fail=$((fail+1)); echo "FAIL: $desc"
    fi
  }
  check 'live-locked worktree kept'    1 "$repo/.worktrees/wt-live"
  check 'dirty worktree kept'          1 "$repo/.worktrees/wt-dirty"
  check 'dead-locked worktree removed' 0 "$repo/.worktrees/wt-dead"
  check 'moved-lock worktree removed'  0 "$repo/.worktrees/wt-moved"
  check 'nested worktree removed'      0 "$repo/.worktrees/feat/nested"
  check 'empty namespace dir pruned'   0 "$repo/.worktrees/feat"
  if [[ "$nested_listed" == 1 ]]; then
    pass=$((pass+1)); echo 'ok: list finds a nested worktree'
  else
    fail=$((fail+1)); echo 'FAIL: list finds a nested worktree'
  fi
  if [[ "$nested_labelled" == 1 ]]; then
    pass=$((pass+1)); echo 'ok: nested worktree labelled by path, not basename'
  else
    fail=$((fail+1)); echo 'FAIL: nested worktree labelled by path, not basename'
  fi
  if [[ "$create_base_ok" == 1 ]]; then
    pass=$((pass+1)); echo 'ok: create uses fetched origin base without updating primary'
  else
    fail=$((fail+1)); echo 'FAIL: create uses fetched origin base without updating primary'
  fi
  if [[ "$create_local_ok" == 1 ]]; then
    pass=$((pass+1)); echo 'ok: create falls back to a verified local base'
  else
    fail=$((fail+1)); echo 'FAIL: create falls back to a verified local base'
  fi
  if [[ "$create_primary_ok" == 1 ]]; then
    pass=$((pass+1)); echo 'ok: create leaves dirty primary checkout unchanged'
  else
    fail=$((fail+1)); echo 'FAIL: create leaves dirty primary checkout unchanged'
  fi
  cd / && rm -rf "$tmp"
  echo "selftest: $pass passed, $fail failed"
  exit $(( fail ? 1 : 0 ))
}

# Run
main "$@"
