---
name: epayment-polish
description: Mandatorily polish epayment PR prose and review its diff.
---

# Epayment Polish

Mandatory final draft-PR pass. Load the epayment guardrails and shared core.

## Inputs

- One TROUT ticket and its open draft epayment PR to `develop`.
- Clean same-tree Claude and Codex receipts.

## Unique actions

1. Run `~/.cursor/bin/sprintflow-scope.mjs assert-epayment` with the TROUT ticket, repository, and PR branch; stop on any nonzero result.
2. Read the PR once and verify draft state, base, head, tree, and exact mandatory receipts.
3. Use `$stop-slop` as the PR-prose discipline: remove boilerplate and update only title/body when needed.
4. Use `$ponytail-review` as a read-only diff discipline: identify unnecessary abstraction, branches, comments, dependencies, or churn without weakening validation, tenant scope, security, or data safety.
5. Do not rerun Claude, Codex, or CodeRabbit here.
6. If Git content or its tree OID changes for any reason, prior receipts are invalid. Stop immediately; do not commit or push.
7. Report actionable prose or diff findings. The human still owns mark-ready, approval, and merge.

## Completion criteria

- PR prose is concise, Ponytail review is recorded, the Git tree is unchanged, and mandatory receipts still match.
- Emit `Summary`, `Evidence`, `PR`, optional `Findings`, and one `Next`.

## Next route

Unchanged and clean: `/epayment-handoff`. Any Git content change: `/epayment-check`. Other finding: `/implement`. Stop.
