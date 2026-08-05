---
name: stop-slop
description: Remove AI writing patterns from prose. Use when drafting, editing, or reviewing text to eliminate predictable AI tells.
metadata:
  trigger: Writing prose, editing drafts, reviewing content for AI patterns
  author: Hardik Pandya (https://hvpandya.com)
---

# Stop Slop

Eliminate predictable AI writing patterns from prose.

## Core Rules

1. **Cut filler phrases.** Remove throat-clearing openers, emphasis crutches, and all adverbs. See [references/phrases.md](references/phrases.md).

2. **Break formulaic structures.** Avoid binary contrasts, negative listings, dramatic fragmentation, rhetorical setups, false agency. See [references/structures.md](references/structures.md).

3. **Use active voice.** Every sentence needs a human subject doing something. No passive constructions. No inanimate objects performing human actions ("the complaint becomes a fix").

4. **Be specific.** No vague declaratives ("The reasons are structural"). Name the specific thing. No lazy extremes ("every," "always," "never") doing vague work.

5. **Put the reader in the room.** No narrator-from-a-distance voice. "You" beats "People." Specifics beat abstractions.

6. **Vary rhythm.** Mix sentence lengths. Two items beat three. End paragraphs differently. No em dashes.

7. **Trust readers.** State facts directly. Skip softening, justification, hand-holding.

8. **Cut quotables.** If it sounds like a pull-quote, rewrite it.

## Quick Checks

Before delivering prose:

- Any adverbs? Kill them.
- Any passive voice? Find the actor, make them the subject.
- Inanimate thing doing a human verb ("the decision emerges")? Name the person.
- Sentence starts with a Wh- word? Restructure it.
- Any "here's what/this/that" throat-clearing? Cut to the point.
- Any "not X, it's Y" contrasts? State Y directly.
- Three consecutive sentences match length? Break one.
- Paragraph ends with punchy one-liner? Vary it.
- Em-dash anywhere? Remove it.
- Vague declarative ("The implications are significant")? Name the specific implication.
- Narrator-from-a-distance ("Nobody designed this")? Put the reader in the scene.
- Meta-joiners ("The rest of this essay...")? Delete. Let the essay move.

## Scoring

Rate 1-10 on each dimension:

| Dimension | Question |
|-----------|----------|
| Directness | Statements or announcements? |
| Rhythm | Varied or metronomic? |
| Trust | Respects reader intelligence? |
| Authenticity | Sounds human? |
| Density | Anything cuttable? |

Below 35/50: revise.

## Examples

See [references/examples.md](references/examples.md) for before/after transformations.

## License

MIT

<!-- ===== LOCAL SETUP (this machine) — not upstream; everything above is verbatim from hardikpandya/stop-slop ===== -->

## Local setup (this machine)

**Scope.** Apply stop-slop to **prose deliverables** — docs, READMEs, PR/commit bodies, Jira/Linear ticket
comments, user-facing copy, longform writing. It does **not** apply to terse chat replies or code. caveman owns chat brevity; ponytail
owns code restraint. Where they overlap, stop-slop governs only the prose artifact being written.

**Default: on.** Toggle with `/stop-slop off`, `/stop-slop on`, `/stop-slop status` (or natural language
"stop slop" / "normal mode"). Active state shows as a magenta `[STOP-SLOP]` badge in the Claude Code statusline.

**Shared install.** This file is the canonical copy at `~/.cursor/skills/stop-slop`, used by both Codex and
Claude Code; `~/.claude/skills/stop-slop` is a symlink to it.

**Gates.** Does not override any validation, security, accessibility, test, or review requirement.

## Plain-writing rules (local)

The twelve rules from `~/AGENTS.md`, applied to every prose deliverable alongside the core rules above. They govern prose in docs, PR text, commit messages, and user messages — not code or technical terms.

1. No stale metaphors or figures of speech.
2. Prefer short words.
3. Cut needless words.
4. Prefer active voice.
5. Prefer everyday English over jargon when meaning stays the same.
6. Break these rules before saying something barbarous.
7. Do not build a straw man. Use "not X, it's Y" at most once per piece.
8. Two examples are enough.
9. Do not announce what you will say — say it.
10. Do not end two paragraphs in a row with punchlines.
11. Vary sentence length and shape.
12. Break these rules before writing like a machine.
