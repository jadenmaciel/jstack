## Research Handoff (local addition — keep when vendor skill updates)

Research runs (deep-research or ad-hoc) publish into per-project notebooks so Claude Code and Codex share one corpus instead of re-researching.

- Publish: `"$HOME/.codex/skills/notebooklm/scripts/publish.sh" .research/<slug> [--notebook <id>] [--dry-run] [--max N] [--no-report]` — resolves/creates `<Project> — Research` notebook (cache `.research/<slug>/notebook_id` -> title match -> create), adds evidence URLs deduped + throttled, uploads report.md as text source. Best-effort, always exits 0.
- Consume: user says "ask my notebook X" / "check the notebook" -> `notebooklm list --json`, fuzzy-match title, `notebooklm ask -n <full-id> "<question>"` (skip `--new`: in 0.7+ it destructively deletes the notebook's previous conversation). Always `-n <id>`, never `use` (shared context clobbers parallel sessions).
- Never send Obsidian wiki content, secrets, or client/private material (script refuses `~/Development/Obsidian`; ask first for work dirs, default `--no-report`). Never run `login` unattended.
