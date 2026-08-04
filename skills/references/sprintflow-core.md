# SprintFlow Core

SprintFlow is a small, Matt-first shell. This file owns the shared
`task-entry-matt-first-v1` routing contract for Development worktrees that opt
in (for example troute-fulfillment and Purely). It is not part of the home
shared contract (`~/AGENTS.md`).

When the user introduces a new actionable task in scope, invoke at most one
matching public workflow. A completed workflow may recommend one next command,
but it never invokes that command except for `$check`'s bounded review/fix
loop, `$address-pr-comments`' embedded return-mode `$check`, and phases
explicitly owned by `$cycle` or `$epayment-cycle`.

## Task-entry routing

Precedence: sigil-invoked skill (`$name` or `/name`; a bare English verb does not count) → explicit lifecycle outcome → ticket intake → matching Matt user-invoked workflow → matching model-invoked discipline → no workflow. Use `$ask-matt` only for an actionable engineering or planning request whose workflow is unclear. Casual conversation and unmatched informational questions stay with the root agent.

SprintFlow lifecycle workflows: explicit-only `$cycle` and `$epayment-cycle`,
plus `$start`, `$epayment-start`, `$check`, `$fix`, `$pr`, `$gate`, `$land`,
`$close`, `$epayment-check`, `$epayment-devtest`, `$epayment-pr`,
`$epayment-polish`, `$epayment-handoff`. Explicit `$epayment-cycle` authorizes
its draft-only epayment loop only through `sprintflow-epayment-cycle.mjs`.

Model-invoked disciplines stay outside the user-invoked table, use exact
description matching, and consume the same one-workflow-per-task-entry budget:
`$prototype`, `$diagnosing-bugs`, `$research`, `$tdd`, `$domain-modeling`,
`$codebase-design`, `$code-review`. Unticketed bug, failure, or performance
symptoms remain available to `$diagnosing-bugs`; ticketed work completes intake
first.

## Authority and stopping

- The current request authorizes only its named, bounded outcome. Invoking normal `$check` authorizes its review/fix loop. Explicit `$cycle` authorizes its normal-repository loop only through `sprintflow-cycle.mjs`. Explicit `$epayment-cycle` authorizes its draft-only epayment loop only through `sprintflow-epayment-cycle.mjs`. Automatic routing adds no authority, and neither guard widens the other.
- Read-only discovery is allowed. Ticket Done and handoff transitions belong only to `$close` and `$epayment-handoff`; tracker updates follow `references/tracker-sync.md`. Normal-path PR creation belongs to `$pr`, or explicit `$cycle` through its guard. Cycle phase agents cannot edit lifecycle state or markers. `$address-pr-comments` may push one validated normal repair. Epayment push and draft-PR creation belong only to `$epayment-pr`, including inside explicit `$epayment-cycle`; its guard may authorize one base-into-branch sync but never mark ready or merge the PR. Merge belongs only to `$land` and is never part of either cycle.
- Stop before destructive history changes, credentials, production/admin action, deployment, material scope growth, or an action outside the named skill.
- Make one bounded pass unless explicit `$cycle` or `$epayment-cycle` owns the loop. Outside those loops, do not poll, wait for CI, retry reviews, fan out workflows, reroute, or silently chain. `$check` invokes one `$code-review` for each checked tree and repeats its fix loop while material progress continues. It stops on repeated state, unsafe work, external or human action, or no progress. `$address-pr-comments` runs one embedded normal check, pushes once, and exits. Each cycle may poll at most every 60 seconds, run eight guard-receipted outer repair pushes, and attempt one pre-persisted synchronization. Normal `$cycle` owns its one final Fable attempt; epayment uses the exact-tree dual review already required by `$epayment-check` and never adds another.
- Report unavailable tools as evidence and stop when they are required; advisory-only tools such as Codex Review record `unavailable` evidence and continue instead of stopping. Do not install, authenticate, or substitute authority.

## Research preflight

For non-trivial implementation, do one bounded preflight before editing:

1. Inspect the local repository first.
2. Query an existing, configured project NotebookLM notebook when it can answer project-specific questions.
3. For current library behavior, use Context7: resolve the library ID unless known, then make one normal documentation query. Codex uses the installed app; Claude uses its configured MCP or CLI. Missing configuration is a documented skip—no login, install, retry, or wait.
4. Send Context7 only a public, generic library question. Never send credentials, customer data, ticket text, private project details, or proprietary code. Deep `researchMode` requires an explicit request.
5. Use Firecrawl only for a required public page or an unresolved public-doc gap.
6. For OpenAI or Codex behavior, use `$openai-docs` and current official OpenAI documentation as authority; Context7 is supplementary.

Small, already-defined fixes may skip the preflight and state why.

## Versioned review evidence

- The authority is `~/.codex/logs/sprintflow-review-receipts.jsonl`, managed by `~/.cursor/bin/sprintflow-evidence.mjs`.
- V2 receipts record repository, clone-scoped `repository_common_dir`, `evidence_origin`, optional `upgrade_of`, reviewer, reviewed base/tree, `changed_paths`, and `change_set_oid`. Lookup returns `match_kind: exact|descendant-base` plus current base/tree identifiers.
- Safe descendant-base reuse requires the reviewed base to be an ancestor, identical PR-owned paths and resulting blobs, and no advancing-base change on a reviewed path. Rewritten/divergent bases, content changes, or overlap invalidate it. A legacy or early-v2 receipt may gain one safe append-only upgrade after Git proves its source worktree belongs to the same clone and reconstructs the reviewed change set. Unprovable receipts do not match.
- Compute dirty-tree OIDs through a temporary Git index. Never alter the real index.
- Identical dirty content and its later commit share a tree OID. Any PR-owned content change invalidates prior evidence. Every branch update still requires fresh GitHub integration checks even when content evidence is safely reused.
- A commit SHA, PR body, comment, or conversation may mirror a receipt but is not authoritative.
- `$check` accepts one Codex receipt on any verdict — it is advisory evidence, not a release gate. Epayment requires both independent `codex-high` and `claude-fable-high` receipts for the same tree, and both remain blocking there.
- `skipped-with-reason` is valid only for verified no-code or documentation-only work. `$pr` must inspect the receipt verdict and diff classification; it never satisfies a code-changing release gate.

## Scope classification

`~/.codex/bin/sprintflow-scope.mjs` classifies normal versus epayment/TROUT work from ticket, repository, and branch configuration. `$cycle` uses `assert-cycle-normal`, which permits no ticket but fails closed on epayment, TROUT, non-Git, mismatch, or ambiguity. `$epayment-cycle` uses `assert-epayment` only after a FILL resolves to one canonical TROUT. `$land` and `$close` retain their stricter assertions.

## Output

Use `Summary`, `Evidence`, optional structured `Findings`, and one `Next` recommendation. Specialized skills may also use `Start Brief`, `QA Plan`, or `PR`. Then stop unless `$check` is in its bounded loop or explicit `$cycle` or `$epayment-cycle` is advancing its state machine.
