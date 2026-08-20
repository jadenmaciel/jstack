# Challenge

Read `report.html` and `plan.json` from the audit directory. Argue against every `MERGE`, `MOVE_TO_PROJECT`, `ARCHIVE`, `DELETE`, `DISABLE`, and `UNINSTALL` recommendation. Look specifically for anything the first audit could damage.

This phase is read-only. Modify no files.

## Check each item

1. Whether another skill, command, hook, plugin, MCP server, or project file references it.
2. Whether it contains scripts, templates, assets, examples, or failure boundaries that exist nowhere else.
3. Whether a symlink points two tools at the same canonical copy.
4. Whether a cache was mistaken for an active item.
5. Whether an apparently global item is still used by multiple repos.
6. Which real workflow would break if the item were disabled, archived, or uninstalled.
7. Whether the rollback path actually exists.
8. Whether matching names or content hashes are intentional harness adapters, generated entries, or genuinely replaceable physical copies.
9. Whether a `DISABLE` or `UNINSTALL` recommendation rests on real usage evidence. If usage is unknown, revise it to `NEEDS_DECISION`.

Missing usage data is not evidence that an item is unused.

## Output

One row per item:

```
ID | Original recommendation | Counter-evidence | Revised recommendation | Risk | Confidence
```

When evidence is weak, revise to `ARCHIVE`, `DISABLE`, or `NEEDS_DECISION`.
