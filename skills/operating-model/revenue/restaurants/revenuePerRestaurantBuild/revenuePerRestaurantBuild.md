---
name: revenue-restaurants-revenue-per-restaurant
description: >
  Revenue-per-restaurant build for restaurant companies in the operating-model
  workbook. Invoked by the restaurant router
  (`revenue/restaurants/restaurants.md`) when the company does NOT report a full
  comparable-store-sales set but DOES report both total revenue and total
  location count — enough to drive the model off revenue per restaurant
  (revenue ÷ units). The unit-count roll-forward is laid down separately by
  `locationBuild/locationBuild.md` before this build runs, so this build is
  responsible only for the revenue lines and references the EOP counts already in
  the workbook. Receives the resolved `company_id`, official company name,
  workbook path, and the shared KPI inventory; builds the revenue model beneath
  the `REVENUE` ALL-CAPS header. The build decomposes reported total revenue into
  two modeled components plus a plug: Revenue from Restaurants (revenue per
  restaurant grown by its year-over-year rate, times the EOP restaurant count),
  Revenue from Franchises (laid by the shared `../franchiseRevenueBuild/` block —
  franchised units × franchise comp where the series exist, else its own YoY rate —
  only if franchise revenue is reported), and Other Revenue (the plug that foots the build to
  reported Total Revenue). Pulls series via `search_kpis` from the shared
  inventory; format per ../../../../_common/revelata-excel-styling-rules.md (one row
  per series, derived cells as live formulas) EXCEPT for time scope (last 4
  fiscal years), which this build overrides. For multi-brand parents, it runs the
  per-brand revenue build for each concept and then a consolidated revenue table.
  Sections: §1 revenue per restaurant, §2 franchise revenue, §3 other + total
  revenue, §4 multi-brand parents + consolidated table, §5 worked example, §6
  downstream handoff.
---

# revenue — restaurants — revenue-per-restaurant build

This is the **revenue-per-restaurant** restaurant revenue build. It is invoked by
the restaurant router (`../restaurants.md`) when the company **lacks** a full
comparable-store-sales dataset but reports both **total revenue** and **total
location count**, so the model is driven off **revenue per restaurant** (revenue
÷ units). It is the **mid-tier** revenue build — more granular than a top-down
growth rate, less granular than the comparable-stores build.

By the time control reaches this build, the **unit-count roll-forward has already
been laid down** in the workbook by `../locationBuild/locationBuild.md` (the
router invokes it before routing). **This makes the build relatively
straightforward:** the unit schedule is the hard part and it already exists.
This build is responsible only for the **revenue** lines and **references the EOP
counts already present** — it does not rebuild the unit roll-forward.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook (with the unit roll-forward already laid
down), the **shared KPI inventory** from the orchestrator, and the router's note
that **revenue and total location count** satisfied the revenue-per-restaurant
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
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped. This
  matches the location build and the comparable-stores build so the revenue lines
  sit directly under the matching unit counts.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 5), then **extends the entire revenue build into the projection window**
  following the **Projections (forecast years)** section near the end of this file.
  Do not fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §1 the
> revenue-per-restaurant bridge through §6 the downstream handoff, plus the
> **Projections (forecast years)** section near the end that extends the build into
> `N+1 … N+5` — are the implemented scope. Do not build or add any new information
> outside the sections present here.

---

## Revenue build — framework overview (Sections 1 – 3)

This build turns the **unit counts** already in the workbook into **revenue
dollars** and foots the build to the company's **reported total revenue**. It
follows one fixed framework so that every revenue-per-restaurant company is
modeled the same way and the workbook always foots.

**The components and the master identity.** The build decomposes reported total
revenue into two modeled components plus a plug:

```
  Revenue from Restaurants    (§1 — revenue per restaurant × EOP restaurant count; per brand, summed)
+ Revenue from Franchises     (§2 — consolidated; only if franchise revenue is reported)
+ Other Revenue               (§3 — plug)
─────────────────────────────────────────
= Total Revenue               (§3 — reported; the anchor / foot)
```

Because **Other Revenue is defined as the plug** (`Total − Restaurants −
Franchises`), the components **sum to reported Total Revenue exactly, by
construction** — that identity is the build's foot/check and must hold for every
brand-set and every period.

**Build the revenue lines in this order**, each beneath the unit roll-forward
that the location build laid down:

1. **Section 1 — Revenue from Restaurants.** Derive revenue per restaurant from
   history, trend it forward by a year-over-year rate, and multiply by the EOP
   restaurant count.
