# Backend Design Document

This document defines the architecture for an Express + Zod + TypeScript backend. It is intended as a reference for AI agents generating or converting backend code. Follow the patterns, file structure, and conventions described here exactly.

---

## 1. Conventions

- **Language**: TypeScript with ESM modules (`"type": "module"` in `package.json`)
- **Server framework**: Express 5
- **Validation**: Zod 4
- **Database**: PostgreSQL (Prisma ORM)
- **Auth**: JWT (Bearer tokens via `jsonwebtoken`)
- **Password hashing**: bcrypt
- **Import extensions**: Always use `.js` extensions in import paths (TypeScript ESM requirement)
- **Strict objects**: Use `z.strictObject()` for request bodies to reject unknown fields
- **No default exports** for utilities — use named exports. Routers use default exports.

### Core Dependencies

```json
{
  "@prisma/client": "^6.19.3",
  "express": "^5.2.1",
  "zod": "^4.4.1",
  "jsonwebtoken": "^9.0.3",
  "bcrypt": "^6.0.0",
  "dotenv": "^17.4.2",
  "tsx": "^4.21.0",
  "typescript": "^6.0.3"
}
```

```json
{
  "prisma": "^6.19.3",
  "@types/express": "^5.0.6",
  "@types/jsonwebtoken": "^9.0.10",
  "@types/bcrypt": "^6.0.0",
  "@types/node": "^25.6.0"
}
```

---

## 2. File Structure

```
src/server/
├── app.ts                       # Express app setup: middleware, router mounting, global error handler
├── main.ts                      # Entry point: starts the HTTP server and background jobs
├── types.d.ts                   # Global type augmentations (e.g. req.user)
├── prisma/
│   └── schema.prisma            # Single source of truth for all database models and relations
├── utils/
│   ├── auth.ts                  # attachUser, dispatchByUserType, chainMiddleware
│   ├── jwt.ts                   # JWT sign/verify wrappers
│   ├── prisma.ts                # Singleton PrismaClient instance
│   └── validation.ts            # validate() middleware, common Zod helpers
└── resources/
    └── <resource>/              # Domain-specific resource (see §8 for pattern)
        ├── router.ts            # Resource Routes
        ├── controller.ts        # Resource Request Handlers
        ├── validation.ts        # Zod Schemas + validate()
        └── types.d.ts           # Inferred TypeScript types from Zod schemas
```

### File Roles

| File | Purpose |
|---|---|
| `app.ts` | Creates and configures the Express app. Mounts routers, applies global middleware. No business logic. |
| `main.ts` | Entry point. Starts the HTTP server and any background jobs. |
| `router.ts` | Defines Express routes. Composes validation middleware and controller handlers. No business logic. |
| `controller.ts` | Request handlers containing business logic. Uses the shared Prisma client for DB access. |
| `validation.ts` | Zod schemas and `validate()` middleware instances. Single source of truth for request shapes. |
| `types.d.ts` | TypeScript types inferred from Zod schemas via `z.infer<>`. Never hand-write these — derive them. |
| `prisma/schema.prisma` | Defines all database models, relations, and enums. Run `prisma migrate dev` after changes. |
| `utils/prisma.ts` | Exports a singleton `PrismaClient`. Import this in every controller that needs DB access. |

---

## 3. Entry Point — `app.ts` + `main.ts`

The entry point is split across two files:

**`app.ts`** — creates and exports the Express app (imported by tests and `main.ts`):

