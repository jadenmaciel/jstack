# Microservice Deployment Guide

## Purpose

This document is the standard deployment guide for any backend module in the payment gateway
platform. Follow it in order when deploying a new service for the first time. Each step includes
the reasoning behind every decision so future engineers understand not just *what* to do but *why*.

Throughout this guide, replace `{service}` with the name of the module being deployed (e.g.
`booking`, `invoice`, `payments`).

---

## Architecture

Every module follows the same deployment shape:

```
SDK Caller / Payment Gateway
      │  HTTPS → api.yourdomain.com/api/v1/{service}/{path}
      │  Authorization: Bearer <token signed with MODULE_JWT_SECRET>
      ▼
Route 53  →  API Gateway (HTTP API, single public entry point)
      │
      └── ANY /api/v1/{service}/{proxy+}
              │
              └─ VPC Link → Private ALB → Fargate: {service}-facade
                                                        │
                                                        └─ Private ALB → Fargate: {service}-backend
                                                                                        │
                                                                                        └─ RDS: {service}-db
```

**Per-request flow inside the facade:**
1. Verify inbound `MODULE_JWT_SECRET` token (including `iss` claim)
2. Mint a short-lived internal JWT (`INTERNAL_JWT_SECRET`, 5 min expiry)
3. HMAC-sign the request (`INTERNAL_HMAC_SECRET`) → adds `X-Internal-Signature` + `X-Timestamp`
4. Rewrite path: strip the service prefix (`/api/v1/{service}/...` → `/api/v1/...`)
5. Proxy to the paired backend service

**Backend verifies on every request:**
- `X-Internal-Signature` — proves the request came from the facade
- `Authorization` Bearer token — signed with `INTERNAL_JWT_SECRET`

Neither the backend nor the database is reachable from the internet.

---

## Prerequisites

Before starting, ensure the following exist in the target AWS account and region:

| Prerequisite | Notes |
|---|---|
| AWS CLI installed and configured | `aws configure` with access key, secret, and region |
| Docker Desktop running | Required to build and push images |
| A VPC with public and private subnets | See Phase B1a — can be shared across services |
| An ECS cluster | Can be shared across services |
| An API Gateway HTTP API | Shared across all services — new routes added per service |
| ACM certificate for `api.yourdomain.com` | Shared — created once |
| Route 53 A-record for `api.yourdomain.com` | Shared — created once |
| Have a /health endpoint (Backend and Facade) | This should not require authorization for tasks health checks |

> Steps B1a, B10, and B11 only need to be done once per AWS account/region. Every subsequent
> service reuses the same VPC, API Gateway, and domain. Only add a new route and VPC Link for
> each new service.

---

## Phase A — Docker Preparation

### A1. Add build script to package.json

In both `{service}-backend/package.json` and `{service}-facade/package.json`, add:

```json
"scripts": {
  "build": "tsc",
  ...
}
```

**Why:** Both services use `tsx` to run TypeScript directly in development. Production containers
cannot use `tsx` — it is a dev tool. The Docker build must compile TypeScript to plain JavaScript
via `tsc`, then run the output with `node`.

---

### A2. Create `{service}-backend/Dockerfile`

Use a multi-stage build:

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:22-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app
COPY --from=builder /app/dist        ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma      ./prisma
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

**Critical — build order:** `npx prisma generate` must run **before** `npm run build`. Prisma
generates TypeScript types into `node_modules/.prisma/client`. If `tsc` runs first, those types
don't exist and compilation fails.

**Why multi-stage:** The builder stage installs all deps (including devDependencies like
`typescript`, `vitest`, `prisma` CLI) and compiles. The runner stage starts from a clean image
and only copies compiled output and production node_modules — dev tools never reach production.

**Why copy full `node_modules/` from builder:** The generated Prisma client lives inside
`node_modules/.prisma/client`. Copying the entire `node_modules/` from builder is simpler than
copying the compiled client separately, and avoids running `npm ci` twice.

**Why copy `prisma/`:** The schema file is needed when this image is used as the migration task
(`prisma migrate deploy`) before each deployment.

**Base image — `node:22-alpine`:** Alpine Linux is a minimal ~5MB OS. Smaller image = faster
pulls, less storage cost, smaller attack surface vs. a full Debian/Ubuntu base.

---

