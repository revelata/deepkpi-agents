---
name: costs-restaurants
description: >
  Operating-cost build for restaurant companies in the operating-model workbook.
  Invoked by the costs router (`costs/costs.md`) when the company was classified
  as a restaurant during the revenue build, and only AFTER the REVENUE section is
  fully built. Receives the resolved `company_id`, official company name, workbook
  path (with the REVENUE section already laid down), the shared KPI inventory, and
  the industry determination; builds the restaurant cost structure beneath the
  `COSTS` ALL-CAPS header. The build reproduces the issuer's income-statement
  operating-expense block — every cost line that rolls up into Total Operating
  Expenses (e.g. food/beverage/packaging, labor, occupancy, other restaurant
  operating costs, general & administrative, depreciation & amortization,
  pre-opening / impairment / closure / asset-disposal costs) and NOTHING below the
  operating line (no interest, no taxes, no other income). It lays down (1) a
  dollar walkdown of each cost line to Total Costs and Expenses, then (2) each cost
  line — every line EXCEPT depreciation & amortization, whose forward dollars reference
  the depreciation schedule (built before this section) — as a live `=` % of its matched revenue base,
  which is the projection driver. A decision gate first reads whether the issuer
  reports its operating costs at the consolidated level only, by company (brand)
  segment, or by geographic segment: for company-segment reporters it runs a per-
  brand $ and % walkdown (denominator = that brand's revenue) plus a consolidated
  costs table; for geographic-segment reporters it runs a per-geography $ and %
  walkdown (denominator = that geography's revenue if revenue is split by
  geography, else total revenue) plus a consolidated table; the consolidated table
  also carries any corporate-only lines (e.g. G&A) that do not appear in the
  segment blocks. When the revenue build laid down a location roll-forward, the
  build additionally expresses labor, food & beverage, and occupancy / restaurant
  expenses per company-owned location (per brand if segmented). Pulls series via
  `search_kpis` from the shared inventory; format per
  ../../../_common/revelata-excel-styling-rules.md (one row per series, derived cells
  as live formulas) EXCEPT for time scope / columns, which this build matches to
  the revenue build. Quality checks: reported Operating Income must equal Total
  Revenue − Total Costs and Expenses, and the consolidated Total Costs and Expenses
  must trace cleanly up from each segment's lines. Sections: §1 identify the cost
  lines + segmentation gate, §2 the dollar walkdown, §3 costs as a % of revenue,
  §4 per-company-owned-location costs (conditional), §5 company-segment build
  (conditional), §6 geographic-segment build (conditional), §7 quality checks +
  foot, §8 worked example, §9 the projection layer (driver methodology + projection
  columns), §10 downstream handoff.
---

# costs — restaurants (operating-cost build)

This is the **restaurant-industry** cost build. It is invoked by the costs router
(`../costs.md`) when the company was classified as a **restaurant** during the
revenue build. It owns the build of the **COSTS** section for restaurant
companies — the income-statement **operating-expense block**, walked down to
**Total Costs and Expenses**, and expressed both in **dollars** and as a **% of
revenue** (the projection driver).

By the time control reaches this file, two things are already true:

1. the company **is in the restaurant industry** (decided by the revenue router
   and carried forward by the orchestrator), and
2. the **REVENUE section is already built** in the workbook, so cost lines can
   reference the revenue lines laid down there — total revenue, company
   restaurant sales, per-brand revenue, and (if a location roll-forward was
   built) the company-owned unit counts.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook (with the REVENUE section already built), the
**shared KPI inventory** from the orchestrator, and the **industry
determination**.

**Data source:** deepKPI only — see `../../../_common/data-source-rules.md`. On
failure, follow `../../../_common/connection-failure.md`. Do **not** re-run
`list_kpis`; pull the specific cost series with `search_kpis` against the shared
inventory.

**Formatting:** follow `../../../_common/revelata-excel-styling-rules.md` and build
with the **xlsx** skill. All conventions there apply here — one row per distinct
series, deepKPI-sourced values as pale-green hyperlinked input cells, and
**every** total / derived / ratio cell as a live `=` formula (never a hardcoded
number) — **except** for the **time scope and column layout**, which this build
matches to the revenue build per the section below.

## Time scope and columns (match the revenue build — overrides the common styling rules)

This rule **overrides** the corresponding conventions in
`../../../_common/revelata-excel-styling-rules.md` for this build:

- **Use the exact period columns the revenue build already laid down.** The cost
  lines must sit **directly beneath the matching revenue rows** so every
  cost-to-revenue ratio lines up in the same column. The restaurant revenue
  sub-builds (`comparableStoresBuild/`, `comparableSalesGrowthBuild/`,
  `revenuePerRestaurantBuild/`) are built on
  the **four most recent fiscal years**, annual columns only (because the unit
  roll-forward they depend on is annual). So in practice this build uses those
  **same four annual columns**, oldest → newest, in Col E onward. Do **not**
  introduce a different timeline, and do **not** add quarterly columns the revenue
  build did not lay down. (The full intended horizon is the canonical **Model
  timeline** in the orchestrator `../../SKILL.md` — the four historical fiscal years
  plus the five projection years, `N+1 … N+5`, after the last historical year; this
  section mirrors whatever portion of that timeline the upstream builds have laid
  down.) If the revenue build did carry a quarterly block, mirror
  it exactly (annual block, blank separator, quarterly block), with imputed
  quarters (`Q4 = FY − Q1 − Q2 − Q3`) as in-row live formulas per the styling
  rules.
- **Never silently substitute data.** If a deepKPI cost series for a specific cell
  is a clear data-quality artifact (order-of-magnitude scaling or a tagging
  error), do not transcribe it. Prefer a clean alternate deepKPI series; if none
  exists, take the value from the company's 10-K "Results of Operations" /
  "Consolidated Statements of Income" table, mark that cell distinctly (gold fill,
  hyperlinked to that filing, with a cell comment that keeps the filing table),
  and record it in the Notes block, one line per override: "Costs: <line> FY<n>
  is taken from the 10-K income statement; the database series was <scaled /
  mis-tagged / missing>."

> This build is authored section by section. The sections present here — §1 the
> cost-line identification + segmentation gate, §2 the dollar walkdown, §3 costs
> as a % of revenue, §4 per-company-owned-location costs, §5 the company-segment
> build, §6 the geographic-segment build, §7 quality checks, §8 a worked example,
> §9 the projection layer, and §10 the downstream handoff — are the implemented
> scope. Do **not** build or add any information outside the sections present here.

---

## Cost build — framework overview

This build turns the issuer's reported **operating-expense line items** into a
clean, footing cost block beneath the `COSTS` header, and then turns each line
into the **cost-to-revenue ratio** that drives the projection. It follows one
fixed framework so that every restaurant company is modeled the same way and the
block always foots.

**The master identity (the foot / quality check):**

```
  Total Costs and Expenses  = Σ (each reported operating-cost line item)
  Operating Income          = Total Revenue − Total Costs and Expenses
```

`Total Costs and Expenses` is built as the **sum of the individual cost lines**
(a live formula), and is cross-checked against the issuer's **reported** Total
Operating Expenses KPI. `Operating Income` is then cross-checked against the
issuer's **reported** Operating Income / Income from Operations KPI — the two
must agree (§7). `Total Revenue` is the line the **revenue build** already laid
down; this build references it, it does not re-derive it.

**Build the cost section in this order** (each conditional step states its
trigger):

1. **§1 — Identify the operating-cost line items** from deepKPI / the 10-K, and
   **decide the segmentation** (consolidated-only vs. company/brand segments vs.
   geographic segments). This gate decides whether §5 or §6 is built.
2. **§2 — The dollar walkdown.** Lay every operating-cost line in dollars for
   every period column, footing to `Total Costs and Expenses`. (When the company
   reports by segment, this is the **consolidated** table that sits at the bottom;
   §5 / §6 build the per-segment walkdowns above it.)
3. **§3 — Costs as a % of revenue.** Express every cost line — **except
   Depreciation & Amortization** — as a live `=` % of its matched revenue base.
   This ratio is the **projection driver**.
4. **§4 — Per-company-owned-location costs** (only if the revenue build laid down
   a location roll-forward). Labor, food & beverage, and occupancy / restaurant
   expenses per company-owned location.
5. **§5 — Company (brand) segment build** (only if the gate found company
   segments). Per-brand $ and % walkdowns + the consolidated table.
6. **§6 — Geographic segment build** (only if the gate found geographic
   segments). Per-geography $ and % walkdowns + the consolidated table.
7. **§7 — Quality checks + foot.**

**Conventions that apply to every section (read once):**

- **Signs follow the income statement.** Costs are carried **positive**; a credit
  within costs (a gain on sale, a settlement credit, other operating income shown
  inside the cost block) is carried **negative**, exactly as the issuer presents it,
  so every subtotal is a plain `SUM`. A deepKPI value delivered with the opposite
  sign is carried with the filing's sign as a 10-K override (gold, hyperlinked, the
  comment stating the flip); the sign is never corrected inside a formula.
