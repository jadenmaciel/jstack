---
name: x-research
description: Use when the task needs live posts from X/Twitter, or when deep-research needs its X pass.
argument-hint: "X search query or topic"
allowed-tools:
  - Bash(python3 *)
  - Bash(grok *)
  - Bash(command *)
  - Bash(mkdir *)
  - Bash(test *)
  - Read
---

# x-research

Search X through authenticated Grok. The ledger cites post URLs.

## 1. Scope

One QUERY. Optional: `@handles` (max 20), `from_date` / `to_date` (YYYY-MM-DD). Default window: last 30 days.

Done when QUERY is a single string and filters are listed or explicitly none.

## 2. Run

```bash
python3 "$HOME/.cursor/skills/x-research/scripts/search.py" \
  --slug "<slug>" --query "<QUERY>" \
  --out ".research/<slug>/x-research"
```

Add `--handle @foo` (repeat), `--from YYYY-MM-DD`, `--to YYYY-MM-DD` when scoped.

The script preflights `grok` + `~/.grok/auth.json`, writes `raw.json` + `posts.json`. On auth miss it prints the exact fix and exits 1 — tell the user that line.

Done when `posts.json` has a `posts` array. Empty array requires a non-empty `gaps` string naming what X did not return.

## 3. Ledger

Each kept row is `url` + `handle` + `quote` (optional `posted_at`, `engagement`). Engagement is salience. Cite the post URL.

Done when every kept claim maps to an `https://x.com/...` or `https://twitter.com/...` URL.

## 4. Deliver

Standalone: short summary plus `[@handle](url)` — quote for every kept post.
From deep-research: leave artifacts in `--out` and return.

Done when that shape is on screen, or the caller has `posts.json`.
