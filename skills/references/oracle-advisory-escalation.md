# Oracle Advisory Escalation

Use Oracle to package a fresh one-shot bundle for ChatGPT 5.5 Pro review when an independent outside critique materially reduces risk. In `$devise`, Oracle Plan Review is the default for substantial planning after local discovery and before final plan output. Codex remains the final planner, executor, and verifier.

## Use Oracle When

- A `$devise` plan is architecture-significant, multi-file, high-risk, security/auth/data-touching, release-risk, design-heavy, vendor/dependency/platform-dependent, or survived grilling.
- A durable technical direction depends on vendor, platform, dependency, protocol, compliance, or security tradeoffs.
- `$check`, `$gate`, PR review, or feedback triage exposes broad uncertainty, systemic review findings, or release-risk ambiguity.
- Hard debugging or repeated failure suggests Codex may be tunnel-visioned and a fresh reviewer could catch missed assumptions.

## Do Not Use Oracle When

- The work is routine, localized, or faster to verify locally.
- A small bug, simple test failure, formatting issue, or one-thread review comment has a clear fix.
- The needed bundle would include secrets, credentials, customer/user data, regulated data, browser/search history, personal docs, raw production logs, or sensitive screenshots.
- Oracle would replace Codex final planning judgment, mandatory local validation, `$codex-review`, `$check`, `$gate`, `$land`, `$close`, or human approval.

## Default Flow

1. Select the minimum prompt and files that contain the truth.
2. Run `oracle --dry-run summary --files-report ...` before broad globs, generated docs/logs, dotfiles, repo-root scopes, or bundles likely over 100k tokens.
3. Target 80k-200k tokens; treat about 250k tokens as the hard ceiling unless the user explicitly approves more.
4. Use browser-mode Oracle only through the `$oracle` hard policy: `--engine browser --browser-manual-login --model "5.5 Pro" --browser-model-strategy select`, no API/OpenRouter/provider mode, with submission and model evidence.
5. For substantial `$devise` plans, standing approval covers safe routine Oracle Plan Review after the safety preflight. Stop instead of submitting on login/2FA/account/payment UI, sensitive bundles, broad ambiguous file scope, or explicit user constraint.
6. Ask ChatGPT 5.5 Pro for a proposed plan or critique: false assumptions, missing tests, security/backend/infra/design risks, simpler options, rollout hazards, and acceptance criteria.
7. Treat the result as advisory evidence. Accept or reject each recommendation against local files, repo constraints, and tests before acting.

## Safety

- Exclude `.env`, `.env.*`, keys, tokens, private logs, customer/user data, regulated data, browser/search history, personal documents, and sensitive screenshots by default.
- Redact sensitive excerpts when they are essential to the review.
- Do not continue long ChatGPT prompt chains; reconstruct a fresh one-shot context for each Oracle review.
- Do not claim completion from Oracle output alone. Completion requires local proof or an explicit review-only scope.
