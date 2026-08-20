---
name: payday
description: >-
  Use when the user says payday, wants a Payday Sweep or paycheck allocation,
  shares a pay stub, or asks what to do with a paycheck that just posted
  (semi-monthly, 1st and 16th).
---

# Payday

Payday Sweep: posted money only → protect → gates → surplus. You plan and report; the user moves the money.

## Hard rules (only three)

- No transfers, payments, card extras, or Monarch edits without the user's explicit **yes** in chat. Preview, then wait.
- Never type passwords. If Monarch or a portal shows a login page, ask the user to sign in in that tab, then continue.
- Never open `/Users/testadmin/Personal-Secure`.

## Where things are

Notion is the system of record. The Obsidian vault is retired (read-only backup) but still the fullest reference — read it, write to Notion.

| Need | Look here |
|---|---|
| Latest paycheck | 1. Attached to chat (PDF, image, or pasted numbers). 2. Mac: `~/Downloads/paycheck-*.pdf` (Paychex stub, ExpiTrans Inc.), `/Users/testadmin/Documents/Personal/01_Finance/Statements 2026/paystub-*.pdf`, else the newest PDF in `~/Downloads`. 3. Notion: search `Paycheck Actuals`, `paycheck stub`. 4. Ask for the stub, or just net + check date. |
| Live balances, transactions, bills due, budget | Monarch in Chrome (next section) |
| Rules: Payday Sweep, gates, Debt Attack order, protected cash | Notion pages **CONTEXT**, **Monthly Operating Budget**, newest **Payday Sweep Spec** (Aug-15 import). Same text in the vault: `/Users/testadmin/Documents/Vault/Atlas/Finance/CONTEXT.md`, `Efforts/Finance/Monarch/`. Newest wins. |
| Current goal + next action | Notion Vault → System → Projects → 🔥 **Debt Attack** (Area: Finance) |
| Portal URLs, account map (last 4s), due dates/autopay, APRs + promo ends, 605 lease facts, Zelle/people map, Monarch conventions | Notion **Finance Reference — Portals, Accounts & Rules** (under Debt Attack). Read it before opening any portal; update it when a date or rule changes. Current payoff order lives in **Debt Attack Payoff Plan YYYY-MM-DD** (newest). |
| Monarch CSV exports (optional) | `/Users/testadmin/Documents/Personal/01_Finance/Monarch/` |

## Monarch in Chrome (read-only)

1. Claude Code: load the tools once — `ToolSearch select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__tabs_close_mcp`. Cursor: use its browser tool.
2. `tabs_context_mcp` → `tabs_create_mcp` → `navigate` to `https://app.monarch.com/accounts`. Screenshot; if it is the sign-in page, hand it to the user.
3. Read with screenshot + `get_page_text` / `read_page`: **Accounts** (checking, Marcus …1374, card balances), **Transactions** (did the paycheck post — amount, date), **Recurring** (bills and minimums due before next payday), **Plan** (budget vs actual; `Debt Payoff` is the surplus line, not Pay Down), **Cash Flow**.
4. Close the tabs you opened.

## Steps

1. **Paycheck.** Find it (table order). Usable only once it *posted* — stub check date plus the Monarch transaction. Not posted → say what is expected and stop.
2. **Ask once:** "Any out-of-the-ordinary expenses before next payday? Amount and date." Fold each yes into Protect; "none" is an answer.
3. **Allocate the posted net, in this order:**
   1. Bills and card minimums due before next payday
   2. Protected: dental, insurance, family auto (full $451; count father's $250 only after it arrives), rent, school
   3. Move Ready + $2,500 Starter Reserve (Marcus …1374, not the joint HYSA)
   4. Keep a $500 checking floor; the rest is surplus → highest-APR card (a 0% promo ending before next payday ranks at its post-promo APR). Move Ready and the School-Funding Gate are tracked, not blocking (CONTEXT, Jul 20 rule).
   Minimums stay on autopay, extras are manual. Count nothing before it posts (OT, reimbursement, bonus, aid). Reimbursements refill the expense they covered. Real trade-off (same dollars twice, skipping a protect line, raiding reserve)? Ask one question at a time until settled.
4. **Report** (below), then file it in Notion: new page `Payday Sweep YYYY-MM-DD` under 🔥 Debt Attack (or wherever the user says), a `Paycheck Actuals YYYY-MM-DD` page when a stub was read (pay period, hours, rate, gross, withholdings, net, YTD, source file), and update Debt Attack **Next Action**. Monarch Plan changes go in the report as current → proposed (delta); the user applies them.

## Report

```markdown
# Payday Sweep — YYYY-MM-DD
Posted net $X (source) · Monarch checked YYYY-MM-DD · Next payday YYYY-MM-DD
Out-of-ordinary: none | list
## Protect — bills, minimums, protected lines (amount, due date)
## Reserves / gates — Move Ready, Starter Reserve, School-Funding (open/closed, gap)
## Surplus — $Y → target | HOLD (open gate)
## Needs your yes — transfers, payments, card extras, Monarch edits (none done)
## Open questions
```

Lighter asks: "capture the stub" → step 1 + Paycheck Actuals page; "what's due before payday" → Monarch Recurring + Accounts only.
