# Ship mode: thermos

Parallel thermo-nuclear audit of the scoped diff.

1. Resolve scope (user request, PR, branch vs base, or changed files). Prefer `docs/specs/<feature>/spec.md` + `tasks.md` when present.
2. Gather diff and needed file excerpts.
3. In one message, launch both with `run_in_background: true`:
   - `thermo-nuclear-review-subagent` (bugs, breakages, security, devex, feature-flag leaks)
   - `thermo-nuclear-code-quality-review-subagent` (maintainability, structure, file growth, spaghetti)
4. Synthesize: unified verdict, deduped prioritized findings with file refs. Weight overlaps higher. Brief summary only.
5. One attempt. No substitute CLIs.

Do not push.
