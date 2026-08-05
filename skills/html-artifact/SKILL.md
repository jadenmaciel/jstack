---
name: html-artifact
description: "Create polished, standalone HTML artifacts from agent work. Use for HTML reports, rich plans/specs, research summaries, code reviews, QA reports, decision docs, shareable summaries, dashboards-for-a-document, or requests to use HTML instead of Markdown."
---

# HTML Artifact

Create visually readable, standalone HTML files for agent outputs that humans need to inspect, compare, share, or review. This skill is for artifacts, not full app builds or production UI features.

## Core Workflow

1. **Detect context first.**
   - Inspect the active workspace for existing design signals: CSS variables, design tokens, brand colors, component/style conventions, fonts, and artifact/evidence folder patterns.
   - Reuse project style when it is clear. If no style exists, use the restrained defaults in `assets/starter.html`.

2. **Choose a durable output path.**
   - Use a user-provided path when given.
   - Otherwise prefer an existing repo-local evidence or artifact folder.
   - If none exists, use `artifacts/html/` in the active workspace.
   - Avoid putting durable outputs in temp directories unless the user asks.

3. **Draft the content model before HTML.**
   - Lock the audience, title, purpose, sections, key facts, decisions, risks, tables, diagrams, and calls to action.
   - Keep short artifacts simple. Use HTML only when the visual structure earns its cost.

4. **Build standalone HTML.**
   - Use semantic HTML: `header`, `main`, `section`, `article`, `table`, `aside`, `footer`.
   - Shared local CSS and JS may be authoring sources, but every final HTML artifact intended for direct opening or sharing must inline its CSS and required JS. A linked local stylesheet does not count as standalone.
   - Do not depend on external CDNs, fonts, scripts, or network images by default.
   - Make the layout responsive, print-friendly, and accessible: readable contrast, visible focus states, and text that does not overflow.

5. **Verify before claiming standalone completion.**
   - Run `deno run --allow-read ~/.cursor/skills/html-artifact/scripts/verify-standalone.ts <html-path> [...html-path]`. It must pass before claiming a direct-open artifact is standalone.
   - The verifier rejects stylesheet links and script `src` dependencies, and requires a substantial inline style block plus basic document markers. Do not bypass it unless the user explicitly requests a multi-file bundle.
   - Open the generated file locally with Browser, Playwright, or browser-harness.
   - Capture at least one desktop screenshot and one narrow/mobile screenshot.
   - Check for text overlap, clipped content, broken tables, unreadable contrast, missing sections, and awkward wrapping.
   - Iterate until the artifact is visually sound, or report the exact verification blocker.

## Starter Template

Use `assets/starter.html` as a compact base when the workspace has no obvious design system. Copy it into the chosen output path, replace placeholder content, then adapt only what the artifact needs.

## Patterns Reference

Read `references/patterns.md` when choosing whether HTML is appropriate, selecting an artifact structure, or deciding how to translate a Markdown-style answer into a visual document.

## Guardrails

- Do not make a marketing landing page unless the user explicitly asks.
- Do not create a full web app, framework project, or build system for a simple artifact.
- Do not add JavaScript unless it materially improves the artifact, such as filtering a table or toggling dense sections.
- Do not hide uncertainty. Label assumptions, unresolved questions, and source quality directly in the artifact.
- If the artifact will be committed, keep diffs reviewable: one HTML file plus only necessary local assets.

## Next Skill Decision

Read `~/.cursor/skills/references/next-skill-router.md` before final output when choosing the next handoff. End with a compact `Next` section by default; use `NEXT_SKILL_DECISION` only when parser-safe output is explicitly requested.

Default helper routing: return to the invoking skill when the artifact is complete; recommend `$check` after changes that need validation, `$diagnosing-bugs` when browser/runtime root cause is unclear, or `$close` when normal ticket completion is the only remaining work. Do not invoke the recommendation.
