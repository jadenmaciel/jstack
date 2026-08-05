---
name: skillspector
description: "Runs NVIDIA SkillSpector security scans on agent skill bundles and reports risk before install or use. Use when scanning or auditing Claude, Codex, Gemini, or MCP skills, SKILL.md files, skill repos or zips, or when the user mentions SkillSpector."
---

# SkillSpector

## Quick Start

Use the bundled wrapper for local scans:

```bash
/Users/testadmin/.cursor/skills/skillspector/scripts/skillspector-scan ./path/to/skill --no-llm
```

Write a machine-readable report when the result needs to be preserved:

```bash
/Users/testadmin/.cursor/skills/skillspector/scripts/skillspector-scan ./path/to/skill --no-llm --format json --output /tmp/skillspector-report.json
```

## Workflow

1. Identify the target exactly: directory, `SKILL.md`, Git URL, zip, or repo.
2. Prefer static scanning first with `--no-llm`; this avoids credential use and gives a fast baseline.
3. If semantic judgment is needed and the user has already authorized/provider-configured credentials, run without `--no-llm`.
4. Treat exit code `1` as “high-risk findings present,” not a wrapper failure. Read/report the findings.
5. Treat exit code `2` or wrapper setup errors as execution failures. Fix setup or report the blocker.
6. Summarize severity, risk score, concrete findings, and whether evidence is static-only or LLM-assisted.

## LLM Analysis

Only use LLM mode when credentials are already configured or the user explicitly asks for it. Supported provider variables include:

```bash
SKILLSPECTOR_PROVIDER=openai
OPENAI_API_KEY=...
OPENAI_BASE_URL=...
SKILLSPECTOR_MODEL=...
```

Other supported providers include Anthropic with `ANTHROPIC_API_KEY` and NVIDIA endpoints with `NVIDIA_INFERENCE_KEY`.

## Notes

- The wrapper uses the local NVIDIA SkillSpector checkout by default.
- Override the checkout with `SKILLSPECTOR_REPO=/path/to/SkillSpector` if needed.
- Do not paste secrets into reports or prompts. Redact credential-looking output.
