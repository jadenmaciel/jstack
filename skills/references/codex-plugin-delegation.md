# Native Codex Delegation

Canonical Codex worker contract. Sol starts workers through native `collaboration.spawn_agent` with `fork_turns="none"` and a self-contained message.

## Runtime

- The current untyped schema selects the configured Terra Medium `default` agent.
- If a future schema exposes `agent_type`, use only configured Terra/Luna roles.
- Never pass model, effort, or service-tier overrides.
- Normally use one worker. Codex defaults allow five workers beside Sol and depth one.
- Keep one writer per workspace; use disjoint worktrees for parallel writers.
- Workers never delegate.
- If native spawning fails, Sol finishes inline without launching a CLI worker.

Claude and Cursor cannot create native Codex children. They remain read-only advisors or return a bounded handoff for Sol. The legacy CLI wrapper and its receipts remain historical rollback artifacts, not active routing.

## Review

Sol owns final verification. The user may invoke Codex's native review feature; agents do not launch review subprocesses.

## Task contract

Send one self-contained task with the bounded outcome, allowed paths, forbidden actions, dirty-work warning, read/write authority, focused proof, receipt format, stop condition, and `Do not delegate`. Sol owns integration and verifies the returned evidence.