2. **Section 2 — Revenue from Franchises.** Laid by the shared block
   `../franchiseRevenueBuild/franchiseRevenueBuild.md` — **included only if the
   shared KPI inventory carries a franchise-revenue series** (the block's §1.1).
3. **Section 3 — Other Revenue and Total Revenue.** `Other Revenue` is the plug
   that ties the modeled components to reported total revenue; `Total Revenue` is
   the reported figure the plug closes to — the grand-total foot.

**Conventions that apply to all sections (read once):**

- **Annual columns.** Total revenue, franchise revenue, and the EOP unit counts
  this build references are reported annually. Use the **same four annual period
  columns** (Col E onward, oldest → newest) the location build uses, so every
  revenue cell sits directly under the matching unit-count cell. (If the issuer
  also reports total revenue quarterly and the workbook carries a quarterly
  block, the standard annual-then-quarterly column ordering from the styling
  rules applies.)
- **Per brand, then consolidate.** Restaurant revenue is built **one block per
  brand** — the same brand set, in the same order, as the location build's
  concept blocks — then summed into a consolidated subtotal. Franchise revenue
  and Other Revenue are **consolidated** lines (Sections 2 – 3).
- **Universe consistency.** Build each brand's revenue on the **same universe**
  (company-owned vs. total system) the location build used for that brand's unit
  counts. The EOP **count** this build multiplies and the **revenue** it divides
  by must be on the same basis (e.g. company-owned restaurant revenue ÷
  company-owned locations). Mixing universes silently corrupts every per-store
  figure.
- **Reference the location build — do not re-derive counts.** Every store count
  this build needs already exists in the workbook (the EOP balances / openings in
  the location roll-forward). Reference those cells with live `=` formulas; never
  hardcode a count or rebuild the unit schedule.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (reported total revenue, reported franchise revenue, and
  any base-year lookback) are **input cells** (pale-green fill,
  dark-blue hyperlinked value linked to the filing). **Every other
  revenue cell is a live `=` formula** (black font, no fill) — the per-restaurant
  figure, the grown estimate, the restaurant-revenue product, subtotals, the
  Other plug, and every YoY % row. Projected-period growth assumptions are
  **drivers** — **red font + dashed-border** cells seeded per the **Projections
  (forecast years)** section near the end of this file (not pale-green deepKPI
  inputs). Never hardcode a computed number.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §1.2, §3.2 and
  §4.1, and, for the franchise rows, the shared block's §2.2 / §3.1
  (`../franchiseRevenueBuild/franchiseRevenueBuild.md`) — and in the `Units (Col D)` column of that
  section's formula table. Dollar rows
  show the placeholder `(USD in <scale>)`: the contract's Rule 2 supplies the scale,
  millions by default, thousands where the digit test puts a small filer. Three
  classifications are specific to this build:
  - **The count row keeps the location build's tag; the per-unit noun is the label's.**
    `Company-Operated EOP Restaurant Count` is a live reference to the location build's
    `Company-Operated EOP Balance` for the brand and carries that row's `(locations)`. `Revenue per Restaurant` divides
    money in millions by that count and is tagged `(USD millions per restaurant)` — a
    per-unit tag takes the noun of its own row label ("per Restaurant" → per restaurant;
    the cost build's "per location" rows → per location; the comparable-stores build's
    "per Store" rows → per store), so a tag never contradicts the label beside it. A
    reader can divide the two rows above and land on the figure (§5: `4,600 ÷ 648 ≈
    7.10`). It is a dollar figure: never round it to whole units.
  - **The two `YoY %` rows are bare `(%)`.** `Revenue per Restaurant YoY %` and
    `Franchise Revenue YoY %` are period-over-period changes, the case the contract's
    Rule 5 reserves the bare tag for; the tag is the same whether the cell is a
    historical formula or a projection driver. Each stores the decimal fraction (`0.06`,
    not `6.0`).
  - **Everything else is money, and two rows carry the SUM-BAR.** `Restaurant Revenue`
    (the §1 numerator), `Revenue from Restaurants`, `Revenue from Franchises`, `Other
    Revenue`, `Total Revenue` and the foot memo are all money at the one Rule 2 scale.
    `Revenue from Restaurants — Total` and `Total Revenue` are totals: bold with a
    single thin top border across the data columns only, per
    `../../../../_common/revelata-excel-styling-rules.md`. `Revenue from Restaurants` in
    §1 is a product, not a total, and carries no bar.
- **Reading the layout blocks (§1.2, §3.2, §4.1, and the shared block's §2.2 /
  §3.1).** Each row's annotation has two
  columns, left to right: the **Col D units tag in parentheses** — `(USD in <scale>)`
  means the contract's Rule 2 sets the money scale; every other tag is written as it
  goes in the cell — and the note in **square brackets**: `[deepKPI INPUT …]` for a
  pulled value, `[FORMULA …]` for a computed row, `driver` for a projection assumption,
  plus styling (`SUM-BAR`, `italic`) and whether the row holds values in historical or
  projection columns only. Brand headers and the `Consolidated Revenue` header carry no
  tag.
- **Label / comment / spacing discipline (same as the cohort build).** Col C
  labels are **plain descriptive text**; the operand recipe for each formula row
  goes in a **cell comment on the Col C label cell** (author `Revenue Build`),
  not in the visible label. Indentation, bold / border, and the
  one-blank-row-between-blocks rule follow
  `../../../../_common/revelata-excel-styling-rules.md` exactly as the location
  build does.

The sub-sections below specify each component cell-by-cell. Build them in order;
do not add revenue lines outside this framework.

---

## Section 1 — Revenue from Restaurants (revenue per restaurant × units)

This is the analytical core of the build. It derives a **revenue-per-restaurant**
figure from history, projects it forward by a year-over-year growth rate, and
rebuilds restaurant revenue from the per-unit figure and the EOP unit count. It
is built **one block per brand**, directly beneath that brand's location
roll-forward, then summed into a consolidated restaurant-revenue subtotal (§4).

### 1.1 — The logic

```
  Revenue per Restaurant         = Restaurant Revenue ÷ Company-Operated EOP Restaurant Count [historicals]
  Revenue per Restaurant YoY %   = (this year's Rev/Restaurant ÷ prior year's) − 1
  Revenue per Restaurant         = <prior-year Rev/Restaurant> × (1 + YoY %)    [projection]
  Revenue from Restaurants       = Revenue per Restaurant × Company-Operated EOP Restaurant Count
```

- **Derive (historicals):** for each historical period, compute revenue per
  restaurant = revenue ÷ the **EOP** location count from the location build.
- **Trend:** compute the **year-over-year growth** of revenue per restaurant.
  This growth rate is the key driver to project forward — anchor the forward
  assumption on the historical trend, plus management guidance, pricing /
  inflation, and any traffic commentary.
- **Project:** grow revenue per restaurant forward by the assumed YoY growth,
  then multiply by the projected EOP restaurant count (from the location build)
  to rebuild **Revenue from Restaurants**.

**Rigor note — isolate restaurant revenue when other streams are material.**
Dividing *total* revenue by location count is clean only when restaurant sales
are essentially all of revenue. When the company also has **franchise revenue or
other revenue**, dividing *total* revenue by units contaminates the per-unit
metric and double-counts once franchise and Other are added back. The numerator
is therefore the **company-operated restaurant sales** figure, obtained in this
order — and **never defined through the §3 Other plug**, which is itself
`Total − Restaurants − Franchises` and so cannot be an input to Restaurants:

1. **The issuer reports a company restaurant sales line** (`Sales`,
   `Company sales`, `Restaurant sales`, `Sales by company-operated restaurants` —
   the face-of-statement line every franchisor presents beside its franchise
   lines): that line is the `Restaurant Revenue` deepKPI input. The common case.
2. **Restaurant sales are essentially all of revenue** (a company-owned operator
   with a single revenue line and no franchise series in the inventory): the
   reported `Total Revenue` is the input, and the Other plug (§3) carries only
   the modeling residual.
3. **The inventory carries franchise revenue but no separate company sales
   line**: `Restaurant Revenue` is a **live formula**,
   `= <Total Revenue> − <Revenue from Franchises>`, over the reported total and
   the row the shared franchise block lays in §2 (a forward reference the
   renderer resolves by key; the §2 gate is on the inventory, so the row will
   exist). The Other plug is then **zero by construction** and any non-restaurant
   other revenue sits inside the per-restaurant figure — say so in the cell
   comment and in one Notes line: `Revenue: restaurant revenue is total revenue
   less franchise revenue; any other revenue sits inside revenue per restaurant
   and the Other line is zero.` This is the default for that shape; it needs no
   question to the user.

State which numerator was used in the row's Col C comment (the issuer's caption)
and in one Notes line: `Revenue: revenue per restaurant divides <reported company
restaurant sales / total revenue> by company-operated restaurants.`

