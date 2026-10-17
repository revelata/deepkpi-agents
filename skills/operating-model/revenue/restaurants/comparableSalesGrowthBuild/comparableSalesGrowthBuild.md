---
name: revenue-restaurants-comparable-sales-growth
description: >
  Comparable-sales-growth build for restaurant companies in the operating-model
  workbook. Invoked by the restaurant router (`revenue/restaurants/restaurants.md`)
  when the company reports comparable-store sales growth % (and usually a
  menu-price / mix / traffic decomposition) plus revenue and total location count,
  but does NOT report the comparable-cohort dollar series required by
  `comparableStoresBuild/`. Projects restaurant revenue as comparable-restaurant growth on the
  prior-year restaurant base plus explicit new-restaurant, annualization and closure contributions,
  instead of a single blended revenue-per-restaurant YoY %. The unit roll-forward
  is laid down by `locationBuild/locationBuild.md` before this build runs. Receives
  the resolved `company_id`, official company name, workbook path, and the shared
  KPI inventory; builds beneath the `REVENUE` ALL-CAPS header. Sections: §1
  comparable-sales decomposition, §2 revenue from restaurants (comparable + new-restaurant + annualization +
  closure identity), §3 franchise revenue, §4 other + total revenue, §5 multi-brand
  / other product lines + consolidated table, §6 worked example, §7 downstream
  handoff, plus Projections (forecast years) with optional latest-quarter recency
  seeding for N+1 drivers.
---

# revenue — restaurants — comparable-sales-growth build

This is the **comparable-sales-growth** restaurant revenue build. It is invoked by
the restaurant router (`../restaurants.md`) when the company **lacks** the
comparable-cohort **dollar** bridge that gates `../comparableStoresBuild/`, but
**does** report **comparable-store sales growth %** (and often a price / check /
traffic split) together with **revenue** and **total location count**. It sits
**between** the full comparable-stores build (A) and the blended
revenue-per-restaurant build (C): it captures price-vs-traffic dynamics and
separates same-store growth from unit growth without fabricating a comparable-
cohort dollar base.

By the time control reaches this build, the **unit-count roll-forward has already
been laid down** in the workbook by `../locationBuild/locationBuild.md`. This
build is responsible only for the **revenue** lines and **references** the EOP
counts, **Company Openings**, **Company Closures** and, where the location build laid
them, **Net Franchise Transfers** and **Other** rows of the company-operated roll
already in the location build — it does not rebuild the unit roll-forward.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook (with the unit roll-forward already laid
down), the **shared KPI inventory** from the orchestrator, and the router's note
that **revenue, total location count, and at least one comp-sales signal**
(single comp % or its decomposition) satisfied the comparable-sales-growth
criteria.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
`../../../../_common/revelata-excel-units-and-scale.md` (see "Number format and units"
in the conventions below) and build with the **xlsx** skill. All conventions there apply
here — one row per distinct series, deepKPI-sourced values as pale-green hyperlinked
input cells, and **every** total / derived cell as a live `=` formula (never a hardcoded
number) — **except** for the **time scope**, which this build overrides per the "Time
scope" section below.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped.
  This matches the location build and the other restaurant revenue builds.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`). This build lays down the **historical**
  columns first (Sections 1 – 5), then **extends the entire revenue build into the
  projection window** following the **Projections (forecast years)** section near
  the end of this file.

> The sections present here — §1 through §7, plus **Projections (forecast years)**
> — are the implemented scope. Do not build outside these sections.

---

## Revenue build — framework overview (Sections 1 – 4)

This build foots to the company's **reported total revenue** using the same
top-level assembly as the revenue-per-restaurant build:

```
  Revenue from Restaurants         (§2 — comparable + new-restaurant + annualization + closure; per brand / product line)
