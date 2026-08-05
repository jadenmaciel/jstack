---
name: diffsum
description: Per-file comprehension summary of a diff — function-signature deltas and numbered flags, not a review. Use when the user wants to understand a big diff, commit, or PR without reading it raw, or asks to "summarize the diff" / "what changed".
argument-hint: "[ref | range] (default: uncommitted changes, else branch vs merge-base)"
allowed-tools: Bash, Task, Read
user-invocable: true
---

# Diffsum

A diffsum is a **map of a diff**, not a verdict on it. It tells you what changed — signatures, deletions, dependencies — so anything weird surfaces immediately. It never says a change is correct.

## 1. Resolve the range

- `$ARGUMENTS` contains `..` → use it verbatim as the range.
- `$ARGUMENTS` is a single ref → range is `<ref>...HEAD`.
- No arguments, dirty tree → range is the working tree against `HEAD` (`git diff -M -C HEAD`); list untracked files by name only, never diff them.
- No arguments, clean tree → range is `HEAD` against the merge-base with the default branch (`git symbolic-ref refs/remotes/origin/HEAD`).
- No arguments, clean tree, already on the default branch → stop: "nothing to summarize."

Validate every ref with `git rev-parse` before using it. A bad ref fails here, not inside a subagent.

Completion: the range is a single git-diff-shaped argument, or you've stopped with nothing-to-summarize.

## 2. Stamp the report

Header carries three facts so a stale report is never mistaken for current: `HEAD` SHA, dirty or clean, and a `shasum` of the exact diff being summarized (`git diff <range> | shasum`).

## 3. Classify every file (deterministic, no subagent)

Run `git diff <range> --name-status -M -C` and `git diff <range> --numstat`. Sort each file into:

- **binary** — numstat shows `-\t-`.
- **lockfile** — `pnpm-lock.yaml`, `*.lock`.
- **generated** — under `dist/`, `build/`, or matching `*.min.*`.
- **oversize** — over ~400 changed lines in one file.
- everything else → fan-out (step 4).

Each sorted-out file gets one line: `NOT SUMMARIZED (<reason>, +X/−Y)`. Never write a partial summary for these — the reason line is the complete, honest answer.

Completion: every file from `--name-status` is either routed to fan-out or already has its `NOT SUMMARIZED` line.

## 4. Summarize each file

Every summary comes from the **raw per-file diff** — `git diff <range> -M -- <file>` — never from memory of what you changed. That's the one hard rule; who does the summarizing is a size call:

- **Small diff** (roughly ≤8 files and ≤2k diff lines) → summarize in-context yourself, one file at a time, under the step-5 contract.
- **Large diff, or you authored the change and want a disinterested second pass** → fan out one `sonnet` subagent per remaining file. Batch files under ~50 lines together, up to ~400 lines per batch. Hard cap: 8 subagents at once — past the cap, summarize the largest/highest-risk files and add one line naming how many were left out. Pass each subagent the **raw diff content inline**, never a bare file path.

## 5. The summarizer contract

Give every summarizer — a subagent, or yourself when summarizing in-context — this exact brief:

> Summarize this diff hunk for a reader who will not read the raw diff. Two sections:
> - **Changed** — one line per added (`+`), modified (`~`), or removed (`−`) function/method/type signature. Quote the exact diff line(s) backing each claim.
> - **Other changes** — one line each for everything that isn't a signature change (body edits, comments, imports, formatting).
>
> Account for every `@@` hunk in the diff — if a hunk doesn't fit either section, say so. If the diff is a partial declaration (truncated by batching) and you cannot tell what changed, reply `AMBIGUOUS` and nothing else.
>
> End with a coda: either `FLAG:` lines (see flag list) or the line "no flags — plain summary, not a correctness claim."
>
> Write every line in plain language a new coder on this repo could follow — expand jargon and abbreviations rather than assuming the reader already knows them.

An `AMBIGUOUS` reply gets re-dispatched once, with the full post-change file content inline instead of just the diff hunk.

## 6. Flags

Six, and only six — a subagent that invents a seventh folds it into the closest one or drops it:

| Flag | Meaning |
|---|---|
| `[scope]` | file wasn't an obvious part of the stated change |
| `[api]` | a public signature changed or was removed |
| `[del]` | something was deleted that's still referenced elsewhere |
| `[deps]` | a dependency or lockfile changed |
| `[sec]` | touches auth, crypto, secrets, or input parsing |
| `[untested]` | source changed with no matching test change |

## 7. Reconcile

Compare the assembled report against the `--name-status` list from step 3. Any file with no section — a crashed subagent, a dropped batch, a missing coda — gets an explicit `NOT SUMMARIZED (no report returned)` line. A diffsum with a silent gap is worse than no diffsum.

## 8. Cross-file pass

One more pass — in-context, or a `sonnet` subagent if you fanned out in step 4 — over every per-file summary, `git diff <range> --stat`, and the same six-flag list from step 6, to find flags that only show up across files: a rename applied to 9 of 10 call sites, a signature change with one caller left behind. Restate the flag list; a summarizer left to name its own categories will invent labels outside the six. This pass adds flags only; it doesn't repeat step 5's per-file work.

## 9. Report

```
Diffsum: N files, M flags (base: <range>)

1. [flag] file:line — one line
2. ...

## src
<file> — Changed / Other changes / coda

## tests
...

## config
...

## NOT SUMMARIZED
<file> — reason, +X/−Y
...

---
facts carry receipts; flags are judgment; no correctness claim.
```

Numbered flags carry receipts (quoted diff lines); prose summaries don't need to. Keep every flag and summary line plain enough that a new coder can follow the report without reading the diff. Never write "LGTM", "looks good", or "no issues" — those are review verdicts, and a diffsum isn't a review.

## Next

Flags present → `/fix` or `/code-review`. Clean and ready to ship → `/pr`. Need to trace a symbol deeper than this diff shows → `/codegraph`. Otherwise: stop.

---

Deferred (`ponytail:` not needed for v1): tree-sitter/ctags signature extraction — `git diff -W` (function-context diff) is the escape hatch if manual parsing gets unreliable; a Stop-hook trigger; a workflow `.js` version for very large diffs; multi-voter summarization.
