---
name: fix-ci
description: Fix failing CI on a GitHub pull request. Use when a PR's checks are red, a workflow run failed, a required check blocks merge, or the user asks to make the build/pipeline green.
---

# Fix failing CI

Drive the red check **green locally before you push**. Pushing a guess and waiting on CI is the slow, blind loop this skill replaces: every fix is reproduced and verified on your machine first, so the push confirms a fix instead of testing one.

## 1. Find the red checks
- Resolve the PR: use the number/URL the user gave, else `gh pr view --json number,headRefName` for the current branch.
- `gh pr checks <pr>` — list every check, note which are FAIL.
- Done when: you have the name of every failing check. No failures -> say so and stop.

## 2. Read the real failure
- Map each red check to its run and pull the failing log: `gh run view <run-id> --log-failed`.
- Quote the actual error — compile error, failing assertion, lint rule, exit line — not the summary banner.
- Done when: every red check has its exact error text in hand.

## 3. Reproduce red locally
- Find the command the step ran (read `.github/workflows/*.yml`), run that same command locally (this repo: `make check`, or the single failing target).
- Confirm it fails the same way.
- Won't reproduce? See [Non-reproducible failures](#non-reproducible-failures).
- Done when: the failure is **red** on your machine, or documented as non-reproducible with a named hypothesis.

## 4. Fix the root cause
- Fix what made it fail, following the repo's normal fix path (TDD, spec gate, scoping rules).
- Cause, not symptom. Do not skip/disable the check or loosen the gate to pass it unless that is genuinely correct — and then say why.

## 5. Verify green locally
- Re-run the exact command from step 3. It must pass.
- Run the repo gate (`make check`) green too — the fix must not redden another check.
- Done when: the command that was red in step 3 is now green locally.

## 6. Push and confirm green
- Commit (no AI attribution) and push to the PR branch.
- Watch it land: `gh pr checks <pr> --watch`.
- Done when: every check from step 1 is green. Any still red -> back to step 2 with the new log.

## Non-reproducible failures
Can't get it red locally (version-pinned linter, missing secret, infra, env-only):
- Match CI's exact version and flags (read the workflow) before blaming infra.
- Flaky / timeout / runner error with no code cause: re-run once (`gh run rerun --failed <run-id>`), if it greens, call it flaky.
- Still red and not reproducible: stop, report the log plus your hypothesis. One unverified push, max — never loop speculative fixes.
