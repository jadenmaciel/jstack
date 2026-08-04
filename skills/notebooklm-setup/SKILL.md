---
name: notebooklm-setup
description: "Seed a project's NotebookLM corpus: create/reuse the project notebook, ingest docs, specs, research, and key URLs, then wire project docs to reference it. Use when the user wants NotebookLM set up for a project, asks to ingest a repo/project into NotebookLM, or says 'seed the corpus'."
allowed-tools:
  - Bash(notebooklm *)
  - Bash(bash /Users/testadmin/.codex/skills/notebooklm/scripts/*)
  - Bash(git *)
  - Bash(jq *)
  - Bash(rg *)
  - Bash(wc *)
  - Bash(head *)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# NotebookLM Project Setup

Seed one notebook per project so both agents query the corpus instead of re-reading the repo or re-researching. CLI reference, auth troubleshooting, parallel-safety rules: `~/.codex/skills/notebooklm/SKILL.md`. Always pass `-n <full notebook id>`; never `use`.

## Steps

### 1. Resolve notebook

Project name = git root basename, else `~/Development/<name>` segment, else ask. Reuse the handoff convention: title `<Project> — Research`.

```bash
notebooklm list --json | jq -r '.notebooks[] | select(.title=="<Project> — Research") | .id'
# none -> notebooklm create "<Project> — Research" --json | jq -r '.notebook.id'
```

An existing differently-titled project notebook (e.g. "<Project> — Project Knowledge Base") the user names wins over creating a new one. Done when: one notebook id in hand, echoed with its title and current source count (`notebooklm source list -n <id> --json | jq '.sources | length'`).

### 2. Inventory the seed

Read-only sweep of what the corpus should hold, ranked by knowledge value:

1. README, CLAUDE.md/AGENTS.md, CONTRIBUTING
2. docs/specs/, docs/adr/, openspec/specs/ (decisions and behavior — highest value per token)
3. `.research/*/` dirs (report.md + evidence URLs — ingest via publish.sh, not by hand)
4. Remaining docs/**/*.md, CHANGELOG
5. Key external URLs referenced by the docs (official specs, vendor docs)

Budget ≤40 sources total (free tier caps ~50/notebook; leave headroom for future research publishes — the count from step 1 spends the same budget). Over budget -> keep the highest rank, note what was cut. Done when: a source plan (paths + URLs + total count) is shown before any upload.

### 3. Privacy gate

Trust boundary — applies to every source in the plan, no exceptions:

- Never upload: secrets, `.env*`, keys/tokens/credentials, customer data, Obsidian vault content, private/local URLs.
- Work/client repos: ask before uploading file contents; default to public URLs only.
- When a doc embeds credentials or client identifiers inline, skip the file and say which.

Done when: every planned source passed the gate or was dropped with a reason.

### 4. Ingest

- Files: `notebooklm source add <path> -n <id> --title "<repo-relative-path>"` (md/txt upload as text sources).
- URLs: `notebooklm source add <url> -n <id>`.
- `.research/` dirs: `bash ~/.codex/skills/notebooklm/scripts/publish.sh <dir> --notebook <id>` (handles dedupe, throttle, report).
- `sleep 2` between manual adds; a failed source is one warning, keep going; a rate-limit error ("No result found for RPC ID") stops the run — report progress, do not retry-storm.

Done when: every planned source is added or individually warned, final count reported against the plan.

### 5. Exploit the notebook

`notebooklm summary -n <id>` — paste the AI summary as proof of a live corpus. Offer (generate only on request): audio overview, mind map, quiz, report (`notebooklm generate --help`).

### 6. Wire docs

- Project-root CLAUDE.md and AGENTS.md (create the file if the repo lacks it): one line — notebook title + id, `notebooklm ask -n <id> "<question>"` for project questions and Gemini-backed research help, check corpus before web research, publish new research via publish.sh.
- Other doc surfaces (README dev section, docs index): follow `~/.claude/reference/DOCUMENTATION_STANDARDS.md`; add at most one pointer, no essays.

Done when: both agent docs carry the routing line and any other doc edits are listed.

### 7. Receipt

Report: notebook id/title, sources added / skipped (with reasons), docs touched, and the top-up path — re-run this skill after major doc changes; URL sources refresh with `notebooklm source refresh`.