### A3. Create `{service}-facade/Dockerfile`

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app
COPY --from=builder /app/dist        ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3001
CMD ["node", "dist/main.js"]
```

**Why simpler than the backend Dockerfile:** The facade has no database. No Prisma, no schema,
no migration task. It only verifies JWTs, mints internal tokens, and proxies requests.

---

### A4. Create `.dockerignore` in both service directories

```
node_modules/
dist/
coverage/
.env
.env.*
!.env.*.example
tests/
**/*.test.ts
*.md
```

**Why:** Without `.dockerignore`, `COPY . .` sends the entire directory to the Docker build
context — including `node_modules/` (hundreds of MB), compiled output, test files, and `.env`
files. This makes builds slow and risks baking secrets into the image.

---

## Phase B — AWS Infrastructure

> Steps B1a, B10, and B11 are done **once per region** and shared across all services.
> Steps B1b through B9 are done **once per service**.

### B1a. Create VPC and Subnets *(once per region)*

Use the AWS Console → VPC → "VPC and more" wizard.

| Setting | Value |
|---|---|
| Name | `{platform}-vpc` (e.g. `module-vpc`) |
| IPv4 CIDR | `10.0.0.0/16` |
| Availability zones | 2 (minimum for ALB and RDS Multi-AZ) |
| Public subnets | 2 (one per AZ — for API Gateway VPC Link ENIs) |
| Private subnets | 2 (one per AZ — for ECS tasks, ALBs, RDS) |
| NAT gateway | 1 in one AZ |
| VPC endpoints | S3 Gateway (free) |

**Why a custom VPC:** The default AWS VPC has all subnets public. All resources must be in a
controlled network where only the API Gateway is internet-reachable.

**Why 2 AZs:** ALBs require 2 AZs. RDS Multi-AZ requires 2 AZs. 2 AZs ensures survival of a
single AZ failure.

**Why a NAT gateway:** ECS Fargate tasks in private subnets need to reach ECR (image pulls) and
Secrets Manager (secret injection) at startup. NAT provides outbound-only internet access.

> **Follow-up optimization:** Replace the NAT gateway with Interface VPC Endpoints for
> `ecr.dkr`, `ecr.api`, `secretsmanager`, `sqs`, and `s3` to eliminate internet egress entirely.
> This is more secure and costs roughly the same (~$28/month for 4 endpoints vs. ~$32/month for
> NAT).

---

### B1a-2. Create RDS DB Subnet Group *(once per region)*

RDS requires a **DB subnet group** — a named collection of subnets it can place instances into.
The default subnet group uses the default VPC's public subnets, which is incorrect. Create a
private one once and reuse it for every RDS instance across all services.

Go to **RDS → Subnet groups → Create DB subnet group**.

| Setting | Value |
|---|---|
| Name | `private-subnets` |
| Description | Private subnets for RDS instances |
| VPC | shared VPC (e.g. `module-vpc`) |
| Availability zones | `us-west-2a`, `us-west-2b` |
| Subnets | Both private subnets (one per AZ) |

Click **Create**.

When provisioning any RDS instance (step B4), select this subnet group under **Connectivity → DB subnet group** instead of `default`.

**Why:** The default subnet group points to the default VPC's public subnets. Placing RDS in
public subnets defeats the private network architecture. This group ensures every database
instance lands in the private subnets where only `sg-{service}-backend-tasks` can reach it.

---

### B1b. Create Security Groups *(once per service)*

Create 5 security groups inside the shared VPC. Name them with the service prefix:
`sg-{service}-facade-alb`, `sg-{service}-facade-tasks`, etc.

**Create all 5 first with no outbound rules, then add outbound rules** — this avoids the
chicken-and-egg problem of referencing a group that doesn't exist yet. AWS also requires deleting
the default "All traffic / `0.0.0.0/0`" outbound rule before adding security group references.

#### `sg-{service}-facade-alb`
| Direction | Protocol | Port | Source / Destination |
|---|---|---|---|
| Inbound | TCP | 3001 | VPC CIDR (e.g. `10.0.0.0/16`) |
| Outbound | TCP | 3001 | `sg-{service}-facade-tasks` |
| Outbound | TCP | 3001 | `sg-{service}-facade-alb` (self) |

> **Why the self-referencing outbound rule:** The API Gateway VPC Link creates ENIs inside the VPC and attaches `sg-{service}-facade-alb` to them. Those ENIs need to reach the facade ALB, which also has `sg-{service}-facade-alb`. Without the self-referencing rule, the VPC Link ENI outbound traffic to the ALB is blocked by the security group.

#### `sg-{service}-facade-tasks`
| Direction | Protocol | Port | Source / Destination |
|---|---|---|---|
| Inbound | TCP | 3001 | `sg-{service}-facade-alb` |
| Outbound | TCP | 80 | `sg-{service}-backend-alb` |
| Outbound | TCP | 443 | `0.0.0.0/0` (ECR + Secrets Manager via NAT) |

#### `sg-{service}-backend-alb`
| Direction | Protocol | Port | Source / Destination |
|---|---|---|---|
| Inbound | TCP | 80 | `sg-{service}-facade-tasks` |
| Outbound | TCP | 3000 | `sg-{service}-backend-tasks` |

#### `sg-{service}-backend-tasks`
| Direction | Protocol | Port | Source / Destination |
|---|---|---|---|
| Inbound | TCP | 3000 | `sg-{service}-backend-alb` |
| Outbound | TCP | 5432 | `sg-{service}-rds` |
| Outbound | TCP | 443 | `0.0.0.0/0` (ECR, Secrets Manager, SQS via NAT) |

#### `sg-{service}-rds`
| Direction | Protocol | Port | Source / Destination |
|---|---|---|---|
| Inbound | TCP | 5432 | `sg-{service}-backend-tasks` |
| Outbound | none | — | — |

**Traffic flow:**
```
API Gateway VPC Link
  └─ sg-{service}-facade-alb    (TCP 3001)
      └─ sg-{service}-facade-tasks   (TCP 3001)
          └─ sg-{service}-backend-alb    (TCP 80)
              └─ sg-{service}-backend-tasks   (TCP 3000)
                  └─ sg-{service}-rds             (TCP 5432)
```

**Why security group references instead of CIDRs:** ECS task IPs change when tasks are replaced
or scaled. Security group references remain correct automatically — no manual IP updates needed.

---

### B2. Create ECR Repositories *(once per service)*

Go to **ECR → Private registry → Repositories → Create repository**.

Create two repositories:

| Repository name | Image |
|---|---|
| `{service}/backend` | The Express API |
| `{service}/facade` | The auth proxy |

**Settings for each:**
- Tag immutability: **Immutable**

**Outside Settings:** If not setup go to Features & Settings and look for the Scanning option. Make sure that "Scan on push all repositories" is activated

**Why namespaced with `{service}/`:** ECR supports slash-separated namespaces. Each service owns
its namespace (`booking/`, `invoice/`, `payments/`). No cross-service naming conflicts and easy
to identify which images belong to which service.

**Why tag immutability:** Once a git-SHA tag is pushed, it cannot be overwritten. The tag in
the ECS task definition always points to exactly the image that was built and tested.

**Note the full URIs after creation:**
```
{account-id}.dkr.ecr.{region}.amazonaws.com/{service}/backend
{account-id}.dkr.ecr.{region}.amazonaws.com/{service}/facade
```

---

### B3. Build and Push Images to ECR *(once per service, then automated via CI/CD)*

**Note:** The region that you need to enter is the region where the VPC and your ECR repos are. For most of the steps on this guide you need to complete them on the same region at all times.

**Windows (PowerShell):**

```powershell
# Configure CLI
aws configure
# Enter region and JSON as output format

# Authenticate (token valid for 12 hours)
aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {account-id}.dkr.ecr.{region}.amazonaws.com

# Backend
cd {service}-backend
docker build -t {service}/backend .
cd ..
docker tag {service}/backend:latest {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/backend:latest
docker push {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/backend:latest

# Facade
cd {service}-facade
docker build -t {service}/facade .
cd ..
docker tag {service}/facade:latest {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/facade:latest
docker push {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/facade:latest
```

**macOS (Terminal):**

Mac hardware (Apple Silicon) builds ARM images by default. ECS Fargate tasks are configured for
`Linux/X86_64`, so you must force the build platform to `linux/amd64` or the container will fail
to start with an `exec format error`.

```bash
# Configure CLI
aws configure
# Enter region and JSON as output format

# Authenticate (token valid for 12 hours)
aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {account-id}.dkr.ecr.{region}.amazonaws.com

# Backend — force linux/amd64 for ECS compatibility
cd {service}-backend
docker build --platform linux/amd64 -t {service}/backend .
cd ..
docker tag {service}/backend:latest {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/backend:latest
docker push {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/backend:latest

# Facade — force linux/amd64 for ECS compatibility
cd {service}-facade
docker build --platform linux/amd64 -t {service}/facade .
cd ..
docker tag {service}/facade:latest {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/facade:latest
docker push {account-id}.dkr.ecr.{region}.amazonaws.com/{service}/facade:latest
```

**Note on `latest` tag:** Used only for the initial manual push to verify the pipeline. In CI/CD
(Phase C) images are tagged with `$GITHUB_SHA` for full traceability to a specific commit.

---

### B4. Provision RDS PostgreSQL *(once per service)*

Go to **RDS → Create database → Standard create**.

| Setting | Value |
|---|---|
| Engine | PostgreSQL 16.x (highest 16.x patch available) |
| Template | Production |
| Deployment | Multi-AZ DB Instance |
| Instance class | db.t4g.micro (upgrade as needed) |
| Storage | gp3, 20 GB, autoscaling to 100 GB |
| DB identifier | `{service}-db` |
| Master username | `{service}_admin` |
| Credentials Management | self managed |
| Compute Resource | Use Default |
| Network Type | IPv4 |
| Initial database name | `{service}` |
| VPC | shared VPC |
| Subnet group | private subnets only |
| Public access | No |
| Security group | `sg-{service}-rds` |
| Authentication | Password |
| Backups | Enabled, 7 day retention |
| Encryption | Enabled |
| Monitoring | Standard (Database Insights) |
| Enhance Monitoring | Active |
| Log Exports | PostgreSQL Logs |
| Encryption | Enabled |

**Note:** Remember the password that you entered. For the backup and maintainance config options just leave them as the default ones.

**Why PostgreSQL 16:** Latest stable major version with full Prisma support. Avoid 17/18 until
Prisma explicitly documents compatibility.

**Why Multi-AZ:** Automatic failover to a standby replica in ~60 seconds if the primary AZ
fails. No data loss, minimal downtime.

**Why private subnets with no public access:** The database is only reachable from
`sg-{service}-backend-tasks`. It has no internet-reachable endpoint.

**After creation, note the endpoint and construct the DATABASE_URL:**
```
postgresql://{service}_admin:<password>@{rds-endpoint}:5432/{service}
```

---

### B5. Store Secrets in Secrets Manager *(once per service)*

Go to **Secrets Manager → Store a new secret → Other type of secret**.

Create one secret per service named `{service}/production`. Store all values as key/value pairs
in a single secret:

| Key | Value |
|---|---|
| `DATABASE_URL` | `postgresql://{service}_admin:<password>@{rds-endpoint}:5432/{service}` |
| `MODULE_JWT_SECRET` | Strong random string (shared with SDK callers) |
| `INTERNAL_JWT_SECRET` | Strong random string (facade → backend only) |
| `INTERNAL_HMAC_SECRET` | Strong random string (facade → backend only) |
| `JWT_SECRET` | Strong random string (any other use tokens, backend only) |
| `{SERVICE}_BACKEND_URL` | Get this after creating the ALB on step B7 |

**Note:** After adding the secrets and setting the name just skip all the other parts until the end

**Why Secrets Manager instead of environment variables in the task definition:**
- Secrets are never stored in plaintext in any config file or git history
- ECS injects them at container startup — the running process sees them as env vars
- Rotation can be automated without redeploying the service
- Access is audited via CloudTrail

---

### B6. Create ECS Cluster *(once per region, shared)*

Go to **ECS → Clusters → Create cluster**.

| Setting | Value |
|---|---|
| Cluster name | `{platform}-cluster` (e.g. `module-cluster`) |
| Infrastructure | AWS Fargate (serverless) |

One cluster hosts all services. Each service gets its own ECS services and task definitions
within the shared cluster.

---

### B6a. Create IAM Task Role *(once per service)*

ECS needs an IAM role attached to the task definition so the running container can read its
secrets from Secrets Manager at startup. Create one role **per service**, scoped only to that
service's secret.

Go to **IAM → Roles → Create role**.

| Setting | Value |
|---|---|
| Trusted entity type | AWS service |
| Use case | Elastic Container Service → **Elastic Container Service Task** |
| Role name | `{service}-ecs-task-role` |

Do **not** attach any managed policies. Instead, add an **inline policy** after the role is
created (Roles → `{service}-ecs-task-role` → Add permissions → Create inline policy → JSON):

**Note:** Create both policies separately. Name the first one "{service}-secrets-policy", and the second one "{service}-logs-create-policy"

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-*"
    }
  ]
}

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "arn:aws:logs:{region}:{account-id}:log-group:/ecs/*"
    }
  ]
}

```

Replace `{region}` (e.g. `us-west-2`), `{account-id}` (e.g. `698623007242`), and `{service}`
(e.g. `booking`, `invoice`) with the correct values for this deployment.

You would go to add permissions again and add the AmazonECSTaskExecutionRolePolicy to the role.

**Why the `-*` suffix on the ARN:** Secrets Manager appends a random 6-character suffix to every
secret ARN (e.g. `booking/production-aBcDeF`). The wildcard is required or the permission will
not match.

**Why one role per service:** Each role's `Resource` is scoped to only `{service}/production-*`.
A booking task role cannot read invoice secrets and vice versa — least privilege by design. Do
**not** reuse the booking service's role for a second service; create a new one with the correct
`{service}` substituted in the ARN.

---

### B6b. Create Task Definitions *(once per service — two task defs: backend + facade)*

Use the **JSON** tab in the ECS console (or register via CLI) to paste these templates directly.
Replace all `{placeholders}` before submitting.

**How to find `{secret-suffix}`:** Go to Secrets Manager → `{service}/production` → copy the
last 6 characters of the ARN (e.g. `aBcDeF` from `…:secret:booking/production-aBcDeF`).

**Backend task definition — `{service}-backend-task`:**

```json
{
  "family": "{service}-backend-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::{account-id}:role/{service}-ecs-task-role",
  "taskRoleArn": "arn:aws:iam::{account-id}:role/{service}-ecs-task-role",
  "containerDefinitions": [
    {
      "name": "{service}-backend",
      "image": "{account-id}.dkr.ecr.{region}.amazonaws.com/{service}/backend:latest",
      "portMappings": [{ "containerPort": 3000, "protocol": "tcp" }],
      "essential": true,
      "secrets": [
        { "name": "DATABASE_URL",         "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:DATABASE_URL::" },
        { "name": "INTERNAL_JWT_SECRET",  "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:INTERNAL_JWT_SECRET::" },
        { "name": "INTERNAL_HMAC_SECRET", "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:INTERNAL_HMAC_SECRET::" },
        { "name": "JWT_SECRET",           "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:JWT_SECRET::" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/{service}-backend",
          "awslogs-region": "{region}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      }
    }
  ]
}
```

**Facade task definition — `{service}-facade-task`:**

```json
{
  "family": "{service}-facade-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::{account-id}:role/{service}-ecs-task-role",
  "taskRoleArn": "arn:aws:iam::{account-id}:role/{service}-ecs-task-role",
  "containerDefinitions": [
    {
      "name": "{service}-facade",
      "image": "{account-id}.dkr.ecr.{region}.amazonaws.com/{service}/facade:latest",
      "portMappings": [{ "containerPort": 3001, "protocol": "tcp" }],
      "essential": true,
      "secrets": [
        { "name": "MODULE_JWT_SECRET",      "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:MODULE_JWT_SECRET::" },
        { "name": "INTERNAL_JWT_SECRET",    "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:INTERNAL_JWT_SECRET::" },
        { "name": "INTERNAL_HMAC_SECRET",   "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:INTERNAL_HMAC_SECRET::" },
        { "name": "{SERVICE}_BACKEND_URL",  "valueFrom": "arn:aws:secretsmanager:{region}:{account-id}:secret:{service}/production-{secret-suffix}:{SERVICE}_BACKEND_URL::" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/{service}-facade",
          "awslogs-region": "{region}",
          "awslogs-stream-prefix": "ecs",
          "awslogs-create-group": "true"
        }
      }
    }
  ]
}
```

> **`executionRoleArn` vs `taskRoleArn`:**
> - `executionRoleArn` → `ecsTaskExecutionRole` — AWS-managed role used by the ECS **agent** to
>   pull images from ECR and push logs to CloudWatch. Shared across all services.
> - `taskRoleArn` → `{service}-ecs-task-role` — the per-service role created in B6a that grants
>   the running **container process** permission to call `secretsmanager:GetSecretValue`. Never
>   set both to the same role; they serve different purposes.

**Pre-create CloudWatch log groups** before starting any ECS service.

The `AmazonECSTaskExecutionRolePolicy` managed policy grants `logs:CreateLogStream` and
`logs:PutLogEvents` but **not** `logs:CreateLogGroup`. The task definitions above include
`"awslogs-create-group": "true"` as a fallback, but pre-creating the groups lets you set
retention and avoids any race condition on first startup.

Go to **CloudWatch → Log Management → Log groups → Create log group** and create:

| Log group name | Retention |
|---|---|
| `/ecs/{service}-backend` | 30 days |
| `/ecs/{service}-facade` | 30 days |

**Note:** Log class choose the standard and no delete protection

---

### B7. Create Two Private ALBs *(once per service)*

Go to **EC2 → Load Balancers → Create load balancer → Application Load Balancer**.

Create two ALBs: one for the facade, one for the backend.

**Facade ALB:**

| Setting | Value |
|---|---|
| Name | `{service}-facade-alb` |
| Scheme | **Internal** (private — not internet-facing) |
| IP address type | IPv4 |
| VPC | shared VPC |
| Subnets | Both **private** subnets |
| Security group | `sg-{service}-facade-alb` |
| Listener | HTTP : **3001** |

**Backend ALB:**

| Setting | Value |
|---|---|
| Name | `{service}-backend-alb` |
| Scheme | **Internal** (private — not internet-facing) |
| IP address type | IPv4 |
| VPC | shared VPC |
| Subnets | Both **private** subnets |
| Security group | `sg-{service}-backend-alb` |
| Listener | HTTP : **80** |

**Why different ports:** `sg-{service}-facade-alb` allows inbound TCP 3001 (matching the facade container port and the API Gateway VPC Link connection). `sg-{service}-backend-alb` allows inbound TCP 80 from the facade tasks, so the backend ALB listener uses port 80.

**Note:** On the forward to target group there should be an option to create a target group, select the link and continue with the target group creation. After both of the ALB are created copy the ALB DNS name from the {service}-backend-alb and update your {SERVICE}_BACKEND_URL secret to be the DNS name, something like http://{ALB DNS Name}.

**Target group for each ALB:**

For the target group name enter {service}-backend-tg or {service}-facade-tg depending on which one are you doing first.

| Setting | Value |
|---|---|
| Target type | IP (required for Fargate) |
| Protocol | HTTP |
| Port | 3001 (facade) / 3000 (backend) |
| Health check path | `/health` |
| Health check success codes | `200` |
| VPC | shared VPC |

**Note:** Skip registering target for the terget groups since we are going to assign them manually to the alb.

**Why internal ALBs:** Neither the facade ALB nor the backend ALB should be internet-facing.
The facade ALB is only reachable from the API Gateway VPC Link. The backend ALB is only
reachable from the facade tasks.

---

### B8. Create ECS Fargate Services *(once per service — two services: backend + facade)*

Go to **ECS → Clusters → {platform}-cluster → Create service**.

Create two services: `{service}-backend` and `{service}-facade`.

| Setting | Value |
|---|---|
| Task definition | `{service}-backend-task` / `{service}-facade-task` |
| Service name | `{service}-backend` / `{service}-facade` |
| Desired tasks | 1 (scale up after validation) |
| VPC | shared VPC |
| Subnets | Both **private** subnets |
| Security group | `sg-{service}-backend-tasks` / `sg-{service}-facade-tasks` |
| Public IP | Disabled |
| Load balancer | `{service}-backend-alb` / `{service}-facade-alb` |
| Listener | The listener from B7 |
| Target group | the target group created in B7 |
| Compute Options | Launch Type |
| Launch Type | Fargate |
| Platform Version | Latest |
| Application Type | Service |
| Revision | Latest |
| Availability Zone | On |
| Health Check Grace Period | 60s |
| Deployment Strategy | Rolling Update |

---

### B9. Run Prisma Migrations *(before each deployment that includes schema changes)*

Run `prisma migrate deploy` as a one-off ECS task using the backend image. This applies any
pending migrations to the production RDS instance before the new container version starts serving
traffic.

In **ECS → Clusters → {platform}-cluster → Run task:**

| Setting | Value |
|---|---|
| Compute Options | Launch Type |
| Launch type | Fargate |
| Task definition | `{service}-backend-task` |
| VPC | shared VPC |
| Subnets | private subnets |
| Security group | `sg-{service}-backend-tasks` |
| Public IP | Disabled |
| Override command | `npx, prisma, migrate, deploy` |

**Note:** Expand Container Overrides for the override command section.

The task will connect to RDS using the `DATABASE_URL` from Secrets Manager, apply all pending
migrations, and exit. Only then should the ECS service be updated to the new image.

**Why a one-off task instead of running migrations at container startup:**
Running migrations at startup in every container replica causes race conditions — multiple
replicas can attempt to migrate simultaneously. A one-off task runs once, applies migrations
atomically (Prisma uses advisory locks), and exits cleanly before traffic is shifted.

---

### B10. Create API Gateway HTTP API + VPC Link *(once per service — API Gateway itself is shared)*

#### Step 1 — Create the VPC Link

Go to **API Gateway → VPC Links → Create**.

| Setting | Value |
|---|---|
| VPC Link version | **VPC Link for HTTP APIs** (v2) |
| Name | `{service}-facade-vpclink` |
| VPC | shared VPC |
| Subnets | Both **private** subnets |
| Security group | `sg-{service}-facade-alb` |

Wait until status shows **Available** (~2 minutes) before proceeding.

#### Step 2 — Create the HTTP API (Once Per Region)

**Note:** Only complete this step once per region.

Go to **API Gateway → APIs → Create API → HTTP API → Build**.

- Skip adding integrations in the wizard — the wizard form does not expose the VPC Link option
- Set API name to `{platform}-api` (e.g. `module-api`)
- Leave routes empty
- Keep `$default` stage with auto-deploy **on**
- Hit **Create**

#### Step 3 — Create the integration

Go to **API Gateway → {platform}-api → Integrations → Create**.

| Setting | Value |
|---|---|
| Integration type | **Private** (VPC Link) |
| Selection method | **Select manually** |
| Target service | **ALB/NLB** |
| Load balancer | `{service}-facade-alb` |
| Listener | HTTP :{facade-port} (the listener that exists on the ALB) |
| Invoke method | **ANY** |

Hit **Create**.

#### Step 4 — Create routes

Go to **API Gateway → {platform}-api → Routes → Create**. Add two routes and attach the integration to each:

| Method | Path | Why |
|---|---|---|
| ANY | `/api/v1/{service}` | Base path with no trailing segment |
| ANY | `/api/v1/{service}/{proxy+}` | All sub-paths |

> **`{proxy+}` requires at least one segment.** Without the bare route, `GET /api/v1/{service}` returns 404 from API Gateway itself.

#### Step 5 — Verify

The invoke URL is shown under **$default stage**. Test:

```powershell
curl https://{api-id}.execute-api.{region}.amazonaws.com/api/v1/{service}/test
```

Expected response: **401 Unauthorized** — traffic reached the facade, which correctly rejected the unauthenticated request.

**Why API Gateway instead of a second internet-facing ALB:**
API Gateway provides TLS termination, path-based routing across all services, throttling, and
access logging — all from a single public endpoint. Adding a new service is a new VPC Link,
two routes, and one integration — no DNS changes, no certificate changes.

---

### B11. ACM Certificate + Route 53 *(once per region — shared)*

**ACM Certificate:**
1. Go to **Certificate Manager → Request certificate → Public certificate**
2. Domain: `api.yourdomain.com` (add `*.yourdomain.com` to cover subdomains)
3. Validation: DNS validation → add the CNAME record to Route 53
4. Wait for status to become `Issued`

**API Gateway custom domain:**
1. Go to **API Gateway → Custom domain names → Create**
2. Domain: `api.yourdomain.com`
3. Certificate: the ACM cert created above
4. Map to the HTTP API with base path `/`

**Route 53:**
1. Go to **Route 53 → Hosted zones → yourdomain.com → Create record**
2. Record name: `api`
3. Type: A
4. Toggle **Alias** on
5. **Route traffic to**: `Alias to API Gateway API`
6. **Region**: `us-west-2` *(ACM certs for API Gateway must be in us-west-2 if using edge-optimized; for regional endpoints select the region where you created the custom domain, e.g. `us-west-2`)*
7. **Endpoint**: select the custom domain name you just created (e.g. `api.yourdomain.com` / the `d-xxxxxxxxxx.execute-api.us-west-2.amazonaws.com` hostname shown in the custom domain details)
8. Click **Create records**

---

## Postman Testing

For Postman API testing we need to setup the authoriation to make sure that all calls are authorized. That way we do not need to setup the authoriation on every single call but on only one place, and for the public routes we can just change the auth config for that route to pass no authorization.

**Collection Setup**

Create a new collection specifically for the service that you want to test. Inside the collection go to the authorization tab and select JWT Bearer for the Auth Type. Then you need to fill up the information like the following:

| Setting | Value |
|---|---|
| Add JWT token to | Request Header |
| Algorithm | HS256 |
| Secret | `MODULE_JWT_SECRET` |

When you enter the secret a warning sign is going to pop-up sensitive value with an option to set as variable, click that.

Then the local vault is going to open. Check save the key to native password manager and download the vault key, save the key .txt file in a safe place. After all that is complete click the open vault button.

When you are in just save the `MODULE_JWT_SECRET` and make sure you allow the domain that you want to test (Should be the domain that is linked to the API Gateway for the modules).

Now, go back and use your vault variable that yiou just saved for the secret field.

This is the payload that you need to enter:

```json
{
  "iss": "{service}-sdk",
  "merchant_id": "{Test Merchant ID}",
  "permission": "merchant",
  "iat": 1748000000,
  "exp": 9999999999
}
```

> For staff endpoints also add "user_id": {Test User ID} and set "permission": "staff".


## Secrets Reference

| Secret key | Used by | Purpose |
|---|---|---|
| `DATABASE_URL` | Backend | RDS PostgreSQL connection string |
| `MODULE_JWT_SECRET` | Facade | Verifies inbound tokens from SDK callers |
| `INTERNAL_JWT_SECRET` | Facade + Backend | Facade mints it; backend verifies it |
| `INTERNAL_HMAC_SECRET` | Facade + Backend | HMAC signature on forwarded requests |
| `JWT_SECRET` | Backend only | Manage-link token signing (cancel/reschedule) |
| `{SERVICE}_BACKEND_URL` | Facade | Internal ALB URL of the paired backend service |

All secrets are stored in AWS Secrets Manager under `{service}/production` and injected into
ECS task containers at startup. They must never be committed to the repository.

---

## Validation Checklist

After completing all steps, verify:

- [ ] Backend health check returns 200 through its private ALB
- [ ] Facade can reach the backend and auth works end to end
- [ ] `POST /api/v1/{service}/...` through API Gateway returns expected response
- [ ] RDS is unreachable from the internet (no public endpoint)
- [ ] Secrets inject cleanly and the app starts without errors (check ECS task logs)
- [ ] `prisma migrate deploy` ran successfully before traffic was shifted
- [ ] ECR image tag matches the deployed task definition revision

---

## Adding a New Service Checklist

When deploying a new module, these steps are **skipped** (already done):
- [ ] ~~B1a — VPC and subnets~~
- [ ] ~~B6 — ECS cluster~~
- [ ] ~~B10 — API Gateway HTTP API~~
- [ ] ~~B11 — ACM certificate + Route 53~~

These steps must be done **for every new service:**
- [ ] A1 — Add build script to package.json (both backend and facade)
- [ ] A2 — Create `{service}-backend/Dockerfile`
- [ ] A3 — Create `{service}-facade/Dockerfile`
- [ ] A4 — Create `.dockerignore` files
- [ ] B1b — Create 5 security groups
- [ ] B2 — Create ECR repositories (`{service}/backend`, `{service}/facade`)
- [ ] B3 — Build and push initial images
- [ ] B4 — Provision RDS PostgreSQL instance
- [ ] B5 — Store secrets in Secrets Manager under `{service}/production`
- [ ] B6b — Create task definitions (backend + facade)
- [ ] B7 — Create two private ALBs
- [ ] B8 — Create two ECS Fargate services
- [ ] B9 — Run `prisma migrate deploy`
- [ ] B10 — Add route + VPC Link to the shared API Gateway
- [ ] C1/C2 — Add CI/CD workflow for the new service repository
