# Embedded Agent Reach Source

- Source repo: https://github.com/Panniantong/Agent-Reach
- Embedded path: repository root
- Commit: `17624268a059ccfb23eba8a2ba50f9f92c8dc0ca`
- Retrieved: 2026-06-09
- License: MIT, copied as `LICENSE`

This bundle is vendored into `deep-research` as supporting platform-routing and channel-diagnostics tooling. The `deep-research` skill controls final report structure, source triage, and evidence ledger semantics.

Notes:
- The vendored Python package requires dependencies from `pyproject.toml` to run the full CLI.
- Use `agent-reach doctor` when the command is installed on PATH; otherwise use the embedded `agent_reach/skill/references/*.md` routing docs directly.
- Do not run install/configure/login or cookie extraction flows unless the user explicitly asks and provides any required credentials.