```typescript
import express from "express";
import { attachUser, verifyInternalRequest } from "./utils/auth.js";

// ── App Setup ────────────────────────────────────────────────────────
const app = express();
app.use(express.json({
    // Captures the raw request bytes onto req.rawBody — verifyInternalRequest's
    // HMAC signature covers the raw bytes, not the parsed/re-serialized body.
    verify: (req, _res, buf) => {
        (req as express.Request).rawBody = buf.toString('utf8');
    },
}));

// ── API Router ───────────────────────────────────────────────────────
// All API routes are mounted under /api.
// verifyInternalRequest must run before attachUser — it rejects requests that
// didn't come through the facade before any claims are trusted.
const api = express.Router();
api.use(verifyInternalRequest);
api.use(attachUser);

// Mount resource routers here:
api.use("/merchants", (await import("./resources/merchants/router.js")).default);
api.use("/staff",     (await import("./resources/staff/router.js")).default);
api.use("/services",  (await import("./resources/services/router.js")).default);
api.use("/bookings",  (await import("./resources/bookings/router.js")).default);

// 404 fallback for unknown API endpoints
api.use((req, res) => {
    return res.status(404).json({ message: `Endpoint ${req.path} does not exist.` });
});

app.use("/api", api);

// ── Global Error Handler ─────────────────────────────────────────────
// Must have 4 parameters for Express to recognize it as an error handler.
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
    console.error("================== Uncaught error in request handling =================");
    console.error("Method:", req.method);
    console.error("URL:", req.originalUrl);
    console.error("Headers:", JSON.stringify(req.headers));
    console.error("Body:", JSON.stringify(req.body));
    console.error(err.stack);
    res.status(500).json({ message: err.message });
});

export default app;
```

**`main.ts`** — starts the server and background jobs:

```typescript
import * as dotenv from "dotenv";
dotenv.config();

import app from "./app.js";

// ── Start Server ─────────────────────────────────────────────────────
const PORT = Number.parseInt(process.env.PORT ?? '3000');
app.listen(PORT, () => console.log(`Server is listening on port ${PORT}...`));
```

### Key Points

- `dotenv.config()` must run before any code that reads `process.env` — it lives in `main.ts`.
- `app.ts` contains no `dotenv` call so it can be imported cleanly by tests without side effects.
- There is **no explicit database connection call**. Prisma's `PrismaClient` connects lazily on first query.
- `verifyInternalRequest` and `attachUser` are applied to the entire `/api` router, in that order, so every route is HMAC-checked before `req.user` is trusted (see §5b).
- Resource routers are dynamically imported with `await import()`. This keeps the import tree clean and allows top-level await.
- The global error handler catches any unhandled errors thrown in route handlers and returns a 500 response.

---

## 4. Global Types — `types.d.ts`

```typescript
export type GatewayPermission = 'sysAdmin' | 'merchant' | 'staff' | 'public';

// Claims present on req.user throughout the application, after attachUser maps
// the facade's internal JWT onto this shape (see §5b). No database lookup is
// performed — all identity information comes from the token.
export type GatewayClaims = {
    merchantId: number;
    merchantName: string;
    merchantApiKey: string;
    permission: GatewayPermission;
    userId?: number; // Present only when permission === 'staff'
};

// Raw claims minted by the facade and carried in the internal JWT
// (signed with INTERNAL_JWT_SECRET). attachUser maps this onto GatewayClaims.
export type InternalJwtClaims = {
    user_id?: string;
    merchant_id: string;
    roles: GatewayPermission[];
    feature_claims: string[];
    exp: number;
};

declare module 'express-serve-static-core' {
    interface Request {
        user: GatewayClaims | null;
        rawBody: string; // Captured by express.json()'s verify option (see §3) for HMAC verification
    }
}

export {};
```

This augments the Express `Request` type so `req.user` is available everywhere with full type safety. JWT claims are decoded directly from the token — no database lookup is needed. The `export {}` ensures the file is treated as a module.

---

## 5. Utils

### 5a. `utils/validation.ts` — Validate Middleware & Common Schemas

