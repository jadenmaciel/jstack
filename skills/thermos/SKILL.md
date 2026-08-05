---
name: thermos
description: Launch both thermo-nuclear review subagents in parallel, then synthesize findings. Use for thermos, double thermo review, check-invoked branch audit, or combined bug/security and code-quality reviews.
---

# Thermos

Run the two thermo review passes as async background subagents in parallel, then synthesize their results.

## Workflow

1. Determine the review scope from the user request, PR, current branch, accepted check comparison base, or relevant changed files. When invoked from `$check` / `$epayment-check`, use that skill's accepted base and tree.
2. Gather the diff and any file/context excerpts needed for reviewers to evaluate the change without guessing. Pass accepted scope/spec (ticket body or OpenSpec artifacts) when the caller provides them.
3. Launch both subagents in the same message with `run_in_background: true`:
   - `subagent_type: "thermo-nuclear-review-subagent"` for bugs, breakages, security, devex regressions, feature-flag leaks, and other branch-audit risks.
   - `subagent_type: "thermo-nuclear-code-quality-review-subagent"` for maintainability, structure, file-size growth, spaghetti, abstractions, and codebase-health risks.
4. Pass each subagent the same scoped diff/file context and ask it to return prioritized findings with file references and evidence.
5. After both finish, synthesize the results with findings first, deduplicated across reviewers. Weight overlapping findings more heavily, resolve disagreements with your own judgment, and keep summaries brief.

If individual background summaries are already visible to the user, do not restate them wholesale. Surface the unified verdict, the highest-signal findings, and any remaining uncertainty.

## Completion criteria

- Unified verdict plus prioritized findings with file references, or an explicit `unavailable` / `unresolved` status if either subagent cannot complete.
- One attempt only when called from `$check` / `$epayment-check`: no retry, polling, or substitute reviewer.
