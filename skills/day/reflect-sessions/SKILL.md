---
name: reflect-sessions
description: Audit Codex and Claude Code skills, plugins, MCP servers, hooks, and persistent instructions into read-only reports; reflect on session transcripts for setup leverage; then run the challenge, approved-execute, and verify lifecycle.
---

# Reflect Sessions

Diagnose leverage and inventory the setup. Change nothing except what the user approves by ID.

## Phases

Route on the prompt. Read only the file for the phase you are running.

| Prompt says | Phase | Read |
| --- | --- | --- |
| nothing, `reflect`, `audit`, `cleanup` | Audit, then reflect | [`audit.md`](audit.md), then [`reflect.md`](reflect.md) |
| `preinstall`, or names an item to install/enable | Pre-install check | [`preinstall.md`](preinstall.md) |
| `challenge` | Challenge every removal call | [`challenge.md`](challenge.md) |
| `execute`, with approved action IDs | Execute approved actions | [`execute.md`](execute.md) |
| `verify`, `recount`, `rollback index` | Recount and roll-back index | [`verify.md`](verify.md) |

Default run: the audit produces the reports, then the reflection runs and its findings become the usage evidence behind every `DISABLE` and `UNINSTALL` call in the audit. A phase past the default runs only when the prompt names it.

## Safety

- Every phase is read-only against the items it inspects. Only `execute` writes, and only for action IDs the user approved by number.
- Write locations, by phase:
  - audit and verify: `~/Downloads/agent-config-audit-YYYY-MM-DD/` only.
  - reflect: `reflection-notes.md` in the current directory, unless the user names another output path.
  - preinstall and challenge: no files; the output is the reply.
  - execute: the approved targets, plus backups and archive under the audit directory.
  - any phase: scratch files in the session's own temp directory, when they only build the deliverables above.
- Do not create, edit, delete, rename, move, install, uninstall, enable, or disable any skill, command, workflow, automation, hook, plugin, MCP server, config, or permission rule outside an approved action ID.
- For any key, token, cookie, auth, header, or env field: record the field name and its location. Do not read, display, or copy the value.
- Do not generate bulk deletion commands. Do not touch managed plugin caches or install staging.
- Redact secrets, credentials, private third-party data, raw logs, and long transcript excerpts.
- Cite transcript sources by date, runtime, and a non-path label; omit UUIDs, `.jsonl` filenames, and absolute paths.
- Do not read old-account paths under `/Users/jadenmaciel-shapiro/**`.
