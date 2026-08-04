# Home Runtime Extended Reference

This file holds background moved out of home-level `AGENTS.md` so routine Codex
sessions stay small. Load it only when the task needs the detail.

## Ponytail And Style Detail

- Ladder, stop at first rung that holds: (1) needs to exist? speculative = skip
  (YAGNI); (2) already in this codebase? reuse it; (3) stdlib; (4) native
  platform feature; (5) installed dependency — never add one for what a few
  lines do; (6) one line; (7) minimum code that works. Mark shortcuts
  `// ponytail: <reason>` naming ceiling + upgrade path.
- Ponytail pressures smallest correct diff; caveman compresses prose; neither
  overrides explicit scope, validation, security, accessibility, tests, or
  review gates. `ponytail-review` is complexity-only; correctness/security
  review runs separately.
- Graphify (`[GRAPHIFY]`, Claude Code statusline): when
  `graphify-out/graph.json` exists and `~/.claude/.graphify-active` ≠ `off` →
  `graphify query --budget 1200` before broad `rg`. Toggle `/graphify off|on`.

## Execution Detail

- Delegate once per actionable workspace request. Batch related work; casual
  conversation stays with Sol. Use native `collaboration.spawn_agent` with
  `fork_turns="none"`; the current untyped schema selects Terra `default`.
- Large-context: `HEADROOM_TELEMETRY=off headroom wrap codex` (or
  `headroom wrap claude`) when installed and baseline auth works. Skip for tiny
  edits, exact raw-text review, secrets/credentials, auth debugging, or when a
  proxy hurts diagnosis. Durable wrap changed config →
  `headroom unwrap codex|claude`.
- Browser for web/localhost UI; Computer Use for native macOS apps and system
  dialogs.
- Match local style; touch only lines tied to the request. Tests proportional to
  risk; smallest useful validation first. Visual/UI work needs visual proof.

## Worker Orchestration

- Use one worker for a normal actionable request; add lanes only for genuinely
  independent work. Cap Codex at Sol plus five workers.
- Active goal mode: delegate substantive safe subtasks; main thread keeps inbox,
  triage, routing, integration, verification, tiny reads, safety-gated decisions.
- No worker for vague scope, credentials/OTPs, destructive/admin, production/release
  authority, tight browser/system-dialog work, shared mutable state, or (outside
  goal mode) simple one-file edits.
- Worker prompts: mission, allowed paths/signals, disallowed actions, dirty-work
  warning, receipt format, proof commands, stop conditions.
- Luna is read-only. Keep one Terra writer per workspace; parallel writers need
  disjoint worktrees. Workers never delegate.
- If native spawning fails, Sol finishes inline without a CLI retry. Never spawn
  Sol as a child.
- Threads: `create_thread` / `fork_thread` / `send_message_to_thread` /
  `read_thread` / `handoff_thread`. Integrate in main: receipts, diffs, smallest
  useful verification, report unproven work.

## Model Routing

- Reference and role source: `~/.codex/model-routing-policy.json`.
- Root: Sol Ultra. Current untyped native workers: Terra Medium `default`.
  Quick-scout Luna Low and evaluator Terra High remain configured for future
  role-aware native spawning.
- `$cursor-quick`: optional read-only lookup, classification, tiny review, or
  documentation opinion via `cursor-agent` + `composer-2.5-fast`. It never
  edits files and is not a substitute for a Terra/Luna worker.
- Never pass direct model, effort, or service-tier overrides to workers.

## Bidirectional Claude / Codex / Cursor (summary)

Full policy: `~/.codex/claude-codex-collaboration-policy.md`.
Receipts: `~/.codex/claude-codex-receipt.schema.json`.
Entry: `$cross-agent-router`.

- Claude and Cursor do not launch Codex workers. They return advice or a bounded
  handoff; Sol starts native Codex children inside the app.
- Codex→Claude (`claude -p`) = prompt-only advisory, read-only by default.
  Claude cannot inspect files in that lane — summarize/excerpt, verify locally.
- Cursor is a read-only advisory lane through `$cursor-quick` ask mode.
- Use Claude for architecture, plan critique, UX/design, scope conflict,
  re-planning after repeated failures, release/security/auth/data judgment,
  final synthesis. Do not bounce routine mechanical implementation.
