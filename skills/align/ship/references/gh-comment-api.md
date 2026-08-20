# gh commands for PR review threads and checks

All via the `gh` CLI (authenticated). `$OWNER`/`$REPO`/`$PR`/`$BRANCH` below are placeholders.

## Coordinates + PR number

```bash
gh repo view --json owner,name --jq '{owner: .owner.login, name: .name}'
gh pr view --json number --jq .number   # current branch's PR; pass a number to override
```

## Fetch unresolved review threads

Returns each thread's GraphQL node id, resolution state, root comment id (for replies), and every comment with file/line.

```bash
gh api graphql -f query='
query($owner:String!,$name:String!,$pr:Int!){
  repository(owner:$owner,name:$name){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{
          id
          isResolved
          isOutdated
          comments(first:100){
            nodes{ databaseId author{login} body path line }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f name="$REPO" -F pr="$PR" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false)'
```

`id` = the thread node id (for resolving). `comments[0].databaseId` = the root comment id (for replying).

## Top-level comments (no thread state -- reply only)

```bash
gh pr view "$PR" --json comments --jq '.comments[] | {author: .author.login, body: .body}'
gh pr view "$PR" --json reviews  --jq '.reviews[]  | select(.body != "") | {author: .author.login, state: .state, body: .body}'
```

## Reply to a thread

Replies to the chain rooted at `$ROOT_COMMENT_DBID` (the `comments[0].databaseId` above).

```bash
gh api -X POST "repos/$OWNER/$REPO/pulls/$PR/comments/$ROOT_COMMENT_DBID/replies" -f body="Done in $(git rev-parse --short HEAD)."
```

## Resolve a thread

```bash
gh api graphql -f query='mutation($id:ID!){ resolveReviewThread(input:{threadId:$id}){ thread{ isResolved } } }' -f id="$THREAD_ID"
```

## List failing checks

`bucket` collapses the raw `state` into pass / fail / pending / skipping / cancel -- filter on `fail`.

```bash
gh pr checks "$PR"   # all checks + state; exits non-zero if any fail
gh pr checks "$PR" --json name,bucket,state,workflow,link \
  --jq '.[] | select(.bucket=="fail")'
```

## Read a failed check's log

Find the failing workflow run on the branch, then dump only its failed steps.

```bash
gh run list --branch "$BRANCH" --json databaseId,conclusion,workflowName \
  --jq '.[] | select(.conclusion=="failure")'
gh run view "$RUN_ID" --log-failed
```

Reproduce Terraform checks locally: `terraform fmt -check`, `terraform validate`, `terraform plan`. A `plan` that fails only on credentials or external state is an environment problem, not a code fix.
