# jstack

Private **Skills pack** (repo SSOT) for Cursor IDE and Cursor Cloud Agents.

Formerly `cursor-cloud-home`.

## Local plugin install

Cursor rejects external symlinks under `~/.cursor/plugins/local`. Use a **real copy** (rsync):

```bash
DEST="$HOME/.cursor/plugins/local/jstack"
mkdir -p "$DEST"
rsync -a --delete --exclude '.git/' --exclude 'graphify-out/' "$(pwd)/" "$DEST/"
```

Or: `bash scripts/sync-local-plugin.sh` from this repo.

Reload Cursor (**Developer: Reload Window**). Enable **jstack** under Settings → Plugins if it is listed but disabled. Skills load from `.cursor-plugin/plugin.json`. Edit in this checkout, then re-run the sync and reload.


## Cloud skills install

Wire each Cloud environment’s `install` to run the consumer hook (or equivalent):

```bash
bash .cursor/install-cloud-home-skills.sh
```

Copy `scripts/install-cloud-home-skills.sh` from this repo into the consumer as `.cursor/install-cloud-home-skills.sh`.

Dashboard secret: `CURSOR_CLOUD_HOME_TOKEN` (read-only PAT for this private repo; secret name kept for existing Cloud envs). Rotate when exposed.

Optional: `CURSOR_CLOUD_HOME_REPO` (default `jadenmaciel/jstack`), `CURSOR_CLOUD_HOME_BRANCH` (default `main`).

The install syncs into `~/.cursor/skills/jstack/` on the VM (pack-owned subtree). It does not wipe the entire `~/.cursor/skills` tree. Missing token fails the Build.

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
