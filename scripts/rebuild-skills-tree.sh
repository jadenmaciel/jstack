#!/usr/bin/env bash
# Rebuild skills/ into category layout from pack.keep + laptop imports.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LAPTOP="${HOME}/.cursor/skills"
STAGING="${ROOT}/.skills-staging"
KEEP="${ROOT}/pack.keep"

category_for() {
  case "$1" in
    grilling|grill-me|grill-with-docs|domain-modeling|to-spec|to-tickets|wayfinder|implement|prototype|ticket-start|ship|handoff) echo align ;;
    ponytail|i-have-adhd|wait-what|writing-for-agents) echo style ;;
    research|x-research|agent-reach|last30days|slop) echo research ;;
    day-sync|day-wrap|payday|standup|reflect-sessions) echo day ;;
    repo-onboard|repo-services) echo repo ;;
    triage|wizard|improve-codebase-architecture|codeburn-optimize|notebooklm|notebooklm-setup) echo misc ;;
    *) echo "" ;;
  esac
}

rm -rf "$STAGING"
mkdir -p "$STAGING"

while IFS= read -r name || [[ -n "${name:-}" ]]; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  cat="$(category_for "$name")"
  if [[ -z "$cat" ]]; then
    echo "ERROR: no category for $name" >&2
    exit 1
  fi
  dest="${STAGING}/${cat}/${name}"
  mkdir -p "$(dirname "$dest")"
  if [[ -d "${ROOT}/skills/${name}" ]]; then
    cp -a "${ROOT}/skills/${name}" "$dest"
  elif [[ -d "${LAPTOP}/${name}" ]]; then
    cp -a "${LAPTOP}/${name}" "$dest"
  else
    echo "ERROR: missing keeper $name (not in repo skills/ or ${LAPTOP})" >&2
    exit 1
  fi
done < "$KEEP"

# Drop nested SKILL.md under references (dual discovery)
find "$STAGING" -path '*/references/*/SKILL.md' -delete 2>/dev/null || true

# Remove delete-set leftovers if copied under wrong names
rm -rf "${ROOT}/skills"
mv "$STAGING" "${ROOT}/skills"
echo "rebuilt skills: $(find skills -name SKILL.md | wc -l | tr -d ' ') SKILL.md files"