+ Revenue from Other Product Lines   (§5 — only when issuer reports comp on non-restaurant lines)
+ Revenue from Franchises            (§3 — consolidated; only if franchise revenue is reported)
+ Other Revenue                      (§4 — plug)
─────────────────────────────────────────
= Total Revenue                      (§4 — reported anchor in history)
```

**Historical vs projection split (critical):**

- **Historical (`N−3 … N`):** `Revenue from Restaurants` is the **reported deepKPI
  anchor** (company restaurant / product-line revenue). The comp decomposition
  rows in §1 are **memo** rows that explain disclosed comp growth; they do **not**
  override reported restaurant revenue in history.
- **Projection (`N+1 … N+5`):** `Revenue from Restaurants` is **assembled** from
  the comparable + new-restaurant + annualization + closure identity in §2 using forward drivers from §1 and
  the location build.

**Conventions that apply to all sections (read once):**

- **Annual columns** — same four annual period columns (Col E onward) the location
  build uses.
- **Per brand / product line, then consolidate** — restaurant comp blocks follow
  the location build's brand order; non-restaurant product lines (e.g. retail) get
  their own comp block per §5.
- **Universe consistency** — comp %, restaurant revenue, and location counts must
  be on the **same basis** (company-owned vs. total system) per brand. See the
  rigor note in §2.1.
- **Reference the location build** — EOP counts, `Company Openings`, `Company
  Closures` (or its implied variant) and, where laid, `Net Franchise Transfers` and
  `Other` are **live references** to the company-operated roll, never re-entered.
- **Additive comp convention** — match `../comparableStoresBuild/comparableStoresBuild.md`
  §2.2: issuers present comp components as **additive contributions**
  (`SSS ≈ Guest traffic % + Average check %`, `Average check % ≈ Menu price % +
  Mix & other %`). Note in comments that the exact relationship is multiplicative,
  `(1+traffic)(1+check) − 1`.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §1.2, the two §2.1
  blocks and §5.3 — and in the `Units (Col D)` column of the §1.2 and §2.2 tables; the
  §3 rows take the tags shown in `../franchiseRevenueBuild/franchiseRevenueBuild.md`
  §2.2 / §3.1 and the §4 rows those shown in
  `../revenuePerRestaurantBuild/revenuePerRestaurantBuild.md` §3, where this file
  already sends you for their layout. Dollar rows show the placeholder `(USD in
  <scale>)`: the contract's Rule 2 supplies the scale, millions by default, thousands
  where the digit test puts a small filer. Three classifications are specific to this
  build:
  - **Section 1 is all bare `(%)`.** `Comparable sales (SSS), %` and its components —
    menu price, mix & other, average check, guest traffic — are period-over-period
    growth rates (the components are additive contributions to one), as is `Revenue per
    Restaurant — YoY %`, so every one takes the bare `(%)` the contract's Rule 5
    reserves for a period change; the labels keep their `, %` suffix. Each stores the
    decimal fraction (`0.052`, not `5.2`) once the §1.3 normalization has been applied.
    The one percent that is not a period change is `New-Restaurant Productivity`,
    tagged `(% of prior-year Revenue per Restaurant)` — the row it scales.
  - **The count row keeps the location build's tag; the per-unit noun is the label's.**
    `Company-Operated EOP Restaurant Count` is a live reference to the location build's
    `Company-Operated EOP Balance` for the brand — the company roll, never the
    franchised roll or the system total — and carries that row's `(locations)`. `Revenue per Restaurant` divides
    money in millions by that count and is tagged `(USD millions per restaurant)` — a
    per-unit tag takes the noun of its own row label ("per Restaurant" → per restaurant;
    the cost build's "per location" rows → per location; the comparable-stores build's
    "per Store" rows → per store), so a tag never contradicts the label beside it. A
    reader can divide the two rows above and land on the figure (§5 example: `4,600 ÷
    648 ≈ 7.10` in the per-restaurant build). It is a dollar figure: never round it to
    whole units.
  - **Totals carry the SUM-BAR.** `Revenue from Restaurants` (the sum of the three
    bridge rows in projection, the reported anchor in history), `Revenue from
    Restaurants — Total`, `Revenue from Other Product Lines — Total` and `Total Revenue`
    are bold with a single thin top border across the data columns only, per
    `../../../../_common/revelata-excel-styling-rules.md`.
- **Reading the layout blocks (§1.2, §2.1, §5.3).** Each row's annotation has two
  columns, left to right: the **Col D units tag in parentheses** — `(USD in <scale>)`
  means the contract's Rule 2 sets the money scale; every other tag is written as it
  goes in the cell — and the note in **square brackets**: `[deepKPI INPUT …]` for a
  pulled value, `[FORMULA …]` for a computed row, `driver` for a projection assumption,
  plus styling (`SUM-BAR`) and whether the row holds values in historical or projection
  columns only. The `Consolidated Revenue` header line carries no tag.

---

## Section 1 — Comparable-sales decomposition

Lay this block **above** the §2 revenue assembly for each **restaurant product
line** (and repeat per non-restaurant product line in §5 with that line's comp
series). In **historical** columns the rows are memo / disclosure; in
**projection** columns the independent drivers feed the §2 identity.

### 1.1 — Decompose only when disclosed

Restaurants commonly break comp sales into **guest traffic** and **average check**,
and sometimes split average check into **menu price** and **product mix**. When
that granularity is disclosed, lay each component as its own row beneath the
total SSS row. When **only a single reported comp %** exists, lay **only** the
`Comparable sales (SSS), %` row (deepKPI input) and **omit** the price / check /
traffic sub-rows — the build is still valid; decomposition is enriching, not
required.

**Driver independence (projection columns only).** The independent forward
assumptions are:

- `Menu price increase, %`
- `Mix & other, %`
- `Guest traffic, %`

Do **not** make `Average check increase, %` a driver when menu price and mix are
also present — it is always a **formula**. When only traffic and average check are
disclosed (no menu/mix split), the independent drivers are `Average check increase,
%` and `Guest traffic, %`, with menu/mix rows omitted.

### 1.2 — Row layout and formulas

```
Comparable sales (SSS), %                             (%)                                       [historical: FORMULA = Average check + Guest traffic, or deepKPI INPUT when no decomposition; projection: FORMULA, or driver on the single-comp-% path]
  Menu price increase, %                              (%)                                       [deepKPI INPUT — only if disclosed; projection driver]
  Mix & other, %                                      (%)                                       [deepKPI INPUT or FORMULA — see the table below]
  Average check increase, %                           (%)                                       [deepKPI INPUT OR FORMULA = Menu price + Mix]
  Guest traffic, %                                    (%)                                       [deepKPI INPUT — only if disclosed; projection driver]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Historical columns | Projection columns |
