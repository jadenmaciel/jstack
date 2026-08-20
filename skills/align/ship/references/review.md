# Ship mode: review

Read-only Standards + Spec review of `git diff <fixed-point>...HEAD`.

## Pin fixed point

User supplies commit/branch/tag/`main`. If missing, ask. Confirm `git rev-parse` and non-empty three-dot diff.

## Spec source (order)

1. `docs/specs/<feature>/spec.md` (+ `tasks.md` when present)
2. Issue refs in commits (fetch via tracker docs / MCP)
3. Path the user passed
4. Matching PRD under `docs/` / `specs/` / `.scratch/`
5. Ask; if none, Spec axis reports "no spec available"

## Standards

Repo coding standards docs when present. Always also apply Fowler smell heuristics as judgment calls (Mysterious Name, Duplicated Code, Feature Envy, Data Clumps, Primitive Obsession, Long Method/Function, Long Parameter List, Shotgun Surgery). Repo docs override baseline. Skip what tooling already enforces.

## Execute

Launch two parallel subagents: Standards and Spec. Aggregate side by side. Findings as `file:line severity: problem. fix.` Most severe first. Do not push.
