---
name: net-working-capital-retail
description: >
  Driver map for the NET WORKING CAPITAL section of a retail operating model. Read
  inline by `net-working-capital/net-working-capital.md` at its §1.5 when the
  orchestrator's industry determination is retail. Names, for each current operating
  line a retailer carries, the driver (DSO / DIO / DPO / % of a base / per location /
  held flat), the exact upstream row it divides by — the cost build's cost-of-sales
  line, `Total Costs and Expenses`, the revenue build's `Net Sales` or
  `Total Revenue`, the location build's `Company-Operated EOP Balance` — the
  row-presence fallback, and the convention. Handles the combined
  "accounts payable and accrued liabilities" caption many retailers report. A
  component, not a route; it lays no rows itself.
---

# net working capital — retail (driver map)

**What this file is.** A **driver map**, not a build and not a route. The net
working capital builder (`../net-working-capital.md`) lays every row and formula;
this file tells it, for a retail issuer, **which current operating lines to expect
beyond the generic placeholders, which driver each line takes, which upstream row
that driver divides by, what to do when that row is absent, and why** — the
convention an analyst expects for this industry. The builder reads this file
**inline at its §1.5**, when it needs the driver bases, and nowhere earlier (a
sibling import, which the orchestrator's GOLDEN RULE 1 permits at that point). The
orchestrator selected this map from the industry it classified once at its Step 1.2;
this file never re-classifies.

**Every base row named below is a row an earlier section already laid** — the
retail cost build (`../../costs/retail/`), the revenue build, or the location
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

## Section 1 — Lines a retailer typically carries

Beyond the builder's generic placeholders (§1.1), expect the classes below. The
`Line` column is the class the builder's driver table keys on; the sheet label is the
issuer's own caption (the builder's §1.1).

| Line | Side | Typical captions | Notes |
|---|---|---|---|
| `Inventory` | asset | `Merchandise inventories`, `Inventories` | The largest current operating asset for every merchandise retailer; always present. |
| `Accounts Receivables` | asset | `Receivables, net`, `Accounts receivable` | Small for store retailers (card settlements, vendor allowances); larger where wholesale or a credit program exists. |
| `Accounts Payable` | liability | `Merchandise accounts payable`, `Accounts payable` | The merchandise payables line, where the issuer reports one — the line DPO is struck on. |
| `Accounts Payable and Accrued Liabilities` | liability | `Accounts payable and accrued liabilities` | Many retailers report **one combined line** and no separate merchandise payables. Then carry it as **one row** and drive it as DPO on the cost-of-sales line, since merchandise payables dominate it; never also carry an `Accrued Expenses` row for dollars already inside it (builder §1.3). Where the issuer reports **merchandise payables as its own line** beside a combined line, the merchandise line is `Accounts Payable` above and the combined line is the **accruals** line, driven as `Accrued Expenses` below; the gift-card and current lease amounts disclosed inside it stay inside it. |
| `Deferred Revenue` | liability | `Gift card liability`, `Deferred revenue`, `Loyalty program liability` | Gift cards and loyalty points; current portion only. |
| `Customer Deposit` | liability | `Customer deposits`, `Layaway deposits` | Where reported. |

Merchandise retailers hold weeks of inventory and finance part of it with supplier
credit, so **net working capital is normally positive** (inventory exceeds payables);
a club or grocery operator with fast turns can run it near zero or negative.

## Section 2 — The driver table

Driver kinds are the builder's (§2.2 / §3.2); this table supplies the **base** and
the **fallback**. "Cost-of-sales line" means the first additive line of the retail
cost build's walkdown, under the issuer's own caption (`Cost of sales`, `Cost of
sales, including buying and occupancy costs`, `Cost of goods sold`, `Cost of
merchandise sold`). Where that caption includes buying, distribution or occupancy
costs, the base is the reported line as laid — analysts strike days of inventory and
payables on the reported cost of sales, and the comment notes what it includes.
"Sales row" means the revenue build's **`Net Sales`** row where it laid one (the
issuer reports a separate revenue face line), else **`Total Revenue`** — the same
presence test the retail cost build applies.

| Line | Driver | Base row (exact label as laid) | If the base row is absent | Convention and reason |
|---|---|---|---|---|
| `Accounts Receivables` | DSO (days) | `Total Revenue` | — | Days of sales outstanding on all revenue (card and credit receivables arise on every sale). |
| `Inventory` | DIO (days) | the cost-of-sales line | `Total Costs and Expenses`, noted | Days of merchandise on hand — the retailer's defining working-capital metric. |
| `Prepaid Expenses` | % of base | `Total Costs and Expenses` | — | Prepaids scale with spending. D&A caveat above. |
| `Income Tax Receivables` | held flat | — | — | No tax line in the model. |
| `Accounts Payable` (or the combined payables-and-accruals line when no separate merchandise payables line exists) | DPO (days) | the cost-of-sales line | `Total Costs and Expenses`, noted | Days of merchandise purchases unpaid. Same base as DIO, so days payable and days inventory read against each other. |
| `Operating Lease Liabilities` (current) | per location | location build → `Company-Operated EOP Balance` (Total block) | `% of Total Costs and Expenses`, noted | Rent scales with the company-operated store base; see the restaurant map's note on analyst practice. |
| `Accrued Expenses` (only when reported separately from payables, including a combined payables-and-accruals line that sits beside a separate merchandise payables line) | % of base | `Total Costs and Expenses` | — | Accruals scale with spending. D&A caveat. |
| `Deferred Revenue` (gift cards, loyalty) | % of base | the sales row | — | Gift-card and loyalty liabilities track merchandise sales, so net sales where the issuer separates it from fee income. |
| `Income Tax Payable` | held flat | — | — | As the receivable. |
| `Wages Payable` / `Accrued Payroll` | % of base | `Total Costs and Expenses` | — | A **fallback, stated as one**: the convention is a share of labor cost, but the retail cost build lays no labor line (store labor sits inside cost of sales and SG&A), so total costs is the closest base. |
| `Customer Deposit` | % of base | the sales row | — | Deposits track merchandise sales. |
| any added line | the analogous kind | the analogous base | — | Receivable-like → DSO on revenue; inventory-like → DIO on cost of sales; payable-like → DPO on cost of sales; accrual-like → % of total costs; sales-linked → % of the sales row. Say which in the comment. |

