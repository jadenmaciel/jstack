#!/usr/bin/env bash
# Publish a .research/<slug>/ dir to a per-project NotebookLM notebook.
# Usage: publish.sh <research-dir> [--notebook <id>] [--dry-run] [--max N] [--no-report]
# Best-effort by design: ALWAYS exits 0 so a NotebookLM outage never blocks research delivery.
set -u

warn() { echo "WARN: $*" >&2; }
die0() { warn "$*"; exit 0; }

DIR="" NOTEBOOK="" DRY=0 MAX=15 NO_REPORT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --notebook) NOTEBOOK="$2"; shift 2 ;;
    --dry-run)  DRY=1; shift ;;
    --max)      MAX="$2"; shift 2 ;;
    --no-report) NO_REPORT=1; shift ;;
    *) DIR="$1"; shift ;;
  esac
done

[ -n "$DIR" ] && [ -d "$DIR" ] || die0 "usage: publish.sh <research-dir> (dir not found: '$DIR')"
DIR="$(cd "$DIR" && pwd)"
SLUG="$(basename "$DIR")"

case "$DIR" in
  "$HOME/Development/Obsidian"*) die0 "refusing to publish Obsidian content" ;;
esac

command -v notebooklm >/dev/null 2>&1 || die0 "notebooklm CLI not found, skipping publish"
command -v jq >/dev/null 2>&1 || die0 "jq not found, skipping publish"

NB_LIST="$(notebooklm list --json 2>/dev/null)" || die0 "notebooklm unavailable/unauthenticated, skipping publish"

# Project name: git root basename, else ~/Development/<name> segment, else Personal
project() {
  local root
  root="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)" && { basename "$root"; return; }
  case "$DIR" in
    "$HOME/Development/"*) echo "$DIR" | sed "s|^$HOME/Development/||" | cut -d/ -f1 ;;
    *) echo "Personal" ;;
  esac
}

# Resolve notebook: --notebook flag > cached id > title match > create
CACHE="$DIR/notebook_id"
TITLE="$(project) — Research"
if [ -z "$NOTEBOOK" ]; then
  NOTEBOOK="$(cat "$CACHE" 2>/dev/null || true)"
  [ -n "$NOTEBOOK" ] || NOTEBOOK="$(jq -r --arg t "$TITLE" '.notebooks[] | select(.title==$t) | .id' <<<"$NB_LIST" | head -1)"
  if [ -z "$NOTEBOOK" ]; then
    if [ "$DRY" = 1 ]; then
      echo "dry-run: would create notebook '$TITLE'"
    else
      NOTEBOOK="$(notebooklm create "$TITLE" --json 2>/dev/null | jq -r '.notebook.id // empty')"
      [ -n "$NOTEBOOK" ] || die0 "notebook create failed, skipping publish"
    fi
  fi
fi
[ -n "$NOTEBOOK" ] && [ "$DRY" = 0 ] && echo "$NOTEBOOK" > "$CACHE"

# Collect source URLs: sources.json if present, else any URL in evidence.md
collect() {
  if [ -f "$DIR/sources.json" ]; then
    jq -r '.. | .url? // empty' "$DIR/sources.json" 2>/dev/null
  elif [ -f "$DIR/evidence.md" ]; then
    grep -Eo 'https?://[^")[:space:]>]+' "$DIR/evidence.md"
  fi
}
URLS="$(collect | sed 's/[.,;`]*$//' | grep -Ev '://(localhost|127\.|0\.0\.0\.0|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)|\.local(/|$)|^file:' | sort -u)"

# Dedupe against notebook + check source-count headroom
EXISTING="" COUNT=0
if [ -n "$NOTEBOOK" ]; then
  SRC_JSON="$(notebooklm source list -n "$NOTEBOOK" --json 2>/dev/null || true)"
  EXISTING="$(jq -r '.sources[]?.url // empty' <<<"$SRC_JSON" 2>/dev/null || true)"
  COUNT="$(jq -r '.sources | length' <<<"$SRC_JSON" 2>/dev/null || echo 0)"
fi
NEW="$(comm -23 <(echo "$URLS" | grep . || true) <(echo "$EXISTING" | sort -u) 2>/dev/null | awk -v m="$MAX" 'NR<=m')"
TOTAL_URLS="$(echo "$URLS" | grep -c . || true)"
N_NEW="$(echo "$NEW" | grep -c . || true)"
[ "$COUNT" -ge 45 ] 2>/dev/null && warn "notebook has $COUNT sources (~50 cap) — consider a new notebook"

if [ "$DRY" = 1 ]; then
  echo "dry-run: notebook=${NOTEBOOK:-<new: $TITLE>} slug=$SLUG"
  echo "dry-run: $TOTAL_URLS urls found, $N_NEW new (cap $MAX):"
  echo "$NEW" | sed 's/^/  /'
  [ "$NO_REPORT" = 0 ] && [ -f "$DIR/report.md" ] && echo "dry-run: would add report.md as 'Report: $SLUG ($(date +%Y-%m-%d))'"
  exit 0
fi

ADDED=0
for u in $NEW; do
  if notebooklm source add "$u" -n "$NOTEBOOK" >/dev/null 2>&1; then
    ADDED=$((ADDED+1))
  else
    warn "failed to add $u"
  fi
  sleep 2
done

if [ "$NO_REPORT" = 0 ] && [ -f "$DIR/report.md" ]; then
  notebooklm source add "$DIR/report.md" -n "$NOTEBOOK" --title "Report: $SLUG ($(date +%Y-%m-%d))" >/dev/null 2>&1 \
    && REPORT=yes || { REPORT=no; warn "report upload failed"; }
else
  REPORT=skipped
fi

echo "published: $ADDED new sources (of $N_NEW new / $TOTAL_URLS found), report=$REPORT -> notebook $NOTEBOOK"
exit 0
