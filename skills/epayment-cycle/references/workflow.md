# Epayment Cycle workflow

`$epayment-cycle` is explicit-only. It orchestrates the existing epayment skills;
it does not replace their proof, publication, or handoff authority. The PR remains
draft for QA. Never expose credentials, local environment contents, customer data,
private logs, or agent machinery in GitHub or Jira text.

## Intake and state

1. Work only in `/Users/testadmin/Development/work/epayment`. For FILL intake,
   first read the issue and its links through Atlassian Rovo, save a minimal
   0600 JSON receipt with `source`, `input_ticket`, fetch time, link relation,
   and sorted `linked_trout`, and require exactly one linked TROUT. FILL remains
   read-only context. Only then run `$epayment-start` with canonical TROUT;
   create no branch or edit before that resolution.
2. Refuse a linked worktree, dirty tree, unrelated branch, `develop` edits,
   overlapping active session, ambiguous ticket, missing Jira evidence, or failed
   `epayment-gh auth status`. Never clean or relocate user work.
3. Run `$grill-with-docs` after intake and wait for the user's explicit shared-
   understanding confirmation.
4. Guard commands are `init`, `decide`, `transition`, and `adopt`. Invoke `init`
   with exact repo, intake ticket, canonical TROUT, branch, `--grill-confirmed
   true`, and FILL Jira receipt when applicable. Every mutation
   uses the latest `--expected-rev`; never pipe or suppress guard failures.
5. Execute the returned Jira action once: move canonical TROUT to `In Progress`.
   A Jira failure is receipted and reported but does not block code work. Do not
   update FILL. Passive phases and polling never comment.

The guard stores version-1 state atomically under the Git common directory and
mirrors it after publication through append-only hidden `epayment-cycle-state`
PR comments. Stale revisions hold. Existing branch or PR state is not adopted
implicitly: use `adopt --user-confirmed true --pr <number>`, require exactly one
matching PR, repeat all scope, head, clean-tree, receipt, and devtest validation,
then run polish before GitHub review.

## Required phases

Codex main starts planner, implementer, and reviewer agents sequentially with
`fork_turns="none"`; wait for each return. Only `$research` and the two mandatory
review transports may create required children within the four-thread cap;
grandchildren never delegate. Claude main executes phases serially. If that path
is unavailable, a fallback phase child never delegates and Claude main performs
research and review transports. One implementer is the only writer.

1. Planner invokes `$research`, follows repository/NotebookLM conventions, and
   uses Context7 for relevant public library/API docs. Otherwise record
   `not-applicable` and a reason. Run `$company-standard` once, record source
   freshness, and produce a tenant/migration/security/test/dev-box checklist.
   Record `plan-complete` with the research and checklist artifacts.
2. Implementer invokes `$implement`, including its local review and commit. Record
   `implement-complete`. The guard derives the changed-file scope.
3. Before `$epayment-check`, obtain explicit approval for private-code egress and
   record `egress-approved` with the exact packet hash. Approval covers the current
   branch and changed-file set; any path expansion requires fresh approval.
4. Reviewer invokes `$epayment-check`. The guard accepts `check-complete` only when
   `sprintflow-evidence.mjs` returns clean, exact, same-tree `claude-fable-high`
   and `codex-high` receipts. Each reviewer runs once per tree. Usage, auth,
   transport, findings, unresolved, or unusable output blocks; no substitute or
   automatic retry. CodeRabbit remains optional under `$epayment-check`.
5. Run `$epayment-devtest`. Pause for the user's transfer and migration receipts.
   Record `devtest-complete`; the guard reads only the latest hidden local marker
   and requires exact branch, commit, sorted file set, and grade `PASS`. `WARN` or
   `BLOCK` holds.
6. Guard `PUBLISH` authorizes `$epayment-pr`; no guard command pushes. After the
   skill returns, record `published`. The guard independently verifies one open
   draft PR to `develop`, exact branch/head/files, and remote synchronization.
7. Run `$epayment-polish`, then record `polish-complete`. If the Git tree changed,
   the guard invalidates both reviews and devtest and returns to checking. If only
   PR prose changed, continue to review.

## GitHub loop

Call guard `decide` at intervals no longer than 60 seconds:

- `WAIT`: poll again; never update Jira.
- `REPAIR`: record `repair-authorized`, give the captured failures and comments to
  the implementer, then repeat implement, egress-scope validation, check, devtest,
  `$epayment-pr`, polish, and GitHub validation. Do not use
  `$address-pr-comments`; it embeds the normal lifecycle.
- `SYNC_ONCE`: record `sync-authorized` before the sole allowed Git merge:
  fetched `origin/develop` into the TROUT branch. This is never permission to
  merge the PR or ticket branch into `develop`. Never rebase. Abort a conflict
  completely and hold.
  Record `sync-complete`, then repeat check and devtest. A second sync holds.
- `HANDOFF`: invoke `$epayment-handoff`, then record `handoff-complete` with the
  exact Jira receipt proving success, its idempotency key, evidence-comment ID,
  and a `Code Review` status readback.
- `HOLD`: record `hold`; post at most one deduplicated TROUT blocker comment and
  stop with evidence. Leave Jira status unchanged.
- `COMPLETE`: report readiness and stop. Leave the PR draft and unmerged.

Only a successful repair publication increments the eight-round outer counter.
The guard normalizes sorted unique failing check/workflow IDs and unresolved
GitHub thread node IDs. Hold when round eight is reached or the same signature
survives two repair pushes. Resolve only clear fix/answer/stale threads. Unclear,
disputed, security-sensitive, declined, or scope-expanding feedback holds.

Any Git tree OID change, including docs, tests, config, repair, polish, or base
sync, invalidates both review receipts and devtest. PR/Jira prose alone does not.
External ready, closed-unmerged,
deleted, or mismatched state holds. External merge stops with evidence and never
changes Jira to Done.

## Completion boundary

Completion requires the final local head to match the remote draft PR, clean dual
receipts and devtest PASS to match that tree, checks green, zero actionable threads,
no conflict/required sync, clean polish, one handoff comment, and TROUT verified in
Code Review. QA owns marking ready, two approvals, merge, Done/Deployed, deployment,
production smoke, and every production/admin action.
