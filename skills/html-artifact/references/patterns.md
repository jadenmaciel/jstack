# HTML Artifact Patterns

Use HTML artifacts when structure, comparison, or visual scanning is more valuable than raw editability.

## Good Artifact Types

- **Implementation plan:** summary, decisions, subsystem changes, tests, assumptions.
- **Research brief:** question, answer, source quality, comparison table, recommendation.
- **Code review:** severity-ranked findings, file references, risk notes, test gaps.
- **QA report:** environment, scenarios, screenshots, pass/warn/block verdict, follow-ups.
- **Architecture map:** system boundaries, data flow, tradeoffs, rollout steps.
- **Executive summary:** status, business impact, risks, decision needed, next owner.

## Prefer HTML When

- The output is long enough that visual hierarchy will help a human stay oriented.
- The reader needs to compare options, evidence, metrics, screenshots, or state.
- The artifact will be shared with stakeholders who are unlikely to edit Markdown.
- The document benefits from tables, callouts, section summaries, or print/PDF export.
- The user explicitly asks for a browser-viewable or visual version of an agent output.

## Prefer Markdown When

- The output is short, plain, or mostly conversational.
- The user will hand-edit it in source control.
- The artifact is code-adjacent documentation such as a README or migration note.
- Reviewable text diffs matter more than layout.

## Recommended Structures

### Plan or Spec

Use: title, summary, key decisions, implementation changes, tests, assumptions.

Make decisions visually obvious. Use tables only for comparisons or ownership, not for every bullet list.

### Research or Decision Brief

Use: question, recommendation, evidence quality, options table, risks, next action.

Separate facts from interpretation. Label stale, inferred, or unverified evidence.

### QA or Gate Report

Use: verdict, environment, scenarios, evidence links/screenshots, blockers, next state.

Keep pass/warn/block status visible near the top. Put logs behind summaries, not as pasted walls.

### Review Findings

Use: verdict, severity groups, finding cards, affected files, reproduction/proof, suggested fix.

Lead with risks and behavior, then summarize implementation context.

## Visual Defaults

- Use one restrained accent color unless project branding says otherwise.
- Keep section headings factual and scannable.
- Use callouts for decisions, blockers, and assumptions.
- Use responsive tables with horizontal scrolling on narrow screens.
- Leave enough whitespace for scanning, but avoid landing-page theatrics for operational artifacts.
