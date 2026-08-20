#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib/install-skills-pack.sh
source "${ROOT}/scripts/lib/install-skills-pack.sh"

export PATH="${HOME}/google-cloud-sdk/bin:${HOME}/.local/bin:${PATH}"
if ! command -v gcloud >/dev/null 2>&1; then
  curl -fsSL -o /tmp/gcloud.tgz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
  tar -xzf /tmp/gcloud.tgz -C "$HOME"
  rm -f /tmp/gcloud.tgz
  "$HOME/google-cloud-sdk/install.sh" --quiet --path-update false --usage-reporting false --command-completion false
  export PATH="${HOME}/google-cloud-sdk/bin:${PATH}"
fi
gcloud --version | head -1 || true

if [[ -n "${GCP_ADC_JSON:-}" ]]; then
  mkdir -p "$HOME/.config/gcloud"
  printf '%s\n' "$GCP_ADC_JSON" >"$HOME/.config/gcloud/application_default_credentials.json"
  chmod 600 "$HOME/.config/gcloud/application_default_credentials.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
  PROJECT="${GOOGLE_CLOUD_PROJECT:-${GCP_PROJECT:-nth-fort-504521-j4}}"
  gcloud config set project "$PROJECT" --quiet || true
  gcloud auth application-default set-quota-project "$PROJECT" --quiet 2>/dev/null || true
  gcloud auth login --cred-file="$HOME/.config/gcloud/application_default_credentials.json" --quiet 2>/dev/null || true
fi

cd /workspace 2>/dev/null || true
if [[ -f requirements.txt ]]; then
  python3 -m venv .venv
  # shellcheck disable=SC1091
  . .venv/bin/activate
  pip install -q -U pip
  pip install -q -r requirements.txt
fi
