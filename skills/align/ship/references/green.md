# Ship mode: green (default)

Drive a PR to merge-ready: synced with base, reviewed, comments addressed, CI green.

## Steps

1. `gh auth status` or stop. Load `gh pr diff` + `gh pr view --json state,mergeable,statusCheckRollup,reviews,comments,baseRefName` (or local three-dot diff).
2. If behind base, update branch (`gh pr update-branch` or merge base).
3. Review: fan out Correctness / Security / Scope / Tests subagents; add a `grilling` pass on risks. Findings as `file:line severity: problem. fix.`
4. Large/complex only: one Cursor Task on Review lane (`grok-4.6` per model-routing) or run Ship `thermos` mode once. Fold results. No Claude/Codex CLIs.
5. Address open comments and findings using Ship `address` rules (confirm before push).
6. After local green, **confirm** with the user before push. Push, read CI once. Re-loop on red (thermos at most once). Stop when current with base, CI green, threads handled, mergeable. Do not merge unless the user explicitly asks in this message.
