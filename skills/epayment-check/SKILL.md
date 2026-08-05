---
name: epayment-check
description: Validate epayment via gauntlet, thermos, and fix until clean; grade against exact-tree evidence.
---

# Epayment Check

Mandatory epayment ship gate. Load the epayment guardrails and the generic quality bar first. Read `../check/references/thermo-nuclear-code-quality-review.md` for the Approval Bar filter.

## Inputs

- Accepted TROUT scope, repository, and `develop` comparison base.

## Unique actions

1. Run `~/.cursor/bin/sprintflow-scope.mjs assert-epayment` with the TROUT ticket, repository, and branch; stop on any nonzero result.
2. Emit a short `QA Plan`; classify the diff.
3. Check `merchant_id` boundaries, authorization, parameterized SQL, and migration/config/`DatabaseTestCase` parity.
4. Invoke `$gauntlet` fully (Run mode, or Build mode when the repo has no gates). Let `$gauntlet` run its own `$fix` → re-enter loop until gates are green or it hits a documented no-progress/blocker stop. Do not proceed to review while gauntlet still has actionable gate failures.
5. Apply the generic quality bar.
6. Fingerprint the exact tree with `~/.cursor/bin/sprintflow-evidence.mjs`.
7. Immediately invoke `$thermos` once against `develop` and the current tree. Pass the accepted TROUT scope/spec when present. Resume `$epayment-check` when its report returns. One attempt only: no retry, polling, or substitute reviewer.
8. Map thermos output into structured `Findings` (`source: thermos`). Each finding needs `id`, `severity`, `source`, `location`, `evidence`, and `summary`. Do not invent a finding for an unavailable or unresolved review.
9. Finding filter — only these enter the `$fix` loop / block PASS:
   - Bugs, breakages, security issues, and clear regressions from the thermo-nuclear (non-CQ) pass.
   - Code-quality items that match the Approval Bar presumptive blockers (visible code-judo deletion left on the table, file pushed past 1k lines, ad-hoc branching that tangles a flow, feature checks scattered across shared code, unnecessary abstraction/wrapper/cast churn, canonical-helper duplication or wrong-layer logic).
   Soft CQ notes that do not match those blockers stay in Evidence as WARN-only; they are not structured findings and do not auto-fix.
10. When structured findings exist, immediately invoke `$fix` with the report and fingerprint. After `$fix` makes material progress, re-enter `$epayment-check` (gauntlet + thermos again); repeat until no structured findings or `$fix` hits a documented safe no-progress or blocker stop.
11. If CodeRabbit is already installed and authenticated, make one opportunistic attempt. Otherwise record a non-blocking skip; do not install or log in.

## Completion criteria

- Grade `PASS`, `WARN`, or `BLOCK`.
- Code-changing `PASS` requires a usable same-tree `$thermos` report with no structured findings after the filter. Unavailable or unresolved `$thermos` blocks PASS (`BLOCK`).
- Emit `Summary`, `QA Plan`, `Evidence`, optional `Findings`, and one `Next`.

## Next route

Clean: `/epayment-pr`. Structured findings: invoke `$fix` now. Clear correction outside the auto-fix loop: `/implement`. Unclear failure: `/diagnosing-bugs`. Stop.
