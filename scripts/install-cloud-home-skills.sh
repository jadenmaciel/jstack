#!/usr/bin/env bash
# Back-compat forwarder for consumers still calling install-cloud-home-skills.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec bash "${ROOT}/install-jstack-skills.sh"
