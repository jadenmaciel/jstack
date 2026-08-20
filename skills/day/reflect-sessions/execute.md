# Execute

Execute only the action IDs the user explicitly approved.

```
Approved action IDs: {for example A-001, A-004, A-009}

Approved human decisions:
- Language: {follow current language / default English / default Chinese}
- Primary browser: {choice}
- Video stack: {choice}
- Always-on tools: {for example 21st}
```

Explicit human decisions override conflicting recommendations in `plan.json`. If an approved decision cannot be mapped to an action ID, stop and ask before changing anything.

Touch no file, configuration, skill, plugin, MCP server, hook, or permission rule whose ID is not listed.

## Before starting

1. For credential-related actions, stop until the old credential has been rotated or invalidated. Only then back up the old configuration. Never place a still-valid credential in the archive.
2. Resolve every path and symlink target again.
3. Back up every affected configuration file.
4. Create a dated archive directory for file moves, under the audit directory.
5. List the exact actions about to run. If the current state differs from the report, stop immediately.

## During execution

- `MERGE`: preserve the destination's existing content and merge only the approved unique rules, scripts, templates, and examples. Do not merge on matching names or hashes alone. Preserve intentional harness adapters, generated entry points, and same-name variants with different behavior.
- `MOVE_TO_PROJECT`: move the item to the approved repo path and repair only the references already confirmed.
- `ARCHIVE`: preserve the original directory structure and source record.
- `DISABLE`: use the tool's supported configuration method — for Codex skills, the `[[skills.config]]` block in [`audit.md`](audit.md). Do not edit an installation directory by hand.
- `DELETE` / `UNINSTALL`: execute only explicitly approved IDs.
- Leave plugin caches alone.
- Change no secrets, authentication data, or unrelated permissions.

After each action, record its ID, original path, target path, change, verification result, and recovery method. Stop on any conflict, missing reference, or need for an unapproved change. Do not expand the scope.
