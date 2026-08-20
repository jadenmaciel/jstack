# jstack

Public **Skills pack** (repo SSOT) for Cursor IDE and Cursor Cloud Agents.

Personal/work-specific skills live in the private overlay [`jstack-personal`](https://github.com/jadenmaciel/jstack-personal).

## Local plugin install

Cursor rejects external symlinks under `~/.cursor/plugins/local`. Use a **real copy**:

```bash
bash scripts/sync-local-plugin.sh
```

Also sync the private overlay (separate checkout):

```bash
bash /path/to/jstack-personal/scripts/sync-local-plugin.sh
```

Reload Cursor (**Developer: Reload Window**). Enable **jstack** / **jstack-personal** under Settings → Plugins if listed but off.

## Cloud skills install

Wire each Cloud environment:

```bash
# install + start
bash .cursor/install-jstack-skills.sh
```

Copy `scripts/install-jstack-skills.sh` into the consumer as `.cursor/install-jstack-skills.sh` (keep `install-cloud-home-skills.sh` as a one-line forwarder if needed).

- **Public core** clones without a token → `~/.cursor/skills/jstack/`
- **Personal overlay** clones when dashboard secret `CURSOR_CLOUD_HOME_TOKEN` can read `jadenmaciel/jstack-personal` → `~/.cursor/skills/jstack-personal/`

Run the same script in **start** so every agent boot pulls latest `main` (Cloud-native edits without waiting on a Mac or a stale Build).

Fixture:

```bash
HOME=/tmp/x SKILLS_PACK_SRC=/path/to/jstack SKILLS_PERSONAL_SRC=/path/to/jstack-personal ./install-on-cloud.sh
```

## Keep set

See `pack.keep`. Slash entry for verify/review/green is `/ship`.

## Docs

- `CONTEXT.md` — glossary
- `docs/adr/` — decisions
- `docs/specs/skills-pack-rebuild/` — rebuild history
