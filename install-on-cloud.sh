set -euo pipefail
# Skills mirror via HTTPS token (Cursor secrets)
if [ -n "${CURSOR_CLOUD_HOME_TOKEN:-}" ]; then
  rm -rf "$HOME/.cursor/cloud-home"
  git clone --depth 1 "https://x-access-token:${CURSOR_CLOUD_HOME_TOKEN}@github.com/jadenmaciel/cursor-cloud-home.git" "$HOME/.cursor/cloud-home"
  mkdir -p "$HOME/.cursor/skills"
  # ponytail: no rsync on stock cloud image
  rm -rf "$HOME/.cursor/skills"
  mkdir -p "$HOME/.cursor/skills"
  cp -a "$HOME/.cursor/cloud-home/skills/." "$HOME/.cursor/skills/"
  echo "cloud-home skills: $(find "$HOME/.cursor/skills" -name SKILL.md | wc -l | tr -d ' ')"
else
  echo "WARN: CURSOR_CLOUD_HOME_TOKEN missing; skipping skills mirror"
fi
if ! command -v codegraph >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
fi
# ensure codegraph on PATH for later MCP stdio
export PATH="$HOME/.local/bin:$PATH"
codegraph --version || true
