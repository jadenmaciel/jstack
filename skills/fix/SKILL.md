---
name: fix
description: Repair every structured finding from the immediately preceding $check or $epayment-check report, prove each repair, and re-enter that check while progress continues.
---

# Fix

Automatic check remediation. Read the shared core and router.

## Inputs

- The immediately preceding `$check` or `$epayment-check` report and exact-tree fingerprint.
- Every structured finding: `id`, `severity`, `source`, `location`, `evidence`, and `summary`.

## Unique actions

1. Refuse a missing report, malformed findings, or a report whose fingerprint no longer matches the current tree.
2. Attempt every reported finding. Trace the root cause and shared callers before editing; add or update focused regression proof at the closest stable seam, then apply the smallest safe fix. For epayment/TROUT findings, keep `merchant_id`, parameterized SQL, and authorization fail-closed.
3. Run the smallest focused proof for each changed behavior and record every finding as resolved or blocked.
4. Do not commit, push, open or update a PR, write tracker state, merge, deploy, or perform production/admin work.
5. Fingerprint the result. After material repair progress, immediately invoke the same check skill that produced the report (`$check` or `$epayment-check`). If it reports structured findings, re-enter `$fix`; repeat until that check reports no findings.
6. Stop the loop when the same finding and fingerprint repeat, no safe in-scope fix exists, proof fails without a clear repair, or a human/external action is required.

## Completion criteria

- Every input finding has a resolved or blocked disposition with focused proof.
- Emit `Summary`, `Evidence`, `Finding Dispositions`, and one `Next`.

## Next route

Material progress: invoke the originating check skill now. Unclear root cause: `/diagnosing-bugs`. No-progress, unsafe, external, or human blocker: `none`. Stop only when no automatic check route applies.
