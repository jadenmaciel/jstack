# Gates And Nets Production Contract

Use this when SprintFlow touches production apps, security, data, release, CI/CD, observability, or project context. Gates prevent bad changes from shipping. Nets catch and explain what slips through.

## Gates

- Spec gate: `$start` and `$devise` turn vague work into a traceable contract with acceptance criteria, constraints, non-goals, and first proof. For behavior/API/auth/data/security/migration/high-risk or >3-file changes, use `/opsx:explore` → `$grill-with-docs` → `/opsx:propose` (then `/opsx:apply`); do not use it for tiny mechanical edits. `$to-spec` is retired.
- Context gate: use `intent-layer` when project docs are missing, duplicated, stale, or hiding non-inferable contracts. Prefer one project-root context file and child `AGENTS.md` files only at real responsibility boundaries.
- Version-control gate: keep work atomic, scoped, branch/worktree-safe, and rollback-friendly.
- Test gate: behavior changes, bug fixes, public interfaces, and integrations use `$tdd` at an agreed seam. Pure removals, mechanical edits, and changes with accepted existing coverage may skip new tests; record the exemption and verify affected callers/builds.
- Auth/data gate: separate authentication from authorization; enforce server/API and database boundaries, including tenant scoping, RLS, indexes, migrations, and N+1 risk.
- Security gate: use least privilege, no secret fallbacks, no fail-open defaults, no stringly typed security. Trigger Trail of Bits helpers when security/API/config risk appears.
- Release gate: `$check` validates, `$gate` proves latest-head CI/review/security/policy readiness, and `$land` merges only with fresh gate evidence plus current explicit scoped merge/release authority.

## Nets

- Error net: expected errors are handled explicitly; unexpected errors surface safe messages and useful diagnostics.
- Runtime net: inputs validate at trust boundaries; network and external calls use timeouts, retries only where safe, and clear failure modes.
- Observability net: logs, metrics, traces, alerts, request/user IDs, version/commit IDs, and smoke checks make failures attributable.
- Rollback net: migrations and deploys have a safe order, rollback or recovery notes, and post-merge target-branch checks when expected.
- Learning net: `$close` records escaped-bug lessons, stale docs, follow-up issues, and context updates.

## External Helper Triggers

- Context/docs ambiguity -> `intent-layer`, `$grill-with-docs`, `/opsx:propose` (after `/opsx:explore` when the area is unclear).
- Security/API/auth/config risk -> `sharp-edges@trailofbits`, `insecure-defaults@trailofbits`, `codex-security:*`.
- Code diff security review -> `differential-review@trailofbits`.
- Static security scan need -> `static-analysis@trailofbits`.
- Dependency or package-choice risk -> `supply-chain-risk-auditor@trailofbits`.
- AI GitHub Actions or agentic CI risk -> `agentic-actions-auditor@trailofbits`.

## Intent Layer Defaults

- One project-root context file where practical; do not keep competing root `CLAUDE.md` and `AGENTS.md` in the same repo unless a runtime requires a pointer-only compatibility file.
- Child `AGENTS.md` files belong at responsibility shifts, hidden contracts, high-token subsystems, or cross-cutting concern LCAs.
- Capture ownership, out-of-scope rules, invariants, repeated confusion, and local patterns.
- Keep each node under roughly 4k tokens, downlink relatively, and do not duplicate ancestor context.
