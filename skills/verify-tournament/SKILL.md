---
name: verify-tournament
description: "Use when Codex must test or verify a skill, instruction asset, or prompt by running multiple sandboxed checks/probes, comparing candidates, and emitting evidence. Useful for instruction optimization, skill validation, prompt variants, and \"prove this works\" requests needing more than one check."
---

# Verify Tournament

Run a small verification tournament: fixed target, fixed profile, copied candidates, measured gates, content review when needed, receipt. This complements `$check` and `$gate`; it does not make release decisions.

## Workflow

1. Freeze the target, accepted intent, candidate source, profile, and stop bar.
2. Work only under `$TMPDIR/verify-tournament-*`; never edit or apply to live files.
3. If candidates are supplied, compare them. If not, author up to 5 candidate files in the sandbox, then compare them.
4. Run `scripts/run_tournament.py` with `instructions-v1` unless another profile is explicitly provided.
5. Treat deterministic gates as hard blockers. A candidate with a missing `must_keep`, new `forbidden_new`, bad frontmatter, broken reference link, old-account path, or secret-looking output cannot win.
6. For instruction assets, require content-based semantic review before claiming a clean winner. Pass content, not just paths. Any claimed drift must include real line-number quote proof.
7. Emit `results.tsv`, `receipt.md`, and `winner.diff` when there is a reviewed winner. Report `no winner` when gates or review do not clear.

## Runner

Use:

```bash
python3 /Users/testadmin/.cursor/skills/verify-tournament/scripts/run_tournament.py \
  --target /path/to/SKILL.md \
  --candidate /tmp/cand-1.md \
  --candidate /tmp/cand-2.md \
  --must-keep "Sandbox only." \
  --forbidden-new "auto-apply"
```

Useful flags:

- `--profile-file profile.json`: load the profile shape in `references/profile-format.md`.
- `--candidate-dir DIR`: include sorted `*.md` candidates from a directory.
- `--objective min_chars|max_passes`: default `min_chars`.
- `--review-pass NAME --review-proof review.md`: mark one candidate as independently reviewed. The proof file must contain at least one exact `L<number>: text` quote from the winner.
- `--review-not-required`: only for non-semantic probes or fixtures.
- `--self-test`: run built-in fixture checks.

## Output Rules

- Report the sandbox path, winner/no-winner, failed gates, source sha256 before/after, and exact commands run.
- Do not apply `winner.diff`; live/global writes require explicit user approval of that exact diff.
- If review is unavailable for instruction text, say `review_pending`; do not call the result clean.

## Resources

- `scripts/run_tournament.py`: stdlib-only runner and self-test.
- `references/profile-format.md`: profile keys and examples.