**Rigor note — EOP vs. average count.** This build uses **EOP** location count
(per the framework). Revenue is earned across the period, so EOP slightly
understates per-unit revenue in fast-expanding years; this is acceptable here
because the same EOP basis is used in the numerator-trend and the rebuild, so the
distortion largely cancels. (The comparable-stores build uses an average count
plus a 0.5 partial-year factor for new units; if you reconcile the two builds,
account for that definitional difference.)

### 1.2 — Layout and formula (cell-by-cell, per brand)

Lay the rows in this exact order beneath the brand's location block. Row labels
are plain Col C text; formula recipes go in Col C cell comments.

```
<Brand>                                                                           [brand header: bold + underlined, indent 0]
    Company-Operated EOP Restaurant Count           (locations)                   [FORMULA = ref to the location build's Company-Operated EOP Balance, this brand, same column]
    Restaurant Revenue                              (USD in <scale>)              [deepKPI INPUT — historical only; blank (dash) in projection columns]
    Revenue per Restaurant                          (USD millions per restaurant)  [FORMULA: historical = Restaurant Revenue ÷ count; projection = prior col × (1 + YoY %)]
    Revenue per Restaurant YoY %                    (%)                           [FORMULA = this col ÷ prior col − 1 in history; projection driver]
    Revenue from Restaurants                        (USD in <scale>)              [FORMULA = Revenue per Restaurant × Company-Operated EOP Restaurant Count]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Company-Operated EOP Restaurant Count` | | `(locations)` | `= <location build's Company-Operated EOP Balance for this brand, same column>` | `"EOP restaurant count — referenced from the location build, not re-entered"` |