```typescript
import type { NextFunction, Request, Response } from "express";
import { z, ZodError, ZodType } from "zod";

// ── Common Reusable Schemas ──────────────────────────────────────────

export const phoneNumber = z.string().regex(
    /^\(\d{3}\) \d{3}-\d{4}$/,
    "Invalid phone number format"
);

export const zipCode = z.string().regex(
    /^\d{5}(-\d{4})?$/,
    "Invalid zip code format. Use 5-digit (12345) or ZIP+4 (12345-6789) format"
);

export const stateCode = z.enum([
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
]);

// Coerces empty strings and null to undefined, then applies .optional().
// Useful for form fields that may be submitted as empty strings.
export const coercedOptional = <T extends z.ZodTypeAny>(schema: T) =>
    z.preprocess(
        (val) => (val === '' || val === null || val === undefined ? undefined : val),
        schema.optional()
    );

// ── Validate Middleware ──────────────────────────────────────────────

type FormattedError = ReturnType<typeof z.treeifyError>;
const formatError = (error: ZodError): FormattedError => {
    return z.treeifyError(error);
};

// Creates Express middleware that validates req.params, req.query, and/or req.body
// against the provided Zod schemas. On success, the parsed (and potentially
// transformed) values replace the original req properties. On failure, returns
// a 422 response with structured error details.
//
// Usage:
//   const schema = { body: z.strictObject({ name: z.string().min(1) }) };
//   router.post('/', validate(schema), controller.create);
export function validate(schemas: {
    params?: ZodType<any> | null;
    query?: ZodType<any> | null;
    body?: ZodType<any> | null;
}) {
    return (req: Request, res: Response, next: NextFunction) => {
        const Errors: {
            body: FormattedError | undefined;
            query: FormattedError | undefined;
            params: FormattedError | undefined;
        } = {
            body: undefined,
            query: undefined,
            params: undefined,
        };

        Object.keys(schemas).forEach((field) => {
            const key = field as keyof typeof schemas;
            if (schemas[key]) {
                try {
                    const parsed = schemas[key].parse(req[key]);
                    if (key === 'query') {
                        // Express 5 makes req.query a read-only getter — plain assignment throws.
                        Object.defineProperty(req, 'query', {
                            value:        parsed,
                            writable:     true,
                            configurable: true,
                            enumerable:   true,
                        });
                    } else {
                        req[key] = parsed;
                    }
                } catch (error) {
                    if (!(error instanceof ZodError)) throw error;
                    Errors[key] = formatError(error);
                }
            }
        });

        if (Errors.body || Errors.query || Errors.params) {
            res.status(422).json({ errors: Errors });
            return;
        }

        next();
    };
}
```

#### How `validate()` Works

1. Accepts an object with optional `params`, `query`, and `body` keys, each a Zod schema.
2. For each provided schema, calls `.parse()` on the corresponding `req` property.
3. If parsing succeeds, the **parsed** value (with transforms applied) replaces `req[key]`. `req.query` needs `Object.defineProperty` instead of plain assignment because Express 5 exposes it as a read-only getter.
4. If any schema fails, collects all errors and returns a `422` response with a structured `{ errors }` body. The handler is **not** called.
5. If all schemas pass, calls `next()`.

### 5b. `utils/auth.ts` — Authentication & Authorization Middleware

This backend is one of several **modules** sitting behind a shared **facade**. The facade is the only service that talks directly to the upstream gateway/payment processor, and it is the only service holding the gateway's own JWT secret. The request path looks like:

```
Gateway (mints a long-lived module JWT)
    │  Bearer <module JWT>
    ▼
Facade
    │  1. Verifies the module JWT
    │  2. Mints a short-lived internal JWT (INTERNAL_JWT_SECRET, ~60s TTL)
    │  3. HMAC-signs the request (INTERNAL_HMAC_SECRET)
    │  4. Proxies to this module with the new headers
    ▼
This module (booking-backend, or whichever module you're building)
    │  verifyInternalRequest: validates the HMAC signature
    │  attachUser: decodes the internal JWT → req.user
    │  dispatchByUserType: routes by permission
    ▼
Controller
```

This module **never** sees the gateway's JWT secret and never verifies the long-lived module JWT — it only trusts requests that arrive already translated and signed by the facade. That keeps the gateway credential blast radius limited to one service (the facade), no matter how many modules exist behind it.

