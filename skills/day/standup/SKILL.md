---
name: standup
description: Turn the week's GitHub PRs (both accounts) and Jira state (FILL, COM, TROUT-539, and blocked TROUT tickets) into Thursday 10:00 meeting notes with speakable talking points, saved to Desktop.
---

# standup

Each Thursday at 10:00 you report what you did. This skill reads **both** GitHub
accounts through Composio (personal for `jadenmaciel/troute-fulfillment` and
`jadenmaciel/troute-comms`, work for `ExpiTrans/epayment`) and the Jira boards
(FILL project, COM board, TROUT-539 epic, and blocked TROUT tickets), then
builds meeting notes that open with a **Say this in standup** section of
speakable bullets. Printed in chat and saved to the Desktop.

Routine: a claude.ai cloud routine (`trig_01TMiXC8hNtrjtjgsABYEp7r`,
"weekly-standup-notes", cron `57 14 * * 4` UTC = 08:57 MDT Thursday) drafts
cloud notes an hour before the meeting from the troute environment plus Jira
via the Rovo connector; it emails and pushes the result. The cloud run has no
ExpiTrans/epayment GitHub access, so its epayment section comes from Jira only.
This local skill remains the full-fidelity version (both GitHub accounts,
Desktop save). If the meeting moves, update this file and that trigger.

## Config (EDIT THIS — single source of truth)

```
PERSONAL_ACCOUNT = github_roub-argal        # login jadenmaciel
PERSONAL_REPO    = jadenmaciel/troute-fulfillment
PERSONAL_COMMS_REPO = jadenmaciel/troute-comms
WORK_ACCOUNT     = github_fut-ranter        # login jadenexpitrans
WORK_REPO        = ExpiTrans/epayment
JIRA_CLOUD_ID    = 0ab11ef1-b7c2-41b1-b2b5-f68458a32086   # expitrans.atlassian.net (Rovo MCP)
COM_BOARD         = https://expitrans.atlassian.net/jira/software/projects/COM/boards/517
TROUT_BOARD       = https://expitrans.atlassian.net/jira/software/projects/TROUT/boards/4
JIRA_FALLBACK    = Composio jira toolkit, --account jira_andre-unhung
WINDOW_DAYS      = 7
SAVE_DIR         = ~/Desktop
COMPOSIO         = /Users/testadmin/.composio/composio
```

All repos are private. Always pass `--account` on every GitHub call — the
Composio default connection is not deterministic, and each repo is only visible
from its own account. Nothing else is a knob.

## Steps

### 1. Window
```
SINCE=$(date -v-7d +%Y-%m-%d)   # WINDOW_DAYS back = last Thursday
TODAY=$(date +%Y-%m-%d)
```
Done when both dates resolve.

### 2. Preflight — both accounts
Verify each account sees its repos before fetching anything:

```bash
$COMPOSIO execute GITHUB_GET_THE_AUTHENTICATED_USER --account github_roub-argal -d '{}'
$COMPOSIO execute GITHUB_GET_A_REPOSITORY --account github_roub-argal \
  -d '{"owner":"jadenmaciel","repo":"troute-fulfillment"}'
$COMPOSIO execute GITHUB_GET_A_REPOSITORY --account github_roub-argal \
  -d '{"owner":"jadenmaciel","repo":"troute-comms"}'
$COMPOSIO execute GITHUB_GET_THE_AUTHENTICATED_USER --account github_fut-ranter -d '{}'
$COMPOSIO execute GITHUB_GET_A_REPOSITORY --account github_fut-ranter \
  -d '{"owner":"ExpiTrans","repo":"epayment"}'
```

Done when the logins come back `jadenmaciel` and `jadenexpitrans` and all
three repos return `private: true` with `permissions.pull: true`. Either
account/repo pair fails: stop and report it; never run that repo's searches
through the other connection. A wrong-account run silently misses that repo.

### 3. Fetch GitHub — searches per repo
For each repo, with its own account and login:

- **Shipped:** `repo:<REPO> is:pr author:<LOGIN> merged:>=SINCE`
- **In progress:** `repo:<REPO> is:pr is:open author:<LOGIN>`
- **Reviewed:** `repo:<REPO> is:pr reviewed-by:<LOGIN> updated:>=SINCE`
- **troute-comms:** Run the shipped, in-progress, and reviewed searches above
  with `PERSONAL_ACCOUNT` and `PERSONAL_COMMS_REPO`.
- **Team open PRs (epayment only):** `repo:ExpiTrans/epayment is:pr is:open -author:jadenexpitrans`
  — teammates' in-flight work belongs in the notes too.

Run each with the parse helper — Composio offloads large results to a temp
file, so reading raw stdout is not enough:

