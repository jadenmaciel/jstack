---
name: epayment-check
description: Validate epayment and collect two exact-tree reviews.
---

# Epayment Check

Mandatory epayment validation. Load the epayment guardrails and the generic quality bar first.

## Inputs

- Accepted TROUT scope, repository, and `develop` comparison base.

## Unique actions

1. Run `~/.codex/bin/sprintflow-scope.mjs assert-epayment` with the TROUT ticket, repository, and branch; stop on any nonzero result.
2. Emit a short `QA Plan`; classify the diff and run focused PHP/test/UI proof.
3. Check `merchant_id` boundaries, authorization, parameterized SQL, and migration/config/`DatabaseTestCase` parity.
4. Apply the generic quality bar.
5. Fingerprint the exact tree with `~/.codex/bin/sprintflow-evidence.mjs`.
6. Reuse exact receipts or launch, in parallel, one non-session Claude Fable High review and one Codex High review against that tree. The current orchestrator counts as neither reviewer. Record separate `claude-fable-high` and `codex-high` receipts.
7. Run each mandatory reviewer once—no retry, polling, or substitute reviewer. Unavailable, findings, unresolved, or mismatched evidence blocks.
8. If CodeRabbit is already installed and authenticated, make one opportunistic attempt. Otherwise record a non-blocking skip; do not install or log in.

## Completion criteria

- Grade `PASS`, `WARN`, or `BLOCK`.
- Code-changing `PASS` requires clean same-tree receipts from both mandatory reviewers.
- Emit `Summary`, `QA Plan`, `Evidence`, optional `Findings`, and one `Next`.

## Next route

Clean: `$epayment-pr`. Clear correction: `$implement`. Unclear failure: `$diagnosing-bugs`. Stop.