|---|---|---|---|---|
| `Menu price increase, %` | DATA_DEPENDENT | `(%)` | deepKPI **input** % (pale-green, hyperlinked) when disclosed; else omit row | **Driver** (red + dashed) when disclosed; see **Projections** for seeding |
| `Mix & other, %` | DATA_DEPENDENT | `(%)` | deepKPI **input** when issuer discloses mix separately; else `= Average check − Menu price` when both menu and average check disclosed | **Driver** when disclosed; else `= Average check − Menu price` (formula) |
| `Average check increase, %` | DATA_DEPENDENT | `(%)` | deepKPI **input** when menu/mix split **not** disclosed; else `= Menu price + Mix & other` | **Formula** `= Menu price + Mix & other` when split disclosed; else **driver** |
| `Guest traffic, %` | DATA_DEPENDENT | `(%)` | deepKPI **input** when disclosed; else omit | **Driver** when disclosed |
| `Comparable sales (SSS), %` | DATA_DEPENDENT | `(%)` | deepKPI **input** when no decomposition; else `= Average check + Guest traffic` | **Formula** `= Average check + Guest traffic` (never a driver when decomposition present) |

- **Single-comp-% path:** when only total SSS is disclosed, the SSS row is a
  deepKPI input in history and a **driver** in projection (red + dashed); omit
  all sub-rows.
- **Base-year component missing** (e.g. traffic not disclosed for FY2022): leave
  that cell a dash; leave that year's computed SSS memo blank if a component is
  missing; reported `Revenue from Restaurants` in §2 is unaffected.

### 1.3 — deepKPI percent scaling (rigor note)