- Peer prompts include owner, cwd/worktree, branch/base, goal, allowed/forbidden
  actions, read-only vs write, proof commands, receipt format, stop conditions.
- Codex→Claude writes need explicit write scope + isolated branch/worktree.
- Cap review ping-pong at two exchanges, then integrate or escalate.
- Do not send secrets/credentials/customer/regulated/private data to Oracle or
  cross-agent prompts without explicit authorization of that exact bundle.
- Oracle: `~/.codex/skills/references/oracle-advisory-escalation.md`.

## Skills And SprintFlow

- Live skill root: `~/.codex/skills`. `$skill` loads that skill body.
- Daily loop: `$start → $implement → $check → ($fix → $check)* → $pr → $gate
  → $land → $close`. The check/fix loop repeats only while progress continues.
  Router: `~/.codex/sprintflow-backend.json`.
  Human docs `~/Desktop/sprintflow.html` are not routing input.
- `$grill-with-docs` = `$start` helper. Workflow output is evidence/plan input
  only — never replaces local verification or release authority.
- Production readiness: `~/.codex/skills/references/gates-and-nets-production.md`
  + `~/.codex/skills/references/next-skill-router.md`.
- Helpers/subagents rejoin main before `$gate` / `$land` / `$close` / final claims.

## Native Goals And Inbox

- `get_goal` when an active goal matters; `create_goal` only on explicit request.
- Goals do not authorize destructive/admin, credentials, production/release, or
  tracker-Done transitions.
- Active goal turns: read `<workspace-root>/todo_goal.md` before substantive
  work; append after steering/milestones/blockers/proof. Append-first; no
  secrets; never rewrite history unless asked. Milestone notification only via
  already-authorized local paths.

## Tools Detail

- Containers: Apple `container` first; docker/Colima only for compose or
  repo-mandated docker. `sandbox_mode` in config.toml = Seatbelt, unrelated.
- Composio-first for Gmail/Drive/Jira/Linear/Figma/Cloudflare/etc.
  Skill: `~/.codex/skills/composio-cli/SKILL.md`. Binary:
  `~/.composio/composio`. Missing link → stop at `composio link` unless user
  authorizes login.
- Native beats Composio when better: `$firecrawl`, Browser, Computer Use,
  XcodeBuildMCP, Firebase, RevenueCat, App Store, NotebookLM. TinyFish only when
  explicitly requested or Firecrawl unavailable.
- Research: NotebookLM corpus check before re-research; publish via
  `~/.codex/skills/notebooklm/scripts/publish.sh .research/<slug>` (best-effort).
- Docs: Context7 plugin/MCP first; CLI skill at
  `~/.codex/skills/context7-cli/SKILL.md`. Local/`rg`/Graphify
  for private repo docs; `$firecrawl` for live pages outside Context7.
- Token work: relevant-file selection → caps → Headroom for large sessions.
  No LiteLLM/provider billing frameworks unless scoped.

## Token Hygiene

- Cap noisy commands: `~/.codex/token-helpers/cap-output --bytes 6000 -- <cmd>`.
- `repomix --compress ...` only when a whole-repo bundle is explicitly useful.
- Summarize logs/JSON before retaining: `compact-logs`, `summarize-json`, short
  error excerpts.
- Long sessions: compact `HANDOFF.md` (~1000 tokens) after 4–5 substantial turns.

## Obsidian Formats

- Memory vault: `~/Development/Obsidian` (`wiki/hot.md`). Prefer this over any
  stale `Documents/Obsidian/Codex-Knowledge` path.
- Format routing names (`obsidian-markdown`, `obsidian-bases`, `json-canvas`,
  `obsidian-cli`, `defuddle`) match CLAUDE.md. As of 2026-07-09 those kepano
  skills are **not** present as live `~/.codex/skills/<name>` entries (only
  `.archived/obsidian-vault`). Re-install/sync before relying on `$skill` load,
  or use `obsidian` CLI / file tools directly.
- Vault name trap: registered vaults may both be named "Obsidian" — verify
  `obsidian vault` path before writes.

