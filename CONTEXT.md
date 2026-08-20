# Cursor Cloud Home

Private personal Agent Skills pack: curated daily workflows for Cursor IDE and Cursor Cloud Agents. Repo is the single source of truth.

## Language

**Skills pack**:
The private Git repository that owns the curated Agent Skills and Cursor plugin manifest. Today this repo (`jstack`, formerly `cursor-cloud-home`).
_Avoid_: skills mirror, cloud home dump, ~/.cursor/skills (as source of truth)

**Skill**:
A folder containing a `SKILL.md` (and optional scripts/references) that teaches an agent a workflow. Packaged under categorized `skills/` directories.
_Avoid_: slash command, rule, prompt file

**Ship**:
The single skill that owns verify + review + deep audit + PR comment repair + green-the-PR. Invoked as `/ship` with modes. Replaces the former separate skills gauntlet, code-review, pr-review, address-pr-comments, and thermos.
_Avoid_: gauntlet, pr-review, thermos (as standalone pack skills)

**Ship mode**:
A named entry path into **Ship**: `gauntlet` (verify gates), `review` (Standards+Spec on a local diff), `thermos` (parallel thermo audits), `address` (PR comments + failing checks, push once), `green` (default full PR-green loop).
_Avoid_: sub-skill, phase (unless describing internal steps)

**Local plugin install**:
Loading the pack on a laptop by symlinking the repo root into `~/.cursor/plugins/local/<name>` so Cursor discovers the `.cursor-plugin` manifest and skills.
_Avoid_: copying into ~/.cursor/skills on the laptop

**Cloud skills install**:
Materializing pack skills onto a Cloud Agent VM by cloning this private repo during `environment.json` `install` and syncing `skills/` into the pack-owned subtree `~/.cursor/skills/jstack/`.
_Avoid_: Team Marketplace, syncing the laptop home directory, wiping the entire `~/.cursor/skills` tree

**Cloud home token**:
The Cursor dashboard secret (`CURSOR_CLOUD_HOME_TOKEN`) used to HTTPS-clone this private repo on Cloud VMs.
_Avoid_: GitHub password, laptop credential

## Relationships

- The **Skills pack** contains many **Skills**, including **Ship**.
- **Ship** exposes several **Ship modes**.
- **Local plugin install** and **Cloud skills install** both consume the same **Skills pack** git history; on-disk layout differs by environment.
- **Cloud skills install** requires a **Cloud home token**.
