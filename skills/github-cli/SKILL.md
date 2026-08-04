---
name: github-cli
description: "GitHub operations via the `gh` CLI: PRs (view/list/create/merge/review/comments/checks/diff), issues, repos, releases, workflow runs, and raw REST/GraphQL via `gh api`. Replaces the GitHub MCP. Trigger on any PR number, issue reference, owner/repo URL, or GitHub request. Requires `gh` on PATH and authenticated."
allowed-tools:
  - Bash(gh *)
---

# GitHub CLI (gh)

`gh` wraps GitHub's REST + GraphQL APIs. Auth is persistent via `gh auth login`; no env vars needed per-call.

## Prerequisites

```bash
gh auth status   # confirm logged in
gh --version     # 2.88+ recommended
```

If auth fails, tell the user to run `gh auth login` themselves (interactive).

## Output Format

Default output is human-readable. For parsing, always pass `--json <fields> [--jq '<expr>']`:

```bash
gh pr view 123 --json number,title,state,author --jq '{n:.number, t:.title}'
```

`--json` without `--jq` returns structured JSON. Most subcommands expose a fixed field set - list available fields by running the command with `--json` alone (it errors with the full list).

---

## Pull Requests

### View a PR

```bash
gh pr view 123                                    # human
gh pr view 123 --json number,title,state,body,headRefName,baseRefName,mergeable,mergeStateStatus,isDraft,author,reviewDecision
```

Cross-repo:

```bash
gh pr view 123 --repo owner/repo
```

### List PRs

```bash
gh pr list --state open --limit 30
gh pr list --author "@me" --json number,title,state,headRefName
gh pr list --search "is:open review-requested:@me" --json number,title,url
```

### Create a PR

```bash
gh pr create \
  --title "PUR-83: fix contrast on main tab" \
  --body "$(cat <<'EOF'
## Summary
- one
- two

## Test plan
- [ ] lint
- [ ] unit
EOF
)" \
  --base main \
  --head feature/pur-83
```

Add `--draft` for WIP, `--reviewer user1,user2`, `--label bug,p1`, `--assignee @me`.

### PR Diff and Changed Files

```bash
gh pr diff 123                                    # unified diff
gh pr diff 123 --name-only                        # file list
gh pr view 123 --json files --jq '.files[].path'  # same, via API
```

### PR Checks (CI Status)

```bash
gh pr checks 123                                  # table
gh pr checks 123 --json name,state,conclusion --jq '.[] | select(.conclusion=="FAILURE")'
gh pr checks 123 --watch                          # blocks until done
```

### Reviews and Comments

```bash
# List review comments (inline, line-level)
gh api repos/{owner}/{repo}/pulls/123/comments --jq '.[] | {user: .user.login, path, line, body}'

# List issue-style PR comments (top-level discussion)
gh api repos/{owner}/{repo}/issues/123/comments --jq '.[] | {user: .user.login, body}'

# Add a top-level PR comment
gh pr comment 123 --body "LGTM after rebase"

# Submit a review
gh pr review 123 --approve --body "ship it"
gh pr review 123 --request-changes --body "see inline"
gh pr review 123 --comment --body "nit: naming"
```

### Merge

```bash
gh pr merge 123 --squash --delete-branch          # preferred default
gh pr merge 123 --merge                           # merge commit
gh pr merge 123 --rebase
gh pr merge 123 --auto --squash                   # merge once checks pass
```

Worktree gotcha: `gh pr merge` can fail inside a git worktree. Fallback via REST:

```bash
gh api -X PUT repos/{owner}/{repo}/pulls/123/merge \
  -f merge_method=squash -f commit_title="PUR-83: fix contrast"
```

### Close / Reopen / Ready

```bash
gh pr close 123
gh pr reopen 123
gh pr ready 123                                   # draft -> ready
```

### Checkout a PR Locally

```bash
gh pr checkout 123
```

---

## Issues

### View / List

```bash
gh issue view 456
gh issue view 456 --json number,title,state,labels,assignees,body
gh issue list --state open --label "its:broken" --limit 20
gh issue list --search "is:open no:assignee label:security" --json number,title,url
```

### Create

