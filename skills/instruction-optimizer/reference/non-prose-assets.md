# Non-prose asset profiles

The prose path (SKILL.md, CLAUDE.md, AGENTS.md, references) is the default and the only one `score.py` fully covers. Two classes need a different gate.

## config (MCP / plugin JSON or TOML)

- Class `config`. Set `parse: "json"` or `parse: "toml"` in `rubric.json`; `require_frontmatter: false`.
- `score.py` runs the stdlib parser (`json` / `tomllib`). A candidate that fails to parse is FAIL regardless of size.
- `must_keep` = every semantically required key/value: server commands, env var names, model ids, permission flags, allow/deny entries. Reformatting whitespace is fine; dropping or renaming a key is not.
- Yield is low here (mostly whitespace/comment trimming). Only run config assets the inventory shows as genuinely bloated.

## script (.workflow.js / .mjs)

- Class `script`. `require_frontmatter: false`, `parse: "none"`.
- meta-presence is a substring gate: put `export const meta` (plus any required meta keys, e.g. `name`, `description`) in `must_keep`.
- Add the parse check `score.py` can't do: in the run, `node --check <candidate>` must pass. A candidate that fails `node --check` is ineligible.
- Trim comments and dead narration only; never touch control flow, agent prompts, or phase logic. Lowest-priority class -- do all prose first.
