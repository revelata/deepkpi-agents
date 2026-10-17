---
name: net-working-capital-restaurants
description: >
  Driver map for the NET WORKING CAPITAL section of a restaurant operating model.
  Read inline by `net-working-capital/net-working-capital.md` at its §1.5 when the
  orchestrator's industry determination is restaurant. Names, for each current
  operating line a restaurant issuer carries, the driver (DSO / DIO / DPO / % of a
  base / per location / held flat), the exact upstream row it divides by — the cost
  build's food-beverage-and-packaging and labor lines, `Total Costs and Expenses`,
  `Total Revenue`, `Revenue from Franchises`, the location build's
  `Company-Operated EOP Balance` — the row-presence fallback, and the convention.
  A component, not a route; it lays no rows itself.
---

# net working capital — restaurants (driver map)

**What this file is.** A **driver map**, not a build and not a route. The net
working capital builder (`../net-working-capital.md`) lays every row and formula;
this file tells it, for a restaurant issuer, **which current operating lines to expect
beyond the generic placeholders, which driver each line takes, which upstream row
that driver divides by, what to do when that row is absent, and why** — the
convention an analyst expects for this industry. The builder reads this file
**inline at its §1.5**, when it needs the driver bases, and nowhere earlier (a
sibling import, which the orchestrator's GOLDEN RULE 1 permits at that point). The
orchestrator selected this map from the industry it classified once at its Step 1.2;
this file never re-classifies.

**Every base row named below is a row an earlier section already laid** — the
restaurant cost build (`../../costs/restaurants/`), the revenue build, or the location
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

## Section 1 — Lines a restaurant issuer typically carries

Beyond the generic placeholders the builder lists in its §1.1 (receivables,
inventory, prepaids, income-tax balances, payables, current operating leases,
accrued expenses, deferred revenue, wages payable, customer deposits), expect the
classes below. The `Line` column is the class the builder's driver table keys on; the
sheet label is the issuer's own caption (the builder's §1.1).

| Line | Side | Typical captions | Notes |
|---|---|---|---|
| `Restaurant Supplies` | asset | `Restaurant supplies`, `Supplies` | Smallwares and consumables; carried only if reported separately from inventory. |
| `Deferred Revenue` | liability | `Gift card liability`, `Unearned revenue`, `Deferred revenue` | Gift cards dominate; current portion only. |
| `Deferred Franchise Fees` | liability | `Deferred franchise fees, current`, `Contract liabilities, current` | Franchisors only; the current slice of initial and renewal fees recognized over the franchise term. Optional — carry it only if reported as a current line. |
| `Accrued Payroll` / `Wages Payable` | liability | `Accrued payroll and benefits`, `Salaries and wages payable` | Labor is the largest cash cost; many issuers break it out of accrued liabilities. Never carry it twice (builder §1.3). |

A restaurant operator collects cash at the point of sale, holds a few days of
perishable inventory and pays suppliers, landlords and staff on terms, so **net
working capital is normally negative**. Treat a positive NWC as a signal to re-check
classification, not as an error.

## Section 2 — The driver table

Driver kinds are the builder's (§2.2 / §3.2); this table supplies the **base** and
the **fallback**. "Cost-of-sales line" means the food, beverage and packaging line
under the issuer's own caption (`Food, beverage and packaging`, `Food and paper`,
`Food and beverage costs`): where the cost build lays a cost-of-sales face line as
component lines, the food component; where it lays only the face line (`Cost of
sales`), that face line. The driver's comment names the row taken. "Labor line" means the cost build's restaurant-labor line
(`Labor`, `Restaurant labor`, `Labor and benefits`).