deepKPI may return comp / traffic series with inconsistent scaling (e.g. `-5000.0`
meaning −5.0%, `3500.00` meaning 3.5%). **Normalize** every % series before use:
anchor against a reliably scaled series (menu-price % is usually clean), validate
that `Comparable sales (SSS), % ≈ Average check + Guest traffic` foots to the
reported annual comp % within tolerance, and note any normalization in a Col C
comment.

### 1.4 — Sourcing patterns (non-exhaustive)

Search the shared inventory via `search_kpis` for patterns such as:

- **Annual:** `Average menu price increase`; `Average Check Increase for
  Restaurant Product Line`; `Comparable Restaurant Guest Traffic`; `Comparable
  Store Sales Increase for Restaurant Product Line`; `Comparable Store Sales
  Decrease for Retail Product Line`.
- **Quarterly (recency seed only):** `Average menu price increase - Three-month
  period`; `Average Check Increase - quarter ended`; `Comparable Restaurant Guest
  Traffic - quarter ended`; `Comparable Store Sales Increase (Decrease) for
  Restaurant Segment - quarter ended`; matching retail-segment quarterly comp
  series.

### 1.5 — Pre-delivery checklist (decomposition)

- [ ] Decomposition rows appear **only when disclosed** — no invented splits.
- [ ] Driver independence rule respected: menu + mix + traffic **or** average
      check + traffic **or** SSS alone — never menu and average check both as
      drivers.
- [ ] Historical SSS memo reconciles to reported comp % when all components exist.
- [ ] Percent values normalized; scaling documented if adjusted.

---

## Section 2 — Revenue from Restaurants (comparable + new-restaurant + annualization + closure)

The analytical core. Built **one block per restaurant product line / brand**,
directly beneath that brand's §1 decomposition and location roll-forward.

### 2.1 — The logic

**Projection identity (each column `N+1 … N+5`, chained year over year):**

```
  Comparable sales (SSS), %                           (%)                                       [from §1 — driver or FORMULA]
  Comparable Restaurant Revenue                       (USD in <scale>)                          [FORMULA = prior-year Revenue from Restaurants × (1 + SSS %); projection only]
  Revenue from New Restaurants                        (USD in <scale>)                          [FORMULA = Company Openings × prior-year Revenue per Restaurant × New-Restaurant Productivity × 0.5; projection only]
  Annualization of Prior-Year Openings                (USD in <scale>)                          [FORMULA = prior-year Company Openings × prior-year Revenue per Restaurant × New-Restaurant Productivity × 0.5; projection only]
  New-Restaurant Productivity                         (% of prior-year Revenue per Restaurant)  [driver; default 0.85; projection only]
  Closure & Transfer Impact                           (USD in <scale>)                          [FORMULA = SUM(Company Closures, Net Franchise Transfers, Other) × prior-year Revenue per Restaurant — the company roll's rows, a term omitted where the roll has no such row; projection only]
  Revenue from Restaurants                            (USD in <scale>)                          [FORMULA = Comparable Restaurant Revenue + Revenue from New Restaurants + Annualization of Prior-Year Openings + Closure & Transfer Impact; bold, SUM-BAR]
```

**The partial-year factor (0.5).** A restaurant opened during the year is open, on
average, for half of it — the same **partial-year factor = 0.5** the comparable-stores
build applies to its non-comparable cohort. So this year's openings earn **half** a
year of productivity-adjusted revenue per restaurant, and **last year's openings earn
the other half** this year — the annualization row. With a steady opening pace the two
rows sum to one full year per opening, which is what a single full-year term would
give; the two-row form is exact when the opening pace accelerates or slows. The 0.5 is
a framework constant — do not adjust it per company.

**Historical columns:**

```
  Company-Operated EOP Restaurant Count               (locations)                               [FORMULA = ref to the location build's Company-Operated EOP Balance, same brand, same column]
  Revenue from Restaurants                            (USD in <scale>)                          [deepKPI INPUT — reported anchor; bold, SUM-BAR]
  Revenue per Restaurant                              (USD millions per restaurant)             [FORMULA = Revenue from Restaurants ÷ Company-Operated EOP Restaurant Count; memo]
  Revenue per Restaurant YoY %                      (%)                                       [FORMULA = this ÷ prior − 1; memo]
```

