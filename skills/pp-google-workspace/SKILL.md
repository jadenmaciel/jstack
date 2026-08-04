---
name: pp-google-workspace
description: "Google Workspace CLI — unified CLI for Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin. Built for humans and AI agents."
author: "Printing Press (github.com/mvanhorn/printing-press)"
license: "MIT"
argument-hint: "<command> [args] | install cli|mcp"
allowed-tools: "Read Bash"
metadata:
  openclaw:
    requires:
      bins:
        - gws
---

# Google Workspace — Printing Press CLI

## Prerequisites: Install the CLI

This skill drives the `gws` binary. **You must verify the CLI is installed before invoking any command from this skill.** If it is missing, install it first:

```bash
# Via Homebrew (macOS/Linux)
brew install googleworkspace-cli

# Via Cargo
cargo install --git https://github.com/googleworkspace/cli --locked

# Pre-built binary
# See https://github.com/googleworkspace/cli/releases for your platform
```

Verify: `gws --version`

If `gws --version` reports "command not found" after install, ensure the binary is on your `$PATH`. The binary name is `gws`, installed to `$GOPATH/bin` or `$HOME/.cargo/bin` depending on install method.

## Overview

One CLI for all of Google Workspace — Drive, Gmail, Calendar, Sheets, Docs, Chat, Admin. Dynamically built from Google's Discovery Service; the command surface grows automatically as Google adds endpoints.

Key capabilities:
- **Structured JSON output** on all commands
- **Auto-pagination** — fetch all pages transparently
- **Dry-run mode** — preview any mutation without executing
- **100+ AI agent skills** built in
- **Helper commands** prefixed with `+` (e.g., `gws gmail +send`, `gws calendar +agenda`)

## Authentication

`gws` supports multiple auth modes. Run the setup command:

```bash
gws auth setup
```

Or:
```bash
gws auth login
```

For API key-based services (Drive, Sheets), set the `GWS_API_KEY` environment variable or the key in `~/.gws/credentials.json`.

For browser-session-based services (Gmail, Chat), use `gws auth login` to authenticate via your browser session.

Run `gws doctor` to verify setup.

## Command Structure

```
gws <service> <resource> <method> [flags]
```

Examples:
```bash
gws auth setup
gws drive files list --params '{"pageSize": 5}'
gws sheets spreadsheets create --json '{"properties": {"title": "Q1 Budget"}}'
gws chat spaces messages create --params '{"parent": "spaces/xyz"}' --json '{"text": "Deploy complete."}' --dry-run
gws calendar events list --calendar primary
gws gmail messages list -- inbox --limit 10 --json
```

## Service Reference

### Drive
- `gws drive files list` — List files
- `gws drive files get` — Get file metadata
- `gws drive files create` — Upload/create file
- `gws drive files delete` — Delete file
- `gws drive about get` — Get Drive info

### Gmail
- `gws gmail messages list` — List messages (supports `--inbox`, `--spam`, `--trash`)
- `gws gmail messages get` — Get message by ID
- `gws gmail messages send` — Send email
- `gws gmail labels list` — List labels

### Calendar
- `gws calendar events list` — List events (supports `--calendar`, `--time-min`, `--time-max`)
- `gws calendar events get` — Get event
- `gws calendar events create` — Create event
- `gws calendar events update` — Update event
- `gws calendar events delete` — Delete event

### Sheets
- `gws sheets spreadsheets list` — List spreadsheets
- `gws sheets spreadsheets get` — Get spreadsheet
- `gws sheets spreadsheets create` — Create spreadsheet
- `gws sheets values get` — Get range values
- `gws sheets values update` — Update range values

### Docs
- `gws docs documents get` — Get document
- `gws docs documents create` — Create document

### Chat
- `gws chat spaces list` — List spaces
- `gws chat spaces messages create` — Post message
- `gws chat spaces messages list` — List messages

### Admin (requires admin credentials)
- `gws admin users list` — List users
- `gws admin users get` — Get user

## Helper Commands

Prefix `+` for high-level helpers:

```bash
gws gmail +send --to "user@example.com" --subject "Hello" --body "World"
gws calendar +agenda          # Today's agenda
gws drive +upload ./file.txt   # Upload file
gws workflow +standup-report   # Generate standup report
```

## Agent Mode

Add `--agent` to any command. Expands to: `--json --compact --no-input --no-color --yes`.

- **Pipeable** — JSON on stdout, errors on stderr
- **Filterable** — `--select` keeps a subset of fields
- **Previewable** — `--dry-run` shows the request without sending
- **Non-interactive** — never prompts, every input is a flag

```bash
gws drive files list --agent --select files(name,id,mimeType)
gws calendar events list --agent --calendar primary --time-min 2026-01-01 --select items(summary,start)
```

## Output Formats

| Flag | Effect |
|------|--------|
| `--json` | Structured JSON output |
| `--compact` | Minimal JSON (no whitespace) |
| `--csv` | CSV output for list commands |
| `--quiet` | Suppress meta output |
| `--select <fields>` | Filter to specific fields (dotted paths supported) |
| `--limit N` | Limit results to N items |

## Error Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 2 | Usage error |
| 3 | Resource not found |
| 4 | Authentication required |
| 5 | API error (upstream issue) |
| 7 | Rate limited |

## Finding the right command

```bash
gws which "<capability in your own words>"
```

`which` resolves natural-language queries to the best matching command.

## Argument Parsing

Parse `$ARGUMENTS`:

1. **Empty, `help`, or `--help`** → show `gws --help` output
2. **Starts with `install`** → ends with `mcp` → MCP installation; otherwise → CLI installation instructions
3. **Anything else** → Direct Use (execute as CLI command with `--agent`)

## MCP Server Installation

```bash
claude mcp add gws-mcp -- gws-mcp
```

Verify: `claude mcp list`

## Direct Use

1. Check if installed: `which gws`
   If not found, offer to install (see Prerequisites at the top of this skill).
2. Match the user query to the best command from the Service Reference above.
3. Execute with the `--agent` flag:
   ```bash
   gws <service> <resource> <method> [args] --agent
   ```
4. If ambiguous, drill into subcommand help: `gws <service> --help`.
