---
name: net-working-capital-software
description: >
  Driver map for the NET WORKING CAPITAL section of a software / technology
  operating model. Read inline by `net-working-capital/net-working-capital.md` at
  its §1.5 when the orchestrator's industry determination is software. Names, for
  each current operating line a software issuer carries, the driver (DSO / DPO / %
  of a base / held flat), the exact upstream row it divides by — `Total Revenue`,
  `Total Costs and Expenses`, the cost build's `Total cost of revenue` — the
  row-presence fallback, and the convention. Payables are driven on total costs, not
  cost of revenue, because a software company's trade payables are mostly operating
  vendors; deferred revenue is the defining line. A component, not a route; it lays
  no rows itself.
---

# net working capital — software / technology (driver map)

**What this file is.** A **driver map**, not a build and not a route. The net
working capital builder (`../net-working-capital.md`) lays every row and formula;
this file tells it, for a software issuer, **which current operating lines to expect
beyond the generic placeholders, which driver each line takes, which upstream row
that driver divides by, what to do when that row is absent, and why** — the
convention an analyst expects for this industry. The builder reads this file
**inline at its §1.5**, when it needs the driver bases, and nowhere earlier (a
sibling import, which the orchestrator's GOLDEN RULE 1 permits at that point). The
orchestrator selected this map from the industry it classified once at its Step 1.2;
this file never re-classifies.

**Every base row named below is a row an earlier section already laid** — the
software cost build (`../../costs/software/`), the revenue build, or the location
build. The builder references those cells by label; it never re-pulls a flow or
re-derives a count. Where a base row may be absent, the fallback is a **row-presence
test** with a stated default — never a question to the user.

**Two caveats every driver on `Total Costs and Expenses` carries.** That contract row
is the all-in total between revenue and operating income, so it **includes
depreciation and amortization**, a non-cash charge nobody is owed. A payable, accrual
or prepaid struck on it is on a base a few percent too large. This is accepted: the
driver is a ratio, the ratio is stable, and the clean alternative (a cash-costs row
laid by every cost build) is not in place; the cell comment says so. A charge the cost
build carries at **zero** forward (an impairment, a write-down, a one-off) is not
accepted in the base: where the hand-back lists one, every base this map names as
`Total Costs and Expenses` is the builder's `Total Costs and Expenses (recurring)`
row instead (builder §1.5), so the ratio stands on the costs the model carries
forward. Second, the
driver is a **period-end balance over an annual flow** with a 365-day year — the
standard model simplification; average balances are an analyst refinement this
build does not make.

## Section 1 — Lines a software issuer typically carries

Beyond the builder's generic placeholders (§1.1), expect the classes below. The
`Line` column is the class the builder's driver table keys on; the sheet label is the
issuer's own caption (the builder's §1.1).

| Line | Side | Typical captions | Notes |
|---|---|---|---|
| `Accounts Receivables` | asset | `Accounts receivable, net` | Invoiced subscriptions and usage; the largest current operating asset. |
| `Prepaid Expenses` | asset | `Prepaid expenses and other current assets` | Often bundled with other current assets; carry the reported line. |
| `Deferred Contract Costs` (optional) | asset | `Deferred commissions, current`, `Contract acquisition costs, current` | Capitalized sales commissions, current slice. Carry only if reported as a current line. |
| `Inventory` | asset | `Inventories` | Usually absent; present for hardware-attached issuers. |
| `Accrued Compensation` | liability | `Accrued compensation and benefits`, `Accrued payroll` | Frequently broken out of accrued liabilities; never carried twice (builder §1.3). |
| `Deferred Revenue` | liability | `Deferred revenue, current`, `Unearned revenue`, `Contract liabilities` | Prepaid subscriptions not yet recognized — the defining working-capital line of a subscription business; current portion only. **When it is not a face line** but the inventory carries a current deferred-revenue series disclosed in a note, lay it anyway, as its own row from that series, and lay the accrual face line it sits inside as a plain input `<face line> (reported)` with a remainder row `<face line> — other` `= reported − Deferred Revenue` beneath it; the remainder takes the accrual driver below. The split holds only while the remainder is non-negative in every historical year — a negative remainder means the series is on a wider basis or another vintage than the face line, and then the face line is carried whole, its composition named in the cell comment, and one Notes line added: "Net Working Capital: <face line> includes current deferred revenue of about <amount>; it is carried whole because the note's figure does not reconcile to the face line." |
| `Operating Lease Liabilities` (current) | liability | `Operating lease liabilities, current` | Offices; no location build exists for software, so this line uses the builder's cost-based fallback. |

