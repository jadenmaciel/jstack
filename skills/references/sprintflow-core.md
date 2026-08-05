# SprintFlow Core

Cursor SSOT for the SprintFlow contract (`task-entry-matt-first-v1`).
`~/.codex/skills` and `~/.claude/skills` symlink here. Not part of home
`AGENTS.md` noise.

OpenSpec is the default spine. SprintFlow lifecycle skills and Matt Pocock
skills attach by phase — they never replace `/opsx:propose` or `/opsx:apply`.

## OpenSpec spine

Use OpenSpec for almost all product work: new features, API/schema/migration,
auth/security contracts, >3 expected files, multi-session work, or design
ambiguity. `$to-spec` is retired.

Default loop:

```text
[/start] → /opsx:explore → /grill-with-docs → /opsx:propose → /opsx:apply
  → /check → /pr → /land → /close → /opsx:archive
```

Skip `/opsx:explore` when the touch area is already clear. Skip
`/grill-with-docs` when decisions/ADRs are locked. If both skip →
`/opsx:propose`. Small/obvious edits may `/implement` without a change folder.

User-facing `/opsx:*` maps to installed skills: `openspec-explore`,
`openspec-propose`, `openspec-apply-change`, `openspec-archive-change`,
`openspec-sync-specs`. How-to lives in those skills; this file owns policy.
`/opsx:verify` is not installed — do not recommend it.

## Addon skills (by phase)

- Intake: `$start`, `$epayment-start`
- Decide: `$grill-with-docs`, Matt skills (`$tdd`, `$diagnosing-bugs`,
  `$research`, `$domain-modeling`, `$codebase-design`, `$prototype`, …)
- Build: `$implement`, `/opsx:apply`
- Prove: `$check` (+ `$code-review` / `$fix` loop), `$epayment-check`
- Ship: `$pr` / `$land` / `$close`, or `$epayment-pr` → `$epayment-polish` →
  `$epayment-handoff`
- Unblock: `$address-pr-comments`, `$fix-ci`
- Babysit: explicit `$cycle` / `$epayment-cycle` only

## Canonical paths

- Spec: OpenSpec loop above, then ship.
- Small: `$implement` → `$check` → `$pr` → `$land` → `$close`
- External tickets prepend `$start`; TROUT prepend `$epayment-start`
- Multi-session OpenSpec: after `/opsx:propose` → `$to-tickets`
- Hard bugs: `$diagnosing-bugs` → then OpenSpec or `$implement` as fit
- Epayment: … → `$epayment-check` → `$epayment-pr` → `$epayment-polish` →
  `$epayment-handoff` (no `$land`)
- Explicit `$cycle` / `$epayment-cycle` own their loops only via
  `~/.cursor/bin/sprintflow-cycle.mjs` and
  `~/.cursor/bin/sprintflow-epayment-cycle.mjs`

## Task entry

At most one matching public workflow per actionable task. Precedence: sigil
(`$name` / `/name`) → explicit lifecycle outcome → ticket intake → router match
→ matching Matt user-invoked or model-invoked skill by description → none.
`$ask-matt` only when the path is unclear. Casual chat stays with the root
agent. A completed workflow recommends one `Next` and stops, except `$check`'s
review/fix loop, `$address-pr-comments`' embedded `$check`, and phases owned
by explicit `$cycle` / `$epayment-cycle`. Matt and SprintFlow addons share the
same one-workflow-per-task-entry budget.

Situation → Next table: `references/next-skill-router.md`. Registry:
`~/.cursor/sprintflow-backend.json`.

## Next quality

Exactly one user-facing `Next: /name` or `none`. Prefer the OpenSpec phase when
a change is active or a spec trigger matches. Never recommend a ship skill that
skips a required OpenSpec step. When the choice is non-obvious, cite the router
row in Evidence. Do not auto-chain, poll CI, or infer tracker/merge authority.

## Authority and stopping

- The current request authorizes only its named, bounded outcome. Automatic
  routing adds no authority.
- Ticket Done / handoff: only `$close` / `$epayment-handoff` (see
  `references/tracker-sync.md`). Normal PR: `$pr` or explicit `$cycle` via its
  guard. Merge: only `$land` (never inside either cycle). Epayment draft PR /
  push: only `$epayment-pr`.
- Stop before destructive history, credentials, prod/admin, deploy, material
  scope growth, or work outside the named skill.
- One bounded pass unless explicit `$cycle` / `$epayment-cycle` owns the loop.
  `$check` runs one `$code-review` per tree and its fix loop while progress
  continues. Cycles: poll ≥60s, ≤8 guard-receipted outer repairs, one
  pre-persisted sync.
- Required tools missing → stop with evidence. Advisory tools may record
  `unavailable` and continue. Do not install, authenticate, or substitute
  authority.

## Research preflight

For non-trivial implementation, before editing:

1. Local repository first.
2. Project NotebookLM when it can answer project-specific questions.
3. Context7 for public library/SDK docs (one resolve + one query; missing
   config = documented skip).
4. `$agent-reach` for public zero-credential internet fetch.
5. `$last30days` for recent public discourse.
6. Firecrawl only for a required public page or unresolved public-doc gap.

Some of these are skills, not MCP. Never send credentials, customer data, ticket text, private project details, or proprietary code to public tools. Small, already-defined fixes may skip and state why.

## Evidence

- Helper: `~/.cursor/bin/sprintflow-evidence.mjs`. Scope:
  `~/.cursor/bin/sprintflow-scope.mjs`.
- Receipts log stays at `~/.codex/logs/sprintflow-review-receipts.jsonl`
  (do not retarget casually).
- Normal `$check`: fingerprint the tree, one `$code-review`, `$fix` loop.
  Commit SHA / PR body / chat are not authoritative.
- `skipped-with-reason` only for verified no-code / docs-only work.
- Epayment `$epayment-check` still requires same-tree `codex-high` and
  `claude-fable-high` receipts. Those reviewers are **explicit user/CLI or
  designated second-opinion exceptions** to cursor-native-only — never ambient
  spawns from normal `$check`. Unavailable dual evidence blocks epayment PASS.
- Non-mjs helpers (`epayment-gh`, `unattended-preflight`) remain under
  `~/.codex/` for now.

## Output

`Summary`, `Evidence`, optional structured `Findings`, one `Next`. User-facing
`Next` uses `/name` (never `$name`); internal narrative may keep `$name`.
Specialized skills may add `Start Brief`, `QA Plan`, or `PR`. Then stop unless
`$check` is in its loop or explicit `$cycle` / `$epayment-cycle` is advancing.
