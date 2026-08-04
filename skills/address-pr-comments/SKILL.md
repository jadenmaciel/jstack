---
name: address-pr-comments
description: "Repair one failing or commented PR, validate locally, push once, snapshot GitHub once, and exit for CI."
---

# Address PR comments

Repair one pull request without babysitting refreshed CI. Fetch the current failures and comments once, repair and validate locally, push once, snapshot GitHub once, and exit.

- A **thread** is one comment chain on the PR -- human or bot (CodeRabbit, Greptile, Claude review).
- A **check** is one CI status on the PR head: a test / build / lint workflow, a Terraform job (`fmt`, `validate`, `plan`), or a review bot's own pass/fail status.

A bot's check and its threads are the same work seen twice: CodeRabbit and Greptile post review threads *and* a failing check, so clearing the threads turns their check green -- don't fix it twice. Code checks -- CI and Terraform -- are separate: they fail in a job log, not on a thread, so you read the failed run and fix the cause.

## 1. Fetch every failing check and unresolved thread

Resolve the PR -- the number in `$ARGUMENTS`, else the current branch's PR -- then pull both lists: every check that is failing, and every unresolved review thread plus any top-level review/issue comments. Commands: [gh-comment-api.md](gh-comment-api.md).

Done when you hold both: each thread's id, root comment id, file:line, author, and body; and each failing check's name, workflow, and log handle. If both are empty, say so and stop.

## 2. Triage

Tag every thread with exactly one action:

- **fix** -- asks for a code change that is correct -> change the code.
- **answer** -- a question -> reply (and change code too if the question exposes a real bug).
- **stale** -- already handled by current code or a later commit -> reply pointing to where.
- **decline** -- wrong, out of scope, or you disagree -> reply with the reasoning; do not resolve.

Classify every failing check:

- **bot check** (CodeRabbit, Greptile) -- owned by its review threads; no separate fix, it clears when those threads are resolved and the bot re-runs.
- **code check** (CI test / build / lint, Terraform `fmt` / `validate` / `plan`) -- read the failed job log, find the root cause, fix it. A `fmt` / `validate` / failing-test failure is a code fix; a `plan` that fails on missing credentials or external state is an environment problem -- surface it, do not fake a pass.

Done when every thread carries one tag, every check is classified, and each carries a one-line planned action.

## 3. Repair and validate

Take one item to completion before the next -- do not batch the fixes. For each thread, and each **code check**:

1. Make the smallest change that satisfies it. For a thread, touch only what it names; for a code check, fix the root cause the log points to. Follow the repo's conventions (TDD if the repo requires it).
2. Verify it with the same command the failed check ran -- `make check`, `terraform fmt` / `validate`, or the failing test.
3. For a thread: reply, then resolve -- see etiquette below. (A code check has nothing to reply to; its proof is the green run.)

After local repairs pass their focused proof, invoke `$check` in embedded return mode with `return_to: address-pr-comments`. `$check` and `$fix` repeat until embedded `$check` returns PASS or `$fix` reaches a documented safe stop. Evaluate the result with `~/.codex/bin/sprintflow-lifecycle-policy.mjs address --snapshot <json>`; only `PUSHED_FOR_CI` permits the single push. Any unresolved finding, warning, or block prevents a push. Done when embedded `$check` returns PASS for the repaired tree.

## 4. Push and report

On PASS, commit and push once. Reply to and resolve each known fix/answer/stale thread using that commit; leave a declined thread open after the required user approval. Read GitHub status once for the pushed head and return `PUSHED_FOR_CI` with every item from the initial snapshot accounted for.

Do not poll, watch refreshed CI, fetch a new failure cycle, merge, or re-enter the workflow. A later explicit `$land` performs its own one-shot gate and queues protected auto-merge when eligible.

Done when one validated repair commit is pushed, known threads are handled, one GitHub snapshot is reported, and the task exits with `PUSHED_FOR_CI`.

## Reply + resolve etiquette

- **fix / answer / stale**: post a one-line reply ("Done in <commit>" or the answer / where it already lives) and resolve the thread -- resolving is the author's job and the done signal.
- **decline**: post the reply explaining why, leave the thread open, and surface it to the user. Disagreeing with a reviewer in public is their call, not yours -- draft the reply but get an OK before posting.
- Replies are plain prose: no emojis, no AI attribution, no tooling references.
