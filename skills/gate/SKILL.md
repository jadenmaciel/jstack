---
name: gate
description: Inspect one non-epayment PR head once for landing readiness.
---

# Gate

One-shot, read-only preview of non-epayment release readiness. Read the shared core and router. `$land` performs the same gate for execution and does not require this report.

## Inputs

- An explicit PR number, or a repository whose current branch resolves to exactly one open PR.
- Clean `$check` evidence for the candidate head tree.

## Unique actions

1. Reject zero or multiple candidate PRs; never guess.
2. Read the PR number, base, latest head SHA/tree, repository, branch, draft state, checks, review decision, mergeability, and blocking comments once.
3. Normalize that snapshot and evaluate it with `~/.cursor/bin/sprintflow-lifecycle-policy.mjs gate --snapshot <json>`; its fail-closed verdict is binding.
4. If repository or branch evidence identifies epayment/TROUT, emit `HOLD` with `Next: /epayment-check`.
5. Confirm `$check` graded this exact tree: re-run `~/.cursor/bin/sprintflow-evidence.mjs fingerprint --repo <path> --base <rev>` and require its `tree_oid` to equal the one in the `$check` report, on a `PASS` or `WARN` grade. A missing report or a mismatched `tree_oid` is a hold; the remedy is `$check`, which re-grades the current tree. A `WARN` grade whose findings are all resolved is advisory and releases.
6. Emit `HOLD` immediately for failed CI, draft, missing approval, conflict, material finding, policy blocker, invalid evidence, or ambiguity. Do not wait, poll, repair, push, or re-enter.
7. Emit `READY_FOR_LAND` when the latest head is clean, current, green, approved as required, and mergeable.
8. Emit `READY_FOR_AUTO_MERGE` when every local/content gate is satisfied and the only remaining blockers are GitHub-enforced checks pending or the branch being behind its base.

## Completion criteria

- Output exactly one verdict: `READY_FOR_LAND`, `READY_FOR_AUTO_MERGE`, or `HOLD`.
- Emit `Summary`, `Evidence`, optional `Findings`, and one `Next`.

## Next route

`READY_FOR_LAND` or `READY_FOR_AUTO_MERGE`: `/land`. `HOLD` on a missing report or mismatched `tree_oid`: `/check`. `HOLD` with a clear correction: `/implement`. Unclear failure: `/diagnosing-bugs`. Stop.
