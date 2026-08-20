# Tasks — Skills pack rebuild

Spec: `./spec.md`

Rule: tick `- [x]` only after the code is written AND its `Test:` command passes
on the current tree. A ticked box with no passing test is a defect.

- [x] Rewrite README for repo-SSOT, local plugin symlink, Cloud pack-subtree install + token hygiene; remove Mac-is-SSOT language
  - Test: `rg -q "Local plugin install" README.md && rg -q "Cloud skills install" README.md && rg -q "CURSOR_CLOUD_HOME_TOKEN" README.md && ! rg -q "SSOT on Mac" README.md`

- [x] Add `pack.keep` (one skill name per line = keep-set authority) and `.cursor-plugin/plugin.json` with `"skills"` as an **array of category dirs**
  - Test: `test -f pack.keep && jq -e '.name and (.skills | type == "array" and length > 0)' .cursor-plugin/plugin.json >/dev/null`

- [x] Tag archive before slim: `git tag archive/full-dump` on pre-slim HEAD (create tag if missing)
  - Test: `git rev-parse -q --verify refs/tags/archive/full-dump >/dev/null`

- [x] Import missing keepers from `~/.cursor/skills` into pack categories (at least the nine named in the spec)
  - Test: `missing=0; while IFS= read -r n; do [ -z "$n" ] && continue; find skills -type d -name "$n" | grep -q . || missing=1; done < pack.keep; test "$missing" -eq 0`

- [x] Author thin `ship/SKILL.md` router + `references/{gauntlet,review,thermos,address,green}.md` (no nested `SKILL.md` under ship); self-contained modes; confirm-before-push
  - Test: `ship=$(find skills -type d -name ship | head -1) && test -n "$ship" && test -f "$ship/SKILL.md" && test "$(find "$ship" -name SKILL.md | wc -l | tr -d ' ')" -eq 1 && for m in gauntlet review thermos address green; do test -f "$ship/references/$m.md"; done && rg -q "confirm" "$ship/SKILL.md" "$ship/references/green.md" "$ship/references/address.md"`

- [x] Slim pack to `pack.keep`; remove delete-set and non-keepers; ensure `.system` gone from `skills/`
  - Test: `! find skills -type d \( -name gauntlet -o -name code-review -o -name pr-review -o -name address-pr-comments -o -name thermos -o -name clock-out -o -name stop-slop -o -name deep-research -o -name obsidian-vault -o -name .system \) | grep -q . && while IFS= read -r n; do [ -z "$n" ] && continue; find skills -type d -name "$n" | grep -q . || exit 1; done < pack.keep`

- [x] Scrub kept skills for retired slash names
  - Test: `! rg -q '/(gauntlet|code-review|pr-review|address-pr-comments|thermos)\b' skills --glob '!**/ship/**'`

- [x] Delete Mac→repo sync artifacts; document `git push` as sync
  - Test: `! test -f sync-cloud-home.sh && ! test -e "$HOME/.cursor/bin/sync-cloud-home.sh" && rg -q "git push" README.md && ! rg -q "sync-cloud-home" README.md`

- [x] Harden shared install: shebang, `SKILLS_PACK_SRC`, pack subtree `~/.cursor/skills/cursor-cloud-home/`, no full wipe, token not in URL, fail without token (non-fixture), share logic with `install-clark-agency.sh`
  - Test: `tmpdir=$(mktemp -d) && mkdir -p "$tmpdir/pack/skills/align/ship/references" "$tmpdir/out/.cursor/skills/unrelated-sentinel" && printf '%s\n' '---' '# ship' >"$tmpdir/pack/skills/align/ship/SKILL.md" && touch "$tmpdir/out/.cursor/skills/unrelated-sentinel/SKILL.md" && HOME="$tmpdir/out" SKILLS_PACK_SRC="$tmpdir/pack" ./install-on-cloud.sh && test -f "$tmpdir/out/.cursor/skills/cursor-cloud-home/align/ship/SKILL.md" && test -f "$tmpdir/out/.cursor/skills/unrelated-sentinel/SKILL.md" && ! HOME="$tmpdir/out" env -u SKILLS_PACK_SRC -u CURSOR_CLOUD_HOME_TOKEN ./install-on-cloud.sh`

- [x] Local symlink into `~/.cursor/plugins/local/<name>`; smoke that plugin/keepers load (document proof in `docs/proof/local-plugin.md`)
  - Test: `name=$(jq -r .name .cursor-plugin/plugin.json) && test -L "$HOME/.cursor/plugins/local/$name" && test -f docs/proof/local-plugin.md`

- [x] Cloud proof before laptop purge: record Build/install log + `/ship` visible in `docs/proof/cloud-ship.md`
  - Test: `test -f docs/proof/cloud-ship.md && rg -q "/ship|ship" docs/proof/cloud-ship.md`

- [x] Purge migrated/deleted dirs from laptop `~/.cursor/skills` (after proof tasks pass)
  - Test: `for n in gauntlet code-review pr-review address-pr-comments thermos clock-out stop-slop deep-research obsidian-vault; do test ! -e "$HOME/.cursor/skills/$n"; done && while IFS= read -r n; do [ -z "$n" ] && continue; test ! -e "$HOME/.cursor/skills/$n"; done < pack.keep`

- [x] Confirm glossary + ADRs still match
  - Test: `rg -q "Skills pack" CONTEXT.md && rg -q "Ship mode" CONTEXT.md && rg -q "Cloud home token" CONTEXT.md && test -f docs/adr/0004-ship-replaces-five-skills.md && test -f docs/adr/0005-asymmetric-local-cloud-layout.md`