```typescript
import type { NextFunction, Request, Response, RequestHandler } from 'express';
import jwt from 'jsonwebtoken';
import { createHmac, timingSafeEqual } from 'crypto';

// ── CUSTOMIZE THIS ───────────────────────────────────────────────────
// Define the set of permission levels for your module.
// These must match the GatewayPermission type in types.d.ts.
type Permission = 'sysAdmin' | 'merchant' | 'staff' | 'public';
// ─────────────────────────────────────────────────────────────────────

type UserTypeMiddlewareMap = Partial<Record<Permission | 'none', RequestHandler[]>>;

// Raw claims minted by the facade — same shape across every module.
type InternalJwtClaims = {
    merchant_id:     string;
    roles:           string[];
    feature_claims:  string[];
    user_id?:        string;
};

// Verifies that a request was forwarded by the facade and not sent directly
// to this module. The facade HMAC-signs each request with INTERNAL_HMAC_SECRET
// before proxying, adding two headers:
//
//   X-Timestamp          — Unix timestamp (seconds) at the time of signing
//   X-Internal-Signature — hex-encoded HMAC-SHA256 over `${timestamp}${method}${url}${rawBody}`
//
// A ±30-second window is enforced to guard against replay attacks.
//
// Behaviour is controlled by the HMAC_ENFORCE environment variable:
//   HMAC_ENFORCE=false (default) — log-only; missing or invalid signatures are warned but allowed.
//                                  Use this until the facade is deployed and headers confirmed.
//   HMAC_ENFORCE=true            — enforcing; requests that fail verification are rejected with 401.
//
// req.rawBody must be captured by express.json()'s verify option (see §3) —
// the signature covers the raw bytes, not the parsed/re-serialized body.
export const verifyInternalRequest = (req: Request, res: Response, next: NextFunction) => {
    const enforce = process.env.HMAC_ENFORCE === 'true';

    if (!process.env.INTERNAL_HMAC_SECRET) {
        if (enforce) return res.sendStatus(500);
        return next();
    }

    const ts  = req.headers['x-timestamp'];
    const sig = req.headers['x-internal-signature'];

    if (!ts || !sig || Array.isArray(ts) || Array.isArray(sig)) {
        if (enforce) return res.sendStatus(401);
        return next();
    }

    if (Math.abs(Date.now() / 1000 - Number(ts)) > 30) {
        if (enforce) return res.sendStatus(401);
        return next();
    }

    const rawBody = req.rawBody ?? '';
    const expected = createHmac('sha256', process.env.INTERNAL_HMAC_SECRET)
        .update(`${ts}${req.method}${req.originalUrl}${rawBody}`)
        .digest('hex');

    let valid: boolean;
    try {
        valid = timingSafeEqual(Buffer.from(sig, 'hex'), Buffer.from(expected, 'hex'));
    } catch {
        valid = false;
    }

    if (!valid && enforce) return res.sendStatus(401);
    next();
};

// Chains an array of middleware functions into a single RequestHandler.
// Each middleware is executed in order; if any calls next(error), the chain stops.
const chainMiddleware = (middlewareList: RequestHandler[]): RequestHandler => {
    return (req, res, next) => {
        const executeMiddlewareAtIndex = (index: number) => {
            if (res.headersSent) return;
            if (index >= middlewareList.length) return next();
            middlewareList[index](req, res, (error?: unknown) => {
                if (error) return next(error);
                executeMiddlewareAtIndex(index + 1);
            });
        };
        executeMiddlewareAtIndex(0);
    };
};

// Routes a request to different middleware chains based on the authenticated
// user's permission level. If no handler is defined for the user's permission:
//   - Authenticated user → 403 Forbidden
//   - No user            → 401 Unauthorized
//
// Usage:
//   router.get('/', dispatchByUserType({
//       merchant: [controller.getForMerchant],
//       sysAdmin: [controller.getAll],
//   }));
//
//   router.patch('/:id', dispatchByUserType({
//       merchant: [validateMerchantPatch, controller.merchantPatch],
//       staff:    [validateStaffPatch, controller.staffPatch],
//   }));
//
// The 'none' key handles unauthenticated requests — distinct from the 'public'
// permission, which is a real role the facade can mint (see attachUser below):
//   router.post('/public', dispatchByUserType({
//       none:     [controller.publicAction],
//       merchant: [controller.merchantAction],
//   }));
export const dispatchByUserType = (userTypeMiddlewareMap: UserTypeMiddlewareMap): RequestHandler => {
    return (req, res, next) => {
        const resolvedPermission: Permission | 'none' = req.user?.permission ?? 'none';
        const matchedHandler = userTypeMiddlewareMap[resolvedPermission];
        if (!matchedHandler) {
            if (req.user) return res.sendStatus(403);
            else return res.sendStatus(401);
        }
        chainMiddleware(matchedHandler)(req, res, next);
    };
};

// Extracts a Bearer token from the Authorization header. Accepts only tokens
// signed with INTERNAL_JWT_SECRET — the short-lived token minted by the facade,
// never the gateway's own long-lived module JWT. No DB query is performed; all
// identity information comes directly from the token claims.
//
// Maps the facade's raw internal claims onto the module-facing GatewayClaims
// shape (see types.d.ts) so controllers never deal with the wire format.
//
// If no token is present, INTERNAL_JWT_SECRET is not set, or verification
// fails, req.user is set to null. This middleware NEVER rejects a request —
// use dispatchByUserType() to enforce auth.
export const attachUser = (req: Request, res: Response, next: NextFunction) => {
    const authorizationHeader = req.headers.authorization;
    if (!authorizationHeader?.startsWith('Bearer ')) {
        req.user = null;
        return next();
    }

    const bearerToken = authorizationHeader.split(' ')[1];
    try {
        if (!process.env.INTERNAL_JWT_SECRET) throw new Error('INTERNAL_JWT_SECRET not configured');
        const internal = jwt.verify(bearerToken, process.env.INTERNAL_JWT_SECRET) as InternalJwtClaims;
        req.user = {
            merchantId:     parseInt(internal.merchant_id, 10),
            merchantName:   '',
            merchantApiKey: '',
            permission:     (internal.roles[0] as Permission) ?? 'public',
            userId:         internal.user_id ? parseInt(internal.user_id, 10) : undefined,
        };
    } catch {
        req.user = null;
    }

    next();
};
```

