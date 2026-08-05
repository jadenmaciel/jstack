---
name: epayment-handoff
description: Post epayment evidence and move TROUT to Code Review.
---

# Epayment Handoff

Human-review handoff ceiling. Load the epayment guardrails and shared core.

## Inputs

- TROUT ticket, clean mandatory polish result, and open draft PR.

## Unique actions

1. Run `~/.cursor/bin/sprintflow-scope.mjs assert-epayment` with the TROUT ticket, repository, and PR branch; stop on any nonzero result.
2. Re-read ticket, draft PR head/tree, and same-tree Claude/Codex receipts once.
3. Refuse a changed tree, non-draft PR, wrong base, open blocking finding, or missing polish evidence.
4. Post one short first-person TROUT comment with the draft PR, behavior, proof, tenant/migration notes, and remaining human action.
5. Transition only the named TROUT ticket to `Code Review`, then re-read its status.
6. Do not request reviewers, mark ready, approve, merge, mark Done/Deployed, deploy, or perform production action.

## Completion criteria

- One evidence comment exists and TROUT is confirmed at `Code Review`, or handoff is blocked.
- Emit `Summary`, `Evidence`, optional `Findings`, and one `Next`.

## Next route

Confirmed handoff: `none`. Changed code: `/epayment-check`. Other blocker: `none`. Stop.
