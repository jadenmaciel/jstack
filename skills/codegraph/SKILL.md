---
name: codegraph
description: Use CodeGraph for local semantic code intelligence, repository indexing, impact analysis, symbol/call graph exploration, and Codex MCP setup/verification.
metadata:
  short-description: Semantic code graph CLI and MCP workflow
---

# CodeGraph

Use when the user asks for CodeGraph, semantic code intelligence, call graphs,
impact analysis, affected tests, repository indexing, or to install/verify the
CodeGraph integration.

## Integration

- CLI launcher: `/Users/testadmin/.local/bin/codegraph`
- Bundle root: `/Users/testadmin/.codegraph/current`
- Codex MCP config: `/Users/testadmin/.codex/config.toml`
- Expected Codex MCP block:

```toml
[mcp_servers.codegraph]
command = "/Users/testadmin/.local/bin/codegraph"
args = ["serve", "--mcp"]
```

Codex must be restarted for newly configured MCP tools and newly added skills to
appear in the active tool/skill list.

## Workflow

1. Prefer the MCP tools when they are available in the active session.
2. If MCP tools are not loaded yet, use the CLI directly:
   - `/Users/testadmin/.local/bin/codegraph --version`
   - `/Users/testadmin/.local/bin/codegraph init -i <repo>`
   - `/Users/testadmin/.local/bin/codegraph index <repo>`
   - `/Users/testadmin/.local/bin/codegraph status <repo>`
3. Initialize a repository only when the user asks, when CodeGraph is needed for
   the current repo task, or when safe local setup is clearly implied.
4. Keep `.codegraph/` project-local. Do not commit it unless the repository
   explicitly tracks it.
5. For code-review or debugging tasks, use CodeGraph to find symbols, callers,
   callees, routes, and blast radius, then verify important claims against
   source files before finalizing.

## Verification

Report the exact checks run. Good minimum checks:

```bash
/Users/testadmin/.local/bin/codegraph --version
sed -n '/\[mcp_servers\.codegraph\]/,/^\[/p' /Users/testadmin/.codex/config.toml
```

If tool loading cannot be verified in the current session, say that a Codex
restart is still required.
