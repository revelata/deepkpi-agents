---
name: costs-retail
description: >
  Operating-cost build for retail / consumer-merchandise companies in the
  operating-model workbook. Invoked by the costs router (`costs/costs.md`) when the
  company was classified as a retail business during the revenue build, and only
  AFTER the REVENUE section is fully built. Receives the resolved `company_id`,
  official company name, workbook path (with the REVENUE section already laid down),
  the shared KPI inventory, and the industry determination; builds the retail cost
  structure beneath the `COSTS` ALL-CAPS header. The build reproduces the issuer's
  income-statement operating block — every cost line that sits between net sales and
  Operating Income (e.g. cost of sales including buying, distribution and occupancy
  costs; selling, general & administrative expenses; depreciation & amortization
  where separately presented; impairment / store-closure / restructuring charges;
  pre-opening costs) and NOTHING below the operating line (no interest, no taxes, no
  other income). Retail issuers present this block in one of two shapes — a
  gross-profit format (cost of sales → Gross profit → SG&A → Operating income) or a
  single total-operating-expenses format — and the build mirrors whichever the
  issuer uses. It lays down (1) a dollar walkdown of each cost line to Total
  Operating Expenses / Operating Income, then (2) each cost line — every line EXCEPT
  depreciation & amortization, whose forward dollars reference the depreciation
  schedule (built before this section) — as a live `=` % of its matched revenue base, which is the projection
  driver. A decision gate first reads whether the issuer reports its operating costs
  at the consolidated level only, by banner / reportable (business) segment, or by
  geographic segment: for banner-segment reporters it runs a per-banner $ and %
  walkdown (denominator = that banner's revenue) plus a consolidated costs table;
  for geographic-segment reporters it runs a per-geography $ and % walkdown
  (denominator = that geography's revenue if revenue is split by geography, else
  total revenue) plus a consolidated table; the consolidated table also carries any
  corporate-only lines (e.g. SG&A) that do not appear in the segment blocks. Costs
  per company-operated location are expressed ONLY when the REVENUE section carries
  the location build's `Company-Operated EOP Balance` contract row — the row's
  presence is the test, never a flag — otherwise that block is omitted entirely. Pulls series via `search_kpis` from the shared inventory; format per
  ../../../_common/revelata-excel-styling-rules.md (one row per series, derived cells as
  live formulas) EXCEPT for time scope / columns, which this build matches to the
  revenue build. Quality checks: reported Gross Profit must equal Total Revenue −
  Cost of Sales (gross-profit format), reported Operating Income must equal Total
  Revenue − Total Costs and Expenses, and the consolidated totals must trace cleanly
  up from each segment's lines. Sections: §1 identify the cost lines + segmentation
  gate, §2 the dollar walkdown, §3 costs as a % of revenue, §4 per-company-operated-
  location costs (conditional on the approved location build), §5 banner-segment
  build (conditional), §6 geographic-segment build (conditional), §7 quality checks +
  foot, §8 worked example, §9 the projection layer (driver methodology + projection
  columns), §10 downstream handoff.
---

# costs — retail (operating-cost build)

This is the **retail-industry** cost build. It is invoked by the costs router
(`../costs.md`) when the company was classified as a **retail / consumer-merchandise**
business during the revenue build. It owns the build of the **COSTS** section for
retail companies — the income-statement **operating block**, walked down to
**Operating Income**, and expressed both in **dollars** and as a **% of revenue**
(the projection driver).

By the time control reaches this file, two things are already true:

1. the company **is in the retail industry** (decided by the revenue router and
   carried forward by the orchestrator), and
2. the **REVENUE section is already built** in the workbook, so cost lines can
   reference the revenue lines laid down there — total revenue / net sales, the
   store-cohort or in-store or per-product revenue lines the chosen sub-build
   produced, any per-banner or per-segment revenue, and (if the location build ran)
   the store roll-forward's company-operated unit counts.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook (with the REVENUE section already built), the
**shared KPI inventory** from the orchestrator, and the **industry determination**.

**Also carried forward from the retail revenue router (`../../revenue/retail/retail.md`),
and required by this build:**

- the **revenue build method** that ran — `comparableStoresBuild/`, `unitsBuild/`,
  `sqftBuild/`, or `other/` — because it determines which revenue rows exist to
  divide by (§3.1).

No location-gate flag is carried. Whether §4 (costs per company-operated location)
is built is decided by the **presence of the `Company-Operated EOP Balance` row** in
the REVENUE section — the contract row the location build lays (`../../SKILL.md`,
"Contract rows") — which this build verifies itself (§4.1), exactly as the
net-working-capital build does for its lease driver.

If the build method was not carried forward, **read it off the workbook** (§3.1) rather
than assuming it; never infer a store fleet or a revenue split from the company's
reputation.

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

- **Use the exact period columns the revenue build already laid down.** The cost lines
  must sit **directly beneath the matching revenue rows** so every cost-to-revenue ratio
  lines up in the same column. **Every** retail revenue sub-build
  (`comparableStoresBuild/`, `unitsBuild/`, `sqftBuild/`, `other/`) and the store
  roll-forward (`locationBuild/`) is built on the **four most recent fiscal years**,
  **annual columns only**, oldest → newest, in Col E onward. So this build uses those
  **same four annual columns**. Do **not** introduce a different timeline. (The full
  intended horizon is the canonical **Model timeline** in the orchestrator
  `../../SKILL.md` — the four historical fiscal years plus the five projection years,
  `N+1 … N+5`, after the last historical year; this section mirrors whatever portion of
  that timeline the upstream builds have laid down.)
- **Retail builds are ANNUAL — do not add a quarterly block.** Unlike some other verticals, no retail revenue sub-build
  lays down quarterly columns: the comp rate, the cohort counts, the store flows, and
  segment revenue are all annual disclosures. So there is no quarterly block to mirror
  here, and adding one would put cost columns under nothing. Pull **annual** (`-
  Annual`) cost series only. The lone exception is the styling rules' standing
  allowance: if a needed annual value genuinely does not exist in deepKPI and must be
  summed from that series' four quarters, bring the quarterly rows in as supporting
  rows, sum them, and place them in an outline group left expanded (no row is hidden;
  styling rules).
- **Adopt the revenue build's fiscal-year column mapping — never re-derive it.** This is the single highest-probability silent error in
  a retail build. Retailers are almost all on a **52/53-week fiscal calendar ending in
  late January or early February**, so a company's "fiscal 2025" ends in **calendar
  2026**, and deepKPI date stamps are inconsistent **between issuers and between series
  within one issuer** (see §2 of `../../revenue/retail/locationBuild/locationBuild.md`).
  The upstream build already resolved that mapping. Read it off the workbook's existing
  column headers and write every cost value into the column its fiscal year already
  owns. **A cost row written one column off its revenue row corrupts every ratio in the
  build while still looking entirely plausible.** Before writing any cost line, confirm
  the newest column's reported Total Costs and Expenses (or Cost of Sales) matches the
  figure in the most recent 10-K's income statement; if it does not, your alignment is
  off by one — fix the mapping first.
- **A 53-week fiscal year is a note, not an adjustment.** Where one of the four historical years had 53 weeks, both the numerator
  and the denominator of a cost-to-revenue ratio scale with the extra week, so the
  **ratio stays broadly comparable** and needs no adjustment. Fixed-cost lines
  (occupancy, D&A, and to a degree SG&A) are the exception — they are understated as a
  percentage in a 53-week year. Do **not** restate anything; record which year had 53
  weeks in the Notes block, in the analyst's words, and keep it visible when reading
  the driver seeds in §9: "Costs: FY<n> was a 53-week year; its fixed-cost ratios
  are slightly understated against the 52-week years."
- **Never silently substitute data.** If a deepKPI cost series for a specific cell is a
  clear data-quality artifact (order-of-magnitude scaling or a tagging error), do not
  transcribe it. Prefer a clean alternate deepKPI series; if none exists, take the value
  from the company's 10-K "Results of Operations" / "Consolidated Statements of
  Operations (and Comprehensive Income)" table, mark that cell distinctly (gold fill,
  hyperlinked to that filing, with a cell comment that keeps the filing table), and
  record it in the Notes block, one line per override: "Costs: <line> FY<n> is taken
  from the 10-K income statement; the database series was <scaled / mis-tagged /
  missing>."
  **Retail series carry these artifacts at a high rate** — the store-count experience in
  the location build applies to cost series too, and the artifacts are often
  **intermittent within a single series**, so check **every cell**, not every series.

> This build is authored section by section. The sections present here — §1 the
> cost-line identification + segmentation gate, §2 the dollar walkdown, §3 costs
> as a % of revenue, §4 per-company-operated-location costs, §5 the banner-segment
> build, §6 the geographic-segment build, §7 quality checks, §8 a worked example,
> §9 the projection layer, and §10 the downstream handoff — are the implemented
> scope. Do **not** build or add any information outside the sections present here.

---

## Cost build — framework overview

This build turns the issuer's reported **operating line items** into a clean,
footing cost block beneath the `COSTS` header, and then turns each line into the
**cost-to-revenue ratio** that drives the projection. It follows one fixed framework
so that every retail company is modeled the same way and the block always foots.

**The master identity (the foot / quality check):**

```
  Total Costs and Expenses  = Σ (each reported operating-cost line item)
  Operating Income          = Total Revenue − Total Costs and Expenses
```

and, for the issuers that present a **gross-profit format** (most retailers), the
same identity read in two steps:

```
  Gross Profit              = Total Revenue − Cost of Sales
  Operating Income          = Gross Profit − Σ (operating-expense lines below gross profit)
```

`Total Costs and Expenses` is built as the **sum of the individual cost lines** (a
live formula), and is cross-checked against the issuer's **reported** all-in total
(captioned "Total operating expenses" or "Total costs and expenses" by the issuer) KPI
where one exists. `Gross Profit` (when the
issuer presents it) and `Operating Income` are **difference formulas**, each
cross-checked against the issuer's **reported** figure — the two must agree (§7).
`Total Revenue` is the line the **revenue build** already laid down; this build
references it, it does not re-derive it.

**Build the cost section in this order** (each conditional step states its trigger):

1. **§1 — Identify the operating line items** from deepKPI / the 10-K, settle which
   of the two retail presentations the issuer uses, resolve the **embedded-D&A**
   question, and **decide the segmentation** (consolidated-only vs. banner / business
   segments vs. geographic segments). This gate decides whether §5 or §6 is built.
2. **§2 — The dollar walkdown.** Lay every operating line in dollars for every
   period column, footing to `Total Costs and Expenses` / `Operating Income (modeled)`. (When
   the company reports by segment, this is the **consolidated** table that sits at
   the bottom; §5 / §6 build the per-segment walkdowns above it.)
3. **§3 — Costs as a % of revenue.** Express every cost line — **except
   Depreciation & Amortization** — as a live `=` % of its matched revenue base.
   This ratio is the **projection driver**.
4. **§4 — Per-company-operated-location costs** — built **only** if the location
   build was **approved and actually built into the REVENUE section** (§4.1). If it
   was not, this section is **omitted entirely**.
5. **§5 — Banner / business-segment build** (only if the gate found segment-level
   cost disclosure). Per-banner $ and % walkdowns + the consolidated table.
6. **§6 — Geographic segment build** (only if the gate found geographic segments).
   Per-geography $ and % walkdowns + the consolidated table.
7. **§7 — Quality checks + foot.**

**Conventions that apply to every section (read once):**

- **Signs follow the income statement.** Costs are carried **positive**; a credit
  within costs (a gain on sale, a settlement credit, other operating income shown
  inside the cost block) is carried **negative**, exactly as the issuer presents it,
  so every subtotal is a plain `SUM`. A deepKPI value delivered with the opposite
  sign is carried with the filing's sign as a 10-K override (gold, hyperlinked, the
  comment stating the flip); the sign is never corrected inside a formula.
- **Reference the revenue build — do not re-derive revenue.** Every revenue figure
  this build divides by already exists in the workbook (the `Total Revenue` /
  `Total Revenue` row, the cohort or in-store or unit-revenue lines, the per-banner
  revenue subtotals). Reference those cells with live `=` formulas; never hardcode a
  revenue number or rebuild a revenue line here.
