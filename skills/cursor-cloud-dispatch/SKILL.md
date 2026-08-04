---
name: cursor-cloud-dispatch
description: Dispatch and supervise bounded Cursor Cloud work. Use when the user asks Codex to send prompts or tasks to Cursor Cloud agents, run cloud agents against a repository, monitor or follow up with those agents, or have Cursor open draft pull requests.
---

# Cursor Cloud Dispatch

Run Cursor Cloud as a supervised worker: bound the task, launch it, verify the run, and stay with it through a report or draft PR.

## 1. Set the envelope

Resolve from the request and live repository state:

- repository and base branch;
- one concrete outcome per run;
- model choice and whether Auto fallback is allowed;
- mutation, draft-PR, AWS, production, ticket, and merge authority;
- repository instructions, verification commands, protected paths, and the live cap on open `cursor/*` PRs.

Use read-only inspection to fill missing facts. Ask only when a missing choice would materially change authority or scope. The envelope is complete when every item above has an explicit value.

## 2. Write a bounded prompt

Give each agent one root outcome. Include:

1. Start from the named base in a fresh isolated cloud branch.
2. Trace the relevant flow before editing; for a defect, prove the root cause with a failing test first.
3. Make the smallest change that satisfies the outcome and preserve meaningful assertions.
4. Run the repository's narrow check, then its canonical full check.
5. Count open `cursor/*` PRs before mutation. At the cap, switch to report-only with no edits, commits, pushes, tickets, or PRs.
6. Below the cap, permit at most one draft PR to the named base when verification passes. If evidence or checks fail, report instead.
7. Restate hard boundaries: no merge or readiness change; no protected-ref, guardrail, workflow, secret, production-log, deployment, paid-overage, AWS, or ticket action unless the envelope explicitly grants it.
8. Require a concise result with evidence, commands run, branch, and PR URL or the exact blocker.

For independent outcomes, launch separate runs. Keep overlapping writers out of the same files unless the user explicitly accepts conflict risk.

## 3. Stage Cursor Cloud

Use the explicitly requested Cursor surface. Otherwise prefer the signed-in Cursor agents web UI because it exposes repository, branch, multi-model, and run status in one place. Follow the applicable browser or computer-use skill.

Select the repository and base, then honor any explicitly requested model set. On this machine, use Cursor Auto by default, including when usage limits force a fallback, unless the user explicitly prohibits Auto. Keep long-running Preview off unless it is both available and requested.

Stage the entire batch before submission. Immediately before the first external submission, obtain one action-time confirmation covering the batch unless the user already confirmed after seeing its exact repository, scope, model, and authority.

## 4. Launch and prove

Submit one prompt per run. A launch is proven only when Cursor shows a new run URL and a running or queued status with the intended repository and model mode. Record every URL. Retry only an unsubmitted prompt; never duplicate a run whose URL already exists.

Report the run names, URLs, model mode, PR authority, and any fallback Cursor applied. This step is complete when every intended run has a unique verified URL or a concrete launch error.

## 5. Supervise

Inspect live runs while useful local work proceeds. Use the product's wait or monitoring mechanism when available; otherwise poll at phase boundaries without a tight loop.

Intervene only when a run:

- asks for information already available in the repository or envelope;
- drifts outside its outcome or authority;
- is blocked by a recoverable command, environment, or verification issue;
- finishes with an unproven claim or incomplete result.

Send the smallest corrective follow-up and preserve the original envelope. Obtain action-time confirmation for follow-up messages unless the user pre-authorized supervision and messaging for these exact runs.

When a run finishes, verify its claimed branch or PR with read-only GitHub state when available. Confirm the PR is draft, targets the intended base, stays under the live cap, and does not touch protected paths. Treat Cursor output as evidence, not proof.

Archive completed chats only when the user requests it. Supervision is complete when every run is finished, intentionally left running with a reported status, or blocked on a named human action.
