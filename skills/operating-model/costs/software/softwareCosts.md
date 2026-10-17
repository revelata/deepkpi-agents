---
name: costs-software
description: >
  Operating-cost build for software / technology companies in the operating-model
  workbook. Invoked by the costs router (`costs/costs.md`) when the company was
  classified as a software / technology business during the revenue build, and only
  AFTER the REVENUE section is fully built. Receives the resolved `company_id`,
  official company name, workbook path (with the REVENUE section already laid down),
  the shared KPI inventory, and the industry determination; builds the software cost
  structure beneath the `COSTS` ALL-CAPS header. The build reproduces the issuer's
  income-statement operating block — every cost line that sits between revenue and
  Income from Operations (e.g. cost of subscription revenue, cost of professional-
  services / license / product revenue, research & development, sales & marketing,
  general & administrative, amortization of acquired intangibles, restructuring /
  acquisition-related charges, depreciation & amortization) and NOTHING below the
  operating line (no interest, no taxes, no other income). It lays down (1) a dollar
  walkdown of cost of revenue → Gross Profit → operating expenses → Income from
  Operations, then (2) each cost line — every line EXCEPT a total depreciation &
  amortization line, whose forward dollars reference the depreciation schedule
  (built before this section), and amortization of acquired intangibles, which is
  held flat — as a live `=` % of its matched revenue
  base, which is the projection driver. A decision gate first reads whether the
  issuer reports its operating costs at the consolidated level only, by product /
  business (operating) segment, or by geographic segment: for business-segment
  reporters it runs a per-segment $ and % walkdown (denominator = that segment's
  revenue) plus a consolidated costs table; for geographic-segment reporters it runs
  a per-geography $ and % walkdown (denominator = that geography's revenue if revenue
  is split by geography, else total revenue) plus a consolidated table; the
  consolidated table also carries any corporate-only lines (e.g. G&A) that do not
  appear in the segment blocks. Pulls series via `search_kpis` from the shared
  inventory; format per ../../../_common/revelata-excel-styling-rules.md (one row per
  series, derived cells as live formulas) EXCEPT for time scope / columns, which this
  build matches to the revenue build. Quality checks: reported Gross Profit must
  equal Total Revenue − Total Cost of Revenue, reported Operating Income must equal
  Total Revenue − Total Costs and Expenses, and the consolidated totals must trace
  cleanly up from each segment's lines. Sections: §1 identify the cost lines +
  segmentation gate, §2 the dollar walkdown, §3 costs as a % of revenue, §4 business-
  segment build (conditional), §5 geographic-segment build (conditional), §6 quality
  checks + foot, §7 worked example, §8 the projection layer (driver methodology +
  projection columns), §9 downstream handoff.
---

# costs — software (operating-cost build)

This is the **software / technology-industry** cost build. It is invoked by the
costs router (`../costs.md`) when the company was classified as a **software /
technology** business during the revenue build. It owns the build of the **COSTS**
section for software companies — the income-statement **operating block** (cost of
revenue and operating expenses), walked down to **Income from Operations**, and
expressed both in **dollars** and as a **% of revenue** (the projection driver).

By the time control reaches this file, two things are already true:

1. the company **is in the software / technology industry** (decided by the revenue
   router and carried forward by the orchestrator), and
2. the **REVENUE section is already built** in the workbook, so cost lines can
   reference the revenue lines laid down there — total revenue, each revenue stream
   (subscription / recurring, professional services, license, product, other), and
   any segment revenue the revenue build carried.

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
  cost-to-revenue ratio lines up in the same column. The software revenue
  sub-builds (`arrBuild/`, `trBuild/`, `arpuBuild/`, `other/`) are built on the
  **four most recent fiscal years**, annual columns only. So in practice this build
  uses those **same four annual columns**, oldest → newest, in Col E onward. Do
  **not** introduce a different timeline, and do **not** add quarterly columns the
  revenue build did not lay down. (The full intended horizon is the canonical
  **Model timeline** in the orchestrator `../../SKILL.md` — the four historical
  fiscal years plus the five projection years, `N+1 … N+5`, after the last
  historical year; this section mirrors whatever portion of that timeline the
  upstream builds have laid down.) If the revenue build did carry a quarterly block,
  mirror it exactly (annual block, blank separator, quarterly block), with imputed
  quarters (`Q4 = FY − Q1 − Q2 − Q3`) as in-row live formulas per the styling rules.
- **Never silently substitute data.** If a deepKPI cost series for a specific cell
  is a clear data-quality artifact (order-of-magnitude scaling or a tagging error),
  do not transcribe it. Prefer a clean alternate deepKPI series; if none exists,
  take the value from the company's 10-K "Results of Operations" / "Consolidated
  Statements of Operations" table, mark that cell distinctly (gold fill, hyperlinked
  to that filing, with a cell comment that keeps the filing table), and record it
  in the Notes block, one line per override: "Costs: <line> FY<n> is taken from the
  10-K income statement; the database series was <scaled / mis-tagged / missing>."

> This build is authored section by section. The sections present here — §1 the
> cost-line identification + segmentation gate, §2 the dollar walkdown, §3 costs as
> a % of revenue, §4 the business-segment build, §5 the geographic-segment build,
> §6 quality checks, §7 a worked example, §8 the projection layer, and §9 the
> downstream handoff — are the implemented scope. Do **not** build or add any
> information outside the sections present here.

---

## Cost build — framework overview

This build turns the issuer's reported **operating-block line items** into a clean,
footing cost block beneath the `COSTS` header, and then turns each line into the
**cost-to-revenue ratio** that drives the projection. It follows one fixed framework
so that every software company is modeled the same way and the block always foots.

**The master identity (the foot / quality check):**

```
  Total Cost of Revenue     = Σ (each reported cost-of-revenue line item)
  Gross Profit              = Total Revenue − Total Cost of Revenue
  Total Operating Expenses  = Σ (each reported operating-expense line item: R&D, S&M, G&A, …)
  Total Costs and Expenses  = Total Cost of Revenue + Total Operating Expenses
  Income from Operations    = Total Revenue − Total Costs and Expenses
                            = Gross Profit − Total Operating Expenses
```

`Total Cost of Revenue` and `Total Operating Expenses` are each built as the **sum
of their individual cost lines** (live formulas). `Gross Profit` and `Income from
Operations` are then cross-checked against the issuer's **reported** Gross Profit and
Operating Income / Income from Operations KPIs — the modeled and reported values must
agree (§6). `Total Revenue` is the line the **revenue build** already laid down; this
build references it, it does not re-derive it.

> **Software terminology warning — read before building.** On a software income
> statement, **"Total operating expenses"** frequently means the **opex block only**
> (research & development, sales & marketing, general & administrative, and the
> like) and **excludes** cost of revenue — which is subtracted first to arrive at
> **Gross Profit**. This is different from a restaurant income statement, where
> "Total operating expenses" is everything above the operating line. This build
> respects the software convention: **cost of revenue and operating expenses are two
> distinct blocks**, separated by the **Gross Profit** subtotal, and the line that
> ties everything together is **Total Costs and Expenses** (= cost of revenue +
> opex). Some issuers instead present a single **"Total costs and expenses"** sum
> line with no gross-profit subtotal; when the issuer does present Gross Profit
> (almost all do), build the subtotal. Mirror the issuer's face-of-statement
> presentation exactly (§1.3).

**Build the cost section in this order** (each conditional step states its
trigger):

1. **§1 — Identify the operating-block line items** from deepKPI / the 10-K, and
   **decide the segmentation** (consolidated-only vs. product/business segments vs.
   geographic segments). This gate decides whether §4 or §5 is built.
2. **§2 — The dollar walkdown.** Lay every cost-of-revenue line, the `Gross Profit`
   subtotal, then every operating-expense line, footing to `Income from Operations`
   for every period column. (When the company reports by segment, this is the
   **consolidated** table that sits at the bottom; §4 / §5 build the per-segment
   walkdowns above it.)
3. **§3 — Costs as a % of revenue.** Express every cost line as a live `=` % of its
   matched revenue base, plus the `Gross Margin` and `Operating Margin` reads. This
   ratio is the **projection driver** — except for amortization of acquired
   intangibles and any standalone D&A, whose % row is a derived read in every column.
4. **§4 — Product / business (operating) segment build** (only if the gate found
   business segments). Per-segment $ and % walkdowns + the consolidated table.
5. **§5 — Geographic segment build** (only if the gate found geographic segments).
   Per-geography $ and % walkdowns + the consolidated table.
6. **§6 — Quality checks + foot.**

> **No per-unit cost sub-block.** Unlike the restaurant cost build (which expresses
> costs per company-owned location off a location roll-forward), this software build
> has **no per-unit cost section** — software cost structure is not modeled per
> customer or per user. Even where the revenue build laid down a customer
> roll-forward, do **not** manufacture a "cost per customer" block; it is out of
> scope for this build.

**Conventions that apply to every section (read once):**

