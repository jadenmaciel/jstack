# day-wrap — sources

Gather for `DATE` only (`TZ` from SKILL.md). Prefer titles + one-line outcomes over
quotes. Cite sessions by project label + date — never paste UUIDs, `.jsonl` paths, or
absolute transcript paths into the daily note.

## Cursor

Roots: `~/.cursor/projects/*/agent-transcripts/`

```bash
# files touched on DATE (mtime)
find ~/.cursor/projects -path '*/agent-transcripts/*.jsonl' ! -path '*/subagents/*' \
  -newermt "$DATE" ! -newermt "$(date -j -v+1d -f %Y-%m-%d "$DATE" +%Y-%m-%d)" 2>/dev/null
```

Prefer parent transcripts over `subagents/`. Skim user goals + final outcomes; skip
tool-noise. Project label = folder under `projects/` (e.g. `Users-testadmin-Development-work-epayment` → epayment).

## Claude

- `~/.claude/transcripts/*.jsonl`
- `~/.claude/projects/**/*.jsonl`

Same date filter via mtime (or embedded timestamps when present). Skip undated files.

## Codex

- `~/.codex/sessions/`
- `~/.codex/archived_sessions/` when the live tree is empty for `DATE`

Date-filter; summarize task + outcome only.

## Git (`DEV_ROOT`)

Discover repos with commits that day by the machine user; skip merges:

```bash
# example — adapt author email from `git config user.email` per repo
find "$DEV_ROOT" -maxdepth 4 -type d -name .git 2>/dev/null | while read -r g; do
  repo="${g%/.git}"
  log=$(git -C "$repo" log --since="$DATE 00:00" --until="$DATE 23:59:59" \
    --author="$(git -C "$repo" config user.email)" --no-merges --oneline 2>/dev/null)
  [ -n "$log" ] && echo "REPO $repo" && echo "$log"
done
```

Bucket: shipped (commit messages / merged work) vs WIP (uncommitted only if clearly
from that day's sessions — otherwise skip dirty trees).

## Gmail

Accounts: `$GMAIL_PERSONAL`, `$GMAIL_PURELY` only. Never school suumail.

`after:` / `before:` are UTC day bounds — for America/Denver, widen one day each side
if the window looks thin, then filter to local `DATE` in the inventory.

```bash
# DATE = 2026-08-06 → after 2026/08/05 before 2026/08/07 (exclusive before)
$COMPOSIO execute GMAIL_FETCH_EMAILS --account "$GMAIL_PERSONAL" -d '{
  "query": "after:2026/08/05 before:2026/08/07",
  "max_results": 30,
  "verbose": false,
  "include_payload": false
}'
# repeat with --account "$GMAIL_PURELY"
```

Large Composio output may land at `outputFilePath` — read that file. Inventory:
from/to, subject, need-reply? Draft candidates only when outbound need is clear.

## Calendar (read)

```bash
$COMPOSIO execute GOOGLECALENDAR_FIND_EVENT --account "$GOOGLE_CALENDAR" -d '{
  "calendar_id": "primary",
  "time_min": "2026-08-06T00:00:00-06:00",
  "time_max": "2026-08-07T00:00:00-06:00",
  "single_events": true,
  "max_results": 50
}'
```

List existing events into the calendar bucket before any create (see external-writes).

## Redaction

Strip tokens, passwords, API keys, raw message bodies with secrets. Note subjects and
outcomes only.