## macOS Recovery Detail

- The healthy primary account is `/Users/testadmin`; the old
  `/Users/jadenmaciel-shapiro` profile had auth/keychain corruption.
- Preserve Apple auth stability when changing local dev tooling, shell startup,
  background jobs, Homebrew permissions, indexing, account settings, or
  migration state.
- Never import old keychains, Apple Account/iCloud state, Messages/FaceTime
  state, IdentityServices, Accounts DB, TCC databases, browser cookies/sessions,
  encrypted app DBs, AI runtime/session state, whole Library folders, or old
  LaunchAgents into `testadmin`.
- Do not rename the short user/home, delete the old account, restore old
  LaunchAgents, recursively `chmod`/`chown` broad paths, restart Apple auth
  daemons, reset keychains, disable SIP, or perform account database surgery
  without explicit approval, durable external backup, and rollback.
- If Apple auth symptoms recur, first test from a clean admin account and
  distinguish user-profile scope from system-wide failure.

## Karpathy Guidelines

Full text:

- `~/.codex/vendor_imports/skills/andrej-karpathy-skills/CLAUDE.md`

Runtime summary:

- Think before coding. State assumptions when they matter.
- Prefer the minimum code that solves the request.
- Touch only what the request requires; do not clean unrelated code.
- Define success criteria and verify with the smallest useful check.

Refresh helper: `~/.codex/scripts/sync-karpathy-guidelines` (does not require a
missing `karpathy-guidelines/SKILL.md` path).

## Printed CLI Skills

Printing Press CLIs live in `~/go/bin/` and are surfaced as skills under
`~/.codex/skills/` when linked. Use the skill body for the exact command contract.

Common API surfaces:

- `/pp-linear`: Linear issue operations.
- `/pp-atlassian`: Jira Cloud operations.
- `/pp-cloud-run-admin`: Google Cloud Run service management.
- `/pp-google-search-console`: Search Console sites, queries, sitemaps.
- `/pp-jina`: URL-to-markdown and web extraction.
- `/pp-revenuecat`: RevenueCat v1 REST API.
- `/pp-tavily`, `/pp-serpapi`, `/pp-apify`, `/pp-lightrag`: search,
  scraping, and knowledge operations when explicitly useful.

Google CLIs use `gcloud` tokens; refresh with `pp-auth-refresh` when needed.

## Knowledge And Memory

- Raw evidence first, then wiki/project memory, then outputs.
- Before broad architecture, workflow, agent-integration, SprintFlow, or prior
  decision work, do a lightweight read-only check of
  `/Users/testadmin/Development/Obsidian/wiki` starting with `hot.md` and
  `index.md`.
- Keep Context7, TinyFish, Graphify, LLM Wiki, and LightRAG as external
  reference surfaces. Sync only summaries or explicit notes unless the user
  asks for broader ingestion.
- `$close` is the memory persistence boundary. Prefer file-backed sinks when
  external/auth-backed memory is unavailable.

## Mistake Memory Loop

When a clear bug, user correction, false completion claim, repeated tool
failure, or workflow drift appears, draft a small lesson in a local file-backed
sink. Use:

`Symptom / Cause / Fix / Trigger / Scope / Evidence / Priority`

Promote only actionable, validated lessons at `$close` or task completion.
Reference: `~/.codex/skills/references/mistake-memory-loop.md`.

## Grok Build Background

Grok Build TUI state is maintained separately under `~/.grok/`. The current
cross-tool convention is that `~/.codex/skills/` is the canonical skill source,
with Grok-native copies synced from it. Keep repository-local `AGENTS.md` or
`CLAUDE.md` authoritative for project work. Do not import old profile paths or
Claude-sourced plugin state into the recovered account.

## AWS Repo Mapping

For AWS-heavy repos, map before editing:

1. Primary IaC, such as `infrastructure/terraform/`.
2. Legacy host/bootstrap paths, such as `scripts/provision_ec2.sh` and
   `infrastructure/systemd/`.
3. CI/CD and CDN deploy flows, such as `.github/workflows/*`.

Keep managed services, runbooks, and runtime entrypoints distinct and cite exact
file anchors in findings.
