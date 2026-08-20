#!/usr/bin/env bash
set -euo pipefail

# SessionStart env-map (Claude + Codex parity). Prints this repo's local env map.
# Source lives in .claude/env-map.md (gitignored) because AGENTS.md is a shared team
# doc. Ignores hook stdin.
dir="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cat "$dir/.claude/env-map.md" 2>/dev/null || true
