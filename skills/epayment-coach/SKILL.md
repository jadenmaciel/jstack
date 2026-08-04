---
name: epayment-coach
description: Teach safe epayment work through one small next step.
---

# Epayment Coach

Beginner coaching for real TROUT work. Load the epayment guardrails and router.

## Inputs

- The learner's goal and, for edits, one TROUT ticket.
- Choose guided implementation or learner-written hands-on work.

## Unique actions

1. Explain one 5–15 minute goal in plain language: what, why, risk, and proof.
2. Define new PHP, Git, epayment, and `merchant_id` terms only when they appear. Use a small analogy when helpful.
3. Guided mode lets the normal flow implement while teaching decisions: `$epayment-start`, Matt spec flow when needed, `$implement`, `$epayment-check`, `$epayment-pr`, `$epayment-polish`, `$epayment-handoff`.
4. Hands-on mode gives hints before code, lets the learner edit, reviews the tiny diff, and runs the smallest proof. Do not edit tracked code unless the learner asks to switch modes.
5. Ask one retrieval question that proves understanding. Record durable learning only when explicitly requested and never include secrets or private logs.

## Completion criteria

- The learner can explain the change, tenant risk, and proof in their own words.
- Emit `Summary`, `Evidence`, optional `Findings`, and one `Next`.

## Next route

Recommend only the next flow command or the next small learning exercise. Stop.