- **Reference the revenue build — do not re-derive revenue.** Every revenue
  figure this build divides by already exists in the workbook (the `Total
  Revenue` row, the company-restaurant-sales line, the per-brand revenue
  subtotals). Reference those cells with live `=` formulas; never hardcode a
  revenue number or rebuild a revenue line here.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (each reported cost line, the reported Total Operating
  Expenses and Operating Income used as checks, and any base-year lookback) are
  **input cells** (pale-green fill,
  dark-blue hyperlinked
  value linked to the filing). **Every other cost cell is a live `=` formula**
  (black font, no fill) — the `Total Costs and Expenses` sum, every `% of
  revenue` row, every per-location figure, every segment subtotal, and every
  foot-check memo. Projected-period cost assumptions (the forward `% of revenue`)
  are **red** driver cells (the projection-driver convention — see §9). Never
  hardcode a computed number.
- **Scope is the operating block ONLY.** Build **only** the lines that roll up
  into **Total Costs and Expenses** (§1.2). Do **not** add interest expense,
  interest income, other income/expense, income taxes, equity-method items, or
  any below-the-operating-line item — those belong to the
  `CONSOLIDATED FINANCIALS` section, not here.
- **D&A is carried in dollars but NOT projected here.** Depreciation &
  amortization is part of Total Costs and Expenses, so it appears in the §2 dollar
  walkdown. But it is the **one** line that is **not** expressed as a % of revenue
  (§3) — its forward dollars reference the **depreciation schedule**
  (`../../depreciation-schedule/depreciation-schedule.md`, §6), which the
  orchestrator builds **before** this section. Leave its `% of revenue` cell as a
  dash with a cell comment pointing to that schedule.
  **Only a line that is the issuer's total D&A references the schedule** (the
  schedule's §6.2 rule): it must equal the schedule's cash-flow `Depreciation &
  Amortization` in every historical column within rounding. A line that is a
  component of D&A — `Amortization of cloud computing arrangements`, amortization of
  intangibles, a depreciation-only line beside a separate amortization line — is
  carried in dollars and projected **held flat at its year-`N` value** (a red driver
  in `N+1` equal to the `N` cell, later years `= the N+1 cell`), with its `% of
  revenue` row a derived read like the D&A row's (§3.3); it never references the schedule, whose forward D&A rolls off
  PP&E and is not a forecast of such a line. The hand-back report lists every such component line by key, as it lists the lines excluded from the issuer's adjusted measure; the consolidated section adds them to its total D&A so EBITDA adds back all depreciation and amortization.
