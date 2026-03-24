---
name: derive-implied-metric
description: >
  Computes a financial or operational metric that isn't directly reported, using
  the algebraic relationship between available quantities. Use whenever a needed
  data point is absent from deepKPI but can be computed — Q4 values, segment
  remainders, per-unit economics (ASP, ARPU, AUV, revenue per store), take rates,
  implied useful life, penetration rates, geographic mix percentages. Trigger for
  "back into", "derive", "implied", "impute", "calculate from", "what's the Q4",
  or any situation where the needed number isn't in the data but its ingredients
  are. Always pull inputs via retrieve-kpi-data; derived values inherit provenance
  from their deepKPI-sourced components. For `.xlsx`/CSV exports, follow
  format-deepkpi-for-excel (plus the xlsx skill).
---

# derive-implied-metric

Computes metrics that aren't directly reported by identifying the algebraic
relationship between available quantities.

**All inputs must come from deepKPI** (via retrieve-kpi-data). Use list_kpis
first to discover exact KPI names, then search_kpis to pull the values. Never
use hardcoded or assumed figures as inputs to a derivation.

## Critical: flow vs. stock

Before any derivation, determine whether the metric is a **flow** (accumulated
over a period) or a **stock** (level at a point in time).

**Flows** — income statement, cash flow, unit sales, deliveries, openings:
`Q4 = FY − (Q1 + Q2 + Q3)`

**Stocks** — balance sheet items, period-end subscriber/store/user counts:
`Q4 = fiscal year-end value directly` — do not subtract.

When in doubt: "Is this a running total for the period, or a level at the end?"

## Derivation patterns

### Q4 from annual + Q1–Q3 (flows only)
```
Q4 = FY − (Q1 + Q2 + Q3)
```
**Always attempt this derivation when quarterly granularity is needed.** If Q4
is not directly in deepKPI, check whether FY is available and compute it — do
not present a partial quarterly series without first trying to fill Q4.

Apply to: revenue, COGS, gross profit, opex, net income, unit sales, deliveries,
store openings, SBC, D&A, capex, cash from operations.

Do NOT apply to: balance sheet items, period-end subscriber/store/user counts.

### Segment remainder
```
missing_segment = total − sum(known_segments)
```
Examples: domestic = total − international; Maggiano's = consolidated − Chili's − Corporate.

### Per-unit metrics

| Derived metric | Formula |
|---|---|
| Average Selling Price (ASP) | Revenue ÷ Units sold |
| ARPU | Revenue ÷ Paying users |
| Average unit volume (AUV) | Revenue ÷ Restaurant count |
| Revenue per store | Revenue ÷ Store count |
| Cost per store | COGS ÷ Store count |
| CAF income per vehicle financed | CAF income ÷ Vehicles financed |
| CapEx per new/remodeled store | Capex ÷ Affected stores |
| Revenue per square foot | Revenue ÷ Total sq ft |
| Average net sales per case | Revenue ÷ Cases sold |

### Implied useful life (depreciation)
```
implied_useful_life    = net_PP&E / depreciation_expense
next_year_depreciation = current_net_PP&E / implied_useful_life
```
Use the average of the last 2 years as the forward assumption, held constant.

### Take rate
```
take_rate = net_revenue / gross_bookings_or_GMV
```

### Geographic / segment mix
```
segment_pct       = segment_value / total_value
projected_segment = projected_total × segment_pct
```

### Penetration rate
```
penetration_rate = units_captured / total_addressable_units
```

## Verify the derivation

- Does the derived Q4 make the four quarters sum exactly to the annual?
- Does the segment remainder produce a non-negative number? (Negative → period mismatch, unit mismatch, or wrong metric definition)
- Does the per-unit figure fall in a plausible range for this business?
- Does implied useful life match the depreciation policy in the 10-K notes?

## Output format — show all work with clickable inputs

Table structure rules (in-chat):
- **Time flows left to right** — column headers are period labels
  (`FY22-Q1` … `FY22-Q4`), earliest at left.
- **One row per time series** — each operand in the derivation formula is its own
  row, mapping 1:1 to a single deepKPI series. Do not fragment a series into
  separate rows per quarter; each series spans all its period columns on one row.
