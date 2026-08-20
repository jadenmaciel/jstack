---
name: ticket-start
description: Scope-lock one ticket, then hand off to /start or /epayment-start. Use when the user says /ticket-start or wants a single-session scope lock before intake.
---

# Ticket-start

One ticket. One session. Scope first. Does not replace `/start` or `/epayment-start`.

## Do

1. **Confirm single session.** If other product agents are implied, warn once: comprehension latch prefers one live session. Continue only if the user insists.
2. **Capture:** ticket ID, repo, one-sentence goal.
3. **Scope lock (ask once):** what this ticket must not touch. Record the answer. Default for fulfillment-only: booking module off-limits unless user overrides.
4. **Handoff only (stop after Next):**
   - Epayment/TROUT → `Next: /epayment-start` (pass the ticket URL/key).
   - Otherwise → `Next: /start`.
5. Do **not** run `/grill-with-docs`, `/to-spec`, or intake yourself.

## Do not

- Open a second workstream.
- Skip the scope lock.
- Skip `/start` or `/epayment-start` checks by chaining grill/spec here.
- Install new skills mid-start.

## Next

TROUT → `/epayment-start`. Else → `/start`.