```bash
$COMPOSIO execute GITHUB_SEARCH_ISSUES_AND_PULL_REQUESTS --account "<ACCOUNT>" \
  -d '{"q":"<QUERY>","per_page":100}' 2>&1 | python3 -c '
import sys, json
o = json.load(sys.stdin)
if not o.get("successful"):
    print("ERR\t" + str(o.get("error"))); sys.exit()
p = o.get("outputFilePath")
d = json.load(open(p)) if o.get("storedInFile") and p else o
d = d.get("data", d)
print("COUNT\t%d" % d.get("total_count", 0))
for it in d.get("items", []):
    if "pull_request" not in it:        # drop plain issues
        continue
    title = (it.get("title") or "").replace("\t", " ").replace("\n", " ")
    print("PR\t%s\t%s\t%s\t%s" % (it.get("number"), it.get("html_url"),
        (it.get("user") or {}).get("login"), title))
'
```

Done when all 10 searches have returned rows, an `ERR` line, or a `COUNT 0`
that step 4 has cleared.

### 4. Rate-limit rule — an empty search is not a quiet week
GitHub *search* has a ~30/min secondary limit. When throttled, Composio returns
`successful: true` with an empty `data` — a silent blank indistinguishable from
no activity. So:

- Any search returning `COUNT 0` (or no rows) → verify through REST before
  believing it. REST core quota is 5000/hr and does not share the search limit.
  - Merged: `bash <skill-dir>/scripts/list_merged_prs.sh <ACCOUNT> <OWNER> <REPO> $SINCE`
  - Open: `GITHUB_LIST_PULL_REQUESTS` with `{"state":"open","per_page":100}`
    (same `--account`; large output lands at `outputFilePath` when
    `storedInFile: true`, PRs under `data.pull_requests`).
- REST agrees it's empty → report `_no activity_` for that section.
- REST disagrees → use the REST rows and note that search was throttled.

Done when every empty section is backed by a REST check, not just a search.

### 5. Fetch Jira — FILL, COM, and TROUT
Primary path is the Atlassian Rovo MCP tool `searchJiraIssuesUsingJql` with
`cloudId = JIRA_CLOUD_ID`, `searchResultMode: "issues"` (required by the live
schema; omitting it triggers a `-32602` argument error), trimmed fields
`["summary","status","assignee","updated","issuetype"]`, and `maxResults: 100`:

- **FILL:** `project = FILL ORDER BY updated DESC` → status counts plus the
  key + summary of everything In Progress and To Do.
