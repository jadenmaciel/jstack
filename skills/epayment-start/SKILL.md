---
name: epayment-start
description: Inspect one TROUT ticket and existing epayment work.
---

# Epayment Start

TROUT intake only. Load `~/.codex/skills/references/epayment-sprintflow.md`, the shared core, and the router.

## Inputs

- One `TROUT-*` ticket.
- The epayment repository path when not already there.

## Unique actions

1. Run `~/.codex/bin/sprintflow-scope.mjs assert-epayment --allow-unready true` with the TROUT ticket, repository, and current branch; stop on any nonzero result.
2. Confirm `ExpiTrans/epayment` and the `develop` base.
3. Before planning, inspect branch, dirty state, commits, remotes, and current-branch PR. Reuse matching work; do not create duplicates. Also scan recent cross-agent sessions for overlapping completed work — `tail -50 ~/.codex/session_index.jsonl` titles and `ls -t ~/.claude/projects/<project-dir>/ | head`; if overlap is suspected, verify PR/commit state before redoing anything.
4. Read the one TROUT ticket and authorized project context. Extract goal, acceptance criteria, tenant/data risks, likely files, proof path, and open decisions.
5. In the main checkout only, create or switch to a non-`develop` TROUT ticket branch based on `develop` when implementation is the immediate user-selected next action. Never create, enter, resolve, or reuse a linked worktree; stop if the current checkout is linked.
6. Do not transition/comment on TROUT, research broadly, plan, implement, or invoke another skill.

## Completion criteria

- Existing work is identified, or its absence is proven.
- Emit `Summary`, `Evidence`, `Start Brief`, optional `Findings`, and one `Next`.

## Next route

Use the router: `$ask-matt`, `$implement`, or `$grill-with-docs`. Stop.
