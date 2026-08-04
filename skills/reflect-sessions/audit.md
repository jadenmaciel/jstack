# Audit

Full read-only audit of every Codex and Claude Code skill, plugin, MCP server, hook, and persistent instruction on this Mac that either affects session context or runs automatically.

This is a dry run. Do not modify, move, delete, or rename anything being audited. Do not install, uninstall, enable, or disable anything. Do not change permissions or configuration. The only allowed write location is:

`~/Downloads/agent-config-audit-YYYY-MM-DD/`

## Inventory

Codex:

- `~/.agents/skills`
- `~/.codex/skills` — this directory exists locally; verify separately whether the current setup actually loads it
- `~/.codex/config.toml`
- `~/.codex/plugins`
- `~/.codex/AGENTS.md` and `~/.codex/AGENTS.override.md`
- `.agents/skills`, `AGENTS.md`, `AGENTS.override.md`, and `.codex/config.toml` from the repo root down to the current working directory

Claude Code:

- `~/.claude/skills`
- `~/.claude/commands`
- `~/.claude/CLAUDE.md` and `~/.claude/rules`
- `~/.claude/settings.json`
- `~/.claude.json`
- `~/.claude/plugins`
- `CLAUDE.md`, `.claude/CLAUDE.md`, `CLAUDE.local.md`, and `.claude/rules` in the current project and applicable parent directories
- `.claude/skills`, `.claude/commands`, `.claude/settings.json`, `.claude/settings.local.json`, and `.mcp.json` in the current project

Resolution rules:

- Follow symlinks. Record both the entry path and the resolved path.
- Distinguish what the config marks as enabled or disabled from what is actually installed or available.
- Distinguish shared symlinks, duplicate copies, broken entries, and stale caches.
- If multiple entries resolve to the same canonical file, they are not duplicate content.
- Use plugin caches only to identify versions. Never recommend cleaning them.

## Analysis

Group everything by actual capability, then check for:

- duplicate or heavily overlapping behavior
- conflicting rules
- references to outdated models, APIs, paths, or commands
- dependencies that no longer exist
- global items that belong in a specific project
- skills that only add generic planning, reasoning, or checking, with no specialized workflow, scripts, examples, or failure boundaries
- low-use plugins, MCP servers, and hooks that stay enabled
- credentials stored in process arguments, literal headers, or configuration files — record presence and location only, never values
- approval, sandbox, permission, and trust settings whose combined effect removes safety boundaries

Do not mark a skill as useless because the model is stronger now. Keep project and domain knowledge, personal voice, safety and publishing boundaries, real failure lessons, working commands, scripts, templates, and assets. Keep current decisions and unfinished work.

## Labels

- Skills, commands, persistent instructions: `KEEP` / `MERGE` / `MOVE_TO_PROJECT` / `ARCHIVE` / `DELETE`
- Plugins, MCP servers: `KEEP_ENABLED` / `DISABLE` / `UNINSTALL`
- Hooks: `KEEP_ENABLED` / `MOVE_TO_PROJECT` / `DISABLE` / `DELETE`

When uncertain, choose `ARCHIVE`, `DISABLE`, or `NEEDS_DECISION`. Use `DELETE` and `UNINSTALL` only for items that are fully duplicated, broken, empty, or confirmed to have no recovery value.

## Outputs

Write three files into `~/Downloads/agent-config-audit-YYYY-MM-DD/`.

**`report.html`**

- one offline file, no external resources and no network requests
- first screen shows totals, enabled, disabled, duplicates, archive, delete, and needs-decision
- opens with a short prose summary of the setup and the 5 to 10 highest-priority findings
- includes a Codex vs Claude Code capability comparison, a searchable and filterable decision table, merge relationships, the archive plan, the plugin/MCP/hook inventory, permission rules, and items needing a human decision
- each item shows path, current state, overlaps, recommendation, reason, target path, risk, confidence, and recovery method
- prints cleanly and exports to PDF from the browser

**`plan.json`**

Same structured decisions and evidence as the HTML, keyed for later execution by ID. Each item carries: ID, name, Harness, Scope, type, entry path, resolved path, current state, overlaps and conflicts, recommended action, reason, target path, risk, confidence, evidence, recovery method.

**`summary.md`**

One page. Current state, the 5 highest-priority items, the main keep and archive recommendations, and the decisions still needed.

## Reply

When the audit finishes, reply with exactly four lines and nothing else:

1. absolute path to `report.html`
2. absolute path to `plan.json`
3. absolute path to `summary.md`
4. one sentence containing the single most important finding

## Built-in checks (Claude Code)

Claude Code has a faster built-in pass the user can run by hand. Name these when the audit lands, or when the user wants a quick look instead of a full audit:

- `/context` — breaks down what is using context in the current session, so the largest category is visible at once
- `/doctor` — checks installation and configuration problems, invalid settings, duplicate installations, unused extensions, and `CLAUDE.md` content derivable straight from the code; it proposes fixes and applies them only after the user confirms
- `/skills`, `/mcp`, `/hooks`, `/permissions` — inspect each area on its own

These are interactive commands for the user to run. Do not run them on the user's behalf.

## Disabling a Codex skill without deleting it

Codex can disable a skill in place. This is the supported disable and recovery method for every Codex-skill `DISABLE` recommendation.

Add to `~/.codex/config.toml`:

```toml
[[skills.config]]
path = "/absolute/path/to/skill/SKILL.md"
enabled = false
```

Restart Codex for the change to take effect. To restore the skill, delete this block and restart Codex again.

First confirm that `path` points to the actual `SKILL.md`. If the entry is a symlink, record its resolved path in the audit report too.
