---
name: epayment-pr
description: Commit, push, and open or update one draft epayment PR.
---

# Epayment PR

Draft-PR boundary. Load the epayment guardrails and shared core.

## Inputs

- TROUT ticket and clean same-tree `$epayment-check` receipts.
- Intended ticket branch and file set.

## Unique actions

1. Run `~/.cursor/bin/sprintflow-scope.mjs assert-epayment` with the TROUT ticket, repository, and branch; stop on any nonzero result.
2. Verify the branch is not `develop`, the diff belongs to the ticket, and both mandatory review receipts match the current tree.
3. Stage intended files only. Refuse unrelated or denied files.
4. Commit with the TROUT key and push the ticket branch.
5. With `epayment-gh`, create or update only a draft PR targeting `develop`. Keep title/body short and factual; include ticket, behavior, proof, tenant, migration, and config notes that matter.
6. Request no human reviewers. Verify URL, open state, `isDraft=true`, base, head branch, head SHA, and changed files.
7. Do not transition TROUT or mark the PR ready.

## Completion criteria

- The remote draft PR is confirmed at the reviewed tree.
- Emit `Summary`, `Evidence`, `PR`, optional `Findings`, and one `Next`.

## Next route

Confirmed draft: `/epayment-polish`. Any changed tree: `/epayment-check`. Stop.
