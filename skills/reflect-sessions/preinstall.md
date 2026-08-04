# Pre-install check

Run this read-only check before installing or enabling any skill, plugin, or MCP server.

State the subject first:

```
Item: {name or URL}
Target: {Codex / Claude Code / both}
Scope: {global / repo path}
```

## Check

1. Whether a similar capability already exists locally. List its name, path, and overlap.
2. Which unique rules, scripts, templates, assets, or tools the new item adds.
3. Whether it belongs globally or inside a project.
4. Which descriptions, tool definitions, hooks, or persistent instructions stay loaded or enabled after installation.
5. Whether its dependencies, commands, and paths exist on this machine.
6. Which file becomes the single source of truth after installation, and how to disable, archive, and restore it.
7. For a plugin or MCP server, where authentication is stored. Flag credentials in process arguments, literal headers, or configuration files. Record only the field name and location, never the value.
8. Whether the plugin or MCP health check passes in a normal interactive session.

## Decision

Return exactly one:

- `INSTALL_GLOBAL`
- `INSTALL_PROJECT`
- `KEEP_DISABLED`
- `MERGE_WITH_EXISTING`
- `SKIP`

Give one specific reason. Install, enable, or edit nothing until the user confirms.
