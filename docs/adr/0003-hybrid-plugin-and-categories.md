# Hybrid plugin shell + categorized skills

Shape the pack like Cursor `pstack` (root `.cursor-plugin/plugin.json` + `skills/`) and Matt Pocock’s catalog (category folders under `skills/`). Local uses the plugin loader; Cloud syncs into a pack-owned subtree under `~/.cursor/skills/` (recursive user-skills discovery).

**Discovery constraint:** Cursor plugin skill roots are not the same as user-skills recursive walk. Do not set `"skills": "./skills/"` on a two-level `skills/<category>/<skill>/` tree and assume every skill loads. Use a `"skills"` **array of category directories** (each category is one level of `skill/SKILL.md`), then smoke-test after `plugins/local` symlink.

Rejected: skills-only tree without a plugin manifest; single-string skills root over nested categories without an array; nested `SKILL.md` files under `ship/references/` (would dual-register on Cloud).