- **Label / comment / spacing discipline (same as the revenue builds).** Col C
  labels are **plain descriptive text** (the issuer's reported line name); the
  operand recipe for each formula row goes in a **cell comment on the Col C label
  cell** (author `Cost Build`), not in the visible label. Indentation, bold /
  border conventions, the italic percent rows, and the one-blank-row-between-blocks
  rule all follow `../../../_common/revelata-excel-styling-rules.md` exactly as the
  revenue builds do.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../_common/revelata-excel-units-and-scale.md`, and every row's family
  follows from that file's Rule 4 — an input row's from its deepKPI `unit` field, a
  derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.1, §3.2, §4.2,
  §5.2, §5.3, §6.1 and §7.1 — and in the `Units (Col D)` column of that section's
  formula table. Dollar rows show the placeholder `(USD in <scale>)`: the contract's
  Rule 2 supplies the scale, millions by default, thousands where the digit test puts a
  small filer. Three classifications are specific to this build:
  - **Percent rows name their denominator, and this build has two.** Restaurant-level
    lines (food & beverage, labor, occupancy, other operating) divide by company
    restaurant sales and are tagged `(% of company sales)`; corporate lines (G&A,
    pre-opening, impairment) and the total divide by total revenue and are tagged `(% of
    total revenue)`; segment blocks use `(% of <Brand> revenue)` / `(% of <Geography>
    revenue)`. The basis still goes in the Col C cell comment as §3.2 requires — the tag
    is the unit, the comment is the recipe.
  - **The D&A `% of revenue` row is tagged `(% of total revenue)` like the corporate
    lines.** It is a live ratio in every column, a derived read — D&A dollars come
    from the depreciation schedule, never from this row — so it is a data row and
    never a driver.
  - **Per-location costs → `(USD millions per location)`; the count row →
    `(locations)`.** A cost in millions divided by a location count in ones comes out in
    millions per location, and displaying it so lets a reader divide the two rows above
    and land on this one (the §8 example: `3,500 ÷ 3,700 ≈ 0.9459`).
- **Reading the layout blocks (§2.1, §3.2, §4.2, §5.2, §5.3, §6.1, §7.1).** Each row's
  annotation has two columns, left to right: the **Col D units tag in parentheses** —
  `(USD in <scale>)` means the contract's Rule 2 sets the money scale; every other tag
  is written as it goes in the cell — and the note in **square brackets**: `[deepKPI
  INPUT …]` for a pulled value, `[FORMULA …]` for a computed row, `[DASH …]` for a
  deliberately empty cell, plus styling (`SUM-BAR`, `italic`). Sub-header lines carry
  no tag.
- **Header hierarchy (per the styling contract).** Only the **ALL-CAPS `COSTS`
  section header** gets the big-header treatment — **bold, underlined, size 16**.
  Every **title-case sub-header beneath it** (`Consolidated Costs`,
  `Consolidated Costs — % of revenue`, `Cost per company-owned location`, and the
  per-brand / per-geography headers) is **bold, underlined, size 12** at the indent
  the contract's block-header rule gives it — the one sub-header treatment every
  section shares (`../../../_common/revelata-excel-styling-rules.md`). Do **not** set
  them to size 16; that big-header look is reserved for the one ALL-CAPS `COSTS` row.

The sub-sections below specify each piece cell-by-cell. Build them in order; do
not add cost lines outside this framework.

---

## Section 1 — Identify the operating-cost line items and decide the segmentation

This first section does no workbook writing of its own. It (a) reads the issuer's
operating-expense block, (b) maps each line to a deepKPI series, and (c) decides
**how the costs are segmented**, which determines whether the build is a single
consolidated walkdown (§2 – §3 only) or a per-segment build (§5 or §6) plus a
consolidated table.

### 1.1 — Where the cost lines live

Restaurant operating costs are disclosed in the issuer's **MD&A "Results of
Operations"** table and, authoritatively, in the **"Consolidated Statements of
Income"** (sometimes "…and Comprehensive Income") in the financial statements.
Both present the same operating-expense block: a list of expense lines that sum
to **Total Costs and Expenses**, with **Income from Operations / Operating
Income** immediately below.

In the **shared KPI inventory** these lines live under the **`Consolidated Income
Statement`** category (and, when the issuer reports cost by segment, under
**`Segment Financials`**). Read that category first to see exactly which expense
lines the issuer reports — do **not** assume a generic set.

### 1.2 — Scope rule (STRICT): only the lines that roll up to Total Costs and Expenses

Build **every** expense line the issuer lists **between** revenue and **Total
Operating Expenses**, and **nothing else**:

- **Include** the operating-expense lines, e.g. food/beverage/packaging (or "cost
  of sales"), labor (restaurant labor), occupancy, other restaurant operating
  costs (or "restaurant expenses"), general & administrative expenses,
  depreciation & amortization, pre-opening costs, and impairment / closure costs
  / asset-disposal charges. The exact set and labels are issuer-specific (§1.3).
- **Exclude — do not add — anything below the operating line.** No interest
  expense, interest / investment income, other income (expense), income tax
  provision, equity in earnings, or net-income subtotals. Those are owned by the
  `CONSOLIDATED FINANCIALS` section. This restriction is deliberate and strict: do
  not add any cost that is not a line of the issuer's reported Total Costs and
  Expenses block.

The discipline check is that **Σ (the lines you include) = reported Total
Operating Expenses** (§7). If your sum does not tie, you have either **missed a
line** the issuer reports inside the block or **included one** that sits below the
operating line — fix the line set, do **not** paper over it with an invented
"other costs" plug.

### 1.3 — The canonical line-item set (use the issuer's exact lines)

A common restaurant operating-expense block — and the canonical example for this
build — reads:

```
  Food, beverage and packaging
  Labor
  Occupancy
  Other operating costs
  General and administrative expenses
  Depreciation and amortization
  Pre-opening costs                                  (issuer may combine the next two with this)
  Impairment, closure costs, and asset disposals
  Total Costs and Expenses
```

**The actual line items vary by issuer — use the issuer's reported labels and
groupings, not these defaults.** A franchisor that consolidates its national
advertising funds carries an **`Advertising funds expense`** line here, matched by
an `Advertising funds revenue` stream in the REVENUE section; it is a pass-through
and is projected as such (§9.3). For example, Brinker International reports `Cost
of sales`, `Restaurant labor`, `Restaurant expenses`, `Depreciation and
amortization`, `General and administrative`, and `Other (gains) and charges`;
some issuers combine pre-opening with impairment/closure into a single line,
others split them. Mirror exactly what the issuer presents in its Total Operating
Expenses block — same lines, same order, same labels (Col C uses the issuer's
wording).

### 1.4 — Map each line to a deepKPI series

For each line in the issuer's block, find the matching series with `search_kpis`
against the **shared inventory** (never re-run `list_kpis`). Match on the issuer's
wording plus the `- Annual` suffix, e.g. `Cost of sales - Annual`, `Restaurant
labor - Annual`, `Occupancy costs - Annual`, `Other restaurant operating costs -
Annual`, `General and administrative expenses - Annual`, `Depreciation and
amortization - Annual`, `Pre-opening costs - Annual`, `Impairment and closure
costs - Annual`, `Total operating expenses - Annual`, and the operating-profit
check line `Income from operations - Annual` / `Operating income - Annual`.

- Prefer **annual** (`- Annual`) series across the build window (the four FYs the
  revenue build used). If the revenue build also carried a quarterly block, pull
  the matching `- 3 Month` quarterly series onto the **same row** (annual block +
  quarterly block), and impute any missing quarter as `Q4 = FY − Q1 − Q2 − Q3` in
  that row's column (live formula), per the styling rules.
- Sanity-check each value against the series trend and the 10-K table; reject
  obvious artifacts and fall back to the 10-K figure (gold-fill override) per the
  time-scope rule above.
- Pull the **reported Total Costs and Expenses** and **reported Operating Income /
  Income from Operations** series too — they are used as the §7 foot checks (and
  Total Costs and Expenses can double as a cross-check input, but the workbook's
  `Total Costs and Expenses` row is always the **sum formula**, not the input).

### 1.5 — Segmentation decision gate (run before any cost line is written)

Decide **which presentation** the cost block gets, by reading how the issuer
reports its operating costs. Check the **`Segment Financials`** category of the
shared inventory and the 10-K segment footnote / MD&A; **do not guess**:

- **Path C0 — consolidated only (default).** The issuer reports a **single**
  operating-expense block for the whole company (one set of cost lines). Build
  **§2 + §3 only** (the consolidated walkdown and its % table), plus §4 if a
  location build exists. Most single-brand operators (e.g. Chipotle) are here.
- **Path C1 — company (brand) segments.** The issuer reports operating costs
  broken out by **operating segment that corresponds to a distinct brand /
  concept** (e.g. **Chili's** vs. **Maggiano's** for Brinker International). Build
  **§5** — a per-brand $ and % walkdown — **then** the §2 / §3 consolidated table
  at the bottom (which sums the brands and adds any corporate-only lines). Plus §4
  per brand if a location build exists.
- **Path C2 — geographic segments.** The issuer reports operating costs broken
  out by **geography** (e.g. domestic vs. international, or by region). Build
  **§6** — a per-geography $ and % walkdown — **then** the §2 / §3 consolidated
  table at the bottom. Plus §4 if a location build exists.

> **What counts as a segment (be precise).** A **segment** is a distinct
> brand/concept (Path C1) or a distinct geography (Path C2) for which the issuer
> reports its **own operating costs**. A split of revenue into **Company sales
> vs. Franchise revenue is NOT a segment** — that is a revenue-mix split within a
> single segment, and it does not by itself trigger a per-segment cost build. Only
> a genuine **two-or-more-brand** breakout (e.g. Chili's and Maggiano's) is a
> company-segment case; only a genuine **geography** breakout is a geographic
> case. If a parent operates two brands but reports operating costs **only on a
> consolidated basis**, it is **Path C0** (you cannot build per-brand cost
> walkdowns from costs that are not disclosed per brand).

State which path you picked and why (one line, citing the specific segment KPIs
that did or did not exist), before writing any cost line, so the routing is
auditable. A company resolves to **exactly one** of C0 / C1 / C2; build only that
path's structure. A segment path also requires the
revenue hand-back's **segment map** (`../../SKILL.md`, "The segment map") to name
every segment the path would lay, corporate-only blocks excepted: a segment block
needs that segment's revenue for its ratios and its operating-income line, and a
segment the map does not name is carried at the consolidated level, never struck
against a blended base.

---

## Section 2 — The dollar walkdown (Consolidated Costs)

This section lays the issuer's operating-expense block in **dollars** for every
period column, footing to `Total Costs and Expenses`. Under **Path C0** this is
the whole dollar build. Under **Path C1 / C2** this is the **consolidated** table
that sits **beneath** the per-segment walkdowns (§5 / §6) and **sums** them — see
those sections for how the consolidated lines reference the segment lines.

### 2.1 — Layout for the dollar walkdown

```
COSTS                                                                                  [ALL-CAPS section header — already in the scaffold]

Consolidated Costs                                                                     [sub-header: bold + underlined, size 12 — per the styling contract]
    Food, beverage and packaging                          (USD in <scale>)             [deepKPI INPUT — issuer's line]
    Labor                                                 (USD in <scale>)             [deepKPI INPUT]
    Occupancy                                             (USD in <scale>)             [deepKPI INPUT]
    Other operating costs                                 (USD in <scale>)             [deepKPI INPUT]
    General and administrative expenses                   (USD in <scale>)             [deepKPI INPUT]
    Depreciation and amortization                         (USD in <scale>)             [deepKPI INPUT — historicals; ref to D&A schedule for projections]
    Pre-opening costs                                     (USD in <scale>)             [deepKPI INPUT — issuer's line[s]]
    Impairment, closure costs, and asset disposals        (USD in <scale>)             [deepKPI INPUT — if reported separately]
  Total Costs and Expenses                                (USD in <scale>)             [FORMULA = SUM(lines above); bold, SUM-BAR]
    Total Costs and Expenses (reported)                   (USD in <scale>)             [deepKPI INPUT — the reported anchor]
    Memo: Total Costs and Expenses sum − reported (must = 0)  (USD in <scale>)         [FORMULA check; italic; 0 every period]
  Operating Income (modeled)                              (USD in <scale>)             [FORMULA = Total Revenue − Total Costs and Expenses; bold, SUM-BAR — contract row]
    Operating Income (reported)                           (USD in <scale>)             [deepKPI INPUT — the reported anchor (Income from operations / Operating income) — contract row]
    Memo: Operating Income modeled − reported (must ≈ 0)  (USD in <scale>)             [FORMULA check; italic; ≈ 0 every period]
```

- Each cost line is **one row** across the period columns (annual block, then the
  quarterly block if the revenue build carried one), per the one-row-per-series
  rule. Do **not** fragment a line into per-period rows.
- **A line the issuer reports in some years and not others** (impairment, closure,
  reorganization) keeps its row across all columns, with a numeric **0** in the years
  it was not incurred (the number format displays it as a dash). Never the text dash:
  the projection seed in §9.1 tests those cells with ISNUMBER (a run-rate seed with COUNT and MEDIAN), and a text dash would make it skip the year; text is invisible
  to both. Do not delete the row and do not leave a hole that breaks the `SUM` range.
- `Total Costs and Expenses` is a **live `= SUM(...)`** over the cost-line rows
  above it — never an input, never hardcoded. This is what makes the summation
  **followable** (quality check 2).
- The two memo rows cross-check the sum against the issuer's **reported** Total
  Operating Expenses (an input); the difference must be **0** every period. A
  non-zero difference means a missing or extra line (§1.2) — resolve it.

### 2.2 — The formulas (cell-by-cell) for the dollar walkdown

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Food, beverage and packaging` (and each operating-cost line) | DATA_DEPENDENT | `(USD in <scale>)` | historicals: deepKPI **input** $ (green, hyperlinked); projections: `= <its % of revenue, this col> × <matched revenue base, this col>` (see §3) | *(no comment on input rows — provenance via hyperlink; projection rows note `"= % of revenue × revenue base"`)* |
| `Depreciation and amortization` | | `(USD in <scale>)` | historicals: deepKPI **input** $; projections: `= <DEPRECIATION SCHEDULE → Depreciation & Amortization, this col>` for the issuer's total-D&A line; a component line is held flat at its year-`N` value (red driver; `depreciation-schedule` §6.2) | `"Historicals: reported D&A. Projections: reference the DEPRECIATION SCHEDULE's Depreciation & Amortization, not a % of revenue."` |
| `Total Costs and Expenses` | | `(USD in <scale>)` | `= SUM(` all cost-line rows above `)` | `"Σ of every operating-expense line. Must tie to reported Total Costs and Expenses (memo below)."` |
| `Total Costs and Expenses (reported)` | | `(USD in <scale>)` | deepKPI **input** $ (reported) | *(no comment — input row; the anchor the memo below ties to)* |
| `Memo: Total Costs and Expenses sum − reported (must = 0)` | | `(USD in <scale>)` | `= <Total Costs and Expenses> − <Total Costs and Expenses (reported)>` | `"Completeness check: 0 means every line in the block is captured and nothing extra was added."` |
| `Operating Income (modeled)` | | `(USD in <scale>)` | `= <Total Revenue, this col> − <Total Costs and Expenses, this col>` | `"Modeled operating profit = total revenue (revenue build) − total operating expenses. Contract row."` |
| `Operating Income (reported)` | | `(USD in <scale>)` | deepKPI **input** $ (Income from Operations / Operating Income) — contract row | *(no comment — input row)* |
| `Memo: Operating Income modeled − reported (must ≈ 0)` | | `(USD in <scale>)` | `= <Operating Income (modeled), this col> − <Operating Income (reported), this col>` | `"Must be ≈ 0 every historical period. A non-zero gap means a missing or extra cost line, a D&A mismatch or a revenue-base mismatch — fix it in the block, never plug it."` |

- In **historical** columns every cost line is a reported **deepKPI input**, and
  `Total Costs and Expenses` is the sum.
- In **projected** columns every cost line **except D&A** flips to `= % × revenue
  base` (the % is the **red** driver from §3, set per §9), **D&A** references the
  depreciation schedule, and `Total Costs and Expenses` stays the same sum formula.

### 2.3 — Pre-delivery checklist (dollar walkdown)

- [ ] Every line in the issuer's operating-expense block is present, in the
      issuer's order and wording; **no** below-the-operating-line item was added.
- [ ] Each cost line is **one row** (annual block; quarterly block + imputed Q4
      only if the revenue build carried quarterlies); historicals are deepKPI
      inputs (green, hyperlinked).
- [ ] `Total Costs and Expenses` is a **live `= SUM(...)`** (bold, SUM-BAR), never
      hardcoded.
- [ ] The `sum − reported (must = 0)` memo evaluates to **0** every period after
      recalculation (completeness / foot).
- [ ] Styling per the styling rules; after recalculation, **zero formula errors**.

---

## Section 3 — Costs as a % of revenue (the projection driver)

This section expresses **each cost line as a live `=` % of its matched revenue
base**. This ratio is the **driver**: it is how the line is read for analysis and
how it is **projected** (projected $ line = % × revenue base). **Every line is
expressed as a % EXCEPT Depreciation & Amortization**, whose forward dollars
reference the depreciation schedule (§9.3).

### 3.1 — Choosing the revenue base ("respective revenue")

Match each cost line to the revenue base it is actually incurred against — the
"respective revenue" — and divide by **that** base, not blindly by total revenue.
The default mapping (and the basis on which issuers themselves present these
ratios in MD&A):

- **Restaurant-level operating costs** — food/beverage/packaging (cost of sales),
  labor, occupancy, other restaurant operating costs — are incurred **only at
  company-operated restaurants**, so the matched base is **company restaurant
  sales** (the company-operated restaurant revenue line from the revenue build),
  **not** total revenue (which also includes franchise royalties and other
  revenue those costs do not support). For a 100%-company-owned operator with no
  franchising, company restaurant sales ≈ total revenue and the distinction is
  moot — but make the reference explicit either way.
- **Corporate / enterprise-level costs** — general & administrative, and
  pre-opening / impairment / closure costs when the issuer presents them
  enterprise-wide — are matched against **total revenue**.
- **Depreciation & amortization** — matched against **total revenue**, a derived
  read in every column, never a driver (the dollars are projected via the
  depreciation schedule).

When the issuer's MD&A presents a specific ratio against a specific base (e.g.
"cost of sales as a percentage of **company sales**"), **follow the issuer's
base**. State the base each line uses in the Col C cell comment so the choice is
auditable. Reference the revenue base cell that the **revenue build** actually laid
down — e.g. the `Total Revenue` row, the consolidated company-restaurant-sales
line (`Revenue from Restaurants — Total` in the revenue-per-restaurant build, or
modeled company sales = `Total Revenue from the Comparable Cohort` +
`Total Revenue from the Non-Comparable Cohort` in the comparable-stores build, or
the reported company-sales input if present).

### 3.2 — Layout for the % of revenue block

Place the `% of revenue` block **immediately beneath** the matching dollar block
so each ratio sits one row under its dollar line and in the same column. Mirror
the dollar line order:

```
Consolidated Costs — % of revenue                                                      [sub-header: bold + underlined, size 12 — per the styling contract]
    Food, beverage and packaging                          (% of company sales)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Labor                                                 (% of company sales)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Occupancy                                             (% of company sales)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Other operating costs                                 (% of company sales)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    General and administrative expenses                   (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Depreciation and amortization                         (% of total revenue)         [FORMULA = D&A $ ÷ Total Revenue in every column; italic; derived read, not a driver — D&A $ comes from the depreciation schedule]
    Pre-opening costs                                     (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Impairment, closure costs, and asset disposals        (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
  Total Costs and Expenses                                (% of total revenue)         [FORMULA = Total Costs and Expenses ÷ Total Revenue; italic, bold; basis in the cell comment]
  Operating margin                                        (% of total revenue)         [FORMULA = Operating Income (modeled) ÷ Total Revenue; italic; derived read, not a driver]
```

**Label rule (STRICT).** The Col C label for each % row is **just the cost line
name** — identical to its dollar line (e.g. `Cost of sales`, `Labor and
benefits`) — and is **never** suffixed with `— % of company sales` /
`— % of revenue`. The enclosing `Consolidated Costs — % of revenue` sub-header
already signals that every row in the block is a percentage, so the suffix is
redundant in the label. Put the **basis** (which revenue denominator the ratio
divides by — `% of company sales` for restaurant-level lines, `% of total
revenue` for corporate lines) in the **Col C cell comment** for that row, not in
the visible label.

(If preferred, the % may instead be carried as an italic memo row **directly
under each dollar line** within the §2 block rather than as a separate block —
either arrangement is acceptable as long as every line has a visible, live `% of
revenue` cell and the column alignment to the dollar line is exact.
Pick one arrangement and apply it sheet-wide.)

### 3.3 — The formulas (cell-by-cell) for the % of revenue block

The Col C label is the **bare cost-line name** (no `— % of …` suffix); the basis
goes in the comment.

| Row (plain Col C label — no suffix) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `<restaurant-level cost>` (e.g. `Cost of sales`) | | `(% of company sales)` | historicals: `= <cost $ line, this col> ÷ <company restaurant sales, this col>`; projections: **red driver input** (see §9) | `"% of company sales. Restaurant-level cost ÷ company restaurant sales. The projection driver: projected $ = this % × company sales."` |
| `<corporate cost>` (e.g. `General and administrative`) | | `(% of total revenue)` | historicals: `= <cost $ line, this col> ÷ <Total Revenue, this col>`; projections: **red driver input** (see §9) | `"% of total revenue. Corporate cost ÷ total revenue. Projection driver."` |
| `Depreciation and amortization` (and each D&A component line) | | `(% of total revenue)` | `= <D&A $ line, this col> ÷ <Total Revenue, this col>` in **every** column, historical and projected; black, italic; never a driver | `"% of total revenue. Derived read, not a driver — D&A dollars come from the DEPRECIATION SCHEDULE section (a component line is held flat), never from this row."` |
| `Total Costs and Expenses` | | `(% of total revenue)` | `= <Total Costs and Expenses, this col> ÷ <Total Revenue, this col>` | `"% of total revenue. Total opex ÷ total revenue. (Complement = operating margin.)"` |
| `Operating margin` | | `(% of total revenue)` | `= <Operating Income (modeled), this col> ÷ <Total Revenue, this col>` | `"% of total revenue. Operating income ÷ total revenue. Derived read, not a driver."` |

- **Historical** % cells are **live formulas** (cost ÷ base) — black font (not
  green; they are derived, not inputs) — with the accounting **percent** format
  and italic styling per the styling rules.
- **Projected** % cells become **red driver inputs** (the assumption the analyst
  sets; see §9 for the driver styling and value methodology), and the corresponding
  **dollar** line in §2 flips to `= % × revenue base`. Anchor each forward % on the historical trend plus management guidance
  (pricing/inflation for cost of sales, wage inflation and leverage for labor,
  fixed-rent leverage for occupancy, G&A leverage as the base scales).
- The `Total Costs and Expenses` row in the % block is convenient because its
  **complement is the operating margin** — a fast read on profitability and a
  bridge to the §7 Operating Income check.

### 3.4 — Pre-delivery checklist (% of revenue)

- [ ] Every operating-cost line has a live `% of revenue` cell; D&A's is a black
      formula in every column, its comment pointing to the depreciation schedule.
- [ ] Each % row's Col C label is the **bare cost-line name** (no `— % of company
      sales` / `— % of revenue` suffix); the basis lives in the **cell comment**.
- [ ] Each line's denominator is the **matched revenue base** (restaurant-level
      costs ÷ company restaurant sales; corporate costs ÷ total revenue), the base
      is **referenced from the revenue build** (not re-entered), and the base is
      stated in the cell comment.
- [ ] Historical % cells are **live formulas**; projected % cells are **red
      drivers** (§9), and the projected **$** line equals `% × revenue base` — except
      the D&A row, whose projected % stays a black formula.
- [ ] % rows use the accounting **percent** format, italic; aligned one row under
      (or beside) the matching dollar line, same column.
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Per-company-owned-location costs (conditional on a location build)

**Build this section only if the revenue build laid down a location
roll-forward** — i.e. the location build (`../../revenue/restaurants/locationBuild/`)
produced per-concept **Company-Operated EOP** unit counts. If no location build
exists, **skip this section entirely** (no empty rows) and record the skip in
`BUILD_LOG.md`; a fallback taken because a row is absent is build history, not
a workbook note.

When the unit counts exist, express the three restaurant-level cost lines **per
company-owned location**, so the analyst can read unit economics and cross-check
them against the per-location **revenue** the revenue build produced. The three
lines:

- **Labor**
- **Food and beverage** (food/beverage/packaging / cost of sales)
- **Occupancy / restaurant expenses**

(Other restaurant operating costs may be added on the same pattern if useful, but
the three above are required.)

### 4.1 — The logic

```
  Cost per company-owned location = <cost $ line> ÷ <Company-Operated EOP location count>
```

- **Denominator:** the **Company-Operated EOP location count** from the location
  build — referenced with a live formula, never re-entered. Use the **same
  universe** (company-owned) as the cost numerator, so the per-unit figure is
  clean. Per brand if the company is segmented (use that brand's company-owned EOP
  count and that brand's cost line).
- **EOP vs. average count.** This build uses the **EOP** count, matching the
  revenue-per-restaurant build's per-unit convention, so per-location **cost** and
  per-location **revenue** are on the same basis and a restaurant-level margin per
  location can be read off directly. (EOP slightly understates the per-unit figure
  in fast-expanding years; the distortion is the same in the cost and revenue
  per-unit lines, so it largely cancels.) Note the choice in a cell comment.

### 4.2 — Layout and formula (cell-by-cell)

Place this block beneath the dollar / % blocks (per brand, beneath that brand's
blocks, if segmented):

```
Cost per company-owned location                                                        [sub-header: bold + underlined, size 12 — per the styling contract]
    Company-Operated EOP location count                   (locations)                  [FORMULA = ref to the location build, same brand/universe]
    Food and beverage per location                        (USD millions per location)  [FORMULA = F&B $ ÷ EOP count]
    Labor per location                                    (USD millions per location)  [FORMULA = Labor $ ÷ EOP count]
    Occupancy / restaurant expenses per location          (USD millions per location)  [FORMULA = Occupancy $ ÷ EOP count]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Company-Operated EOP location count` | HAS_LOCATION_BLOCK | `(locations)` | `= <location build's Company-Operated EOP Balance for this brand/consolidated, same column>` | `"EOP company-owned unit count — referenced from the location build, not re-entered."` |
| `Food and beverage per location` | HAS_LOCATION_BLOCK | `(USD millions per location)` | `= <Food/beverage/packaging $, this col> ÷ <Company-Operated EOP location count, this col>` | `"F&B cost ÷ company-owned EOP locations. Same universe as the numerator."` |
| `Labor per location` | HAS_LOCATION_BLOCK | `(USD millions per location)` | `= <Labor $, this col> ÷ <Company-Operated EOP location count, this col>` | `"Restaurant labor ÷ company-owned EOP locations."` |
| `Occupancy / restaurant expenses per location` | DATA_DEPENDENT | `(USD millions per location)` | `= <Occupancy $, this col> ÷ <Company-Operated EOP location count, this col>` | `"Occupancy / restaurant expenses ÷ company-owned EOP locations."` |

- Every cell is a **live formula** (the count is a reference; the per-unit lines
  are ratios) — no hardcodes.
- Per-unit figures are **dollars per location** in the sheet's unit; do **not** round
  them to whole units (they are dollar figures, not store counts). Display with the
  sheet accounting number format.
- For a **segmented** company, repeat this three-line block **per brand** (Path
  C1) using that brand's cost lines and that brand's company-owned EOP count.

### 4.3 — Pre-delivery checklist (per-location costs)

- [ ] Section present **iff** a location build exists; otherwise omitted, with the
      skip noted.
- [ ] The `Company-Operated EOP location count` row is a **live reference** to the
      location build (same brand and company-owned universe), not re-entered.
- [ ] Food & beverage, labor, and occupancy / restaurant expenses each have a
      live `cost ÷ EOP count` per-location row; numerator and denominator are on
      the **same universe**.
- [ ] Per brand if segmented (Path C1).
- [ ] After recalculation, **zero formula errors**.

---

## Section 5 — Company (brand) segment cost build (Path C1 only)

Build this section **only** when the gate (§1.5) found **company / brand
segments** — i.e. the issuer reports operating costs separately for two or more
**brands** (e.g. Chili's and Maggiano's for Brinker International). Do **not**
blend the brands; build a **complete $ and % walkdown per brand**, then a single
**consolidated costs table** that combines them.

### 5.1 — Why per brand, never blended

Each brand has a different cost structure (cost of sales %, labor %, occupancy
intensity) and a different revenue base. Dividing one brand's costs by another's
sales, or summing the brands before computing ratios, silently corrupts every
ratio. Build each brand on **its own** reported cost lines and **its own** revenue
base (from the revenue build's per-brand revenue), and let the brands meet only at
the **dollar level** in the consolidated table, where summing is always valid.

### 5.2 — Per-brand block (the full walkdown for one brand)

For **each brand**, lay a self-contained block — the §2 dollar walkdown and the
§3 % walkdown — for **that brand's** operating costs, in the same brand order as
the revenue build's per-brand blocks:

```
<Brand> — Costs                                                                        [brand header: bold + underlined, size 12]
    <each operating-cost line for this brand>             (USD in <scale>)             [deepKPI INPUT — that brand's reported segment costs]
  Total Costs and Expenses — <Brand>                      (USD in <scale>)             [FORMULA = SUM(this brand's lines); bold, SUM-BAR]
  Operating income — <Brand>                              (USD in <scale>)             [FORMULA = <Brand> revenue − Total Costs and Expenses — <Brand>; bold, SUM-BAR]
  Operating income — <Brand> (reported)                   (USD in <scale>)             [deepKPI INPUT — the reported segment operating income, where the issuer reports one]
  Memo: segment OI modeled − reported (must ≈ 0)          (USD in <scale>)             [FORMULA; italic; laid with the reported row, omitted with it where no reported figure exists]
<Brand> — Costs as % of segment revenue                                                [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <Brand> revenue)       [FORMULA = brand cost ÷ brand revenue; italic; basis in the cell comment; the D&A row a derived read in every column, as in §3.3]
  Total Costs and Expenses — <Brand>                      (% of <Brand> revenue)       [FORMULA; italic; basis in the cell comment]
<Brand 2> …                                                                            [repeat the whole block]
```

**Segment denominator (STRICT).** The % walkdown for a brand divides each brand
cost by **that brand's revenue**, **never** by total consolidated revenue: a cost
that belongs to one brand (Chili's, say) is a share of that brand's revenue, not of
the parent's. That brand's revenue is the row, or the sum of the rows, the revenue hand-back's
**segment map** names for it (`../../SKILL.md`, "The segment map") — `Total Revenue —
<Brand> (modeled)` in the comparable-stores build, the brand's `Revenue from
Restaurants` in the revenue-per-restaurant build. Never pick the rows by label, and
name the brand as the map spells it; a brand the map does not name gets no block
(§1's gate). For
restaurant-level lines, prefer that brand's **company restaurant sales** if the
revenue build separated it; otherwise that brand's revenue.

- Each brand's cost lines are reported **deepKPI segment inputs** (from the
  `Segment Financials` category); `Total Costs and Expenses — <Brand>` is a live
  `SUM`.
- The brand D&A `%` row is a derived read in every column (§3.3), never a driver, at
  the brand level too.
- If the location build is per brand, the §4 per-company-owned-location block is
  also built **per brand** here (using that brand's cost lines and EOP count).
- One blank spacer row separates each brand's block from the next.

### 5.3 — The consolidated costs table (always built under Path C1)

After the per-brand blocks, lay one **consolidated costs table** that combines the
brands and foots to the reported consolidated operating block. **This is the §2 /
§3 table, lifted to the consolidated level**, with each line summing the brands:

```
Consolidated Costs                                                                     [sub-header: bold + underlined, size 12 — per the styling contract]
    <each cost line that appears in the brands>           (USD in <scale>)             [FORMULA = Σ that line across brands]
    <corporate-only line, e.g. General and administrative>  (USD in <scale>)             [deepKPI INPUT — reported consolidated; see note]
    Depreciation and amortization                         (USD in <scale>)             [FORMULA = Σ brand D&A, or reported consolidated input]
  Total Costs and Expenses                                (USD in <scale>)             [FORMULA = SUM(consolidated lines); bold, SUM-BAR]
    Total Costs and Expenses (reported)                   (USD in <scale>)             [deepKPI INPUT — the reported anchor]
    Memo: Total Costs and Expenses sum − reported (must = 0)  (USD in <scale>)         [FORMULA check; 0 every period]
Consolidated Costs — % of revenue                                                      [sub-header: bold + underlined, size 12]
    <each line>                                           (% of total revenue)         [FORMULA = consolidated line ÷ Total Revenue; basis in the cell comment; the D&A row a derived read in every column, as in §3.3]
  Total Costs and Expenses                                (% of total revenue)         [FORMULA = Total opex ÷ Total Revenue; basis in the cell comment]
  Operating margin                                        (% of total revenue)         [FORMULA = Operating Income (modeled) ÷ Total Revenue — the §3.2 read, laid here too]
```

**Corporate-only lines (important).** Some cost lines exist **only at the
corporate / parent level** and do **not** appear in any brand segment — most
commonly **General & administrative expenses**, and sometimes consolidated
pre-opening or impairment. Carry each such
line in the **consolidated table only**, as a reported **deepKPI input** (it has
no segment lines to sum), and include it in the consolidated `Total operating
expenses`. In the consolidated **% table**, corporate-only lines are divided by
**total consolidated revenue** (§3.1).

**Followable summation (quality check 2).** Each consolidated cost line that maps
to the brands is a **`= SUM(` brand lines `)`** so the analyst can trace exactly
how the consolidated figure is built up from the segment figures; corporate-only
lines are clearly flagged (input, with a comment that they have no segment
detail). The consolidated `Total Costs and Expenses` then sums all consolidated
lines and ties to the reported figure via the memo check.

### 5.4 — Pre-delivery checklist (company-segment build)

- [ ] **One full $ + % walkdown per brand**, same brand order as the revenue
      build; each brand's % uses **that brand's revenue** as the denominator,
      never total revenue.
- [ ] No blended cross-brand ratios; brands meet only at the dollar level in the
      consolidated table.
- [ ] A single **`Consolidated Costs`** table sums each brand line
      (`= SUM(brands)`), carries any **corporate-only** lines as reported inputs
      (e.g. G&A), and foots to reported Total Costs and Expenses (memo = 0).
- [ ] Consolidated **% table** divides each line by **total revenue**; D&A
      excluded everywhere (dash + comment).
- [ ] §4 per-location block built per brand if a location build exists.
- [ ] The consolidated `Total Costs and Expenses` traces cleanly up from the
      segment lines (followable summation); after recalculation, **zero formula
      errors**.

---

## Section 6 — Geographic segment cost build (Path C2 only)

Build this section **only** when the gate (§1.5) found **geographic segments** —
i.e. the issuer reports operating costs separately by geography (e.g. domestic vs.
international, or by region). The structure mirrors §5, with **geography** in
place of **brand** and a geography-aware denominator.

### 6.1 — Per-geography block

For **each geography**, lay a self-contained §2 dollar walkdown and §3 %
walkdown for that geography's operating costs:

```
<Geography> — Costs                                                                    [geography header: bold + underlined, size 12]
    <each operating-cost line for this geography>         (USD in <scale>)             [deepKPI INPUT — that geography's reported costs]
  Total Costs and Expenses — <Geography>                  (USD in <scale>)             [FORMULA = SUM(this geography's lines); bold, SUM-BAR]
<Geography> — Costs as % of segment revenue                                            [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <Geography> revenue)   [FORMULA = geography cost ÷ geography revenue; italic; basis in the cell comment; the D&A row a derived read in every column, as in §3.3]
  Total Costs and Expenses — <Geography>                  (% of <Geography> revenue)   [FORMULA; italic; basis in the cell comment]
<Geography 2> …                                                                        [repeat]
```

**Geographic denominator (STRICT).** Divide each geography's cost by the **revenue
applicable to that geography** — but **only if the revenue build split revenue by
geography**: the denominator is the revenue of that same domestic or international
segment where the revenue build laid that split; **otherwise it is the company's
total revenue**. So:

- If the revenue build laid down geographic revenue lines (domestic /
  international / by region), reference the **matching geography's revenue** as the
  denominator.
- If revenue is **not** split by geography, divide each geography's cost by **total
  consolidated revenue** (and state this fallback in the cell comment, since the
  resulting ratio is a cost-to-total-revenue figure, not a true within-geography
  margin).

The geography D&A `%` row is a derived read in every column (§3.3), never a driver,
at the geography level too.

### 6.2 — The consolidated costs table (always built under Path C2)

Identical in form to §5.3: a `Consolidated Costs` table where each line is
`= SUM(` the geographies `)`, plus any **corporate-only** lines (reported inputs),
footing to reported Total Costs and Expenses (memo = 0), followed by the
consolidated **% of (total) revenue** table. The consolidated table is what makes
the geographic build foot and traceable.

### 6.3 — Pre-delivery checklist (geographic-segment build)

- [ ] **One full $ + % walkdown per geography**; each geography's % uses **that
      geography's revenue** as the denominator **if** revenue is split by
      geography, **else total revenue** (noted in the comment).
- [ ] A single **`Consolidated Costs`** table sums each line across geographies
      (`= SUM(geographies)`), carries any corporate-only lines as inputs, and foots
      to reported Total Costs and Expenses (memo = 0).
- [ ] Consolidated **% table** divides by total revenue; D&A excluded everywhere.
- [ ] §4 per-location block built if a location build exists.
- [ ] The consolidated total traces cleanly up from the geography totals; after
      recalculation, **zero formula errors**.

---

## Section 7 — Quality checks and the foot

Before declaring the cost build done, verify **both** required quality checks with
live formulas in the workbook (not by eyeballing):

### 7.1 — Operating Income foot (quality check 1)

The foot rows live in the §2 walkdown, laid once: `Operating Income (reported)`
beneath `Operating Income (modeled)` with `Memo: Operating Income modeled − reported
(must ≈ 0)`. This section lays nothing; it checks that the memo reads ≈ 0 in every
historical period. A non-zero gap means a missing or extra cost line, a D&A mismatch
or a revenue-base mismatch — fix it in the block, never plug it. `Operating Income
(modeled)` and `Operating Income (reported)` are the contract rows CONSOLIDATED
FINANCIALS and the orchestrator reference.

### 7.2 — Followable summation (quality check 2)

The analyst must be able to trace **how Total Costs and Expenses is summed up
across the segments and the costs within those segments**. Confirm:

- Every `Total Costs and Expenses` (each segment's and the consolidated) is a
  **live `= SUM(...)`** over visible line rows — never a hardcoded number.
- Under Path C1 / C2, each **consolidated** cost line is `= SUM(` the segment
  lines `)` (so the segment → consolidated roll-up is explicit), and any
  **corporate-only** line is clearly an input with a comment that it has no
  segment detail.
- The `sum − reported (must = 0)` memo on the consolidated `Total operating
  expenses` evaluates to **0** every period (completeness).

### 7.3 — Final recalculation

Recalculate the workbook (LibreOffice / the xlsx skill's `recalc.py`) and confirm
**zero formula errors**, that the Operating Income memo is ~0 every historical
period, and that the consolidated `sum − reported` memo is 0 every period.

---

## Section 8 — Worked example (illustrative): Chipotle-style consolidated build

A condensed illustration of **Path C0** (consolidated only, single brand, no
franchising — so company restaurant sales ≈ total revenue). Figures illustrative;
the actual build pulls every input from deepKPI and lets the formulas compute the
ratios and totals.

**§2 dollar walkdown (one fiscal year, USD in millions):** Food, beverage and
packaging 3,500; Labor 2,600; Occupancy 600; Other operating costs
1,400; General and administrative 700; Depreciation and amortization
400; Pre-opening costs 30; Impairment/closure/asset disposals 20.
`Total Costs and Expenses = SUM = 9,250`. Reported Total Costs and Expenses
= 9,250 → `sum − reported = 0`. ✓

**§3 % of revenue (total revenue 11,000; ≈ company sales here):** Food &
beverage 31.8%, Labor 23.6%, Occupancy 5.5%, Other 12.7%, G&A 6.4% (of total
revenue), Pre-opening 0.3%, Impairment 0.2% — each a live `cost ÷ revenue`
formula, and D&A 3.6% (400 ÷ 11,000) the same, a derived read (D&A dollars are
projected via the depreciation schedule, never from this row).
`Total Costs and Expenses — % of revenue = 9,250 ÷ 11,000 = 84.1%`
(operating margin ≈ 15.9%).

**§4 per-company-owned-location (EOP count 3,700):** Food & beverage per location
= 3,500 ÷ 3,700 ≈ 0.9459 (USD millions per location); Labor per location ≈ 0.7027;
Occupancy per location ≈ 0.1622 — all live formulas off the location build's EOP count.

**§7 foot:** Operating Income (modeled) = 11,000 − 9,250 = 1,750;
reported Income from Operations 1,750 → `modeled − reported = 0`. ✓

A **multi-brand** issuer (e.g. Brinker) instead runs §5: a full $ + % walkdown for
**Chili's** (costs ÷ Chili's company sales) and for **Maggiano's** (costs ÷
Maggiano's company sales), then a `Consolidated Costs` table summing the two
brands and adding the **corporate-only** `General and administrative` line, footing
to reported Total Costs and Expenses and to reported Operating Income.

---

## Section 9 — Projecting the build forward (the projection layer)

Sections §1–§8 build and quality-check the **historical** cost block. This section
explains how to populate the **projection columns** — the forward fiscal years
(`N+1 … N+5`, or whatever forward portion the **revenue build** actually laid
down). It adds **no new rows and no new line items**: every projection lives in the
**forward period columns of the rows already built** in §2–§7.

**Two ground rules that hold for the whole projection layer:**

1. **Never touch a historical cell or a historical formula.** Every value and
   formula in the historical columns (the four FYs `N−3 … N`) stays exactly as
   §2–§7 laid it down. This section writes **only** into the forward columns.
2. **Project only the columns the revenue build projected.** The cost projections
   reference forward **revenue** (and, for per-location costs, forward **unit
   counts**). A cost column can only be filled where the revenue build already laid
   down that forward period. If the revenue build did not project a given column,
   leave the matching cost column blank (dash) — do not invent a revenue base.

The entire projection rests on **one set of drivers**: the forward **% of revenue**
assumptions (§3). Everything else in the forward columns is a **placeholder** that
either (a) flows from those drivers (the dollar costs), or (b) carries a historical
formula forward (per-location costs, the Total-Operating-Expenses sum, modeled
Operating Income). Set the drivers first; the placeholders follow.

### 9.1 — The driver methodology (how every forward assumption is set)

**What is a driver.** The **forward `% of revenue` cells** in the
`Consolidated Costs — % of revenue` block (§3) — and the per-segment `% of segment
revenue` cells (§5 / §6) when those are projected — are the model's **true
assumptions**. They are the only cells in this build an analyst is meant to dial.
Every projected **dollar** cost is computed from them, so they are the **drivers**.

**Driver styling — RED font.** Mark **every forward driver cell red**, the styling
rules' color for **estimated / assumption values**. This makes the assumption set
visible at a glance and separates the drivers an analyst may change from the black
formula cells they should not. (Historical `% of revenue` cells stay **black live
formulas** — they are
derived, `cost ÷ base`, not drivers.) Placeholders are **not** red: projected dollar
costs, per-location costs, the `Total Costs and Expenses` sum, the `% of revenue`
total row, and modeled Operating Income are all **black formula** cells.

**Driver value methodology (apply to every driver row, identically).** When setting
what a driver equals across the projection horizon:

- **First projection year (`N+1`) = the default seed** (`../../SKILL.md`, Build
  mechanics), in this order: the **guided** value when the shared guidance table
  names this driver for `N+1` (the midpoint, hyperlinked to the exhibit, the comment
  quoting the issuer); else the latest year on the **issuer's normalized basis** when
  the filing discloses one (a red constant, the disclosure cited); else the **latest
  historical year as reported**, which the renderer writes as a live formula over the
  three most recent historical cells:

  ```
  N+1 driver  =  IF(ISNUMBER(<N>), <N>, IF(ISNUMBER(<N−1>), <N−1>, IF(ISNUMBER(<N−2>), <N−2>, 0)))
  ```

  and only when `N` is itself a disclosed distortion with no normalized figure, a
  reference to the latest clean year among `N−1` and `N−2`, the comment naming the
  distortion. No year is averaged and no CAGR is seeded; the first forward year
  continues the last actual, so there is no mechanical step at `N+1`.

- **Every later projection year (`N+2`, `N+3`, `N+4`, `N+5`) = the first projection
  year.** Each forward column references the `N+1` driver cell, so the assumption is
  **held flat** across the horizon:

  ```
  N+2 driver = <N+1 driver cell>
  N+3 driver = <N+1 driver cell>
  …and so on for every remaining projection year.
  ```

  (Referencing `N+1` directly — rather than the immediately prior column — means that
  if the analyst overrides `N+1`, the whole flat line moves with it.)

- **This pattern holds forward for every driver, in every block** (consolidated and,
  where projected, each segment). All of these forward cells are **red**, because the
  whole forward row is the assumption set. An analyst may **override any driver cell**
  by typing a value over the formula; the cell stays red to signal it is an
  assumption.

- **Episodic lines do not take the default seed.** Read `../episodicLines.md` now and
  seed each in-scope line by its rule: zero for a one-off, the disclosed remaining
  cost for a program the exit-cost note describes, a spike-resistant run-rate for a
  program the issuer runs every year. In this build the in-scope captions are
  impairment of long-lived assets or goodwill; closure costs and asset disposals;
  reorganization, realignment or restructuring charges; refranchising or system
  optimization gains and losses; lease termination and settlement items; and an
  "other (gains) and charges" line. Pre-opening costs, advertising funds expense and
  a recurring other operating income or expense line stay on the default seed. The cell
  comment and the Notes line read as that file prescribes.

- **D&A has no driver.** Depreciation & amortization is excluded from the `% of
  revenue` block (its `%` cell is a dash; §3.3) and is **not** projected here — its
  forward dollars reference the **depreciation schedule** (§9.3). Do not create a
  red driver for a total-D&A line. The one exception is a **component** line
  (`depreciation-schedule` §6.2, e.g. cloud-computing amortization): its `N+1` cell
  is a red driver equal to the `N` value, held flat.

### 9.2 — `Consolidated Costs — % of revenue` — set the forward drivers

This block (§3) is where the drivers live, so build it **first** in the forward
columns. For **each** `% of revenue` line **except D&A**:

- Leave the **historical** `%` cells exactly as §3 laid them (`= cost ÷ matched
  revenue base`, black).
- Fill the **forward** `%` cells with the §9.1 driver methodology — `N+1` = the default seed (guided, else the latest year), each later year `= the N+1 cell` — and color every forward
  cell **red**. An episodic line takes its seed from `../episodicLines.md` instead of
  the default seed (§9.1); it is red and flat forward like every other driver.
- **D&A**: the `%` cells stay the **black formula** `= D&A $ ÷ Total Revenue` in the
  forward columns too — a read off the depreciation schedule's dollars, never a
  driver.
- **`Total Costs and Expenses` (% row)**: this is **not** a driver — it is a derived
  read. Carry its historical formula forward unchanged: `= Total Costs and Expenses ÷
  Total Revenue` in each projection column (black). Its complement remains the modeled
  operating margin.

### 9.3 — `Consolidated Costs` ($) — project each dollar cost from its driver

With the drivers set, fill the forward **dollar** columns of the §2 walkdown.
**Do not alter any historical dollar value or the historical input styling.** For
each projection column:

- **Each operating-cost line except D&A** = its **forward `% of revenue` driver
  (this column) × the matching revenue base (this column)** — a **black live
  formula**, not a red cell (it is a placeholder derived from the driver):

  ```
  Projected cost $  =  <forward % driver, this col>  ×  <matched revenue base, this col>
  ```

  Use the **same revenue base the historical `%` used as its denominator** (§3.1):
  restaurant-level lines (food/beverage/packaging, labor, occupancy, other restaurant
  operating costs) × **company restaurant sales**; corporate lines (G&A, enterprise
  pre-opening / impairment) × **total revenue**. If the `%` was struck against a
  **segment-specific** base (e.g. a single brand's or a single subsidiary's revenue —
  Path C1 / C2), multiply by **that same segment base**, never by total company
  revenue. Read the denominator off the historical `%` cell's recipe so the forward
  `%`→`$` math is internally consistent. Reference the forward revenue cell the
  **revenue build** already laid down; never re-enter or re-derive a revenue number.

- **Advertising funds expense (consolidated advertising funds only)** = the
  REVENUE section's `Advertising funds revenue` stream, **same column**, referenced
  with a live formula — **not** `% × revenue base`. Where an issuer consolidates
  its franchisee-funded advertising funds, the contributions are revenue and the
  spend is this line, and the two move together; a percentage-of-revenue driver
  would let them drift apart and invent a margin on the fund. The line's `% of
  revenue` row (§3) then becomes a **memo** formula in the projection columns
  (black, `= expense ÷ total revenue`), not a red driver. A laid stream row carries
  a projected value in every column under both of the franchise block's modes
  (Mode A: units × comp; Mode B: pro rata off the block's driver), so this reference
  never meets a blank cell. Only if the revenue build laid no `Advertising funds
  revenue` stream at all (franchise revenue reported as a single line, so no fund
  stream exists anywhere) fall back to the `% × total revenue` driver and record
  the fallback in `BUILD_LOG.md`; the ratio row's cell comment already names
  the base.
- **Depreciation and amortization** = `= <DEPRECIATION SCHEDULE → Depreciation &
  Amortization, this col>`, the schedule's forward D&A
  (`../../depreciation-schedule/depreciation-schedule.md`, §6), referenced with a live
  formula — **not** `% × revenue`. The schedule is built before this section, so the
  row exists. A **component** line (schedule §6.2 — e.g. `Amortization of cloud
  computing arrangements`) is instead held flat: `N+1` is a red driver equal to the
  `N` cell, later years `= the N+1 cell`.

- **`Total Costs and Expenses`** = the **same `= SUM(...)`** formula carried into each
  projection column (black, bold, SUM-BAR). Never re-key it.

- **`Total Costs and Expenses (reported)`** and **`Memo: Total Costs and Expenses sum − reported`**: there
  is **no reported figure for a future period**, so leave **both memo cells blank**
  (dash) in every projection column. The completeness check is a historical-only
  control; do not fabricate a "reported" projection.

### 9.4 — `Cost per company-owned location` — carry the formulas forward

This block (§4) is **detail only** — it drives nothing and is not a set of
assumptions — so there is **no difference between its historical and projected
cells**: simply **carry the same formulas forward** into the projection columns
(black, no red). For each projection column:

```
Company-Operated EOP location count          = <location build's forward EOP balance, this col>
Food and beverage per location               = <F&B $, this col>       ÷ <EOP count, this col>
Labor per location                           = <Labor $, this col>     ÷ <EOP count, this col>
Occupancy / restaurant expenses per location = <Occupancy $, this col> ÷ <EOP count, this col>
```

The numerators are the forward dollar costs from §9.3; the denominator is the
**forward** company-owned EOP count from the location build. **Dependency:** these
per-location cells can only be filled where the location build **projected** unit
counts. If the location build laid down units for the historical years only, leave
the projection cells of this block **blank** (dash) — the same rule §9.5 applies to
segment detail. Per brand if the company is segmented (Path C1), using that brand's
forward costs and forward EOP count.

### 9.5 — Segment detail (§5 / §6) — project only where the segment build exists

Show **projected** segment values **only if the associated segment build exists for
the projection periods**. Two cases:

- **The segment is projected** (its revenue / cost breakdown was carried into the
  forward columns by the upstream build). Read `../segmentSpine.md` now and apply
  it: it names which level carries the forward drivers (the segment blocks when
  their lines are the face lines; the consolidated lines when the segments
  decompose costs differently, with the largest segment derived as the residual),
  and it is the one place where forward `%` cells are black reads and forward
  dollar lines are identity formulas rather than `% × base`. On the level that
  keeps its drivers, set them with the §9.1 methodology (red; `N+1` = the default
  seed, later years `= N+1`), divide a segment's ratios against **that segment's**
  forward revenue, and compute its forward dollar lines as `% × segment base`
  (black). Carry the `Total Costs and Expenses − Σ segment totals` memo into every
  projection column; it must read 0.

- **The segment breakdown is historical-only** (the upstream build never projected the
  per-brand / per-geography split). Then **show the segment block for the historical
  periods only and leave every projection cell of that block blank** (dash). Do **not**
  fabricate forward segment drivers or forward segment revenue that the model does not
  carry. The **consolidated** `% of revenue` drivers and consolidated dollar costs
  **still project** (§9.2–§9.3) — only the segment-level detail is left blank in the
  forward columns.

In both cases the consolidated `Total Costs and Expenses` continues to foot from
whatever lines are populated, and the segment → consolidated `= SUM(...)` roll-ups in
the historical columns are untouched.

### 9.6 — `Operating Income` — project modeled, leave reported blank

In the §7.1 Operating Income check block:

- **`Operating Income (modeled)`** — **carry the formula forward** into every
  projection column, unchanged: `= <Total Revenue, this col> − <Total operating
  expenses, this col>` (black). This is the projected operating profit that the
  `CONSOLIDATED FINANCIALS` section reads.
- **`Operating Income (reported)`** — **leave the projection cells blank** (dash);
  there is no reported actual for a future period. Keep the **historical** reported
  cells exactly as §7.1 laid them (deepKPI inputs).
- **`Memo: Operating Income modeled − reported (must ≈ 0)`** — this tie-out only has meaning where a
  reported figure exists, so leave its **projection cells blank** as well. The memo
  stays a historical-only control (≈ 0 every historical period).

### 9.7 — Worked illustration (projection mechanics)

Take the §8 consolidated example and project `Labor` one year. Suppose historical
`Labor % of company sales` reads **23.2% / 23.5% / 23.6% / 23.9%** across
`N−3 … N`. No guidance names labor, so the first projection driver is the latest
year: `N+1 = 23.9%` (the renderer's latest-year formula over `N−2 … N`) — a **red**
cell. `N+2 … N+5` each `= the N+1 cell`, so they all read **23.9%** (red, held flat).
If forward company restaurant sales for `N+1` is **11,600**, the §9.3 dollar cell is
`= 23.9% × 11,600 = 2,772.40` (**black** formula). `Total Costs and Expenses` sums that
forward column as before; `Operating Income (modeled) = forward Total Revenue −
forward Total Costs and Expenses` (black), while `Operating Income (reported)` and
both memo rows sit **blank** in the `N+1 … N+5` columns. D&A's forward dollars come
from the depreciation schedule; its `%` cells stay the black ratio formula.

### 9.8 — Pre-delivery checklist (projections)

- [ ] On a segment path, `../segmentSpine.md` was applied: one level carries the
      drivers, the other is derived, and the Σ-segments memo reads 0 in every
      projection column.

- [ ] Every episodic line named in §9.1 is seeded by `../episodicLines.md`, not the
      default seed; its cell comment states the treatment and the Notes carry the line.

- [ ] **No historical cell or formula changed** — projections live only in the
      forward columns the **revenue build** projected.
- [ ] **Forward `% of revenue` drivers are RED**, set as `N+1` = the default seed and each later year `= the N+1 cell` (held flat); historical `%` cells stay
      **black formulas**.
- [ ] **D&A** has **no** red driver — its `%` cells stay black formulas; its forward
      dollars reference the depreciation schedule's `Depreciation & Amortization` row
      (a component line is held flat instead; schedule §6.2).
- [ ] **Projected dollar costs are BLACK formulas** = forward `%` driver × the
      **matching** forward revenue base (the same denominator the historical `%` used:
      company sales / total revenue / segment base — never blindly total revenue).
- [ ] **`Total Costs and Expenses`** stays the live `= SUM(...)` in every projection
      column; the **reported** and **sum − reported** memo cells are **blank** for
      projections.
- [ ] **Per-location block** carries its `cost ÷ EOP count` formulas forward (black),
      blank where the location build did not project units.
- [ ] **Segment detail** projects **only** where the segment build exists forward;
      otherwise the segment block is blank in the projection columns while the
      consolidated block still projects.
- [ ] **`Operating Income (modeled)`** formula carried forward (black);
      **`Operating Income (reported)`** and the **modeled − reported** memo are
      **blank** in the projection columns; historicals untouched.
- [ ] After recalculation, **zero formula errors**; historical quality checks (§7)
      still pass unchanged.

---

## Section 10 — Downstream handoff

After the cost build is laid down, recalculated, and both quality checks pass:

- Confirm **zero formula errors**, the **Operating Income** memo ≈ 0 every
  historical period, and the consolidated `sum − reported` memo = 0 every period.
- The build deliberately leaves **D&A as the only operating line not projected
  here** — the **depreciation schedule**
  (`../../depreciation-schedule/depreciation-schedule.md`, built before this
  section) owns the D&A projection, and the §2 D&A row's projected cells reference
  its `Depreciation & Amortization` row.
- The **consolidated-financials** section will reference `Total Costs and
  Expenses` and `Operating Income (modeled)` directly when it assembles the
  income statement, so keep those row labels stable and the revenue-base
  references explicit.
- Hand control back to the costs router (`../costs.md`), which returns to the
  orchestrator to continue with the remaining sections.

---

*This build is part of the Revelata operating-model skill set. It writes only the
restaurant COSTS section (the operating-expense block walked down to Total
Operating Expenses, in dollars and as a % of revenue); D&A projection, the
consolidated statements, and all other sections are owned by their respective
skills.*

## Dependencies — rows this build references but does not lay

Per `../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Total Revenue` (`rev_total`) | revenue build | always | none — stop |
| each brand's revenue rows for the §5 brand blocks (`<Brand> revenue`; `Total Revenue — <Brand> (modeled)` or the brand's `Revenue from Restaurants`), as the revenue hand-back's segment map names them | revenue build (cohort / per-restaurant sub-build) | the segment map names the brand | no brand block for that brand: the segmentation gate takes a segment path only for brands the map names |
| `Company-Operated EOP Balance` (`coeop_total` / `coeop_<brand>`; the location build's forward EOP balance) for the per-location rows | location build | the revenue hand-back report shows a location build ran | omit the per-location rows; state why in the cell comment of the affected restaurant-level cost driver |
| `Depreciation & Amortization` (`dna`; DEPRECIATION SCHEDULE → Depreciation & Amortization) for forward D&A | depreciation schedule | always | none — stop |
