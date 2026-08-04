# Next Skill Router

Recommend exactly one route and stop. Never invoke it except for `$check`'s bounded `$code-review` substep and the progress-guarded `$check` → `$fix` → `$check` loop.

`$to-spec` is retired. Spec-worthy default: `/opsx:explore` → `$grill-with-docs` → `/opsx:propose` → `/opsx:apply`. Skip explore when the touch area is already clear; skip grill when decisions/ADRs are already locked; if both skip, go to `/opsx:propose`.

| Situation | Next |
|---|---|
| Unsure which path fits | `$ask-matt` |
| Big diff, commit, or PR needs a comprehension pass before reading it raw | `$diffsum` (big-diff comprehension helper; routes on to `$fix`/`$code-review`/`$pr`) |
| Empirical question about real code is faster to answer by running throwaway code than by reasoning | `$slop` (empirical-probe helper; returns to the invoking context when done) |
| Small, well-defined change | `$implement` |
| New feature, API/schema/migration, auth/security contract, more than three expected files, multiple sessions, or meaningful design ambiguity | `/opsx:explore` |
| Codebase area mapped (after `/opsx:explore`, or explore skipped because area already clear) | `$grill-with-docs` |
| Scope is grilled and decision-complete and meets a spec criterion above | `/opsx:propose` |
| Scope is grilled and decision-complete but meets no spec criterion above | `$implement` |
| OpenSpec change artifacts ready; one session | `/opsx:apply` |
| OpenSpec change / approved spec needs multiple sessions | `$to-tickets` |
| Hard bug or unclear failure | `$diagnosing-bugs` |
| Implementation or clear correction is complete | `$check` |
| Normal `$check` has fingerprinted its current tree | `$code-review` (invoke once, then resume `$check`) |
| Normal `$check` reports one or more structured findings | `$fix` (invoke now) |
| `$fix` changes the tree or adds decisive evidence | `$check` (invoke now) |
| Non-epayment check is clean, including documentation-only | `$pr` (if an OpenSpec change is still active, recommend `/opsx:verify` first) |
| Normal-path PR is open and current | `$land` (self-gate once) |
| Human or queue operator wants a read-only landing preview | `$gate` |
| Gate says `READY_FOR_LAND` | `$land` |
| Gate says `READY_FOR_AUTO_MERGE` | `$land` (queue once, then stop) |
| Land says `QUEUED_FOR_MERGE` | `none` |
| Normal PR is confirmed merged | `$close` |
| Epayment intake is complete and scope is small | `$implement` |
| Epayment implementation is complete | `$epayment-check` |
| Epayment check is clean | `$epayment-pr` |
| Epayment draft PR is current | `$epayment-polish` |
| Epayment polish is clean | `$epayment-handoff` |
| Work is blocked | `none` |

External normal tickets prepend `$start`; TROUT/epayment tickets prepend `$epayment-start`.
