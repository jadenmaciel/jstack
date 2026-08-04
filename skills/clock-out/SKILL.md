---
name: clock-out
description: Clock out of a task you must leave mid-flight. Stop at a safe breakpoint, preserve uncommitted work so nothing is lost, write a resume checkpoint to HANDOFF.md, and post a status note to the live channel (Jira, GitHub issue, PR, or local doc). The checkpoint lets the next shift resume cold — you tomorrow, or Codex / Claude Code / Cursor. Use when the user is leaving, out of time, wrapping up for the day, or picking the task up later.
---

# Clock Out

You are leaving a task mid-flight. Clock out cleanly: freeze the work into a state the
next shift can resume from without you. The next shift is you tomorrow, or a peer agent
(Codex, Claude Code, Cursor) — the checkpoint reads the same to all of them.

Tracker routing (which CLI hits Jira / GitHub / Linear) and its safety rails live in
`$session-sync` — reuse them. This skill adds the mid-task stop and the resume checkpoint.
Want a full conversation-summary doc for a brand-new agent instead of a resume anchor? Use
`$handoff`.

## Steps

1. **Stop clean.** Start no new work and open no new threads. Land on the nearest safe
   breakpoint: finish the atomic edit in your hands, or back out to the last coherent
   state. Done when no half-applied edit would fail to compile or parse on next open.

2. **Preserve the work — lose nothing.** Every dirty file goes into a named ref you can
   point to: a WIP commit on the task branch (`git commit -am "wip: <task> — see HANDOFF.md"`)
   or a named stash (`git stash push -m "<task> wip"`). Prefer the WIP commit — it survives a
   reboot and is visible. Done when `git status` is clean or every dirty file is captured
   under a ref named in the checkpoint. Never leave work only in editor buffers.

3. **Write the checkpoint → `HANDOFF.md` at the workspace root.** This file is the
   cross-agent sync channel: whoever resumes reads it first. Use the template below. The
   field that carries the most weight is the **exact next action**. Done when a fresh agent
   with zero memory could resume from this file alone — task, where you stopped, the ref
   holding the WIP, the next step, and how to verify.

4. **Post the status note to the live channel.** Where the task actually lives — Jira /
   TROUT ticket, GitHub issue, or PR — gets one concise status comment (template below).
   No live channel? `HANDOFF.md` is the record. Done when the channel shows current status
   plus a pointer to `HANDOFF.md`, or you have named the exact gate (credential / login)
   that blocked the post.

5. **Report the clock-out.** Print: what was frozen, the ref holding the WIP, the
   `HANDOFF.md` path, the one-line resume incantation, and any gated post left unwritten.

## Checkpoint template (HANDOFF.md)

```md
# HANDOFF — <task / ticket>
Updated: <date> · Branch: <branch> · WIP ref: <commit sha or stash name>

## Where I stopped
<1-3 lines: state of play, what just changed>

## Next action  ← start here
<the single exact next step; command or file:line when known>

## Open threads
- <decision pending / question / thing half-investigated>

## Verify
<command(s) that prove the resumed work is correct>

## Resume with
- Claude Code / Codex / Cursor: read this file, then continue from "Next action".
- Suggested skill: <$implement / $check / ...>
```

## Status comment (live channel)

```md
Clocking out mid-task — <in progress / blocked / in review>.
- Done so far: <changed paths / PR surface>
- Next: <exact next action>
- State frozen in HANDOFF.md @ <branch>, WIP ref <sha / stash>.
- Blockers: <only real ones>
```

## Rails

- Lose nothing: work lives in a named ref before you leave, not just buffers.
- Clocking out is status-only — do not close, merge, release, or transition on the way out.
- Redact secrets, tokens, and PII from the checkpoint and the comment.
- Separate repo state from tracker / CI / release state; report only what is true.
