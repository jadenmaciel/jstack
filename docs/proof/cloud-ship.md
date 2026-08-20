# Cloud ship proof

Status: **passed** (2026-08-20)

## Environment

- Repo: `jadenmaciel/clark-agency`
- Active build: `bld-20260820-86eae8aa-5918-4c78-9c98-d92e323750a6` (manual, Success, activated)
- Build commit: `08e10e4` (venv fix); snapshot later pinned in `0f263e3`
- Proof agent: https://cursor.com/agents/bc-77315c28-ed03-4df8-bdfa-6e01e196aff4

## Fix that unblocked installs

Recurring builds failed with:

```text
The virtual environment was not created successfully because ensurepip is not available.
apt install python3.12-venv
```

`clark-agency` `.cursor/environment.json` install now runs `sudo apt-get install -y python3-venv` before `python3 -m venv .venv`, after `bash .cursor/install-cloud-home-skills.sh`.

## Agent evidence

Read-only check on the activated build:

| Check | Result |
|-------|--------|
| `find ~/.cursor/skills/cursor-cloud-home -name SKILL.md \| wc -l` | `34` |
| `ls …/align/ship` | present (`SKILL.md` + `references/`) |
| `test -f …/align/ship/SKILL.md` | `SHIP_OK` |
| pack dirs | `align day misc repo research style` |

`/ship` skill file is on the Cloud VM under the pack-owned subtree.

## Notes

- Dashboard **Install Script** UI may still show an older inline clone snippet; builds from repo `environment.json` on `main` are the working path used for this proof.
- Laptop purge (2026-08-20): removed 43 dirs under `~/.cursor/skills` (all `pack.keep` copies + delete-set including `obsidian-note`). Left non-pack leftovers and `.system`. Local load path is `~/.cursor/plugins/local/cursor-cloud-home`.
