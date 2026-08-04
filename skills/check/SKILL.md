---
name: check
description: Run focused proof and one automatic two-axis code review, then grade against exact-tree evidence.
---

# Check

Non-epayment validation. Read `references/thermo-nuclear-code-quality-review.md` first, then the shared core and router.

## Inputs

- Accepted scope and comparison base.
- Repository containing the implementation.
- Optional embedded return mode `return_to: address-pr-comments`, accepted only from that active repair workflow.

## Unique actions

1. If repository or branch evidence identifies epayment/TROUT, stop with `Next: $epayment-check`; otherwise classify the diff as code-changing or verified no-code/documentation-only.
2. Emit a short `QA Plan`; run the smallest focused tests, type-check, lint, build, browser, or visual proof required by the changed behavior. When the repo wires coverage thresholds, mutation testing, or complexity/function-size limits, run them for the touched scope and hold their thresholds.
3. Apply the quality bar to the accepted diff.
4. Fingerprint repository, base SHA, and tree OID with `~/.cursor/bin/sprintflow-evidence.mjs`.
5. Immediately invoke `$code-review` once against the accepted comparison base and current tree. Pass the accepted scope/spec (Matt ticket body or OpenSpec change artifacts under `openspec/changes/<active>/` when present), or explicitly state that no spec exists so its Spec axis skips; resume `$check` when its report returns and preserve each concrete issue as a structured finding with source `code-review`. One attempt only: do not retry, poll, invoke another workflow, or fan out subagents.
6. Emit every concrete report-backed issue in `Findings`. Each finding requires `id`, `severity`, `source`, `location`, `evidence`, and `summary`; do not invent a finding for an unavailable or unresolved review.
7. When structured findings exist, immediately invoke `$fix` with the report and fingerprint. After `$fix` makes material progress, it re-enters `$check`; repeat until `$check` reports no findings or `$fix` hits a documented safe no-progress or blocker stop.

## Completion criteria

- Grade `PASS`, `WARN`, or `BLOCK` with commands and exact-tree evidence.
- A `$code-review` that returns unavailable or unresolved grades `WARN` and still releases; it is not retried. An independent proof failure may still grade `BLOCK`.
- Emit `Summary`, `QA Plan`, `Evidence`, structured `Findings`, and one `Next`.
- In embedded return mode, return the final report to `address-pr-comments`; do not route to `$pr`.

## Next route

Clean normal work, including documentation-only: `$pr`, or return to `address-pr-comments` in embedded return mode. When an OpenSpec change is still active, recommend `/opsx:verify` before `$pr` (advisory; does not block). Structured findings: invoke `$fix` now. Unresolved review without a concrete finding: `$diagnosing-bugs`. Stop only when no automatic `$fix` route applies.
