# cursor-cloud-home

Private **Skills pack** (repo SSOT) for Cursor IDE and Cursor Cloud Agents.

## Local plugin install

```bash
ln -sfn "$(pwd)" ~/.cursor/plugins/local/cursor-cloud-home
```

Reload Cursor. Skills load from `.cursor-plugin/plugin.json`. Edit in this checkout; sync with `git push`.

Do not treat `~/.cursor/skills` as the source of truth.

## Cloud skills install

Wire each Cloud environment’s `install` to run the consumer hook (or equivalent):

```bash
bash .cursor/install-cloud-home-skills.sh
```

Copy `scripts/install-cloud-home-skills.sh` from this repo into the consumer as `.cursor/install-cloud-home-skills.sh`.

Dashboard secret: `CURSOR_CLOUD_HOME_TOKEN` (read-only PAT for this private repo). Rotate when exposed.

Optional: `CURSOR_CLOUD_HOME_BRANCH` (default in the hook today: `skills-pack-rebuild` until that lands on `main`).

The install syncs into `~/.cursor/skills/cursor-cloud-home/` on the VM (pack-owned subtree). It does not wipe the entire `~/.cursor/skills` tree. Missing token fails the Build.

Fixture / local test override:

```bash
HOME=/tmp/x SKILLS_PACK_SRC=/path/to/this/repo ./install-on-cloud.sh
```

## Keep set

See `pack.keep`. Slash entry for verify/review/green is `/ship` (modes in that skill).

## Docs

- `CONTEXT.md` — glossary
- `docs/adr/` — decisions
- `docs/specs/skills-pack-rebuild/` — rebuild spec
