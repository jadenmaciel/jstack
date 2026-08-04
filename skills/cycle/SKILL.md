---
name: cycle
description: Explicit normal loop to a green PR. Invoke as $cycle.
---

# Cycle

Read [references/workflow.md](references/workflow.md). `sprintflow-cycle.mjs` is
the sole state, decision, publish, adoption, and tracker-receipt authority. Never
merge, force-push, rewrite, stash, or widen scope.

## Inputs

Require task and repository; ticket optional.

## Unique actions

Confirm `$grill-with-docs` before init. Codex runs sequential `$research`,
`$implement`, and `$check` agents with `fork_turns="none"`; Claude runs
serially. One writer. Main owns bounded polling, repair, and Fable.

## Completion criteria

Reach green; leave the PR unmerged.

## Next route

None. Stop at complete or hold.
