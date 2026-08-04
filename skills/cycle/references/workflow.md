# Cycle workflow

Cycle is explicit-only. It owns one normal-repository task, branch, and ready PR.
`~/.codex/bin/sprintflow-cycle.mjs` is the sole state, decision, publication,
adoption, and tracker-receipt authority. Never hand-build a lifecycle snapshot or
edit a `cycle-state` marker. Never merge, force-push, rebase, reset, rewrite, or
stash.

## Intake and state

1. Run `$grill-with-docs`; wait for explicit shared-understanding confirmation.
2. Select the checked-in repository branch convention. If none exists, create
   `cycle/<task-slug>` from the fetched default base. A non-`cycle/` branch needs
   `--branch-policy-source` and, when applicable, `--branch-prefix`; branch history
   is not policy.
3. Invoke guard `init` with exact `--repo`, `--task`, `--base`, `--branch`,
   `--grill-confirmed true`, every explicit `--tracker`, and an optional `--ticket`.
   Do not pipe, truncate, or suppress its exit status. It runs narrowed preflight
   and `assert-cycle-normal`; any nonzero result is `HOLD`.
4. Execute each returned tracker update with `~/.codex/skills/references/tracker-sync.md`, then
   record `transition --event tracker-ack`. Tracker failure never releases or
   blocks code work once receipted, but every queued outcome is mandatory before
   the next guard decision, transition, or publication.

State is stored atomically under the Git common directory before publication and
mirrored as an append-only, non-rendered PR-comment marker v2 afterward. New PRs
also receive one immutable `cycle-ref` identity marker in their body; the guard
never rewrites that body and validates its exact cycle, branch, and base on every
resume. A local remote-ack receipt distinguishes an interrupted
ledger append from deliberate marker deletion. Every mutating command requires
the latest `--expected-rev`; stale, deleted, or mismatched local/PR state holds. A
legacy, absent, or malformed marker is not resumable. Use `adopt --user-confirmed true --pr <named>`
only when the user explicitly names the existing PR; adoption revalidates scope,
branch, head, clean tree, and an exact receipt.

## Required phases

Codex main starts reusable planner, implementer, then reviewer agents sequentially
with `fork_turns="none"`; wait for each return. Only required research/review
grandchildren may run within four total threads, and grandchildren never delegate.
Only the implementer writes. Claude Code prefers the serial main-session workflow;
use phase subagents only when unavailable, and children never delegate. In Claude's
fallback, main invokes delegation-owning `$research` and `$check`; it gives the
research artifact to a non-delegating planner, which uses Context7 and returns the
plan. The `$check` review children become the reviewer lane.

Pi runtime: the main thread owns every `sprintflow-cycle.mjs` invocation — all
state transitions, `decide` calls, and publication; children never touch the
guard or push. Phases run as subagents per pi's AGENTS.md routing:
planner on `claude`/`sonnet` (or `codex`/`gpt-5.6-terra`), pre-planning
research/scouting on `cursor`/`composer-2.5` (or inlined into the planner
prompt), implementer on `codex`/`gpt-5.6-terra` (must commit — cursor
children are denied `.git/` writes), reviewer on `claude`/`opus`, and
embedded `$check` standards/spec reviews on `claude`/`sonnet` rather than
luna. Implementers commit on
the cycle branch and stop; the main thread verifies each returned receipt
(head SHA, files touched, proof commands) before recording the transition.
Pi children cannot spawn workflows or skills, so the planner prompt carries
its research instructions inline instead of invoking `$research`. Do not
probe `sprintflow-cycle.mjs` with `--help`/`init --help` — unsupported, each
probe costs a HOLD; the usage line in the cycle skill is the reference.

1. Codex planner invokes `$research`; Claude serial main treats the returned research
   worker as its planning input. Follow repository research conventions and use
   Context7 for relevant current library/API docs. If none apply, record the reason.
   Then call `transition --event plan-complete --research-artifact <path>
   --context7 used|not-applicable`.
2. Implementer invokes `$implement`, including its local review and commit. Then
   call `transition --event implement-complete`.
3. Reviewer invokes `$check`. Only its exact current-tree `codex-high` receipt, on
   any verdict, may satisfy `transition --event check-complete`.
