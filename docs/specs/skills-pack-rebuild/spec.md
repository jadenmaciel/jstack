# Skills pack rebuild

## Problem Statement

Custom Cursor skills live on the laptop under `~/.cursor/skills` and do not appear on Cursor Cloud Agent VMs. Installing marketplace plugins in the IDE (for example mattpocock) also fails to sync to Cloud. The existing `cursor-cloud-home` private repo was a push-mirror of the whole laptop skills tree with Mac as source of truth, so it stayed huge, stale relative to intent, and pointed the wrong way for a curated pack. The user wants one private **Skills pack** that is the SSOT, loads locally like a Cursor plugin, and reaches Cloud via environment install — without switching to Teams/Enterprise.

## Solution

Rebuild `cursor-cloud-home` in place as a curated personal **Skills pack**: Cursor plugin shell (`.cursor-plugin/`) plus categorized `skills/` (human browsing). Repo is SSOT. Local **Local plugin install** via symlink into `~/.cursor/plugins/local`. Cloud **Cloud skills install** via hardened `install-on-cloud.sh` + **Cloud home token**, syncing into a **pack-owned subtree** under the VM’s `~/.cursor/skills/` (not a full wipe). Merge five verify/review skills into one thin **Ship** router (`/ship` + **Ship modes** with mode bodies in `references/*.md`, not nested `SKILL.md`). Import missing keepers from the laptop **before** slim/purge. Prove Cloud discovery before deleting laptop copies. Delete Mac→Git sync. Edit in the git checkout and `git push`.

## User Stories

1. As a Cursor user on a personal plan, I want my curated skills available on Cloud Agents, so that Cloud work matches how I work locally without Teams/Enterprise.
2. As a Cursor user, I want a single private GitHub repo to own those skills, so that I am not maintaining two conflicting sources of truth.
3. As a Cursor user, I want the pack shaped like pstack (plugin manifest) and mattpocock (categories), so that local discovery and mental model match tools I already trust.
4. As a Cursor user, I want plugin discovery to actually list every keeper after symlink, so that category folders do not hide skills from the Cursor plugin loader.
5. As a Cursor user, I want to symlink the repo into `~/.cursor/plugins/local`, so that the IDE loads the pack without copying into `~/.cursor/skills`.
6. As a Cloud Agent operator, I want `environment.json` `install` to clone the private pack with a dashboard secret, so that VMs get skills without my laptop home directory.
7. As a Cloud Agent operator, I want skills materialized under a pack-owned path under the VM’s `~/.cursor/skills/`, so that other VM skills are not deleted on every Build.
8. As a Cloud Agent operator, I want missing auth to fail the Build (not soft-skip), so that I notice when Cloud has no pack.
9. As a pack maintainer, I want the clone credential kept out of the git remote URL, so that tokens are less likely to appear in process lists and logs.
10. As a pack maintainer, I want `install-on-cloud.sh` and `install-clark-agency.sh` to share one skills-install function, so that layout changes cannot diverge.
11. As a pack maintainer, I want Mac→Git push sync removed, so that the old mirror direction cannot fight the new SSOT.
12. As an agent user, I want one `/ship` entrypoint for verify, review, thermos, address-comments, and green-the-PR, so that I do not juggle five overlapping slash skills.
13. As an agent user, I want **Ship modes** (`gauntlet`, `review`, `thermos`, `address`, `green`), so that I can run a slice without always running the full green loop.
14. As an agent user, I want default `/ship` to mean `green`, so that “make this PR merge-ready” stays the common path.
15. As an agent user, I want Ship to be a thin router with mode docs in `references/<mode>.md` (not nested `SKILL.md`), so that Cloud recursive discovery does not register fake top-level skills.
16. As an agent user, I want Ship modes to be self-contained (no dependency on deleted `$check`, SprintFlow wrappers, or retired slash names), so that Cloud and laptop both work after the purge.
17. As an agent user, I want `/ship address` and `/ship green` to require explicit confirmation before push or merge, so that agents do not push without a latch.
18. As an agent user, I want old skill names gone with no aliases, so that muscle memory moves once and dual discovery cannot happen.
19. As a pack maintainer, I want keepers that exist only on the laptop imported into the repo before slim/purge, so that Seam 3 cannot pass on an empty promise.
20. As a laptop user, I want purge of migrated/deleted dirs only after local plugin smoke and a Cloud `/ship` receipt, so that I do not destroy the only working copy first.
21. As a laptop user, I want `clock-out`, `stop-slop`, `deep-research`, and `obsidian-vault` deleted from machine and pack (`obsidian-note` only if present), so that dead weight is gone; `stop-slop` delete does not imply deleting `slop`.
22. As a Cursor user, I want `handoff` in the keep set after deleting clock-out, so that mid-flight leave still has a skill.
23. As a pack maintainer, I want company-only and school-only skills excluded from the pack, so that Cloud and the private repo stay a personal daily OS.
24. As a pack maintainer, I want byte-identical mattpocock shadows excluded, so that I do not duplicate his plugin inside this pack.
25. As a pack maintainer, I want a machine-readable keep list (`pack.keep` or equivalent), so that inventory tests are generated from one authority.
26. As a pack maintainer, I want an archive git tag before slimming the historical dump, so that recovery does not depend on remembering a SHA.
27. As a pack maintainer, I want retired slash-name references scrubbed from kept skills, so that `/code-review` etc. do not linger after AD.
28. As a pack maintainer, I want `CONTEXT.md` and ADRs to describe SSOT, Cloud delivery, hybrid shape, `/ship`, and asymmetric layouts, so that future agents do not reverse the grill.
29. As a pack maintainer, I want README rewritten for the new model, so that I do not follow the old “Mac is SSOT” instructions.
30. As a developer opening another repo on Cloud, I want a documented snippet to wire the install script, so that new environments get the pack without reinventing clone auth.
31. As a pack maintainer, I want no secrets committed to the repo, so that the private pack stays safe to clone with a scoped read-only token.
32. As a future me, I want Uncle Bob CRAP / negative-test-experiment left out of this rebuild, so that this pass stays skills-pack + Cloud only.
33. As a pack maintainer, I want `.system/` absent from the Cloud skills tree, so that built-in skill names are not shadowed.
34. As a pack maintainer, I want large vendored junk (e.g. `__pycache__`, huge `last30days` assets) trimmed or gitignored, so that every Cloud Build is not a multi‑MB clone tax.