- `Revenue per Restaurant` uses **prior-year** values in the projection formulas
  for the new-restaurant, annualization and closure lines.
- **New-Restaurant Productivity** defaults to **0.85** in projection (driver) — the
  ramp factor, a new restaurant's volume as a share of the prior-year revenue per
  restaurant (the mature average unit volume); historical memo optional if the
  issuer discloses ramp factors.
- **Location-build references (strict row names):**
  - New-restaurant openings → `Company Openings` for the same brand / universe
    (this year's column for `Revenue from New Restaurants`, the prior year's column
    for `Annualization of Prior-Year Openings`; in `N+1` the prior year's openings
    are the historical `N` actual).
  - Closure and transfer drag → the company roll's `Company Closures` (or `Company
    Net Closures (implied)`), `Net Franchise Transfers` and `Other` rows, summed as
    separate arguments with a term omitted where the location build laid no such row
    (each already signed: closures negative, units acquired from franchisees positive,
    units sold to franchisees negative). Never the franchised roll's rows.
- **Single-comp-% path:** the §1 SSS driver feeds `Comparable Restaurant Revenue`
  directly; the new-restaurant, annualization and closure rows still apply.

**Rigor note — isolate restaurant revenue when other streams are material.**
When franchise revenue or retail / other product lines are material, the reported
`Revenue from Restaurants` input and the comp % series must be on the **restaurant
(company-owned) product-line universe** — not consolidated revenue that mixes
retail, franchise fees, or licensing. Non-restaurant product lines get their own
§5 block. State the universe in a Col C comment.

**Rigor note — comp on total restaurant base vs comparable cohort.** This build
applies SSS to **prior-year total restaurant revenue**, not to a comparable-cohort
dollar base partitioned in §1 of the comparable-stores build. That is intentional
for issuers who disclose comp % without cohort dollars; accept the approximation
versus build A's cohort machinery.

### 2.2 — Layout and formula (cell-by-cell, per brand / restaurant product line)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Company-Operated EOP Restaurant Count` | | `(locations)` | `= <location build's Company-Operated EOP Balance, same brand, same column>` | `"Company-operated EOP count — referenced from the location build, not re-entered"` |
| `Revenue from Restaurants` | | `(USD in <scale>)` | historical: deepKPI **input**; projection: `= Comparable + New Restaurants + Annualization + Closure` | `"Reported anchor in history; assembled in projection"` |
| `Revenue per Restaurant` | | `(USD millions per restaurant)` | `= Revenue from Restaurants ÷ Company-Operated EOP Restaurant Count` | `"Memo — not a projection driver"` |
| `Revenue per Restaurant YoY %` | | `(%)` | `= this col ÷ prior col − 1` | `"Memo"` |
| `Comparable Restaurant Revenue` | ALWAYS_DASHES_OK | `(USD in <scale>)` | projection only: `= <prior col Revenue from Restaurants> × (1 + <SSS %>)` | `"Same-store growth on prior restaurant base"` |
| `Revenue from New Restaurants` | ALWAYS_DASHES_OK | `(USD in <scale>)` | projection only: `= <Company Openings, this col> × <prior col Revenue per Restaurant> × <New-Restaurant Productivity> × 0.5` | `"This year's openings × prior-year revenue per restaurant × ramp factor × the 0.5 partial-year factor (open half the year on average). Openings from location build × mature AUV × productivity"` |
| `Annualization of Prior-Year Openings` | ALWAYS_DASHES_OK | `(USD in <scale>)` | projection only: `= <Company Openings, prior col> × <prior col Revenue per Restaurant> × <New-Restaurant Productivity> × 0.5` | `"Last year's openings earn the second half of their first full year this year. Prior-year openings from the location build (the N actual in N+1)."` |
| `New-Restaurant Productivity` | ALWAYS_DASHES_OK | `(% of prior-year Revenue per Restaurant)` | projection **driver**; default **0.85** | `"Ramp factor: a new restaurant's volume as a share of the prior-year revenue per restaurant (mature AUV)"` |
| `Closure & Transfer Impact` | ALWAYS_DASHES_OK | `(USD in <scale>)` | projection only: `= SUM(<Company Closures>, <Net Franchise Transfers>, <Other>) × <prior col Revenue per Restaurant>` — the company roll's rows, as separate arguments, a term omitted where that row is not laid | `"Closures, net franchise transfers and residual from the company-operated unit roll × prior-year revenue per restaurant. Closed and sold units lose a full year of the average unit volume; acquired units gain it."` |

