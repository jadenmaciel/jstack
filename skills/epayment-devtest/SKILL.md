---
name: epayment-devtest
description: Prove one epayment PR branch end to end on the personal dev box before review.
---

# Epayment Devtest

Standalone dev-box proof for one epayment PR branch. Read
[references/dev-environment.md](references/dev-environment.md) before acting.
Credentials live only in the repo's gitignored `DEV_ENVIRONMENT.local.md` and
never enter output, commits, PR text, or Jira.

## Inputs

- One epayment PR number or TROUT ticket branch, checked out in the main checkout.
- `DEV_ENVIRONMENT.local.md` present at the repo root.

## Hard boundary

This skill tests and reports. It never merges, approves, closes, or transitions
the PR, and never treats its own green evidence as approval — two human
reviewers approve and a PM merges. Green devtest results go in the report only.

## Unique actions

1. Preflight: `git fetch origin develop`; confirm the checkout is the PR branch
   (not `develop`/`master`); read `DEV_ENVIRONMENT.local.md`. The diff is
   merge-base vs `origin/develop`.
2. Deploy: compute the changed-file list from that diff; print ONE `rsync -avR`
   command targeting the box web root for the user to run (suggest `! <cmd>`).
   The agent harness cannot push over SSH. Wait for the transfer receipt before
   testing anything.
3. Migrations: when the diff touches `db/*.sql`, print the exact `ssh` + `psql`
   apply command (migrations are idempotent; reruns are safe) and wait for its
   run receipt.
4. Verify, all the way, every run — build the checklist from the diff, then run
   every applicable tier:
   - Render: `curl` each touched page and doc route; expect HTTP 200 and the
     changed markup present.
   - Login: authenticate as the test merchant; use `headless-browse` when the
     change is UI-visible.
   - API: authed smoke call of each touched `/query` endpoint using the
     test-merchant credentials.
   - Flow: when module code changed, drive the full business flow (fulfillment:
     order -> shipment -> label through the facade with sandbox carriers).
   - Tenancy: one negative check — a request scoped to a different
     `merchant_id` is denied.
5. Record: append a deploy record (branch, commit, file list, UTC date, grade)
   to `DEV_ENVIRONMENT.local.md`, followed by the hidden version-1 JSON marker
   defined in the reference. The box keeps the PR deployed.

## Completion criteria

- Grade `PASS`, `WARN`, or `BLOCK`; every touched surface has a named check
  result; no credential value appears in any output.
- Emit `Summary`, `QA Plan`, `Evidence` (commands and statuses, not secrets),
  optional `Findings`, and one `Next`.

## Next route

PASS: `$epayment-pr` (open or update the PR — merging stays human). Findings:
fix locally, redeploy, retest. Unclear failure: `$diagnosing-bugs`. Stop.


Additional: Use `browser-use` for testing the dev environment https://jaden.expitrans.com/