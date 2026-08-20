# day-wrap — external writes

Run only after the daily note merge. Every Composio call needs `--account`.
Never `GMAIL_SEND_EMAIL`.

## Calendar create

Create only when the inventory has:

1. A short **title** (`summary`)
2. A **concrete start** — ISO datetime `YYYY-MM-DDTHH:MM:SS` (API rejects natural language)

All-day intent → use `DATE T00:00:00` and `end_datetime` next calendar day `T00:00:00` (or 24h duration). Skip vague “should schedule X.” Default timezone: `America/Denver`.

### Dedupe

Before create, search the same window:

```bash
$COMPOSIO execute GOOGLECALENDAR_FIND_EVENT --account "$GOOGLE_CALENDAR" -d '{
  "calendar_id": "primary",
  "query": "<summary keywords>",
  "time_min": "<window start>",
  "time_max": "<window end>",
  "single_events": true
}'
```

Skip if an event already matches **summary + start** (same day / same time).

### Create

```bash
$COMPOSIO execute GOOGLECALENDAR_CREATE_EVENT --account "$GOOGLE_CALENDAR" -d '{
  "calendar_id": "primary",
  "summary": "<title>",
  "start_datetime": "<YYYY-MM-DDTHH:MM:SS>",
  "end_datetime": "<YYYY-MM-DDTHH:MM:SS>",
  "timezone": "America/Denver",
  "description": "day-wrap"
}'
```

Record created `id` / link for the chat report. On re-run, FIND again — do not double-book.

## Gmail drafts

Tool: `GMAIL_CREATE_EMAIL_DRAFT` only.

Draft only when evidence shows a clear outbound need (reply owed, promised follow-up,
explicit “email X”). Pick `$GMAIL_PERSONAL` or `$GMAIL_PURELY` by which inbox owns the thread.

### Dedupe

Before create, fetch drafts / recent mail for that subject+to on `DATE`. Skip if an
open draft (or unsent) with the same **subject + recipient** already exists.

```bash
$COMPOSIO execute GMAIL_FETCH_EMAILS --account "<GMAIL_ACCOUNT>" -d '{
  "query": "in:drafts subject:\"<subject>\"",
  "max_results": 10,
  "verbose": false
}'
```

### Create draft

```bash
$COMPOSIO execute GMAIL_CREATE_EMAIL_DRAFT --account "<GMAIL_ACCOUNT>" -d '{
  "recipient_email": "<to>",
  "subject": "<subject>",
  "body": "<plain text>",
  "is_html": false,
  "thread_id": "<optional existing thread>"
}'
```

Never send. Report draft subject + account in chat.

## Candidate ledger

For each external candidate, leave one line in the report: `created` | `skipped:<reason>`.
Done when the ledger covers every candidate from synthesis.