A subscription business is paid in advance, so deferred revenue typically exceeds
receivables and **net working capital is normally negative**; a usage-billed or
enterprise-license issuer with long collection terms can run it positive.

## Section 2 — The driver table

Driver kinds are the builder's (§2.2 / §3.2); this table supplies the **base** and
the **fallback**. The software cost build lays fixed labels for its two subtotals,
`Total cost of revenue` and `Total operating expenses`, beneath its stream-level
cost rows, and the contract row `Total Costs and Expenses` as their sum.

| Line | Driver | Base row (exact label as laid) | If the base row is absent | Convention and reason |
|---|---|---|---|---|
| `Accounts Receivables` | DSO (days) | `Total Revenue` | — | Days of revenue outstanding. The core collections metric. |
| `Inventory` (if present) | DIO (days) | `Total cost of revenue` | `Total Costs and Expenses`, noted | Hardware-attached issuers only. |
| `Prepaid Expenses` | % of base | `Total Costs and Expenses` | — | Prepaid hosting, software and insurance scale with spending. D&A caveat above. |
| `Deferred Contract Costs` (optional) | % of base | `Total Costs and Expenses` | — | Capitalized commissions move with selling spend; total costs is the available base, noted as a simplification. |
| `Income Tax Receivables` | held flat | — | — | No tax line in the model. |
| `Accounts Payable` | DPO (days) | `Total Costs and Expenses` | — | Days of operating spend unpaid. **Not** cost of revenue: for a software company cost of revenue is a small slice of spend (hosting, support) and trade payables are mostly marketing, G&A and R&D vendors, so days on cost of revenue would be inflated and would scale payables with the wrong flow. The base includes D&A — caveat above. |
| `Operating Lease Liabilities` (current) | % of base | `Total Costs and Expenses` | — | The builder's fallback, by design: no location build, so no per-unit count. |
| `Accrued Expenses` / `Accrued Compensation` / `<face line> — other` | % of base | `Total Costs and Expenses` | — | Accrued compensation is the bulk of it and scales with headcount spend; total costs is the available base. Accrued compensation disclosed only inside the face line is **not** split out: it sits on the face line's own base, so a split changes no forecast. |
| `Deferred Revenue` (current) | % of base | `Total Revenue` | — | Prepaid subscriptions scale with revenue; a share of annual revenue is equivalent to days of revenue (× 365) and reads the same way analysts quote it. A share of the recurring stream alone would be the sharper base; it is not used because the revenue build identifies the recurring stream by comment and memo, not by a fixed row — a refinement to make when that row is a contract. |
| `Income Tax Payable` | held flat | — | — | As the receivable. |
| `Customer Deposit` (if present) | % of base | `Total Revenue` | — | Deposits track billings. |
| any added line | the analogous kind | the analogous base | — | Receivable-like → DSO on revenue; payable- or accrual-like → % of or days of total costs; revenue-linked → % of revenue. Say which in the comment. |

**Tags.** `(% of total costs)`, `(% of total revenue)`, `(days)`. No per-location
tag appears in a software build.

## Section 3 — Worked example (illustrative): a subscription software issuer