- In **historical** columns, lay only `Company-Operated EOP Restaurant Count`, `Revenue from
  Restaurants` (input), `Revenue per Restaurant`, and `Revenue per Restaurant —
  YoY %`. Omit the comparable / new-restaurant / annualization / closure bridge rows in history (or leave
  them blank / dashed) — they are projection mechanics only.
- In **projection** columns, the bridge rows are live formulas; `Revenue from
  Restaurants` equals their sum.

### 2.3 — Pre-delivery checklist (Revenue from Restaurants)

- [ ] Historical `Revenue from Restaurants` is reported deepKPI input every year.
- [ ] `Company Openings`, `Company Closures` and, where laid, `Net Franchise Transfers`
      and `Other` are **live references** to the location build's company roll.
- [ ] Projection identity foots every year: Comparable + New Restaurants + Annualization + Closure = Revenue
      from Restaurants.
- [ ] Universe matches §1 comp series and location counts.
- [ ] Zero formula errors after recalculation.

---

## Section 3 — Revenue from Franchises (if applicable)

**Include only if the shared KPI inventory carries a franchise-revenue series**
(the block's §1.1 gate). Otherwise **skip entirely** — no empty rows. The location
build's Franchised roll decides the block's mode, not whether the block exists.

Lay the franchise lines through the **shared franchise revenue block**,
`../franchiseRevenueBuild/franchiseRevenueBuild.md` (a sibling import, read at this
point): its §1 selects **Mode A** (sales-linked streams = prior year × (1 +
franchised unit growth from the location build) × (1 + franchise same-restaurant
sales growth); non-sales streams on their own drivers) or the fallback **Mode B**
(reported franchise revenue grown by `Franchise Revenue YoY %`); its §2 / §3 give
the layout, formulas and checklist; its §5 the projection seeds. The labels
`Revenue from Franchises` and `Franchise Revenue YoY %` are fixed — §4 below
subtracts the former in its Other plug.

---

## Section 4 — Other Revenue and Total Revenue

Closes the build with the **Other Revenue** plug and **Total Revenue** foot.

Same logic, layout, sourcing, and checklist as
`../revenuePerRestaurantBuild/revenuePerRestaurantBuild.md` **Section 3**, with
one extension when §5 models non-restaurant product lines:

```
  Other Revenue = Total Revenue
                − Revenue from Restaurants — Total
                − Revenue from Other Product Lines — Total   (0 if §5 not used)
                − Revenue from Franchises
```

When no non-restaurant product-line block exists, drop the middle term (identical
to build C).

---

## Section 5 — Multi-brand parents, other product lines, consolidated table

### 5.1 — Per-brand restaurant blocks

For each brand in the location build (same order), lay **§1 decomposition** then
**§2 revenue assembly** directly beneath that brand's location roll-forward.

### 5.2 — Other product lines (e.g. retail)

When the issuer reports **comparable sales % on a non-restaurant product line**
(e.g. CBRL retail / MSBC), lay a **separate** §1 + §2 mini-block for that line
using that line's comp series and **reported revenue for that product line** as
the historical anchor. Use the same location universe only if the product line
shares units; otherwise omit unit-count rows and apply only the comparable revenue
line:

```
  Comparable revenue (other product line) = prior-year reported product-line revenue × (1 + SSS %)
```

Sum non-restaurant product lines into **`Revenue from Other Product Lines — Total`**.

### 5.3 — Consolidated revenue table

```
  <Brand A> — Revenue from Restaurants                (USD in <scale>)                          [§2]
  <Brand B> — Revenue from Restaurants                (USD in <scale>)                          [§2]
  …
  <Retail / MSBC> — Revenue from Other Product Line   (USD in <scale>)                          [§5.2, when applicable]
  Consolidated Revenue                                                                          [section sub-header: bold + underlined, size 12]
    Revenue from Restaurants — Total                  (USD in <scale>)                          [FORMULA = Σ restaurant product lines; bold, SUM-BAR]
    Revenue from Other Product Lines — Total          (USD in <scale>)                          [FORMULA = Σ non-restaurant lines; omit if none; bold, SUM-BAR]
    Revenue from Franchises                           (USD in <scale>)                          [§3]
    Other Revenue                                     (USD in <scale>)                          [§4 plug; projection = the ratio row beneath × the named components]
      Other Revenue — % of Modeled Revenue            (% of modeled revenue)                    [§4 ratio driver, per the revenue-per-restaurant build §3]
    Total Revenue                                     (USD in <scale>)                          [deepKPI INPUT — reported foot in history; bold, SUM-BAR]
```

Single-brand operators with no separate retail line need **no** consolidated
header — the one stack plus franchise / Other / Total already foots.

---

## Section 6 — Worked example (Cracker Barrel — CBRL)

Illustrative acceptance check from a comp-build prototype (figures rounded):

- **Routing:** CBRL reports restaurant comp %, menu price, average check, guest
  traffic, revenue, and location count, but **not** a comparable-cohort dollar
  bridge → **comparable-sales-growth** (not comparable-stores, not blended
  rev/restaurant).
- **Historical:** `Revenue from Restaurants` = reported restaurant product-line
  revenue; §1 memo rows reconcile SSS ≈ average check + traffic.
- **Projection `N+1`:** seed menu price / traffic (and retail comp if applicable)
  from the **latest reported fiscal quarter** after annual `N` (green hyperlinked
  actuals — see **Projections**); new-restaurant productivity ≈ 0.85 with the 0.5
  partial-year factor on this year's and last year's openings; openings, closures
  and transfers from the location build.
- **Validation:** recomputed FY2026 total revenue ≈ **$3.24B**, in line with
  company guidance ($3.24–3.27B) and consensus (~$3.26B), versus ~$3.56B under
  flat blended rev/restaurant YoY growth.

---

## Projections (forecast years)

After historical Sections 1 – 5 are laid down, recalculated, and footed (`Memo:
components − Total (must = 0)` = 0), extend into `N+1 … N+5` per the **Model
timeline** in `../../../SKILL.md`.

> This section is the **single source of truth** for projection styling and
> seeding.

### Driver styling

- **Standard projection drivers** — red font + dashed border on all
  four sides; no pale-green fill; no hyperlink. Applies even when the seeded value
  is a live formula.
- **`N+1` recency seed (green actual).** When deepKPI has **quarterly** comp /
  price / traffic (or retail comp) for a fiscal quarter **more recent than annual
  `N`**, seed each corresponding **`N+1`** driver to that **latest reported
  quarter** value as a **pale-green hyperlinked input** (it is an actual, not an
  assumption). Use the quarterly rate **as the full-year `N+1` assumption** — do
  **not** annualize (×4) unless the issuer's convention requires it. Document which
  quarter was used in a Col C comment.
- When the modeler overwrites a green `N+1` recency cell, it becomes their
  assumption — restyle to red + dashed if they replace the value with a forward
  estimate not tied to a filing.
- **`N+2 … N+5`:** revert to standard **red + dashed** drivers.

### Driver value methodology

**Independent comp drivers** (`Menu price increase, %`, `Mix & other, %`, `Guest
traffic, %` — or `Average check increase, %` + `Guest traffic, %` when no menu/mix
split — or `Comparable sales (SSS), %` alone when no decomposition):

1. **`N+1` — issuer guidance (first, when the guidance table names it).** When the
   orchestrator's guidance table carries a comparable-sales figure for fiscal year
   `N+1` at this driver's scope (company-operated, franchised or system; a nameplate
   where the issuer guides by nameplate), seed `N+1` at the midpoint as a red driver
   hyperlinked to the exhibit, the comment quoting the issuer. A full-year outlook
   from management supersedes a single quarter's print. A systemwide-sales figure is
   not a comp and does not seed this driver.
