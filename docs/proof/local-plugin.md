# Local plugin smoke

Date: 2026-08-20 (updated after rename to `jstack`)

## Filesystem (verified)

- Symlink: `~/.cursor/plugins/local/jstack` → `/Users/testadmin/Development/personal/jstack`
- Manifest: `.cursor-plugin/plugin.json` name `jstack`
- Plugin skill roots (array): `align`, `style`, `research`, `day`, `repo`, `misc`
- Discoverable `SKILL.md` count under those roots: **34** (includes `skills/align/ship`)

## Browser (dashboard)

Checked via browser-use on `cursor.com/dashboard`:

- **Plugins** (team marketplace list): does **not** show `jstack` (expected; local plugin is IDE-only, not Team Marketplace).
- **Cloud Agents → My Secrets**: `CURSOR_CLOUD_HOME_TOKEN` is present (secret name kept after repo rename).
- **Cloud proof:** see `docs/proof/cloud-ship.md` (clark-agency, 34 skills, `SHIP_OK`).

## Operator IDE check (Electron, not browser-use)

Reload Cursor → Customize → Skills → confirm `ship` appears from plugin `jstack`.
