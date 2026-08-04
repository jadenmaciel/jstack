---
name: agent-reach
description: >
  Use for public, zero-credential internet research: web search, public URLs,
  GitHub, YouTube, RSS, V2EX, Bilibili, and other anonymously readable sources.

  Also MUST USE when user mentions any platform or shares any URL/link:
  Twitter/X, Reddit, Facebook, Instagram, YouTube, GitHub, Bilibili, XiaoHongShu,
  Xiaoyuzhou Podcast, LinkedIn/jobs/recruiting, V2EX, Xueqiu (stocks), RSS.

  This local adoption is credential-free: never request, read, import, or store
  cookies, tokens, API keys, browser sessions, or authenticated account data.

  NOT for: authenticated/login-backed access, posting/commenting/liking,
  writing reports/analysis/translation (this skill only FETCHES internet
  content), or platforms with a dedicated installed skill.
metadata:
  openclaw:
    homepage: https://github.com/Panniantong/Agent-Reach
---

# Agent Reach — internet capability router

Public internet routing using already-installed, zero-credential tools.

## Standing rules (apply for the whole session)

1. **Credential-free boundary**: never run `agent-reach install`, `setup`,
   `configure`, `doctor`, or `watch`; never request/read/import/store cookies,
   tokens, API keys, proxy credentials, or browser sessions; never use OpenCLI
   or another backend that reuses a logged-in browser; never start a daemon,
   MCP server, container, cron job, or background service.
2. **Installed public tools only**: use `command -v` before a CLI and stay with
   anonymous/public endpoints. If public access fails, report the limitation;
   do not fall through to a login-backed retry chain.
3. **Announce what you use**: say "using agent-reach, platform X via backend Y"
   before starting.
4. **On failure**, references may be used only for their public command groups;
   ignore every cookie, token, browser-login, installer, and authenticated
   fallback instruction.
5. **For broad research tasks**, combine public sources, collect in parallel,
   then synthesize.

## Routing table

| User intent | Category | Details |
|---------|------|---------|
| Web / code search | search | [references/search.md](references/search.md) |
| XiaoHongShu / Twitter / Bilibili / V2EX / Reddit / Facebook / Instagram | social | [references/social.md](references/social.md) |
| Jobs / LinkedIn | career | [references/career.md](references/career.md) |
| GitHub / code | dev | [references/dev.md](references/dev.md) |
| Web pages / articles / RSS | web | [references/web.md](references/web.md) |
| YouTube / Bilibili / podcast transcripts | video | [references/video.md](references/video.md) |

## Zero-config quick commands

```bash
# Exa web search
mcporter call 'exa.web_search_exa(query: "query", numResults: 5)'

# Read any web page
curl -s "https://r.jina.ai/URL"

# GitHub search
gh search repos "query" --sort stars --limit 10

# YouTube subtitles (NOTE: never use yt-dlp for Bilibili — see video.md)
yt-dlp --write-sub --skip-download -o "/tmp/%(id)s" "URL"

# V2EX hot topics
curl -s "https://www.v2ex.com/api/topics/hot.json" -H "User-Agent: agent-reach/1.0"

# Bilibili search (bili-cli, no login needed)
bili search "query" --type video -n 5
```

## Login-backed platforms

Disabled in this local adoption. Do not configure or use them. Public links may
still be fetched anonymously when an existing public reader supports them.

## Workspace rules

**Never create files in the agent workspace.** Use `/tmp/` for temporary
output and `~/.agent-reach/` for persistent data.

## Detailed references

Read the matching file when you need specifics (commands above cover the
common cases; references hold per-backend command groups, caveats, retry
chains — note: reference docs are written in Chinese, commands are universal):

- [Search](references/search.md) — Exa AI search
- [Social](references/social.md) — XiaoHongShu, Twitter, Bilibili, V2EX, Reddit, Facebook, Instagram (multi-backend/login-backed groups)
- [Career](references/career.md) — LinkedIn
- [Dev](references/dev.md) — GitHub CLI
- [Web](references/web.md) — Jina Reader, RSS
- [Video](references/video.md) — YouTube, Bilibili, Xiaoyuzhou

## Configure a channel

Do not configure channels. This installation intentionally contains only the
reviewed skill files, not the Agent Reach CLI or its credential-storing
installer.
