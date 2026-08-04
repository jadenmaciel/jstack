---
name: to-tickets-jira
description: File and maintain Jira tickets on expitrans.atlassian.net (project TROUT) via Atlassian MCP (Composio fallback). Create bracketed feature/bug Jira issues, fetch tickets, and add comments. Fulfillment-module parent tickets live under epic TROUT-539. User-invoked.
---

# To Tickets (Jira)

Turn the conversation, notes, or a plan into well-formed Jira issues, and fetch
or comment on existing ones. Default project `TROUT` on expitrans.atlassian.net.

**Primary:** Atlassian plugin MCP. **Fallback:** composio-cli only if MCP fails
or lacks the needed action (e.g. attachment upload).

## Every ticket

- **Bracket the summary** (mandatory). `[Module] imperative title`. The bracket
  names the feature/module/area. e.g. `[Checkout] Save payment method`,
  `[Auth] Login returns 500 on submit`.
- **Work type**. Set `issue_type`. TROUT work items are `Task` unless the user asks for an Epic or Subtask. Convey feature-vs-bug intent through the `[Module]` bracket and body.
- **Labels**. Use at least one. New labels auto-create.
- **Long first-person body.** Start with "As a ..." in the user's or developer's
  voice, then give enough scope, acceptance criteria, verification, risks, and open
  questions for a developer to start without this chat.
- **Human voice.** Run the body and comments through `stop-slop`: no em dashes, no
  AI scaffolding, no workflow-tooling leakage (`$start`, `/opsx:propose`, `$check`,
  intake, recon, worktree, receipt), no throat-clearing, and no repeated scope.

## Feature ticket

Use `issue_type: Task`.

Description body (markdown, lengthy and first person):

<feature-template>
## User Story
As a [role], I can [use or operate the thing] so [specific outcome].

## Context
[A few concrete paragraphs. Name the repo, route, service, page, config, external ticket, file, or decision that frames the work. If there is a linked fulfillment-service ticket, write: External reference: FILL-XXX (Fulfillment project).]

## Scope
- [Specific change]
- [Specific change]

## Out of Scope
- [Boundary the implementer must not cross]
- [Boundary the implementer must not cross]

## Acceptance Criteria
- [ ] [Observable done state]
- [ ] ...

## Verification
```bash
[smallest useful command]
```

## Risks / Notes
- [Risk, tenant boundary, secret handling note, money-safety note, or migration concern]

## Open Questions
1. [Question that blocks or shapes implementation, if any]
</feature-template>

## Bug ticket

Use `issue_type: Task`.

<bug-template>
## Problem
As a [role], I hit [bad behavior] when I [specific action].

## Replication Steps
1. Go to [URL]
2. [Do thing]

## Expected Result
[What it should do]

## Actual Result
[What it does instead]

## Acceptance Criteria
- [ ] [Observable fixed state]
- [ ] [Regression guard]

## Verification
```bash
[smallest useful command]
```

## Risks / Notes
- [Data-loss, tenant boundary, payment, secret, or migration concern]
</bug-template>

Attach evidence when it exists:
- **Screenshot / video** of the issue.
- **Logs**. Capture recent app/console/network output to a file (server stdout,
  browser console, or a trace/diagnosing-bugs capture) and attach it.

Attach via `--file` (best-effort). If the tool rejects the local file, write the
file path into the description or a follow-up comment so the evidence is still
recorded.

## Publish (Atlassian MCP primary)

Use the Atlassian MCP tools. Site: expitrans.atlassian.net
(`cloudId` from `getAccessibleAtlassianResources` if needed).

TROUT issue types: Task, Epic, Subtask.

Create:
- `createJiraIssue` with project key `TROUT`, summary, description (markdown/ADF as the tool accepts), issue type, labels, and `parent` when under an epic/task.

Fetch:
- `searchJiraIssuesUsingJql` with JQL (preferred), or `getJiraIssue` for one key.

Comment / update:
- `addCommentToJiraIssue` / `editJiraIssue`.