## Implementation Decisions

- Evolve existing private repo `jadenmaciel/cursor-cloud-home` in place. Do not create a second skills mirror.
- Flip SSOT from laptop `~/.cursor/skills` to this repo; update README; delete Mac→repo sync (`sync-cloud-home.sh` and related).
- **Plugin discovery (fixes ADR-0003 soft gap):** keep category folders for humans; set `.cursor-plugin/plugin.json` `"skills"` to an **array of category directories** (each category is one level of `skill/SKILL.md`), matching the manifest `string | array` schema. Smoke-test after `plugins/local` symlink that every keeper appears. Do not point a single `"./skills/"` string at a two-level tree and assume recursion (plugin loader ≠ user-skills recursive walk).
- **Local plugin install:** symlink repo root to `~/.cursor/plugins/local/<plugin-name>`. Do not keep a second copy under laptop `~/.cursor/skills` for pack skills after purge.
- **Cloud skills install:** harden `install-on-cloud.sh`:
  - `#!/usr/bin/env bash`
  - `SKILLS_PACK_SRC` override skips git (fixture/tests)
  - Sync into **pack-owned subtree** `$HOME/.cursor/skills/cursor-cloud-home/` (user-skills roots recurse — discovery works)
  - **Never** `rm -rf "$HOME/.cursor/skills"`
  - Missing token → **non-zero exit** (fail Build), not WARN-and-continue
  - Clone without putting the token in the remote URL (e.g. `GIT_ASKPASS` / header / `gh` — pick one in implement; document)
  - Idempotent; preserve an unrelated sentinel skill dir outside the pack subtree in tests
  - Do not run network tool installs (codegraph) when `SKILLS_PACK_SRC` is set; decide whether codegraph stays in Cloud install at all (pack drops codegraph skill — prefer remove or gate behind a flag)
- Share skills-install logic between `install-on-cloud.sh` and `install-clark-agency.sh` (one sourced function or shared script).
- **Ship:** thin router `SKILL.md` + `references/gauntlet.md`, `review.md`, `thermos.md`, `address.md`, `green.md` (no nested `SKILL.md` under ship). Modes self-contained; no deps on deleted skills or retired SprintFlow/`$check` wrappers. Re-home needed helpers/agents under `ship/`. Push/merge only after explicit user confirmation. Soft ceiling: prefer router under ~120 lines; mode detail in references. No alias stubs.
- **Import-before-slim:** copy from laptop `~/.cursor/skills` into the pack any keep-list name missing from the repo (at least: `grill-me`, `wait-what`, `writing-for-agents`, `x-research`, `day-sync`, `day-wrap`, `payday`, `ticket-start`, `repo-services`). Source of import = laptop path only for this pass.
- **Keep set (single authority — also emit `pack.keep`, one name per line):**  
  `grilling`, `grill-me`, `grill-with-docs`, `domain-modeling`, `to-spec`, `to-tickets`, `wayfinder`, `implement`, `prototype`, `ticket-start`, `ship`, `handoff`, `ponytail`, `i-have-adhd`, `wait-what`, `writing-for-agents`, `research`, `x-research`, `agent-reach`, `last30days`, `slop`, `day-sync`, `day-wrap`, `payday`, `standup`, `reflect-sessions`, `repo-onboard`, `repo-services`, `triage`, `wizard`, `improve-codebase-architecture`, `codeburn-optimize`, `notebooklm`, `notebooklm-setup`.  
  (`standup` stays unless dropped in implement with an explicit `pack.keep` edit.)