- **FILL queue (what's coming):**
  `project = FILL AND status IN (Ready, "In Progress") ORDER BY Rank ASC` →
  the dependency-aware next-up queue. Split the rows by `issuetype`: Epics are
  the themes coming next (a Wayfinder map or an MVP grouping); Tasks and
  Bugs are the individual tickets under them. This feeds the "What's next"
  block. Rank often matches key order when nobody has reordered the backlog;
  say so rather than implying a curated priority.
- **TROUT-539 epic:** `parent = TROUT-539 ORDER BY key ASC` → one row per
  ticket for the snapshot table.
- **COM:** `project = COM AND assignee = currentUser() ORDER BY updated DESC`
  → one row per ticket for the current user's shipped and active standup state. Board:
  `COM_BOARD`.
- **Blocked TROUT:** `project = TROUT AND assignee = currentUser() AND (status = Blocked OR Flagged is not EMPTY) ORDER BY updated DESC`
  → one row per blocked or impeded ticket, including its flag state. Board:
  `TROUT_BOARD`.

All durable payloads, verbatim (a count-only probe uses the same shape with
`searchResultMode: "count"` and no `fields`):

<!-- jira-payload-contract:begin -->
```json
[
  {
    "cloudId": "JIRA_CLOUD_ID",
    "jql": "project = FILL ORDER BY updated DESC",
    "fields": ["summary", "status", "assignee", "updated", "issuetype"],
    "maxResults": 100,
    "searchResultMode": "issues"
  },
  {
    "cloudId": "JIRA_CLOUD_ID",
    "jql": "project = FILL AND status IN (Ready, \"In Progress\") ORDER BY Rank ASC",
    "fields": ["summary", "status", "assignee", "updated", "issuetype"],
    "maxResults": 100,
    "searchResultMode": "issues"
  },
  {
    "cloudId": "JIRA_CLOUD_ID",
    "jql": "parent = TROUT-539 ORDER BY key ASC",
    "fields": ["summary", "status", "assignee", "updated", "issuetype"],
    "maxResults": 100,
    "searchResultMode": "issues"
  },
  {
    "cloudId": "JIRA_CLOUD_ID",
    "jql": "project = COM AND assignee = currentUser() ORDER BY updated DESC",
    "fields": ["summary", "status", "assignee", "updated", "issuetype"],
    "maxResults": 100,
    "searchResultMode": "issues"
  },
  {
    "cloudId": "JIRA_CLOUD_ID",
    "jql": "project = TROUT AND assignee = currentUser() AND (status = Blocked OR Flagged is not EMPTY) ORDER BY updated DESC",
    "fields": ["summary", "status", "assignee", "updated", "issuetype", "flagged"],
    "maxResults": 100,
    "searchResultMode": "issues"
  }
]
```
<!-- jira-payload-contract:end -->

Oversized responses get saved to a tool-results file instead of returned
inline; parse the file with `jq` — the shape is
`.issues.nodes[] | {key, status: .fields.status.name, summary: .fields.summary}`.

Rovo MCP unavailable (headless or cron run) → Composio jira fallback with
`--account jira_andre-unhung`: `composio search "jira jql"` to get the slug,
`--get-schema` before executing, same four JQL queries.

Done when all five queries returned issues (or a visible `_error_` line explains
why not).

### 6. Handle gaps explicitly — never a silent blank
- `ERR` line → emit a visible `_error: <message>_` under that section; do not
  drop it. A 422 naming the repo means the config slug is wrong — fix config,
  do not paper over it.
- All sections for a repo are 0 even after step 4's REST check → probe
  `repo:<REPO> is:pr` with no author filter on the same account. Nonzero means
  the login is wrong, not a quiet week: check `user.login` on a returned PR,
  fix config, rerun.
- On a `403` rate-limit message, pause briefly and retry once, then report.

### 7. Build markdown — written to be said out loud
Section order:

1. `## Say this in standup` — speakable bullets grouped per project, in bold
   sub-headers (**troute-fulfillment**, **troute-comms**, **epayment**, **COM**).
   Put every blocked or impeded TROUT ticket under a **Blocked** sub-header.
   Each bullet: one idea,
   plain words a non-engineer follows, sayable in one breath. Ticket keys and
   PR links go in parens at the end of the sentence, never inside it.
2. `**Bottom line:**` — one paragraph, the whole week in prose.
3. `## troute-fulfillment` — Done bullets grouped under bold plain-language
   themes (**Security**, **Database**, ...), each ending with its PR links;
   then a "What I'm finishing now" list from the FILL In Progress tickets;
   then a **What's next** list from the FILL queue. Lead the What's next list
   with the Ready Epics, since those are the themes the next weeks go to, then
   name up to five individual Ready tickets from the top of the Rank order.
   Say what the work does in plain words, not the ticket title. The
   `## Say this in standup` section gets one bullet naming the next theme, so
   the meeting hears where the work is heading and not only what closed.
4. `## epayment (TROUT-539)` — shipped / in progress / still to do, mapped to
   epic tickets; then the team's open PRs with authors.
5. `## troute-comms (COM)` — shipped / in progress / reviewed PRs, mapped to
   the current user's active COM tickets.
6. `## Jira snapshot` — FILL status counts, a FILL next-up table
   (Ticket | Type | Slice | Status), a TROUT-539 table, a COM table,
   and a blocked TROUT table with the Jira flag state
   (Ticket | Slice | Status | Flag).

Prose rules: this is a prose deliverable, so stop-slop applies — active voice,
no em dashes in body text, no filler. Strip conventional-commit prefixes and
ticket keys out of bullet wording (`feat(db): FILL-512 add postgres schema
baseline` → `Added the Postgres schema baseline`). Every section is always
accounted for — content, `_no activity_`, or `_error_`.

### 8. Output — print, save, open
Print the full markdown in chat, write it to `SAVE_DIR/<TODAY>-standup.md`,
then `open` the file so it appears in the default app. Confirm the path back
to the user.

## Output template

```
# Standup — week of <TODAY> (since <SINCE>)

## Say this in standup

**troute-fulfillment**
- The last blocker on go-live is cleared. The merchant-scoping check is merged. ([#203](url))
- Next up is letting merchants name their own order stages. (FILL-754)

**epayment**
- I shipped the fulfillment config and key custody this week. (TROUT-592)

**troute-comms**
- I reviewed the active communications changes and kept the open work moving. ([#41](url))

**Blocked**
- I need a decision on the payment rollout before I can close this ticket. (TROUT-601, flagged)

---

**Bottom line:** <one paragraph>

## troute-fulfillment
- **Security (3 PRs).** Required signed webhooks so nobody can forge one. ([#131](url))

**What I'm finishing now**
- **Cutover countdown (FILL-542, In Progress).** <plain sentence>

**What's next**
- **Merchant-defined order stages (FILL-754, Epic).** <plain sentence>
- **Then:** <up to five Ready tickets, plain sentence each> (FILL-745)

## epayment (TROUT-539)
- **Shipped.** <plain sentence> (TROUT-592, Deployed)
- **Team open PRs:** <title> ([#339](url), @author)

## troute-comms (COM)
- **In progress.** <plain sentence> (COM-42, In Progress)

## Jira snapshot
**FILL:** 80 Done, 4 In Progress, 4 To Do.

**FILL next up**

| Ticket | Type | Slice | Status |
|---|---|---|---|
| FILL-754 | Epic | Merchant-defined order stages | Ready |
| FILL-745 | Task | Stage schema and stage-set routes | Ready |

**TROUT-539 epic**

| Ticket | Slice | Status |
|---|---|---|
| TROUT-592 | Config and key custody | Deployed |

**COM**

| Ticket | Slice | Status |
|---|---|---|
| COM-42 | Communications rollout | In Progress |

**Blocked TROUT**

| Ticket | Slice | Status | Flag |
|---|---|---|---|
| TROUT-601 | Payment rollout | Blocked | Impediment |
```