```bash
gh issue create \
  --title "Contrast broken on main tab" \
  --body "Steps to repro..." \
  --label "its:broken,p1" \
  --assignee "@me"
```

### Comment / Close / Reopen / Label

```bash
gh issue comment 456 --body "repro'd on iOS 18.2"
gh issue close 456 --reason completed
gh issue reopen 456
gh issue edit 456 --add-label security --remove-label triage
```

---

## Repos

```bash
gh repo view owner/repo
gh repo view owner/repo --json name,defaultBranchRef,visibility,isArchived
gh repo list <owner> --limit 50 --json name,isPrivate,pushedAt
gh repo clone owner/repo
gh repo create owner/new-repo --private --source=. --push
gh repo fork owner/repo --clone
```

---

## Commits / Branches / Files

```bash
# Recent commits on a branch
gh api repos/{owner}/{repo}/commits?sha=main\&per_page=20 \
  --jq '.[] | {sha: .sha[0:7], msg: .commit.message | split("\n")[0], author: .commit.author.name}'

# Compare two refs
gh api repos/{owner}/{repo}/compare/main...feature/branch \
  --jq '{ahead: .ahead_by, behind: .behind_by, files: [.files[].filename]}'

# Read a file at a ref
gh api repos/{owner}/{repo}/contents/path/to/file.py?ref=main \
  --jq '.content' | base64 -d

# Create or update a file
gh api -X PUT repos/{owner}/{repo}/contents/path/to/file.md \
  -f message="docs: update readme" \
  -f content="$(base64 -i file.md)" \
  -f branch=main
```

---

## Workflow Runs (Actions)

```bash
gh run list --limit 10
gh run list --workflow ci.yml --branch main --limit 5
gh run view <run-id>
gh run view <run-id> --log-failed                 # tail failing step logs
gh run watch <run-id>                             # block until done
gh run rerun <run-id>
gh run rerun <run-id> --failed                    # only failed jobs
gh run cancel <run-id>
```

---

## Releases

```bash
gh release list --limit 10
gh release view v1.2.0
gh release create v1.2.1 --title "v1.2.1" --notes "Bug fixes" --target main
gh release upload v1.2.1 ./dist/app.zip
```

---

## Raw API Escape Hatch

When a subcommand doesn't expose what you need, drop to REST or GraphQL:

```bash
# REST
gh api repos/{owner}/{repo}/pulls/123/reviews --jq '.[] | {user: .user.login, state, body}'
gh api -X PATCH repos/{owner}/{repo} -f description="new desc"

# Paginated
gh api --paginate repos/{owner}/{repo}/issues?state=all

# GraphQL
gh api graphql -f query='
  query($owner:String!, $name:String!) {
    repository(owner:$owner, name:$name) {
      pullRequests(first:10, states:OPEN) {
        nodes { number title reviewDecision mergeStateStatus }
      }
    }
  }' -F owner=buzz-financial -F name=troute-shipping
```

`{owner}/{repo}` placeholders auto-resolve to the current repo when run inside one. Pass `--repo owner/name` to target elsewhere.

---

## Search

```bash
gh search prs "is:open author:jadenms org:buzz-financial" --json number,title,url
gh search issues "is:open label:p1 archived:false" --limit 20
gh search code "merchant_id" --repo buzz-financial/troute-shipping --limit 10
gh search repos "topic:swiftdata stars:>50"
```

---

## Usage Notes

- Auth is persistent - never echo tokens; let `gh` manage them. If `gh auth status` fails, stop and ask the user.
- Inside a git repo, `--repo` is optional; `gh` infers from `origin`.
- Inside a git worktree, `gh pr merge` can fail - use the `gh api -X PUT .../merge` fallback.
- For scripting: always prefer `--json` + `--jq` over parsing human output.
- `--paginate` auto-follows `Link` headers for list endpoints; without it you get one page (default 30).
- Writing a long `--body` or `--notes`: use a HEREDOC, not an inline multiline string, to preserve formatting.
- Commit messages, PR titles, PR bodies: undercover mode applies - no AI attribution, no Co-Authored-By lines.
- `gh` uses `GH_TOKEN`/`GITHUB_TOKEN` env vars if set; they override `gh auth login`. Unset them for interactive auth issues.
