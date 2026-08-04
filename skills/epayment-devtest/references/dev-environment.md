# The epayment dev environment

How Jaden's dev/test box works. Every concrete secret — host IP, SSH login,
test-merchant logins, API keys, carrier sandbox keys — lives only in the
epayment repo's gitignored `DEV_ENVIRONMENT.local.md`. This file explains the
machinery; read that file for the values. Never copy values from it into
tracked files, command output shown in reports, PR text, or Jira.

## What the box is

The canonical dev/test stage for epayment: a per-developer subdomain
(`jaden.expitrans.com`, HTTP and HTTPS) serving a copy of the repo as a live
PHP site. It sits between local work and `develop`:

| Stage | Target | Deploy / test | Gate |
| --- | --- | --- | --- |
| local | your machine | run locally | - |
| dev/test | `jaden.expitrans.com` | rsync/scp or PhpStorm SFTP to the web root | test here before opening a PR |
| develop | `origin/develop` | squash-merge PR | 2 reviewers, PM merges |

The develop environment is the real post-merge test; the box exists to prove a
PR branch before that.

## Server layout

- Web root: `/var/www/jaden.expitrans.com/public_html` — it maps 1:1 to the
  epayment repo root. Copying a repo file to the same relative path under the
  web root deploys it.
- Plain PHP: no build step, no compile, no cache to bust. A copied file is live
  on the next request. `templates/docs/**` renders live at `/docs` (anchors per
  section, e.g. `/docs#fulfillment_module`).
- SSH login lands directly in the web root.
- Auth is password-based (per `DEV_ENVIRONMENT.local.md`); the same file
  carries keygen instructions if you ever switch the box to key auth.

## Deploy lane

The Claude agent harness cannot push over SSH/SFTP — the credential classifier
blocks it. The agent computes what to send and prints the exact command; the
user (or Codex) runs it. In a Claude session, `! <command>` runs it inline so
the transfer receipt lands in the conversation.

Auth is key-based and non-interactive (set up 2026-07-20): a dedicated key
with a `~/.ssh/config` Host block (`IdentityFile`, `BatchMode yes`) for the
dev box. The printed rsync/scp/ssh commands run without a password prompt.
If a command asks for a password, the key lane is broken — fix that
(`ssh -o BatchMode=yes <user>@<host> true` must succeed) instead of typing
the password.

- Changed-file set for a PR branch: `git diff --name-only $(git merge-base
  origin/develop HEAD)` (drop deleted and gitignored/local-only paths).
- Multi-file push, preserving relative paths (`-R`/`--relative`), from the repo
  root:

  ```
  rsync -avR <file> <file> ... <user>@<host>:/var/www/jaden.expitrans.com/public_html/
  ```

- Single file: `scp <path> <user>@<host>:/var/www/jaden.expitrans.com/public_html/<path>`
- PhpStorm SFTP is the manual alternative (project root mapped to the web
  root).
- Local-only files never ship: `AGENTS.md`, `CLAUDE.md`, `company-docs/`,
  `.claude/`, `DEV_ENVIRONMENT.local.md`, `lib/config.inc.php`, notes. The box
  has its own config.

## Database

The box runs its own PostgreSQL; nothing applies migrations automatically.

- Apply a PR's `db/*.sql` by hand over SSH:

  ```
  ssh <user>@<host> "psql -U <dbuser> -d <dbname> -f /var/www/jaden.expitrans.com/public_html/db/<migration>.sql"
  ```

  (push the migration file first; migrations are idempotent, so reruns are
  safe).
- Separate from the box: the local proof lane `~/.codex/bin/epayment-devdb`
  (`reset|apply|seed|verify`) runs the schema against a local Postgres via
  `~/.config/epayment-devdb.env`. Use it for schema proof without touching the
  box.

## Test identities

`DEV_ENVIRONMENT.local.md` carries, for end-to-end runs:

- Troute app logins: one admin, one test merchant.
- Troute API test key/secret, the test merchant's `merchant_id`, and a
  ready-made JWT (JWTs expire — mint or refresh rather than trusting an old
  one).
- Carrier sandboxes: FedEx test API (sandbox URL, account, key pair) and USPS
  test keys. Sandbox only; live carrier accounts are out of bounds.

## End-to-end verification

What "working as intended" means on this box, tiered:

1. **Render** — `curl -s -o /dev/null -w '%{http_code}' https://jaden.expitrans.com/<route>`
   for each touched page; then `curl -s ... | grep` for the changed markup.
   Docs pages: `/docs#<anchor>`.
2. **Login** — authenticate as the test merchant (browser via
   `headless-browse` when the change is UI-visible).
3. **API** — call each touched `/query/*` endpoint with the test-merchant
   credentials/JWT; assert status and response shape.
4. **Business flow** — for module changes, drive the whole chain. Fulfillment:
   epayment `/query/fulfillment/*` -> module cURL client
   (`modules/fulfillment/fulfillment.api.php`, per-request HS256 JWT) ->
   fulfillment facade -> order -> shipment -> label, on sandbox carriers.
   Booking mirrors the same shape through `modules/booking/`.
5. **Tenancy** — one negative check per run: a request scoped to a different
   `merchant_id` must be denied. Multi-tenancy is a security boundary here.

## Box state and hygiene

- The box keeps the last tested PR's files; there is no auto-reset. Each
  devtest run appends a deploy record (branch, commit, files, UTC date, grade)
  to `DEV_ENVIRONMENT.local.md` so the next agent knows what state the box is
  in.
- End each record with one machine-readable line. Sort `files`, compute
  `files_sha256` from their newline-joined UTF-8 names, and never include secrets:

  `<!-- epayment-devtest:{"v":1,"branch":"jms/trout-123-task","commit":"<40-hex>","files":["path"],"files_sha256":"<64-hex>","utc":"<ISO-8601>","grade":"PASS|WARN|BLOCK"} -->`

  Lifecycle guards read only the latest valid marker and never print surrounding
  `DEV_ENVIRONMENT.local.md` content.
- Stale-box check: diff the recorded state against the current branch before
  assuming the box matches your checkout.
- Boundaries (standing, confirmed by Jaden): dev/test surfaces only — no
  production deploys, no production merchant mappings, no live carrier
  accounts, no Jira mutation from test evidence, no tracked secret files, and
  devtest evidence never merges a PR.
