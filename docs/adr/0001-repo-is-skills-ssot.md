# Repo is the skills SSOT

Laptop `~/.cursor/skills` is no longer the source of truth. This private GitHub repo owns the curated pack; local IDE loads it via `~/.cursor/plugins/local` symlink; Cloud Agents clone it during environment `install`. Rejected: keeping Mac skills as SSOT with a push-mirror (old cursor-cloud-home model) — it fought Cloud sync and duplicated state.
