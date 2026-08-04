---
name: land-ready
description: Make a repo an effective landing environment - grill scope, sweep agent docs against code, add pointers, scaffolding, and a drift guard.
---

# Land Ready

A repo is **land-ready** when anyone — agent or human — can pick up a ticket
and land code without archaeology: every agent doc tells the truth, context
auto-loads where the work happens, and scaffolding keeps it that way. This
skill runs the full sweep; to close drift in one AGENTS.md after a batch of
changes, `agents-update` alone is enough.

## Steps

### 1. Survey

Fan out read-only subagents to inventory, in parallel:

- every AGENTS.md / CLAUDE.md (or equivalent) and what it covers;
- claims in those docs the code contradicts — verify each against source,
  with file:line;
- directories past the repo's size threshold (default: more than 3 non-test
  source files) that have no doc;
- stale references: dead links, deleted trees, renamed commands.

**Done when** you hold an itemized findings list with file:line evidence — no
claim carried forward unverified.

### 2. Grill

Apply the `grilling` skill to the open decisions. Facts come from step 1;
the decisions are the user's. Default agenda:

1. Sweep breadth — which undocumented dirs get docs this round?
2. Scaffolding — which pieces: pointer files, PR template, spec template,
   drift-guard test?
3. Tree state — stack on a dirty tree (commit only files this task owns) or
   branch clean?
4. Tracking — which ticket, or create one?

Skip grilling's router ending; return here. **Done when** the user confirms
shared understanding.

### 3. Execute

Spec first if the repo requires one at this size. Then, in commit-sized
steps:

- Close drift with `agents-update` mechanics: surgical edits, real commands
  and paths only. Document only what the code proves — an inverted invariant
  is worse than a missing doc.
- Author the agreed missing docs from step 1 evidence, matching the repo's
  existing doc template.
- Put a pointer file beside every doc so context auto-loads where work
  happens (for Claude Code: a sibling one-line CLAUDE.md containing
  `@AGENTS.md`).
- Add the agreed scaffolding pieces.

**Done when** every agreed deliverable exists and every doc claim traces to
code read this session.

### 4. Guard

Add a drift-guard test in the repo's native test idiom so the structure
cannot silently rot. Checks that earn their keep:

- every relative link in every agent doc resolves;
- every pointer file has its sibling doc;
- every directory past the size threshold has a doc.

Write it red first against a real stale reference from step 1 when one
exists; the doc fixes turn it green in the same commit.

### 5. Land

Repo's full gate green, then PR per the repo's workflow, branch and commits
carrying the ticket key. **Done when** the PR is open with checks passing.
