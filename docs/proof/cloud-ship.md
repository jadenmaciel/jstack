# Cloud ship proof

Status: **passed** — dual-pack + start re-sync (2026-08-20)

## Model

| Pack | Visibility | Cloud path | Token |
|------|------------|------------|-------|
| [jadenmaciel/jstack](https://github.com/jadenmaciel/jstack) | **Public** MIT | `~/.cursor/skills/jstack/` | none |
| [jadenmaciel/jstack-personal](https://github.com/jadenmaciel/jstack-personal) | **Private** | `~/.cursor/skills/jstack-personal/` | `CURSOR_CLOUD_HOME_TOKEN` must read this repo |

Consumer repos run `bash .cursor/install-jstack-skills.sh` on **install** and **start** so every agent boot pulls latest `main`.

Install copies `skills/` contents into each subtree (paths are `…/jstack/align/ship`, not `…/jstack/skills/align/ship`).

## Local

```bash
# jstack checkout
bash scripts/sync-local-plugin.sh
# jstack-personal checkout
bash scripts/sync-local-plugin.sh
```

Plugins: `~/.cursor/plugins/local/jstack` + `…/jstack-personal` (real copies, not symlinks).

## Consumers (default branch)

| Repo | Branch | Wired |
|------|--------|-------|
| clark-agency | main | install + start |
| purely-expo | main | install + start |
| Purely (purely-ios) | main | install.sh + start |

work/troute: not wired.

## Clark proof (dual-pack + future-proof)

| Item | Value |
|------|--------|
| Env | `ecab15a7-903f-11f1-a7d1-d6b4613131ce` |
| Active build | `bld-20260820-aa0a3278-9b3d-46b3-ae62-06e5067f7d29` (Success) |
| Install / Start | `install-jstack-skills.sh` (+ venv on install) |
| Proof agent | https://cursor.com/agents/bc-58ebe708-32ef-4cbb-bf76-ed7d78a3ff38 |

| Check | Result |
|-------|--------|
| `find ~/.cursor/skills/jstack -name SKILL.md \| wc -l` | **28** |
| `…/jstack/align/ship/SKILL.md` | **SHIP_OK** |
| `cat …/jstack/FUTUREPROOF_MARKER.txt` | **CLOUD_NATIVE_FUTUREPROOF_20260820_1135** |
| `find ~/.cursor/skills/jstack-personal -name SKILL.md \| wc -l` | **6** |
| `…/jstack-personal/day/standup/SKILL.md` | **STANDUP_OK** |

Future-proof: marker commit `779bbf6` was pushed to public `jstack` **main** after the active build; the agent still saw it via **start** re-clone (no rebuild required).

## Operator notes

1. Dashboard secret `CURSOR_CLOUD_HOME_TOKEN` must clone **`jstack-personal`** (public core needs no token).
2. After consumer hook changes, Trigger New Build and Activate draft if needed.
3. Edit pack → `git push` → next agent **start** re-clones (no Mac sync).