| `Restaurant Revenue` | | `(USD in <scale>)` | deepKPI **input** — the company restaurant sales line (rigor note case 1), or total revenue when restaurant sales are essentially all of revenue (case 2); **or** the live formula `= <Total Revenue> − <Revenue from Franchises>` when franchise revenue exists but no company sales line is reported (case 3) | `"<Reported company restaurant sales | Reported total revenue (restaurant sales ≈ all of revenue) | Total revenue − franchise revenue (no company sales line reported; Other plug is 0 by construction)>, the per-restaurant numerator"` |
| `Revenue per Restaurant` | | `(USD millions per restaurant)` | historicals: `= <Restaurant Revenue> ÷ <Company-Operated EOP Restaurant Count>`; projection: `= <prior col Revenue per Restaurant> × (1 + <Revenue per Restaurant YoY %>)` | `"Rev/restaurant = revenue ÷ EOP count; projection compounds prior × (1 + YoY)"` |
| `Revenue per Restaurant YoY %` | | `(%)` | `= <this col Revenue per Restaurant> ÷ <prior col> − 1` (historical); projection **driver** — red font + dashed border, seeded per **Projections (forecast years)** | `"Rev/restaurant growth, YoY"` |
| `Revenue from Restaurants` | | `(USD in <scale>)` | `= <Revenue per Restaurant> × <Company-Operated EOP Restaurant Count>` | `"Rev/restaurant × EOP count; identical recipe in actuals and projections"` |

- **Time periods run across columns; each row is a single metric** (one row per
  series — do not split a metric into per-period rows).
- The `Company-Operated EOP Restaurant Count` row is a **live reference** to the location
  build; a single edit there flows through to revenue.
- `Restaurant Revenue` is the **only deepKPI input** in this section for historical
  columns (pale-green, hyperlinked); the `Revenue per Restaurant YoY %` becomes a
  projection **driver** (red font + dashed border) in projected columns; everything else
  is a **black live formula**.
- `Revenue from Restaurants` uses the **same `Rev/Restaurant × EOP count`
  recipe** in both historicals and projections, so the line is internally
  consistent.

### 1.3 — Pre-delivery checklist (Revenue from Restaurants)

- [ ] `Company-Operated EOP Restaurant Count` is a **live reference to the location build**,
      not re-entered or hardcoded; same brand and universe.
- [ ] `Restaurant Revenue` is the reported deepKPI input (pale-green, hyperlinked) for
      every historical column.
- [ ] `Revenue per Restaurant` is computed for every historical period and its
      **YoY growth trend is visible** in its own row.
- [ ] The forward `Revenue per Restaurant YoY %` is a projection **driver** (red
      font + dashed border, seeded per the **Projections** section) that is
      justified (trend, guidance, pricing / inflation), not an unexplained number.
- [ ] If franchise / other revenue is material, the per-unit numerator is
      **restaurant (company-owned) revenue only**, with the choice noted (rigor
      note §1.1).
- [ ] `Revenue from Restaurants = Revenue per Restaurant × EOP count` in every
      column, a live formula (no hardcodes).
- [ ] Numerator and denominator are on the **same universe**; units are
      consistent and labeled.
- [ ] After recalculation (LibreOffice / `recalc.py`), there are **zero formula
      errors**.

---

## Section 2 — Revenue from Franchises (if applicable)

