# Reflect

Diagnose leverage from session transcripts. Do not build it.

Reflection findings are also the usage evidence behind every `DISABLE` and `UNINSTALL` call in [`audit.md`](audit.md). Missing usage data is not evidence that an item is unused.

## Inputs

- Scope from the prompt. Default: general setup leverage. If the prompt names `skills`, `workflows`, `automations`, hooks, config, or another type, restrict candidates to that type.
- Time range from the prompt. Default: recent sessions from the last 30 days.
- Transcript roots:
  - Claude: `/Users/testadmin/.claude/projects/**/*.jsonl`
  - Codex: `/Users/testadmin/.codex/sessions/**/*.jsonl`
  - Codex archive: `/Users/testadmin/.codex/archived_sessions/*.jsonl`
  - Codex index: `/Users/testadmin/.codex/session_index.jsonl`
  - Retention archive (fallback for transcripts pruned from the live roots): `/Users/testadmin/.codex/reflection-archive/{claude,codex}/**`. Prefer the live copy when both exist; deduplicate by internal source identity, not filename. Report source gaps (index entries with no resolvable transcript in either live or archive) as redacted labels and counts only.

## Process

1. Inventory sessions. Prefer indexes and metadata first; then read only transcript excerpts needed to identify friction. Record every cap or skipped root.
2. Fan out raw extraction only when Sonnet or Haiku subagents are available. Use Haiku for broad transcript scouting and Sonnet for messy extraction. If only other-model subagents are available, do not use them; run inline or use an already configured Claude lane that can satisfy Sonnet/Haiku.
3. Give extractors this bounded job: return raw signals only: non-path source label, date, runtime, observed friction, repeated action, failed assumption, possible label, and brief redacted evidence. They must not cluster, rank, or recommend builds.
4. Cluster signals in the main session. Merge duplicates by underlying setup friction, not wording.
5. Check existing coverage before recommending a new skill: search current skill names/descriptions and recent notes. Existing coverage downgrades to `fix` or `nothing` unless the evidence shows the existing asset repeatedly fails.
6. Rank clusters by leverage: recurrence, pain/time saved, confidence, and build cost. Prefer cheap fixes over new machinery when they solve the same recurrence.
7. Write `reflection-notes.md` with ranked candidates first and evidence below each candidate. End with diagnosis-only status.

Done when `reflection-notes.md` exists, cites sources behind each ranked call with date/runtime/non-path labels, and contains no build/edit instructions beyond proposed next actions.

## Labels

- `skill`: recurring across at least 2 distinct sessions, needs judgment or process memory, and is not already covered by a working skill.
- `workflow`: recurring multi-step orchestration issue, only when workflows are in scope.
- `automation`: repeated deterministic task with low judgment and a stable trigger.
- `fix`: broken config, tool, prompt, path, permission, or instruction causing friction.
- `nothing`: one-off, low leverage, too costly, already solved, or insufficient evidence.

Only propose `skill` for something that actually recurs.

## reflection-notes.md

Use this shape:

```md
# Reflection Notes

## Ranked Assessment

1. <candidate> - <label> - <why this is highest leverage>

## Candidates

### 1. <candidate>
- Label: <skill|workflow|automation|fix|nothing>
- Rank rationale: recurrence <n sessions>; pain <low|medium|high>; confidence <low|medium|high>; build cost <low|medium|high>
- Evidence: <date/runtime/non-path label>; <date/runtime/non-path label>
- Observed pattern: <redacted summary>
- Recommendation: <diagnosis-only next action>
- Why not the other labels: <short reason>
- Do not build yet: this report is assessment only.

## Coverage Notes

- Scope: <scope>
- Sources searched: <source labels/counts>
- Caps/skips: <none or explicit list>
```
