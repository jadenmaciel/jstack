# Ship mode: gauntlet

Run every quality gate the project has, once. Report PASS/FAIL/SKIP per gate.

## Discover (first match wins)

1. Repo `AGENTS.md` / `CLAUDE.md` sections named Commands, Testing, or Quality gates.
2. Makefile target `check`, then `ci`, then `verify`.
3. Manifest scripts: `package.json` (`pnpm` test/lint/typecheck/build — never `npm`), `composer.json`, `pyproject.toml`.
4. Stack defaults: `go test ./...`; `pnpm test && pnpm lint && pnpm typecheck`; `pytest && ruff check`; phpunit when present.

Nothing found → build a minimal aggregate (Makefile or script with those probes), leave uncommitted, then run once.

## Run

1. Run each discovered gate once. Skip deploy/credential-gated targets; record SKIP.
2. Emit a table: gate, command, PASS/FAIL/SKIP, duration.
3. All green → stop.
4. Failures → list structured findings (gate, command, evidence). Fix root causes in-repo if the user asked to make it green; otherwise stop with the table. Do not edit threshold files to hide failures.

Optional ratchet: if `gauntlet`/`crap4go` CLI is installed, use it only as a thresholds helper after gates run — it does not discover gates.
