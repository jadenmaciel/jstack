set -euo pipefail

# --- cloud-home skills ---
if [ -n "${CURSOR_CLOUD_HOME_TOKEN:-}" ]; then
  rm -rf "$HOME/.cursor/cloud-home"
  git clone --depth 1 "https://x-access-token:${CURSOR_CLOUD_HOME_TOKEN}@github.com/jadenmaciel/cursor-cloud-home.git" "$HOME/.cursor/cloud-home"
  rm -rf "$HOME/.cursor/skills"
  mkdir -p "$HOME/.cursor/skills"
  # ponytail: no rsync on stock cloud image
  cp -a "$HOME/.cursor/cloud-home/skills/." "$HOME/.cursor/skills/"
  echo "cloud-home skills: $(find "$HOME/.cursor/skills" -name SKILL.md | wc -l | tr -d ' ')"
else
  echo "WARN: CURSOR_CLOUD_HOME_TOKEN missing; skipping skills mirror"
fi

# --- codegraph ---
if ! command -v codegraph >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
fi
export PATH="$HOME/.local/bin:$PATH"
codegraph --version || true

# --- gcloud CLI (user-local tarball; org blocks SA keys so ADC secret is the auth path) ---
export PATH="$HOME/google-cloud-sdk/bin:$HOME/.local/bin:$PATH"
if ! command -v gcloud >/dev/null 2>&1; then
  # ponytail: extract under $HOME without changing install cwd (/workspace)
  curl -fsSL -o /tmp/gcloud.tgz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
  tar -xzf /tmp/gcloud.tgz -C "$HOME"
  rm -f /tmp/gcloud.tgz
  "$HOME/google-cloud-sdk/install.sh" --quiet --path-update false --usage-reporting false --command-completion false
  export PATH="$HOME/google-cloud-sdk/bin:$PATH"
fi
gcloud --version | head -1 || true

# ADC from Cursor secret GCP_ADC_JSON (authorized_user; org policy blocks SA key creation)
if [ -n "${GCP_ADC_JSON:-}" ]; then
  mkdir -p "$HOME/.config/gcloud"
  printf '%s\n' "$GCP_ADC_JSON" > "$HOME/.config/gcloud/application_default_credentials.json"
  chmod 600 "$HOME/.config/gcloud/application_default_credentials.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
  PROJECT="${GOOGLE_CLOUD_PROJECT:-${GCP_PROJECT:-nth-fort-504521-j4}}"
  gcloud config set project "$PROJECT" --quiet || true
  gcloud auth application-default set-quota-project "$PROJECT" --quiet 2>/dev/null || true
  gcloud auth login --cred-file="$HOME/.config/gcloud/application_default_credentials.json" --quiet 2>/dev/null || true
  if gcloud auth print-access-token >/dev/null 2>&1 \
     || gcloud auth application-default print-access-token >/dev/null 2>&1; then
    echo "gcloud ADC ok; project=$PROJECT"
  else
    echo "WARN: gcloud ADC present but print-access-token failed"
  fi
fi

# --- Python venv (AGENTS.md); repo lives at /workspace ---
cd /workspace 2>/dev/null || true
if [ -f requirements.txt ]; then
  python3 -m venv .venv
  # shellcheck disable=SC1091
  . .venv/bin/activate
  pip install -q -U pip
  pip install -q -r requirements.txt
  echo "venv ready: $(python -V) packages=$(pip list --format=freeze | wc -l | tr -d ' ') pwd=$(pwd)"
else
  echo "WARN: requirements.txt missing (pwd=$(pwd))"
fi