**Include this section only if the shared KPI inventory carries a
franchise-revenue series** (the block's §1.1 gate). If none exists, **skip this
section entirely** (no empty rows). The location build's Franchised roll decides
the block's mode, not whether the block exists.

The franchise revenue lines are laid by the **shared franchise revenue block**,
`../franchiseRevenueBuild/franchiseRevenueBuild.md`. Read that file now (it is a
sibling import, permitted at this point) and follow it in full: its §1 decides
between **Mode A** (unit-and-comp — sales-linked streams projected as prior year ×
(1 + franchised unit growth) × (1 + franchise same-restaurant sales growth), with
unit growth referenced from the location build) and **Mode B** (the standalone
`Franchise Revenue YoY %` driver, used when the location build laid no Franchised
roll or no franchise comp series exists); its §2 / §3 give the layout, formulas and
checklist for the chosen mode; its §5 gives the projection seeds.

What this build relies on from the block: the two labels **`Revenue from
Franchises`** and **`Franchise Revenue YoY %`** are fixed; §3 below subtracts
`Revenue from Franchises` in its Other plug and §4 carries it in the consolidated
table. Franchise revenue is **never** derived from the §1 per-restaurant figure or
the company-owned units — it scales with the franchised system.

### 2.1 — Pre-delivery checklist (Franchise revenue)

- [ ] Section present **iff** the inventory carries a franchise-revenue series
      (block §1.1); otherwise omitted entirely (no empty rows).
- [ ] The block's §1 outcomes (mode, comp series and universe, stream
      classification, placement) are stated in one line each.
- [ ] The block's own checklist for the chosen mode (its §2.3 or §3.2) passes, and
      the labels `Revenue from Franchises` / `Franchise Revenue YoY %` are exact.

---

## Section 3 — Other Revenue and Total Revenue

This section closes the build: it adds the **Other Revenue** plug and foots to
**reported Total Revenue**.

### 3.1 — The logic

```
  Other Revenue = Total Revenue
                − Revenue from Restaurants
                − Revenue from Franchises
```

- **Total Revenue** is the **reported** deepKPI input (pale-green, hyperlinked) —
  the anchor the whole build foots to.
- **Other Revenue** is the **plug**: whatever reported total revenue is not
  explained by restaurant revenue and franchise revenue. It exists for the event
  where **Revenue from Restaurants + Franchise Revenue does not equal Total
  Revenue**, and captures gift-card breakage, licensing, supply-chain /
  distribution revenue, miscellaneous, and any modeling residual.
- A small, stable Other plug (a few % of revenue) signals a healthy build; a
  large or swinging plug means the restaurant or franchise line is off (often a
  universe mismatch in §1) — investigate before delivering (§3.3). If Other is
  large and a genuine, growing revenue stream, break it out with its own
  assumption rather than leaving it buried as a plug.

### 3.2 — Layout and formula (cell-by-cell)

```
Revenue from Restaurants — Total                    (USD in <scale>)              [FORMULA = SUM(per-brand Revenue from Restaurants rows); bold, SUM-BAR]
Revenue from Franchises                             (USD in <scale>)              [from §2, or omit if no franchise revenue is reported]
Other Revenue                                       (USD in <scale>)              [FORMULA plug = Total Revenue − Restaurants − Franchises in history; projection: = the ratio row beneath × (Restaurants + Franchises)]
  Other Revenue — % of modeled revenue              (% of modeled revenue)        [FORMULA historical = Other Revenue ÷ (Restaurants + Franchises); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]
Total Revenue                                       (USD in <scale>)              [deepKPI INPUT — reported anchor in history; projection: FORMULA = sum of the components; bold, SUM-BAR]
  Memo: components − Total (must = 0)               (USD in <scale>)              [FORMULA check; italic; 0 every period]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Revenue from Restaurants — Total` | | `(USD in <scale>)` | `= SUM(per-brand Revenue from Restaurants rows)` | `"Σ restaurant revenue across brands"` |
