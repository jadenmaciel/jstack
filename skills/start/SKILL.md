---
name: start
description: Inspect one external ticket and existing work before implementation.
---

# Start

External-ticket intake only. Read `~/.cursor/skills/references/sprintflow-core.md` and `next-skill-router.md`.

## Inputs

- One ticket ID or issue URL.
- Repository path when it cannot be inferred safely.

## Unique actions

1. Normalize the ticket ID. From the current cwd, run `~/.cursor/bin/sprintflow-scope.mjs assert-normal --repo <repository-path> --ticket <normalized-ticket-id> --branch <active-branch>`. On any nonzero result, stop and recommend `$epayment-start` only for confirmed epayment; otherwise report ambiguity.
2. Inspect the current branch, dirty state, `git worktree list`, commits relative to the expected base, and any PR for the current branch. If this worktree clearly belongs to another ticket, leave it untouched: never clean, reset, stash, delete, run `git switch`, or modify it.
3. For an unrelated ticket worktree, resolve the repository's configured default branch; do not assume `main` (`develop` is valid). Locate that branch's existing worktree with `git worktree list`, and require its branch to match and `git -C <path> status --porcelain` to be empty. Then `cd <path>` and confirm the top level and active branch. Stop if no matching clean worktree exists; do not create or clean one during intake. Rerun step 1 with this active path and branch, and run every later command from this path.
4. Reuse matching work already in progress. Do not create a duplicate branch, worktree, commit, or PR. Also scan recent cross-agent sessions for overlapping completed work — `tail -50 ~/.codex/session_index.jsonl` titles and `ls -t ~/.claude/projects/<project-dir>/ | head`; if overlap is suspected, verify PR/commit state before redoing anything. Read-only: if the repo has `openspec/`, detect `openspec/changes/<ticket-id>*` (or an obvious matching change folder); note any change ID, proposal/design presence, and path in the Start Brief. Do not create or edit OpenSpec artifacts here.
5. Read exactly one ticket from its configured tracker and extract goal, acceptance criteria, constraints, likely touchpoints, risks, and first proof.
6. Create a ticket branch or workspace only when the user has selected implementation as the immediate next action. Otherwise stay read-only.
7. If a workspace is needed (implementation was selected and the current path is a git repo), create or reuse the ticket's worktree and `cd` into it: run `bash ~/.cursor/skills/start/scripts/resolve-worktree.sh <branch-slug>`, capture its stdout path, `cd` into it, and confirm with `git rev-parse --show-toplevel`; run every later command from that path. Skip this entirely when no implementation was selected or the path is not a git repo. The resolver safely reuses the current matching worktree and no-ops if already inside it.
8. Do not transition or comment on the ticket. Do not run research, planning, implementation, or another skill.

## Completion criteria

- Existing work is identified, or its absence is proven.
- The ticket and repository match.
- The active worktree path is reported, or the reason none was created is stated.
- Emit `Summary`, `Evidence`, a compact `Start Brief`, optional `Findings`, and one `Next`.

## Next route

Use `next-skill-router.md`. Spec-worthy default: `/opsx:explore` (then `/grill-with-docs` → `/opsx:propose` → `/opsx:apply`). Skip explore when the touch area is already clear; skip grill when decisions/ADRs are already locked; if both skip and the ticket meets a spec criterion, Next is `/opsx:propose`. Small scope: `/implement`. Unsure: `/ask-matt`. Hard bug: `/diagnosing-bugs`. Stop. `$to-spec` is retired.
