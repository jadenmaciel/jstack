---
name: day-wrap
description: >-
  day-wrap a named calendar day into the Notion Daily row, seed tomorrow's Daily
  with unfinished work, and light day-ops (calendar + Gmail drafts). Use when
  wrapping or catching up a finished day, carrying todos into the next Daily,
  asking what you did on a date, or end-of-day digest of sessions/email/calendar
  into Notion Daily. Requires an explicit YYYY-MM-DD (or $ARGUMENTS); never
  assume today.
argument-hint: YYYY-MM-DD
---

# day-wrap

Fold one calendar day's evidence into the Notion **Daily** row, seed **tomorrow's**
Daily with leftovers, then light day-ops (calendar events + Gmail drafts).
Mid-day checkbox sync is `day-sync`. No grill gate — run on invoke.

## Config (EDIT THIS — single source of truth)

Notion Daily IDs + open/create/merge:
[`references/notion-daily.md`](references/notion-daily.md)

```
COMPOSIO        = /Users/testadmin/.composio/composio
GMAIL_PERSONAL  = gmail_scoria-sunlet    # jadenmacielshapiro@gmail.com
GMAIL_PURELY    = gmail_briner-lame      # contact@getpurelyapp.com
# school suumail: out of scope
GOOGLE_CALENDAR = googlecalendar_sook-ayu
DEV_ROOT        = /Users/testadmin/Development
TZ              = America/Denver
```

Always pass `--account` on every Composio call. Do **not** write Obsidian daily notes.

## Off-limits

Never write or rewrite: **Therapy** sections, **Secrets**, meds/health, relationship
processing. Personal = errands / logistics / non-therapy life only.

Therapy SSOT is the Notion Therapy Area. After a session: one Daily **Log** line
plus a mention-link to the session page — no session/intake body on Daily.

## Steps

### 1. Date

Lock one `YYYY-MM-DD` from `$ARGUMENTS` or the prompt. Missing → ask once, recommend
**today** in `TZ` (`date +%Y-%m-%d`), and stop until they reply with a date.
Done when one date `DATE` is locked.

### 2. Open / create Daily row

Follow **Open / create** in [`references/notion-daily.md`](references/notion-daily.md)
for `DATE`. Fetch the full page into context.
Done when the Daily page exists and its contents are in context.

### 3. Gather

Read [`references/sources.md`](references/sources.md). Collect evidence for `DATE`
only (local `TZ`). Build a short inventory with four buckets — sessions, git, mail,
calendar — and name empty buckets. Redact secrets/tokens.
Done when the inventory exists.

### 4. Synthesize

Map inventory → Work checkboxes, Personal bullets, Ideas, Log lines. Tag each item
`keep` / `skip(off-limits)` / `already-in-note`.
Done when every inventory item has one tag.

### 5. Merge + polish

Update the Daily page in place (Notion MCP — **Merge rules** in
[`notion-daily.md`](references/notion-daily.md)):

- If `## Work` or `## Personal` is missing its Tick Done list, add it (see
  notion-daily.md locked UI). Never add a Daily `Tasks` relation.
- Mark matching Tasks Done when evidence supports done.
- **Append** new bullets under Log / Ideas — do not rewrite existing prose.
- Light polish: dedupe Log, short clear bullets.
- Keep section set: Today's focus / Work / Personal / Log / Ideas.
  Leave Therapy (and any other off-limits block) byte-stable.

Done when allowed sections match synthesis and off-limits blocks are unchanged.

### 6. Seed next day

`NEXT` = calendar day after `DATE` (local `TZ`).

Open/create `$NEXT` via [`notion-daily.md`](references/notion-daily.md)
(`Source: day-wrap`). Follow **Carry / seed** there.

Build a **carry list** from the wrapped `$DATE` page + inventory:

- Still-open Tasks on `$DATE` (set `Day` → `$NEXT` so they appear in Tick Done)
- Every still-open **non-Task** Work / Personal checkbox (`- [ ] …`)
- Clear unfinished outcomes from sessions/git (not yet a Task)
- Mark stalled items briefly when useful: `*(not started $DATE)*`, `**parked until …**`
- Skip: Done Tasks, `- [x]` markdown, Ideas (unless clearly actionable tomorrow), Therapy /
  Secrets / meds / relationship / boundary reminders

Write into `$NEXT` (dedupe — skip lines already present):

1. **Work** — Tick Done list, `Area = Work`, filtered to `$NEXT`
2. **Personal** — Tick Done list, `Area != Work`, filtered to `$NEXT`. Carry still-open Tasks via `Day` + `Area`.
3. **Focus** property — 1–3 highest-priority carry items when empty
4. **Log** — one carried-from mention of `$DATE`'s page
5. Optional footer mentions: Vault home + `$DATE` page (Notion mentions, not `[[wikilinks]]`)

Do not copy `$DATE` Log/Therapy prose wholesale. Do not invent new tickets.
Done when `$NEXT` exists and every carry item is present or skipped-as-duplicate.

### 7. External writes

Read [`references/external-writes.md`](references/external-writes.md). Create calendar
events and Gmail drafts per those rules; skip duplicates with a reason.
Done when every candidate is created or skipped-with-reason.

### 8. Report

Chat only:

- Notion Daily URL (`$DATE`)
- Next Daily URL (`$NEXT`) + how many items carried
- Work / Personal / Log deltas on `$DATE` (short)
- Calendar events created (or none)
- Email drafts created (or none)
- One concrete Next

No transcript dumps. Done when the report is printed.

## Out of scope

Email Send, school Gmail, grill gate, cron, inventing facts not in the inventory,
Obsidian daily files.
