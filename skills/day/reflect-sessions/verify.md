# Verify

Run another read-only scan of the skills, commands, plugins, MCP servers, hooks, and persistent instructions for Codex and Claude Code, using the inventory in [`audit.md`](audit.md).

## Compare against the original `plan.json`

1. Counts per category, before and after cleanup.
2. Which duplicate entries are gone.
3. Which items moved from global scope into a repo.
4. Which items are archived or disabled.
5. Any broken symlinks, invalid references, configuration parse errors, or missing dependencies.
6. Which changes require a restart or new session, and whether the expected skills, plugins, and MCP servers appear afterward.
7. Whether every unapproved item stayed unchanged.
8. Whether MCP health checks pass after authentication changes.
9. Whether each SessionStart reminder fires exactly once per matching event.
10. Whether any report, backup, or archive holds credential material not confirmed invalidated. Record its location only, never the value.
11. Whether managed plugin caches and install staging stayed unchanged.
12. Whether every approved human decision was preserved.

## rollback-index.md

Write it to the audit directory:

```
Action ID | Original path or state | Current path or state | One-step recovery method | Restart required
```

If verification fails, stop the cleanup. List the failed action IDs, the affected human decisions, and the exact recovery steps. Wait for the user's approval before rolling anything back.