- **Signs follow the income statement.** Costs are carried **positive**; a credit
  within costs (a gain on sale, a settlement credit, other operating income shown
  inside the cost block) is carried **negative**, exactly as the issuer presents it,
  so every subtotal is a plain `SUM`. A deepKPI value delivered with the opposite
  sign is carried with the filing's sign as a 10-K override (gold, hyperlinked, the
  comment stating the flip); the sign is never corrected inside a formula.
- **Reference the revenue build — do not re-derive revenue.** Every revenue figure
  this build divides by already exists in the workbook (the `Total Revenue` row, each
  `Revenue from <Stream>` row the revenue build laid, and any per-segment revenue
  subtotals). Reference those cells with
  live `=` formulas; never hardcode a revenue number or rebuild a revenue line here.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (each reported cost line, the reported Gross Profit and
  Operating Income used as checks, and any base-year lookback) are **input cells**
  (pale-green fill,
  dark-blue hyperlinked value linked to the
  filing). **Every other cost cell is a live `=` formula** (black font, no fill) — the
  `Total Cost of Revenue` and `Total Operating Expenses` sums, `Gross Profit`, `Income
  from Operations`, every `% of revenue` row, every segment subtotal, and every
  foot-check memo. Projected-period cost assumptions (the forward `% of revenue`) are
  **red** driver cells (the projection-driver convention — see §8). Never hardcode a
  computed number.
- **Scope is the operating block ONLY.** Build **only** the lines that sit between
  revenue and **Income from Operations** (§1.2). Do **not** add interest expense,
  interest / investment income, other income (expense), income taxes, equity-method
  items, or any below-the-operating-line item — those belong to the
  `CONSOLIDATED FINANCIALS` section, not here.
- **GAAP face lines only — no non-GAAP add-backs.** Reproduce the operating block
  **as presented on the face of the GAAP income statement**. Stock-based compensation
  is embedded inside the GAAP cost lines (allocated across cost of revenue and each
  opex line) and is **not** carved out as a separate line unless the issuer itself
  presents it as one on the face. Do **not** build non-GAAP / adjusted cost lines,
  SBC add-back rows, or "adjusted operating income" here — those are a separate
  presentation, out of scope.
- **Amortization of acquired intangibles and standalone D&A are carried in dollars
  but NOT projected as a % of revenue.** When the issuer presents **amortization of
  acquired intangibles** and/or a **standalone depreciation & amortization** line
  inside the operating block, those lines appear in the §2 dollar walkdown but are
  the lines **not** expressed as a % of revenue (§3); leave their `% of revenue`
  cells as a dash with a cell comment. Their forward dollars follow the
  partial-D&A-line rule of the **depreciation schedule**
  (`../../depreciation-schedule/depreciation-schedule.md`, §6.2), which the
  orchestrator builds **before** this section:
  - a standalone D&A line that is the issuer's **total** D&A (it equals the
    schedule's cash-flow `Depreciation & Amortization` in every historical column
    within rounding) references the schedule's forward D&A;
  - **`Amortization of acquired intangibles`**, and any D&A line that is only a
    component, is **held flat at its year-`N` value** (a red driver in `N+1` equal to
    the `N` cell, later years `= the N+1 cell`). It never references the schedule,
    whose forward D&A rolls off PP&E and is not a forecast of intangibles
    amortization. The hand-back report lists every such component line by key, as it lists the lines excluded from the issuer's adjusted measure; the consolidated section adds them to its total D&A so EBITDA adds back all depreciation and amortization.
  **If D&A is not a separate face line** (it is embedded within cost of revenue and
  the opex lines, as many software issuers present it), then there is no line to
  carve out here — every face line is projected as a % of revenue normally, and
  CONSOLIDATED FINANCIALS takes its D&A from the schedule directly. Which treatment
  applies is a block-wide fact, not a single cell's: state it in the Notes block,
  "Costs: depreciation and amortization is embedded in the cost lines; the operating
  block carries no separate D&A line." (or, where a face line exists, "Costs:
  depreciation and amortization is a separate line, taken from the depreciation
  schedule in the forecast.").
