# Cloud ship proof

Status: **cloud-native dual-pack** (2026-08-20)

## Model

| Pack | Visibility | Cloud path | Token |
|------|------------|------------|-------|
| [jadenmaciel/jstack](https://github.com/jadenmaciel/jstack) | **Public** MIT | `~/.cursor/skills/jstack/` | none |
| [jadenmaciel/jstack-personal](https://github.com/jadenmaciel/jstack-personal) | **Private** | `~/.cursor/skills/jstack-personal/` | `CURSOR_CLOUD_HOME_TOKEN` must read this repo |

Consumer repos run `bash .cursor/install-jstack-skills.sh` on **install** and **start** so every agent boot pulls latest `main`.

## Local

```bash
# jstack checkout
bash scripts/sync-local-plugin.sh
# jstack-personal checkout
bash scripts/sync-local-plugin.sh
```

Plugins: `~/.cursor/plugins/local/jstack` + `…/jstack-personal` (real copies).

## Consumers (default branch)

| Repo | Branch | Wired |
|------|--------|-------|
| clark-agency | main | install + start |
| purely-expo | main | install + start |
| Purely (purely-ios) | main | install.sh + start |

work/troute: not wired.

## Evidence

- Fixture: core 28 + personal 6 SKILL.md under separate subtrees.
- ADR: `docs/adr/0006-public-core-private-overlay.md`
- Prior SHIP_OK proof on clark (pre-split): agent `bc-77315c28-ed03-4df8-bdfa-6e01e196aff4` — rebuild after this rollout for dual-pack paths.

## Operator notes

1. Ensure dashboard secret `CURSOR_CLOUD_HOME_TOKEN` is a PAT that can clone **`jstack-personal`** (public jstack needs no token).
2. After pushing pack or consumer hooks, Trigger New Build and Activate draft if needed.
3. Future-proof: edit public/personal → `git push` → next agent **start** re-clones (no Mac sync).
