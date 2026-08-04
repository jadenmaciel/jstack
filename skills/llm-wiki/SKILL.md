---
name: llm-wiki
description: Proactively inspect the filesystem-first LLM Wiki and Obsidian knowledge vault for broad plans, prior decisions, agent workflows, architecture, SprintFlow, repo-memory, and current-state questions.
allowed-tools:
  - Bash
  - Read
---

# LLM Wiki

LLM Wiki is installed as an external source/app surface, not vendored into Codex.

- Source: `~/Projects/knowledge-tools/llm_wiki`
- Version: `v0.4.7`
- macOS ARM DMG: `~/Projects/knowledge-tools/releases/LLM.Wiki_0.4.7_aarch64.dmg`
- Release hash: `bed6a74852754e3ed67069c367c15fd52d909a76eeee80feeb2d3455cc4f5543`

## Common Tasks

```bash
codex-knowledge status
sed -n '1,160p' /Users/testadmin/Documents/Obsidian/Codex-Knowledge/hot.md
sed -n '1,160p' /Users/testadmin/Documents/Obsidian/Codex-Knowledge/index.md
rg -n "keyword" /Users/testadmin/Documents/Obsidian/Codex-Knowledge
open -g ~/Projects/knowledge-tools/releases/LLM.Wiki_0.4.7_aarch64.dmg
open -gja "LLM Wiki"
rg -n "keyword" <wiki-root>/wiki <wiki-root>/raw
```

## Operating Rules

- Treat LLM Wiki projects as user knowledge bases with immutable `raw/sources/` and generated `wiki/` pages.
- Use this skill proactively, without waiting for explicit invocation, for broad/ambiguous work, prior decisions, agent integration, SprintFlow routing, architecture, repo-memory, and current-state questions.
- Start with the shared vault: `/Users/testadmin/Documents/Obsidian/Codex-Knowledge/hot.md`, `index.md`, then `rg` relevant keywords.
- Keep proactive lookup read-only and lightweight. Do not run `codex-knowledge sync` unless the user asks or the workflow is at `$close`.
- Inspect `purpose.md`, `schema.md`, `wiki/index.md`, and `wiki/overview.md` before summarizing a wiki project.
- When syncing into LightRAG, ingest summaries and integration notes, not whole private source trees unless the user asks.
- Keep LLM Wiki code and app artifacts in `~/Projects/knowledge-tools/`.
