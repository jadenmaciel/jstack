# Cloud delivery via environment install, not Teams

## Status

Superseded in part by [0006-public-core-private-overlay](0006-public-core-private-overlay.md).

## Context

Stay on a personal Cursor plan. Cloud Agents do not inherit laptop User plugins or `~/.cursor` skills.

## Decision (historical core, still true)

Deliver pack skills through `.cursor/environment.json` **install** (and **start** re-sync), not Team Marketplace Required plugins.

## Update (2026-08-20)

- Public **Skills pack** (`jstack`) clones **without** a token.
- **Cloud home token** (`CURSOR_CLOUD_HOME_TOKEN`) clones only the private **Personal overlay**.
- See ADR 0006 for the split and paths.

## Alternatives considered

- Team Marketplace Required — needs Teams/Enterprise.
- Relying on IDE marketplace / laptop sync — does not reach Cloud VMs.
