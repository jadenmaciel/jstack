# Epayment Guardrails

Load this reference only for `ExpiTrans/epayment` or TROUT work.

## Authority

- TROUT is the canonical ticket. FILL material is external context.
- Work only in the main checkout at `/Users/testadmin/Development/work/epayment`, on a non-`develop` TROUT ticket branch based on `develop`. Never create, enter, or use a linked worktree for `ExpiTrans/epayment`.
- The automation ceiling is a draft PR to `develop`, one handoff comment, and a TROUT transition to `Code Review`.
- Explicit `$epayment-cycle` alone may orchestrate the full guarded epayment loop through `sprintflow-epayment-cycle.mjs`; normal `$cycle` remains fail-closed for this scope.
- Humans own marking ready, approval, merge, Done/Deployed, deployment, production smoke, and production actions.
- Use Atlassian Rovo for issue/context reads and the configured Jira surface for the authorized handoff write. Use `epayment-gh` for PR operations.

## Tenant and data safety

- `merchant_id` is a trust boundary. Every tenant read, write, endpoint, form, job, and migration path must preserve it.
- SQL must be parameterized. Never concatenate tenant or user input into SQL.
- Keep existing authorization helpers and fail closed when tenant identity is missing or mismatched.
- Schema changes require migration, rollback/compatibility reasoning, config-sample parity when configuration changes, and `DatabaseTestCase` mock-schema parity when modeled fields change.
- Never stage or expose `lib/config.inc.php`, credentials, customer data, private logs, or local-only files.

## Proof and review

- Syntax-check changed PHP with `php -l`.
- Run the smallest focused PHPUnit/PHPStan/Selenium proof that exists and applies; document an unavailable harness.
- Apply the generic quality bar before review.
- Every Git tree change requires separate, non-session Claude Fable High and Codex High reviews on the exact same tree OID. The current orchestrator counts as neither reviewer.
- Each mandatory reviewer runs once. Missing, unavailable, findings, mismatched-tree, or unresolved evidence blocks.
- CodeRabbit is advisory: make one opportunistic attempt only when it is already installed and authenticated. Do not install, log in, retry, poll, or block on its absence.

## PR and handoff

- Stage intended files only. Commit subjects include the TROUT key.
- Create or update only a draft PR targeting `develop`; request no human reviewers.
- Outward text is short, factual, first-person, and stripped of AI boilerplate. Never expose agent machinery or proof dumps.
- `$epayment-polish` is mandatory after the draft PR. Stop Slop reviews PR prose; Ponytail reviews the diff. A Git tree change invalidates review and devtest receipts and returns to `$epayment-check`.
- `$epayment-handoff` posts one evidence comment and moves TROUT only to `Code Review`.

## Guided mode

When the user asks to learn, explain phase purpose, tenant risk, important files, and what each proof establishes. Keep implementation moving; do not narrate every line.

## Matt skill mapping

epayment skills invoke mattpocock methods by sigil; both runtimes resolve it:
Claude Code via the `mattpocock-skills:` plugin, Codex via its `~/.codex/skills/`
copy.

| Sigil | Claude plugin | Codex copy |
| --- | --- | --- |
| `$grilling` | `mattpocock-skills:grilling` | `~/.codex/skills/grilling` |
| `$research` | `mattpocock-skills:research` | `~/.codex/skills/deep-research` Quick mode (folded in 2026-07-24) |
| `$tdd` | `mattpocock-skills:tdd` | `~/.codex/skills/tdd` |
| `$code-review` | `mattpocock-skills:code-review` | `~/.codex/skills/code-review` |
| `$diagnosing-bugs` | `mattpocock-skills:diagnosing-bugs` | `~/.codex/skills/diagnosing-bugs` |
| `$domain-modeling` | `mattpocock-skills:domain-modeling` | `~/.codex/skills/domain-modeling` |
| `$codebase-design` | `mattpocock-skills:codebase-design` | `~/.codex/skills/codebase-design` |

`$implement`, `/opsx:propose`, and `$grill-with-docs` are user-only for Matt/OpenSpec planning steps
(`disable-model-invocation: true` on Matt plugin skills) — a skill can route to them but only the
user can type them. `$to-spec` is retired.
