---
name: ship
description: >-
  Verify, review, deep-audit, address PR comments, or drive a PR green.
  Modes: gauntlet (gates only), review (Standards+Spec on a local diff),
  thermos (parallel thermo audits), address (comments+CI repair, push once),
  green (default full PR-green loop). Use /ship gauntlet for verify-only.
  Replaces former /gauntlet /code-review /pr-review /address-pr-comments /thermos.
---

# Ship

Parse `$ARGUMENTS` for a mode. Default mode is `green`.

| Mode | File |
|------|------|
| `gauntlet` | [references/gauntlet.md](references/gauntlet.md) |
| `review` | [references/review.md](references/review.md) |
| `thermos` | [references/thermos.md](references/thermos.md) |
| `address` | [references/address.md](references/address.md) |
| `green` | [references/green.md](references/green.md) |

Load only the matching reference. Do not load all modes.

## Hard rules

- Self-contained. Do not invoke retired slash skills (`/gauntlet`, `/code-review`, `/pr-review`, `/address-pr-comments`, `/thermos`, `/check`, `/fix`, `/land`).
- Before any `git push` or merge, **confirm** with the user (AskQuestion or explicit yes). No silent push.
- Cursor-native review only. No `claude -p` or `codex` CLIs unless the user invoked `/double-review`.
