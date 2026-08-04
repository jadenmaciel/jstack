---
name: deep-research
description: "Cited multi-source deep research via Codex web tools, Firecrawl, Agent Reach, Context7, local repo/docs search, Jina, and Last30Days (Tavily/Apify fallback). Plans sub-questions, deep-reads primary sources, keeps an evidence ledger, gap-checks, delivers a cited report. Use for competitive analysis, tech evaluation, market sizing, due diligence, regulatory/current-state questions, any \"deep research\" / \"current state of X\" request, or a quick primary-source lookup delegated to a background agent."
argument-hint: "research topic or question"
allowed-tools:
  - Bash(firecrawl *)
  - Bash(agent-reach *)
  - Bash(mcporter *)
  - Bash(gh *)
  - Bash(yt-dlp *)
  - Bash(twitter *)
  - Bash(rdt *)
  - Bash(xhs *)
  - Bash(bili *)
  - Bash(command *)
  - Bash(test *)
  - Bash(curl *)
  - Bash(python3 *)
  - Bash(python3.12 *)
  - Bash(python3.13 *)
  - Bash(python3.14 *)
  - Bash(jq *)
  - Bash(wc *)
  - Bash(rg *)
  - Bash(grep *)
  - Bash(head *)
  - Bash(tail *)
  - Bash(mkdir *)
  - Bash(notebooklm *)
  - Bash(bash /Users/testadmin/.codex/skills/notebooklm/scripts/*)
  - Read
  - Write
  - Glob
  - Grep
---

# Deep Research

Produce a cited report. Native surface priority (fall through):

1. Built-in Codex web/search/browser.
2. `firecrawl`: web search, page fetch/scrape, map/crawl, structured extraction, browser interaction, agent web jobs.
3. Embedded Agent Reach (`references/agent-reach`): platform routing + read/search for public social/dev/video/career (platforms in pass below).
4. `context7-cli`: official library/framework/API docs.
5. Local files, project docs, `rg`, and Graphify when a graph exists: repo/package/docs.
6. Jina Reader/Search: URL-to-markdown or light search backup.
7. Embedded Last30Days (`references/last30days`): fresh public/social signal for reaction, adoption, complaints, recommendations, trends (sources in pass below).
8. Tavily/Apify only if available as a fallback native stack cannot cover.

Never make Tavily/Apify/any MCP a hard dependency. Preferred native tool unavailable -> record fallback in methodology, continue.

## Quick mode (background delegation)

One narrow question, no report needed -> skip the full pipeline below. Spin up a **background agent** so the user keeps working while it reads:

1. Investigate against **primary sources** only -- official docs, source code, specs, first-party APIs, not a secondary write-up of them. Follow every claim to the source that owns it.
2. Write findings to a single Markdown file, citing each claim's source.
3. Save it where the repo already keeps such notes; match the existing convention, or say where if there is none.

Use the full Workflow below whenever the question needs triangulation, a dated report, or more than a couple of sources.

## Core Guarantees

1. Every factual claim cited; unsourced -> rewrite or drop.
2. Triangulate 3 or more independent sources for load-bearing claims; single-source flagged `[unverified]`.
3. Primary > secondary: official docs, filings, standards, first-party announcements, direct data > reporting > blogs/forums.
4. No fabrication: evidence absent -> say "insufficient data" + list what would close the gap.
5. Reproducible: write intermediate artifacts to `.research/<slug>/` for resume/audit.

## Pre-flight

Check relevant native surfaces before searching:

```bash
command -v firecrawl >/dev/null && firecrawl view-config || true
command -v jq >/dev/null
command -v agent-reach >/dev/null && agent-reach --version || true
test -f "$HOME/.codex/skills/deep-research/references/agent-reach/agent_reach/skill/SKILL.md" && echo "agent-reach=embedded" || true
for py in python3.14 python3.13 python3.12 python3; do
  command -v "$py" >/dev/null 2>&1 || continue
  "$py" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 12) else 1)' || continue
  echo "LAST30DAYS_PYTHON=$py"
  break
done
test -f "$HOME/.codex/skills/deep-research/references/last30days/scripts/last30days.py" && echo "last30days=embedded" || true
notebooklm list --json 2>/dev/null | jq -r '.notebooks[] | "\(.id)\t\(.title)"' || true
```

Record: primary web/search tool; Firecrawl auth?; Agent Reach on PATH or embedded-only?; Last30Days relevant/available/Python 3.12+?; helpers (`context7-cli`, `rg`, Graphify, `jina-cli`, browser-use/Chrome/Playwright); any unavailable fallback.

### NotebookLM corpus check (consume before re-researching)

If a notebook title plausibly matches the topic: `notebooklm ask -n <id> "<research question>. Answer only from sources; say what is missing."` Always `-n <full id>` (never `use` — shared context clobbers parallel sessions). Skip `--new` — in 0.7+ it destructively deletes the notebook's previous conversation; the default (continue last conversation) is fine for corpus queries.

- Answer covers the question -> deliver it, labeled "from NotebookLM corpus <title>, dated sources — say 'fresh' to re-research", and stop.
- Partial -> treat as prior: seed plan.md sub-questions with what is already known, research only the gaps.
- `list`/`ask` errors or hangs -> note "notebooklm unavailable" in methodology and proceed with normal research. Never run `notebooklm login` unattended (opens a browser); tell the user instead.

## Workflow

### 1. Scope

Ask <=2 clarifying questions only if ambiguous on goal, audience, decision use, geography, or depth. Direction given or "just research it" -> defaults: Goal decision support; Depth standard; Recency 24 months current-state (anytime historical/background); Geography global unless topic implies market/jurisdiction.

Depth: Brief = <= 5 sources, short inline answer. Standard = 15-30 sources, disk report + inline summary. Deep = 30-60 sources, extraction matrix/structured data when useful.

### 2. Plan

Break topic into 4-7 independently searchable sub-questions. Write `.research/<slug>/plan.md`:

```markdown
# Research Plan: <topic>

- Goal: <goal>
- Depth: <depth>
- Recency: <window>
- Geography: <scope>
- Primary tool: <codex-web | firecrawl | context7 | local-files | graphify | jina | fallback>

## Sub-questions
1. ...

## Source priors
- Official:
- Data/filings:
- Analysts/academic:
- Press/trade:
- Platform-routed public sources:
- Recent public signal:
- Community:
```

### 3. Broad Search

Native fit: general web = built-in search else Firecrawl. Library/API/framework docs = `context7-cli` first, then official via Firecrawl/Jina. Repo/package/docs = local project docs and `rg` first, Graphify when `graphify-out/graph.json` exists, then web. Specific URL/page = Firecrawl scrape first, Jina Reader clean-markdown fallback. Login/profile/browser-only = Browser Use/Chrome/Firecrawl interact.

#### Embedded Agent Reach platform-routing pass

Use when topic needs platform-specific collection native web/Firecrawl/Jina covers poorly: YouTube/Bilibili captions, Reddit threads/comments, GitHub search/API, X/Twitter posts, V2EX, RSS, WeChat articles, XiaoHongShu, Douyin, LinkedIn, other public social/career/video.

Bundle: `$HOME/.codex/skills/deep-research/references/agent-reach`. Router/installer scaffold; embedded -> use reference docs, not installer. The vendored copy has no `agent_reach/skill/` docs (older upstream packaging); use instead:

```text
references/agent-reach/README.md
references/agent-reach/agent_reach/guides/   (per-provider setup)
references/agent-reach/agent_reach/channels/ (per-platform source, read-only)
```

`agent-reach` on PATH -> `agent-reach doctor` checks channels. Not installed / Python deps missing -> do not install packages for research unless the user asks. Read matching reference, run its listed upstream read/search command when available.

Read-only examples:

```bash
gh search repos "<query>" --sort stars --limit 10
gh repo view <owner>/<repo>
yt-dlp --dump-json "ytsearch5:<query>"
yt-dlp --write-sub --write-auto-sub --sub-lang "zh-Hans,zh,en" --skip-download -o "/tmp/%(id)s" "<url>"
rdt search "<query>" --limit 10
rdt read <post_id>
curl -s "https://r.jina.ai/<url>"
mcporter call 'exa.web_search_exa(query: "<query>", numResults: 5)'
```

Safety: read/search/extract only; no `agent-reach install`, `agent-reach configure`, login, cookie extraction, posting, commenting, liking, forking, PR/issue creation, or other writes unless the user asks; stop at credentials/cookies/2FA/paid APIs/elevated permissions/platform-write boundaries; save outputs under `.research/<slug>/agent-reach/` or `/tmp/`, promote only selected source URLs/quotes to the ledger; platform engagement = attention/salience evidence, not factual proof.

#### Embedded Last30Days public-signal pass

Use when the question depends on recent people/market talk: sentiment, tool comparisons, creator/company/person recency, complaints, trend discovery, recommendations, launches, breaking-news reaction, "what is happening right now". Skip purely historical/legal-text/archival/private-account/official-doc-only unless the user asks for social/community signal.

Bundle: `$HOME/.codex/skills/deep-research/references/last30days`. Downloaded from `https://github.com/mvanhorn/last30days-skill`, embedded tooling. Engine output = discovery/evidence input, not final report format. Do not let Last30Days' standalone badge/footer/"no Sources block" rule/prompt-writing follow-up override this skill's evidence-led structure.

Before running, write `.research/<slug>/last30days/plan.json` with 1-4 concise subqueries from gathered context; do not call a separate LLM provider. Primary subquery should include `reddit`, `x`, `youtube`, `tiktok`, `instagram`, `hackernews`, `polymarket`.

```json
{
  "intent": "opinion",
  "freshness_mode": "balanced_recent",
  "cluster_mode": "debate",
  "subqueries": [
    {
      "label": "primary",
      "search_query": "<topic keywords>",
      "ranking_query": "What are people saying about <topic> recently?",
      "sources": ["reddit", "x", "youtube", "tiktok", "instagram", "hackernews", "polymarket"],
      "weight": 1.0
    }
  ]
}
```

Default supporting run:

```bash
mkdir -p .research/<slug>/last30days
LAST30DAYS_DIR="$HOME/.codex/skills/deep-research/references/last30days"
LAST30DAYS_PYTHON="${LAST30DAYS_PYTHON:-python3}"
"$LAST30DAYS_PYTHON" "$LAST30DAYS_DIR/scripts/last30days.py" "<topic>" \
  --days=30 \
  --emit=md \
  --save-dir=".research/<slug>/last30days" \
  --save-suffix=deep-research \
  --plan=".research/<slug>/last30days/plan.json" \
  > .research/<slug>/last30days/raw.md \
  2> .research/<slug>/last30days/run.log
```

Flags: sparse/older-than-month topic or broader window -> `--days=90`; resolved handles/repos/subreddits/hashtags/targeting during search -> pass `--x-handle`, `--github-user`, `--github-repo`, `--subreddits`, `--tiktok-hashtags`, `--tiktok-creators`, `--ig-creators`; no plan (web/search unavailable) -> add `--auto-resolve`, omit `--plan`, record degraded path; no `--deep-research` unless the user explicitly approves the paid OpenRouter/Perplexity path and the required key is available.

After run: add unique source URLs from `.research/<slug>/last30days/raw.md` to `candidates.md`/`candidates.json`; prefer original item URLs/quotes over synthesized prose; engagement = attention/salience only, not factual truth unless corroborated; missing credentials/too thin/timeout -> record exact blocker in methodology, continue.

Firecrawl examples:

```bash
mkdir -p .research/<slug>/search
firecrawl search "<sub-question variant 1>" --limit 10 --json > .research/<slug>/search/q1-v1.json
firecrawl search "<official source query> site:<official-domain>" --limit 10 --json > .research/<slug>/search/q1-official.json
```

2-3 variants per sub-question: Official/data = `site:<official-domain>`, `filetype:pdf`, `annual report`, `SEC`, `.gov`, standards body. Recency = exact years, e.g. `2025 2026`. News = reputable outlets/trade. Academic/technical = `site:arxiv.org`, `site:.edu`, DOI, standards group, project repo. Geography = country, regulator, market name, country-code TLD.

### 4. Triage

Create `.research/<slug>/candidates.json` or `candidates.md`, unique URLs + short rationale. Rank: (1) Authority tier: official/.gov/.edu/standards/filings/analyst/reputable press/trade/community. (2) Recency per plan window. (3) Coverage: answers a sub-question, not keyword-match. (4) Independence: don't count syndicated copies or repeated citations of one underlying source as separate evidence.

Last30Days ran -> triage its original platform URLs, classify by actual tier (usually community/press/trade/GitHub/prediction-market); don't count Last30Days itself as independent corroboration for claims needing primary/official confirmation.

Agent Reach routed -> classify each item by upstream surface queried, not Agent Reach: `gh repo view` = GitHub/project, `yt-dlp` captions = video, `rdt read` = community, Jina/Exa = web/search.

Pick top 12-25 URLs (standard depth). Reject SEO spam, content farms, AI-rewrite sites, undated listicles unless research is about them. Write selected to `.research/<slug>/sources.json`:

```json
{"url":"https://example.com","title":"...","tier":"official","sub_question_ids":["Q1"],"rationale":"..."}
```

### 5. Deep Read

Fetch full content for every selected URL. Prefer Firecrawl:

```bash
mkdir -p .research/<slug>/pages
firecrawl scrape "<url-1>" --format markdown --only-main-content > .research/<slug>/pages/001.md
```

Per page: `wc -l` first; `rg -n "<keyword>|<synonym>"` to jump to sections; read targeted line ranges, don't dump full pages.

Fallback ladder:
1. Built-in browser/web extraction if runtime provides it.
2. Jina Reader (replace URL; shortest working Reader URL): `curl -L "https://r.jina.ai/https://example.com" > .research/<slug>/pages/001-jina.md`
3. Firecrawl interact/agent (JS-heavy/interaction): `firecrawl agent "Extract the relevant facts and quoteable passages as markdown with source URL." --urls "<url>" --wait > .research/<slug>/pages/001-agent.md`
4. Playwright/Browser Use/Chrome for visual/login-gated, stopping before credential/irreversible boundaries.
5. Optional Tavily/Apify only if installed/authenticated and above cannot retrieve evidence.

Page empty/inaccessible -> mark dropped in `sources.json` with `drop_reason`.

### 6. Structured Extraction

Only when it materially improves the result (pricing matrices, feature tables, funding rounds, benchmark tables, regulatory lists). Prefer: Firecrawl agent/crawl for many similar pages; Browser/Playwright for deterministic DOM extraction; local `jq` for fetched JSON; Apify only for broad crawling / JS-heavy native tools cannot cover. Save under `.research/<slug>/extracted/`, note method in `.research/<slug>/.spend.log` or `.research/<slug>/methodology.md`.

### 7. Evidence Ledger

Flat-file ledger `.research/<slug>/evidence.md`:

```markdown
## E001
- Claim: <one-line assertion>
- Quote: "<verbatim text, <= 25 words unless source license allows more>"
- Source: [Title](url)
- Tier: official | academic | analyst | press | trade | community
- Retrieved: <YYYY-MM-DD>
- Sub-question: Q<n>
```

Every report finding cites one or more evidence IDs; no evidence ID -> no claim. Last30Days-derived -> cite original platform URL in `Source:` + short path note if needed, e.g. `Via: .research/<slug>/last30days/raw.md`. Never cite the Last30Days synthetic summary as a factual source.

### 8. Gap Pass

Before writing, second targeted search round for: sub-questions with fewer than 2 supporting entries; any `[unverified]` claim; source contradictions; missing primary-source confirmation behind a secondary report. Update `sources.json`, fetch new pages, extend `evidence.md`. Stop when every sub-question has at least 2 independent entries or budget exhausted. Record thin areas honestly.

### 9. Synthesize

```markdown
# <Topic>: Research Report
*Date: <YYYY-MM-DD> | Depth: <tier> | Sources: <N> | Evidence items: <M> | Confidence: <High|Medium|Low>*

## Executive Summary
<3-6 decision-relevant sentences.>

## Key Takeaways
- <Actionable insight> [E007, E011]

## 1. <Sub-question theme>
<Prose with evidence tags [Exxx]. Highlight consensus vs contested claims.>

## Contested or Unverified
- <Claim> - only one source [E019].

## Gaps
- <Sub-question left thin>: <why>, <what would close it>.

## Methodology
- Primary tools:
- Searches:
- Pages fetched/read:
- Agent Reach platform-routing run:
- Last30Days public-signal run:
- Structured extraction:
- Rejected sources:

## Sources
1. [Title](url) - <one-line summary> - tier: <tier>

## Evidence Ledger
See `.research/<slug>/evidence.md`.
```

### 10. Mandatory Oracle Critique

Use after the evidence ledger + synthesis exist, before delivery. Mandatory; not a fact source, must not create evidence IDs. Bundle unsafe/too sensitive/too broad, or browser/manual submission unavailable -> record `Oracle: blocked/skipped` + exact reason in methodology/final summary.

Follow `~/.codex/skills/references/oracle-advisory-escalation.md`: challenge conclusions, gaps, assumptions, source weighting, decision recommendations; attach report + evidence ledger + small set of safe source excerpts; run `oracle --dry-run summary --files-report ...` before any broad bundle; record accepted/rejected critiques in methodology/final summary.

Don't silently skip Oracle for brief/factual/low-risk/well-triangulated research; run the smallest safe critique bundle or record the exact blocker. Don't send sensitive/private context.

### 11. Deliver

Brief: full report inline. Standard/deep: executive summary + key takeaways + confidence + gaps inline; full report at `.research/<slug>/report.md`. Always include confidence + gaps inline. Don't overclaim from partial evidence.

### 12. Publish to NotebookLM (handoff)

Standard/deep runs: after delivering the report, run

```bash
"$HOME/.codex/skills/notebooklm/scripts/publish.sh" .research/<slug>
```

Resolves/creates the per-project notebook (`<Project> — Research`), adds evidence URLs (deduped, capped, throttled) + `report.md` as a text source. Best-effort: any failure is one warning line in methodology; never redo research, never block delivery. Brief runs: skip unless the user asks.

Ask first when the report embeds client/private/work identifiers or Obsidian content — offer `--no-report` (URLs only). Route into a specific existing notebook with `--notebook <id>` when the user names one.

## Parallelization

- `multi_tool_use.parallel` for independent local reads/search prep where available.
- External searches modest: 2-4 concurrent requests unless the tool documents a higher safe limit.
- Don't overlap heavy browser/agent extraction unless pages are independent and the tool supports it cleanly.

## Spend And Safety

- Prefer no-auth/already-authenticated native Codex/Firecrawl/Jina/Context7 paths.
- Don't expose secrets in logs.
- Ask before paid/high-volume/credential-gated/externally-visible actions.
- Paid fallback -> record tool, run count, why necessary.

## Authority Heuristics

| Tier | Examples |
|------|----------|
| Official | Vendor docs, SEC filings, gov domains, standards bodies |
| Academic | arXiv, DOI-backed journals, university repos |
| Analyst | Gartner, Forrester, CB Insights, IDC, McKinsey, BCG |
| Press | Reuters, Bloomberg, FT, NYT, WSJ, The Verge, Ars Technica |
| Trade | Industry journals specific to the topic |
| Community | HN, Reddit, GitHub discussions, Stack Overflow |
| Reject | SEO mills, AI-rewrite sites, link farms, undated listicles |

Community sources support a claim only when corroborated by one or more higher-tier source.

## Failure Modes To Avoid

Writing the report from snippets without full-page evidence; counting three stories from one syndicated report as three independent sources; paid/heavy scraping where Firecrawl/Codex web/Context7/local files/Jina would work; running Agent Reach installer/configuration/login/posting during research without explicit user approval; citing Agent Reach instead of the upstream item it routed to; treating Last30Days synthesized prose as a primary source instead of ledgering original URLs/quotes; skipping the gap pass; trusting an LLM paraphrase over the evidence ledger; dumping large raw logs or full pages into the final answer; re-researching a topic the NotebookLM corpus already answers; publishing private/client context to NotebookLM without asking.

## Resume Semantics

`.research/<slug>/plan.md` exists -> read it, then `sources.json` + `evidence.md` if present. Continue from earliest incomplete phase. Restart only if the user says "fresh."

## Examples

```text
Research the current state of post-quantum cryptography standards adoption.
Deep dive into Rust vs Go for async HTTP services in 2026, decision-oriented.
Investigate the funding and product timelines of the top 5 AI code-editor startups.
What is the regulatory landscape for EU cosmetics ingredient disclosure under EC 1223/2009?
Competitive analysis of shipping-label SaaS vendors in North America, depth: deep.
```
