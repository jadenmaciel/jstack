---
name: repo-onboard
description: Stamp the code-landing baseline (env-map hooks, core.hooksPath, AGENTS.md/CLAUDE.md stubs, PR template, CI check workflow) into a repo that lacks it. Use on /repo-onboard when onboarding a new or pre-baseline repo.
---

# repo-onboard

Bring a repo up to the baseline described in
`/Users/testadmin/Development/README-repo-baseline.md`: local hook wiring plus
a handful of committed stub files. Never overwrites anything that already
exists — only fills gaps, and only after the user confirms the gap list.

## Steps

1. **Read the baseline.** Load
   `/Users/testadmin/Development/README-repo-baseline.md` for the current
   checklist (committed files, local wiring, what's out of scope).

2. **Scan.** From the repo root, in the style of `autohooks`' signal scan,
   check for:
   - Language/build signal: `go.mod`, `package.json` (+ lockfile),
     `Package.swift`, `pyproject.toml` / `requirements.txt`, `Cargo.toml`.
   - Existing CI: any `.github/workflows/*.yml`.
   - Existing docs: `AGENTS.md`, `CLAUDE.md`, `README.md`.
   - Existing PR template: `.github/PULL_REQUEST_TEMPLATE.md`.
   - Existing hook wiring: `git config core.hooksPath`, `.claude/settings.json`,
     `.claude/hooks/env-map.sh`, `.claude/env-map.md`.
   - Whether `.claude/` is already git-ignored (tracked `.gitignore` or
     `.git/info/exclude`).

3. **Present the gap list and wait.** One line per baseline item: pass
   (present already), or missing (would be stamped). Do not touch the repo
   until the user confirms. Nothing here is destructive, but a hook and a
   committed CI workflow are the kind of thing a repo owner should approve
   before they land.

4. **Local wiring** (only after confirmation; skip any sub-item already
   present):
   - `git config core.hooksPath /Users/testadmin/.codex/git-hooks` in the
     repo.
   - Copy `templates/env-map.sh` to `<repo>/.claude/hooks/env-map.sh`,
     `chmod +x` it.
   - Copy `templates/env-map.md` to `<repo>/.claude/env-map.md`.
   - Merge a `SessionStart` env-map hook entry into
     `<repo>/.claude/settings.json` (create the file as `{}` first if
     absent). Reuse autohooks' exact merge pattern — write the matcher group
     to a temp file, then:

     ```bash
     # group.json holds just the matcher-group object (written with the Write tool)
     jq --slurpfile g group.json \
       '.hooks.<Event> = ((.hooks.<Event> // []) + $g | unique)' \
       .claude/settings.json > .claude/settings.json.tmp \
       && jq -e . .claude/settings.json.tmp >/dev/null \
       && mv .claude/settings.json.tmp .claude/settings.json
     ```

     `<Event>` is `SessionStart` and the group is:

     ```json
     {
       "matcher": "startup|resume|clear|compact",
       "hooks": [
         { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/env-map.sh" }
       ]
     }
     ```
   - If `.claude/` is not already git-ignored, add it via
     `<repo>/.git/info/exclude` — never edit the repo's tracked `.gitignore`
     uninvited; that file is the maintainers' surface, not this skill's.

5. **Hand off hook recipes.** Tell the user to run `/autohooks` next to pick
   hook recipes (formatters, destructive-command blocking, etc.). Do not
   install or duplicate any recipe here — that's autohooks' job, and
   reimplementing it here would just drift out of sync with it.

6. **Stamp missing committed files only** (copy from `templates/`, never
   overwrite an existing file):
   - `AGENTS.md` stub (if the repo has none).
   - `CLAUDE.md` stub (if the repo has none) — a one-line `@AGENTS.md` import
     plus an empty `## Claude-only deltas` header.
   - `.github/PULL_REQUEST_TEMPLATE.md`.
   - `.github/workflows/check.yml` — deliberately fails
     (`echo "TODO: replace with this repo's real check command..." && exit 1`)
     until someone points it at the repo's real check command. A silently
     passing placeholder is worse than an honest failing one.

7. **Final report.** One line per baseline item: `pass` (already present,
   untouched), `stamped` (just created), or `skipped` (existed, left alone).
   Suggest `/autohooks` next, and `/setup-matt-pocock-skills` if the repo
   also wants the issue-tracker/triage/domain-doc layer.

## What this skill does not do, on purpose

- **Not `/git-guardrails-claude-code`.** That installs a PreToolUse hook
  blocking destructive git commands — the same job as autohooks'
  `block-destructive-bash` recipe. Run `/autohooks` instead so there's one
  installer for hook recipes, not two.
- **Not `/setup-pre-commit`.** That wires Husky + lint-staged, a
  Node-ecosystem-specific commit-time gate. This skill's local wiring is the
  global `core.hooksPath` (language-agnostic, one hooks dir for every repo);
  adding Husky on top would be a second, redundant commit-time gate.
