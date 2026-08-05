---
name: instruction-optimizer
description: Trim token bloat from your instruction assets (skills, CLAUDE.md/AGENTS.md, plugin & MCP configs, workflow scripts) via a sandbox tournament that never drops a load-bearing rule. Produces per-file diffs + receipts; never auto-applies.
---

# Instruction Optimizer

Shrink the token cost of the instruction assets that load every session, without weakening one rule. One loop, scaled across the whole fleet:

`locked intent + editable asset + locked scorer + capped sandbox tournament + keep only measured winners`

You author the trimmed variants; `scripts/score.py` only **measures**. Safety is a **gate**, not a weight — among candidates that pass every gate, the largest reduction wins. A rule any live skill, hook, or project leans on is **load-bearing**: it stays verbatim, whatever the token cost.

## Safety spine (non-negotiable)

- **Sandbox only.** Every run works on copies under `$TMPDIR/instruction-optimizer-<date>/`. Assert each target's sha256 is identical before and after a run.
- **Never auto-apply.** Output is `winner.diff` + `receipt.md`. Writing a winner onto a live/global file requires the user's explicit approval of that exact diff. `apply-winners.sh` stays gated.
- **No exfiltration.** No network, no LLM or tokenizer call on file contents, no external service. `est_tokens = chars/4`, a labeled estimate.
- **No leakage / no collateral.** No secrets, serials, UUIDs, or tokens in any output. Never read or write old-account paths (`/Users/jadenmaciel-shapiro/**`).

## In scope (local editable instruction TEXT)

- Skills: `~/.cursor/skills/**/SKILL.md` (canonical) and `~/.claude/skills/**/SKILL.md` (synced copies).
- Globals: `~/.claude/CLAUDE.md`, `CLAUDE-omc.md`, `SPRINTFLOW.md`; `~/Agents.md`; `~/.cursor/skills/references/*.md`.
- Plugin assets that are local files: plugin `SKILL.md`, command `.md`, agent-definition `.md`.
- Scripts (do last, different gate -> reference/non-prose-assets.md): `~/.cursor/skills/**/*.workflow.js`, `*.mjs`.

Out of scope: MCP server-provided tool descriptions (not local files), any code/logic file, old-account paths. Skip `~/.cursor/skills/check/SKILL.md` (already optimized).

## Ask first only if ambiguous (0-3 questions)

Which roots to sweep; the reduction bar (default >=15% chars, zero rule loss); any phrase you cannot tell is load-bearing. All clear -> don't ask.

## Steps

1. **Discover + usage triage.** Enumerate every in-scope asset; measure baseline `chars`/`est_tokens` with `score.py`; write `inventory.tsv` ranked by bloat; tag each `prose | config | script`. Then weight by real usage and real dependence:
   - Run the `/codeburn-optimize` skill for what you actually use (it wraps `codeburn optimize --provider all`, `codeburn models --period 30days --provider all`). Heavily-used hot assets: trim conservatively, correctness first. Rarely/never-used assets: trim hard, and flag truly-dead ones for the user to delete (report -- never delete for them).
   - Scan the live projects `/Users/testadmin/Projects/Purely` and `/Users/testadmin/Projects/work/troute-fulfillment` (and `troute-shipping`) for anything an instruction asset names that the project consumes -- ticket prefixes (`SHPPNG-`, `PUR-`, `fill-`), `merchant_id` multi-tenancy, invoked skill/alias names (`$build`, `$check`, ...), referenced paths and commands. Every such token is **load-bearing** -> it must land in that asset's `must_keep`.
   *Done when:* `inventory.tsv` exists, every asset is classed, usage + project-dependence are recorded, and the user has seen the ranked list and batch order. No silent caps -- log every deferred asset.

2. **Lock the rubric (per asset).** Build `rubric.json`: `must_keep[]` (safety/proof/authority lines, every governance rule, every load-bearing project token), `forbidden_new[]` (rule inversions -- `may skip`, `optional`, `auto-apply`), `anchors[]` (referenced paths), `require_frontmatter`, `parse` (`none|json|toml`). For `CLAUDE.md`/`AGENTS.md`/`SPRINTFLOW.md` be strict: every `<HARD-GATE>`, the ticket-routing table, the model-routing ladder, TDD/Spec-Gate, all security + macOS-recovery lines are `must_keep`; when unsure, under-trim. Freeze it.
   *Done when:* `rubric.json` is locked and the unmodified baseline PASSes its own gate (proves the rubric isn't self-failing).

3. **Run the tournament.** Author <=5 trimmed candidates (compress narration, dedupe repeated lists, collapse bullets -- keep every rule, path, threshold, and branch verbatim in meaning). Score each. A candidate is **eligible** iff it PASSes every gate AND is smaller than baseline. Stop early once an eligible candidate clears the bar and trims show diminishing returns.
   *Done when:* there is a measured winner (largest reduction among eligible), or a "no winner" note citing the gate each candidate failed.

4. **Verify the winner -- confabulation-proof.** A path-only reviewer hallucinates; this step exists because one already did -- it returned a confident reject with fabricated line numbers on an intact file.
   - Pass the baseline and winner **CONTENT** into the reviewer, never just file paths.
   - Require **read-proof**: the reviewer quotes exact lines with line numbers for any claimed drift; reject any verdict whose quotes/line-refs don't match the real file.
   - `score.py` is ground truth for gates/metrics only (substring presence, parse validity, char counts); the reviewer owns the semantic call of whether the trim is compression-only. If the reviewer flags drift the gates missed, trust the reviewer and reject the candidate; if the reviewer contradicts a passing gate, re-verify inline rather than re-running the same reviewer.
   - Keep author != reviewer.
   *Done when:* a content-based review agrees with the scorer that the winner is compression-only.

5. **Emit.** Per asset: `winner.diff` + `receipt.md` (scores table, winner + reduction, gate results, source-sha256-unchanged proof, gated apply command). Then one `REPORT.md` (inventory, per-asset reduction, total est. token saving, gate results) and a gated `apply-winners.sh`. Cross-file findings -- duplication, contradiction, dead instructions -- go in a separate findings list to **report**, never auto-merge or auto-delete.
   *Done when:* every processed asset has a `winner.diff` + `receipt.md` (or a logged "no winner" with the failing gate), `REPORT.md` and the gated `apply-winners.sh` exist, and no live/global file has been written.

## Sandbox layout

```
$TMPDIR/instruction-optimizer-<date>/
  scripts/score.py
  inventory.tsv
  runs/<asset-id>-<ts>/
    baseline/<file>      rubric.json
    candidates/cand-1..5.<ext>     scores.tsv
    winner/  winner.diff  receipt.md
  REPORT.md  apply-winners.sh
```

## Stop conditions

- Bar missed on an asset -> recommend narrowing or skipping it; do not overbuild.
- Two reviewer cycles without convergence -> integrate the scorer's ground truth and report; don't loop.
- Non-prose validation profiles: reference/non-prose-assets.md.
