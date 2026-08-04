---
name: company-standard
description: Apply verified company and product standards for epayment, TRoute, legacy PHP, TypeScript/Prisma module services, AWS ECS deployment, and develop/staging/production infrastructure. Use when designing, implementing, reviewing, deploying, or auditing company backend work; changing APIs, authentication, validation, databases, Docker, AWS, CI/CD, secrets, networking, environments, or documentation; or checking work for company-standard compliance.
---

# Company Standard

Use the bundled references as the portable module-service baseline. Use live repository and TRoute sources for current product evidence. Keep the legacy epayment host and standalone module services as separate systems.

## Route the work

- For backend structure, Express entry points, TypeScript types, validation, authentication, JWT, Prisma, sessions, domain resources, database changes, or API errors, read [references/backend-design.md](references/backend-design.md) completely before acting.
- For Docker images, AWS infrastructure, ECS/Fargate, ECR, RDS, Secrets Manager, IAM, load balancers, API Gateway, DNS, migrations, deployment testing, or adding a service, read [references/microservice-deployment.md](references/microservice-deployment.md) completely before acting.
- For develop, staging, or production topology; shared versus isolated resources; environment setup; per-service setup; GitHub Actions environments; CD; routes; or environment checklists, read [references/multi-environment.md](references/multi-environment.md) completely before acting.
- Read every matching reference when work crosses branches. The multi-environment guide cites phases in the deployment guide, so read both for environment or cross-environment deployment work.
- For epayment or legacy TRoute PHP work, locate the active `ExpiTrans/epayment` checkout, read every applicable `AGENTS.md`, record its remote, branch, and commit, then inspect the implementation and task-specific documents named by `AGENTS.md`. If no active checkout is evident, try `/Users/testadmin/Development/work/epayment`; report a limitation if it is absent. Apply the bundled TypeScript/Prisma guides only to separate module services.
- For TRoute wiki context, read the epayment checkout's redacted `company-docs/troute-wiki-digest.md` first when available. Search the TRoute Confluence space with Atlassian Rovo for pages relevant to the task, then fetch each selected current page in full. If Rovo is unavailable, use the digest and report its read date and reduced freshness.

## Resolve authority

Apply sources in this order:

1. User instructions and applicable repository instructions.
2. Current implementation and configuration on the target branch.
3. Accepted repository ADRs and specifications.
4. The bundled company module standards.
5. TRoute wiki guidance within its documented PHP-host or team-workflow scope.
6. Jira tickets as evidence of planned work, never proof of merged or deployed behavior.

Treat an explicit repository deviation as local scope, not a rewrite of the company baseline. Report contradictions instead of blending them.

## Check freshness

Before relying on documentation:

1. Record the current date and the target repository's remote, branch, and commit.
2. Confirm every cited file exists on that branch. Label untracked, ignored, worktree-only, ticket-only, and PR-only material accurately.
3. Compare hashes when the bundled standards also exist in a repository. Report drift and identify the adoption ADR or ticket; never merge divergent copies silently.
4. Confirm each Rovo result is a current page, fetch its full body, and distinguish its modification state from the local digest's read date.
5. Verify operational claims against current repository or infrastructure evidence available within the user's authorization. Documentation alone does not prove deployed state.

If a required repository, connector, page, or accepted contract is unavailable, state the limitation or block the affected conclusion.

## Enforce audited guardrails

- Set ECS `executionRoleArn` to the shared `ecsTaskExecutionRole`; set `taskRoleArn` to the service and environment task role. The identical-role JSON examples conflict with the deployment guide's explicit separation rule and must not be copied.
- Treat `HMAC_ENFORCE=false` as rollout-only. Require `HMAC_ENFORCE=true` for production completion after facade signatures have been verified.
- Treat the internal JWT TTL as unresolved: the backend guide says approximately 60 seconds while the deployment guide says five minutes. Use an accepted target-repository ADR or tested contract; otherwise report a blocker.
- Keep epayment's PHP/SFTP host deployment model separate from module-service ECS/Fargate deployment.
- Treat wiki pages marked `sensitive-risk` as restricted operational context. Never reproduce credentials or secret values; identify the affected page and remediation need without the value.

## Apply the standard

1. List the selected sources and their freshness evidence before proposing or editing work. Reuse an existing compliant pattern when one exists.
2. Extract the relevant requirements into a task-local checklist. Resolve placeholders such as service, region, account, VPC, subnet, domain, and environment from repository or infrastructure evidence.
3. Implement the smallest change that satisfies the full checklist. Preserve the documented boundaries between facade and backend, shared and isolated infrastructure, environment-specific values, secrets, migrations, and validation.
4. Verify with the checks named in the references plus the repository's existing tests, build, lint, deployment validation, or smoke tests that apply. Never run production-changing commands without the user's explicit authorization.
5. Report each applicable checklist item as satisfied, intentionally not applicable, or blocked. Cite the source and freshness evidence for deviations.

Completion requires every applicable rule and checklist item from every selected source to be accounted for. A hidden contradiction, partial phase, unsupported current-state claim, or unverified deployment is not complete.
