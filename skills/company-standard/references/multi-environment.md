# Multi-Environment Guide (Develop / Staging / Production)

## Purpose

This guide explains how to extend the platform to support multiple environments (develop, staging,
production) so that each environment of the payment gateway connects to the matching environment of
every module service. Follow it after a service has already been deployed to production using
`microservice-deployment-guide.md`.

Throughout this guide, replace `{service}` with the module name (e.g. `booking`, `invoice`) and
`{env}` with the environment name (`develop` or `staging`).

---

## Why Three Environments

The payment gateway runs separate develop, staging, and production environments — each with its own
database, credentials, and SQS queues. If your module only has a production environment, any test
or development work in the payment gateway automatically hits your production database and
production secrets. Three environments guarantee:

- Payment gateway develop → module develop (isolated test data, dev gateway credentials)
- Payment gateway staging → module staging (pre-release validation, staging credentials)
- Payment gateway production → module production (live data, production credentials)

The environment pairing is enforced automatically by `MODULE_JWT_SECRET`: each environment's facade
is loaded with that environment's secret, so a token minted by the dev gateway can only be verified
by the dev facade. There is no code flag or header to set — the credentials determine the
environment.

---

## Architecture

```
dev.modules.troute.io          staging.modules.troute.io          modules.troute.io
        │                               │                                │
        ▼                               ▼                                ▼
 API Gateway                    API Gateway                      API Gateway
 module-api-develop             module-api-staging               module-api (existing)
        │                               │                                │
        ├─ /api/v1/booking/{proxy+}     ├─ /api/v1/booking/{proxy+}     ├─ /api/v1/booking/{proxy+}
        │     └─ VPC Link               │     └─ VPC Link                │     └─ VPC Link
        │         └─ booking-facade-dev │         └─ booking-facade-stg  │         └─ booking-facade
        │                               │                                │
        ├─ /api/v1/invoice/{proxy+}     ├─ /api/v1/invoice/{proxy+}     ├─ /api/v1/invoice/{proxy+}
        │     └─ VPC Link               │     └─ VPC Link                │     └─ VPC Link
        │         └─ invoice-facade-dev │         └─ invoice-facade-stg  │         └─ invoice-facade
        │                               │
        └─ (each new service             └─ (same pattern)
            adds a new route
            to the existing API)
```

**Key insight:** There is one API Gateway per environment, shared across all module services. Each
new service adds new routes (and a new VPC Link + ALBs + ECS services) to the existing per-environment
API Gateway. The subdomain does not change when a new service is added.

---

## What Is Shared vs. Per-Environment vs. Per-Service

| Resource | Scope | Notes |
|---|---|---|
| VPC, subnets, NAT | Once per AWS region | Shared by everything |
| ECS cluster | Once per region | All services and environments run in `module-cluster` |
| ECR repositories | Once per service | Images are env-agnostic; tagged by git SHA |
| API Gateway HTTP API | Once per environment | `module-api`, `module-api-staging`, `module-api-develop` |
| ACM certificate | Once per region | Wildcard `*.modules.troute.io` covers all subdomains |
| Route 53 subdomain | Once per environment | `dev.modules.troute.io`, `staging.modules.troute.io` |
| VPC Link | Per service per environment | Routes the API Gateway to that service's facade ALB |
| Security groups (×5) | Per service per environment | Isolate traffic within each env/service pair |
| RDS database | Per service per environment | Each env has its own isolated data |
| Secrets Manager secret | Per service per environment | `{service}/{env}` — holds env-specific credentials |
| IAM task role | Per service per environment | Scoped to read only `{service}/{env}-*` |
| ECS task definitions (×2) | Per service per environment | Backend + facade, point to env-specific secrets |
| Private ALBs (×2) | Per service per environment | Facade ALB + backend ALB |
| ECS services (×2) | Per service per environment | Backend + facade |
| CloudWatch log groups (×2) | Per service per environment | |
| GitHub Actions environment | Per environment | Holds ECS resource names as variables |

---

## Initial Setup — Once Per New Environment

