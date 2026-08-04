---
name: epayment-cycle
description: Explicit TROUT/FILL loop to a green draft PR and Code Review. Invoke as $epayment-cycle.
---

# Epayment Cycle

Read [references/workflow.md](references/workflow.md).
`sprintflow-epayment-cycle.mjs` is the sole state, decision, adoption, and
receipt authority; epayment skills retain action authority. Never exceed the
draft/Code Review ceiling, use worktrees, or perform destructive Git actions.

## Inputs

Require `TROUT-*` or `FILL-*`; FILL links one TROUT.

## Unique actions

Resolve FILL first. Then run `$epayment-start` and confirmed `$grill-with-docs`
before init. Codex runs sequential planner, implementer, and reviewer agents
with `fork_turns="none"`; Claude runs serially. One writer. Follow referenced
proof, publication, polish, repair, sync, and handoff. Only `$epayment-pr`
publishes; only `$epayment-handoff` moves TROUT to Code Review.

## Completion criteria

Reach `COMPLETE` with every referenced predicate satisfied; leave the PR draft.

## Next route

None. Stop at `COMPLETE` or `HOLD`.