| Line | Driver | Base row (exact label as laid) | If the base row is absent | Convention and reason |
|---|---|---|---|---|
| `Accounts Receivables` | DSO (days) | `Total Revenue` | — (always laid) | Days of sales outstanding on revenue. Low for a cash business. |
| `Inventory` | DIO (days) | the cost-of-sales line | `Total Costs and Expenses`, noted | Days of food cost on hand; low single digits for perishables. |
| `Restaurant Supplies` | DIO (days) | the cost-of-sales line | as above | Same base as inventory. |
| `Prepaid Expenses` | % of base | `Total Costs and Expenses` | — | Prepaids scale with spending. Base includes D&A — caveat above. |
| `Income Tax Receivables` | held flat | — | — | No tax line in the model (it stops at EBITDA); hold at year N. |
| `Accounts Payable` | DPO (days) | the cost-of-sales line | `Total Costs and Expenses`, noted | Days of purchases unpaid; a restaurant's trade payables are overwhelmingly food and packaging suppliers. Same base as DIO, as analysts expect. |
| `Operating Lease Liabilities` (current) | per location | location build → `Company-Operated EOP Balance` (Total block) | `% of Total Costs and Expenses`, noted | Rent obligation scales with the company-operated fleet. Most analysts hold this line flat or exclude operating leases from working capital; this model keeps the current portion and drives it per unit so it moves with openings. |
| `Accrued Expenses` | % of base | `Total Costs and Expenses` | — | Accruals scale with spending. D&A caveat. |
| `Deferred Revenue` (gift cards) | % of base | `Total Revenue` | — | Gift-card sales track sales. |
| `Deferred Franchise Fees` (optional) | % of base | `Revenue from Franchises` | `Total Revenue`, noted | Fees deferred scale with franchise activity; the franchise block lays the base row whenever franchise revenue is reported. |
| `Income Tax Payable` | held flat | — | — | As the receivable. |
| `Wages Payable` / `Accrued Payroll` | % of base | the labor line | `Total Costs and Expenses`, noted as a fallback | Unpaid wages are a share of payroll — the convention for a labor-heavy operator. Only if the issuer breaks it out of accrued liabilities. |
| `Customer Deposit` | % of base | `Total Revenue` | — | Deposits track sales. |
| any added line | the analogous kind | the analogous base | — | Receivable-like → DSO on revenue; inventory-like → DIO on cost of sales; payable-like → DPO on cost of sales; accrual-like → % of total costs; revenue-linked → % of revenue. Say which in the comment. |

**Tags.** Each percent driver's Col D tag names its base: `(% of total costs)`,
`(% of total revenue)`, `(% of franchise revenue)`, `(% of restaurant labor)`. Days
drivers are `(days)`; the per-location driver is `(USD thousands per location)`.

## Section 3 — Worked example (illustrative): a restaurant operator

A single fiscal year, USD in millions; figures illustrative — the real build references
the cells and pulls every balance from deepKPI. Upstream rows: `Total Revenue`
11,000; cost-of-sales line 3,500; labor line 3,300; `Total Costs and Expenses` 9,250;
`Company-Operated EOP Balance` 3,700.

```
  Current Operating Assets
  Accounts Receivables                                         120.0  (USD in millions)            [input]
  Inventory                                                     35.0  (USD in millions)            [input]
  Prepaid Expenses                                              60.0  (USD in millions)            [input]
  Income Tax Receivables                                        15.0  (USD in millions)            [input]
  Restaurant Supplies                                           25.0  (USD in millions)            [input]
  Total Current Operating Assets                               255.0  (USD in millions)            [= SUM(above) ← sum bar]

  Current Operating Assets — Drivers
  Accounts Receivables — DSO                                     4.0  (days)                       [= 120.0 ÷ 11,000 × 365]
  Inventory — DIO                                                3.7  (days)                       [= 35.0 ÷ 3,500 × 365]
  Prepaid Expenses — % of Total Costs                           0.6%  (% of total costs)           [= 60.0 ÷ 9,250]
  Restaurant Supplies — DIO                                      2.6  (days)                       [= 25.0 ÷ 3,500 × 365]
  (Income Tax Receivables: no driver row — held flat forward)

  Current Operating Liabilities
  Accounts Payable                                             180.0  (USD in millions)            [input]
  Operating Lease Liabilities                                  220.0  (USD in millions)            [input — current portion]
  Accrued Expenses                                             150.0  (USD in millions)            [input]
  Deferred Revenue                                             140.0  (USD in millions)            [input — gift card liability]
  Income Tax Payable                                            20.0  (USD in millions)            [input]
  Wages Payable                                                 90.0  (USD in millions)            [input]
  Customer Deposit                                              10.0  (USD in millions)            [input]
  Total Current Operating Liabilities                          810.0  (USD in millions)            [= SUM(above) ← sum bar]

  Current Operating Liabilities — Drivers
  Accounts Payable — DPO                                        18.8  (days)                       [= 180.0 ÷ 3,500 × 365]
  Operating Lease Liabilities — per Company-Operated Location   59.5  (USD thousands per location) [= 220.0 ÷ 3,700 = 0.0595 million, shown in USD thousands]
  Accrued Expenses — % of Total Costs                           1.6%  (% of total costs)           [= 150.0 ÷ 9,250]
  Deferred Revenue — % of Revenue                               1.3%  (% of total revenue)         [= 140.0 ÷ 11,000]
  Wages Payable — % of Restaurant Labor                         2.7%  (% of restaurant labor)      [= 90.0 ÷ 3,300]
  Customer Deposit — % of Revenue                               0.1%  (% of total revenue)         [= 10.0 ÷ 11,000]
  (Income Tax Payable: no driver row — held flat forward)

  Net Working Capital
  Net Working Capital (NWC)                                  (555.0)  (USD in millions)            [= 255.0 − 810.0 ← sum bar; NEGATIVE (normal)]
  Change in NWC                                               (40.0)  (USD in millions)            [= (555.0) − (515.0 prior year)]
```

