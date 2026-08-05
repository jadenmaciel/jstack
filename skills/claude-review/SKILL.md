---
name: claude-review
description: >-
  User-invoked Fable review via Claude Code CLI. Type $claude-review or
  /claude-review to shell out to claude -p with full tools.
disable-model-invocation: true
---

# Claude Review

Ask Claude Fable 5 High for one full-tools review. Cursor stays owner; Claude
output is advisory evidence, not approval.

**Allowed only when the user explicitly invoked this skill.** Never from
`$check`, ambient review, or “second opinion” routing.

## 1. Scope

Done when the review target is one sentence the CLI prompt can act on.

- User named files / PR / base → use that.
- Else → current branch vs merge-base of default base (`main`/`master`),
  including uncommitted changes if present.

## 2. Preflight

Done when `claude` works, or the user is told to stop.

```bash
which claude && claude --version
```

If missing or auth-gated: report the blocker. Do not invent a review.

## 3. Invoke

Done when stdout returns, or the command errors with a short pasted reason.

Run from the repo CWD (add `--add-dir <path>` if the target is outside cwd).
One call at a time.

```bash
claude -p \
  --model fable \
  --effort high \
  --permission-mode bypassPermissions \
  --tools default \
  --no-session-persistence \
  --output-format text \
  "$PROMPT"
```

### Prompt contract

Include:

- Owner: Cursor.
- CWD/worktree, branch/base, review target (one sentence).
- Mode: full tools (`--tools default`, `--permission-mode bypassPermissions`).
- Judge: bugs, risks, simpler path, concrete suggestions.
- Forbidden: secrets/credentials/customer data unless the user explicitly
  authorized this exact bundle; no nested consultations.
- Output: ranked findings (critical → suggestion), missed risks, simpler path,
  confidence.

## 4. Relay

Done when the user sees the review and one concrete Next action.

Present findings as advisory. Verify any claim that would change code before
acting on it.
