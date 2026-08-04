---
name: best-long-term
description: Use when the user wants a durable production decision that compounds over the fastest patch, or when current primary-source research should shape dependency, platform, protocol, security, data, AI/agent, or architecture choices.
---

# Best Long-Term

Optimize for the decision a strong senior team would still be glad to own in 12-24 months, not the fastest green check — the change lands in a production system someone else maintains and is paged for.

## Decision Standard

A durable choice **compounds**: each one makes the next change cheaper. A fast patch borrows against the future — it ships today and bills later as migration debt, fragile coupling, or a 3am page. Choose the option that compounds; name the one that borrows and what it borrows.

A production choice keeps **control**: tests catch regressions, rollout can stop, logs and traces explain failure, one owner can change it, contracts stay compatible, privileges stay narrow, and cost has a ceiling.

Weigh every option against what a production codebase must keep true:

- **Correctness & idempotency** — explicit invariants, not behaviour that happens to pass today; anything retried, replayed from a queue, or re-run as a migration is safe to execute more than once, with a named idempotency key.
- **Reversibility** — bounded blast radius with a named containment mechanism (feature-flag kill switch, circuit breaker, rate limit); behavioural changes on hot paths ship behind a flag or canary; one-way doors (dropping a column after backfill, breaking an event schema, removing an API field) need explicit sign-off.
- **Compatibility** — no breaking a public contract, schema, or stored-data shape without expand-then-contract: add the new shape, migrate readers, backfill (batched, lock- and replication-lag-safe), drop the old shape in a later change; new code stays readable by the N-1 version for one deploy cycle; code and migration roll back independently.
- **Operability** — diagnosable by on-call who never saw it written; new failure modes get alerts; a change that moves an existing alert's signal is checked against the SLO and error budget.
- **Scale & cost** — holds at p95 production load, not just test fixtures; name the row count, request rate, or payload it must take; flag unindexed queries, synchronous fan-out, and cost that grows super-linearly with traffic or data.
- **Security** — name the trust boundary the change crosses; least privilege and auditability at it; no secret on a path that logs, no access wider than the operation needs.
- **AI/agent work** — generated or agent-written code must pass the same controls as human code; reject unchecked output, context bloat, runaway loops, unbounded retries or tool fan-out, and hidden architectural drift.
- **Simplicity & fit** — the simpler architecture with a clear owner; abstractions earn their keep; solve the real requirement, not a speculative future one; low surprise at the call site.

Default to small batches, boring architecture, explicit ownership, automated verification, reversible rollout, supply-chain/security posture, and operable failure modes. Reject the fastest-demo fix that buys a green check with migration debt, the clever single-use abstraction, the unjustified dependency, the broad rewrite where a narrow durable repair holds, and research theater that does not change the decision.

## Workflow

1. **Frame.** State the long-term objective in one sentence. Name the hard constraints — deadline, compatibility, migration risk, compliance, team skill, production state — and what would make a fast patch dangerous here.

2. **Gather evidence.** Read the local code, tests, ADRs, issues, and recent failures that hold the truth; use repo and knowledge tools when available. Research externally only when an external fact moves the decision (see *Deep research when*). For current or "latest" facts, use primary sources and capture source names plus publication or update dates. Done when every local source that could move the decision is read and the evidence fits in one sentence.

3. **Compare 2-4 paths.** For each: long-term upside, risk, migration cost, operational burden, when to pick it. Call out the cheapest acceptable option separately from the best durable one when they differ — name the gap, don't hide it.

4. **Decide.** Recommend one path, state why it compounds better than the rest, and write success criteria and verification before any code. When the decision is architecture-, security-, data-, dependency-, or contract-significant, run Oracle review per `~/.codex/skills/references/oracle-advisory-escalation.md` before locking; below that threshold record `Oracle: skipped — routine`. Oracle is advisory: accept or reject each point against local code, tests, and constraints. If the bundle is unsafe, too broad, or submission is unavailable, record `Oracle: blocked` with the exact reason. Done when the path is locked with success criteria written and Oracle status recorded.

5. **Execute.** Change only what the approved path requires, toward the durable shape. Preserve every observable behaviour — API contracts, event schemas, stored-data shapes — unless the user explicitly wrote "approved" or the migration was named in step 1. Add tests, docs, and operational checks proportional to risk. Done when every change traces to the approved path, tests pass, and no unscoped follow-up remains.

6. **Verify.** Done when every external claim names its source, residual risk is stated, and the next hardening step is named and actionable — not "monitor" or "revisit later."

## Deep research when

The cost of being wrong exceeds the cost of research — and one of these holds:

- Security, privacy, compliance, legal, financial, medical, or production-reliability stakes are material.
- The decision turns on current public facts that may have changed since training.
- You are choosing a dependency on the production critical path, or one load-bearing for security, reliability, data integrity, or compliance — not dev/test-only tooling.
- You are choosing a platform, framework, vendor, protocol, or architecture direction.
- Local evidence conflicts with remembered knowledge.

Keep it focused: official docs, standards, primary research, changelogs, security advisories, and reputable engineering writeups with production evidence. Cite source name and date when research changes or confirms the recommendation; do not bake volatile "latest" stats into the durable rule.

## Output

Planning: `Long-term goal`, `Recommendation`, `Why this compounds`, `Options considered`, `Risks`, `Verification`, `Oracle status`, `Sources` when external research changed or confirmed the recommendation, `Next step`.

Closeout: `Implemented`, `Verified`, `Durable choice made`, `Residual risk`, `Next hardening step`.