- **Delete set (pack + laptop after proof):** `gauntlet`, `code-review`, `pr-review`, `address-pr-comments`, `thermos`, `clock-out`, `stop-slop`, `deep-research`, `obsidian-vault`, and `obsidian-note` if present. Do not delete `slop` when deleting `stop-slop`.
- **Exclude from pack:** company/school/secrets-adjacent (e.g. `company-standard`, `security-review`, `study-notes`, `teach-course`, `scaffold-exercises`, epayment-*, `.system`, product built-ins).
- Tag `archive/full-dump` (or equivalent) on current HEAD **before** deleting non-keepers from `skills/`.
- Scrub kept skills for retired slash names (`/gauntlet`, `/code-review`, `/pr-review`, `/address-pr-comments`, `/thermos`).
- Purge laptop pack copies only after: (1) local plugin smoke shows keepers, (2) Cloud Build/`/ship` receipt recorded in Further Notes or a `docs/proof/` scrap. Optionally note `~/.claude/skills` / `~/.codex/skills` duplicates as a manual follow-up (not auto-purge this pass).
- Preserve `CONTEXT.md` vocabulary; ADRs 0001–0005 binding; amend ADR-0003 notes for skills-array discovery if needed during implement.
- Document consumer `environment.json` install snippet in README; rewriting every consumer repo is still optional follow-up.

## Testing Decisions

- Good tests assert **external behavior**: files present/absent, manifest parseable, install script outcome on a fixture — not prose quality of SKILL.md bodies. Every task `Test:` must use `&&` (not `;`) so failures propagate.
- Prefer shell/`test`/`jq`/`find` seams (AX); no new test framework.
- Seam 1 — Install: fixture with `SKILLS_PACK_SRC`; pack lands under `$HOME/.cursor/skills/cursor-cloud-home/`; pre-seeded unrelated skill **outside** that subtree survives; missing token exits non-zero when not in fixture mode.
- Seam 2 — Pack shape: plugin.json has `name` and `"skills"` **array** of category dirs; every `pack.keep` name has exactly one `SKILL.md`; ship tree has exactly one `SKILL.md`.
- Seam 3 — Inventory: every `pack.keep` name resolves; every delete-set name is absent under `skills/`; `.system` absent.
- Seam 4 — Glossary/ADRs still present and named.
- Seam 5 — Cloud proof (manual OK): one Cloud Agent run shows `/ship` (or ship in skill list) + install log line; evidence path recorded before laptop purge task is ticked.
- Prior art: `install-on-cloud.sh`; fit research `docs/research/skills-pack-rebuild-fit.md`; double-review Act-first (2026-08-20).

## Out of Scope

- Teams/Enterprise Team Marketplace Required plugins.
- Publishing to the public Cursor Marketplace.
- Automatic laptop↔Cloud sync of `~/.cursor` home.
- Uncle Bob CRAP / negative-test-experiment.
- Rebuilding or uninstalling mattpocock’s plugin.
- Auto-purging Claude/Codex skill trees (manual note only).
- Rewriting every consumer repo’s `environment.json` in this pass.
- Alias stubs for deleted slash names.
- Dropping the plugin shell for a skills-only symlink (considered in review; rejected for this pass — keep AF + skills-array fix).

## Further Notes

- Grill: Notion task [Custom Cursor skills…](https://app.notion.com/p/3c2ec3298ad18168b3c0c665e23aaf43).
- Research: `docs/research/skills-pack-rebuild-fit.md`; prior `Development/personal/.research/cursor-cloud-skills-sync.md`.
- Double-review (2026-08-20): architecture **right with fixes**; this patch absorbs Act-first blockers.
- Historical `skills/` dump will be slimmed after `archive/full-dump`.
- Token: dashboard only; prefer read-only, single-repo scope; document rotation in README.
