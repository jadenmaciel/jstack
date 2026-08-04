#!/usr/bin/env bash
# resolve-worktree.sh <branch-slug>
#
# Find-or-create a worktree for the given branch slug, then print its absolute
# path on stdout. All chatter goes to stderr so the path can be captured.
#
# Behavior:
#   1. If a worktree on <branch-slug> already exists -> print its path.
#   2. Else if the branch exists locally -> attach a new worktree to it.
#   3. Else -> delegate to worktree-manager.sh to create a fresh one off the
#      repo's default branch (origin/HEAD, e.g. main or develop -- never
#      hardcoded).
#
# Exit non-zero on any failure (caller should NOT proceed with intake).
#
# Supported worktree path layouts
# -------------------------------
# Reuse (step 1): path-agnostic. We query `git worktree list --porcelain` and
#   match purely on the branch ref, so any layout that git itself knows about
#   is honored -- including legacy siblings like
#       /Users/testadmin/Projects/Purely-pur-172
#   and the canonical
#       /Users/testadmin/Projects/Purely/.worktrees/<slug>
#
# Create (steps 2 & 3): always produces the canonical path
#   "$main_repo/.worktrees/<slug>". Legacy sibling paths are tolerated when
#   discovered, but we never generate new ones -- worktree-manager.sh owns
#   creation and writes only to .worktrees/. Migrating an existing legacy
#   worktree is a manual operation (`git worktree move`) and intentionally
#   left out of this script to avoid disrupting parallel Claude sessions that
#   may currently have the legacy path checked out.

set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "usage: resolve-worktree.sh <branch-slug>" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "resolve-worktree: not inside a git repo" >&2
  exit 2
fi

# Canonical caller cwd, captured before we cd away, so we can detect the
# idempotent "already inside the target worktree" case below.
caller_cwd=$(pwd -P)

# Always operate from the main repo, not from a linked worktree.
common_dir=$(git rev-parse --git-common-dir)
main_repo=$(cd "$(dirname "$common_dir")" && pwd)
cd "$main_repo"

existing_path=$(git worktree list --porcelain \
  | awk -v slug="$slug" '
      /^worktree / { wt = substr($0, 10) }
      /^branch refs\/heads\// {
        b = substr($0, 19)
        if (b == slug) { print wt; exit }
      }')

if [[ -n "$existing_path" ]]; then
  # Idempotent no-op: the caller is already inside the worktree this slug
  # resolves to. Print the path and exit without syncing docs or mutating git.
  existing_canon=$(cd "$existing_path" 2>/dev/null && pwd -P || echo "$existing_path")
  if [[ "$caller_cwd" == "$existing_canon" || "$caller_cwd" == "$existing_canon"/* ]]; then
    echo "resolve-worktree: already inside target worktree ($existing_canon); no-op" >&2
    echo "$existing_path"
    exit 0
  fi

  echo "resolve-worktree: reusing existing worktree at $existing_path" >&2
  bash "$HOME/.claude/skills/git-worktree/scripts/worktree-manager.sh" sync-agent-docs "$existing_path" >&2 \
    || echo "resolve-worktree: warning: agent-doc sync failed for $existing_path (non-fatal, continuing)" >&2
  echo "$existing_path"
  exit 0
fi

target="$main_repo/.worktrees/$slug"

if git show-ref --verify --quiet "refs/heads/$slug"; then
  echo "resolve-worktree: branch '$slug' exists; attaching worktree at $target" >&2
  mkdir -p "$(dirname "$target")"
  git worktree add "$target" "$slug" >&2
  bash "$HOME/.claude/skills/git-worktree/scripts/worktree-manager.sh" sync-agent-docs "$target" >&2 \
    || echo "resolve-worktree: warning: agent-doc sync failed for $target (non-fatal, continuing)" >&2
  echo "$target"
  exit 0
fi

echo "resolve-worktree: creating fresh worktree off the repo's default branch at $target" >&2
bash "$HOME/.claude/skills/git-worktree/scripts/worktree-manager.sh" create "$slug" >&2
# worktree-manager creates at "$main_repo/.worktrees/$slug"; verify and print.
if [[ -d "$target" ]]; then
  echo "$target"
else
  echo "resolve-worktree: expected worktree at $target but it is missing" >&2
  exit 1
fi