These steps create the shared infrastructure for an environment. Do them once before deploying any
service into that environment.

### 1. ACM Certificate Update

Your existing production cert covers `modules.troute.io`. You need it to also cover the new
subdomains. Request a new certificate in **Certificate Manager → Request certificate → Public**:

- `modules.troute.io`
- `dev.modules.troute.io`
- `staging.modules.troute.io`

Or request a single wildcard `*.modules.troute.io` that automatically covers all future subdomains.
Add the DNS validation CNAME records to Route 53 and wait for status `Issued`.

**Why update instead of reuse:** ACM certificates are tied to exact domain names. A cert for
`modules.troute.io` does not cover `dev.modules.troute.io`.

### 2. API Gateway HTTP API

Create a new HTTP API for the environment — do **not** add routes to the production API. The same
path `/api/v1/{service}/...` is used in all environments, so they cannot share one API without
conflicting route integrations.

Go to **API Gateway → APIs → Create API → HTTP API → Build**:

| Setting | Value |
|---|---|
| API name | `module-api-{env}` |
| Integrations | Skip — add after |
| Stage | `$default` with auto-deploy on |

### 3. Custom Domain + Route 53

**API Gateway → Custom domain names → Create:**

| Setting | Value |
|---|---|
| Domain name | `{env}.modules.troute.io` |
| Certificate | Updated cert from step 1 |
| API mapping | `module-api-{env}`, stage `$default`, base path `/` |

**Route 53 → `troute.io` hosted zone → Create record:**

| Setting | Value |
|---|---|
| Record name | `{env}.modules` (e.g. `dev.modules` or `staging.modules`) |
| Type | A, Alias on |
| Route traffic to | Alias to API Gateway API, `us-west-2` |
| Endpoint | The custom domain just created |

**Why `{env}.modules` and not just `{env}`:** The existing `modules` record lives in the `troute.io`
hosted zone. Record names in Route 53 are relative to the zone, so `dev.modules` resolves as
`dev.modules.troute.io` — no separate hosted zone needed.

### 4. GitHub Actions Environment

Go to your repo → **Settings → Environments → New environment** → name it `develop` or `staging`.

No variables yet — these are added per service in the per-service steps below.

---

## Per-Service Setup — Repeat for Each Service in Each Environment

These steps deploy one service (e.g. booking) into one environment (e.g. develop). Repeat the full
block for every service/environment combination.

### Step 1 — Security Groups (ref: B1b)

Create 5 security groups in the shared VPC using the same rules from `microservice-deployment-guide.md`
B1b. Name them with the service and environment:

- `sg-{service}-facade-alb-{env}`
- `sg-{service}-facade-tasks-{env}`
- `sg-{service}-backend-alb-{env}`
- `sg-{service}-backend-tasks-{env}`
- `sg-{service}-rds-{env}`

Inbound/outbound rules are identical to production — just reference these new SGs instead.

### Step 2 — RDS PostgreSQL (ref: B4)

Create a new database instance following B4 exactly:

| Setting | Value |
|---|---|
| DB identifier | `{service}-db-{env}` |
| Master username | `{service}_admin` |
| Initial database name | `{service}` |
| Subnet group | `private-subnets` |
| Security group | `sg-{service}-rds-{env}` |
| Public access | No |

Note the endpoint and build the connection string:
```
postgresql://{service}_admin:<password>@{rds-endpoint}:5432/{service}
```

### Step 3 — Secrets Manager (ref: B5)

Create a secret named `{service}/{env}` with these key/value pairs:

| Key | Value |
|---|---|
| `DATABASE_URL` | Connection string from step 2 |
| `MODULE_JWT_SECRET` | Dev/staging secret from the payment gateway team for this environment |
| `INTERNAL_JWT_SECRET` | Any strong random string |
| `INTERNAL_HMAC_SECRET` | Any strong random string |
| `JWT_SECRET` | Any strong random string |
| `{SERVICE}_BACKEND_URL` | Fill in after step 5 (backend ALB DNS name) |

Note the 6-character suffix from the secret ARN — needed for task definitions in step 5.

