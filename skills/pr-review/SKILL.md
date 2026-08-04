---
name: pr-review
description: Review a pull request and drive it to green — fan out the review, resolve open comments, fix findings, repeat until CI passes and it is merge-ready. Use when the user asks to review a PR, review a diff, or get a PR ready to merge.
---

# PR Review

Take a PR green: current with base, every axis reviewed, every comment resolved, findings fixed, CI passing, ready to merge. No praise, no scope creep.

## Steps

1. Get the diff and PR state. First `gh auth status`; if it fails, stop and
   tell the user to run `gh auth login` — do not review without PR context.
   Then `gh pr diff <n>` plus
   `gh pr view <n> --json state,mergeable,statusCheckRollup,reviews,comments,baseRefName`;
   else `git diff <base>...HEAD`.
   Done when the changeset, CI status, open comments, and base-branch position are all in view.

2. Sync with base. If the branch is behind its base, update it
   (`gh pr update-branch <n>`, or merge the base in and push).
   Done when the branch is even with or ahead of base.

3. Review and grill. Fan out one subagent per axis (a workflow if the diff is large),
   plus a `grill` pass via the `grilling` skill that interrogates the change for the
   questions and risks a sharp reviewer would raise. Each reports findings as
   `file:line severity: problem. fix.`, most severe first.
   - Correctness — logic, edge cases, error handling, off-by-one.
   - Security — untrusted input validated at the boundary, authz, secrets, injection.
   - Scope — change matches the stated intent; stray edits flagged.
   - Tests — new behavior has a test that fails without the change.
   Done when every hunk is checked on all four axes, the grill questions are answered, and findings are collected.

4. Second opinion — large or complex PR only, once per review. Spawn one Cursor
   Task subagent on the Review lane (`grok-4.5` per `model-routing-cursor.mdc`),
   or run `$thermos` when the user asked for a heavy pass. Fold in anything it
   surfaces. Never call `claude -p` or `codex` CLIs.
   Done when a second opinion is folded in, or the PR is small enough to skip.

5. Address. Resolve every open PR comment via the `address-pr-comments` skill,
   and fix every finding from steps 3-4.
   Done when each comment and finding has a commit or an explicit reply saying why not.

6. Take it green. Push, wait for CI. Re-run steps 2-5 on anything red or if base moved;
   the step-4 second opinion fires at most once per review.
   Done when the branch is current with base, CI passes, no review comment is unresolved,
   and the PR is mergeable. Report the final state.
