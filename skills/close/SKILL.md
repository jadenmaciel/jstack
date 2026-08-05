---
name: close
description: Finish one normal ticket after its exact PR is confirmed merged.
---

# Close

Normal-ticket completion boundary. Read the shared core and router.

## Inputs

- The ticket ID. Require it explicitly when parent and child tickets are both plausible.
- One exact merged PR owned by that ticket.

## Unique actions

1. Run `~/.cursor/bin/sprintflow-scope.mjs assert-normal --ticket <ID> --repo <path> --branch <name>`. Any nonzero result refuses TROUT/epayment or ambiguous scope.
2. Read the exact PR once and require `mergedAt`, its merge/head identity, and exact ticket ownership. A queued auto-merge is not merge evidence. After merge, confirmed merge plus exact ticket ownership is closure proof; never routes a merged PR to `$check`.
3. Normalize the closure snapshot and evaluate it with `~/.cursor/bin/sprintflow-lifecycle-policy.mjs close --snapshot <json>`; its ownership and no-review-reentry limits are binding.
4. Look up content evidence for the merged tree. Missing evidence is a warning, not a blocker. Add one idempotent Jira warning keyed by ticket, PR number, and merge SHA; do not duplicate it on a retry.
5. Before summary or `Done`, review merged work for verified, durable, non-inferable facts. Require canonical docs and applicable `AGENTS.md` corrections to be merged; record their paths as evidence. Known stale docs or guidance block `Done`: leave the ticket open and recommend `$implement` for the smallest docs-only correction, then rerun `$close` after it lands.
6. Summarize completed scope, merge proof, warning state, residual risks, and follow-ups.
7. Transition the named normal ticket to `Done` using its configured tracker, then re-read the status. If the write is unavailable or fails, report the blocker and do not claim closure.
8. Once closure is confirmed, remove the ticket's worktree if it needed one: run `bash ~/.cursor/skills/close/scripts/remove-worktree.sh <branch-slug>` (same slug `$start` used). It safely no-ops -- and never forces a removal -- when the worktree is dirty, still the active directory, or already gone; treat any of those as a note, not a blocker. Skip this step entirely when step 5 blocked closure, since `$implement` needs that worktree next.
9. Write memory or other sinks only when explicitly requested.

## Completion criteria

- The exact ticket is confirmed `Done`, or closure is explicitly blocked.
- No known stale docs or guidance remains; required canonical docs and applicable `AGENTS.md` corrections are merged and their paths are recorded as evidence.
- The ticket's worktree is removed, or the reason it was left in place is stated.
- Emit `Summary`, `Evidence`, optional `Findings`, and one `Next`.

## Next route

Known stale docs or guidance: `/implement` for the smallest docs-only correction, then rerun `/close` after it lands. Confirmed `Done`: if a matching `openspec/changes/<id>/` remains active, recommend `/opsx:archive` (advisory; archive failure never blocks Done); otherwise `none`. Any other merge, ownership, tracker, or scope blocker: `none`. Stop.