**Tags.** `(% of total costs)`, `(% of total revenue)`, `(% of net sales)` — the tag
names the row actually divided by, exactly as the cost build's cost-of-sales tag
does; `(days)`; `(USD thousands per location)`.

## Section 3 — Worked example (illustrative): a discount retailer

A single fiscal year, USD in millions; figures illustrative. The issuer reports a
single revenue line, so the sales row is `Total Revenue`. Upstream rows:
`Total Revenue` 40,000; cost-of-sales line 27,800; `Total Costs and Expenses`
37,800; `Company-Operated EOP Balance` 20,893. The issuer reports `Accounts payable`
and `Accrued expenses and other` separately.

```
  Current Operating Assets
  Accounts Receivables                                         150.0  (USD in millions)            [input]
  Inventory                                                  7,500.0  (USD in millions)            [input]
  Prepaid Expenses                                             300.0  (USD in millions)            [input]
  Income Tax Receivables                                        10.0  (USD in millions)            [input]
  Total Current Operating Assets                             7,960.0  (USD in millions)            [= SUM(above) ← sum bar]

  Current Operating Assets — Drivers
  Accounts Receivables — DSO                                     1.4  (days)                       [= 150.0 ÷ 40,000 × 365]
  Inventory — DIO                                               98.5  (days)                       [= 7,500.0 ÷ 27,800 × 365]
  Prepaid Expenses — % of Total Costs                           0.8%  (% of total costs)           [= 300.0 ÷ 37,800]
  (Income Tax Receivables: no driver row — held flat forward)

  Current Operating Liabilities
  Accounts Payable                                           3,900.0  (USD in millions)            [input]
  Operating Lease Liabilities                                1,400.0  (USD in millions)            [input — current portion]
  Accrued Expenses                                           1,000.0  (USD in millions)            [input]
  Deferred Revenue                                             300.0  (USD in millions)            [input — gift card liability]
  Income Tax Payable                                            80.0  (USD in millions)            [input]
  Total Current Operating Liabilities                        6,680.0  (USD in millions)            [= SUM(above) ← sum bar]

  Current Operating Liabilities — Drivers
  Accounts Payable — DPO                                        51.2  (days)                       [= 3,900.0 ÷ 27,800 × 365]
  Operating Lease Liabilities — per Company-Operated Location   67.0  (USD thousands per location) [= 1,400.0 ÷ 20,893 = 0.0670 million]
  Accrued Expenses — % of Total Costs                           2.6%  (% of total costs)           [= 1,000.0 ÷ 37,800]
  Deferred Revenue — % of Revenue                               0.8%  (% of total revenue)         [= 300.0 ÷ 40,000; sales row = Total Revenue, no Net Sales row]
  (Income Tax Payable: no driver row — held flat forward)

  Net Working Capital
  Net Working Capital (NWC)                                  1,280.0  (USD in millions)            [= 7,960.0 − 6,680.0 ← sum bar; POSITIVE (normal for a merchandise retailer)]
  Change in NWC                                                120.0  (USD in millions)            [= 1,280.0 − 1,160.0 prior year]
```

**Projection mechanics.** Identical to the restaurant map's illustration: each red
driver is the latest year (or the guided value) held flat, each forward balance is the driver
inverted against its forward base in the same column (`Inventory = DIO ÷ 365 × cost
of sales`, `Accounts Payable = DPO ÷ 365 × cost of sales`, `Deferred Revenue = % ×
the sales row`), the tax balances carry their year-N value as the red `N+1` driver.

## Section 4 — Sane ranges and checks (retail)

- `DIO` weeks to a few months of days (grocery and club at the low end, apparel and
  home at the high end); `DPO` tens of days; `DSO` a few days for store retailers,
  more where wholesale or a credit program exists. A `DIO` under ten days for an
  apparel retailer means the base is wrong, not the inventory.
- Net working capital **positive** for most merchandise retailers and stable in scale;
  near zero or negative only for fast-turn formats — say which the issuer is in one
  Notes line: "Net Working Capital: positive and stable in scale, as for most
  merchandise retailers." or "Net Working Capital: near zero, a fast-turn format."
- The combined payables-and-accruals caption, where reported, is carried **once**; no
  separate accruals row duplicates it.
- Every `% of net sales` tag sits on a driver that divides by the `Net Sales` row; every
  `% of total revenue` tag on one that divides by `Total Revenue`.

## Notes

- This map adds no deepKPI calls; the builder pulls balances from the shared inventory.
- Adding a retail-specific line later means one row in §2's table, nothing in the
  builder.