4. Invoke guard `decide`. Only `PUBLISH` permits guard `publish`; supply factual
   title, summary, and proof. The guard alone pushes, opens or updates one ready PR,
   verifies it, persists state, and queues In Review tracker updates.

The guard rejects publication when any phase or receipt is missing. Do not replace
named skills with manual approximations or direct `git push`, `gh pr create`,
`codex review`, or raw lifecycle-policy calls.

## PR loop

Poll by invoking guard `decide` at intervals no longer than 60 seconds:

- `WAIT`: poll again. Never post a tracker update for passive polling.
- `REPAIR`: first persist `transition --event repair-authorized`, then reactivate
  the implementer with `$address-pr-comments`. It fetches one snapshot, repairs,
  runs embedded `$check`, pushes once, and exits. Record `repair-pushed` with
  `--source address-pr-comments`, then invoke reviewer `$check` and record
  `check-complete` before deciding again.
- `SYNC_ONCE`: persist `sync-authorized` before merging the fetched base into the
  cycle branch. Abort conflicts completely and hold. On success record
  `sync-complete`, then `$check`, `check-complete`, and guard `publish`. Never sync
  twice.
- `MARK_READY`: guard `publish` verifies and marks the existing PR ready.
- `ASK_REOPEN`: ask the user. Do not reopen without approval.
- `HOLD`: record `transition --event hold --reason <reason>` and stop with evidence.

Only a successful `$address-pr-comments` push increments the eight-round outer
counter. Inner `$check`/`$fix`, sync, and Fable repairs do not. Failure identity is
derived by the guard from sorted unique CI check/step IDs and GitHub thread node
IDs. Two surviving repair pushes with the same signature hold. Reply to and resolve
clear fix/answer/stale threads; declined, disputed, ambiguous, or scope-expanding
feedback stops for the user.

## Fable and completion

When `decide` returns `FABLE_ONCE`, determine repository visibility. For private,
internal, or unknown visibility, obtain explicit approval for the exact review
packet/head, SHA-256 the packet, and record `egress-approved --user-confirmed true
--packet-hash <sha256>`. Pass the same hash to `fable-authorized` before
making exactly one Fable 5 High whole-PR call through `$claude-second-opinion`.

Send full changed-file coverage when safe and within limits; otherwise use complete
summaries plus risk-focused hunks. A usage, authentication, transport, or unusable
result consumes the attempt. Run `$check` once and record `fallback-complete`; never
run repeated direct Codex reviews. Save that fresh post-authorization `$check`
result as a JSON report containing reviewer, exact head, verdict, findings, and
completion time; SHA-256 it and pass `--check-report` plus
`--check-report-sha256` to `fallback-complete`. For every usable Fable result, save
the same shaped JSON with reviewer `claude-fable-high`, hash it, and pass
`--fable-report` plus `--fable-report-sha256`. `$claude-second-opinion` must also
record its exact-tree `claude-fable-high` evidence receipt after authorization;
the guard rejects a report without that fresh transport receipt. The fallback
`$check` must likewise create a new post-authorization `codex-high` receipt; an
older exact-tree receipt or any transport except `cycle-fallback-check` cannot
release it. For a clean Fable result record
`fable-complete` with that report. For validated findings record `fable-findings`
with the report and exact finding IDs, invoke
implementer `$implement`, reviewer `$check`, push with guard `publish`, record
`fable-repair-pushed`, and revalidate GitHub. When green, record `fable-complete`
for that validated repaired head. Never call Fable again.

`COMPLETE` is valid only when checks are green, exact local evidence is recorded, local
and remote heads match, actionable threads are zero, the PR is ready and
conflict-free, and Fable is head-bound `complete` or `fallback_complete`. Record
`transition --event complete`, synchronize every pending tracker update, report
review decision separately, and leave the PR unmerged and trackers In Review.

Tracker phases are planning start, plan complete, implementation/check clean, PR
published, each repair or sync, Fable completion, blocker, and green completion.
Update every explicitly linked ownership-approved Jira ticket or GitHub issue once
per phase/head. Never mark Done or close an issue. Missing GitHub status labels
degrade to a recorded comment-only update.
