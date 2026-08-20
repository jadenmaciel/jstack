#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/install-skills-pack.sh
source "${ROOT}/scripts/lib/install-skills-pack.sh"
