---
name: booking-module-mirror
description: Use when epayment or fulfillment work asks what the Booking module did, how to mirror Booking's epayment proxy/JWT contract, mentions Roarmo's merged Booking PRs, or needs buzz-financial/Booking-Backend checked.
---

# Booking Module Mirror

Read-only loop for understanding what Booking did before using it as the fulfillment mirror.

## Steps

1. Confirm the target.
   - Use `/Users/testadmin/Development/work/epayment` for Booking evidence.
   - Treat `https://github.com/buzz-financial/Booking-Backend` as the Booking service-side source when access is available.
   - If the target is fulfillment, treat Booking as the epayment-side pattern and the fulfillment docs as the contract.
   - Completion: state whether the answer is about Booking itself, fulfillment's mirror, or both.

2. Re-check the merged Roarmo PR evidence.
   ```sh
   epayment-gh pr list --repo ExpiTrans/epayment --state merged --author roarmo --search booking --limit 30 --json number,title,mergedAt,author,url,headRefName,baseRefName
   epayment-gh pr view 313 --repo ExpiTrans/epayment --json number,title,body,mergedAt,url,files,commits
   epayment-gh pr view 314 --repo ExpiTrans/epayment --json number,title,body,mergedAt,url,files
   epayment-gh pr view 315 --repo ExpiTrans/epayment --json number,title,body,mergedAt,url,files
   ```
   - Starting points: #313 `TROUT-283 Appointment APIs` merged 2026-06-23, #314 `TROUT-588 Make the module Base URL an env for develop, staging and production` merged 2026-06-25, #315 `TROUT-589 Add merchant module activation table and APIs` merged 2026-06-25.
   - Treat those PRs as known anchors, not the whole search space. If `pr list` returns other current Booking PRs, inspect the relevant ones before summarizing.
   - If fulfillment mirror work is in scope, also check PR #385 metadata; it is the active epayment mirror branch when open and may contain helper files not yet on `develop`.
   - Completion: name the PRs used and the part each contributed. If GitHub now reports different Booking PRs, use the current metadata.

3. Read the local evidence.
   - `/Users/testadmin/Development/work/troute-fulfillment/docs/handoffs/2026-07-07-booking-module-investigation.md`
   - `/Users/testadmin/Development/work/epayment/modules/booking/booking.jwt.php`
   - `/Users/testadmin/Development/work/epayment/modules/booking/booking.api.php`
   - `/Users/testadmin/Development/work/epayment/endpoints/ExpiBooking.inc.php`
   - If fulfillment is in scope, also read the current fulfillment contract docs named by the repo's `AGENTS.md`.
   - If a fixed path is missing or moved, say so, then use `rg --files`/Graphify to locate the current Booking or fulfillment path. Do not fill gaps from memory.
   - Completion: identify the current code path, not just the PR body.

4. Ask the epayment NotebookLM corpus as an advisory sidecar.
   ```sh
   notebooklm auth check --test --json
   notebooklm ask -n 49496b97-0936-4d76-946a-037d06569464 "For this ticket, what should I learn from the Booking module integration? Include PRs, local files, and JWT/proxy contract conflicts."
   ```
   - Use explicit `-n`; do not rely on NotebookLM context.
   - Verify NotebookLM claims against GitHub and local files before acting.
   - Include NotebookLM claims only when corroborated, or label them `corpus-only/unverified`.
   - Completion: either include the useful corpus finding or record the auth/corpus blocker.

5. Check the Booking backend source when accessible.
   ```sh
   gh repo view buzz-financial/Booking-Backend --json nameWithOwner,url,defaultBranchRef,visibility
   git ls-remote https://github.com/buzz-financial/Booking-Backend.git HEAD
   ```
   - If access works, inspect current backend routes, auth/JWT expectations, tenant identifiers, and validation shapes from an existing checkout or a temporary clone outside epayment.
   - If access fails or the repo is private, record that blocker and do not treat PR bodies, handoffs, or NotebookLM as backend source of truth.
   - Completion: state whether `buzz-financial/Booking-Backend` was checked, and cite the exact backend files or the access error.

6. Produce the mirror summary.
   - Treat the details below as the expected baseline as of the last read; confirm each against Step 3 and correct the summary if the live code has drifted.
   - Booking epayment pattern: `ExpiBooking` routes the query API, enforces module activation and caller permission, mints one short-lived HS256 JWT per non-manage request, then calls `BookingModuleApi`.
   - Booking JWT: `BookingJwt::mint()` signs with `SHARED_JWT_SECRET`, TTL 3600, and claims `iss`, `merchant_id`, `permission`, `user_id`, `iat`, `exp`, `x_login`, and `x_tran_key`.
   - Booking proxy: `BookingModuleApi` reads `MODULE_URL`, appends `/api/v1/bookings` when needed, sends JSON cURL requests with `Authorization: Bearer <jwt>`, and maps 422 Zod errors through `BookingValidationException`.
   - Fulfillment mirror: copy the narrow epayment gateway contract, not Booking's whole product surface. Verify the current fulfillment JWT claim name in local docs; the 2026-07-07 handoff says `troute_merchant_id`, while some corpus summaries may say `merchant_id`.
   - Completion: separate `copy`, `verify`, and `leave out` items, with file paths or PR URLs as evidence.

## Stop Conditions

- If GitHub auth fails, use local files and say PR metadata was not rechecked.
- If `buzz-financial/Booking-Backend` is private or unreachable, say backend source was not checked.
- If local fulfillment docs conflict with NotebookLM, use the local docs and name the conflict.
- If the task requires AWS secrets, production mutation, deploys, or database changes, stop at read-only evidence until the user explicitly authorizes that action.

## Output

Use concise Markdown sections: `Evidence`, `Booking Pattern`, `Mirror Contract`, `Open Checks`.
