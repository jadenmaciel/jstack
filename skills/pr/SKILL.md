---
name: pr
description: Commit, push, and open one normal-path PR after a clean check.
---

# PR

Normal-path PR boundary. Read the shared core and router. This is the only skill that pushes or opens a PR on the normal path; epayment work uses `$epayment-pr`.

## Inputs

- The ticket ID and an acceptable content receipt for the current PR-owned changes. Lookup may return a native v2 receipt or a safe upgraded legacy/early-v2 receipt.
- Intended ticket branch and file set.

## Unique actions

1. Run `~/.codex/bin/sprintflow-scope.mjs assert-normal --ticket <ID> --repo <path> --branch <name>`. Any nonzero result refuses epayment/TROUT or ambiguous scope with `Next: $epayment-pr`.
2. Verify the branch is a ticket branch, not `main`/`master`/`develop`, classify the diff as code-changing or verified no-code/documentation-only, and confirm it belongs to the ticket.
3. Confirm `$check` graded this exact tree: re-run `~/.cursor/bin/sprintflow-evidence.mjs fingerprint --repo <path> --base <rev>` and require its `tree_oid` to equal the one in the `$check` report, on a `PASS` or `WARN` grade. A missing report, a mismatched `tree_oid`, or changed PR content is HOLD with `Next: $check`.
4. Stage intended files only. Refuse unrelated or denied files.
5. Commit with the ticket key and push the ticket branch.
6. With `gh`, create or update one PR targeting the repository default base. Open it ready (not draft) — the normal path has no separate ready step and `$gate` holds on draft. Keep title/body short and factual: ticket, behavior, proof, and any migration/config notes that matter. Request no human reviewers. Confirm the repo squashes from the PR body (`gh api repos/<owner/repo> --jq .squash_merge_commit_message` returns `PR_BODY`; if not, set it per the AGENTS.md Attribution rule) so the merged commit takes this body and no branch-commit `Co-authored-by:` agent trailer leaks in. End the body with a `## Changes by file` section: the `$diffsum` report for the PR range (fresh subagent summaries from the real diff). Verify URL, open state, `isDraft=false`, base, head branch, head SHA, and changed files. **Attribution strip (required):** immediately after create/update, read `gh pr view <n> --json body -q .body`. If it contains `Made with [Cursor]` or `Made-with: Cursor`, strip those lines with `gh pr edit` and re-read until clean. Never report success while that footer remains (Cursor may inject it even when attribution settings are off).
7. Move the ticket to In Review and comment the PR link per `references/tracker-sync.md` (owned tickets only; a tracker failure is reported, never blocks the PR).
8. Do not transition the ticket to Done and do not merge.

## Completion criteria

- The remote PR is confirmed open and non-draft at the accepted tree.
- Emit `Summary`, `Evidence`, `PR`, optional `Findings`, and one `Next`.

## Next route

Normal-path PR open and current: `$land`. Humans and `pr-queue-operator` may use `$gate` as a read-only preview. Any changed tree: `$check`. Stop.
