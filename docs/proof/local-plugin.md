# Local plugin smoke

Date: 2026-08-20

## Filesystem (verified)

- Symlink: `~/.cursor/plugins/local/cursor-cloud-home` → `/Users/testadmin/Development/personal/cursor-cloud-home`
- Manifest: `.cursor-plugin/plugin.json` name `cursor-cloud-home`
- Plugin skill roots (array): `align`, `style`, `research`, `day`, `repo`, `misc`
- Discoverable `SKILL.md` count under those roots: **34** (includes `skills/align/ship`)

## Browser (dashboard)

Checked via browser-use on `cursor.com/dashboard`:

- **Plugins** (team marketplace list): does **not** show `cursor-cloud-home` (expected; local plugin is IDE-only, not Team Marketplace).
- **Cloud Agents → My Secrets**: `CURSOR_CLOUD_HOME_TOKEN` is present (also `CURSOR_CLOUD_HOME_DEPLOY_KEY`).
- **clark-agency** `environment.json` install currently runs venv/pip only. It does **not** call `install-on-cloud.sh`, so Cloud Agents will not load this pack until that install line is wired and the branch is pushed.

## Operator IDE check (Electron, not browser-use)

Reload Cursor → Customize → Skills → confirm `ship` appears from plugin `cursor-cloud-home`.
