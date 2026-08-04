---
name: land
description: Revalidate one named non-epayment PR, then merge immediately or queue protected auto-merge once.
---

# Land

Scoped merge boundary. Read the shared core and router.

## Inputs

- One explicit PR number.
- Optional `--override-agent-guards`. The override is bound to the head SHA read at invocation.

## Unique actions

1. Run `~/.codex/bin/sprintflow-scope.mjs assert-normal --ticket <ID> --repo <path> --branch <name>`. Any nonzero result refuses epayment/TROUT or ambiguous scope.
2. Take one snapshot of the named PR's head, tree, base, draft state, checks, review decision, mergeability, update state, a `$check` report whose `tree_oid` equals the head tree, blocking advisory state, and every open PR's `autoMergeRequest`. `$land` performs its own one-shot gate; fresh `$gate` evidence is not an input.
3. Normalize that snapshot and evaluate it with `~/.codex/bin/sprintflow-lifecycle-policy.mjs land --snapshot <json>` plus `--override-head <invocation-head>` only when requested. Treat its fail-closed action limits as binding, and evaluate the single post-update snapshot again for race handling.
4. Without an override, refuse a missing `$check` report or a mismatched `tree_oid`, agent approval-policy failures, material findings, or blocking advisory state. `--override-agent-guards` may waive a missing or tree-mismatched report, agent approval policy, and non-material advisory state only for the invocation head. A changed head expires it. Never waive material findings, failed required checks, conflicts, drafts, ambiguous scope, another active landing candidate, or GitHub protections. Never use GitHub admin bypass.
5. Fail closed if any other PR has auto-merge armed. Multiple active auto-merge PRs are `HOLD`; do not update any branch.
6. If the target is current and green, squash-merge it immediately, confirm `mergedAt` once, and return the merged result.
7. If required checks are pending or the branch is behind, arm protected squash auto-merge on the target. If behind, update it exactly once using the expected head SHA, then re-read once. Fresh GitHub checks remain required after an update.
8. On an update race, continue only if that single re-read shows the branch became current. Otherwise disable the target's auto-merge and return `HOLD`.
9. Confirm auto-merge remains armed once and emit `QUEUED_FOR_MERGE`. Never poll CI, wait for the merge, retry an update, or invoke `$close`; GitHub completes the merge and `$close` runs in a later task after confirmed merge evidence.

## Completion criteria

- The named PR is confirmed merged at the revalidated head, confirmed `QUEUED_FOR_MERGE`, or no merge/update was attempted.
- Emit `Summary`, `Evidence`, optional `Findings`, and one `Next`.

## Next route

Confirmed merge: `$close`. `QUEUED_FOR_MERGE`: `none`. Missing `$check` report or mismatched `tree_oid` without an override: `$check`. Any other blocker: `none`. Stop.
