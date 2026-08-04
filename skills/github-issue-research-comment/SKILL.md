---
name: github-issue-research-comment
description: "Prepare GitHub issues for stronger implementation agents: read the issue, inspect the repo, gather evidence (local files/Context7/deep-research), post an execution brief, and tag the issue reviewed. Use to enrich, prepare, research, triage, or comment on issues before a bigger model executes them."
argument-hint: "repo/issue selector and optional comment goal"
allowed-tools:
  - Bash(gh *)
  - Bash(git *)
  - Bash(rg *)
  - Bash(fd *)
  - Bash(find *)
  - Bash(sed *)
  - Bash(jq *)
  - Bash(curl *)
  - Bash(context7-cli *)
  - Bash(firecrawl *)
  - Bash(jina-pp-cli *)
  - Bash(jina-cli *)
  - Read
  - Write
  - Glob
  - Grep
---

# GitHub Issue Research Comment

Use this skill as a context-upgrade pass. A smaller or cheaper model should do the legwork that does not require deep implementation judgment: read the issue, inspect the actual project, research current sources, and leave the issue in a better state for a stronger model to execute.

The deliverable is an implementation-ready GitHub issue comment that is posted to the issue. It should reduce ambiguity, cite evidence, expose constraints, and give the next model a clear starting point.

## Quick Start

```bash
gh issue view <number> --json number,title,state,author,body,labels,comments,url
gh issue list --state open --limit 20 --json number,title,labels,updatedAt,url
rg "<key term from issue>" .
```

Default behavior is to post the execution brief comment and add the `reviewed` label. Invoking this skill is explicit permission to leave that comment and label automatically. Do not ask for approval before posting.

## Success Criteria

The comment should give a stronger executor: issue summary, relevant files/symbols/tests/docs, current external sources when needed, constraints/open questions, acceptance criteria, a validation plan, and a recommended first implementation step. Posted issues should also have the `reviewed` label.

## Research Ladder

Use the lightest evidence source that answers the issue, but do not skip grounding: local `rg`/docs/tests first; Graphify when `graphify-out/graph.json` exists for repo/package/docs questions; Context7 for external library/framework/SDK/API behavior; deep-research pattern for current web, market, regulatory, product, or ambiguous claims; Firecrawl/Jina only when page fetch/search is needed beyond Context7 or local evidence.

## Workflow

1. Identify scope: resolve repo with `gh repo view --json nameWithOwner,url` and `git remote -v`; resolve issue numbers from prompt, labels, milestone, search, or `gh issue list`.
2. Read the issue: fetch title, body, labels, state, linked PRs when available, and recent comments. Preserve the author's wording and constraints.
3. Inspect the project: read relevant `AGENTS.md`, README, docs, config, tests, and code paths named by the issue. Use `rg` for symbols, error text, routes, labels, feature names, and TODOs.
4. Run the research ladder. Record which helpers were used or skipped and why.
5. Synthesize the execution brief: separate proven facts from inference; include exact files, local/Graphify findings, Context7 docs, commands, errors, screenshots, external links, acceptance criteria, validation, and the first implementation move.
6. Post and verify: use `gh issue comment <number> --body-file <file>`, apply `gh issue edit <number> --add-label reviewed`, and verify with `gh issue view <number> --comments --json comments,labels,url`. Draft-only is allowed only when the user explicitly says not to post.

## Comment Template

```markdown
I did a context pass to make this easier to implement.

Issue summary:
- <what this issue is really asking for>

Evidence:
- `<path>:<line>` or `<command>` -> <why this matters>
- Local/Graphify: <path/query/result, if used>
- Context7 or URL: <library/topic/page result, if used>

Constraints / open questions:
- <constraint, risk, or question; say "none found" if none>

Suggested acceptance criteria:
- <observable behavior or testable outcome>
- <observable behavior or testable outcome>

Suggested validation:
- `<command or manual check>` -> <what it proves>

Recommended first step:
- <smallest implementation move for the stronger model>
```

## Guardrails

- Do not post speculative comments. If the evidence is weak, say what is missing.
- Do not implement the issue in this skill unless the user explicitly asks; the primary job is preparing execution context.
- Do not expose secrets, tokens, private logs, customer data, raw OCR text, or other sensitive issue context.
- Do not dump full local search, Graphify, Context7, web, or command output into the comment; summarize the relevant fact and cite the source/tool.
- Only add the `reviewed` label after the context pass succeeds. If the label is missing, create it with `gh label create reviewed --description "Context pass completed" --color 0E8A16` when safe for the repo.
- Do not close, assign, edit issue bodies, or add labels other than `reviewed` unless explicitly asked.
- For many issues, work one issue at a time unless the user asks for batch comments.
