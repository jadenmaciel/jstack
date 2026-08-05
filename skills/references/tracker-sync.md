# Tracker Sync

How lifecycle skills keep the issue tracker in step with the work. Referenced by `$implement`, `$pr`. `$close` and `$epayment-handoff` own terminal transitions and are unchanged.

## Boundaries

| Moment | Transition | Comment |
|---|---|---|
| `$implement` starts work on a ticket | In Progress | none |
| `$pr` opens the normal-path PR | In Review | PR link + one-line behavior/proof |
| `$close` (normal) | Done | only if the user asks |
| `$epayment-handoff` (epayment) | Code Review | one first-person TROUT comment (existing behavior) |

Lifecycle skills update owned trackers at their named phase boundaries,
never on passive polls:

| Cycle phase | Status | Comment |
|---|---|---|
| confirmed intake / planning | In Progress | branch + scope |
| plan complete | In Progress | plan + verification intent |
| implementation and exact-tree check clean | In Progress | head SHA + proof |
| PR published | In Review | PR link + proof |
| repair push, base sync, or final Fable result | In Review | reason + head SHA |
| hold | unchanged | blocker |
| green, merge-ready completion | In Review | checks/comments/sync/review result |

The cycle guard queues each update and records `ok`, `skipped-ownership`,
`failed`, or `missing-label` with an idempotency key derived from cycle, phase,
tracker, and head. Read current status and existing comments before writing; do not
repeat an already-applied transition or identical comment. A failed update remains
non-blocking but must receive a guard receipt. Cycle never marks Done or closes an
issue.

Epayment work reaches In Review through `$epayment-handoff`, not `$epayment-pr`; do not double-transition. Epayment implement-start still uses the In Progress row above.

## Reality check before Done (hard guard)

Before any transition to Done/closed — including bulk status passes — verify reality first: the linked PR is actually merged (`gh pr view <n> --json state,mergedAt` or the Jira-linked PR shows landed). HANDOFF.md and current ticket status are claims, not truth. If merge state cannot be confirmed, do not transition; report instead. (Incident: FILL-600/601 marked Done against unlanded PRs #258/#275, 2026-07-09.)

## Ownership scope (hard guard)

Write only to a ticket the user owns: the Jira assignee or reporter is `j.shapiro`, or the GitHub issue assignee/author is `jadenmaciel`. If ownership cannot be determined, treat the ticket as not owned and skip the write. This is the only sanctioned relaxation of the create-only default in `to-tickets-jira` ("never edit, transition, comment on ... a ticket you do not own without explicit OK"); it never extends to tickets owned by others.

## Mechanism

- Jira (FILL / TROUT): Composio. Comment with `JIRA_ADD_COMMENT` (confirmed). For the status move, resolve the transition tool from the Composio Jira toolkit at call time (the transition slug is not pinned here; confirm it exists before use, and skip the transition with a reported note if it does not). Never send credentials, customer data, or proprietary code in a comment body.
- GitHub Issues (GH / Purely): `gh`. Status is expressed with labels (`gh issue edit <n> --add-label in-progress` / `--remove-label in-progress --add-label in-review`) since GitHub Issues has no status state machine; comment with `gh issue comment <n> --body "..."`. For multi-phase work, query labels and comments first and acknowledge the guard's pending update afterward.

## Failure handling

A tracker write must never block the code lifecycle. If the write is unavailable, unauthorized, or fails, report the blocker in `Evidence` and continue — a Jira or GitHub hiccup does not stop an implement or a PR. Mirror `$close`'s "report the blocker and do not claim" posture, but for these non-terminal writes the work proceeds regardless.

## Dependency

The GitHub status labels (`in-progress`, `in-review`) must exist in the repository; `setup-matt-pocock-skills` / `triage` label setup provisions them. If a label is missing, degrade to a comment only and report the missing label.

## Voice

Comments are plain first-person prose in the user's voice: no emojis, no AI attribution, no internal tooling references.
