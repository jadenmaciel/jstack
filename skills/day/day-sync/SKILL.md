---
name: day-sync
description: >-
  day-sync mid-day progress into today's Notion Daily row (check off
  Work/Personal, append Log). Use when a ticket shipped, a school/coding session
  finished, or the user asks to sync or update today's daily mid-day. Defaults to
  today in America/Denver; optional freeform $ARGUMENTS are evidence. Scope stops
  at today's Daily page — leave next-day seed and day-ops to day-wrap.
argument-hint: "[optional evidence — e.g. finished TROUT-736 / coding session 2]"
---

# day-sync

Fold **today's** evidence into the Notion **Daily** row. Mid-day sibling of
`day-wrap`: same page shape, no next-day seed, no day-ops.
No grill gate — run on invoke.

## Config

SSOT for Notion Daily open/create/merge:
[`day-wrap/references/notion-daily.md`](../day-wrap/references/notion-daily.md)

```
DEV_ROOT = /Users/testadmin/Development
TZ       = America/Denver
```

No Composio. Mail and calendar stay on `day-wrap`. Do **not** write Obsidian daily notes.

## Off-limits

Never write or rewrite: **Therapy** sections, **Secrets**, meds/health, relationship
processing. Personal = errands / logistics / non-therapy life only.

Therapy SSOT is the Notion Therapy Area. After a session: one Daily **Log** line
plus a mention-link to the session page — no session/intake body on Daily.

## Steps

### 1. Date

`DATE` = `$ARGUMENTS` leading `YYYY-MM-DD` if present, else **today** in `TZ`
(`date +%Y-%m-%d`). Freeform text after a date (or the whole `$ARGUMENTS` when
there is no date) is **prompt evidence** — treat it as primary inventory.
Done when one `DATE` is locked.

### 2. Open / create Daily row

Follow **Open / create** in
[`notion-daily.md`](../day-wrap/references/notion-daily.md) for `DATE`.
Fetch the full page (properties + body) into context.
Done when the Daily page exists and its contents are in context.

### 3. Gather

Inventory for `DATE` only (`TZ`), three buckets — prompt, sessions, git — and
name empty ones. Prefer prompt evidence when the user named what finished.

1. **Prompt** — freeform `$ARGUMENTS` / chat claims (ticket keys, “coding session
   2 done”, school milestone). Highest trust for checkbox flips.
2. **Sessions** — Cursor / Claude / Codex for `DATE`: follow
   [`day-wrap/references/sources.md`](../day-wrap/references/sources.md)
   Cursor + Claude + Codex sections only. Titles + one-line outcomes; no UUID /
   `.jsonl` / absolute transcript paths in the Daily page.
3. **Git** — commits under `$DEV_ROOT` for `DATE`: same sources.md Git section.

Skip Gmail and Calendar. Redact secrets/tokens.
Done when the inventory exists.

### 4. Synthesize

Map inventory → Task.Done (preferred), leftover Work/Personal markdown, Log lines.
Tag each item `keep` / `skip(off-limits)` / `already-in-note`.

Mark a Task `Done = __YES__` when evidence matches (ticket key, PR number, named
item). Markdown `- [ ]` only for lines that are not Tasks. Ambiguous match → Log
line, leave Done unchecked.
Done when every inventory item has one tag.

### 5. Merge

Update the Daily page in place via Notion MCP (see **Merge rules** in
[`notion-daily.md`](../day-wrap/references/notion-daily.md)):

- If `## Work` or `## Personal` is missing its Tick Done list, add it (see
  notion-daily.md locked UI). Never add a Daily `Tasks` relation.
- Mark matching Tasks Done when tagged `keep`.
- **Append** new Log bullets under `## Log` — do not rewrite existing prose.
- Light polish only on touched lines: short clear bullets, project `###` headings
  stay.
- Keep section set: Today's focus / Work / Personal / Log / Ideas.
  Leave Therapy (and any other off-limits block) byte-stable.
- Do **not** edit the `Focus` property or `## Today's focus` unless the user
  explicitly asked.
- Do **not** create `$NEXT` or touch any other Daily row.

Done when allowed sections match synthesis and off-limits blocks are unchanged.

### 6. Report

Chat only:

- Notion Daily URL for `DATE`
- Checkboxes flipped (count + short list)
- Log lines appended (count)
- Empty gather buckets (if any)
- One concrete Next

No transcript dumps. Done when the report is printed.

## Out of scope

Next-day seed, calendar create, Gmail drafts/send, school Gmail, grill gate,
inventing tickets not in the inventory, rewriting Therapy / Secrets, Obsidian
daily files.
