---
name: aws-cli
description: "AWS CLI operations across accounts, profiles, regions, IAM, S3, EC2, ECS, ECR, RDS, Lambda, CloudFormation, CloudWatch, Route53, STS, SSO, and Organizations. Use when the user mentions AWS, aws cli, profiles/credentials, buckets, instances, clusters, or other Amazon cloud resources."
allowed-tools:
  - Bash(aws *)
  - Bash(brew *)
---

# AWS CLI

AWS is the real cloud backend. Prefer `aws` directly for AWS inspection and operations; do not invent local state or assume the active account.

## Troute Default Profile

When the user asks for Troute AWS or fulfillment AWS work and does not name another profile, use:

```bash
--profile troute-fulfillment --region us-west-2
```

This profile is AWS SSO for account `698623007242` with role `IAM-Full-Access`. Treat it as admin-capable: read-only discovery is okay after identity proof, but every mutating or billing-impacting action still needs exact current-turn authorization for account, region, service, and resource. Do not copy browser callback URLs, auth codes, or token material into config; use `aws sso login --profile troute-fulfillment`.

## Preflight (boundary capability check)

Before a run whose promised outcome is real AWS verification (identity-proven reads, deploys, or mutations), declare the capabilities that outcome needs so a missing tool or expired profile fails BEFORE work starts, not mid-task:

```bash
~/.codex/scripts/unattended-preflight --require-command aws --require-auth aws-profile:<name>
```

Nonzero exit means the boundary cannot be verified this run (aws absent or SSO expired) — report that instead of proceeding. Ordinary local AWS reads do not need preflight; only declare capabilities your claimed outcome actually depends on.

## Install, Version, Auth

```bash
aws --version
brew install awscli
brew upgrade awscli
aws configure
aws configure sso
aws sso login --profile PROFILE
```

Credential setup, browser SSO login, access-key entry, token entry, and account switching are credential-gated. Stop for the user before creating, pasting, importing, rotating, or storing AWS credentials unless explicitly authorized in the current turn. Never print access keys, session tokens, or raw credential files.

## Profile And Identity First

Always identify the active account and region before AWS work, especially before anything that writes, deploys, bills, or deletes. Use explicit `--profile PROFILE` and `--region REGION`; do not rely on ambient defaults for production/admin work.

```bash
aws configure list-profiles
aws configure list --profile PROFILE
aws sts get-caller-identity --profile PROFILE --output json
aws configure get region --profile PROFILE
```

## Safe Read-Only Discovery

Use `--output json`, `--query`, and `--no-cli-pager` to keep output bounded.

```bash
aws sts get-caller-identity --profile PROFILE --output json
aws s3 ls --profile PROFILE
aws ec2 describe-vpcs --profile PROFILE --region REGION --output json
aws ecs list-clusters --profile PROFILE --region REGION --output json
aws ecr describe-repositories --profile PROFILE --region REGION --output json
aws rds describe-db-instances --profile PROFILE --region REGION --output json
aws logs describe-log-groups --profile PROFILE --region REGION --output json
aws cloudformation list-stacks --profile PROFILE --region REGION --output json
```

Redact or summarize account IDs, ARNs, bucket names, and private resource names when unnecessary.

## Mutating Or Admin Commands

Treat AWS commands as production/admin unless proven read-only. Require explicit current-turn authorization for the exact account, region, service, and resource before running commands with verbs such as:

```text
create, put, update, delete, remove, terminate, reboot, stop, start, deploy,
sync, cp upload, restore, modify, attach, detach, authorize, revoke, associate, disassociate, tag, untag, register, deregister, enable, disable, set
```

Before authorized mutation, capture identity and a preview when available:

```bash
aws sts get-caller-identity --profile PROFILE --output json
aws cloudformation validate-template --template-body file://template.yml --profile PROFILE --region REGION
aws cloudformation create-change-set ... --profile PROFILE --region REGION
aws s3 sync SOURCE DEST --dryrun --profile PROFILE
aws ec2 run-instances --dry-run ... --profile PROFILE --region REGION
```

AWS `--dry-run` support is service-specific. `DryRunOperation` usually proves permission without changing resources; `UnauthorizedOperation` usually proves missing permission. Neither proves the real command is safe.

## Common Workflows

```bash
aws s3 ls s3://BUCKET --profile PROFILE
aws s3 sync ./local s3://BUCKET/path --dryrun --profile PROFILE
aws cloudformation validate-template --template-body file://template.yml --profile PROFILE --region REGION
aws cloudformation describe-stacks --stack-name STACK --profile PROFILE --region REGION
aws cloudformation describe-change-set --stack-name STACK --change-set-name CHANGESET --profile PROFILE --region REGION
aws iam get-role --role-name ROLE --profile PROFILE
aws iam list-attached-role-policies --role-name ROLE --profile PROFILE
aws iam get-policy-version --policy-arn ARN --version-id VERSION --profile PROFILE
aws logs tail LOG_GROUP --since 30m --profile PROFILE --region REGION
aws logs filter-log-events --log-group-name LOG_GROUP --start-time EPOCH_MS --profile PROFILE --region REGION
```

## Automation Notes

Set `AWS_PAGER=""` or use `--no-cli-pager` for noninteractive runs. Prefer JSON output plus `--query` over broad dumps. Report local CLI proof, credential/profile proof, read-only cloud proof, and mutation/deploy proof as separate claims.
