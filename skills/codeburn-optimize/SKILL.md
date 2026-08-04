---
name: codeburn-optimize
description: Use when the user asks about CodeBurn, LLM spend, token usage, rate-limit pressure, model efficiency, Claude vs Codex usage, subscription value, or where coding-agent usage can be optimized.
---

# CodeBurn Optimize

Use `codeburn` to turn coding-agent logs into spend, usage, efficiency, and optimization advice.

## Steps

1. Confirm the CLI exists.
   ```bash
   command -v codeburn
   codeburn --version
   ```
   Done when the executable path and version are known. If missing, say CodeBurn is unavailable and stop.

2. Pick the smallest useful window.
   - Today: `codeburn today --timezone America/Denver`
   - Yesterday: `codeburn models --from YYYY-MM-DD --to YYYY-MM-DD --provider all --format json`
   - This month: `codeburn month --timezone America/Denver`
   - Last 30 days: `codeburn models --period 30days --provider all`
   - All visible logs: `codeburn models --period all --provider all`

   Done when the command matches the user's timeframe. Use exact dates for "today" and "yesterday".

3. For spend and model mix, prefer non-interactive model tables.
   ```bash
   codeburn models --period 30days --provider all
   codeburn models --period all --provider all --format json
   ```
   Done when totals are separated by provider and model.

4. For waste, run optimize once per relevant provider.
   ```bash
   codeburn optimize --provider all
   codeburn optimize --provider claude
   codeburn optimize --provider codex
   ```
   Done when savings, waste type, and exact fix are identified. Skip provider-specific runs if the all-provider result already answers the question.

5. For Claude vs Codex decisions, compare efficiency, not only dollars.
   Report:
   - API-equivalent cost
   - calls and sessions
   - one-shot rate
   - retries/edit when visible
   - top projects and activities
   - cache hit rate

   Done when the recommendation says which plan/model should be the workhorse and why.

6. Keep the money caveat explicit.
   CodeBurn cost is API-equivalent token value unless the data proves actual billing. Subscription-covered usage is not the same as card spend.
   Done when the answer separates "API-equivalent" from "cash paid".

## Output

Lead with the answer, then the evidence.

Use this shape:

```text
Total: $X API-equivalent.

Provider split:
- Claude: $X
- Codex: $X

Optimization read:
- Biggest waste: ...
- Best fix: ...
- Subscription read: ...

Verified with: `command`
```

## Guardrails

- Do not use `codeburn report` unless the user asks for the interactive dashboard.
- Do not paste full JSON. Aggregate with `jq`, tables, or a short summary.
- Do not treat API-equivalent value as actual subscription billing.
- Do not recommend upgrading a plan from raw spend alone. Use one-shot rate and retry pressure too.
