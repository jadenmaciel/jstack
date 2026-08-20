# ADR 0006: Public core + private personal overlay

## Status

Accepted

## Context

We need jstack skills on every personal Cloud Agent without depending on Mac sync, and we want a pstack-like experience on a personal Cursor plan (no Team Marketplace Required). Some skills contain ExpiTrans/personal wiring that must not be public.

## Decision

Split into:

1. **Public** `jadenmaciel/jstack` (MIT) — generic agent OS; Cloud clones without a token into `~/.cursor/skills/jstack/`.
2. **Private** `jadenmaciel/jstack-personal` — six personal skills; Cloud clones with `CURSOR_CLOUD_HOME_TOKEN` into `~/.cursor/skills/jstack-personal/`.

Local IDE loads both as separate rsync copies under `~/.cursor/plugins/local/`. Consumer `install` and `start` both run the installer so agent boots pull latest `main`.

## Consequences

- Cloud gets core skills even if the overlay token is missing (warn-only).
- Publishing requires scrubbing personal strings from the public tree before `gh repo edit --visibility public`.
- Token dashboard name stays `CURSOR_CLOUD_HOME_TOKEN` but means “overlay clone token”.

## Alternatives considered

- All-private + token for everything — works but blocks tokenless Cloud and public sharing.
- All-public after scrub — loses personal standup/payday/repo-services as written.
- Team Marketplace Required — needs Teams/Enterprise.