#### Authorization Pattern

The `dispatchByUserType` middleware is the primary authorization mechanism. It allows you to define **per-permission middleware chains** for each route. Each chain is an array of `RequestHandler` functions — typically a validation middleware followed by a controller function.

This means the same endpoint (e.g., `GET /services`) can have completely different validation and business logic depending on the caller's permission level, without complex `if/else` branching in controllers.

`'public'` is a real permission the facade can mint for unauthenticated end-user flows (e.g. a customer-facing booking widget) — it still carries `merchantId`, so controllers scope data by tenant exactly like `merchant`/`staff` do. It is distinct from `'none'`, which means no token was presented at all.

Note that `attachUser` is **synchronous** — it only decodes the internal JWT. No database lookup is performed at the auth layer; all identity information (merchant ID, user ID, permission) comes directly from the token claims. `verifyInternalRequest` must run *before* `attachUser` in the middleware chain (see §3) — it rejects requests that didn't come through the facade before any claims are trusted.

#### Required Environment Variables

```
INTERNAL_JWT_SECRET   # Shared with the facade — verifies the short-lived internal JWT
INTERNAL_HMAC_SECRET  # Shared with the facade — verifies the X-Internal-Signature header
HMAC_ENFORCE          # "true" to reject failed HMAC checks; omit/"false" to log-only
```

This module never holds the gateway's own JWT secret — only the facade does.

### 5c. `utils/jwt.ts` — JWT Wrapper

