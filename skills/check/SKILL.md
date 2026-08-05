---
name: check
description: Run project gauntlet, thermos review, and fix until clean; grade against exact-tree evidence.
---

# Check

Non-epayment ship gate. Read `references/thermo-nuclear-code-quality-review.md` first (Approval Bar), then the shared core and router.

## Inputs

- Accepted scope and comparison base.
- Repository containing the implementation.
- Optional embedded return mode `return_to: address-pr-comments`, accepted only from that active repair workflow.

## Unique actions

1. If repository or branch evidence identifies epayment/TROUT, stop with `Next: /epayment-check`; otherwise classify the diff as code-changing or verified no-code/documentation-only.
2. Emit a short `QA Plan`.
3. Invoke `$gauntlet` fully (Run mode, or Build mode when the repo has no gates). Let `$gauntlet` run its own `$fix` → re-enter loop until gates are green or it hits a documented no-progress/blocker stop. Do not proceed to review while gauntlet still has actionable gate failures.
4. Apply the quality bar to the accepted diff.
5. Fingerprint repository, base SHA, and tree OID with `~/.cursor/bin/sprintflow-evidence.mjs`.
6. Immediately invoke `$thermos` once against the accepted comparison base and current tree. Pass the accepted scope/spec (Matt ticket body or OpenSpec change artifacts under `openspec/changes/<active>/` when present), or explicitly state that no spec exists. Resume `$check` when its report returns. One attempt only: do not retry, poll, or substitute another reviewer.
7. Map thermos output into structured `Findings` (`source: thermos`). Each finding needs `id`, `severity`, `source`, `location`, `evidence`, and `summary`. Do not invent a finding for an unavailable or unresolved review.
8. Finding filter — only these enter the `$fix` loop / block PASS:
   - Bugs, breakages, security issues, and clear regressions from the thermo-nuclear (non-CQ) pass.
   - Code-quality items that match the Approval Bar presumptive blockers in `references/thermo-nuclear-code-quality-review.md` (visible code-judo deletion left on the table, file pushed past 1k lines, ad-hoc branching that tangles a flow, feature checks scattered across shared code, unnecessary abstraction/wrapper/cast churn, canonical-helper duplication or wrong-layer logic).
   Soft CQ notes that do not match those blockers stay in Evidence as WARN-only; they are not structured findings and do not auto-fix.
9. When structured findings exist, immediately invoke `$fix` with the report and fingerprint. After `$fix` makes material progress, it re-enters `$check` (gauntlet + thermos again); repeat until `$check` reports no structured findings or `$fix` hits a documented safe no-progress or blocker stop.

## Completion criteria

- Grade `PASS`, `WARN`, or `BLOCK` with commands and exact-tree evidence.
- A `$thermos` that returns unavailable or unresolved grades `WARN` and still releases; it is not retried. An independent gauntlet/proof failure may still grade `BLOCK`.
- Emit `Summary`, `QA Plan`, `Evidence`, structured `Findings`, and one `Next`.
- In embedded return mode, return the final report to `address-pr-comments`; do not route to `$pr`.

## Next route

Clean normal work, including documentation-only: `/pr`, or return to `address-pr-comments` in embedded return mode. Structured findings: invoke `$fix` now. Unresolved review without a concrete finding: `/diagnosing-bugs`. Stop only when no automatic `$fix` route applies.