A single fiscal year, USD in millions; figures illustrative. Upstream rows:
`Total Revenue` 2,500; `Total cost of revenue` 450; `Total Costs and Expenses`
2,100. No location build exists.

```
  Current Operating Assets
  Accounts Receivables                                          60.0  (USD in millions)            [input]
  Prepaid Expenses                                             110.0  (USD in millions)            [input]
  Income Tax Receivables                                         5.0  (USD in millions)            [input]
  Total Current Operating Assets                               175.0  (USD in millions)            [= SUM(above) ← sum bar]

  Current Operating Assets — Drivers
  Accounts Receivables — DSO                                     8.8  (days)                       [= 60.0 ÷ 2,500 × 365]
  Prepaid Expenses — % of Total Costs                           5.2%  (% of total costs)           [= 110.0 ÷ 2,100]
  (Income Tax Receivables: no driver row — held flat forward)

  Current Operating Liabilities
  Accounts Payable                                              40.0  (USD in millions)            [input]
  Operating Lease Liabilities                                   70.0  (USD in millions)            [input — current portion]
  Accrued Compensation                                         180.0  (USD in millions)            [input]
  Deferred Revenue                                             720.0  (USD in millions)            [input — current portion]
  Income Tax Payable                                            15.0  (USD in millions)            [input]
  Total Current Operating Liabilities                        1,025.0  (USD in millions)            [= SUM(above) ← sum bar]

  Current Operating Liabilities — Drivers
  Accounts Payable — DPO                                         7.0  (days)                       [= 40.0 ÷ 2,100 × 365]
  Operating Lease Liabilities — % of Total Costs                3.3%  (% of total costs)           [= 70.0 ÷ 2,100; no location build]
  Accrued Compensation — % of Total Costs                       8.6%  (% of total costs)           [= 180.0 ÷ 2,100]
  Deferred Revenue — % of Revenue                              28.8%  (% of total revenue)         [= 720.0 ÷ 2,500 — about 105 days of revenue]
  (Income Tax Payable: no driver row — held flat forward)

  Net Working Capital
  Net Working Capital (NWC)                                  (850.0)  (USD in millions)            [= 175.0 − 1,025.0 ← sum bar; NEGATIVE (normal for prepaid subscriptions)]
  Change in NWC                                               (60.0)  (USD in millions)            [= (850.0) − (790.0 prior year)]
```

**Projection mechanics.** As in the restaurant map's illustration: each red driver is
the latest year (or the guided value) held flat; `Accounts Receivables = DSO ÷ 365 × Total
Revenue`, `Accounts Payable = DPO ÷ 365 × Total Costs and Expenses`, `Deferred
Revenue = % × Total Revenue`; the tax balances carry their year-N value as the red
`N+1` driver. Because deferred revenue is the largest line and scales with revenue,
forward NWC becomes **more negative as revenue grows** — the cash-generative shape
of a prepaid subscription model, and expected.

## Section 4 — Sane ranges and checks (software)

- `DSO` tens of days for enterprise billers, single digits for consumer or
  self-serve; `Deferred Revenue — % of Revenue` tens of percent for annual-prepaid
  subscription models (several months of revenue), low single digits for
  usage-billed or advertising-funded issuers; `DPO` on total costs single digits to
  low tens of days.
- Net working capital **negative** for prepaid subscription issuers and growing more
  negative with revenue; positive for usage-billed or license issuers with long
  collection terms — say which the issuer is in one Notes line: "Net Working Capital:
  negative, as customers prepay subscriptions." or "Net Working Capital: positive;
  billing is in arrears with long collection terms."
- No per-location row appears; the lease line used the cost-based fallback and its
  comment says so.
- `Accrued Compensation` and `Accrued Expenses` are not both carried for the same
  dollars.

## Notes

- This map adds no deepKPI calls; the builder pulls balances from the shared inventory.
- Adding a software-specific line later means one row in §2's table, nothing in the
  builder.
