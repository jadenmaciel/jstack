# Verify Tournament Profile Format

Profiles are JSON files. Keep them small; only encode gates that matter for the current tournament.

```json
{
  "profile": "instructions-v1",
  "objective": "min_chars",
  "must_keep": ["Sandbox only."],
  "forbidden_new": ["auto-apply"],
  "anchors": ["references/profile-format.md"],
  "checks": [
    {
      "name": "custom check",
      "command": "python3 -m py_compile {candidate}",
      "timeout": 30,
      "expected_exit": 0
    }
  ],
  "probes": [
    {
      "prompt": "Use the candidate skill on this fixture.",
      "expected_invariants": ["receipt is emitted", "no live file changes"]
    }
  ],
  "review": {
    "required": true,
    "quote_proof": true
  }
}
```

## Keys

- `profile`: use `instructions-v1` for skill, prompt, and instruction text.
- `objective`: `min_chars` chooses the smallest fully passing candidate; `max_passes` chooses the highest gate pass count, then the smallest candidate.
- `must_keep`: exact strings every candidate must retain.
- `forbidden_new`: exact strings no candidate may introduce.
- `anchors`: path or command strings that must remain present.
- `checks`: shell commands run in each candidate sandbox. `{candidate}` expands to the candidate file and `{candidate_dir}` expands to the copied candidate root.
- `probes`: manual or subagent probe prompts. The runner records them; Codex executes them when they are useful.
- `review.required`: `true` for instruction assets unless the user explicitly accepts deterministic-only verification.
- `review.quote_proof`: require line-number quote proof for semantic review.

## Built-In `instructions-v1`

The runner always applies these gates:

- skill frontmatter is present and non-placeholder when the target is `SKILL.md`
- linked relative references exist
- `must_keep` and `anchors` are present
- `forbidden_new` is absent
- `/Users/jadenmaciel-shapiro/**` is absent
- secret-looking strings are absent from content and check output
- `chars` and `est_tokens = chars/4` are recorded
- `quick_validate.py` runs for copied skill folders when available

Semantic equivalence is intentionally not automated. Use a separate reviewer and pass the proof with `--review-pass` and `--review-proof`.
