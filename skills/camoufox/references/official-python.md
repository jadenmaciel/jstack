# Official Python branch

Use this branch for code changes, direct Python automation, or a Playwright server. Recheck the official docs before changing package versions or using an API missing from the installed version. The official site warns that new 2026 preview releases are highly experimental; use the stable channel for production unless the task explicitly tests a preview.

Sources:

- https://github.com/daijro/camoufox
- https://camoufox.com/python/installation/
- https://camoufox.com/python/usage/
- https://camoufox.com/python/geoip/
- https://camoufox.com/python/remote-server/
- https://camoufox.com/python/virtual-display/

## Install and inspect

Use the project's virtual environment and package manager. For the stable official branch:

```bash
python -m pip install -U camoufox
python -m camoufox fetch
python -m camoufox version
```

Do not infer Python readiness from a `Camoufox.app` bundle. Require `python -m camoufox version` to identify the package, active browser, and installed browser. Install `camoufox[geoip]` only when proxy-matched location is required. Use `camoufox sync`, `camoufox set official/stable`, and `camoufox list --path` to inspect or select releases. Pin the wrapper and browser compatibility set when reproducibility requires it.

## Sync API

```python
from camoufox.sync_api import Camoufox

with Camoufox() as browser:
    page = browser.new_page()
    page.goto("https://example.com")
    print(page.locator("h1").inner_text())
```

## Async API

```python
from camoufox.async_api import AsyncCamoufox

async with AsyncCamoufox() as browser:
    page = await browser.new_page()
    await page.goto("https://example.com")
    print(await page.locator("h1").inner_text())
```

Use the context manager so browser resources close on errors.

With `persistent_context=True, user_data_dir=...`, the context manager returns a Playwright `BrowserContext` instead of `Browser`; create or reuse pages on that context.

## Identity and sessions

- Let BrowserForge generate the fingerprint by default.
- For current v149+ binaries, use `fingerprint_preset=True` when the installed wrapper supports the upstream real-fingerprint presets.
- Use `os="macos"` or another constraint only when the task needs a target platform.
- Avoid fixed `window` values outside debugging; fixed dimensions weaken rotation.
- Use `persistent_context=True` with a dedicated `user_data_dir` only for an approved login workflow.
- Use `humanize=True` when interaction timing matters; still verify each action.
- Use `proxy={...}, geoip=True` together so locale, timezone, geolocation, and WebRTC match the exit IP.
- Load proxy secrets from environment variables.

## Remote and display modes

Treat the Playwright server as experimental and use it only when another process or language must connect. Rotate the server between identities because one server owns one browser instance and does not rotate fingerprints between connections.

Use `headless="virtual"` on Linux for a virtual display. On macOS, use headed mode only for debugging or user handoff. Camoufox is automation-first; the official docs warn that its normal browser window may resize and render fonts unusually.

## Proof

Leave one runnable smoke check that opens `https://example.com`, reads `Example Domain`, and closes the browser. For persistent or proxy work, also verify the intended profile directory or public exit geography without printing credentials.
