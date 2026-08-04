---
name: gauntlet
description: Run a project's full check battery (tests, lint, typecheck, thresholds) end to end. If the project has no wired checks, build one — a Makefile/script aggregate plus a thresholds ratchet — then run it. Use when the user says "run the gauntlet", "/gauntlet", or asks to run all checks/tests/lint for a project.
---

# Gauntlet

Run every quality gate a project has, once, and report PASS/WARN/BLOCK per gate. If
none exist, build a minimal set modeled on `~/Development/work/troute-fulfillment`'s
`make check`, then run it. The `gauntlet`/`crap4go` CLI (github.com/jadenmaciel/gauntlet,
local clone `~/Development/tools/gauntlet`) is the thresholds ratchet this skill wires
in — the binary enforces one ceiling/floor per `verify` call, it does not discover or
run anything itself.

## Inputs

- Target repository (default: current working directory).
- Optional scope (touched-files-only vs whole tree) — default to whatever the
  project's own gates already scope to; do not widen it.

## Discover (first match wins, stop there)

1. Repo agent docs: `AGENTS.md`/`CLAUDE.md` sections named Commands, Testing, or
   Quality gates. This is the canonical source when present — trust its command
   list over guessing from files on disk.
2. Aggregate Makefile target: `check`, then `ci`, then `verify`.
3. Manifest scripts: `package.json` (`pnpm test`/`lint`/`typecheck`/`build` — never
   `npm`), `composer.json`, `pyproject.toml`.
4. Stack-default probes: `go test ./... && golangci-lint run`; `pnpm test && pnpm
   lint && pnpm typecheck`; `./vendor/bin/phpunit` + `phpmd`; `pytest && ruff check`.

Found nothing after all four → Build mode. Found something → Run mode.

## Run mode

1. Run every discovered gate once. Skip cost- or credential-gated targets (deploys,
   cloud smoke tests, paid APIs) and record the skip — do not ask permission to
   skip, only to run one.
2. Emit a table: gate, command, PASS/FAIL/SKIP, duration.
3. All green → report and stop.
4. Any failure → turn each into a structured finding (gate, command, evidence) and
   invoke `$fix`. After `$fix` makes material progress it re-enters `/gauntlet`;
   repeat until green or `$fix` hits a documented safe no-progress/blocker stop —
   same loop `$check` step 7 uses. Never edit a threshold file to make a failure
   disappear; fix the code.

## Build mode

Nothing wired. Build the troute-style aggregate, then run it once (falls through to
Run mode). Everything stays uncommitted — troute and epayment both keep their gate
scripts staged, not pushed, until a ticket scopes wiring them into live CI.

1. Detect stack (go.mod / package.json / composer.json / pyproject.toml). Wire that
   stack's standard test runner and linter; add a typecheck step where the language
   has one (tsc, mypy/pyright, `go build`).
2. Install the thresholds ratchet:
   - Run `gauntlet init` to write `.gauntlet/thresholds.yml` with loose starting
     values — the ratchet only tightens later, never loosen an existing ceiling.
   - Go projects: also pull `crap4go` and copy `templates/go/Makefile.fragment` +
     `templates/go/golangci-fragment.yml` from `~/Development/tools/gauntlet` and
     adapt them, the same fragments troute-fulfillment's Makefile is built from.
   - Non-Go stacks: wrap the stack's own coverage/complexity output with
     `gauntlet verify --metric <name> --value <n>` for each threshold in
     `.gauntlet/thresholds.yml`.
3. Create one aggregate entry point (`make check` or the stack's nearest
   equivalent — `pnpm run check` for a Node project with no Makefile) that runs
   every gate from step 1 plus the ratchet checks from step 2, in sequence.
4. Give every new gate script a self-test path (`--self-test` flag, or its own
   unit test) — matches `scripts/phpmd-gate.sh --self-test` in epayment and every
   gate script in troute-fulfillment.
5. Write or append an `AGENTS.md` §Commands section listing the aggregate command
   and what it runs, so the next `/gauntlet` — or any agent — finds it via
   Discover step 1 instead of rebuilding it.
6. Report what was created (files touched, thresholds chosen, why), then run the
   new aggregate once. Falls into Run mode.

## Boundaries

- Ratchet moves one direction: coverage floors up, complexity/CRAP ceilings down.
  Never loosen a threshold to make a run pass.
- Never commit or push anything this skill creates or runs.
- Never run a gate that spends money or needs credentials (deploys, paid API
  calls) without asking first.

## Completion criteria

- Grade `PASS`, `WARN` (all findings resolved by `$fix`), or `BLOCK`.
- Emit `Summary`, the gate table, and one `Next`.

## Next route

Clean: hand back to whatever brought you here (PR flow, `$check`, or the user).
Unresolved failure `$fix` can't close: `$diagnosing-bugs`. Stop.