```typescript
import jwt from 'jsonwebtoken';

const config = {
    secret: process.env.JWT_SECRET!,
};

export function sign(payload: object, options?: jwt.SignOptions) {
    return jwt.sign(payload, config.secret, options);
}

export function verify(token: string, options?: jwt.VerifyOptions) {
    return jwt.verify(token, config.secret, options);
}
```

Centralizes the JWT secret so it is never referenced directly outside this file. `JWT_SECRET` here is a **separate** secret from `INTERNAL_JWT_SECRET` (§5b) — this one is for tokens *this module itself* mints and verifies directly (e.g. a customer-facing "manage this booking" link), not for decoding the facade's internal auth JWT.

---

## 6. Prisma Client — `utils/prisma.ts` + `prisma/schema.prisma`

### `utils/prisma.ts` — Singleton Client

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export default prisma;
```

Import this single instance in every controller that needs database access. Never instantiate `PrismaClient` more than once — it manages a connection pool internally.

### `prisma/schema.prisma` — Database Models

All database models and relations are defined here. This is the single source of truth for the database schema. After any change to this file, run:

```sh
npx prisma migrate dev --name <description>
```

This generates a SQL migration, applies it to the database, and regenerates the Prisma Client types.

**Example model:**

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Merchant {
    id          String   @id @default(uuid())
    externalId  Int      @unique

    name        String
    createdAt   DateTime @default(now())
    updatedAt   DateTime @updatedAt

    services    Service[]
}
```

### Key Points

- IDs use `String @id @default(uuid())` — all records have UUID primary keys.
- `externalId` (an `Int`) is used to link records to the payment gateway's merchant ID from the JWT.
- Prisma generates fully-typed query methods from the schema (e.g., `prisma.merchant.findUnique()`).
- There are **no per-resource model files**. Models are defined in `schema.prisma` and accessed via the shared `prisma` client.

### Required Environment Variable

```
DATABASE_URL="postgresql://user:password@host:5432/dbname"
```

---

## 7. Session Routes

This project does **not** use a traditional session/login flow. Authentication is handled externally by the payment gateway, which mints signed JWT tokens. This backend only verifies those tokens in `attachUser` (see §5b).

There is no `/session` route. To identify the current caller in a controller, read from `req.user`:

```typescript
export async function getMe(req: Request, res: Response) {
    const merchant = await prisma.merchant.findUnique({
        where: { externalId: req.user!.merchantId },
    });
    if (!merchant) return res.sendStatus(404);
    res.json({ data: merchant });
}
```

The `req.user.merchantId` is the integer ID from the payment gateway JWT and is used as the `externalId` foreign key to link gateway merchants to local database records.

---

## 8. Domain Resource Pattern

Every domain resource follows the same 4-file convention. Below is a skeleton for a resource called `things`.

### File Structure

```
resources/things/
├── router.ts
├── controller.ts
├── validation.ts
└── types.d.ts
```

There is no `model.ts` per resource. All models are defined in `prisma/schema.prisma` and accessed via the shared `prisma` client from `utils/prisma.ts`.

### `validation.ts` — Skeleton

```typescript
import { z } from "zod";
import * as utils from "../../utils/validation.js";

// Reuse the shared UUID param helper from utils/validation.ts
// utils.uuidParam = z.object({ id: z.uuid('Invalid UUID format') })

// Define one schema object per route handler.
// Each schema object can have params, query, and/or body keys.
export const PostSchema = {
    body: z.strictObject({
        name: z.string().trim().min(1),
        // ... fields
    }),
};
export const validatePost = utils.validate(PostSchema);

export const GetByIdSchema = {
    params: utils.uuidParam,
};
export const validateGetById = utils.validate(GetByIdSchema);

export const PatchSchema = {
    params: utils.uuidParam,
    body: z.strictObject({
        name: z.string().trim().min(1).optional(),
        // ... all fields optional for PATCH
    }),
};
export const validatePatch = utils.validate(PatchSchema);

export const DeleteSchema = {
    params: utils.uuidParam,
};
export const validateDelete = utils.validate(DeleteSchema);
```