> **A declared coherence departure.** `Operating Lease Liabilities — per Company-Operated
> Location` displays in **USD thousands per location** (59.5) although liabilities are in
> millions and the location count in ones (220.0 ÷ 3,700 = 0.0595 million). Rescaling the
> count to thousands would break the count family the location build uses everywhere
> else, and 0.0595 reads badly, so the conventional display wins and the row's Col C
> comment records it, per the units contract's Rule 2 coherence test.

**Projection mechanics (continuing the same company).** Suppose the upstream builds
project, for `N+1`, `Total Revenue = 11,600`, the cost-of-sales line `= 3,700`,
`Total Costs and Expenses = 9,750`, labor `= 3,480`, and a company-owned count of
`3,850`. Three drivers whose three most recent historical years read `DSO 3.8 / 3.9 /
4.0`, `DPO 18.6 / 18.7 / 18.8` and `Wages Payable 2.6% / 2.7% / 2.7%`, with no
guidance naming any of them and no one-off disclosed in the balances:

```
                                        N+1                                       N+2
  DRIVERS (red)
  Accounts Receivables — DSO            4.0   = latest year (IF(ISNUMBER(N),N,…))          4.0   = <N+1 cell>  (held flat)
  Accounts Payable — DPO               18.8   = latest year                                 18.8   = <N+1 cell>
  Wages Payable — % of Restaurant Labor 2.7%  = latest year                                 2.7%   = <N+1 cell>
  Income Tax Payable (N+1 cell)        20.0   = <year N value>  (red driver, held flat)    20.0   = <N+1 cell>

  VALUES (black formulas — driver inverted against its forward base)
  Accounts Receivables               127.1   = 4.0 ÷ 365 × 11,600
  Accounts Payable                   190.6   = 18.8 ÷ 365 × 3,700
  Wages Payable                       94.0   = 2.7% × 3,480   (the stored ratio, not the display rounding)
  Income Tax Payable                  20.0   = <the N+1 driver cell>
```

## Section 4 — Sane ranges and checks (restaurants)

- `DSO` low single digits of days; `DIO` low single digits; `DPO` on food cost in the
  teens to low twenties of days; `Wages Payable — % of Restaurant Labor` low single
  digits percent. A `DPO` in the single digits usually means the base was struck on
  total costs rather than the cost-of-sales line — fix the base, not the value.
- Net working capital **negative** and stable in scale year to year; a sign flip is a
  classification error until proven otherwise.
- Every base row named in §2 exists on the sheet under the label the cost build,
  revenue build or location build laid; each absence used its stated fallback, and
  the cell comment says so.
- Every franchise-related line (deferred franchise fees) references `Revenue from
  Franchises` only when the franchise block laid it.

## Notes

- This map adds no deepKPI calls: the builder pulls balances from the shared inventory
  (its §1.1 / §1.4); the bases are rows already on the sheet.
- Adding a restaurant-specific line later means one row in §2's table, nothing in the
  builder.
