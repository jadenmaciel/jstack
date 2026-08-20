# Notion Daily (SSOT for day-sync + day-wrap)

Obsidian `Calendar/Daily` is retired. All daily note reads/writes go through Notion MCP.

## IDs

```
MCP_SERVER          = plugin-notion-workspace-notion
DAILY_DATA_SOURCE   = 2d70fa7c-7e1a-42b2-a6b5-39e8fdcc58ef
DAILY_DB_PAGE       = https://app.notion.com/p/85d499ec7b804e35b0dcb8a46083f449
DAILY_TEMPLATE_ID   = 3beec3298ad180e39b04cd609df388e7
DAILY_HUB           = https://app.notion.com/p/3bfec3298ad181b5aab7decee7f531af
VAULT_HOME          = https://app.notion.com/p/3beec3298ad181ed844ec3652b8e2a1f
TASKS_DATA_SOURCE   = 58ca1d7a-1674-49c2-995a-4907fa6d82cc
```

Call `GetMcpTools` for this server before the first `CallMcpTool` in a run.

## Page shape

Each day is **one row** in the Daily data source:

| Field | Role |
|-------|------|
| `Name` | `YYYY-MM-DD` |
| `date:Date:start` | same date (`is_datetime` = 0) |
| `Focus` | 1–3 line focus string (property) |
| `Source` | set `day-sync` / `day-wrap` when creating |

Do **not** put a `Tasks` relation on Daily. That makes truncated chips in properties — no clickable Done, “10 more…” hides the rest. Locked 2026-08-18: two clickable lists — **Work** (Area = Work) and **Personal** (everything else).

Assign work with **Task.Day → this Daily row** (one-way on Tasks; Daily schema stays Name / Date / Focus / Source only).

### Two checklists (locked UI)

Two **separate** linked lists on every Daily page. Same clickable Done checkbox. No overlap.

**`## Work`** — job only (`Area = Work`):

```
## Work
Job only (Area = Work). Tick **Done**. Set Area to Work to land here.
<database url="…" inline="true" data-source-url="collection://58ca1d7a-1674-49c2-995a-4907fa6d82cc"></database>
```

```
name: Tick Done
type: list
FILTER "Day" = "<this Daily page URL>"
FILTER "Area" = "Work"
SORT BY "Done" ASC
SHOW "Done", "Task", "Area", "Due"
```

**`## Personal`** — everything else (`Area != Work`: School, Housing, Finance, Health, Projects, Admin, …):

```
## Personal
Everything else. Tick **Done**.
<database url="…" inline="true" data-source-url="collection://58ca1d7a-1674-49c2-995a-4907fa6d82cc"></database>
```

```
name: Personal
type: list
FILTER "Day" = "<this Daily page URL>"
FILTER "Area" != "Work"
SORT BY "Done" ASC
SHOW "Done", "Task", "Area", "Due"
```

If a list is missing after create, add it the same turn (`notion-create-view` with `parent_page_id` and **type: list**, then move the `<database>` into the right heading). Never use type table for these Daily checklists. Preserve existing `<database url="…">` tags — do not delete children. Do **not** hide Done. Do **not** put both filters on one list.

Template (`@Today`) only has the headings. day-sync / day-wrap must add both filtered views per date.

Assign with **Task.Day** + **Area**. Area = Work → Work list; any other Area → Personal list. Markdown `- [ ]` only for a line that is not already a Task.

Body sections (Notion-flavored Markdown), keep this set:

```
## Today's focus
## Work
## Personal
## Log
## Ideas
```

Optional `## Calendar` may already exist — leave it unless the user asked to change it.
Never invent a Therapy section. If one appears, leave it byte-stable.
After a session: one Log bullet + `<mention-page>` to the session page under
Therapy. Do not copy session/intake prose onto Daily.

Before first Daily write in a session, fetch [Vault home](https://app.notion.com/p/3beec3298ad181ed844ec3652b8e2a1f) agent toggles if the hub map is needed.

## Open / create (`DATE`)

1. Query:

```sql
SELECT url, Name, Focus, "date:Date:start"
FROM "collection://2d70fa7c-7e1a-42b2-a6b5-39e8fdcc58ef"
WHERE "date:Date:start" = '<DATE>'
LIMIT 1
```

Use `notion-query-data-sources` with `data_source_urls: ["collection://2d70fa7c-…"]`.

2. If a row exists → `notion-fetch` that page URL/id. If `## Work` or `## Personal` is missing its Tick Done list, add it (locked UI). Then done.

3. If missing → `notion-create-pages` once:

```json
{
  "parent": {"type": "data_source_id", "data_source_id": "2d70fa7c-7e1a-42b2-a6b5-39e8fdcc58ef"},
  "pages": [{
    "template_id": "3beec3298ad180e39b04cd609df388e7",
    "properties": {
      "Name": "<DATE>",
      "date:Date:start": "<DATE>",
      "date:Date:is_datetime": 0,
      "Source": "day-sync|day-wrap"
    }
  }]
}
```

Template apply is async — wait briefly, then `notion-fetch`. If body sections are still empty, insert the section headings with `notion-update-page` `insert_content` / `replace_content` (preserve any children).

**No retry** on a successful create (duplicate rows). On error, stop and report.

## Merge rules

Use `notion-update-page`:

- **Focus property** — `command=update_properties` with `Focus` only when the user explicitly asked to change focus, or when seeding `$NEXT` focus from carry list (day-wrap only).
- **Body** — prefer `command=update_content` with exact `old_str`/`new_str` from the latest fetch. Append Log bullets under `## Log`. Flip `- [ ]` → `- [x]` under `## Work` / `## Personal` only for non-Task lines when evidence matches.
- Prefer marking the matching **Task** `Done = __YES__` (clickable checkbox in Tick Done). Fetch the Task first.
- Never uncheck without evidence.
- Do not rewrite whole-page prose; patch the smallest unique snippet.
- If `## Work` or `## Personal` is missing its list, add it (see locked UI above).
- If `## Work` / `## Personal` are empty `<empty-block/>`, replace that empty block with checkbox lists only for items that are not already Tasks.

### Tasks database

When inventory names a clear open action:

1. Fetch the matching Task if one exists. Set `Day` to this Daily row. Mark `Done = __YES__` when evidence says finished.
2. If none exists, `notion-create-pages` into Tasks (`Day` = this Daily URL, `Done` = `__NO__`). It then appears in Tick Done.
3. Do not create duplicate Tasks for the same action in one run.
4. Do **not** add a `Tasks` relation (or any dual relation) on the Daily data source. That restores chips.

## Carry / seed (`$NEXT`, day-wrap only)

1. Open/create `$NEXT` as above (`Source: day-wrap`). Ensure `$NEXT` has **both** Work (Area = Work) and Personal (Area != Work) Tick Done lists.
2. For still-open Tasks on `$DATE` that should move, set `Day` to `$NEXT` (they show in that day’s Tick Done). Do not copy them as markdown checkboxes.
3. Carry leftover **non-Task** `- [ ]` lines into `$NEXT` `## Work` / `## Personal` (dedupe).
4. Set `$NEXT` `Focus` property from top 1–3 carry items when Focus is empty.
5. Append one Log line on `$NEXT`: `Carried from <mention previous day page>.`
6. Do not copy `$DATE` Log/Therapy wholesale. Therapy body stays on the Therapy Area pages.

## Report links

In the chat report, link the Daily page URL from fetch/create (not an Obsidian path). Mention the [Daily hub](https://app.notion.com/p/3bfec3298ad181b5aab7decee7f531af) when helpful.