- **Label / comment / spacing discipline (same as the revenue builds).** Col C
  labels are **plain descriptive text** (the issuer's reported line name); the operand
  recipe for each formula row goes in a **cell comment on the Col C label cell**
  (author `Cost Build`), not in the visible label. Indentation, bold / border
  conventions, the italic percent rows, and the one-blank-row-between-blocks rule all
  follow `../../../_common/revelata-excel-styling-rules.md` exactly as the revenue builds
  do.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../_common/revelata-excel-units-and-scale.md`, and every row's family
  follows from that file's Rule 4 — an input row's from its deepKPI `unit` field, a
  derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.1, §3.2, §4.2,
  §4.3, §5.1 and §6.1 — and in the `Units (Col D)` column of that section's formula
  table. Dollar rows show the placeholder `(USD in <scale>)`: the contract's Rule 2
  supplies the scale, millions by default, thousands where the digit test puts a small
  filer. A bracketed placeholder inside a tag — `<Segment>`, `<Geography>`, `<§3.1
  base>` — is filled with the actual Col C label of the row the formula divides by.
  Three classifications are specific to this build:
  - **Percent rows name their denominator.** A cost-of-revenue line divides by its
    matched revenue stream and is tagged accordingly — `(% of subscription revenue)`,
    `(% of professional services revenue)`, `(% of license/product revenue)`; opex
    lines, the margins and the totals divide by total revenue and are tagged `(% of
    total revenue)`; segment and geography blocks use `(% of <Segment> revenue)` / `(%
    of <Geography> revenue)`. The basis still goes in the Col C cell comment as §3.2
    requires — the tag is the unit, the comment is the recipe.
  - **The D&A-type `% of revenue` rows are tagged `(% of total revenue)` like the
    operating-expense lines.** `Amortization of acquired intangibles` and any
    standalone `Depreciation and amortization` are live ratios in every column of the
    % block, derived reads — their dollars follow the depreciation schedule's
    partial-D&A-line rule (§8.3), never this row — so they are data rows and never
    drivers. When the issuer embeds D&A inside the face lines there is no such row at
    all.
  - **No per-unit rows.** This build carries no cost-per-customer or cost-per-seat block
    (see the framework-overview blockquote above), so every row that is not a percent is
    money.
- **Reading the layout blocks (§2.1, §3.2, §4.2, §4.3, §5.1, §6.1).** Each row's
  annotation has two columns, left to right: the **Col D units tag in parentheses** —
  `(USD in <scale>)` means the contract's Rule 2 sets the money scale; every other tag
  is written as it goes in the cell — and the note in **square brackets**: `[deepKPI
  INPUT …]` for a pulled value, `[FORMULA …]` for a computed row, `[DASH …]` for a
  deliberately empty cell, plus styling (`SUM-BAR`, `italic`). Sub-header lines, the
  `<Segment 2> …` repeat markers carry no tag.
- **Header hierarchy (per the styling contract).** Only the **ALL-CAPS `COSTS`
  section header** gets the big-header treatment — **bold, underlined, size 16**.
  Every **title-case sub-header beneath it** (`Consolidated Costs`,
  `Consolidated Costs — % of revenue`, and the per-segment / per-geography headers) is **bold, underlined, size 12** at the indent
  the contract's block-header rule gives it — the one sub-header treatment every
  section shares (`../../../_common/revelata-excel-styling-rules.md`). Do **not** set
  them to size 16; that big-header look is reserved for the one ALL-CAPS `COSTS` row.

The sub-sections below specify each piece cell-by-cell. Build them in order; do not
add cost lines outside this framework.

---

## Section 1 — Identify the operating-block line items and decide the segmentation

This first section does no workbook writing of its own. It (a) reads the issuer's
operating block, (b) maps each line to a deepKPI series, and (c) decides **how the
costs are segmented**, which determines whether the build is a single consolidated
walkdown (§2 – §3 only) or a per-segment build (§4 or §5) plus a consolidated table.

### 1.1 — Where the cost lines live

Software operating costs are disclosed in the issuer's **MD&A "Results of
Operations"** table and, authoritatively, in the **"Consolidated Statements of
Operations"** (sometimes "…and Comprehensive Loss") in the financial statements.
Both present the same operating block: a set of **cost of revenue** lines that sum to
**Total Cost of Revenue**, a **Gross Profit** subtotal, then a set of **operating
expense** lines (R&D, S&M, G&A, …) that sum to **Total Operating Expenses**, with
**Income (Loss) from Operations** immediately below.

In the **shared KPI inventory** these lines live under the **`Consolidated Income
Statement`** category (and, when the issuer reports cost by segment, under **`Segment
Financials`**). Read that category first to see exactly which cost-of-revenue and
operating-expense lines the issuer reports — do **not** assume a generic set.

### 1.2 — Scope rule (STRICT): only the lines that sit between revenue and Income from Operations

Build **every** line the issuer lists **between** revenue and **Income from
Operations**, and **nothing else**:

- **Include** the cost-of-revenue lines (e.g. cost of subscription revenue, cost of
  professional-services revenue, cost of license revenue, cost of product / hardware
  revenue) and the operating-expense lines (research & development, sales & marketing,
  general & administrative, amortization of acquired intangibles, restructuring /
  acquisition-related / impairment charges, and any standalone depreciation &
  amortization). The exact set and labels are issuer-specific (§1.3).
- **Exclude — do not add — anything below the operating line.** No interest expense,
  interest / investment income, other income (expense), income tax provision, equity
  in earnings, or net-income subtotals. Those are owned by the `CONSOLIDATED
  FINANCIALS` section. This restriction is deliberate and strict: only the lines that
  roll up into Total Costs and Expenses belong here.

The discipline checks are that **Σ (cost-of-revenue lines) = reported Total Cost of
Revenue**, **Σ (operating-expense lines) = reported Total Operating Expenses**, and
**Total Revenue − (both blocks) = reported Income from Operations** (§6). If a sum
does not tie, you have either **missed a line** the issuer reports inside the block or
**included one** that sits below the operating line — fix the line set, do **not**
paper over it with an invented "other costs" plug.

### 1.3 — The canonical line-item set (use the issuer's exact lines)

A common software operating block — and the canonical example for this build — reads:

```
  Cost of subscription revenue
  Cost of professional services revenue                (issuer may combine or split cost-of-revenue streams)
  [Cost of license / product revenue]                  (if the issuer sells licenses / hardware)
  Total cost of revenue
  Gross profit
  Research and development
  Sales and marketing
  General and administrative
  Amortization of acquired intangibles                 (if presented as its own operating line)
  Restructuring / acquisition-related charges          (if reported separately)
  Total operating expenses
  Income (loss) from operations
```

**The actual line items vary by issuer — use the issuer's reported labels and
groupings, not these defaults.** Some issuers report a **single** `Cost of revenue`
line rather than splitting it by stream; some fold amortization of acquired
intangibles into cost of revenue and each opex line rather than presenting it
separately; some add a `Restructuring` or `Impairment` line only in years they incur
it. Mirror exactly what the issuer presents between revenue and Income from
Operations — same lines, same order, same labels (Col C uses the issuer's wording).

### 1.4 — Map each line to a deepKPI series

For each line in the issuer's operating block, find the matching series with
`search_kpis` against the **shared inventory** (never re-run `list_kpis`). Match on
the issuer's wording plus the `- Annual` suffix, e.g. `Cost of subscription revenue -
Annual`, `Cost of professional services revenue - Annual`, `Cost of revenue -
Annual`, `Research and development expense - Annual`, `Sales and marketing expense -
Annual`, `General and administrative expense - Annual`, `Amortization of acquired
intangibles - Annual`, `Restructuring charges - Annual`, `Total cost of revenue -
Annual`, `Total operating expenses - Annual`, and the check lines `Gross profit -
Annual` and `Income from operations - Annual` / `Operating income - Annual`.

- Prefer **annual** (`- Annual`) series across the build window (the four FYs the
  revenue build used). If the revenue build also carried a quarterly block, pull the
  matching `- 3 Month` quarterly series onto the **same row** (annual block +
  quarterly block), and impute any missing quarter as `Q4 = FY − Q1 − Q2 − Q3` in
  that row's column (live formula), per the styling rules.
- Sanity-check each value against the series trend and the 10-K table; reject obvious
  artifacts and fall back to the 10-K figure (gold-fill override) per the time-scope
  rule above.
- Pull the **reported Total Cost of Revenue**, **reported Gross Profit**, **reported
  Total Operating Expenses**, and **reported Income from Operations / Operating
  Income** series too — they are used as the §6 foot checks (the workbook's subtotal
  and total rows are always the **sum / difference formulas**, not the inputs).

### 1.5 — Segmentation decision gate (run before any cost line is written)

Decide **which presentation** the cost block gets, by reading how the issuer reports
its operating costs. Check the **`Segment Financials`** category of the shared
inventory and the 10-K segment footnote / MD&A; **do not guess**:

- **Path C0 — consolidated only (default).** The issuer reports a **single**
  operating block for the whole company (one set of cost lines). Build **§2 + §3
  only** (the consolidated walkdown and its % table). Most software companies report a
  single reportable segment and are here.
- **Path C1 — product / business (operating) segments.** The issuer reports operating
  costs (or a segment-level cost decomposition) broken out by **reportable operating
  segment that corresponds to a distinct product line or business** (e.g. Oracle's
  Cloud & License / Hardware / Services; Adobe's Digital Media / Digital Experience;
  Microsoft's three segments). Build **§4** — a per-segment $ and % walkdown — **then**
  the §2 / §3 consolidated table at the bottom (which sums the segments and adds any
  corporate-only lines).
- **Path C2 — geographic segments.** The issuer reports operating costs broken out by
  **geography** (e.g. Americas / EMEA / APAC, or domestic vs. international). Build
  **§5** — a per-geography $ and % walkdown — **then** the §2 / §3 consolidated table
  at the bottom.

> **What counts as a segment (be precise).** A **segment** is a distinct product /
> business (Path C1) or a distinct geography (Path C2) for which the issuer reports
> its **own operating costs**. Two very common software splits are **NOT** segments:
> a split of **cost of revenue into cost of subscription vs. cost of services** is a
> cost-of-revenue **decomposition within a single segment** (handled by the matched
> revenue bases in §3, not by a per-segment build); and a split of **revenue into
> subscription vs. license vs. services** is a **revenue-mix split**, not a segment.
> Only a genuine **reportable-segment breakout of costs** (two or more product /
> business segments, or two or more geographies, each with its own reported costs)
> triggers a per-segment cost build. If a company operates several product lines but
> reports operating costs **only on a consolidated basis**, it is **Path C0** (you
> cannot build per-segment cost walkdowns from costs that are not disclosed per
> segment). Note that many software issuers disclose segment **revenue** and a segment
> **operating income / profit** but **not** a full cost-line decomposition per
> segment; in that case build per-segment only to the depth the issuer actually
> discloses (often just segment revenue → segment operating income), and rely on the
> consolidated table for the full line-item walkdown.

State which path you picked and why (one line, citing the specific segment KPIs that
did or did not exist), before writing any cost line, so the routing is auditable. A
company resolves to **exactly one** of C0 / C1 / C2; build only that path's structure. A segment path also requires the
revenue hand-back's **segment map** (`../../SKILL.md`, "The segment map") to name
every segment the path would lay, corporate-only blocks excepted: a segment block
needs that segment's revenue for its ratios and its operating-income line, and a
segment the map does not name is carried at the consolidated level, never struck
against a blended base.

---

## Section 2 — The dollar walkdown (Consolidated Costs)

This section lays the issuer's operating block in **dollars** for every period
column: the cost-of-revenue lines footing to `Total Cost of Revenue`, the `Gross
Profit` subtotal, the operating-expense lines footing to `Total Operating Expenses`,
and `Income from Operations`. Under **Path C0** this is the whole dollar build. Under
**Path C1 / C2** this is the **consolidated** table that sits **beneath** the
per-segment walkdowns (§4 / §5) and **sums** them — see those sections for how the
consolidated lines reference the segment lines.

### 2.1 — Layout for the dollar walkdown

```
COSTS                                                                                  [ALL-CAPS section header — already in the scaffold]

Consolidated Costs                                                                     [sub-header: bold + underlined, size 12 — per the styling contract]
    Cost of subscription revenue                          (USD in <scale>)             [deepKPI INPUT — issuer's line]
    Cost of professional services revenue                 (USD in <scale>)             [deepKPI INPUT]
    Cost of license / product revenue                     (USD in <scale>)             [deepKPI INPUT — if reported]
  Total cost of revenue                                   (USD in <scale>)             [FORMULA = SUM(cost-of-revenue lines); bold, SUM-BAR]
    Total cost of revenue (reported)                      (USD in <scale>)             [deepKPI INPUT — the reported anchor, where the issuer reports a total of two or more lines; omitted with its memo otherwise]
    Memo: Total cost of revenue sum − reported (must = 0)  (USD in <scale>)            [FORMULA check; italic; 0 every period]
  Gross profit                                            (USD in <scale>)             [FORMULA = Total Revenue − Total cost of revenue; bold, SUM-BAR]
    Gross profit (reported)                               (USD in <scale>)             [deepKPI INPUT — the reported anchor; only where the issuer presents a gross-profit subtotal]
    Memo: Gross profit modeled − reported (must ≈ 0)      (USD in <scale>)             [FORMULA check; italic; ≈ 0 every period]
    Research and development                              (USD in <scale>)             [deepKPI INPUT]
    Sales and marketing                                   (USD in <scale>)             [deepKPI INPUT]
    General and administrative                            (USD in <scale>)             [deepKPI INPUT]
    Amortization of acquired intangibles                  (USD in <scale>)             [deepKPI INPUT — historicals; ref to D&A schedule for projections]
    Restructuring / acquisition-related charges           (USD in <scale>)             [deepKPI INPUT — if reported separately]
  Total operating expenses                                (USD in <scale>)             [FORMULA = SUM(opex lines); bold, SUM-BAR]
  Total Costs and Expenses                                (USD in <scale>)             [FORMULA = Total cost of revenue + Total operating expenses; bold, SUM-BAR — the all-in contract row CONSOLIDATED FINANCIALS and NET WORKING CAPITAL reference]
  Operating Income (modeled)                              (USD in <scale>)             [FORMULA = Total Revenue − Total Costs and Expenses; bold, SUM-BAR — contract row]
    Operating Income (reported)                           (USD in <scale>)             [deepKPI INPUT — the reported anchor (Income from operations) — contract row]
    Memo: Operating Income modeled − reported (must ≈ 0)  (USD in <scale>)             [FORMULA check; italic; ≈ 0 every period]
```

- Each cost line is **one row** across the period columns (annual block, then the
  quarterly block if the revenue build carried one), per the one-row-per-series rule.
  Do **not** fragment a line into per-period rows.
- **A line the issuer reports in some years and not others** (restructuring,
  impairment, a gain or loss on assets) keeps its row across all columns, with a
  numeric **0** in the years it was not incurred (the number format displays it as a
  dash). Never the text dash: the projection seed in §8.1 tests those cells with ISNUMBER (a run-rate seed with COUNT and MEDIAN), and a text dash would make it skip the year;
  text is invisible to both. Do not delete the row and do not leave a hole
  that breaks the `SUM` range.
- `Total cost of revenue` and `Total operating expenses` are each a **live `=
  SUM(...)`** over their own line rows — never inputs, never hardcoded. `Gross profit`
  and `Operating Income (modeled)` are **difference formulas**. This is what makes the
  summation **followable** (quality check 2).
- The memo rows cross-check each subtotal against the issuer's **reported** figure (an
  input); the difference must be **0** (cost of revenue) or **≈ 0** (gross profit,
  operating income) every period. A non-zero difference means a missing or extra line
  (§1.2) — resolve it.

### 2.2 — The formulas (cell-by-cell) for the dollar walkdown

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Cost of subscription revenue` (and each cost-of-revenue / opex line) | DATA_DEPENDENT | `(USD in <scale>)` | historicals: deepKPI **input** $ (green, hyperlinked); projections: `= <its % of revenue, this col> × <matched revenue base, this col>` (see §3) | *(no comment on input rows — provenance via hyperlink; projection rows note `"= % of revenue × revenue base"`)* |
| `Total cost of revenue` | | `(USD in <scale>)` | `= SUM(` the cost-of-revenue rows above `)` | `"Σ of every cost-of-revenue line. Must tie to reported Total Cost of Revenue (memo below)."` |
| `Gross profit` | DATA_DEPENDENT | `(USD in <scale>)` | `= <Total Revenue, this col> − <Total cost of revenue, this col>` | `"Total revenue (revenue build) − total cost of revenue. Cross-checked to reported gross profit (memo below)."` |
| `Amortization of acquired intangibles` / standalone `Depreciation and amortization` | DATA_DEPENDENT | `(USD in <scale>)` | historicals: deepKPI **input** $; projections: a total-D&A line `= <DEPRECIATION SCHEDULE → Depreciation & Amortization, this col>`; amortization of acquired intangibles (a component line) held flat at its year-`N` value as a red driver (§8.3) | `"Historicals: reported. Projections: a total-D&A line references the DEPRECIATION SCHEDULE's Depreciation & Amortization; a component line is held flat — never a % of revenue."` |
| `Total operating expenses` | | `(USD in <scale>)` | `= SUM(` the opex rows above `)` | `"Σ of every operating-expense line (opex block only, excludes cost of revenue). Must tie to reported Total Operating Expenses."` |
| `Operating Income (modeled)` | | `(USD in <scale>)` | `= <Total Revenue, this col> − <Total Costs and Expenses, this col>` | `"Gross profit − total operating expenses. Cross-checked to reported operating income (memo below)."` |
| `Total Costs and Expenses` | | `(USD in <scale>)` | `= <Total cost of revenue, this col> + <Total operating expenses, this col>` | `"All-in total of every cost line between revenue and Operating Income (modeled): cost of revenue plus operating expenses. CONSOLIDATED FINANCIALS (Total Costs) and NET WORKING CAPITAL (DPO and % of Total Costs drivers) reference it by this label. Operating Income (modeled) = Total Revenue − this row."` |
| `Total cost of revenue (reported)` | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** $ (reported), where the issuer reports a total of two or more cost-of-revenue lines; omitted with its memo when there is no reported total or the issuer reports a single cost-of-revenue line (that line is the total — lay it, lay `Total cost of revenue` as its sum, and nothing to check) | *(no comment — input row)* |
| `Memo: Total cost of revenue sum − reported (must = 0)` | DATA_DEPENDENT | `(USD in <scale>)` | `= <Total cost of revenue, this col> − <Total cost of revenue (reported), this col>` | `"Completeness check: 0 means every cost-of-revenue line is captured."` |
| `Gross profit (reported)` | HAS_GROSS_PROFIT_ROW | `(USD in <scale>)` | deepKPI **input** $ (reported) | *(no comment — input row)* |
| `Memo: Gross profit modeled − reported (must ≈ 0)` | HAS_GROSS_PROFIT_ROW | `(USD in <scale>)` | `= <Gross profit, this col> − <Gross profit (reported), this col>` | `"Completeness check: ≈ 0 means the cost-of-revenue block is complete."` |
| `Operating Income (reported)` | | `(USD in <scale>)` | deepKPI **input** $ (Income from operations) — contract row | *(no comment — input row)* |
| `Memo: Operating Income modeled − reported (must ≈ 0)` | | `(USD in <scale>)` | `= <Operating Income (modeled), this col> − <Operating Income (reported), this col>` | `"Must be ≈ 0 every historical period. A non-zero gap means a missing or extra cost line or a revenue-base mismatch — fix it in the block, never plug it."` |

- In **historical** columns every cost line is a reported **deepKPI input**, and the
  subtotals / totals are the sum / difference formulas.
- In **projected** columns every cost line **except amortization of acquired
  intangibles / standalone D&A** flips to `= % × revenue base` (the % is the **red**
  driver from §3, set per §8), those D&A-type lines follow the schedule's
  partial-D&A-line rule (§8.3: reference or flat hold), and the subtotal / total rows keep the same sum / difference formulas.

### 2.3 — Pre-delivery checklist (dollar walkdown)

- [ ] Every line in the issuer's operating block (cost of revenue AND opex) is
      present, in the issuer's order and wording; **no** below-the-operating-line item
      was added.
- [ ] Each cost line is **one row** (annual block; quarterly block + imputed Q4 only
      if the revenue build carried quarterlies); historicals are deepKPI inputs
      (green, hyperlinked).
- [ ] `Total cost of revenue` and `Total operating expenses` are **live `= SUM(...)`**;
      `Gross profit` and `Operating Income (modeled)` are **difference formulas** (bold,
      correct borders), never hardcoded.
- [ ] The `sum − reported (must = 0)` memo on cost of revenue is **0**, and the
      `modeled − reported (must ≈ 0)` memos on gross profit and operating income are
      **≈ 0**, every period after recalculation.
- [ ] Styling per the styling rules; after recalculation, **zero formula errors**.

---

## Section 3 — Costs as a % of revenue (the projection driver)

This section expresses **each cost line as a live `=` % of its matched revenue
base**, plus the `Gross Margin` and `Operating Margin` reads. This ratio is the
**driver**: it is how the line is read for analysis and how it is **projected**
(projected $ line = % × revenue base). **Every line is expressed as a % EXCEPT
amortization of acquired intangibles and any standalone D&A**, which follow the
depreciation schedule's partial-D&A-line rule (§8.3).

### 3.1 — Choosing the revenue base ("respective revenue")

Match each cost line to the revenue base it is actually incurred against — the
"respective revenue" — and divide by **that** base, not blindly by total revenue. The
default mapping (and the basis on which software issuers themselves present these
ratios in MD&A):

- **Cost-of-revenue lines** — each cost-of-revenue stream is matched to **its own
  revenue stream**, so the ratio's complement is that stream's **gross margin**. The
  revenue build lays one **`Revenue from <Stream>`** row per stream (the contract row,
  `../../SKILL.md`, "Contract rows"), with `<Stream>` the issuer's own caption: cost of
  subscription revenue ÷ `Revenue from Subscription`; cost of professional-services
  revenue ÷ `Revenue from Professional Services`; cost of license / product revenue ÷
  `Revenue from License` / `Revenue from Product`. **Match by the stream name in the
  cost line's caption, by label** — never by which revenue sub-build ran. Where the
  issuer's two captions differ (`Cost of subscription revenue` against `Revenue from
  Cloud Services`), pair them the way the 10-K's own presentation pairs them and state
  the pairing in the Col C comment. If **no** `Revenue from <Stream>` row matches — the
  issuer reports a **single** `Cost of revenue` line, or the revenue build cut revenue
  by reportable segment rather than by type — divide by **`Total Revenue`**; the
  comment keeps the denominator and the Notes block carries one line, "Costs: cost
  of revenue is one reported line, so its ratio is struck against total revenue."
  Never reconstruct a stream revenue here.
- **Operating-expense lines** — research & development, sales & marketing, general &
  administrative, and restructuring / acquisition-related charges are enterprise-level
  and matched against **total revenue**.
- **Amortization of acquired intangibles / standalone D&A** — matched against
  **total revenue**, a derived read in every column, never a driver (the dollars
  follow the schedule's partial-D&A-line rule, §8.3).

When the issuer's MD&A presents a specific ratio against a specific base (e.g.
"subscription gross margin" or "cost of subscription revenue as a percentage of
**subscription revenue**"), **follow the issuer's base**. State the base each line
uses in the Col C cell comment so the choice is auditable. Reference the revenue base
cell that the **revenue build** actually laid down, by its label — the `Total Revenue`
row, a `Revenue from <Stream>` row, or a reported segment-revenue row if present.

### 3.2 — Layout for the % of revenue block

Place the `% of revenue` block **immediately beneath** the matching dollar block so
each ratio sits one row under its dollar line and in the same column. Mirror the
dollar line order:

```
Consolidated Costs — % of revenue                                                      [sub-header: bold + underlined, size 12 — per the styling contract]
    Cost of subscription revenue                          (% of subscription revenue)  [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Cost of professional services revenue                 (% of professional services revenue)  [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Cost of license / product revenue                     (% of license/product revenue)  [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
  Gross margin                                            (% of total revenue)         [FORMULA = Gross profit ÷ Total Revenue; italic, bold; basis in the cell comment]
    Research and development                              (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Sales and marketing                                   (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    General and administrative                            (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Amortization of acquired intangibles                  (% of total revenue)         [FORMULA = amortization $ ÷ Total Revenue in every column; italic; derived read, not a driver — the dollars follow §8.3]
    Restructuring / acquisition-related charges           (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
  Total Costs and Expenses                                (% of total revenue)         [FORMULA = Total Costs and Expenses ÷ Total Revenue; italic, bold; complement = operating margin]
  Operating margin                                        (% of total revenue)         [FORMULA = Operating Income (modeled) ÷ Total Revenue; italic, bold; basis in the cell comment]
```

**Label rule (STRICT).** The Col C label for each % row is **just the cost line
name** — identical to its dollar line (e.g. `Cost of subscription revenue`, `Sales
and marketing`) — and is **never** suffixed with `— % of subscription revenue` / `—
% of revenue`. The enclosing `Consolidated Costs — % of revenue` sub-header already
signals that every row in the block is a percentage, so the suffix is redundant in
the label. Put the **basis** (which revenue denominator the ratio divides by — the
matching stream revenue for a cost-of-revenue line, total revenue for an opex line)
in the **Col C cell comment** for that row, not in the visible label. The `Gross
margin` and `Operating margin` reads keep their descriptive labels (they are
subtotals, not cost lines).

(If preferred, the % may instead be carried as an italic memo row **directly under
each dollar line** within the §2 block rather than as a separate block — either
arrangement is acceptable as long as every line except the D&A-type lines has a
visible, live `% of revenue` cell and the column alignment to the dollar line is
exact. Pick one arrangement and apply it sheet-wide.)

### 3.3 — The formulas (cell-by-cell) for the % of revenue block

The Col C label is the **bare cost-line name** (no `— % of …` suffix); the basis goes
in the comment.

| Row (plain Col C label — no suffix) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `<cost-of-revenue stream>` (e.g. `Cost of subscription revenue`) | | `(% of <§3.1 base>)` | historicals: `= <cost $ line, this col> ÷ <matching stream revenue, this col>`; projections: **red driver input** (see §8) | `"% of <stream> revenue. Cost-of-revenue stream ÷ its matching revenue stream; complement = that stream's gross margin. Projection driver."` |
| `Gross margin` | HAS_GROSS_PROFIT_ROW | `(% of total revenue)` | `= <Gross profit, this col> ÷ <Total Revenue, this col>` | `"% of total revenue. Gross profit ÷ total revenue. A read, not a driver."` |
| `<operating-expense line>` (e.g. `Sales and marketing`) | | `(% of total revenue)` | historicals: `= <cost $ line, this col> ÷ <Total Revenue, this col>`; projections: **red driver input** (see §8) | `"% of total revenue. Opex line ÷ total revenue. Projection driver."` |
| `Amortization of acquired intangibles` / standalone `Depreciation and amortization` | DATA_DEPENDENT | `(% of total revenue)` | `= <that $ line, this col> ÷ <Total Revenue, this col>` in **every** column, historical and projected; black, italic; never a driver | `"% of total revenue. Derived read, not a driver — the dollars follow the depreciation schedule's rule (a total-D&A line references the DEPRECIATION SCHEDULE; amortization of acquired intangibles is held flat), never this row."` |
| `Operating margin` | | `(% of total revenue)` | `= <Operating Income (modeled), this col> ÷ <Total Revenue, this col>` | `"% of total revenue. Income from operations ÷ total revenue. A read, not a driver."` |

- **Historical** % cells are **live formulas** (cost ÷ base, or subtotal ÷ revenue) —
  black font (not green; they are derived, not inputs) — with the accounting
  **percent** format and italic styling per the styling rules.
- **Projected** % cells for the cost lines become **red driver inputs** (the
  assumption the analyst sets; see §8 for the driver styling and value methodology),
  and the corresponding **dollar** line in §2 flips to `= % × revenue base`. Anchor
  each forward % on the historical trend plus management guidance (cost-of-revenue
  ratios trending with cloud-infrastructure and services-delivery leverage; S&M as the
  base scales and the mix shifts toward renewals; R&D intensity; G&A leverage).
- **`Gross margin` and `Operating margin` are reads, not drivers** — they are always
  derived formulas (never red), historical and projected alike. They are convenient
  because gross margin is the headline software profitability read and operating
  margin bridges directly to the §6 Operating Income check.

### 3.4 — Pre-delivery checklist (% of revenue)

- [ ] Every cost line has a live `% of revenue` cell; the D&A-type rows are black
      formulas in every column, their comment stating the dollars' projection basis
      (§8.3).
- [ ] Each % row's Col C label is the **bare cost-line name** (no `— % of …` suffix);
      the basis lives in the **cell comment**.
- [ ] Each cost-of-revenue line's denominator is its **matching revenue stream** (or
      total revenue if cost of revenue is a single line); each opex line's denominator
      is **total revenue**; every base is **referenced from the revenue build** (not
      re-entered) and stated in the cell comment.
- [ ] `Gross margin` and `Operating margin` reads are present as derived formulas
      (never red drivers).
- [ ] Historical % cells are **live formulas**; projected cost-line % cells are **red
      drivers** (§8), and the projected **$** line equals `% × revenue base`.
- [ ] % rows use the accounting **percent** format, italic; aligned one row under (or
      beside) the matching dollar line, same column.
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Product / business (operating) segment cost build (Path C1 only)

Build this section **only** when the gate (§1.5) found **product / business
segments** — i.e. the issuer reports operating costs (or a segment-level cost
decomposition) separately for two or more **reportable operating segments** (e.g.
Oracle's Cloud & License / Hardware / Services). Do **not** blend the segments; build
a **complete $ and % walkdown per segment**, then a single **consolidated costs
table** that combines them.

### 4.1 — Why per segment, never blended

Each segment has a different cost structure (gross margin, R&D intensity, S&M load)
and a different revenue base. Dividing one segment's costs by another's revenue, or
summing the segments before computing ratios, silently corrupts every ratio. Build
each segment on **its own** reported cost lines and **its own** revenue base (from the
revenue build's per-segment revenue), and let the segments meet only at the **dollar
level** in the consolidated table, where summing is always valid.

### 4.2 — Per-segment block (the full walkdown for one segment)

For **each segment**, lay a self-contained block — the §2 dollar walkdown (to the
depth the issuer discloses per segment) and the §3 % walkdown — for **that segment's**
operating costs, in the same segment order as the revenue build's per-segment blocks:

```
<Segment> — Costs                                                                      [segment header: bold + underlined, size 12]
    <each cost line disclosed for this segment>           (USD in <scale>)             [deepKPI INPUT — that segment's reported costs]
  Total Costs and Expenses — <Segment>                                 (USD in <scale>)             [FORMULA = SUM(this segment's cost lines); bold, SUM-BAR]
  Segment operating income — <Segment>                    (USD in <scale>)             [FORMULA = <segment revenue> − <segment total costs>, or the reported segment operating income input; bold, SUM-BAR]
  Segment operating income — <Segment> (reported)         (USD in <scale>)             [deepKPI INPUT — the reported segment operating income, where the issuer reports one]
  Memo: segment OI modeled − reported (must ≈ 0)          (USD in <scale>)             [FORMULA; italic; laid with the reported row, omitted with it where no reported figure exists]
<Segment> — Costs as % of segment revenue                                              [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <Segment> revenue)     [FORMULA = segment cost ÷ segment revenue; italic, except the D&A-type lines; basis in the cell comment]
  Segment operating margin — <Segment>                    (% of <Segment> revenue)     [FORMULA = segment operating income ÷ segment revenue; italic]
<Segment 2> …                                                                          [repeat the whole block]
```

**Segment denominator (STRICT).** The % walkdown for a segment divides each segment
cost by **that segment's revenue**, **never** by total consolidated revenue.
That segment's revenue is the row, or the sum of the rows, the revenue hand-back's
**segment map** names for it (`../../SKILL.md`, "The segment map"): one stream, or an
ARPU stream plus the segment's other-revenue stream. Write the sum in the formula;
never pick the rows by label, and name the segment as the map spells it. A segment
the map does not name gets no block (§1's gate). For a cost-of-revenue line disclosed at the segment level, prefer that segment's
matching **stream** revenue if the revenue build separated it; otherwise that
segment's revenue.

- Each segment's cost lines are reported **deepKPI segment inputs** (from the `Segment
  Financials` category); `Total Costs and Expenses — <Segment>` is a live `SUM`.
- The D&A-type lines (amortization of acquired intangibles / standalone D&A) are still
  excluded from the % walkdown (dash + comment) at the segment level too.
- Build per-segment only to the **depth the issuer actually discloses** — many
  software issuers report only segment revenue and segment operating income (not a
  full cost-line split), in which case the per-segment block is just those two lines
  and the full line-item walkdown lives in the consolidated table.
- One blank spacer row separates each segment's block from the next.

### 4.3 — The consolidated costs table (always built under Path C1)

After the per-segment blocks, lay one **consolidated costs table** that combines the
segments and foots to the reported consolidated operating block. **This is the §2 /
§3 table, lifted to the consolidated level**, with each line summing the segments:

```
Consolidated Costs                                                                     [sub-header: bold + underlined, size 12 — per the styling contract]
    <each cost line that appears in the segments>         (USD in <scale>)             [FORMULA = Σ that line across segments]
    <corporate-only line, e.g. General and administrative>  (USD in <scale>)             [deepKPI INPUT — reported consolidated; see note]
    Amortization of acquired intangibles                  (USD in <scale>)             [FORMULA = Σ segment amortization, or reported consolidated input]
  Total cost of revenue                                   (USD in <scale>)             [FORMULA = SUM(consolidated cost-of-revenue lines); bold, SUM-BAR]
  Gross profit                                            (USD in <scale>)             [FORMULA = Total Revenue − Total cost of revenue; bold, SUM-BAR]
  Total operating expenses                                (USD in <scale>)             [FORMULA = SUM(consolidated opex lines); bold, SUM-BAR]
  Total Costs and Expenses                                (USD in <scale>)             [FORMULA = Total cost of revenue + Total operating expenses; bold, SUM-BAR — contract row]
  Income from operations                                  (USD in <scale>)             [FORMULA = Gross profit − Total operating expenses; bold, SUM-BAR]
    Gross profit (reported) / Operating Income (reported)  (USD in <scale>)            [deepKPI INPUT — the reported anchors, laid once beneath their modeled rows as in §2.1]
    Memo: … modeled − reported (must ≈ 0)                 (USD in <scale>)             [FORMULA checks; ≈ 0 every period; one per anchor, labeled as in §2.1]
Consolidated Costs — % of revenue                                                      [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <§3.1 base>)           [FORMULA = consolidated line ÷ its matched base; except the D&A-type lines; basis in the cell comment]
  Gross margin / Operating margin                         (% of total revenue)         [FORMULA reads]
```

**Corporate-only lines (important).** Some cost lines exist **only at the corporate /
parent level** and do **not** appear in any operating segment — most commonly
**General & administrative expenses**, and sometimes consolidated restructuring or
amortization of acquired intangibles (which issuers frequently do not push down to
segment operating income). Carry each such line in the **consolidated table only**, as
a reported **deepKPI input** (it has no segment lines to sum), and include it in the
consolidated totals. In the consolidated **% table**, corporate-only opex lines are
divided by **total consolidated revenue** (§3.1).

**Followable summation (quality check 2).** Each consolidated cost line that maps to
the segments is a **`= SUM(` segment lines `)`** so the analyst can trace exactly how
the consolidated figure is built up from the segment figures; corporate-only lines are
clearly flagged (input, with a comment that they have no segment detail). The
consolidated subtotals then sum their lines and tie to the reported figures via the
memo checks.

### 4.4 — Pre-delivery checklist (business-segment build)

- [ ] **One full $ + % walkdown per segment** (to the depth disclosed), same segment
      order as the revenue build; each segment's % uses **that segment's revenue** as
      the denominator, never total revenue.
- [ ] No blended cross-segment ratios; segments meet only at the dollar level in the
      consolidated table.
- [ ] A single **`Consolidated Costs`** table sums each segment line (`= SUM(segments)`),
      carries any **corporate-only** lines as reported inputs (e.g. G&A), and foots to
      reported Gross Profit and Operating Income (memos ≈ 0).
- [ ] Consolidated **% table** divides each cost-of-revenue line by its stream (or
      total revenue) and each opex line by **total revenue**; the D&A-type lines
      excluded everywhere (dash + comment); `Gross margin` / `Operating margin` reads
      present.
- [ ] The consolidated totals trace cleanly up from the segment lines (followable
      summation); after recalculation, **zero formula errors**.

---

## Section 5 — Geographic segment cost build (Path C2 only)

Build this section **only** when the gate (§1.5) found **geographic segments** — i.e.
the issuer reports operating costs separately by geography (e.g. Americas / EMEA /
APAC, or domestic vs. international). The structure mirrors §4, with **geography** in
place of **business segment** and a geography-aware denominator.

### 5.1 — Per-geography block

For **each geography**, lay a self-contained §2 dollar walkdown and §3 % walkdown for
that geography's operating costs (to the depth disclosed):

```
<Geography> — Costs                                                                    [geography header: bold + underlined, size 12]
    <each cost line disclosed for this geography>         (USD in <scale>)             [deepKPI INPUT — that geography's reported costs]
  Total Costs and Expenses — <Geography>                               (USD in <scale>)             [FORMULA = SUM(this geography's cost lines); bold, SUM-BAR]
  Operating income — <Geography>                          (USD in <scale>)             [FORMULA = <geography revenue> − <geography total costs>, or reported input; bold, SUM-BAR]
<Geography> — Costs as % of segment revenue                                            [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <Geography> revenue)   [FORMULA = geography cost ÷ geography revenue; italic, except the D&A-type lines; basis in the cell comment]
  Operating margin — <Geography>                          (% of <Geography> revenue)   [FORMULA; italic]
<Geography 2> …                                                                        [repeat]
```

**Geographic denominator (STRICT).** Divide each geography's cost by the **revenue
applicable to that geography** — but **only if the revenue build split revenue by
geography**. So:

- If the revenue build laid down geographic revenue lines (Americas / EMEA / APAC,
  domestic / international, or by region), reference the **matching geography's
  revenue** as the denominator.
- If revenue is **not** split by geography, divide each geography's cost by **total
  consolidated revenue** (and state this fallback in the cell comment, since the
  resulting ratio is a cost-to-total-revenue figure, not a true within-geography
  margin).

The D&A-type `%` rows are derived reads in every column (§3.3), never drivers, at the
geography level too.

### 5.2 — The consolidated costs table (always built under Path C2)

Identical in form to §4.3: a `Consolidated Costs` table where each line is `= SUM(` the
geographies `)`, plus any **corporate-only** lines (reported inputs), footing to
reported Gross Profit and Operating Income (memos ≈ 0), followed by the consolidated **%
of (total) revenue** table with the `Gross margin` / `Operating margin` reads. The
consolidated table is what makes the geographic build foot and traceable.

### 5.3 — Pre-delivery checklist (geographic-segment build)

- [ ] **One full $ + % walkdown per geography** (to the depth disclosed); each
      geography's % uses **that geography's revenue** as the denominator **if** revenue
      is split by geography, **else total revenue** (noted in the comment).
- [ ] A single **`Consolidated Costs`** table sums each line across geographies
      (`= SUM(geographies)`), carries any corporate-only lines as inputs, and foots to
      reported Gross Profit and Operating Income (memos ≈ 0).
- [ ] Consolidated **% table** divides by the matched base; the D&A-type lines excluded
      everywhere; `Gross margin` / `Operating margin` reads present.
- [ ] The consolidated totals trace cleanly up from the geography totals; after
      recalculation, **zero formula errors**.

---

## Section 6 — Quality checks and the foot

Before declaring the cost build done, verify **all** required quality checks with live
formulas in the workbook (not by eyeballing):

### 6.1 — Gross Profit and Operating Income foots (quality check 1)

The foot rows live in the §2 walkdown, laid once: `Gross profit (reported)` beneath
`Gross profit` with `Memo: Gross profit modeled − reported (must ≈ 0)` where the issuer
presents a gross-profit subtotal, and `Operating Income (reported)` beneath `Operating
Income (modeled)` with `Memo: Operating Income modeled − reported (must ≈ 0)`. This
section lays nothing; it checks that the memos read ≈ 0 in every historical period. A
non-zero gap means a missing or extra cost line or a revenue-base mismatch — fix it in
the block, never plug it. `Operating Income (modeled)` and `Operating Income (reported)`
are the contract rows CONSOLIDATED FINANCIALS and the orchestrator reference.

### 6.2 — Followable summation (quality check 2)

The analyst must be able to trace **how the totals are summed up across the segments
and the cost lines within those segments**. Confirm:

- `Total cost of revenue` and `Total operating expenses` (each segment's and the
  consolidated) are **live `= SUM(...)`** over visible line rows — never hardcoded;
  `Gross profit` and `Operating Income (modeled)` are difference formulas.
- Under Path C1 / C2, each **consolidated** cost line is `= SUM(` the segment lines `)`
  (so the segment → consolidated roll-up is explicit), and any **corporate-only** line
  is clearly an input with a comment that it has no segment detail.
- The `sum − reported` / `modeled − reported` memos evaluate to **0 / ≈ 0** every
  period (completeness).

### 6.3 — Final recalculation

Recalculate the workbook (LibreOffice / the xlsx skill's `recalc.py`) and confirm
**zero formula errors**, that the Gross Profit and Operating Income memos are ≈ 0 every
historical period, and that the consolidated `sum − reported` memo on cost of revenue
is 0 every period.

---

## Section 7 — Worked example (illustrative): SaaS-style consolidated build

A condensed illustration of **Path C0** (consolidated only, single reportable
segment, subscription + professional-services streams). Figures illustrative; the
actual build pulls every input from deepKPI and lets the formulas compute the ratios
and totals.

**§2 dollar walkdown (one fiscal year, USD in millions):** Cost of subscription revenue
420; Cost of professional services revenue 260. `Total cost of revenue = SUM =
680`. Total revenue 3,000 (subscription 2,400; professional services
600). `Gross profit = 3,000 − 680 = 2,320` → reported gross profit
2,320, `modeled − reported = 0`. ✓  Operating expenses: Research and development
630; Sales and marketing 1,140; General and administrative 300;
Amortization of acquired intangibles 90. `Total operating expenses = SUM =
2,160`. `Income from operations = 2,320 − 2,160 = 160` → reported
160, `modeled − reported = 0`. ✓

**§3 % of revenue:** Cost of subscription revenue 17.5% (of subscription revenue →
subscription gross margin 82.5%); Cost of professional services revenue 43.3% (of
services revenue); **Gross margin = 2,320 ÷ 3,000 = 77.3%**; R&D 21.0%, S&M
38.0%, G&A 10.0% (each of total revenue) — live `cost ÷ base` formulas; amortization
of acquired intangibles 3.0% (90 ÷ 3,000) the same, a derived read (its dollars are
projected per §8.3, never from this row). **Operating margin = 160 ÷ 3,000 = 5.3%**.

**§6 foot:** Gross profit (modeled) = 3,000 − 680 = 2,320 → `= 0`;
Operating Income (modeled) = 2,320 − 2,160 = 160 → `= 0`. ✓

A **multi-segment** issuer (e.g. an issuer reporting Cloud vs. License vs. Hardware)
instead runs §4: a full $ + % walkdown for each segment (each segment's costs ÷ that
segment's revenue), then a `Consolidated Costs` table summing the segments and adding
the **corporate-only** `General and administrative` line, footing to reported Gross
Profit and Operating Income.

---

## Section 8 — Projecting the build forward (the projection layer)

Sections §1–§7 build and quality-check the **historical** cost block. This section
explains how to populate the **projection columns** — the forward fiscal years (`N+1 …
N+5`, or whatever forward portion the **revenue build** actually laid down). It adds
**no new rows and no new line items**: every projection lives in the **forward period
columns of the rows already built** in §2–§6.

**Two ground rules that hold for the whole projection layer:**

1. **Never touch a historical cell or a historical formula.** Every value and formula
   in the historical columns (the four FYs `N−3 … N`) stays exactly as §2–§6 laid it
   down. This section writes **only** into the forward columns.
2. **Project only the columns the revenue build projected.** The cost projections
   reference forward **revenue**. A cost column can only be filled where the revenue
   build already laid down that forward period. If the revenue build did not project a
   given column, leave the matching cost column blank (dash) — do not invent a revenue
   base.

The entire projection rests on **one set of drivers**: the forward **% of revenue**
assumptions (§3). Everything else in the forward columns is a **placeholder** that
either (a) flows from those drivers (the dollar costs), or (b) carries a historical
formula forward (the subtotals, `Gross profit`, `Operating Income (modeled)`, the margin
reads). Set the drivers first; the placeholders follow.

### 8.1 — The driver methodology (how every forward assumption is set)

**What is a driver.** The **forward `% of revenue` cells** in the `Consolidated Costs
— % of revenue` block (§3) — and the per-segment `% of segment revenue` cells (§4 / §5)
when those are projected — are the model's **true assumptions**. They are the only
cells in this build an analyst is meant to dial. Every projected **dollar** cost is
computed from them, so they are the **drivers**. (The `Gross margin` and `Operating
margin` reads are **not** drivers — they are derived from the projected dollar lines.)

**Driver styling — RED font.** Mark **every forward driver cell red**, the styling rules' color for **estimated / assumption values**. This
makes the assumption set visible at a glance and separates the drivers an analyst may
change from the black formula cells they should not. (Historical `% of revenue` cells
stay **black live formulas** — they are derived, `cost ÷ base`, not drivers.)
Placeholders are **not** red: projected dollar costs, the subtotal / total rows,
`Gross profit`, `Operating Income (modeled)`, and the margin reads are all **black
formula** cells.

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
  restructuring, acquisition-related or impairment charges; gains or losses on real
  estate, leases or asset sales the issuer presents inside the operating block; and
  litigation or settlement items. Amortization of acquired intangibles is not in
  scope (§8.3 holds it flat). The cell comment and the Notes line read as that file
  prescribes.

- **The D&A-type lines have no % driver.** Amortization of acquired intangibles and
  any standalone D&A sit in the `% of revenue` block as derived reads, black ratio
  formulas in every column (§3.3). Their forward dollars follow the depreciation schedule's
  partial-D&A-line rule (§8.3): a total-D&A line references the schedule and gets no
  driver at all; amortization of acquired intangibles is held flat, its only red
  driver being the `N+1` dollar cell equal to the `N` value.

### 8.2 — `Consolidated Costs — % of revenue` — set the forward drivers

This block (§3) is where the drivers live, so build it **first** in the forward
columns. For **each** `% of revenue` cost line **except the D&A-type lines**:

- Leave the **historical** `%` cells exactly as §3 laid them (`= cost ÷ matched
  revenue base`, black).
- Fill the **forward** `%` cells with the §8.1 driver methodology — `N+1` = the default seed (guided, else the latest year), each later year `= the N+1 cell` — and color every forward
  cell **red**. An episodic line takes its seed from `../episodicLines.md` instead of
  the default seed (§8.1); it is red and flat forward like every other driver.
- **The D&A-type lines**: the `%` cells stay the **black formula** `= $ line ÷ Total
  Revenue` in the forward columns too — a read off the §8.3 dollars, never a driver.
- **`Gross margin` and `Operating margin`**: these are **not** drivers — they are
  derived reads. Carry their historical formulas forward unchanged (`= Gross profit ÷
  Total Revenue` and `= Operating Income (modeled) ÷ Total Revenue`) in each projection
  column (black).

### 8.3 — `Consolidated Costs` ($) — project each dollar cost from its driver

With the drivers set, fill the forward **dollar** columns of the §2 walkdown. **Do
not alter any historical dollar value or the historical input styling.** For each
projection column:

- **Each cost line except the D&A-type lines** = its **forward `% of revenue` driver
  (this column) × the matching revenue base (this column)** — a **black live formula**,
  not a red cell (it is a placeholder derived from the driver):

  ```
  Projected cost $  =  <forward % driver, this col>  ×  <matched revenue base, this col>
  ```

  Use the **same revenue base the historical `%` used as its denominator** (§3.1):
  each cost-of-revenue stream × **its matching revenue stream** (or total revenue if
  cost of revenue is a single line); each opex line (R&D, S&M, G&A, restructuring) ×
  **total revenue**. If the `%` was struck against a **segment-specific** base (Path
  C1 / C2), multiply by **that same segment base**, never by total company revenue.
  Read the denominator off the historical `%` cell's recipe so the forward `%`→`$` math
  is internally consistent. Reference the forward revenue cell the **revenue build**
  already laid down; never re-enter or re-derive a revenue number.

- **Standalone D&A (the issuer's total D&A)** = `= <DEPRECIATION SCHEDULE →
  Depreciation & Amortization, this col>`, the schedule's forward D&A
  (`../../depreciation-schedule/depreciation-schedule.md`, §6), referenced with a live
  formula — **not** `% × revenue`. The schedule is built before this section, so the
  row exists. The test for "total": the line equals the schedule's cash-flow D&A in
  every historical column within rounding (schedule §6.2).
- **Amortization of acquired intangibles** (and any D&A line that is only a
  component) = **held flat**: `N+1` is a red driver equal to the `N` cell, later years
  `= the N+1 cell`. It never references the schedule — PP&E-derived D&A is not a
  forecast of intangibles amortization. An analyst holding the 10-K's future
  amortization table may override the red cells with it.

- **`Total cost of revenue` / `Total operating expenses`** = the **same `= SUM(...)`**
  formulas carried into each projection column; **`Gross profit`** and **`Income from
  operations`** = the **same difference formulas** carried forward. Never re-key them.

- **The reported cross-check memos** (`reported Total Cost of Revenue`, `reported Gross
  Profit`, `reported Income from Operations`, and their `− reported` memos): there is
  **no reported figure for a future period**, so leave **all reported and memo cells
  blank** (dash) in every projection column. The completeness / foot checks are
  historical-only controls; do not fabricate a "reported" projection.

### 8.4 — Segment detail (§4 / §5) — project only where the segment build exists

Show **projected** segment values **only if the associated segment build exists for
the projection periods**. Two cases:

- **The segment is projected** (its revenue / cost breakdown was carried into the
  forward columns by the upstream build). Read `../segmentSpine.md` now and apply
  it: it names which level carries the forward drivers (the segment blocks when
  their lines are the face lines; the consolidated lines when the segments
  decompose costs differently, with the largest segment derived as the residual),
  and it is the one place where forward `%` cells are black reads and forward
  dollar lines are identity formulas rather than `% × base`. On the level that
  keeps its drivers, set them with the §8.1 methodology (red; `N+1` = the default
  seed, later years `= N+1`), divide a segment's ratios against **that segment's**
  forward revenue, and compute its forward dollar lines as `% × segment base`
  (black). Carry the `Total Costs and Expenses − Σ segment totals` memo into every
  projection column; it must read 0.

- **The segment breakdown is historical-only** (the upstream build never projected the
  per-segment / per-geography split). Then **show the segment block for the historical
  periods only and leave every projection cell of that block blank** (dash). Do **not**
  fabricate forward segment drivers or forward segment revenue that the model does not
  carry. The **consolidated** `% of revenue` drivers and consolidated dollar costs
  **still project** (§8.2–§8.3) — only the segment-level detail is left blank in the
  forward columns.

In both cases the consolidated subtotals continue to foot from whatever lines are
populated, and the segment → consolidated `= SUM(...)` roll-ups in the historical
columns are untouched.

### 8.5 — `Gross profit`, `Operating Income (modeled)`, and the foot — project modeled, leave reported blank

In the §2 walkdown and the §6.1 foot-check block:

- **`Gross profit (modeled)`** and **`Operating Income (modeled)`** — **carry the
  difference formulas forward** into every projection column, unchanged (black). This
  projected operating income is what the `CONSOLIDATED FINANCIALS` section reads.
- **The `reported` rows** (`Gross profit (reported)`, `Income from operations
  (reported)`) — **leave the projection cells blank** (dash); there is no reported
  actual for a future period. Keep the **historical** reported cells exactly as §6.1
  laid them (deepKPI inputs).
- **The `modeled − reported` memos** — this tie-out only has meaning where a reported
  figure exists, so leave its **projection cells blank** as well. The memos stay
  historical-only controls (≈ 0 every historical period).

### 8.6 — Worked illustration (projection mechanics)

Take the §7 consolidated example and project `Sales and marketing` one year. Suppose
historical `Sales and marketing % of total revenue` reads **39.0% / 38.5% / 38.2% /
38.0%** across `N−3 … N`. No guidance names the line, so the first projection driver
is the latest year: `N+1 = 38.0%` (the renderer's latest-year formula over `N−2 … N`)
— a **red** cell. `N+2 … N+5` each `= the N+1 cell`, so they all read **38.0%** (red,
held flat). If forward total revenue for `N+1` is **3,300**, the §8.3 dollar cell is
`= 38.0% × 3,300 = 1,254.00` (**black** formula). `Total operating expenses` sums that
forward column; `Gross profit (modeled)` and `Operating Income (modeled)` carry
their difference formulas forward (black), while the reported rows and all `− reported`
memos sit **blank** in the `N+1 … N+5` columns. Amortization of acquired intangibles'
forward dollars are held flat at the `N` value (red driver); its `%` cell stays a dash; the
`Operating margin` read recomputes off the projected lines.

### 8.7 — Pre-delivery checklist (projections)

- [ ] On a segment path, `../segmentSpine.md` was applied: one level carries the
      drivers, the other is derived, and the Σ-segments memo reads 0 in every
      projection column.

- [ ] Every episodic line named in §8.1 is seeded by `../episodicLines.md`, not the
      default seed; its cell comment states the treatment and the Notes carry the line.

- [ ] **No historical cell or formula changed** — projections live only in the forward
      columns the **revenue build** projected.
- [ ] **Forward `% of revenue` drivers are RED**, set as `N+1` = the default seed
      and each later year `= the N+1 cell` (held flat); historical `%` cells stay
      **black formulas**.
- [ ] **The D&A-type lines** have **no** `%` driver — their `%` cells stay black
      formulas; their forward dollars follow §8.3 (a total-D&A line references the schedule's
      `Depreciation & Amortization`; amortization of acquired intangibles is held
      flat).
- [ ] **Projected dollar costs are BLACK formulas** = forward `%` driver × the
      **matching** forward revenue base (the same denominator the historical `%` used:
      stream revenue / total revenue / segment base — never blindly total revenue).
- [ ] **`Total cost of revenue`, `Total operating expenses`, `Gross profit`, `Income
      from operations`** keep their live sum / difference formulas in every projection
      column; the **reported** and **− reported** memo cells are **blank** for
      projections.
- [ ] **`Gross margin` and `Operating margin`** reads carry their derived formulas
      forward (black).
- [ ] **Segment detail** projects **only** where the segment build exists forward;
      otherwise the segment block is blank in the projection columns while the
      consolidated block still projects.
- [ ] After recalculation, **zero formula errors**; historical quality checks (§6) still
      pass unchanged.

---

## Section 9 — Downstream handoff

After the cost build is laid down, recalculated, and the quality checks pass:

- Confirm **zero formula errors**, the **Gross Profit** and **Operating Income** memos
  ≈ 0 every historical period, and the consolidated `sum − reported` memo on cost of
  revenue = 0 every period.
- The build deliberately leaves **the D&A-type lines as the only operating lines not
  projected as a % of revenue**: a total-D&A line references the **depreciation
  schedule** (`../../depreciation-schedule/depreciation-schedule.md`, built before this
  section), and amortization of acquired intangibles is held flat (§8.3). (If D&A is
  embedded within the cost lines rather than a separate face line, the Notes block
  says so in the wording the framework overview gives; CONSOLIDATED FINANCIALS takes
  its D&A from the schedule directly.)
- The **consolidated-financials** section references `Total Costs and Expenses` (the
  all-in contract row — never `Total operating expenses`, which here is the opex-only
  subtotal below gross profit) and `Operating Income (modeled)`; the **net-working-
  capital** section references `Total Costs and Expenses` for its DPO and `% of Total
  Costs` drivers and `Total cost of revenue` for DIO. Keep those row labels stable and
  the revenue-base references explicit.
- Hand control back to the costs router (`../costs.md`), which returns to the
  orchestrator to continue with the remaining sections.

---

*This build is part of the Revelata operating-model skill set. It writes only the
software COSTS section (the operating block — cost of revenue and operating expenses
— walked down to Income from Operations, in dollars and as a % of revenue, with the
D&A-type lines projected per §8.3); the depreciation schedule, the consolidated
statements, and all other sections are owned by their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Total Revenue` (`rev_total`) | revenue build | always | none — stop |
| `Revenue from <Stream>` (`rev_<stream>`) as a cost-of-revenue denominator | software revenue build | the stream is laid (match by label per §this build's matching rule) | `Total Revenue` |
| each segment's revenue rows for the §4 segment blocks (`<segment revenue>`), as the revenue hand-back's segment map names them | revenue build | the segment map names the segment | no segment block for that segment: the segmentation gate takes a segment path only for segments the map names |
| `Depreciation & Amortization` (`dna`) | depreciation schedule | always | none — stop |