| `Revenue from Franchises` | DATA_DEPENDENT | `(USD in <scale>)` | the shared block's row (§2); when no franchise revenue is reported the row is **omitted** — no zero row — and the franchise term is dropped from the plug and the foot check below | the block's own comment |
| `Other Revenue` | | `(USD in <scale>)` | `= <Total Revenue> − <Revenue from Restaurants — Total> − <Revenue from Franchises>` (drop the franchise term when the row is omitted); projection: `= <Other Revenue — % of modeled revenue, this col> × (<Revenue from Restaurants — Total> + <Revenue from Franchises>)` | `"Plug = reported total − restaurants − franchises. Absorbs genuine other revenue AND the per-restaurant model residual. Projection: a share of modeled revenue, off the ratio row beneath."` |
| `Other Revenue — % of modeled revenue` *(driver row under the plug; visible)* | | `(% of modeled revenue)` | historical: `= <Other Revenue> ÷ (<Revenue from Restaurants — Total> + <Revenue from Franchises>)`; projection: **DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The plug's share of the revenue the build models (restaurants + franchises). Historical: a fit diagnostic — a few percent expected. Projection: driver, guided or else the latest year, then flat."` |
| `Total Revenue` | | `(USD in <scale>)` | deepKPI **input** (reported) | `"Reported total revenue — the anchor / foot"` |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= (<Revenue from Restaurants — Total> + <Revenue from Franchises> + <Other Revenue>) − <Total Revenue>` (drop the franchise term when the row is omitted) | `"Foot check: must equal 0 every period (Other is the plug)."` |

- Place `Other Revenue` directly above `Total Revenue` so the build reads as a
  clean stack and the foot is obvious.
- In projected columns, where `Total Revenue` is an **output** rather than a
  reported input, flip the assembly: `Other Revenue` becomes `Other Revenue — % of modeled revenue
  × (Restaurants + Franchises)`, with that ratio row the projection driver (red font +
  dashed border, the default seed — see **Projections (forecast
  years)**), and `Total Revenue = Revenue from Restaurants + Revenue from Franchises
  + Other Revenue`. Note in a comment which columns are reported-anchored
  vs. assembled.

### 3.3 — Pre-delivery checklist (Other + Total)

- [ ] `Total Revenue` is the reported deepKPI input (pale-green, hyperlinked) for
      historical columns.
- [ ] `Other Revenue` is the **plug** = Total − Restaurants − Franchises, a live
      formula.
- [ ] The components **sum to reported Total Revenue exactly** every historical
      period (the foot holds by construction).
- [ ] A `Memo: components − Total (must = 0)` foot-check row evaluates to **0** in
      every period after recalculation.
- [ ] Other Revenue is **small and stable** — its `Other Revenue — % of modeled revenue`
      row reads a few percent in every historical year. A large / swinging plug ⇒ investigate the restaurant (universe) or franchise
      lines; break out genuine streams.
- [ ] In projected columns the assembly is consistent (Total = Restaurants +
      Franchises + Other) and the reported-vs-assembled basis is noted.

---

## Section 4 — Multi-brand parents + consolidated revenue table

For a multi-brand parent, build the per-brand **Revenue from Restaurants** stack
(§1) **once per brand**, in the same brand order as the location build's concept
blocks, then a **consolidated revenue table** that sums the brands and adds the
consolidated franchise (§2) and Other / Total (§3) lines.

### 4.1 — Layout and formula

```
  <Brand A> — Revenue from Restaurants              (USD in <scale>)              [§1 block]
  <Brand B> — Revenue from Restaurants              (USD in <scale>)              [§1 block]
  …
  Consolidated Revenue                                                            [section sub-header: bold + underlined, size 12]
    Revenue from Restaurants — Total                (USD in <scale>)              [FORMULA = Σ brands; bold, SUM-BAR]
    Revenue from Franchises                         (USD in <scale>)              [§2, consolidated]
    Other Revenue                                   (USD in <scale>)              [§3 plug]
      Other Revenue — % of modeled revenue          (% of modeled revenue)        [§3 ratio driver]
    Total Revenue                                   (USD in <scale>)              [deepKPI INPUT — reported, the foot; bold, SUM-BAR]
