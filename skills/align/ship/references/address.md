# Ship mode: address

Repair one PR: failing checks + unresolved review threads. Validate locally. **Confirm** with the user before push. Push once. Snapshot GitHub once. Exit.

Helper: [gh-comment-api.md](gh-comment-api.md)

## Fetch

Resolve PR (`$ARGUMENTS` or current branch). Collect failing checks and unresolved threads (plus top-level review comments). Stop if both empty.

## Triage threads

Exactly one tag each: `fix` | `answer` | `stale` | `decline`.

Checks: `bot check` (owned by threads) vs `code check` (fix from job log). Do not double-fix bot checks.

## Repair

One item to completion at a time. Smallest change. Re-run the failed check command locally when possible. For threads: reply then resolve (`fix`/`answer`/`stale`). `decline`: draft reply, get user OK before posting; leave open.

## Push latch

After local repairs look good, **confirm** with the user before any `git push`. On yes: commit, push once, reply/resolve known threads, read GitHub status once for that head, exit. Do not poll CI or merge.
