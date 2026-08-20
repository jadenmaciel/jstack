---
name: repo-services
description: Wire GitHub Student Pack services (Doppler, Codecov, Cursor Cloud environment.json, student-pack rules) into a repo after repo-onboard. Use on /repo-services when onboarding pack tooling; requires network and user confirmation.
---

# repo-services

Stamp Student Pack service wiring into a repo. Runs **after** `/repo-onboard` (offline baseline). Never overwrites existing files. Confirm gap list before stamping.

Canonical runbook: `~/.cursor/docs/student-pack-cursor.md`
Cloud dashboard steps: `~/.cursor/docs/cloud-agent-dashboard.md`

## Repo matrix

| Repo path | Tier | Doppler project | Sentry | Codecov | ConfigCat |
|-----------|------|-----------------|--------|---------|-----------|
| `Development/clark-agency` | personal | `clark-agency` | skip | yes (gauntlet) | skip |
| `Development/purely-expo` | personal | `purely-expo` | yes | stub until tests | yes |
| `Development/Purely` | personal | `purely-ios` | yes | skip (Xcode Cloud) | yes |
| `Development/work/troute-fulfillment` | work | `work-troute-fulfillment` | skip | yes | skip |
| `Development/work/troute-communications/troute-comms` | work | `work-troute-communications` | skip | yes | skip |

**Out of scope:** `Development/work/epayment`

## Steps

1. **Resolve repo.** Use matrix row or ask user. Detect language: `go.mod`, `package.json`, `pyproject.toml`/`requirements.txt`, `Cargo.toml`.

2. **Scan gaps.** Check:
   - `doppler.yaml`
   - `.cursor/environment.json`
   - `.cursor/rules/student-pack.mdc`
   - `docs/agents/dev-tooling.md` or `docs/STUDENT_PACK.md`
   - `.github/workflows/codecov.yml` (or Codecov step in existing CI)
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `.gitignore` — must allow `.cursor/rules/`, `.cursor/environment.json`, `.cursor/skills/`; ignore only `.cursor/mcp.json` and `.cursor/mcp-env/`

3. **Present gap list and wait.** Same confirm gate as repo-onboard.

4. **Doppler (check-then-create).**
   - Verify project exists via Doppler MCP or `doppler projects get <name>` (source `~/.cursor/mcp-env/doppler.env` locally).
   - If missing, create project in Doppler UI or API; stamp `templates/doppler.yaml` with matrix project name.
   - Never duplicate an existing project.

5. **Stamp files** from `templates/` (pick variant by language):
   - `doppler.yaml`
   - `environment.json` → `.cursor/environment.json` (python | node | go | rust variant)
   - `student-pack.mdc` → `.cursor/rules/student-pack.mdc` (fill `{REPO}`, `{DOPPLER_PROJECT}`, `{TIER}`)
   - `STUDENT_PACK.md` or `dev-tooling.md` → repo docs path
   - `codecov.yml` if no Codecov upload yet
   - `PULL_REQUEST_TEMPLATE.md` if missing
   - Patch `.gitignore` if blanket `.cursor/` blocks committed Cursor files

6. **AGENTS.md.** Add or extend `## Cursor Cloud` with:
   - Doppler project + config
   - Install/check commands
   - Allowed MCP servers (tier-specific)
   - Skip list (no student Sentry/Datadog on work)

7. **Notion.** Append status row to [Student Benefits checklist](https://app.notion.com/p/3c0ec3298ad18177985cc26bedf0494b) via Notion MCP (repo name, Doppler project, Cloud env stamped date). No secrets in Notion.

8. **Final report.** Per item: pass | stamped | skipped. Remind user:
   - Dashboard Team MCP + Runtime Secrets (`cloud-agent-dashboard.md`)
   - Cloud Build + save snapshot
   - Fill `~/.cursor/mcp-env/configcat.env` if ConfigCat tier

## Templates

| File | Variants |
|------|----------|
| `templates/doppler.yaml` | single |
| `templates/environment.json` | `{LANG}` = python, node, go, rust |
| `templates/student-pack.mdc` | placeholders `{REPO}`, `{DOPPLER_PROJECT}`, `{TIER}`, `{MCP_ALLOWLIST}` |
| `templates/STUDENT_PACK.md` | personal (Purely-style) |
| `templates/dev-tooling.md` | work (Clark-style) |
| `templates/codecov.yml` | upload stub |
| `templates/PULL_REQUEST_TEMPLATE.md` | standard |

## Tier rules

**Personal:** Sentry + ConfigCat allowed where matrix says yes. Codecov via GitHub app on `jadenmaciel/*`.

**Work:** Doppler + Codecov + company observability only. No student Sentry, Datadog, or ConfigCat MCP on Cloud allowlist.

## What this skill does not do

- Replace `/repo-onboard` baseline (hooks, AGENTS stub, check.yml)
- Rotate or paste secrets into git
- Configure Cursor dashboard (human steps in `cloud-agent-dashboard.md`)
- Touch `Development/work/epayment`
