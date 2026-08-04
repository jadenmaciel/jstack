# MCP runtime reference

Use this reference for installation, repair, transport selection, or persistent sessions. Normal browsing should stay in `SKILL.md`.

## Installed transports on this Mac

### Direct Camoufox MCP - default

Codex server name: `camoufox`

```toml
[mcp_servers.camoufox]
command = "npx"
args = ["--yes", "camoufox-mcp-server@2.3.0"]
```

This is `whit3rabbit/camoufox-mcp`. It owns the Camoufox browser directly, applies a best-effort SSRF policy, bounds results, and provides 17 tools. It is pinned because the server, `camoufox-js`, Playwright, and browser binary are a tested compatibility set. Keep unsafe browser options and JavaScript evaluation disabled unless a concrete task requires an operator opt-in.

Start with `camoufox_status`. Require `browserAvailable: true`; inspect `maxSessions`, `sessionTtlMs`, `activeSessions`, `unsafeOptionsAllowed`, and `evaluateAllowed` before relying on them. One-shot tools close their browser. Sessions are isolated, in-memory, ephemeral, and default to one active slot with a ten-minute idle expiry.

Tool routing:

| Need | Raw MCP tool |
| --- | --- |
| Load status/title only | `browse` with `outputMode: "metadata"` |
| Bounded readable text | `browse` with `maxChars` |
| One text match | `browse_find` |
| Links, forms, or headings | `browse_links`, `browse_forms`, `browse_outline` |
| Interactive element map | `browse_snapshot` |
| Fixed multi-action flow | `browse_sequence` |
| Stateful decision loop | `browse_session_start`, `navigate`, `action`, `snapshot`, `close` |
| Visual proof | `browse_screenshot` |
| Focused diagnostics | `browse_console`, `browse_network_summary` |

Raw tool names may be namespaced by the host. Use the names in the active tool list.

Smoke test: call `camoufox_status`, then `browse` on `https://example.com` with `maxChars: 2000`; require `Example Domain`. On a genuinely missing binary, fetch the version paired with this server once:

```bash
npx --yes camoufox-js@0.10.2 fetch
```

Do not fetch over a working cache or upgrade Playwright independently.

### Local REST profile service - exceptional

Codex server name: `camofox_rest`

This is the existing local `redf0x1/camofox-browser@2.4.6` server and its matching `camofox-mcp@1.14.5` adapter at `127.0.0.1:9377`. It is not `jo-inc/camofox-browser` and it is not the direct MCP above. Use it only when the user needs durable profiles, the existing REST API, or compatibility with that installation.

```bash
pnpm -C /Users/testadmin/Development/stealth run start
curl -fsS http://127.0.0.1:9377/health
```

For an approved persistent login, use `userId="cli-default"` and a task-specific `sessionKey`; never share a session key across unrelated work. Create a tab, snapshot, act once, verify with a fresh snapshot, close the tab, and confirm cleanup with the tab list.

Keep a REST service on loopback. Any non-loopback deployment needs authentication and network egress controls in addition to application URL checks.

## Repository map

- `daijro/camoufox`: browser engine and official Python integration. Current 2026 preview releases are experimental; prefer the stable channel for production and expect preview breakage.
- `whit3rabbit/camoufox-mcp`: direct, short-lived MCP runtime used by default here.
- `jo-inc/camofox-browser`: separate REST/OpenClaw server design with persistent sessions and accessibility refs. Do not install it over the working local server or bind both to port 9377.

Primary sources:

- https://camoufox.com/
- https://github.com/daijro/camoufox
- https://github.com/whit3rabbit/camoufox-mcp
- https://github.com/jo-inc/camofox-browser
