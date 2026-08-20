# jstack

Public personal Agent Skills pack: curated daily workflows for Cursor IDE and Cursor Cloud Agents. Repo is the single source of truth for the **public core**.

## Language

**Skills pack**:
The public Git repository (`jstack`) that owns the curated Agent Skills and Cursor plugin manifest for the shareable core.
_Avoid_: skills mirror, cloud home dump, ~/.cursor/skills (as source of truth)

**Personal overlay**:
The private Git repository (`jstack-personal`) that owns personal/work-specific skills layered beside the Skills pack on Cloud and locally.
_Avoid_: embedding ExpiTrans/standup specifics in the public Skills pack

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
Loading a pack on a laptop by rsync-copying the repo into `~/.cursor/plugins/local/<name>` (Cursor rejects external symlinks there) so Cursor discovers the `.cursor-plugin` manifest and skills.
_Avoid_: symlink into plugins/local, copying into ~/.cursor/skills on the laptop as SSOT

**Cloud skills install**:
Materializing pack skills onto a Cloud Agent VM by cloning the public Skills pack (no token) and optionally the Personal overlay (with token) during `environment.json` `install`/`start` into pack-owned subtrees under `~/.cursor/skills/`.
_Avoid_: Team Marketplace Required (needs Teams), syncing the laptop home directory, wiping the entire `~/.cursor/skills` tree

**Cloud home token**:
The Cursor dashboard secret (`CURSOR_CLOUD_HOME_TOKEN`) used to HTTPS-clone the private **Personal overlay**. Not required for the public Skills pack.
_Avoid_: GitHub password, laptop credential

## Relationships

- The **Skills pack** contains many public **Skills**, including **Ship**.
- The **Personal overlay** contains personal **Skills** that must not ship in the public tree.
- **Local plugin install** and **Cloud skills install** both consume git history; on-disk layout differs by environment.
- **Cloud skills install** of the Personal overlay requires a **Cloud home token**.