- **Reference the store roll-forward — never re-enter a store count.** The same rule
  applies to unit counts: if §4 is built, its denominator is a **live reference** to
  the location build's `Company-Operated EOP Balance` row. Pulling a store-count
  series into the COSTS section to stand in for a roll-forward that was not built is
  a violation of §4.1, not a workaround.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (each reported cost line, the reported Gross Profit / Total
  Operating Expenses / Operating Income used as checks, and any base-year lookback)
  are **input cells** (pale-green fill,
  dark-blue hyperlinked
  value linked to the filing). **Every other cost cell is a live `=` formula** (black
  font, no fill) — the `Total Costs and Expenses` sum, `Gross profit`,
  `Operating Income (modeled)`, every `% of revenue` row, every per-location figure, every
  segment subtotal, and every foot-check memo. Projected-period cost assumptions (the
  forward `% of revenue`) are **red** driver cells (the projection-driver convention
  — see §9). Never hardcode a computed number.
- **Scope is the operating block ONLY.** Build **only** the lines that sit between
  net sales and **Operating Income** (§1.2). Do **not** add interest expense,
  interest income, other income/expense, income taxes, equity-method items, or any
  below-the-operating-line item — those belong to the `CONSOLIDATED FINANCIALS`
  section, not here.
- **D&A is carried in dollars but NOT projected here — when it is a line at all.**
  Where the issuer presents depreciation & amortization as its **own** line inside
  the operating block, it appears in the §2 dollar walkdown, and it is the **one**
  line that is **not** expressed as a % of revenue (§3) — its forward dollars
  reference the **depreciation schedule**
  (`../../depreciation-schedule/depreciation-schedule.md`, §6), which the
  orchestrator builds **before** this section. Leave its `% of revenue` cell as a
  dash with a cell comment pointing to that schedule. Only a line that is the
  issuer's **total** D&A references the schedule (schedule §6.2: it equals the
  schedule's cash-flow D&A in every historical column within rounding); a component
  line is held flat at its year-`N` value as a red driver instead. The hand-back report lists every such component line by key, as it lists the lines excluded from the issuer's adjusted measure; the consolidated section adds them to its total D&A so EBITDA adds back all depreciation and amortization. Where the issuer
  **embeds** D&A inside cost of sales and SG&A (very common in retail), §1.4 governs
  — do **not** add a D&A line the income statement does not have.