### `types.d.ts` — Skeleton

```typescript
import type { z } from 'zod';
import * as validate from './validation.js';

export type PostBody = z.infer<typeof validate.PostSchema.body>;
export type PatchBody = z.infer<typeof validate.PatchSchema.body>;
```

### `controller.ts` — Skeleton

```typescript
import type { Request, Response } from 'express';
import prisma from '../../utils/prisma.js';
import type * as t from './types.js';

export async function getAll(req: Request, res: Response) {
    const things = await prisma.thing.findMany({
        where: { merchantId: req.user!.merchantId },
    });
    res.json({ data: things });
}

export async function getById(req: Request, res: Response) {
    const thing = await prisma.thing.findUnique({
        where: { id: req.params.id },
    });
    if (!thing) return res.sendStatus(404);
    res.json({ data: thing });
}

export async function create(req: Request, res: Response) {
    const body = req.body as t.PostBody;
    const thing = await prisma.thing.create({ data: body });
    res.status(201).json({ data: thing });
}

export async function update(req: Request, res: Response) {
    const body = req.body as t.PatchBody;
    const thing = await prisma.thing.update({
        where: { id: req.params.id },
        data:  body,
    });
    res.json({ data: thing });
}

export async function remove(req: Request, res: Response) {
    await prisma.thing.delete({ where: { id: req.params.id } });
    res.sendStatus(204);
}
```

### `router.ts` — Skeleton

```typescript
import express from 'express';
import * as v from './validation.js';
import * as c from './controller.js';
import * as a from '../../utils/auth.js';

const things = express.Router();

// Public or permission-gated routes using dispatchByUserType:
things.get('/', a.dispatchByUserType({
    merchant: [c.getAll],
}));

things.get('/:id', a.dispatchByUserType({
    merchant: [v.validateGetById, c.getById],
}));

things.post('/', a.dispatchByUserType({
    merchant: [v.validatePost, c.create],
}));

things.patch('/:id', a.dispatchByUserType({
    merchant: [v.validatePatch, c.update],
}));

things.delete('/:id', a.dispatchByUserType({
    merchant: [v.validateDelete, c.remove],
}));

export default things;
```

### Pattern Rules

1. **Routers** contain no business logic. They compose validation + controller handlers.
2. **Controllers** cast `req.body` / `req.params` to the types derived from Zod schemas. They never re-validate.
3. **Validation files** export both the raw schema objects (for type inference) and the `validate()` middleware instances.
4. **Types files** only contain `z.infer<>` type aliases. They import from the sibling `validation.ts`.
5. When different roles need different behavior on the same endpoint, use `dispatchByUserType` with per-role middleware chains — each chain can have its own validation and controller.

---

## 9. Database Instructions

### PostgreSQL (Prisma ORM)

This is the database used in this architecture. The connection string is configured via a single environment variable:

```
DATABASE_URL="postgresql://user:password@host:port/dbname"
```

There is **no explicit connect call** in application code. `PrismaClient` connects lazily when the first query runs and manages its own connection pool.

#### Migrations

Migrations are managed with Prisma Migrate:

```sh
# After modifying prisma/schema.prisma:
npx prisma migrate dev --name <description>

# Apply pending migrations in production:
npx prisma migrate deploy

# Check migration status:
npx prisma migrate status

# Regenerate the Prisma Client without migrating (after manual schema edits):
npx prisma generate
```

#### Querying

All database access goes through the shared `prisma` client imported from `utils/prisma.ts`:

```typescript
import prisma from '../../utils/prisma.js';

// Find a unique record
const merchant = await prisma.merchant.findUnique({ where: { id } });

// Find many with a filter
const services = await prisma.service.findMany({ where: { merchantId } });

// Create
const booking = await prisma.booking.create({ data: { ... } });

// Update
const staff = await prisma.staff.update({ where: { id }, data: { ... } });

// Upsert
const record = await prisma.merchant.upsert({
    where:  { externalId },
    update: body,
    create: { externalId, ...body },
});

// Delete
await prisma.thing.delete({ where: { id } });

// Transaction (atomic batch)
const results = await prisma.$transaction([
    prisma.merchantSchedule.upsert({ ... }),
    prisma.merchantSchedule.upsert({ ... }),
]);
```

#### ID Format

All primary keys use UUID strings (`String @id @default(uuid())`). Validate UUID params with the shared helper from `utils/validation.ts`:

```typescript
// In validation.ts:
export const uuidParam = z.object({ id: z.uuid('Invalid UUID format') });

// Usage in a schema:
export const GetByIdSchema = { params: uuidParam };
```

#### Key Differences vs. Mongoose

| Concern | Mongoose (old) | Prisma (current) |
|---|---|---|
| Schema location | Per-resource `model.ts` file | Single `prisma/schema.prisma` |
| ID format | 24-char hex ObjectId | UUID string |
| ID validation | `z.string().regex(/^[0-9a-fA-F]{24}$/)` | `z.uuid()` |
| Find by ID | `Model.findById(id)` | `prisma.model.findUnique({ where: { id } })` |
| Create | `Model.create(data)` | `prisma.model.create({ data })` |
| Update | `Model.findByIdAndUpdate(id, data, { new: true })` | `prisma.model.update({ where: { id }, data })` |
| Delete | `Model.findByIdAndDelete(id)` | `prisma.model.delete({ where: { id } })` |
| Migrations | Automatic (schema sync) | Manual via `prisma migrate dev` |
| Transactions | Sessions / `session.withTransaction()` | `prisma.$transaction([...])` |

---

## 10. Validation Pattern Deep-Dive

### Data Flow

```
Request → validate(schemas) middleware → Controller (typed body)
                  │                              │
                  │  On failure: 422 + errors     │  On success: req.body/params/query
                  ▼                              ▼  are now parsed & transformed
             Client                        Business logic
```

### Schema Definition Convention

Each route's schema is defined as a plain object with `params`, `query`, and/or `body` keys:

```typescript
export const CreateSchema = {
    body: z.strictObject({
        name: z.string().trim().min(1),
        email: z.string().trim().toLowerCase().pipe(z.email()),
    }),
};
export const validateCreate = utils.validate(CreateSchema);
```

### Type Inference Convention

In the sibling `types.d.ts`, derive TypeScript types from the schemas:

```typescript
import type { z } from 'zod';
import * as validate from './validation.js';

export type CreateBody = z.infer<typeof validate.CreateSchema.body>;
```

Then cast in the controller:

```typescript
const body = req.body as t.CreateBody;
```

### Why Cast Instead of Re-Validate?

The `validate()` middleware has already parsed and transformed the data. By the time the controller runs, `req.body` is guaranteed to match the schema. The `as` cast is safe and avoids redundant parsing.

### Validation Tips

- **Use `z.strictObject()`** for bodies to reject extra fields.
- **Use `z.object()`** only when you need to allow extra fields (e.g., login where you don't want to leak info about expected fields).
- **PATCH bodies**: Make every field `.optional()`.
- **Transforms**: Zod transforms (`.trim()`, `.toLowerCase()`, `.pipe()`) run during `validate()`, so controllers receive clean data.
- **Params**: Always validate params to ensure IDs are well-formed before hitting the database.
- **`coercedOptional()`**: Use for form fields that might arrive as empty strings but should be treated as `undefined`.

### Error Response Format

When validation fails, the response body has this shape:

```json
{
  "errors": {
    "body": { /* Zod treeified error or undefined */ },
    "query": { /* Zod treeified error or undefined */ },
    "params": { /* Zod treeified error or undefined */ }
  }
}
```

Each error value is the output of `z.treeifyError()` — a nested object mirroring the schema structure with error messages at each invalid path.