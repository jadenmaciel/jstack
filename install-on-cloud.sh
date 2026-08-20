#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# When sourced path is a clone, SKILLS_PACK_SRC may already be set by the consumer hook.
# shellcheck source=scripts/lib/install-skills-pack.sh
source "${ROOT}/scripts/lib/install-skills-pack.sh"