Write comment text in Jaden's voice per the Ticket Comment Voice rule in
`~/.cursor/skills/references/sprintflow-core.md` and run it through `stop-slop`:
casual, first person, no skill/step names or internal terms, no em dashes or AI
scaffolding.

### Fallback (composio)

Only if Atlassian MCP fails or cannot attach files. Binary:
`/Users/testadmin/.composio/composio` (or `composio` on PATH). Unsure of args?
`--get-schema`. Preview? `--dry-run`. "Not connected" -> `composio link jira`.

```bash
composio execute JIRA_CREATE_ISSUE -d '{
  "project_key": "TROUT",
  "summary": "[Module] title",
  "issue_type": "Task",
  "description": "## User Story\nAs a developer, I can ...",
  "labels": ["area-x"]
}'
composio execute JIRA_ADD_ATTACHMENT --file ./evidence.png -d '{ "issue_key": "TROUT-123" }'
composio execute JIRA_SEARCH_ISSUES -d '{ "project_key": "TROUT", "jql": "status = \"In Progress\"" }'
composio execute JIRA_ADD_COMMENT -d '{ "issue_id_or_key": "TROUT-123", "comment": "..." }'
```

## Fetch tickets

Prefer `searchJiraIssuesUsingJql`. JQL beats loose filters.

## Comment / update

Prefer `addCommentToJiraIssue` / `editJiraIssue` via Atlassian MCP.

## Fulfillment Module Tickets

Use this branch when the ticket belongs under the Fulfillment Module epic.

- Set project `TROUT` for every ticket.
- Standalone fulfillment work: create `issue_type: Task` with parent `TROUT-539`.
- Related ticket set: create the owning parent `Task` first with parent `TROUT-539`.
- Child work that is part of an owning parent: create `issue_type: Subtask` with parent `<parent task key>`.
- Independent sibling work stays as a separate `Task` under `TROUT-539`.
- Publish parent Tasks before Subtasks so the Subtasks can reference real parent keys.
- Add `go-fulfillment` plus concrete area labels such as `epayment`, `local-dev`, or `apple-container`.
- Do not add the old pivot label.
- If a linked fulfillment-service ticket matters, include it as `External reference: FILL-XXX (Fulfillment project).`
- Do not create a Jira issue link, status mirror, or twin unless the user asks for that exact action.

Body pattern, inspired by TROUT-593 and TROUT-597:
- Open with the first-person user story.
- State that TROUT is canonical for epayment/project work when external fulfillment tickets are involved.
- Name the concrete route, file, service, config, or workflow.
- List scope, out of scope, acceptance criteria, verification commands, risks, notes, and open questions.
- For parent Tasks, end with `Detail / spec: TROUT-539 (Fulfillment Module epic).`
- For Subtasks, name the parent Task in the context and keep `TROUT-539` as the epic context in prose.

Use Atlassian MCP `createJiraIssue` with the same fields as the old composio examples
(project, summary, issue type, parent, description, labels). Fall back to composio
only if MCP cannot set parent/labels.

### Shared-board safety
- Create-only by default. Never edit, transition, comment on, link, reassign, or delete a TROUT ticket you do not own without explicit OK from the user.
- Cross-reference in prose only. Do not create Jira issue links between TROUT and external fulfillment tickets.
- One scoped call at a time. No bulk operations.
- On any error, STOP and report it; no blind retries.

## Before publishing

Show the user each drafted ticket: bracketed summary, work type, parent or epic,
labels, body, and get an OK. For related tickets, show the Task/Subtask
hierarchy before creating anything. Then create parent Tasks first, followed by
their Subtasks, so every child can reference a real parent key. Filing blockers?
Create blockers first so you can reference real keys.

Done when every created ticket has: a bracketed summary, a work type, at least
one label, and a long first-person body matching its template. Bug tickets also
need Replication Steps, Expected Result, Actual Result, and attached evidence or
paths to evidence when evidence exists. Fulfillment Module tickets also need the
correct hierarchy: standalone and parent Tasks under `TROUT-539`, related child
work as Subtasks under the owning parent Task.