```

- `Revenue from Restaurants — Total` is `= SUM(` the per-brand `Revenue from
  Restaurants` rows `)`.
- Franchise (§2) and Other / Total (§3) appear **once**, consolidated, beneath
  the per-brand restaurant blocks.
- Record in `BUILD_LOG.md` (the stage's hand-back report carries the same) the
  **segment map** of `../../../SKILL.md`, "The segment map": each brand's name as the
  inventory's segment series spell it and the key of its `Revenue from Restaurants`
  row; the cost build and the consolidated section read it for that brand's revenue.
- Single-brand operators need **no** separate consolidated table — the one
  brand's stack plus the franchise / Other / Total lines already foots.

### 4.2 — Pre-delivery checklist (multi-brand)

- [ ] One per-brand `Revenue from Restaurants` stack (§1) per brand, same order
      as the location build.
- [ ] Consolidated table sums the per-brand restaurant-revenue rows.
- [ ] Franchise (§2) and Other / Total (§3) appear **once**, consolidated.
- [ ] Consolidated `Total Revenue` ties to the reported consolidated figure.
- [ ] Single-brand operators: no separate consolidated table (the one brand's
      stack already foots).

---

## Section 5 — Worked example (illustrative)

A condensed end-to-end illustration for a single-brand, lightly-franchised
operator on the company-owned universe (figures illustrative — the actual build
pulls every input from deepKPI and lets the formulas compute the lines):

- **§1 revenue per restaurant:** reported restaurant revenue ≈ $4,600M ÷ EOP
  count 648 ⇒ Revenue per Restaurant ≈ **$7.10M**; prior year ≈ $6.70M ⇒
  Revenue per Restaurant YoY ≈ **+6.0%**. Revenue from Restaurants =
  $7.10M × 648 ≈ **$4,600M**.
- **§2 franchise:** reported franchise revenue ≈ **$24M**, growing ≈ +8% YoY.
- **§3 other + total:** with reported total ≈ $5,107M, Other = $5,107M − $4,600M −
  $24M ≈ **$483M** (other revenue streams — sanity-check the magnitude; if it is
  large, confirm the §1 numerator universe).

---

## Projections (forecast years)

After the **historical** build above (Sections 1 – 5) is laid down, recalculated,
and footed (the §3 `components − Total (must = 0)` check passes), **extend the
entire revenue build into the projection window** before the downstream handoff
(§6). The projection window is the **five fiscal years after the last historical
year** (`N+1 … N+5`) per the **Model timeline** in `../../../SKILL.md` — do not
redefine it here. Add five more **annual** columns immediately to the right of the
historical block, continuing the same left → right, oldest → newest order; the build
stays **annual**. The overwhelming majority of the build simply **drags across as
formulas**; only a small set of **drivers** per brand are entered as forward
assumptions.

> This section is the **single source of truth** for projection styling and seeding:
> projection **drivers** use the **red font + dashed-border** convention and the
> **default seed** (guided, else the latest year, then flat) methodology defined here.

### Driver styling (applies to every projection driver below)

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **Dashed box border on all four sides** of the cell (e.g. openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom`).
- **No pale-green fill and no hyperlink** — projection drivers are assumptions, not
  deepKPI-sourced actuals.
- **Exception to the "formulas are black" rule.** A projection driver keeps the red
  font + dashed border **even though its default value is a live formula** (the
  seeding formula below). The red/dashed treatment marks it as the intended override
  point; every **non-driver** projection cell keeps standard formula styling (black
  font, no fill, no dashed border) — identical to its historical styling, just
  dragged one column right.

### Driver value methodology (the default seed for every driver)

Unless a driver is called out as an exception below, seed each driver cell as:

- **First projection year (`N+1`)** — the **default seed** (`SKILL.md`, Build
  mechanics): the guided value where the orchestrator's guidance table names this
  driver for `N+1`; else the latest year on the issuer's normalized basis where the
  filing discloses one; else the **latest historical year** (`N`), which the renderer
  writes as a live `ISNUMBER`-guarded formula over `N`, `N−1`, `N−2` (0 when none is
  numeric). No year is averaged into the seed.
- **Each later projection year (`N+2 … N+5`)** — **equal to the `N+1` cell** (flat):
  `= <driver N+1 cell>`. This holds forward across all remaining projection years.
- The modeler may type a specific assumption over any driver cell; the red/dashed
  styling flags exactly which cells are meant to be overwritten. Every driver uses
  this seed, the `Other Revenue — % of modeled revenue` ratio driver included (see Part 3).

The three major parts of this build — **Revenue from Restaurants**, **Revenue from
Franchises / Licensing**, and the **Total Revenue (consolidated) build** — project as
follows, and **repeat per brand / segment** exactly as the historical sections do.

### Part 1 — Revenue from Restaurants (§1)

- **Location-count rows** (`Company-Operated EOP Restaurant Count`, etc.) were **already
  forecast in the location build**, so they carry **no driver here** — keep them as
  **live references up to the (now-projected) location roll-forward** and drag the
  reference across into the projection columns.
- **The restaurant-sales numerator row** — the `Restaurant Revenue` deepKPI input row of
  §1.2, the line that historically drives `Revenue per Restaurant` — is a
  **historical-only** input. Keep its historical cells exactly as the existing
  methodology sets them, and **leave every projection-year cell blank (dash)** — it is
  not projected.
- **`Revenue per Restaurant`** — **definition unchanged for historical** (= restaurant
  sales ÷ EOP location count). For **projection** columns it switches to compounding
  off the prior year: `= <prior column Revenue per Restaurant> × (1 + <Revenue per
  Restaurant YoY %, this column>)`. (Because the sales numerator is blank in
  projection, the historical ratio definition cannot be used; the line grows off its
  own prior value by the driver.)
- **`Revenue per Restaurant YoY %`** — the **driver** for this part. Historically it
  is **derived** (`= this col ÷ prior col − 1`); in projection it **inverts** to the
  forward assumption (red/dashed; `N+1` = the default seed: the guided value, else the
  latest historical `YoY %`; `N+2 … N+5` = `N+1`).
- **`Revenue from Restaurants`** — **formula unchanged** historical → projection:
  `= Revenue per Restaurant × Company-Operated EOP Restaurant Count` (the count now resolves to
  the projected location roll-forward).