2. **`N+1` — recency seed (when no guidance names it).** If quarterly data exist
   for a period after annual `N`, pull the **latest fiscal quarter** and enter as
   green hyperlinked inputs in the `N+1` column for each disclosed component (and
   for each non-restaurant product-line comp driver in §5).
3. **`N+1` — fallback.** If neither exists, seed `N+1` at the **latest historical
   year** (`N`), the default seed (red + dashed).
4. **`N+2` —** `=AVERAGE(<driver N−2>:<driver N>)` using **historical annual
   values only** — the `N+1` seed is **excluded** from this average. This is the
   one place a multi-year average is a seed: a comparable-sales rate reverts toward
   its historical norm, and the build states that as its long-run rate rather than
   holding a guided or quarterly rate for five years.
5. **`N+3 … N+5` —** `= <driver N+2>` (flat).

**`New-Restaurant Productivity`** — driver every projection year; `N+1` = **0.85**
unless issuer guidance suggests otherwise; `N+2 … N+5` = `N+1` (flat). The 0.5
partial-year factor in the two new-restaurant rows is a constant in the formula, not
a driver.

**Franchise block (§3)** — per `../franchiseRevenueBuild/franchiseRevenueBuild.md`
§5: Mode A compounds the sales-linked streams off the projected franchised roll and
the franchise comp driver (latest-quarter recency seed where available); Mode B
seeds `Franchise Revenue YoY %` the default seed (guided, else the latest annual value), then flat.