- **Inputs first, derived metric last** — raw deepKPI rows appear at the top;
  the derived result is the final data row, bolded.
- **Links embed in cell values** — every directly reported input is a clickable
  hyperlink: `[$41.8M](exact-deepkpi-url)`. No separate Source column.
- **Notes is a bottom row** — populated in columns where something non-standard
  occurred (derivation applied, stock item, unit conversion, MD&A gap-fill, etc.).

Every derived metric must show all operands with links, and the result. Never
present a derived number without its full derivation visible.

**Single derivation block:**
```
**[Metric] ([Ticker], [Period])** — *derived*
Formula: FY − (Q1 + Q2 + Q3)
= [FY: $X](<exact-deepkpi-url>) − ([Q1: $A](<url>) + [Q2: $B](<url>) + [Q3: $C](<url>))
= **$D**
Caveat: Q4 not directly reported in SEC filings; derived from 10-K annual figure.
```

**Multi-period table (preferred when deriving multiple periods):**

```
## [Metric] ([Ticker]) — Q4 derivation
Units: $M

                   | FY22-Q1       | FY22-Q2       | FY22-Q3       | FY22-Q4   | FY23-Q1       | FY23-Q2       | FY23-Q3       | FY23-Q4   |
-------------------|---------------|---------------|---------------|-----------|---------------|---------------|---------------|-----------|
Quarterly Revenue  | [$41.8](url)  | [$55.3](url)  | [$65.1](url)  |           | [$43.9](url)  | [$59.8](url)  | [$69.7](url)  |           |
Annual Revenue     |               |               |               |[$210.1](url)|             |               |               |[$226.6](url)|
**Q4 (derived)**   |               |               |               | **$47.9** |               |               |               | **$53.2** |
Notes              |               |               |               |FY−Q1−Q2−Q3|               |               |               |FY−Q1−Q2−Q3|
```

Use the Notes row to flag anything non-standard: stock item used directly as Q4,
unit conversion applied, anomaly year excluded, one input estimated from MD&A
rather than deepKPI, etc.

## Excel workbook (`.xlsx`)

Follow **`format-deepkpi-for-excel`** for layout, styling, provenance **hyperlinks
on the value cells** (not separate Source rows), date headers, freeze panes,
column grouping, and checklist. Use the **xlsx** skill to build the file.

**Derive-implied-metric addenda:**

- Structure sections with ALL CAPS headers as needed (e.g. **INPUTS**, **DERIVED
  METRICS**); **operand** deepKPI rows first, **derived** row(s) last in each block.
- **Every derived value** must be a live `=` formula referencing the actual input
  cells — no hardcoded derived numbers:
  - **Q4:** `=FY_cell - Q1_cell - Q2_cell - Q3_cell`
  - **Segment remainder:** `=Total_cell - Seg1_cell - Seg2_cell`
  - **Per-unit:** `=Revenue_cell / Units_cell`
  - **Implied useful life:** `=NetPPE_cell / Depreciation_cell`
  - **Take rate:** `=NetRevenue_cell / GrossBookings_cell`
  - **Segment mix %:** `=Segment_cell / Total_cell`
- DeepKPI-sourced cells are **values** (with links per `format-deepkpi-for-excel`),
  not formulas; derived cells are **black** formulas, not hardcoded.

**CSV:** Per `format-deepkpi-for-excel` — `provenance_url` / `formula` columns as
needed; recommend `.xlsx`.

## Common pitfalls

- **Flow/stock confusion**: subscriber counts, store counts, balance sheet items
  are stocks — year-end value is Q4, not derived by subtraction.
- **Unit mismatch**: deepKPI may return some values in thousands, others in
  millions. Check units before dividing.
- **Non-December fiscal year**: ensure FY and Q1–Q3 are all from the same fiscal
  year, not the calendar year (e.g., AAPL ends September, NVDA ends January).
- **Negative remainder**: if FY − Q1 − Q2 − Q3 < 0, check that annual and
  quarterly values use the same metric definition and filing series.
- **Hardcoded inputs**: never use a revenue or count figure that wasn't just
  pulled from deepKPI in this session — always show the search that sourced it.