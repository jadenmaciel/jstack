# Dev tooling (REPO_NAME)

Student Pack wiring for this repo. Tier: **work**. Company observability only — no student Sentry or Datadog.

Runbook: `~/.cursor/docs/student-pack-cursor.md` on the machine.

## Use on this repo

| Tool | Role |
|------|------|
| Doppler Team | Project `DOPPLER_PROJECT`, config `dev`. `doppler.yaml` in repo root. |
| Codecov | GitHub app on org repo. Upload via CI. |
| GitLens | Cursor extension for blame/PR tools. |
| GitHub Pro | Personal/org GitHub features. |

## Secrets layout

```
1Password (humans)
     ↓
Doppler DOPPLER_PROJECT / dev
     ↓
doppler run -- <check command>
```

## Skip on this repo

| Tool | Why |
|------|-----|
| Student Sentry / Datadog | Company observability on work repos |
| ConfigCat | Not used in this repo |
| epayment/TROUTE stack | Out of Student Pack rollout scope |

## Cursor Cloud

- Committed: `.cursor/environment.json`
- Dashboard: Team MCP + `DOPPLER_TOKEN` Runtime Secret
- Build: save environment at cursor.com/agents after green Build
