# Next Skill Router

Authority: `~/.cursor/skills/references/sprintflow-core.md`. OpenSpec is the
default spine; SprintFlow + Matt skills attach by phase.

Recommend exactly one route and stop. Never invoke it except for `$check` /
`$epayment-check` bounded `$gauntlet` and `$thermos` substeps and the
progress-guarded check → `$fix` → check loop.

User-facing `Next` lines write `/name` (never `$name`). Internal narrative may
keep `$name`. Exactly one `/name` or `none` per Next — never two skills in one
cell.

`$to-spec` is retired. Spec-worthy default: `/opsx:explore` →
`/grill-with-docs` → `/opsx:propose` → `/opsx:apply`. Skip explore when the
touch area is clear; skip grill when decisions/ADRs are locked; if both skip →
`/opsx:propose`. Prefer OpenSpec whenever a change is active or a spec trigger
matches. When a change is active, clean `/check` routes through
`/opsx:verify` before `/pr`; after `/close` Done with a matching
change, route `/opsx:archive`.

| Situation | Next |
|---|---|
| Unsure which path fits | `/ask-matt` |
| Big diff, commit, or PR needs a comprehension pass before reading it raw | `/diffsum` |
| Empirical question faster to answer by running throwaway code than by reasoning | `/slop` |
| Small, well-defined change (no OpenSpec change active) | `/implement` |
| New feature, API/schema/migration, auth/security contract, >3 expected files, multi-session, or design ambiguity | `/opsx:explore` |
| Codebase area mapped (after `/opsx:explore`, or explore skipped) | `/grill-with-docs` |
| Scope grilled and decision-complete; meets a spec criterion | `/opsx:propose` |
| Scope grilled and decision-complete; no spec criterion | `/implement` |
| OpenSpec change artifacts ready; one session | `/opsx:apply` |
| OpenSpec change needs multiple sessions | `/to-tickets` |
| Hard bug or unclear failure | `/diagnosing-bugs` |
| Implementation or clear correction is complete | `/check` |
| Normal `$check` needs project gates before review | `$gauntlet` |
| Normal `$check` has green gauntlet and fingerprinted its current tree | `$thermos` |
| `$check` or `$epayment-check` reports structured findings | `$fix` |
| `$fix` changed the tree or added decisive evidence after `$check` | `$check` |
| `$fix` changed the tree or added decisive evidence after `$epayment-check` | `$epayment-check` |
| Epayment `$epayment-check` needs project gates before review | `$gauntlet` |
| Epayment `$epayment-check` has green gauntlet and fingerprinted its tree | `$thermos` |
| Non-epayment check is clean and an OpenSpec change is active | `/opsx:verify` |
| Non-epayment check is clean and no OpenSpec change is active | `/pr` |
| `/opsx:verify` is clean (or skipped: no active change) | `/pr` |
| Normal-path PR is open and current | `/land` |
| Human wants a read-only landing preview | `/gate` |
| Gate says `READY_FOR_LAND` or `READY_FOR_AUTO_MERGE` | `/land` |
| Land says `QUEUED_FOR_MERGE` | `none` |
| Normal PR is confirmed merged | `/close` |
| `/close` Done and matching OpenSpec change still active | `/opsx:archive` |
| Epayment intake complete and scope is small | `/implement` |
| Epayment intake complete and scope is spec-worthy | `/opsx:explore` |
| Epayment implementation complete | `/epayment-check` |
| Epayment check clean | `/epayment-pr` |
| Epayment draft PR current | `/epayment-polish` |
| Epayment polish clean | `/epayment-handoff` |
| Work is blocked | `none` |

External normal tickets prepend `/start`; TROUT/epayment tickets prepend
`/epayment-start`.