(The inversion mirrors the other builds: historically `Revenue per Restaurant` is the
formula and the `YoY %` is derived from it; in projection the `YoY %` is the driver
and `Revenue per Restaurant` compounds off it.)

### Part 2 — Revenue from Franchises / Licensing (§2; only if franchise revenue is reported)

- Project the franchise block exactly as `../franchiseRevenueBuild/franchiseRevenueBuild.md`
  §5 specifies for the mode its §1 selected: in **Mode A** the sales-linked streams
  compound off franchised unit growth (the projected location roll) and the
  franchise comp driver (latest-quarter recency seed where available), and the
  non-sales streams off their own `— YoY %` drivers; in **Mode B**
  `Franchise Revenue YoY %` is the driver (default default seed, then flat seed) and
  `Revenue from Franchises` compounds off it.
- Apply this wherever the franchise / licensing revenue line lives: **per brand** if
  the issuer reports it per brand, otherwise **once** in the consolidated table (§4).

### Part 3 — Total Revenue (consolidated) build (§3 / §4)

- **`Revenue from Restaurants — Total`** (`= Σ` per-brand `Revenue from Restaurants`)
  — the **same formula** as the historical columns; drag it across.
- **`Revenue from Franchises`** (consolidated, if applicable) — **same** as Part 2;
  its projection value is whatever the shared franchise block (Part 2) produces.
- **`Other Revenue` — a share of modeled revenue.** Historically `Other Revenue` is
  the **plug** (`= Total − Restaurants − Franchises`). There is no reported total in
  the projection columns, so it cannot stay a plug, and it is never seeded to zero
  dollars (that would step projected revenue down at `N+1`). Its row beneath,
  `Other Revenue — % of modeled revenue`, holds the historical ratio of the plug to
  `Restaurants + Franchises` and, in projection, is the **driver** (red/dashed,
  the default seed then flat, like every other driver);
  `Other Revenue = that driver × (Restaurants + Franchises)`. The denominator
  excludes the plug itself, so there is no circularity.
- **`Total Revenue` — the foot.** The identity **`Restaurants + Franchises + Other =
  Total Revenue`** holds in **both** halves, so `Total Revenue` is always the
  foot/sum of its components and is **never a driver** (no red/dashed) in either half.
  The only thing that changes is *which* cell is the free input: historically `Total
  Revenue` is the **reported deepKPI input** and `Other` is the plug; in projection
  `Other` is driven off its ratio row, so `Total Revenue` is written **directly as the
  sum of the components**: `= Revenue from Restaurants — Total + Revenue from
  Franchises + Other Revenue` (drop the franchise term if no franchise revenue is reported). This is
  exactly the projected-column assembly §3.2 describes. The `components − Total (must
  = 0)` foot-check memo then evaluates to **0** in every projection year (trivially,
  since Total is defined as that sum).

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=`
  formula (no hardcoded numbers). The **only** seeded/typed cells are the drivers:
  per-brand `Revenue per Restaurant YoY %` (§1), `Franchise Revenue YoY %` (§2 / §4),
  and the consolidated `Other Revenue — % of modeled revenue`. The restaurant-sales
  numerator projection cells are **blank**.
- **Driver seeding.** Each driver's `N+1` = the default seed (the guided value where the guidance table names it, else the latest historical year) and `N+2 … N+5` = `N+1`, the ratio driver included.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors**.
- **Foot.** The `components − Total (must = 0)` memo equals **0** in every projection
  year.
- **Continuity at the boundary.** `N+1` `Revenue per Restaurant` compounds off `N`'s
  value; `N+1` `Revenue from Franchises` compounds off `N`'s value; `Revenue from
  Restaurants` uses the projected EOP count — the projection joins the actuals with
  no gap or jump.

---

## Section 6 — Downstream handoff

After the revenue build is laid down, recalculated, and footed to reported total
revenue:

- Confirm **zero formula errors** (LibreOffice / `recalc.py`).
- Confirm the **foot**: the modeled components (Revenue from Restaurants +
  Franchises + Other) sum to reported Total Revenue for every period.
- Hand back to the restaurant router (`../restaurants.md`), which will continue
  with any remaining REVENUE sub-sections or return to the parent revenue router.
- The downstream **costs / margins** builds may reference the revenue lines laid
  down here (e.g. restaurant-level margin = restaurant revenue − restaurant
  operating costs), so keep the row labels stable and the universe explicit.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's revenue-per-restaurant lines; the location roll-forward and all
non-revenue sections are owned by their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Company-Operated EOP Balance` for the brand (`coeop_<brand>`) | location build (`../locationBuild/`) | the restaurant router ran the location build | none — return `ABORTED` |