**Why `MODULE_JWT_SECRET` must match the payment gateway environment:** The facade verifies every
inbound token against this secret. A token minted by the dev gateway will fail verification on
staging or production because the secrets differ — this is what enforces environment isolation.

### Step 4 — IAM Task Role (ref: B6a)

Create a role named `{service}-ecs-task-role-{env}` following B6a. The inline secrets policy
must reference only this environment's secret:

```json
{
  "Effect": "Allow",
  "Action": "secretsmanager:GetSecretValue",
  "Resource": "arn:aws:secretsmanager:us-west-2:698623007242:secret:{service}/{env}-*"
}
```

Add the logs policy and `AmazonECSTaskExecutionRolePolicy` managed policy as described in B6a.

**Why a separate role per environment:** Each role's `Resource` is scoped to only its own
environment's secrets. A dev task role cannot read staging or production secrets — least privilege
by design.

### Step 5 — CloudWatch Log Groups + Task Definitions (ref: B6b)

**Create log groups first** (30 days retention, standard class):
- `/ecs/{service}-backend-{env}`
- `/ecs/{service}-facade-{env}`

**Create task definitions** using the JSON templates from B6b with these substitutions:

| Field | Change to |
|---|---|
| `"family"` | `{service}-backend-task-{env}` / `{service}-facade-task-{env}` |
| Container `"name"` | Keep as `{service}-backend` / `{service}-facade` (unchanged) |
| All secret ARNs | Point to `{service}/{env}-{new-secret-suffix}` |
| `executionRoleArn` / `taskRoleArn` | `{service}-ecs-task-role-{env}` |
| `awslogs-group` | `/ecs/{service}-backend-{env}` / `/ecs/{service}-facade-{env}` |
| Image | Use `:latest` for first deploy; CI/CD takes over after |

### Step 6 — Private ALBs + Target Groups (ref: B7)

Create two internal ALBs in private subnets:

| ALB | Security group | Target group port |
|---|---|---|
| `{service}-facade-alb-{env}` | `sg-{service}-facade-alb-{env}` | 3001 |
| `{service}-backend-alb-{env}` | `sg-{service}-backend-alb-{env}` | 3000 |

After both ALBs are created, copy the **backend ALB DNS name** and update `{SERVICE}_BACKEND_URL`
in the `{service}/{env}` secret (prefix with `http://`).

### Step 7 — ECS Fargate Services (ref: B8)

Create two services in `module-cluster`:

| Service name | Task definition | Security group | ALB |
|---|---|---|---|
| `{service}-backend-{env}` | `{service}-backend-task-{env}` | `sg-{service}-backend-tasks-{env}` | `{service}-backend-alb-{env}` |
| `{service}-facade-{env}` | `{service}-facade-task-{env}` | `sg-{service}-facade-tasks-{env}` | `{service}-facade-alb-{env}` |

All other settings (desired tasks, private subnets, health check grace period, deployment strategy)
are the same as production.

### Step 8 — Run Prisma Migrations (ref: B9)

Run a one-off ECS task in `module-cluster` using `{service}-backend-task-{env}`, private subnets,
`sg-{service}-backend-tasks-{env}`, no public IP, with command override:

```
npx, prisma, migrate, deploy
```

### Step 9 — VPC Link + Routes in the Environment API Gateway (ref: B10)

**Create VPC Link (B10 step 1):**

| Setting | Value |
|---|---|
| Name | `{service}-facade-vpclink-{env}` |
| Subnets | Both private subnets |
| Security group | `sg-{service}-facade-alb-{env}` |

Wait for status **Available**.

**Create integration in `module-api-{env}` (B10 step 3):**

- Integration type: Private (VPC Link)
- VPC Link: `{service}-facade-vpclink-{env}`
- Load balancer: `{service}-facade-alb-{env}`
- Invoke method: ANY

**Create routes in `module-api-{env}` (B10 step 4):**

| Method | Path |
|---|---|
| ANY | `/api/v1/{service}` |
| ANY | `/api/v1/{service}/{proxy+}` |

Attach the integration to both routes.

