---
name: slop
description: Answer an empirical question, or explore/test something about real code, by building and running throwaway code in ~/slop/ — harnesses, lint rules, load tests, ports, API probes. Never merged. Use whenever disposable code would answer, explore, or test something faster or more reliably than reasoning about it.
argument-hint: "<question or theory> [repo path]"
allowed-tools: Bash, Task, Read, Write, Edit
user-invocable: true
---

# Slop

Some questions are cheaper to answer, or explore, by running code than by reasoning about it. Slop is that code: built to answer or explore one thing, run once or a few times, then thrown away. The finding is the deliverable; the code is trash — the same throwaway spirit as `$prototype`, aimed at empirical questions and exploration about existing code instead of design questions about new code.

## 1. Name the question or goal

One sentence, stated up front in the report and in `NOTES.md` — a question ("Does this endpoint leak the internal ID under load?") or an exploration goal ("See how this API behaves under a malformed payload"). Either way, name it before building anything so the report and `NOTES.md` stay anchored to what was being found out.

## 2. Open a workspace

```sh
mkdir -p ~/slop/<repo-name>/<yyyy-mm-dd>-<slug>/
```

Start `NOTES.md` there with the question as the first line. This directory, not the product repo, is where every file below gets written.

## 3. Build and run

Do the work through `sonnet` subagents (`haiku` for bulk or deliberately-dumb roles — see the API-usability recipe). Reference the product repo **read-only, by absolute path**; no subagent writes inside it, and slop is never staged, committed, or merged into any product repo. Feed subagents real file content inline, not bare paths.

Read-only means read-only even for side effects a language runtime adds without being asked — importing a module by path can drop a bytecode cache next to it, running a linter can write a report file, opening a project in some tools writes an index. Copy the referenced file(s) into the workspace before running anything against them (or set the runtime to skip its cache, e.g. `PYTHONDONTWRITEBYTECODE=1`), and check the product repo's `git status` after the run to confirm nothing landed there.

Run autonomously — don't stop to ask before building or running local probes. The one boundary: cost- or credential-gated targets (a cloud load test, a paid API, anything that spends money or touches prod credentials) get named to the user before running.

## 4. Report the finding

Lead with the answer, then the evidence (output, numbers, diffs against expected). Write the same answer into `NOTES.md` under the question.

## 5. Retention

`NOTES.md` stays — it's the keepsake. Everything else is disposable: offer the `rm -rf` of the workspace, don't run it unasked.

## Promote

Sometimes a probe earns a second life — a lint rule that catches real violations, a load test worth re-running each release, a debug harness you'd reach for again next month. When that happens, promote it: rebuild it inside the repo as normal code via `$tdd` or `$implement`. The probe is the spec, not the source — never copy slop into the repo wholesale, because slop is written unreviewed and untested by design. Slop itself is still never merged; only the rebuild ships.

## Recipes

**Verification harness / custom debugger** — write a small instrumented entry point (extra logging, assertions, a repro script) that exercises the real code under the condition in question; run it; report what it showed.

**Custom lint rule** — write a one-off rule (grep/AST/regex, whatever's fastest) for the pattern in question, run it across the repo, report every match as a candidate, not a confirmed bug.

**Load test** — local or dev targets only by default; a cloud/AWS target needs explicit user instruction first (Ask boundary). Report latency/error numbers, not a pass/fail guess.

**Slop-port** — port the module in question to another language or approach, run the product's real test suite against the port, report pass/fail per test. The port is never the deliverable; the test result is.

**API-usability fan-out** — spawn N `haiku` workers (chosen for being the least capable, most literal readers available) with nothing but the API's public surface; have each attempt the target task cold. Workers succeeding cleanly is evidence the API is usable; workers stumbling on the same spot is evidence the API needs a fix, not the workers.

## Next

Finding implies a product change, or the probe itself proved durable enough to promote (rebuild in-repo) → `$tdd` or `$implement`. Finding is really a design question → `$prototype`. Otherwise: return to whatever invoked `$slop`.