- **Label / comment / spacing discipline (same as the revenue builds).** Col C
  labels are **plain descriptive text** (the issuer's reported line name); the
  operand recipe for each formula row goes in a **cell comment on the Col C label
  cell** (author `Cost Build`), not in the visible label. Indentation, bold / border
  conventions, the italic percent rows, and the one-blank-row-between-blocks rule all
  follow `../../../_common/revelata-excel-styling-rules.md` exactly as the revenue
  builds do.
- **Sum bars run across the data columns only — never the row-header column.** Every sum
  bar in this build — the single thin top border on `Gross profit`, `Total operating
  expenses` and `Operating Income (modeled)` — is applied **only to the value cells** — Col E
  onward. **Never** border **Col C**, and never Col A, Col B, or Col D. The bar sits
  under the numbers it totals, not beneath the label text.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../_common/revelata-excel-units-and-scale.md`, and every row's family
  follows from that file's Rule 4 — an input row's from its deepKPI `unit` field, a
  derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.1, §3.2, §4.4,
  §5.2, §5.3, §6.1 and §7.1 — and in the `Units (Col D)` column of that section's
  formula table. Dollar rows show the placeholder `(USD in <scale>)`: the contract's
  Rule 2 supplies the scale, millions by default, thousands where the digit test puts a
  small filer. A bracketed placeholder inside a tag — `<Banner>`, `<store net sales
  row>`, `<§3.1 base>` — is filled with the actual Col C label of the row the formula
  divides by. Three classifications are specific to this build:
  - **Percent rows name their denominator, and this build has three.** `Cost of sales`
    divides by the revenue build's `Net Sales` row and is tagged `(% of net sales)`
    (by `Total Revenue`, tagged `(% of total revenue)`, when no `Net Sales` row is
    laid — §3.1); store-level lines such as occupancy divide by the revenue build's
    store-sales row and are tagged `(% of <store sales row>)`; corporate lines, the
    margins and the totals divide by total revenue and are tagged `(% of total
    revenue)`; segment blocks use `(% of <Banner> revenue)` / `(% of <Geography>
    revenue)`. The basis still
    goes in the Col C cell comment as §3.2 requires — the tag is the unit, the comment
    is the recipe.
  - **The D&A `% of revenue` row (Case A) is tagged `(% of total revenue)` like the
    corporate lines.** It is a live ratio in every column, a derived read — D&A
    dollars come from the depreciation schedule, never from this row — so it is a
    data row and never a driver.
  - **Per-location costs → `(USD millions per location)`; the count row →
    `(locations)`.** A cost in millions divided by a location count in ones comes out in
    millions per location, and displaying it so lets a reader divide the two rows above
    and land on this one (the §8 example: `27,800 ÷ 20,893 ≈ 1.3306`).
- **Reading the layout blocks (§2.1, §3.2, §4.4, §5.2, §5.3, §6.1, §7.1).** Each row's
  annotation has two columns, left to right: the **Col D units tag in parentheses** —
  `(USD in <scale>)` means the contract's Rule 2 sets the money scale; every other tag
  is written as it goes in the cell — and the note in **square brackets**: `[deepKPI
  INPUT …]` for a pulled value, `[FORMULA …]` for a computed row, `[DASH …]` for a
  deliberately empty cell, plus styling (`SUM-BAR`, `italic`) and any presentation
  condition. Sub-header lines carry no tag.
- **Header hierarchy (per the styling contract).** Only the **ALL-CAPS `COSTS`
  section header** gets the big-header treatment — **bold, underlined, size 16**.
  Every **title-case sub-header beneath it** (`Consolidated Costs`,
  `Consolidated Costs — % of revenue`, `Cost per company-operated location`, and the
  per-banner / per-geography headers) is **bold, underlined, size 12** at the indent
  the contract's block-header rule gives it — the one sub-header treatment every
  section shares (`../../../_common/revelata-excel-styling-rules.md`). Do **not** set
  them to size 16; that big-header look is reserved for the one ALL-CAPS `COSTS` row.

The sub-sections below specify each piece cell-by-cell. Build them in order; do
not add cost lines outside this framework.

---

## Section 1 — Identify the operating line items and decide the segmentation

This first section does no workbook writing of its own. It (a) reads the issuer's
operating block, (b) settles which of the two retail presentations it uses, (c)
resolves whether D&A is a line or is embedded, (d) maps each line to a deepKPI
series, and (e) decides **how the costs are segmented**, which determines whether the
build is a single consolidated walkdown (§2 – §3 only) or a per-segment build (§5 or
§6) plus a consolidated table.

### 1.1 — Where the cost lines live

Retail operating costs are disclosed in the issuer's **MD&A "Results of Operations"**
table and, authoritatively, in the **"Consolidated Statements of Operations"**
(sometimes "…and Comprehensive Income") in the financial statements. Both present the
same operating block: net sales, a cost-of-sales line, the operating-expense lines,
and **Operating income / Operating profit** at the bottom.

In the **shared KPI inventory** these lines live under the **`Consolidated Income
Statement`** category (and, when the issuer reports cost by segment, under **`Segment
Financials`**). Read that category first to see exactly which expense lines the issuer
reports — do **not** assume a generic set.

Two retail reading habits are worth carrying into that scan:

- **The top line is usually called `Net sales`, not `Revenue`.** Search both. The
  cost ratios in §3 are struck against the revenue rows the revenue build laid down,
  whatever the issuer's own label for them.
- **MD&A gives you the issuer's own ratio bases.** Retail MD&A routinely states
  "cost of sales as a percentage of net sales" and "SG&A as a percentage of net
  sales", and sometimes on a merchandise-only or segment basis. Those stated bases
  are authoritative for §3.1 — read them before choosing a denominator.

### 1.2 — Scope rule (STRICT): only the lines between net sales and Operating Income

Build **every** line the issuer lists **between** net sales and **Operating income**,
and **nothing else**:

- **Include** the cost-of-sales line (however labeled — see §1.3), the
  operating-expense lines (selling, general & administrative expenses; any separately
  presented depreciation & amortization; impairment, store-closure, restructuring or
  asset-disposal charges; pre-opening costs; provision for doubtful accounts; other
  operating income / expense), and any subtotal the issuer itself presents (`Gross
  profit`, `Total operating expenses`, `Total costs and expenses`). The exact set and
  labels are issuer-specific (§1.3).
- **Exclude — do not add — anything below the operating line.** No interest expense,
  interest / investment income, other income (expense), income tax provision, equity
  in earnings, or net-income subtotals. Those are owned by the `CONSOLIDATED
  FINANCIALS` section. This restriction is deliberate and strict: do not add any
  costs that are not part of the operating block.
- **Exclude non-operating retail items that look operational.** Gain or loss on the
  **sale of a business or of real estate**, **debt extinguishment** costs, and
  **insurance recoveries** presented below operating income stay out, even when the
  narrative discusses them alongside store closures.

The discipline check is that **Σ (the lines you include) = reported Total Operating
Expenses** and **Total Revenue − Σ (those lines) = reported Operating Income** (§7).
If your sum does not tie, you have either **missed a line** the issuer reports inside
the block or **included one** that sits below the operating line — fix the line set,
do **not** paper over it with an invented "other costs" plug.

### 1.3 — The two retail presentations, and the canonical line-item set

Retail issuers present the operating block in one of two shapes. **Decide which one
the issuer uses before laying a single row**, because it determines the subtotal rows
in §2 and the number of foot checks in §7.

**Presentation 1 — the gross-profit format (most common in retail).** Cost of sales
is struck against net sales to give a `Gross profit` subtotal, and the operating
expenses sit below it:

```
  Net sales                                                (from the revenue build)
  Cost of sales, including buying, distribution and occupancy costs
  Gross profit                                             (subtotal the issuer presents)
  Selling, general and administrative expenses
  Depreciation and amortization                            (only if separately presented — see §1.4)
  Impairment / store closing / restructuring charges       (if reported separately)
  Pre-opening costs                                        (if reported separately)
  Other operating (income) expense, net                    (if reported)
  Operating income
```

**Presentation 2 — the single total-operating-expenses format.** No gross-profit
subtotal; every operating line is listed and summed once:

```
  Net sales                                                (from the revenue build)
  Cost of merchandise sold
  Selling, general and administrative expenses
  Depreciation and amortization                            (only if separately presented)
  Impairment and store closure costs
  Total Costs and Expenses
  Operating income
```

**The actual line items vary by issuer — use the issuer's reported labels and
groupings, not these defaults.** Mirror exactly what the issuer presents between net
sales and Operating income — same lines, same order, same labels (Col C uses the
issuer's wording).

Three retail-specific facts about the cost-of-sales line that matter downstream:

- **Buying, distribution and occupancy costs are frequently inside cost of sales.**
  Labels such as `Cost of sales, including buying and occupancy costs` (TJX) or
  `Cost of goods sold` (Dollar General) cover merchandise cost **plus** distribution,
  buying and store occupancy. That means the ratio's complement is the issuer's
  **gross margin as it defines it**, not a pure merchandise-cost ratio — and it means
  you must **not** manufacture a separate `Occupancy` line for a retailer that does
  not present one. State what the line includes in the Col C cell comment.
- **The cost-of-sales line covers goods sold through every channel** — stores,
  e-commerce, and wholesale alike. This is decisive for the denominator choice in
  §3.1.
- **Some retailers report cost of sales excluding occupancy and D&A** and say so in
  the label (`Cost of sales, exclusive of depreciation and amortization shown
  separately below`). When they do, the excluded items are separate lines and belong
  in the walkdown as such — read the label, do not assume.

### 1.4 — The embedded-D&A question (settle this before §2)

In retail, depreciation & amortization is **often not a separate income-statement
line**: it is embedded inside cost of sales and SG&A, and disclosed only in the cash
flow statement and the property footnote. Getting this wrong double-counts a material
cost. Resolve it explicitly:

- **Case A — D&A is presented as its own operating line.** Carry it as a line in §2,
  give it a **dash** in the §3 `% of revenue` block, and reference the
  **depreciation schedule**'s forward D&A in the projection columns (§9.3). This is
  the same treatment every other build in this skill set gives D&A.
- **Case B — D&A is embedded in cost of sales and/or SG&A** (no separate line on the
  income statement). Then **do not add a D&A row to the walkdown** — the dollars are
  already inside the lines you are carrying, and adding a row would break the foot and
  overstate total operating expenses. Instead:
  - carry the cash-flow D&A figure as an **italic memo row** beneath the walkdown,
    labeled `Memo: depreciation and amortization (embedded in the lines above)`, as a
    deepKPI **input**, explicitly **excluded** from every sum;
  - put a cell comment on that row stating that it is **not** additive and naming the
    lines it sits inside; and
  - record it in the Notes block as one line, "Costs: depreciation and amortization
    is embedded in cost of sales and SG&A; the memo row is for reference and is not
    added.", and **state it in the §10 handoff**. Nothing downstream
    needs a D&A row here: CONSOLIDATED FINANCIALS references the depreciation
    schedule's D&A directly, so no D&A line is ever created inside the operating
    block for its sake.

State which case applies (one line, citing the income-statement label you read)
before writing any cost row.

### 1.5 — Map each line to a deepKPI series

For each line in the issuer's block, find the matching series with `search_kpis`
against the **shared inventory** (never re-run `list_kpis`). Match on the issuer's
wording plus the `- Annual` suffix, e.g. `Cost of sales - Annual`,
`Cost of goods sold - Annual`, `Cost of merchandise sold - Annual`,
`Cost of sales including buying and occupancy costs - Annual`,
`Selling, general and administrative expenses - Annual`, `SG&A expenses - Annual`,
`Depreciation and amortization - Annual`, `Impairment charges - Annual`,
`Store closing costs - Annual`, `Restructuring charges - Annual`,
`Pre-opening costs - Annual`, `Total operating expenses - Annual`, and the check lines
`Gross profit - Annual` and `Operating income - Annual` / `Operating profit - Annual`.

- Prefer **annual** (`- Annual`) series across the build window (the four FYs the
  revenue build used). Retail cost series are annual disclosures; see the time-scope
  section for the narrow quarterly-summation exception.
- **Read the `unit` field, not just the label.** A `Gross margin` or `SG&A rate`
  series with `unit: percent` is a **ratio**, not a dollar line — it does not go in
  the §2 dollar walkdown. It is useful as a **cross-check** against the ratio your §3
  formula computes, and a disagreement between the two usually means your denominator
  is not the issuer's.
- **Sanity-check each value** against the series trend, against the sibling lines, and
  against the 10-K income statement. Reject obvious artifacts (order-of-magnitude
  scaling, a single point wildly out of line with its own series, a value repeated
  under two date stamps) and fall back to the 10-K figure as a **gold-fill override**
  per the time-scope rule above.
- Pull the **reported Gross Profit** (Presentation 1), the **reported Total Operating
  Expenses** (Presentation 2, and Presentation 1 where the issuer presents one), and
  the **reported Operating Income / Operating Profit** series too — they are the §7
  foot checks. The workbook's subtotal and total rows are always the **sum /
  difference formulas**, never the reported inputs.

### 1.6 — Segmentation decision gate (run before any cost line is written)

Decide **which presentation** the cost block gets, by reading how the issuer reports
its operating costs. Check the **`Segment Financials`** category of the shared
inventory and the 10-K segment footnote / MD&A; **do not guess**:

- **Path C0 — consolidated only (default).** The issuer reports a **single**
  operating block for the whole company (one set of cost lines). Build **§2 + §3
  only** (the consolidated walkdown and its % table), plus §4 if the location build
  was approved and built. Most single-banner retailers are here — and, because of the
  segment-profit trap below, so are many multi-banner ones.
- **Path C1 — banner / business segments.** The issuer reports operating **cost
  lines** broken out by **reportable segment or banner** (e.g. a parent that
  separately discloses cost of sales and SG&A for each of its chains). Build **§5** —
  a per-banner $ and % walkdown — **then** the §2 / §3 consolidated table at the
  bottom (which sums the banners and adds any corporate-only lines). Plus §4 if the
  location build was approved and built.
- **Path C2 — geographic segments.** The issuer reports operating **cost lines**
  broken out by **geography** (e.g. domestic vs. international, or by region). Build
  **§6** — a per-geography $ and % walkdown — **then** the §2 / §3 consolidated table
  at the bottom. Plus §4 if the location build was approved and built.

> **The segment-profit trap (read this before choosing C1 or C2).** Retail segment
> footnotes very commonly disclose **segment revenue and segment profit only** — a
> single profit figure per segment, with **no expense-line detail behind it**. A
> segment profit number is **not** a cost breakdown, and you cannot build a
> per-segment $ and % walkdown from it. If that is all the issuer discloses, the
> company is **Path C0**: build the consolidated walkdown, and carry the reported
> segment profit (and segment revenue) as **italic memo rows** beneath the
> consolidated table if useful — clearly labeled as memo, never as part of any sum.
> Only a genuine breakout of the **expense lines themselves** by segment triggers C1
> or C2.

> **What counts as a segment (be precise).** A **segment** is a distinct banner /
> chain / reportable business segment (Path C1) or a distinct geography (Path C2) for
> which the issuer reports its **own operating cost lines**. A split of revenue into
> **stores vs. e-commerce vs. wholesale is NOT a segment** — that is a channel-mix
> split within a single segment, and it does not by itself trigger a per-segment cost
> build. Neither is **company-operated vs. franchised / licensed**. And a
> **store-count partition by banner in the location build is not a cost segmentation**
> — the roll-forward being per banner says nothing about whether costs are disclosed
> per banner. If a parent operates several banners but reports operating costs **only
> on a consolidated basis**, it is **Path C0** (you cannot build per-banner cost
> walkdowns from costs that are not disclosed per banner).

State which path you picked and why (one line, citing the specific segment KPIs that
did or did not exist, and explicitly naming the segment-profit trap if it applied),
before writing any cost line, so the routing is auditable. A company resolves to
**exactly one** of C0 / C1 / C2; build only that path's structure. A segment path also requires the
revenue hand-back's **segment map** (`../../SKILL.md`, "The segment map") to name
every segment the path would lay, corporate-only blocks excepted: a segment block
needs that segment's revenue for its ratios and its operating-income line, and a
segment the map does not name is carried at the consolidated level, never struck
against a blended base.

---

## Section 2 — The dollar walkdown (Consolidated Costs)

This section lays the issuer's operating block in **dollars** for every period column,
footing to `Total Costs and Expenses` and `Operating Income (modeled)`. Under **Path C0** this
is the whole dollar build. Under **Path C1 / C2** this is the **consolidated** table
that sits **beneath** the per-segment walkdowns (§5 / §6) and **sums** them — see
those sections for how the consolidated lines reference the segment lines.

### 2.1 — Layout for the dollar walkdown

**Presentation 1 — the gross-profit format:**

```
COSTS                                                                                  [ALL-CAPS section header — already in the scaffold]

Consolidated Costs                                                                     [sub-header: bold + underlined, size 12 — per the styling contract]
    Cost of sales, including buying and occupancy         (USD in <scale>)             [deepKPI INPUT — issuer's line]
  Gross profit                                            (USD in <scale>)             [FORMULA = Total Revenue − Cost of sales; bold, SUM-BAR]
    Gross profit (reported)                               (USD in <scale>)             [deepKPI INPUT — the reported anchor; Presentation 1 only]
    Memo: Gross profit modeled − reported (must ≈ 0)      (USD in <scale>)             [FORMULA check; italic; ≈ 0 every period; Presentation 1 only]
    Selling, general and administrative expenses          (USD in <scale>)             [deepKPI INPUT]
    Depreciation and amortization                         (USD in <scale>)             [deepKPI INPUT — ONLY in §1.4 Case A]
    Impairment, store closure and restructuring           (USD in <scale>)             [deepKPI INPUT — if reported separately]
    Pre-opening costs                                     (USD in <scale>)             [deepKPI INPUT — if reported separately]
    Other operating (income) expense, net                 (USD in <scale>)             [deepKPI INPUT — if reported]
  Total Costs and Expenses                                (USD in <scale>)             [FORMULA = Cost of sales + SUM(opex lines above); bold, SUM-BAR]
    Total Costs and Expenses (reported)                   (USD in <scale>)             [deepKPI INPUT — the reported anchor, where the issuer reports the total; omitted with its memo otherwise]
    Memo: Total Costs and Expenses sum − reported (must = 0)  (USD in <scale>)         [FORMULA check; italic; 0 every period; omitted where no reported total]
  Operating Income (modeled)                              (USD in <scale>)             [FORMULA = Total Revenue − Total Costs and Expenses; bold, SUM-BAR — contract row]
    Operating Income (reported)                           (USD in <scale>)             [deepKPI INPUT — the reported anchor — contract row]
    Memo: Operating Income modeled − reported (must ≈ 0)  (USD in <scale>)             [FORMULA check; italic; ≈ 0 every period]
    Memo: depreciation and amortization (embedded in the lines above)  (USD in <scale>)  [deepKPI INPUT — §1.4 Case B ONLY; italic; NOT additive; dash in every projection column]
```

**Presentation 2 — the single total-operating-expenses format:** identical, minus the
`Gross profit` row and its two memo rows. Every operating line, including cost of
merchandise sold, sits in one contiguous block that `Total Costs and Expenses` sums.

- Each cost line is **one row** across the four annual period columns, per the
  one-row-per-series rule. Do **not** fragment a line into per-period rows.
- `Total Costs and Expenses` is a **live `= SUM(...)` / addition** over the cost-line
  rows above it — never an input, never hardcoded. `Gross profit` and `Operating
  income` are **difference formulas**. This is what makes the summation **followable**
  (quality check 2).
- The memo rows cross-check each subtotal against the issuer's **reported** figure (an
  input); the difference must be **0** (total operating expenses) or **≈ 0** (gross
  profit, operating income) every period. A non-zero difference means a missing or
  extra line (§1.2) — resolve it.
- **Where the issuer reports no `Total Costs and Expenses` figure at all** (some
  gross-profit-format retailers do not), omit those two memo rows and rely on the
  `Operating Income (modeled)` foot, which tests the same completeness. Record the
  omission in `BUILD_LOG.md`; a fallback taken because a series is absent is build
  history, and the operating-income foot still shows on the sheet.

### 2.2 — The formulas (cell-by-cell) for the dollar walkdown

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Cost of sales, …` (and each operating-cost line) | DATA_DEPENDENT | `(USD in <scale>)` | historicals: deepKPI **input** $ (green, hyperlinked); projections: `= <its % of revenue, this col> × <matched revenue base, this col>` (see §3) | *(no comment on input rows — provenance via hyperlink; carry a comment on cost of sales naming what it includes: buying, distribution, occupancy, D&A)* |
| `Gross profit` *(Presentation 1 only)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <Total Revenue, this col> − <Cost of sales, this col>` | `"Total revenue (revenue build) − cost of sales. Cross-checked to reported gross profit (memo below)."` |
| `Depreciation and amortization` *(§1.4 Case A only)* | NOT HAS_DNA_EMBEDDED | `(USD in <scale>)` | historicals: deepKPI **input** $; projections: `= <DEPRECIATION SCHEDULE → Depreciation & Amortization, this col>` (a component line is held flat at its year-`N` value instead; `depreciation-schedule` §6.2) | `"Historicals: reported D&A. Projections: reference the DEPRECIATION SCHEDULE's Depreciation & Amortization, not a % of revenue."` |
| `Total Costs and Expenses` | | `(USD in <scale>)` | Presentation 1: `= <Cost of sales, this col> + SUM(<first operating-expense line> : <last operating-expense line>, this col)` — the gross-profit rows between are never inside the range; Presentation 2: `= SUM(<Cost of sales> : <last operating-expense line>, this col)` | `"Σ of every operating line between net sales and operating income. Must tie to reported Total Costs and Expenses (memo below)."` |
| `Operating Income (modeled)` | | `(USD in <scale>)` | `= <Total Revenue, this col> − <Total Costs and Expenses, this col>` | `"Total revenue − total operating expenses. Cross-checked to reported operating income (memo below)."` |
| `Gross profit (reported)` | HAS_GROSS_PROFIT_ROW | `(USD in <scale>)` | deepKPI **input** $ (reported) | *(no comment — input row; the anchor the memo below ties to)* |
| `Memo: Gross profit modeled − reported (must ≈ 0)` | HAS_GROSS_PROFIT_ROW | `(USD in <scale>)` | `= <Gross profit, this col> − <Gross profit (reported), this col>` | `"Completeness check: ≈ 0 means every cost-of-sales dollar is captured."` Under Path C1 where a corporate-only line holds cost of sales the issuer does not split out (§5.3), add: `"Equals the cost of sales inside <corporate line> by construction, <x>% of revenue in FY<N>; the issuer does not split it."` |
| `Total Costs and Expenses (reported)` | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** $ (reported), where the issuer reports the total; omitted with its memo otherwise (§2.1) | *(no comment — input row)* |
| `Memo: Total Costs and Expenses sum − reported (must = 0)` | DATA_DEPENDENT | `(USD in <scale>)` | `= <Total Costs and Expenses, this col> − <Total Costs and Expenses (reported), this col>`; omitted where no reported total | `"Completeness check: 0 means every line in the block is captured and nothing extra was added."` |
| `Operating Income (reported)` | | `(USD in <scale>)` | deepKPI **input** $ (reported) — contract row | *(no comment — input row)* |
| `Memo: Operating Income modeled − reported (must ≈ 0)` | | `(USD in <scale>)` | `= <Operating Income (modeled), this col> − <Operating Income (reported), this col>` | `"Must be ≈ 0 every historical period. A non-zero gap means a missing or extra cost line, an embedded-D&A mismatch or a revenue-base mismatch — fix it in the block, never plug it."` |
| `Memo: depreciation and amortization (embedded in the lines above)` *(§1.4 Case B only)* | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** $ (cash-flow D&A); italic | `"NOT additive. D&A is embedded inside cost of sales and SG&A; carried here for reference only and excluded from every sum. CONSOLIDATED FINANCIALS takes D&A from the DEPRECIATION SCHEDULE directly."` |

- In **historical** columns every cost line is a reported **deepKPI input**, and the
  subtotals / totals are the sum / difference formulas.
- In **projected** columns every cost line **except D&A** flips to `= % × revenue
  base` (the % is the **red** driver from §3, set per §9), **D&A** (Case A)
  references the depreciation schedule, and the subtotal / total rows keep the same
  sum / difference formulas.
- Use `SUM(...)` over each contiguous range of cost rows rather than chained addition
  of the lines, so a dashed cell in a year the issuer reported no impairment cannot
  throw `#VALUE!`; under Presentation 1 that is the cost-of-sales cell plus one `SUM`
  over the operating-expense range beneath the gross-profit rows.
- **A line the issuer reports in some years and not others** (impairment, store
  closure, restructuring) keeps its row across all columns, with a numeric **0** in
  the years it was not incurred (the number format displays it as a dash). Never the
  text dash: the projection seed in §9.1 tests those cells with ISNUMBER (a run-rate seed with COUNT and MEDIAN), and a text dash would make it skip the year; text is
  invisible to both. Do not delete the row and do not leave a hole that breaks the `SUM`
  range.

### 2.3 — Pre-delivery checklist (dollar walkdown)

- [ ] The **presentation** (gross-profit vs. single total) was decided in §1.3 and
      the layout matches it; the `Gross profit` row exists **iff** the issuer
      presents one.
- [ ] Every line in the issuer's operating block is present, in the issuer's order
      and wording; **no** below-the-operating-line item was added.
- [ ] The **§1.4 D&A case** was decided and applied: a D&A row exists **iff** the
      issuer presents one (Case A); in Case B the non-additive memo row is present
      and excluded from every sum.
- [ ] Each cost line is **one row** across the four annual columns; historicals are
      deepKPI inputs (green, hyperlinked), with any 10-K overrides gold-filled and
      noted.
- [ ] `Total Costs and Expenses` is a **live `= SUM(...)`** and `Gross profit` /
      `Operating Income (modeled)` are **difference formulas** — never hardcoded.
- [ ] The `sum − reported (must = 0)` and `modeled − reported (must ≈ 0)` memos
      evaluate to **0 / ≈0** every period after recalculation (completeness / foot).
- [ ] Cost columns sit **directly beneath** the matching revenue columns, on the
      revenue build's fiscal-year mapping; the newest column ties to the latest 10-K.
- [ ] Sum bars span the **data columns only**; Col C carries no border.
- [ ] Styling per the styling rules; after recalculation, **zero formula errors**.

---

## Section 3 — Costs as a % of revenue (the projection driver)

This section expresses **each cost line as a live `=` % of its matched revenue base**.
This ratio is the **driver**: it is how the line is read for analysis and how it is
**projected** (projected $ line = % × revenue base). **Every line is expressed as a %
EXCEPT Depreciation & Amortization**, whose forward dollars reference the
depreciation schedule (§9.3).

### 3.1 — Choosing the revenue base ("respective revenue")

Match each cost line to the revenue base it is actually incurred against — the
"respective revenue" — and divide by **that** base, not blindly by total revenue. The
default mapping (and the basis on which retail issuers themselves present these ratios
in MD&A):

- **Cost of sales / cost of merchandise sold** — matched against the issuer's
  **net sales** line: the revenue build's **`Net Sales`** row when it laid one,
  else **`Total Revenue`**, which is then the reported net sales line. A row-presence
  test, not a judgment. Retail issuers that earn fee income present it on the face
  of the income statement as its own line (Costco's `Membership fees`, Macy's and
  Target's `Other revenue`), and their net sales line is the merchandise base their
  own MD&A gross margin is struck on; the revenue build lays `Net Sales` exactly
  when such a face line exists. Do **not** subtract streams yourself: a stream the
  issuer keeps inside net sales carries cost of sales behind it (Gap's franchise
  revenue is product shipped to franchisees), and one it reports separately is
  already outside the row. Retail-specific and important: cost of sales covers goods
  sold through **every** channel — stores, e-commerce, and wholesale — so the base
  is **not** store-only revenue. Dividing a consolidated cost of sales by a
  store-only denominator inflates the ratio and makes its complement something that
  is not the issuer's gross margin. State which row was used in the Col C comment.
- **Store-level operating costs presented as their own lines** — occupancy, store
  labor, or store operating expenses when the issuer presents them **outside** cost of
  sales — are incurred only at company-operated stores, so the matched base is the
  store-sales row the revenue build laid, again by presence:
  - **`Net Sales from Stores`** (the comparable-stores build's comparable plus
    non-comparable subtotal — modeled store **net sales**);
  - else **`In-Store Revenue`** (the square-footage build's store engine — the
    **revenue** credited to the fleet, which keeps whatever the issuer does not break
    out; the two labels are different quantities and are not interchangeable);
  - else, where the cost is product-specific under the units build, that product's
    `Unit Revenue` (or `Total Unit Revenue`);
  - else `Net Sales` if laid, else `Total Revenue`, with the denominator named in the
    cell comment and the fallback recorded in `BUILD_LOG.md` (the `other/` build lays
    no store row).
- **Corporate / enterprise-level costs** — selling, general & administrative
  expenses, impairment / store-closure / restructuring charges, pre-opening costs, and
  other operating income / expense — are matched against **total revenue**.
- **Depreciation & amortization** — matched against **total revenue**, a derived
  read in every column, never a driver (the dollars are projected via the
  depreciation schedule). In §1.4 Case B there is no D&A row at all.

When the issuer's MD&A presents a specific ratio against a specific base (e.g. "cost
of sales as a percentage of **net sales**", or a **merchandise-only** gross margin),
**follow the issuer's base** — and cross-check your computed historical ratio against
any reported `Gross margin %` / `SG&A rate` series in the inventory. A material
disagreement means your denominator is not the issuer's; fix the reference rather than
explaining the gap away.

**Reference the revenue base cell the revenue build actually laid down.** Whichever
sub-build ran, the total-revenue anchor is the contract row `Total Revenue` (the
grand-total row of the revenue build's consolidated revenue table), and the
cost-of-sales base is the `Net Sales` row when present. Every denominator in this
section is a single row laid by the revenue build — never arithmetic over several
rows inside the `%` cell, and never a re-keyed figure.

### 3.2 — Layout for the % of revenue block

Place the `% of revenue` block **immediately beneath** the matching dollar block so
each ratio sits one row under its dollar line and in the same column. Mirror the
dollar line order:

```
Consolidated Costs — % of revenue                                                      [sub-header: bold + underlined, size 12 — per the styling contract]
    Cost of sales, including buying and occupancy         (% of net sales)             [FORMULA hist. / red driver proj.; italic; basis in the cell comment; (% of total revenue) when no Net Sales row]
  Gross margin                                            (% of total revenue)         [FORMULA = Gross profit ÷ Total Revenue; italic, bold; basis in the cell comment; Presentation 1 only]
    Selling, general and administrative expenses          (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Depreciation and amortization                         (% of total revenue)         [FORMULA = D&A $ ÷ Total Revenue in every column; italic; derived read, not a driver — D&A $ comes from the depreciation schedule; §1.4 Case A only]
    Impairment, store closure and restructuring           (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Pre-opening costs                                     (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
    Other operating (income) expense, net                 (% of total revenue)         [FORMULA hist. / red driver proj.; italic; basis in the cell comment]
  Total Costs and Expenses                                (% of total revenue)         [FORMULA = Total Costs and Expenses ÷ Total Revenue; italic, bold; basis in the cell comment]
  Operating margin                                        (% of total revenue)         [FORMULA = Operating Income (modeled) ÷ Total Revenue; italic, bold; basis in the cell comment]
```

**Label rule (STRICT).** The Col C label for each % row is **just the cost line
name** — identical to its dollar line — and is **never** suffixed with `— % of net
sales` / `— % of revenue`. The enclosing `Consolidated Costs — % of revenue`
sub-header already signals that every row in the block is a percentage, so the suffix
is redundant in the label. Put the **basis** (which revenue denominator the ratio
divides by) in the **Col C cell comment** for that row, not in the visible label. The
two derived reads, `Gross margin` and `Operating margin`, are the exceptions: they are
margins, not cost lines, so they carry their own names.

(If preferred, the % may instead be carried as an italic memo row **directly under
each dollar line** within the §2 block rather than as a separate block — either
arrangement is acceptable as long as every line has a visible, live `% of revenue`
cell and the column alignment to the dollar line is exact. Pick one
arrangement and apply it sheet-wide.)

### 3.3 — The formulas (cell-by-cell) for the % of revenue block

The Col C label is the **bare cost-line name** (no `— % of …` suffix); the basis goes
in the comment.

| Row (plain Col C label — no suffix) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Cost of sales, …` | DATA_DEPENDENT | `(% of net sales)` — `(% of total revenue)` when no `Net Sales` row is laid | historicals: `= <cost $ line, this col> ÷ <Net Sales, this col>` (÷ `Total Revenue` when no `Net Sales` row); projections: **red driver input** (see §9) | `"% of net sales (revenue build's Net Sales row; Total Revenue when the issuer reports a single revenue line). Cost of sales covers goods sold through every channel — stores, digital and wholesale — so the base is NOT store-only revenue. The projection driver: projected $ = this % × the same row."` |
| `Gross margin` *(Presentation 1)* | HAS_GROSS_PROFIT_ROW | `(% of total revenue)` | `= <Gross profit, this col> ÷ <Total Revenue, this col>` | `"% of total revenue. Gross profit ÷ total revenue. Derived read, not a driver — cross-check against any reported gross-margin series."` |
| `<store-level cost>` (e.g. `Occupancy`, when presented separately) | | `(% of <store sales row>)` | historicals: `= <cost $ line, this col> ÷ <Net Sales from Stores or In-Store Revenue, this col>` (§3.1 by presence); projections: **red driver input** | `"% of <row>. Store-level cost ÷ the revenue build's store-sales row (<name it>). Projection driver."` |
| `<corporate cost>` (e.g. `Selling, general and administrative expenses`) | | `(% of total revenue)` | historicals: `= <cost $ line, this col> ÷ <Total Revenue, this col>`; projections: **red driver input** | `"% of total revenue. Corporate cost ÷ total revenue. Projection driver."` |
| `Depreciation and amortization` *(Case A; and each D&A component line)* | NOT HAS_DNA_EMBEDDED | `(% of total revenue)` | `= <D&A $ line, this col> ÷ <Total Revenue, this col>` in **every** column, historical and projected; black, italic; never a driver | `"% of total revenue. Derived read, not a driver — D&A dollars come from the DEPRECIATION SCHEDULE section (a component line is held flat), never from this row."` |
| `Total Costs and Expenses` | | `(% of total revenue)` | `= <Total Costs and Expenses, this col> ÷ <Total Revenue, this col>` | `"% of total revenue. Total opex ÷ total revenue. (Complement = operating margin.)"` |
| `Operating margin` | | `(% of total revenue)` | `= <Operating Income (modeled), this col> ÷ <Total Revenue, this col>` | `"% of total revenue. Operating income ÷ total revenue. Derived read, not a driver."` |

- **Historical** % cells are **live formulas** (cost ÷ base) — black font (not green;
  they are derived, not inputs) — with the accounting **percent** format and italic
  styling per the styling rules.
- **Projected** % cells become **red driver inputs** (the assumption the analyst sets;
  see §9 for the driver styling and value methodology), and the corresponding **dollar**
  line in §2 flips to `= % × revenue base`. Anchor each forward % on the historical
  trend plus management guidance — merchandise margin and markdown cadence for cost of
  sales, wage and rent inflation against sales leverage for SG&A, and the fact that
  impairment / store-closure charges are episodic rather than run-rate.
- The `Total Costs and Expenses` row in the % block is convenient because its
  **complement is the operating margin** — a fast read on profitability and a bridge to
  the §7 Operating Income check.

### 3.4 — Pre-delivery checklist (% of revenue)

- [ ] Every operating-cost line has a live `% of revenue` cell; D&A's is a black
      formula in every column, its comment pointing to the depreciation schedule
      (Case A), or there is no D&A row at all (Case B).
- [ ] Each % row's Col C label is the **bare cost-line name** (no `— % of net sales` /
      `— % of revenue` suffix); the basis lives in the **cell comment**.
- [ ] **Cost of sales is struck against the revenue build's `Net Sales` row when
      laid, else `Total Revenue`** — never store-only revenue, and never a
      hand-built "total less streams" arithmetic — and the row used is named in the
      comment.
- [ ] Any **store-level** cost line presented separately is struck against the
      store-sales row the revenue build produced (`Net Sales from Stores` or
      `In-Store Revenue`, by presence) — and where no such row exists, the comment
      names the denominator used and the fallback is recorded in `BUILD_LOG.md`.
- [ ] Each denominator is a **single row referenced from the revenue build** (not
      re-entered, not arithmetic over several rows), and the base is stated in the
      cell comment.
- [ ] The computed historical ratios were **cross-checked** against any reported gross
      margin / SG&A-rate series in the inventory, and the result recorded in
      `BUILD_LOG.md`.
- [ ] Historical % cells are **live formulas**; projected % cells are **red drivers**
      (§9), and the projected **$** line equals `% × revenue base`.
- [ ] % rows use the accounting **percent** format, italic; aligned one row under (or
      beside) the matching dollar line, same column.
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Per-company-operated-location costs (conditional on an APPROVED location build)

When the store fleet exists in the workbook, express the store-level cost lines **per
company-operated location**, so the analyst can read unit economics and cross-check
them against the per-location **revenue** the revenue build produced.

### 4.1 — The test (STRICT): the `Company-Operated EOP Balance` row must be present

**Build this section only if the REVENUE section carries the location build's
`Company-Operated EOP Balance` row** — the contract row (`../../SKILL.md`, "Contract
rows"). The test is the row's **presence**, never a flag carried down from the router
and never the industry: locate the store roll-forward beneath the `REVENUE` header
and find the `Total — all banners` block's **`Company-Operated EOP Balance`** row,
populated in every column this cost block will divide, historical and projected. If
the row is absent, or present but not populated across the build window, **skip this
section entirely** — no sub-header, no empty rows, no placeholder — and record the
skip in `BUILD_LOG.md` and the §10 handoff. A row-presence test and its fallback are
build history, not a workbook note.

**The anti-workaround rule.** If the row is absent, do **not** manufacture a denominator:
do not pull a store-count series from the KPI inventory into the COSTS section, do not
re-enter a count read off a 10-K, do not substitute square footage, a segment count, or
an average store count, and do not build a "costs per store" line off a number that the
REVENUE section does not carry. A fleet that was never approved into the revenue build
is not a fleet this build may model against. The reason is the same one the revenue
router gives for hard-gating its own square-footage build: a per-unit figure whose
denominator is not the model's fleet cannot be traced, cannot be projected consistently
with revenue, and silently diverges from every other per-unit line in the workbook.

**The common failure case is the `other/` route.** When the revenue build routed to
`../../revenue/retail/other/other.md`, the workbook carries **no store roll-forward**
by construction — that build's own handoff states so, and that downstream sections
"must not expect store counts, square footage, or per-unit lines from the REVENUE
section." The row is absent, and §4 is **always** omitted.

State the outcome explicitly (one line: the row you verified, or the reason it is
absent) before building or skipping this section, so the decision is auditable.

### 4.2 — The logic and the denominator rule

```
  Cost per company-operated location = <cost $ line> ÷ <Company-Operated EOP location count>
```

- **Denominator — company-operated only, never the system total (STRICT).** Use the
  location build's **`Company-Operated EOP Balance`** row, referenced with a live
  formula, never re-entered. Do **not** use `Total System EOP Balance`: it includes the
  **franchised & licensed** fleet, whose operating costs the company does **not**
  incur — those stores generate royalty and wholesale revenue, not owned-store sales,
  and dividing company-operated costs by a system-wide count understates every
  per-location figure. This is the retail counterpart of the numerator/denominator
  universe rule, and it is the most common way this block goes wrong.
- **Match the level of the numerator to the level of the denominator.** Consolidated
  cost lines divide by the **consolidated** `Company-Operated EOP Balance`. Only where
  the issuer discloses cost lines **per banner** (Path C1) **and** the roll-forward
  carries that banner's own company-operated EOP may the block be built per banner —
  using that banner's cost line over that banner's count. **Never** divide a
  consolidated cost by a single banner's store count; the roll-forward being
  per-banner does not make the costs per-banner.
- **EOP vs. average count.** This build uses the **EOP** count, matching the retail
  revenue builds' per-unit convention (`Implied Revenue per Store` in `sqftBuild/` is
  struck against its laid `Company-Operated EOP Store Count` row), so per-location **cost** and per-location
  **revenue** are on the same basis and a store-level margin per location can be read
  off directly. (EOP slightly understates the per-unit figure in fast-expanding years;
  the distortion is the same in the cost and revenue per-unit lines, so it largely
  cancels.) Note the choice in a cell comment.

### 4.3 — Which cost lines get a per-location row

Express **the store-level cost lines the issuer actually reports** per location — no
more, no fewer:

- **`Cost of sales` (however labeled)** — always, when the fleet exists. Note in its
  comment that the numerator covers merchandise sold through every channel while the
  denominator is the store fleet, so the figure is a fleet-scaled cost read, not a pure
  per-store cost.
- **`Selling, general and administrative expenses`** — always. In retail this line
  carries store payroll and most store operating costs, which makes it the closest
  available read on per-store operating cost.
- **`Occupancy`, `Store operating expenses`, or `Store labor`** — **only** where the
  issuer presents them as separate lines. **Do not manufacture an occupancy row** for a
  retailer that reports occupancy inside cost of sales (§1.3); there is no separable
  dollar figure to divide.

Do not add per-location rows for corporate-only or episodic lines (impairment,
restructuring, pre-opening) — a per-store impairment figure is noise, not unit
economics.

### 4.4 — Layout and formula (cell-by-cell)

Place this block beneath the dollar / % blocks (per banner, beneath that banner's
blocks, in the Path C1 case where §4.2 permits a per-banner build):

```
Cost per company-operated location                                                     [sub-header: bold + underlined, size 12 — per the styling contract]
    Company-Operated EOP location count                   (locations)                  [FORMULA = ref to the location build's Total — all banners block]
    Cost of sales per location                            (USD millions per location)  [FORMULA = Cost of sales $ ÷ EOP count]
    Selling, general and administrative per location      (USD millions per location)  [FORMULA = SG&A $ ÷ EOP count]
    Occupancy per location                                (USD millions per location)  [FORMULA = Occupancy $ ÷ EOP count — ONLY if separately reported]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Company-Operated EOP location count` | HAS_LOCATION_BLOCK | `(locations)` | `= <location build's "Total — all banners" → "Company-Operated EOP Balance", same column>` | `"EOP company-operated unit count — referenced from the location build, not re-entered. Company-operated only: the franchised & licensed fleet is excluded because the company does not incur its operating costs."` |
| `Cost of sales per location` | HAS_LOCATION_BLOCK | `(USD millions per location)` | `= <Cost of sales $, this col> ÷ <Company-Operated EOP location count, this col>` | `"Cost of sales ÷ company-operated EOP locations. Numerator covers merchandise sold through every channel; read as a fleet-scaled figure, not a pure per-store cost."` |
| `Selling, general and administrative per location` | HAS_LOCATION_BLOCK | `(USD millions per location)` | `= <SG&A $, this col> ÷ <Company-Operated EOP location count, this col>` | `"SG&A ÷ company-operated EOP locations. Carries store payroll and store operating costs."` |
| `Occupancy per location` *(only if separately reported)* | DATA_DEPENDENT | `(USD millions per location)` | `= <Occupancy $, this col> ÷ <Company-Operated EOP location count, this col>` | `"Occupancy ÷ company-operated EOP locations. Built only because the issuer presents occupancy outside cost of sales."` |

- Every cell is a **live formula** (the count is a reference; the per-unit lines are
  ratios) — no hardcodes.
- Per-location rows are **per-unit money** — `(USD millions per location)`, see "Number
  format and units" above — and take the contract's per-unit format (decimals at natural
  precision), **not** the whole-number accounting format of the dollar rows above them.
- **Cross-check, do not add a row:** compare each per-location cost against the revenue
  build's per-location revenue (`Implied Revenue per Store` in `sqftBuild/`, or modeled
  store net sales ÷ the same EOP count) and confirm the implied store-level margin is
  plausible. Record the result in `BUILD_LOG.md`; it is a diagnostic, not a line
  item and not a workbook note.

### 4.5 — Pre-delivery checklist (per-location costs)

- [ ] Section present **iff** the §4.1 test holds — the `Company-Operated EOP
      Balance` row is **physically present** in the REVENUE section and populated
      across the window. Otherwise **omitted entirely**, with the skip recorded in
      `BUILD_LOG.md` and the handoff.
- [ ] **No store count was re-entered, re-derived, or substituted** anywhere in the
      COSTS section to enable this block.
- [ ] The denominator is the **`Company-Operated EOP Balance`**, referenced live —
      **never** `Total System EOP Balance` and never a franchised or licensed count.
- [ ] Numerator and denominator are at the **same level** (consolidated ÷
      consolidated, or one banner ÷ that same banner's count under Path C1).
- [ ] Cost of sales and SG&A each have a live `cost ÷ EOP count` per-location row; an
      occupancy or store-operating row exists **only** where the issuer reports one
      separately.
- [ ] The per-location cost vs. per-location revenue cross-check was run and recorded
      in `BUILD_LOG.md` (not added as a row, not a workbook note).
- [ ] After recalculation, **zero formula errors**.

---

## Section 5 — Banner / business-segment cost build (Path C1 only)

Build this section **only** when the gate (§1.6) found **banner / business segments**
— i.e. the issuer reports operating **cost lines** separately for two or more banners
or reportable segments, not merely a segment profit figure. Do **not** blend the
banners; build a **complete $ and % walkdown per banner**, then a single
**consolidated costs table** that combines them.

### 5.1 — Why per banner, never blended

Each banner has a different cost structure (merchandise margin, occupancy intensity,
SG&A rate) and a different revenue base. Dividing one banner's costs by another's
sales, or summing the banners before computing ratios, silently corrupts every ratio.
Build each banner on **its own** reported cost lines and **its own** revenue base
(from the revenue build's per-banner revenue), and let the banners meet only at the
**dollar level** in the consolidated table, where summing is always valid.

### 5.2 — Per-banner block (the full walkdown for one banner)

For **each banner**, lay a self-contained block — the §2 dollar walkdown and the §3 %
walkdown — for **that banner's** operating costs, in the **same banner order as the
revenue build's per-banner blocks** (which is in turn the location build's banner
order — keep all three consistent):

```
<Banner> — Costs                                                                       [banner header: bold + underlined, size 12]
    <each operating-cost line for this banner>            (USD in <scale>)             [deepKPI INPUT — that banner's reported segment costs]
  Total Costs and Expenses — <Banner>                     (USD in <scale>)             [FORMULA = SUM(this banner's lines); bold, SUM-BAR]
  Operating income — <Banner>                             (USD in <scale>)             [FORMULA = <Banner> revenue − Total Costs and Expenses — <Banner>; bold, SUM-BAR]
  Operating income — <Banner> (reported)                  (USD in <scale>)             [deepKPI INPUT — the reported segment operating income, where the issuer reports one]
  Memo: segment OI modeled − reported (must ≈ 0)          (USD in <scale>)             [FORMULA; italic; laid with the reported row, omitted with it where no reported figure exists]
<Banner> — Costs as % of segment revenue                                               [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <Banner> revenue)      [FORMULA = banner cost ÷ banner revenue; italic; basis in the cell comment; the D&A row a derived read in every column, as in §3.3]
  Total Costs and Expenses — <Banner>                     (% of <Banner> revenue)      [FORMULA; italic; basis in the cell comment]
<Banner 2> …                                                                           [repeat the whole block]
```

**Segment denominator (STRICT).** The % walkdown for a banner divides each banner cost
by **that banner's revenue**, **never** by total consolidated revenue. The denominator
should not be total revenue if the cost is attributable only to one banner; it should
be that banner's cost over that banner's revenue. That banner's revenue is the row, or the sum of the rows, the revenue hand-back's
**segment map** names for it (`../../SKILL.md`, "The segment map"): a brand's row in
the units build, `Total Revenue — <Banner> (modeled)` in the comparable-stores build,
the banner's revenue rows in the square-footage build. Never pick the rows by label,
and name the banner as the map spells it; a banner the map does not name gets no
block (§1's gate). Where a banner's **store** net sales was separated from its other
channels, prefer that store-level base for store-level cost lines and the banner's
total revenue for its merchandise and corporate lines, following §3.1's logic one
level down.

- Each banner's cost lines are reported **deepKPI segment inputs** (from the `Segment
  Financials` category); `Total Costs and Expenses — <Banner>` is a live `SUM`.
- The banner D&A `%` row is a derived read in every column (§3.3), never a driver, at
  the banner level too.
- **Where the segment disclosure is thinner than the consolidated block** — the
  common retail case, e.g. segment cost of sales and SG&A only, with impairment and
  pre-opening reported only consolidated — build the banner block from the lines that
  **are** disclosed, and leave the rest to the consolidated table's corporate-only
  lines (§5.3). Do not allocate a consolidated line across banners.
- If §4 is built and this banner's own company-operated EOP count exists in the
  roll-forward, the §4 per-location block may also be built **per banner** here (using
  that banner's cost lines and that banner's count) — subject to §4.1 and §4.2.
- One blank spacer row separates each banner's block from the next.

### 5.3 — The consolidated costs table (always built under Path C1)

After the per-banner blocks, lay one **consolidated costs table** that combines the
banners and foots to the reported consolidated operating block. **This is the §2 / §3
table, lifted to the consolidated level**, with each line summing the banners:

```
Consolidated Costs                                                                     [sub-header: bold + underlined, size 12 — per the styling contract]
    <each cost line that appears in the banners>          (USD in <scale>)             [FORMULA = Σ that line across banners]
    <corporate-only line, e.g. corporate SG&A>            (USD in <scale>)             [deepKPI INPUT — reported consolidated; see note]
    Depreciation and amortization                         (USD in <scale>)             [FORMULA = Σ banner D&A, or reported consolidated input]
  Total Costs and Expenses                                (USD in <scale>)             [FORMULA = SUM(consolidated lines); bold, SUM-BAR]
    Total Costs and Expenses (reported)                   (USD in <scale>)             [deepKPI INPUT — the reported anchor]
    Memo: Total Costs and Expenses sum − reported (must = 0)  (USD in <scale>)         [FORMULA check; 0 every period]
  Operating income                                        (USD in <scale>)             [FORMULA = Total Revenue − Total Costs and Expenses; bold, SUM-BAR]
Consolidated Costs — % of revenue                                                      [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <§3.1 base>)           [FORMULA = consolidated line ÷ its §3.1 base; basis in the cell comment; the D&A row a derived read in every column, as in §3.3]
  Total Costs and Expenses                                (% of total revenue)         [FORMULA = Total opex ÷ Total Revenue; basis in the cell comment]
  Gross margin                                            (% of total revenue)         [FORMULA = Gross profit ÷ Total Revenue; Presentation 1 only — the §3.2 read, laid here too]
  Operating margin                                        (% of total revenue)         [FORMULA = Operating Income (modeled) ÷ Total Revenue — the §3.2 read, laid here too]
```

**Corporate-only lines (important).** Some cost lines exist **only at the corporate /
parent level** and do **not** appear in any banner segment — most commonly **corporate
general & administrative expenses**, and sometimes consolidated impairment,
restructuring, or pre-opening costs. Carry each such line in the **consolidated table
only**, as a reported **deepKPI input** (it has no segment lines to sum), and include
it in the consolidated `Total Costs and Expenses`. In the consolidated **% table**,
corporate-only lines are divided by **total consolidated revenue** (§3.1). Where the
corporate-only line holds a slice of a cost the issuer also reports by segment (a
corporate cost of sales inside `Enterprise corporate costs`), the segment sum of that
line is **less than the face line by the slice**, and the slice stays inside the
corporate line: it is never allocated to the segments and never moved into the
summed line. The gross-profit memo then equals the slice by construction; its
comment says so (§2.2) and one Notes line states it (*"Costs: gross profit is modeled
from the segment cost-of-sales lines; the corporate line holds <x> of cost of sales
in FY<N>, which the issuer does not split, so the gross-profit memo equals that
amount."*).

**Intersegment eliminations.** Where the issuer reports an elimination or corporate
reconciling line between the sum of the segments and the consolidated total, carry it
as its **own clearly-labeled row** inside the consolidated table (a reported input),
included in the total. Do not spread it across the banners and do not let it hide
inside the memo difference.

**Followable summation (quality check 2).** Each consolidated cost line that maps to
the banners is a **`= SUM(` banner lines `)`** so the analyst can trace exactly how the
consolidated figure is built up from the segment figures; corporate-only lines are
clearly flagged (input, with a comment that they have no segment detail). The
consolidated `Total Costs and Expenses` then sums all consolidated lines and ties to
the reported figure via the memo check.

### 5.4 — Pre-delivery checklist (banner-segment build)

- [ ] **One full $ + % walkdown per banner**, same banner order as the revenue build
      and the location build; each banner's % uses **that banner's revenue** as the
      denominator, never total revenue.
- [ ] No blended cross-banner ratios; banners meet only at the dollar level in the
      consolidated table.
- [ ] A single **`Consolidated Costs`** table sums each banner line (`= SUM(banners)`),
      carries any **corporate-only** lines and any **elimination** line as reported
      inputs, and foots to reported Total Costs and Expenses (memo = 0).
- [ ] Consolidated **% table** applies the §3.1 base to each line; D&A excluded
      everywhere (dash + comment, or absent under §1.4 Case B).
- [ ] §4 per-location block built per banner **only** where that banner's own
      company-operated EOP count exists and the §4.1 row test holds.
- [ ] The consolidated `Total Costs and Expenses` traces cleanly up from the segment
      lines (followable summation); after recalculation, **zero formula errors**.

---

## Section 6 — Geographic segment cost build (Path C2 only)

Build this section **only** when the gate (§1.6) found **geographic segments** — i.e.
the issuer reports operating **cost lines** separately by geography (e.g. domestic vs.
international, or by region). The structure mirrors §5, with **geography** in place of
**banner** and a geography-aware denominator.

### 6.1 — Per-geography block

For **each geography**, lay a self-contained §2 dollar walkdown and §3 % walkdown for
that geography's operating costs:

```
<Geography> — Costs                                                                    [geography header: bold + underlined, size 12]
    <each operating-cost line for this geography>         (USD in <scale>)             [deepKPI INPUT — that geography's reported costs]
  Total Costs and Expenses — <Geography>                  (USD in <scale>)             [FORMULA = SUM(this geography's lines); bold, SUM-BAR]
  Operating income — <Geography>                          (USD in <scale>)             [FORMULA = <Geography> revenue − Total Costs and Expenses — <Geography>; bold, SUM-BAR]
<Geography> — Costs as % of segment revenue                                            [sub-header: bold + underlined, size 12]
    <each line>                                           (% of <Geography> revenue)   [FORMULA = geography cost ÷ geography revenue; italic; basis in the cell comment; the D&A row a derived read in every column, as in §3.3]
  Total Costs and Expenses — <Geography>                  (% of <Geography> revenue)   [FORMULA; italic; basis in the cell comment]
<Geography 2> …                                                                        [repeat]
```

**Geographic denominator (STRICT).** Divide each geography's cost by the **revenue
applicable to that geography** — but **only if the revenue build split revenue by
geography**. So:

- If the revenue build laid down geographic revenue lines (domestic / international /
  by region — including the banner × region blocks the retail location and revenue
  builds use where that is the reporting level), reference the **matching geography's
  revenue** as the denominator.
- If revenue is **not** split by geography, divide each geography's cost by **total
  consolidated revenue**, and state this fallback in the cell comment, since the
  resulting ratio is a cost-to-total-revenue figure, not a true within-geography
  margin.

**Currency (retail-specific).** For international fleets, a geography's costs and its
revenue are translated at the same rates, so the **ratio** is largely
currency-neutral even though both dollar lines move with FX. Do not adjust for
currency; record in the Notes block any year in which the issuer flagged a material
foreign-currency impact on net sales, so the driver seeds in §9 are read with that
in view: "Costs: FY<n> net sales carried a material foreign-currency effect; that
year's cost ratios are read against it."

The geography D&A `%` row is a derived read in every column (§3.3), never a driver,
at the geography level too.

### 6.2 — The consolidated costs table (always built under Path C2)

Identical in form to §5.3: a `Consolidated Costs` table where each line is `= SUM(` the
geographies `)`, plus any **corporate-only** lines and any **elimination** line
(reported inputs), footing to reported Total Costs and Expenses (memo = 0), followed by
the consolidated **% of revenue** table and the `Operating Income (modeled)` foot. The
consolidated table is what makes the geographic build foot and traceable.

### 6.3 — Pre-delivery checklist (geographic-segment build)

- [ ] **One full $ + % walkdown per geography**; each geography's % uses **that
      geography's revenue** as the denominator **if** revenue is split by geography,
      **else total revenue** (noted in the comment).
- [ ] A single **`Consolidated Costs`** table sums each line across geographies
      (`= SUM(geographies)`), carries any corporate-only and elimination lines as
      inputs, and foots to reported Total Costs and Expenses (memo = 0).
- [ ] Consolidated **% table** applies the §3.1 base; D&A excluded everywhere.
- [ ] §4 per-location block built only where the §4.1 row test holds and the matching
      company-operated count exists at the level being divided.
- [ ] The consolidated total traces cleanly up from the geography totals; after
      recalculation, **zero formula errors**.

---

## Section 7 — Quality checks and the foot

Before declaring the cost build done, verify **every** required quality check with live
formulas in the workbook (not by eyeballing):

### 7.1 — Gross Profit and Operating Income foots (quality check 1)

The foot rows live in the §2 walkdown, laid once: `Gross profit (reported)` beneath
`Gross profit` with `Memo: Gross profit modeled − reported (must ≈ 0)` (Presentation
1), and `Operating Income (reported)` beneath `Operating Income (modeled)` with `Memo:
Operating Income modeled − reported (must ≈ 0)`. This section lays nothing; it checks
that both memos read ≈ 0 in every historical period. A non-zero gap means a missing or
extra cost line, an embedded-D&A mismatch or a revenue-base mismatch — fix it in the
block, never plug it. `Operating Income (modeled)` and `Operating Income (reported)`
are the contract rows CONSOLIDATED FINANCIALS and the orchestrator reference.

### 7.2 — Followable summation (quality check 2)

The analyst must be able to trace **how Total Costs and Expenses is summed up across
the segments and the costs within those segments**. Confirm:

- Every `Total Costs and Expenses` (each segment's and the consolidated) is a **live
  `= SUM(...)`** over visible line rows — never a hardcoded number; `Gross profit` and
  `Operating Income (modeled)` are difference formulas.
- Under Path C1 / C2, each **consolidated** cost line is `= SUM(` the segment lines `)`
  (so the segment → consolidated roll-up is explicit), and any **corporate-only** or
  **elimination** line is clearly an input with a comment that it has no segment detail.
- The `sum − reported (must = 0)` memo on the consolidated `Total Costs and Expenses`
  evaluates to **0** every period (completeness).

### 7.3 — Column alignment to the revenue build (quality check 3 — retail-specific)

Confirm that every cost row sits on the revenue build's fiscal-year columns:

- The **newest** column's `Cost of sales` and `Total Costs and Expenses` match the
  latest 10-K income statement exactly.
- Each `% of revenue` cell divides a cost by a revenue figure **from the same fiscal
  year**, and the resulting historical ratios are stable and plausible year over year —
  a ratio that jumps by hundreds of basis points in one year and reverts the next is
  the signature of a one-column offset, not of operating performance.
- Any reported `Gross margin %` / `SG&A rate` series in the inventory agrees with the
  computed ratio for the same year (§3.1's cross-check).

### 7.4 — Final recalculation

Recalculate the workbook (LibreOffice / the xlsx skill's `recalc.py`) and confirm
**zero formula errors**, that the Gross Profit and Operating Income memos are ≈ 0 every
historical period, and that the consolidated `sum − reported` memo is 0 every period.

---

## Section 8 — Worked example (illustrative): a Dollar General-style consolidated build

A condensed illustration of **Path C0** with **Presentation 1** (gross-profit format,
single banner, no franchised fleet, D&A embedded in cost of goods sold and SG&A —
§1.4 Case B). Figures illustrative; the actual build pulls every input from deepKPI and
lets the formulas compute the ratios and totals.

**§2 dollar walkdown (one fiscal year, USD in millions):** Net sales (from the revenue
build) 40,000. Cost of goods sold 27,800 → `Gross profit = 40,000 −
27,800 = 12,200` (reported gross profit 12,200 → `modeled − reported = 0`
✓). Selling, general and administrative expenses 9,900; Impairment and store
closure costs 100. `Total Costs and Expenses = SUM = 37,800`; reported Total
Operating Expenses 37,800 → `sum − reported = 0` ✓. `Operating income = 40,000
− 37,800 = 2,200`; reported operating profit 2,200 → `modeled − reported =
0` ✓.

`Memo: depreciation and amortization (embedded in the lines above)` carries the
cash-flow D&A of 1,000 as an italic, **non-additive** input — it is already inside
cost of goods sold and SG&A, so no D&A row was added and the block still foots.

**§3 % of revenue (Dollar General reports a single revenue line, so no `Net Sales`
row was laid and every ratio divides by `Total Revenue`):** Cost of goods sold 69.5%, `Gross margin`
30.5%, SG&A 24.8%, Impairment 0.3% — each a live `cost ÷ revenue` formula. `Total
operating expenses — % of revenue = 37,800 ÷ 40,000 = 94.5%`, so
`Operating margin = 5.5%`.

**§4 per-company-operated location — built, because the row is present.** The location
build ran (single banner, Tier 1 gross flows) and its `Total — all banners` →
`Company-Operated EOP Balance` reads **20,893** for this year, with no franchised fleet,
so company-operated = system total here. `Cost of goods sold per location = 27,800 ÷
20,893 ≈ 1.3306` (USD millions per location); `SG&A per location ≈ 0.4738`. No occupancy
row is built — occupancy sits inside cost of goods sold and there is no separable figure
to divide. Cross-check recorded in `BUILD_LOG.md`: net sales per store ≈ 1.9145 (USD millions
per store) against 1.3306 + 0.4738 = 1.8044 of cost per store, implying ~0.110 of
operating income per store — consistent with the 5.5% operating margin above. ✓

**The same company without the row.** Had the retail router's location gate failed
and routed revenue to `other/`, the workbook would carry no store roll-forward and no
`Company-Operated EOP Balance` row — §4 would be **omitted entirely**, with the skip recorded in `BUILD_LOG.md`, and
**no** store count would be pulled into the COSTS section to substitute for it.

**A multi-banner issuer that discloses only segment profit** (segment revenue and
segment operating profit, with no expense-line detail) is **Path C0**, not C1: the
consolidated walkdown above is the whole build, and the reported segment revenue and
segment profit are carried as italic memo rows beneath it. Only an issuer that
discloses **cost of sales and SG&A per banner** runs §5 — a full $ + % walkdown for
each banner against that banner's own revenue, then a `Consolidated Costs` table
summing the banners and adding the **corporate-only** SG&A line, footing to reported
Total Costs and Expenses and to reported Operating Income.

---

## Section 9 — Projecting the build forward (the projection layer)

Sections §1–§8 build and quality-check the **historical** cost block. This section
explains how to populate the **projection columns** — the forward fiscal years
(`N+1 … N+5`, or whatever forward portion the **revenue build** actually laid down). It
adds **no new rows and no new line items**: every projection lives in the **forward
period columns of the rows already built** in §2–§7.

**Two ground rules that hold for the whole projection layer:**

1. **Never touch a historical cell or a historical formula.** Every value and formula
   in the historical columns (the four FYs `N−3 … N`) stays exactly as §2–§7 laid it
   down. This section writes **only** into the forward columns.
2. **Project only the columns the revenue build projected.** The cost projections
   reference forward **revenue** (and, for per-location costs, forward **unit
   counts**). A cost column can only be filled where the revenue build already laid
   down that forward period. If the revenue build did not project a given column, leave
   the matching cost column blank (dash) — do not invent a revenue base. In practice
   every retail revenue sub-build projects the full `N+1 … N+5` window, so all five
   forward columns are normally available.

The entire projection rests on **one set of drivers**: the forward **% of revenue**
assumptions (§3). Everything else in the forward columns is a **placeholder** that
either (a) flows from those drivers (the dollar costs), or (b) carries a historical
formula forward (per-location costs, the Total-Operating-Expenses sum, Gross profit,
modeled Operating income). Set the drivers first; the placeholders follow.

### 9.1 — The driver methodology (how every forward assumption is set)

**What is a driver.** The **forward `% of revenue` cells** in the `Consolidated Costs —
% of revenue` block (§3) — and the per-segment `% of segment revenue` cells (§5 / §6)
when those are projected — are the model's **true assumptions**. They are the only
cells in this build an analyst is meant to dial. Every projected **dollar** cost is
computed from them, so they are the **drivers**.

**Driver styling — RED font.** Mark **every forward driver cell red**, the styling rules' color for **estimated / assumption values**. This
makes the assumption set visible at a glance and separates the drivers an analyst may
change from the black formula cells they should not. Driver cells receive **no**
pale-green input fill and **no** provenance hyperlink — they are assumptions, not
deepKPI-sourced actuals. (Historical `% of revenue` cells stay **black live formulas**
— they are derived, `cost ÷ base`, not drivers.) Placeholders are **not** red:
projected dollar costs, per-location costs, the `Total Costs and Expenses` sum,
`Gross profit`, the `% of revenue` total row, `Gross margin`, `Operating margin`, and
modeled `Operating Income (modeled)` are all **black formula** cells.

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
  by typing a value over the formula; the cell stays red to signal it is an assumption.

- **Episodic lines do not take the default seed.** Read `../episodicLines.md` now and
  seed each in-scope line by its rule: zero for a one-off, the disclosed remaining
  cost for a program the exit-cost note describes, a spike-resistant run-rate for a
  program the issuer runs every year. In this build the in-scope captions are
  impairment of goodwill, intangibles or store assets; store-closing, restructuring or
  exit charges; asset-disposal and real-estate gains or losses the issuer presents
  inside the operating block; and litigation or settlement items. Pre-opening costs,
  provision for doubtful accounts and a recurring other operating income or expense
  line stay on the default seed. The cell comment and the Notes line read as that file
  prescribes.

- **A 53-week year `N` sits inside the seed.** Where year `N` had 53 weeks, the
  latest-year seed carries its ratios as they are — broadly comparable for variable
  costs, slightly understated for fixed-cost lines (see the time-scope section). Do
  not restate; record which year it was in the Notes block, in the wording the
  time-scope section gives, so the reader knows the seed's base.

- **D&A has no driver.** Depreciation & amortization is excluded from the `% of
  revenue` block (its `%` cell is a dash; §3.3) and is **not** projected here — its
  forward dollars reference the **depreciation schedule** (§9.3). Do not create a red
  driver for a total-D&A line; a component line is the one exception (held flat at
  its year-`N` value; `depreciation-schedule` §6.2). Under §1.4 Case B there is no D&A row at all, and the non-additive
  memo row is left **blank (dash)** in every projection column.

### 9.2 — `Consolidated Costs — % of revenue` — set the forward drivers

This block (§3) is where the drivers live, so build it **first** in the forward columns.
For **each** `% of revenue` line **except D&A**:

- Leave the **historical** `%` cells exactly as §3 laid them (`= cost ÷ matched revenue
  base`, black).
- Fill the **forward** `%` cells with the §9.1 driver methodology — `N+1` = the default seed (guided, else the latest year), each later year `= the N+1 cell` — and color every forward cell **red**.
  An episodic line takes its seed from `../episodicLines.md` instead of the default
  seed (§9.1); it is red and flat forward like every other driver.
- **D&A**: the `%` cells stay the **black formula** `= D&A $ ÷ Total Revenue` in the
  forward columns too — a read off the depreciation schedule's dollars, never a
  driver.
- **`Total Costs and Expenses` (% row), `Gross margin`, and `Operating margin`**: these
  are **not** drivers — they are derived reads. Carry their historical formulas forward
  unchanged into each projection column (black).

### 9.3 — `Consolidated Costs` ($) — project each dollar cost from its driver

With the drivers set, fill the forward **dollar** columns of the §2 walkdown. **Do not
alter any historical dollar value or the historical input styling.** For each projection
column:

- **Each operating-cost line except D&A** = its **forward `% of revenue` driver (this
  column) × the matching revenue base (this column)** — a **black live formula**, not a
  red cell (it is a placeholder derived from the driver):

  ```
  Projected cost $  =  <forward % driver, this col>  ×  <matched revenue base, this col>
  ```

  Use the **same revenue base the historical `%` used as its denominator** (§3.1): cost
  of sales × **`Net Sales`** (or `Total Revenue` when no `Net Sales` row is laid);
  separately-presented store-level lines × **`Net Sales from Stores`** or
  **`In-Store Revenue`**; corporate lines (SG&A, impairment, pre-opening, other
  operating) × **total revenue**. If the `%` was struck against a **segment-specific**
  base (one banner's or one geography's revenue — Path C1 / C2), multiply by **that same
  segment base**, never by total company revenue. Read the denominator off the historical
  `%` cell's recipe so the forward `%`→`$` math is internally consistent. Reference the
  forward revenue cell the **revenue build** already laid down; never re-enter or
  re-derive a revenue number.

- **Depreciation and amortization** (§1.4 Case A) = `= <DEPRECIATION SCHEDULE →
  Depreciation & Amortization, this col>`, the schedule's forward D&A
  (`../../depreciation-schedule/depreciation-schedule.md`, §6), referenced with a live
  formula — **not** `% × revenue`. The schedule is built before this section, so the
  row exists. A component line (schedule §6.2) is instead held flat: `N+1` is a red
  driver equal to the `N` cell, later years `= the N+1 cell`.

- **`Total Costs and Expenses`** = the **same `= SUM(...)`** formula carried into each
  projection column (black, bold, SUM-BAR). `Gross profit` and `Operating
  income` likewise carry their **difference formulas** forward. Never re-key them.

- **Every `<row> (reported)` input and every `Memo: … − reported` check**: there is **no
  reported figure for a future period**, so leave **all** of those memo cells blank
  (dash) in every projection column. The completeness and foot checks are historical-only
  controls; do not fabricate a "reported" projection.

### 9.4 — `Cost per company-operated location` — carry the formulas forward

This block (§4) is **detail only** — it drives nothing and is not a set of assumptions —
so there is **no difference between its historical and projected cells**: simply **carry
the same formulas forward** into the projection columns (black, no red). For each
projection column:

```
Company-Operated EOP location count               = <location build's forward Company-Operated EOP Balance, this col>
Cost of sales per location                        = <Cost of sales $, this col> ÷ <EOP count, this col>
Selling, general and administrative per location  = <SG&A $, this col>          ÷ <EOP count, this col>
Occupancy per location (if built)                 = <Occupancy $, this col>     ÷ <EOP count, this col>
```

The numerators are the forward dollar costs from §9.3; the denominator is the
**forward** company-operated EOP count from the location build. **Dependency:** these
per-location cells can only be filled where the location build **projected** unit
counts. The retail location build does project every roll-forward into `N+1 … N+5` (its
"Projections (forecast years)" section inverts the flows into drivers and makes EOP the
formula), so when §4 exists the forward per-location cells are normally fillable across
the whole horizon. If, exceptionally, the roll-forward carries units for the historical
years only, leave the projection cells of this block **blank** (dash) — never
substitute a count. Per banner if the block was built per banner (§4.2), using that
banner's forward costs and forward company-operated EOP count.

**And the §4.1 test still governs.** If §4 was **skipped** under §4.1, there is nothing to
carry forward — do not introduce a per-location block in the projection columns that
does not exist in the historical ones.

### 9.5 — Segment detail (§5 / §6) — project only where the segment build exists

Show **projected** segment values **only if the associated segment build exists for the
projection periods**. Two cases:

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
  per-banner / per-geography split). Then **show the segment block for the historical
  periods only and leave every projection cell of that block blank** (dash). Do **not**
  fabricate forward segment drivers or forward segment revenue that the model does not
  carry. The **consolidated** `% of revenue` drivers and consolidated dollar costs
  **still project** (§9.2–§9.3) — only the segment-level detail is left blank in the
  forward columns.

In both cases the consolidated `Total Costs and Expenses` continues to foot from
whatever lines are populated, and the segment → consolidated `= SUM(...)` roll-ups in
the historical columns are untouched.

### 9.6 — `Gross profit` and `Operating Income (modeled)` — project modeled, leave reported blank

In the §7.1 foot-check block:

- **`Gross profit (modeled)`** and **`Operating Income (modeled)`** — **carry the
  formulas forward** into every projection column, unchanged (`= Total Revenue − Cost of
  sales` and `= Total Revenue − Total Costs and Expenses`, black). The projected
  operating income is what the `CONSOLIDATED FINANCIALS` section reads.
- **`Gross profit (reported)`** and **`Operating Income (reported)`** — **leave the
  projection cells blank** (dash); there is no reported actual for a future period. Keep
  the **historical** reported cells exactly as §7.1 laid them (deepKPI inputs).
- **Both `modeled − reported` memos** — these tie-outs only have meaning where a
  reported figure exists, so leave their **projection cells blank** as well. They stay
  historical-only controls (≈ 0 every historical period).

### 9.7 — Worked illustration (projection mechanics)

Take the §8 consolidated example and project `Cost of goods sold` one year. Suppose the
historical `Cost of goods sold % of net sales` (struck against `Total Revenue`, since
Dollar General lays no `Net Sales` row) reads **68.9% / 69.2% / 69.4% / 69.5%**
across `N−3 … N`. No guidance names the cost-of-sales rate, so the first projection
driver is the latest year: `N+1 = 69.5%` (the renderer's latest-year formula over
`N−2 … N`) — a **red** cell. `N+2 … N+5` each `= the N+1 cell`, so they all read
**69.5%** (red, held flat). If forward `Total Revenue` for `N+1` is **42,400**, the
§9.3 dollar cell is `= 69.5% × 42,400 = 29,468.00` (**black** formula). `Gross profit`
for that column is `= <Total Revenue> − <Cost of goods sold> = 42,400 − 29,468.00` (black); `Total Costs and Expenses` sums the forward
column as before; `Operating Income (modeled) = forward Total Revenue − forward Total
operating expenses` (black), while `Gross profit (reported)`, `Operating income
(reported)` and every memo check sit **blank** in the `N+1 … N+5` columns. The §4
per-location rows divide the forward dollar costs by the location build's forward
`Company-Operated EOP Balance`. D&A, being embedded in this issuer's lines (§1.4 Case
B), has no row and no driver, and its memo row stays blank forward.

### 9.8 — Pre-delivery checklist (projections)

- [ ] On a segment path, `../segmentSpine.md` was applied: one level carries the
      drivers, the other is derived, and the Σ-segments memo reads 0 in every
      projection column.

- [ ] Every episodic line named in §9.1 is seeded by `../episodicLines.md`, not the
      default seed; its cell comment states the treatment and the Notes carry the line.

- [ ] **No historical cell or formula changed** — projections live only in the forward
      columns the **revenue build** projected.
- [ ] **Forward `% of revenue` drivers are RED** (no green fill, no hyperlink), set as
      `N+1` = the default seed and each later year `= the N+1 cell` (held flat);
      historical `%` cells stay **black formulas**.
- [ ] **D&A** has **no** red driver — its `%` cells stay black formulas and its forward
      dollars reference the depreciation schedule's `Depreciation & Amortization` row (Case A;
      a component line is held flat instead); under Case B there is no D&A row and the
      non-additive memo stays blank forward.
- [ ] **Projected dollar costs are BLACK formulas** = forward `%` driver × the
      **matching** forward revenue base (the same denominator the historical `%` used:
      `Net Sales` / the store-sales row / total revenue / segment base — never
      blindly total revenue).
- [ ] **`Total Costs and Expenses`** stays the live `= SUM(...)`, and `Gross profit` /
      `Operating Income (modeled)` stay difference formulas, in every projection column; **all**
      reported and `− reported` memo cells are **blank** for projections.
- [ ] **Per-location block** carries its `cost ÷ EOP count` formulas forward (black)
      against the location build's **forward** `Company-Operated EOP Balance` — and does
      not exist at all if the §4.1 row is absent.
- [ ] **Segment detail** projects **only** where the segment build exists forward;
      otherwise the segment block is blank in the projection columns while the
      consolidated block still projects.
- [ ] **`Gross profit (modeled)`** and **`Operating Income (modeled)`** formulas carried
      forward (black); their **reported** rows and the **modeled − reported** memos are
      **blank** in the projection columns; historicals untouched.
- [ ] After recalculation, **zero formula errors**; historical quality checks (§7) still
      pass unchanged.

---

## Section 10 — Downstream handoff

After the cost build is laid down, recalculated, and every quality check passes:

- Confirm **zero formula errors**, the **Gross Profit** and **Operating Income** memos
  ≈ 0 every historical period, and the consolidated `sum − reported` memo = 0 every
  period.
- **Report the §1.4 D&A case.** Under **Case A** the build deliberately leaves **D&A
  as the only operating line not projected here** — the **depreciation schedule**
  (`../../depreciation-schedule/depreciation-schedule.md`, built before this section)
  owns the D&A projection, and the §2 D&A row's projected cells reference its
  `Depreciation & Amortization` row. Under **Case B** there is **no D&A row in the
  operating block**: state it, so that no later step creates one (which would
  double-count against cost of sales and SG&A). CONSOLIDATED FINANCIALS takes its D&A
  from the schedule directly in either case.
- **Report the §4 outcome.** State whether the per-company-operated-location block was
  **built** (naming the roll-forward row it divides by and the level — consolidated or
  per banner) or **skipped**, and if skipped, that the `Company-Operated EOP Balance` row was absent (§4.1).
  The consolidated-financials section reads this to know
  whether per-unit cost lines exist in the workbook.
- The **consolidated-financials** section will reference `Total Costs and Expenses`,
  `Gross profit` (where built), and `Operating Income (modeled)` directly when it
  assembles the income statement, so keep those row labels stable and the revenue-base
  references explicit.
- **Record in the workbook Notes**, one line per fact, in the analyst's words:
  - the presentation: "Costs: the issuer presents <a gross-profit format / a single
    total costs line>; the block follows the income statement."
  - the D&A treatment, one line: "Costs: depreciation and amortization is <a separate
    line / embedded in cost of sales and SG&A>." (where embedded, the §1.4 line
    already carries this; do not repeat it)
  - where the build ran on segments, the line `../segmentSpine.md` prescribes;
  - the revenue base per cost line: "Costs: cost of sales is struck against net
    sales, which excludes <streams>; store-level lines against store sales;
    corporate lines against total revenue." (the per-row base stays in each
    comment)
  - every 10-K override cell, one line each: "Costs: <line> FY<n> is taken from the
    10-K income statement; the database series was <scaled / mis-tagged /
    missing>."
  - the 53-week year, if any: "Costs: FY<n> was a 53-week year; its fixed-cost
    ratios are slightly understated against the 52-week years."
  - any material foreign-currency year: "Costs: FY<n> net sales carried a material
    foreign-currency effect; that year's cost ratios are read against it."
- **Record in `BUILD_LOG.md`** (build history, never the workbook Notes): the
  segmentation path taken and, if the segment-profit trap applied, that it did; the
  §4.1 row test and its outcome; the omission of the two total-costs memo rows where
  the issuer reports no such figure; any store-level denominator fallback; the result
  of the reported gross-margin / SG&A-rate cross-check; and the per-location cost vs.
  revenue cross-check.
- Hand control back to the costs router (`../costs.md`), which returns to the
  orchestrator to continue with the remaining sections.

---

*This build is part of the Revelata operating-model skill set. It writes only the
retail COSTS section (the operating block walked down to Total Costs and Expenses and
Operating Income, in dollars and as a % of revenue); D&A projection, the consolidated
statements, and all other sections are owned by their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Total Revenue` (`rev_total`) | revenue build | always | none — stop |
| `Net Sales` (`net_sales`) as the cost-of-sales denominator | revenue build | the inventory's income statement shows a merchandise net sales line and a separate revenue line | `Total Revenue`, tag `(% of total revenue)` |
| each banner's revenue rows for the §5 banner blocks (`<Banner> revenue`), as the revenue hand-back's segment map names them | revenue build | the segment map names the banner | no banner block for that banner: the segmentation gate takes a segment path only for banners the map names |
| `Net Sales from Stores` / `In-Store Revenue` as the store-level denominator | retail comparable-stores build / square-footage build | the revenue hand-back report names route A / route C | the other of the two by presence; else omit the store-level rows |
| `Company-Operated EOP Balance` (`coeop_total` / `coeop_<banner>`; the location build's "Total — all banners" block; the forward Company-Operated EOP Balance) | location build | the retail location gate PASSED | omit the per-location rows; state why in the cell comment of the affected store-level cost driver |
| `Depreciation & Amortization` (`dna`) | depreciation schedule | always | none — stop |