**`Other Revenue`** — a share of modeled revenue, exactly as the revenue-per-restaurant
build's Section 3 lays it: the row beneath it, `Other Revenue — % of Modeled Revenue`, holds
the historical ratio of the plug to the named components and is the driver in
projection (red + dashed, the default seed then flat); `Other Revenue = that driver × the
named components`.

### Projection assembly (§2)

- §1 formula rows (`Average check`, `SSS`) drag as formulas in projection.
- Comparable / new-restaurant / annualization / closure bridge rows compute per §2.2.
- `Revenue from Restaurants` = sum of bridge rows.
- `Revenue per Restaurant` and `YoY %` remain **memo formulas** in projection.
- Location-build rows (`Company Openings`, `Company Closures`, `Net Franchise
  Transfers`, `Other`, EOP) remain **live references** to projected location drivers
  — no new unit drivers here.

### Checks (projection)

- [ ] Every non-driver projection cell is a live `=` formula.
- [ ] `N+1` recency seed documented when used; quarterly rate not annualized.
- [ ] `N+2` average excludes `N+1` quarterly seed.
- [ ] `components − Total (must = 0)` = 0 every projection year.
- [ ] Zero formula errors after `recalc.py`.

---

## Section 7 — Downstream handoff

After the revenue build is laid down, recalculated, and footed:

- Confirm **zero formula errors**.
- Confirm historical foot: components sum to reported Total Revenue every period.
- Confirm `SSS ≈ average check + guest traffic` reconciles to reported comp % in
  historical memo rows (when decomposition exists).
- Hand back to the restaurant router (`../restaurants.md`).
- Downstream **costs / margins** builds may reference `Revenue from Restaurants`
  and per-unit memos — keep row labels stable and universe explicit.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's comparable-sales-growth lines; the location roll-forward and all
non-revenue sections are owned by their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Company-Operated EOP Balance` for the brand (`coeop_<brand>`) | location build (`../locationBuild/`) | the restaurant router ran the location build (its Step 1) | none — return `ABORTED` |
| `Company Openings` and `Company Closures` (or `Company Net Closures (implied)`) for the brand, company-operated roll | location build | the location build ran (it lays both rows on every company roll) | none — return `ABORTED` |
| `Net Franchise Transfers` for the brand, company-operated roll | location build | the issuer discloses transfers between company and franchised units (the location build laid the row) | the term is omitted from `Closure & Transfer Impact` |
| `Other` for the brand, company-operated roll | location build | the roll's closures are an input (the location build laid the residual row) | the term is omitted from `Closure & Transfer Impact` |