**Verify:** Hit `https://{env}.modules.troute.io/api/v1/{service}/health` — expect `200 OK`.

### Step 10 — GitHub Actions Environment Variables

In your repo → **Settings → Environments → `{env}`**, add these variables for the service:

| Variable | Value |
|---|---|
| `ECS_CLUSTER` | `module-cluster` |
| `BACKEND_SERVICE` | `{service}-backend-{env}` |
| `FACADE_SERVICE` | `{service}-facade-{env}` |
| `BACKEND_TASK_DEF` | `{service}-backend-task-{env}` |
| `FACADE_TASK_DEF` | `{service}-facade-task-{env}` |
| `BACKEND_CONTAINER` | `{service}-backend` |
| `FACADE_CONTAINER` | `{service}-facade` |

`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` stay as repo-level secrets (shared across all
environments if using the same AWS account).

---

## Adding a Second Service to an Existing Environment

Once the initial environment infrastructure exists (API Gateway, subdomain, custom domain, Route 53),
adding a new service to that environment skips steps 2 and 3 of the initial setup and goes straight
to the per-service steps. The only addition is creating the VPC Link and routes in the **already
existing** `module-api-{env}` API Gateway (step 9).

**What to skip when the environment already exists:**
- ACM certificate update (already covers the subdomain)
- Creating the API Gateway HTTP API (already exists as `module-api-{env}`)
- Custom domain and Route 53 record (already exist)
- GitHub Actions environment (already exists — just add new variables for the new service)

**What to do for each new service (steps 1–10 above apply in full), with one note on step 9:**
Instead of creating a new API Gateway, you open the existing `module-api-{env}` and add a new
VPC Link + integration + two routes for the new service's path prefix. The subdomain
`{env}.modules.troute.io` handles all services in that environment automatically.

---

## CD Workflow

The `.github/workflows/cd.yml` in this repo is already configured for three environments. It
triggers on push to `develop`, `staging`, and `main`, and maps each branch to the corresponding
GitHub Actions environment:

```
develop branch  →  GitHub environment "develop"  →  vars.BACKEND_SERVICE, etc.
staging branch  →  GitHub environment "staging"  →  vars.BACKEND_SERVICE, etc.
main branch     →  GitHub environment "production" →  vars.BACKEND_SERVICE, etc.
```

Each module repository must follow the same CD pattern. The GitHub Actions environment variables
(`ECS_CLUSTER`, `BACKEND_SERVICE`, `FACADE_SERVICE`, `BACKEND_TASK_DEF`, `FACADE_TASK_DEF`,
`BACKEND_CONTAINER`, `FACADE_CONTAINER`) are the only per-environment configuration needed in the
workflow — the rest is driven by Secrets Manager at container startup.

---

## Checklist — New Environment (first service)

- [ ] ACM certificate updated to include `{env}.modules.troute.io`
- [ ] API Gateway HTTP API `module-api-{env}` created
- [ ] Custom domain `{env}.modules.troute.io` created in API Gateway
- [ ] Route 53 A-record alias for `{env}.modules.troute.io` created
- [ ] GitHub Actions environment `{env}` created in repo settings
- [ ] Per-service steps 1–10 completed for first service

## Checklist — New Service in Existing Environment

- [ ] Step 1 — 5 security groups created
- [ ] Step 2 — RDS instance `{service}-db-{env}` created
- [ ] Step 3 — Secret `{service}/{env}` created in Secrets Manager
- [ ] Step 4 — IAM task role `{service}-ecs-task-role-{env}` created
- [ ] Step 5 — Log groups and task definitions created
- [ ] Step 6 — Backend ALB DNS name saved to `{SERVICE}_BACKEND_URL` secret
- [ ] Step 7 — Two ECS Fargate services running and healthy
- [ ] Step 8 — `prisma migrate deploy` ran successfully
- [ ] Step 9 — VPC Link + routes added to `module-api-{env}`
- [ ] Step 10 — GitHub Actions environment variables set for service
- [ ] Health check `{env}.modules.troute.io/api/v1/{service}/health` returns 200
