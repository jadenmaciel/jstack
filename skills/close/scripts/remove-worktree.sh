#!/usr/bin/env bash
# remove-worktree.sh <branch-slug>
#
# Remove the worktree for a just-closed ticket branch, if one exists and it
# is safe to remove. Mirrors start/scripts/resolve-worktree.sh's branch-to-
# worktree lookup so the two skills agree on what "the ticket's worktree" is.
#
# Never forces removal: a dirty tree, the caller's own cwd, or a missing
# worktree are all treated as safe no-ops (message on stderr, exit 0) so the
# close skill can call this unconditionally without special-casing failure.
#
# Exit non-zero only on real errors (bad args, not a git repo, git itself
# refusing the removal for a reason not already checked for above).

set -euo pipefail

slug="${1:-}"
if [[ -z "$slug" ]]; then
  echo "usage: remove-worktree.sh <branch-slug>" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "remove-worktree: not inside a git repo" >&2
  exit 2
fi

# Canonical caller cwd, captured before we cd away, so we can refuse to
# remove the worktree the caller is still standing in.
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

if [[ -z "$existing_path" ]]; then
  echo "remove-worktree: no worktree for branch '$slug'; nothing to do" >&2
  exit 0
fi

existing_canon=$(cd "$existing_path" 2>/dev/null && pwd -P || echo "$existing_path")
if [[ "$caller_cwd" == "$existing_canon" || "$caller_cwd" == "$existing_canon"/* ]]; then
  echo "remove-worktree: caller is still inside $existing_canon; cd out and rerun to remove it" >&2
  exit 0
fi

if [[ -n "$(git -C "$existing_path" status --porcelain 2>/dev/null)" ]]; then
  echo "remove-worktree: $existing_path has uncommitted changes; leaving it in place" >&2
  exit 0
fi

echo "remove-worktree: removing $existing_path" >&2
git worktree remove "$existing_path"
git worktree prune
echo "remove-worktree: removed $existing_path" >&2
