---
name: revenue-restaurants-other
description: >
  Catch-all (bare-bones) revenue build for restaurant companies in the
  operating-model workbook. Invoked by the restaurant router
  (`revenue/restaurants/restaurants.md`) as the DEFAULT route when the company
  reports neither a full comparable-store-sales set (→ comparableStoresBuild) nor
  the comp % / decomposition needed for a comparable-sales-growth build
  (→ comparableSalesGrowthBuild) nor the revenue + total location count needed
  for a revenue-per-restaurant build (→ revenuePerRestaurantBuild). This is the
  simplest revenue model: a revenue
  CAGR / growth build by reporting segment. Receives the resolved `company_id`,
  official company name, workbook path, and the shared KPI inventory; builds the
  revenue model beneath the `REVENUE` ALL-CAPS header by laying down one
  Revenue-from-segment line (plus its YoY growth) for EACH reporting segment the
  company discloses, then a Total Revenue line equal to the sum of the segments.
  Historical segment revenue comes from deepKPI inputs; projected periods grow
  each segment forward by its own growth driver (seeded by the default seed — the
  guided figure, else the latest year's change — then flat; a historical CAGR memo is
  informational). Pulls series via `search_kpis` from the shared inventory and
  segment structure via `get_company_segments`; format per
  ../../../../_common/revelata-excel-styling-rules.md (one row per series, derived
  cells as live formulas) EXCEPT for time scope (last 4 fiscal years), which this
  build overrides. Sections: §1 revenue by segment, §2 total revenue,
  §3 single-/no-segment handling, §4 worked example, §5 downstream handoff.
---

# revenue — restaurants — other / catch-all build (revenue CAGR by segment)

This is the **catch-all** restaurant revenue build — the **most bare-bones**
revenue model in the set. It is invoked by the restaurant router
(`../restaurants.md`) when the company is a restaurant but does **not** have the
KPIs required for either richer build:

- it lacks a full **comparable-store-sales** dataset (→ `comparableStoresBuild/`),
  **and**
- it lacks **comparable-store sales growth %** (or price / traffic decomposition)
  with revenue + location count (→ `comparableSalesGrowthBuild/`),
  **and**
- it does not give **revenue + total location count** in a form that supports a
  per-restaurant model (→ `revenuePerRestaurantBuild/`).

So this build falls back to the simplest thing that still produces a defensible
revenue line: a **revenue CAGR / growth model by reporting segment**. For each
segment the company discloses, lay down the segment's revenue and its
year-over-year growth; **Total Revenue is simply the sum of the segments**.

Unlike the other three restaurant builds, this build does **not** depend on the
location roll-forward and does **not** reference unit counts — it is driven purely
by reported revenue and a growth assumption.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, and the router's note that the company fell through to the catch-all
route.

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
  matches the sibling restaurant builds. (Keep at least the four years so a
  historical CAGR can be computed — see §1.1.)
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 4), then **extends every segment into the projection window** following the
  **Projections (forecast years)** section near the end of this file. Do not
  fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §1 the
> per-segment revenue build through §5 the downstream handoff, plus the
> **Projections (forecast years)** section near the end that extends the build into
> `N+1 … N+5` — are the implemented scope. Do not build or add any new information
> outside the sections present here.

---

## Revenue build — framework overview

This build turns each **reporting segment's revenue** into a small CAGR-driven
block and foots them to total revenue. The framework is deliberately minimal and
**repeats once per segment**:

```
  For EACH reporting segment:
      Revenue from <Segment>           (deepKPI input historicals; grown by its rate in projections)
        YoY %                   (historical = this ÷ prior − 1; projection = driver, the default seed then flat)
  …repeat for every segment…
  ─────────────────────────────────────────
  Total Revenue = Σ (Revenue from each segment)
```

**The master identity.** Total Revenue is the **sum of the segment revenue
lines** — there is no separate plug here (a one-segment company simply has one
segment line that equals total revenue). If the company reports a **consolidated
total** that does **not** equal the sum of its disclosed segments (because of
intersegment eliminations or an unallocated/corporate bucket), capture that
difference as **its own segment block** (e.g. `Corporate / Other`,
`Intersegment eliminations`) so the sum still ties to the reported total — see
§3.2. Either way:

> **Σ (Revenue from each segment) = Total Revenue**, exactly, every period.

**Build the lines in this order:**

1. **Section 1 — Revenue by Segment.** One two-row block (revenue + YoY growth)
   per reporting segment, with a small CAGR memo to anchor the forward growth.
2. **Section 2 — Total Revenue.** The sum of the segment revenue lines, with its
   own YoY growth and a foot-check against any reported consolidated total.

**Conventions that apply to all sections (read once):**

- **Annual columns.** Segment revenue and total revenue are reported annually.
  Use the **same four annual period columns** (Col E onward, oldest → newest). If
  the issuer also reports revenue quarterly and the workbook carries a quarterly
  block, the standard annual-then-quarterly column ordering from the styling rules
  applies.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (reported segment revenue, reported total revenue) are
  **input cells** (pale-green fill,
  dark-blue hyperlinked
  value linked to the filing). **Every other cell is a live `=` formula** (black
  font, no fill) — YoY growth rows, the CAGR memo, the segment sum, and the total.
  **Projected-period growth rates are drivers — red font + dashed-border cells**
  seeded per the **Projections (forecast years)** section near the end of this file
  (not pale-green deepKPI inputs). Never hardcode a computed number.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §1.3 and §2.2 — and
  in the `Units (Col D)` column of that section's formula table. Dollar rows show the
  placeholder `(USD in <scale>)`: the contract's Rule 2 supplies the scale, millions by
  default, thousands where the digit test puts a small filer. Three points are specific
  to this build:
  - **Every revenue row is money at one scale.** Each `Revenue from <Segment>` row,
    `Total Revenue`, the `Memo: sum vs. reported total` foot check, and any §3.2
    reconciling block (`Corporate / Other` or `Intersegment eliminations`, laid out
    exactly like a segment block) are `(USD in <scale>)` at the one Rule 2 scale.
    Revenue is a dollar figure — never round it.
  - **`YoY %` and `Memo: CAGR (window)` are bare `(%)`.** `YoY %` is the
    period-over-period change the contract's Rule 5 reserves the bare tag for, and the
    CAGR memo is the same change annualized over the historical window, so both take
    `(%)`; the tag is the same whether the cell is a historical formula or a projection
    driver. Each stores the decimal fraction (`0.074`, not `7.4`).
  - **`Total Revenue` carries the SUM-BAR.** It is the one total in this build: bold
    with a single thin top border across the data columns only, per
    `../../../../_common/revelata-excel-styling-rules.md`.
- **Reading the layout blocks (§1.3, §2.2).** Each row's annotation has two columns,
  left to right: the **Col D units tag in parentheses** — `(USD in <scale>)` means the
  contract's Rule 2 sets the money scale; every other tag is written as it goes in the
  cell — and the note in **square brackets**: `[deepKPI INPUT …]` for a pulled value,
  `[FORMULA …]` for a computed row, plus styling (`bold`, `italic`, `SUM-BAR`) and
  whether the row is a projection driver. The `REVENUE` header, segment headers and
  the `<Segment 2> …` repeat marker carry no tag.
- **Label / comment / spacing discipline (same as the sibling builds).** Col C labels
  are **plain descriptive text**; the operand recipe for each formula row goes in a
  **cell comment on the Col C label cell** (author `Revenue Build`), not in the visible
  label. Indentation, bold / border, and the one-blank-row-between-blocks rule follow
  `../../../../_common/revelata-excel-styling-rules.md` exactly.

The sub-sections below specify each component cell-by-cell. Build them in order;
do not add revenue lines outside this framework.

---

## Section 1 — Revenue by Segment

This section lays down, **for each reporting segment**, a two-row block: the
segment's revenue and its year-over-year growth. The blocks repeat — a company
with three segments gets three revenue lines and three YoY growth rows.

### 1.1 — The logic (revenue CAGR by segment)

```
  Revenue from <Segment>        = reported segment revenue (deepKPI input)        [historicals]
  YoY %                  = (this year's segment revenue ÷ prior year's) − 1
  Revenue from <Segment>        = <prior-year segment revenue> × (1 + YoY growth) [projection]
  Segment CAGR (memo)           = (latest historical ÷ earliest historical)^(1/n) − 1
```

- **Historicals:** pull each segment's reported revenue from deepKPI as an input.
- **Trend:** compute each segment's **year-over-year growth** in its own row, and
  a single **historical CAGR memo** across the window (n = number of year-over-year
  steps in the window — for a 4-year window, n = 3).
- **Project:** grow each segment forward by an **assumed growth rate** (a red-font +
  dashed-border **driver**, seeded per the **Projections (forecast years)** section).
  Each projected segment revenue = prior-year revenue × (1 + assumed growth). Because
  segments can grow at very different rates, **each segment carries its own growth
  assumption** — do not apply one company-wide rate to all of them.

**Why per segment, not one blended rate.** A company's mix can shift materially
(e.g. a fast-growing franchise-royalty segment alongside a flat company-restaurant
segment). Growing each segment on its own CAGR preserves that mix shift; the
segments meet only at the **dollar level** in the Total (Section 2), where summing
is always valid.

### 1.2 — Discovering the segments

Determine the company's reporting segments **before** laying down rows:

1. Call **`get_company_segments`** (and, if useful, `get_company_summary`) to read
   the registrant's reportable segments and operating structure.
2. Cross-check against the **shared KPI inventory** for the matching revenue
   series — segment names appear inside the KPI strings (e.g. `Revenue - <Segment>
   - Annual`, `<Segment> revenue - Annual`, `Net sales - <Segment> - Annual`).
   Pull each via `search_kpis` against the shared inventory (do **not** re-run
   `list_kpis`).
3. Use the segmentation the issuer **actually reports revenue on**. If the company
   reports revenue by more than one cut (e.g. by brand **and** by geography), pick
   the **primary reportable-segment** cut the 10-K uses for its segment footnote,
   and record the choice in `BUILD_LOG.md` (a series set chosen over a sibling;
   the segment rows show the result). Do not build the same revenue twice under
   two different cuts.
4. If the company reports **no** segment breakdown (a single consolidated revenue
   line), treat the whole company as **one segment** — see §3.1.

Record in `BUILD_LOG.md` which segmentation was used and how many segment blocks
will be built, so the basis is auditable, and the **segment map** with it
(`../../../SKILL.md`, "The segment map"): each segment block's name as the inventory's
segment series spell it and the key of its revenue row. No note row is laid on the sheet for this;
the segment rows show the cut.

### 1.3 — Per-segment block layout

For **each segment**, lay one block. All label text in Col C; period values Col E
onward (annual):

```
REVENUE                                                                      [ALL CAPS section header — bold, underlined, size 16]
<Segment>                                                                    [segment header: bold + underlined, indent 0]
    Revenue from <Segment>                                (USD in <scale>)   [deepKPI INPUT historicals; FORMULA in projections; bold]
      YoY %                                               (%)                [FORMULA = this col ÷ prior col − 1; italic; projection driver]
      Memo: CAGR (window)                                 (%)                [FORMULA, one cell; italic]
<Segment 2> …                                                                [repeat the block]
```

**Row-spacing rule (strict, mirrors the sibling builds):** within a segment's
block there are **zero blank rows** from `Revenue from <Segment>` through its
`Memo: CAGR (window)` row. **One** blank spacer row separates one segment's block
from the next. The `YoY %` and `Memo: CAGR (window)` rows sit **immediately**
beneath the segment revenue row (no blank row above them).

**Indentation / fonts / borders (per the styling rules):** the `REVENUE` section header
gets the build-section treatment (bold, underlined, size 16); each segment header is
bold + underlined at `Alignment(indent=0)`; the `Revenue from <Segment>` line is at
`Alignment(indent=1)` and **bold**; the `YoY %` and CAGR memo rows are at
`Alignment(indent=2)` and italic. Indent is the cell's real indent property — never
leading spaces. Number
formats follow each row's Col D tag (see "Number format and units" in the conventions
list above).

### 1.4 — The formulas (cell-by-cell, per segment)

Row labels are the **plain Col C text**. "Prior col" = the period column
immediately to the left.

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Segment>` | | `(USD in <scale>)` | historicals: deepKPI **input** (reported segment revenue; green, hyperlinked). Projection: `= <prior col 'Revenue from <Segment>'> × (1 + <this col 'YoY %'>)` | `"Reported segment revenue (input) in history; prior × (1 + growth) in projections."` |
| `YoY %` | | `(%)` | base col: blank/dash; historical: `= <this col> ÷ <prior col> − 1`; projection: **driver** — red font + dashed border, seeded per **Projections (forecast years)** | `"Segment revenue growth, YoY. Projection: driver seeded at the guided growth where the issuer gives one, else the latest historical YoY, then held flat (see Projections)."` |
| `Memo: CAGR (window)` | | `(%)` | one cell: `= (<latest historical Revenue from <Segment>> ÷ <earliest historical Revenue from <Segment>>)^(1/n) − 1`, where **n** = number of YoY steps in the historical window (e.g. 3 for 4 years) | `"Historical CAGR across the window = (last ÷ first)^(1/n) − 1; anchor for the forward growth assumption."` |

- The **only deepKPI input** in a segment block is the historical
  `Revenue from <Segment>` cells; `YoY %` (historical) and the CAGR memo are
  **black live formulas**; `YoY %` (projection) is a **driver** (red font + dashed
  border).
- The projected `Revenue from <Segment>` cell uses the **same compounding recipe**
  as the per-restaurant build (`prior × (1 + growth)`), so the line is internally
  consistent across history and projection.
- Do **not** round revenue (it is a dollar figure); the CAGR memo and YoY rows are
  percentages.

### 1.5 — Pre-delivery checklist (Revenue by Segment)

- [ ] The italic note beneath the `REVENUE` header states the **segmentation
      used** (reportable segments / geography / single segment) and the **segment
      count**, citing `get_company_segments`.
- [ ] **One two-row block per reporting segment** (revenue + `YoY %`), in a
      stable, stated order; a company with k segments has **k** revenue lines and
      **k** YoY rows.
- [ ] Historical `Revenue from <Segment>` cells are deepKPI **inputs** (pale-green,
      hyperlinked); no hardcoded historical numbers.
- [ ] Each `YoY %` row is a **live formula** in history and a projection **driver**
      (red font + dashed border, seeded per the **Projections** section) in any
      projected column; the base column is blank/dash.
- [ ] A `Memo: CAGR (window)` cell is present per segment and is a **live formula**
      `(last ÷ first)^(1/n) − 1` with the correct **n**.
- [ ] Forward growth assumptions are **per segment** (not one blended company-wide
      rate) and are justified (segment CAGR + guidance).
- [ ] Row-spacing, plain Col C labels, and formula-in-comment rules match the sibling
      builds; each row's number format follows its Col D tag.
- [ ] After recalculation (LibreOffice / `recalc.py`), there are **zero formula
      errors**.

---

## Section 2 — Total Revenue (sum of the segments)

`Total Revenue` is **the sum of the segment revenue lines** — that is the entire
identity of this build. It carries its own YoY growth and a foot-check against any
reported consolidated total.

### 2.1 — The logic

```
  Total Revenue        = Σ (Revenue from each segment)
  Total Revenue YoY %  = (this year's Total ÷ prior year's) − 1
```

In projected columns, `Total Revenue` remains the **sum of the (now grown)
segment lines** — never grown directly by a separate top-level rate, which would
double-count the segment growth.

### 2.2 — Layout and formula

```
Total Revenue                                             (USD in <scale>)   [FORMULA = Σ segment revenue rows; bold, SUM-BAR]
  YoY %                                                   (%)                [FORMULA = this col ÷ prior col − 1; italic]
  Memo: sum vs. reported total (must = 0)                 (USD in <scale>)   [FORMULA check; italic — only if a reported consolidated total exists]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Total Revenue` | | `(USD in <scale>)` | `= SUM(` each segment's `Revenue from <Segment>` `)` | `"Σ segment revenue. The grand-total foot."` |
| `YoY %` | | `(%)` | base col: blank/dash; else `= <this col> ÷ <prior col> − 1` | `"Total revenue growth, YoY."` |
| `Memo: sum vs. reported total (must = 0)` *(only if reported total available)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <Total Revenue (this build)> − <reported consolidated total revenue (deepKPI input)>` | `"Foot check: summed segments less reported consolidated total; must be 0 (add a Corporate/Other or eliminations segment if not)."` |

- `Total Revenue` gets the grand-total treatment (bold, SUM-BAR) and
  sits beneath the last segment block.
- If deepKPI exposes a **reported consolidated total revenue** series, pull it as
  an input **only** to feed the foot-check memo (it is not the driver — the driver
  is the segment sum). If the memo is **not 0**, the segments do not foot to the
  reported total — resolve via §3.2 before delivering.

### 2.3 — Pre-delivery checklist (Total Revenue)

- [ ] `Total Revenue` = `SUM` of the per-segment `Revenue from <Segment>` rows, a
      **live formula** (no hardcode), bold with the SUM-BAR.
- [ ] `Total Revenue` is **not** grown by a separate top-level rate in projections
      — it is always the sum of the grown segment lines.
- [ ] A `YoY %` row sits beneath it (formula; dash in the base column).
- [ ] If a reported consolidated total exists, the `sum vs. reported total` memo
      evaluates to **0** every period; any gap has been resolved by adding a
      `Corporate / Other` or `Intersegment eliminations` segment (§3.2).
- [ ] After recalculation, **zero formula errors**.

---

## Section 3 — Single-segment and reconciliation handling

### 3.1 — Single-segment / no segment disclosure

If the company reports **only one consolidated revenue line** (no segment
breakdown), build **one** segment block whose label is the company / sole
operating line (e.g. `Revenue from Restaurants`, or the registrant's single
reportable segment name). `Total Revenue` then equals that one line. The structure
is identical — one revenue row, one `YoY %` row, one CAGR memo — and Section 2's
sum trivially reduces to the single segment.

### 3.2 — When segments don't foot to the reported total

If the disclosed segments **sum to less (or more) than** the reported
consolidated total, the difference is almost always **intersegment eliminations**
or an **unallocated / corporate** revenue bucket. Capture it as **its own segment
block** so the identity still holds:

- Add a block labeled `Corporate / Other` or `Intersegment eliminations` (the
  latter is typically **negative**).
- Its historical values are the **plug** = reported consolidated total −
  Σ disclosed segments (a live formula referencing the reported-total input), so
  the build foots exactly. Project it flat or at a small rate as appropriate.
- This mirrors the **Other plug** philosophy of the sibling builds: an explicit,
  visible reconciling line rather than a silent gap.

### 3.3 — Pre-delivery checklist (reconciliation)

- [ ] Single-segment companies get **one** segment block; `Total Revenue` equals
      that line.
- [ ] If disclosed segments don't tie to the reported total, a `Corporate / Other`
      or `Intersegment eliminations` block is added as a **plug** so the sum foots.
- [ ] No revenue is **double-counted** (only one segmentation cut is built — §1.2).

---

## Section 4 — Worked example (illustrative)

A two-segment operator on a FY2022 (base) → FY2025 window. Figures illustrative
(the actual build pulls every historical from deepKPI and lets the formulas
compute growth, CAGR, and the total); $ thousands.

**Section 1 — segment revenue (deepKPI inputs in history):**

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Revenue from Company Restaurants | | `(USD in millions)` | 4,000 | 4,300 | 4,600 | 4,950 |
| YoY % | | `(%)` | — | +7.5% | +7.0% | +7.6% |
| Memo: CAGR (window) | | `(%)` | | | | **+7.4%** *(=(4,950 ÷ 4,000)^(1/3) − 1)* |
| Revenue from Franchising | | `(USD in millions)` | 90 | 102 | 116 | 132 |
| YoY % | | `(%)` | — | +13.3% | +13.7% | +13.8% |
| Memo: CAGR (window) | | `(%)` | | | | **+13.6%** *(=(132 ÷ 90)^(1/3) − 1)* |

**Section 2 — total (sum of segments):**

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| **Total Revenue** = Σ segments | | `(USD in millions)` | **4,090** | **4,402** | **4,716** | **5,082** |
| YoY % | | `(%)` | — | +7.6% | +7.1% | +7.8% |
| Memo: sum vs. reported total (=0) | | `(USD in millions)` | 0 | 0 | 0 | 0 |

**Projecting FY2026** (illustrative): grow each segment by its own driver, seeded to
its latest historical change — Company Restaurants +7.6% → 4,950 × 1.076 = 5,326.2;
Franchising +13.8% → 132 × 1.138 = 150.2; **Total Revenue = 5,326.2 + 150.2 =
5,476.4** (USD in millions; the sum of the grown segments, not a
separate top-level growth). Note the two segments grow at very different rates —
exactly why each carries its own driver.

---

## Projections (forecast years)

After the **historical** build above (Sections 1 – 4) is laid down, recalculated,
and footed (the §2 `sum vs. reported total (must = 0)` check passes), **extend every
segment into the projection window** before the downstream handoff (§5). The
projection window is the **five fiscal years after the last historical year**
(`N+1 … N+5`) per the **Model timeline** in `../../../SKILL.md` — do not redefine it
here. Add five more **annual** columns immediately to the right of the historical
block, continuing the same left → right, oldest → newest order; the build stays
**annual**. The whole build simply **drags across as formulas**; the only forward
assumptions are **one driver per segment**.

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
  styling flags exactly which cells are meant to be overwritten. The
  `Memo: CAGR (window)` row is an informational reference the modeler may also
  consider, never the seed (leave its projection cells blank — it is a single
  historical memo).

### Per segment — the only driver is `YoY %`

This build repeats one two-row block per reporting segment, and projects **every
segment identically**:

- **`Revenue from <Segment>`** — **historical unchanged** (reported deepKPI input).
  For **projection**: `= <prior column Revenue from <Segment>> × (1 + <YoY %, this
  column>)` — exactly the compounding recipe §1.4 already specifies.
- **`YoY %`** — the **driver** for the segment. Historically it is **derived**
  (`= this col ÷ prior col − 1`); in projection it **inverts** to the forward
  assumption (red/dashed; `N+1` = the default seed: the guided value, else the latest historical `YoY %` value; `N+2 … N+5` = `N+1`).
- **Repeat for every segment.** Each segment carries its **own independent** `YoY %`
  driver, seeded and styled the same way — never apply one company-wide rate to all
  segments (segments can grow at very different rates; this preserves the mix shift).

### Total Revenue (§2) — no new driver

- **`Total Revenue`** = `Σ` segment revenue rows — the **same formula** as the
  historical columns; drag it across. It is **never** grown by a separate top-level
  rate in projection (that would double-count the segment growth), so there is **no
  Total-level driver**.
- **`YoY %`** (total) = `= this col ÷ prior col − 1` — formula, drags across.
- **`Memo: sum vs. reported total (must = 0)`** is a **historical-only** check —
  there is no reported consolidated total for future years, so **leave its
  projection cells blank (dash)**.

### Reconciling block (§3.2 Corporate / Other / Intersegment eliminations) — exception

If a `Corporate / Other` or `Intersegment eliminations` block was added to make the
segments foot (§3.2), it is a **reconciling plug, not a disclosed segment**. Project
it the way §3.2 already prescribes — **held flat** (carry the last historical value
forward) or by an explicit modeler assumption — rather than mechanically seeding the default on a residual / often-negative line. If you express it via a `YoY %`
driver, style that driver red/dashed and default it to **0 %** (flat). This is the
analog of the `Other`-Revenue placeholder in the sibling builds.

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=`
  formula (no hardcoded numbers). The **only** seeded/typed cells are the per-segment
  `YoY %` drivers (and any reconciling-block driver).
- **Driver seeding.** Each segment's `YoY %` `N+1` = the default seed (the guided
  figure, else its latest historical `YoY %`) and `N+2 … N+5` = `N+1` — except a
  reconciling-block driver, which defaults to flat (`0 %`).
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors**.
- **Foot.** `Total Revenue` = `Σ` segments in every projection year (by
  construction).
- **Continuity at the boundary.** `N+1` `Revenue from <Segment>` compounds off `N`'s
  value for every segment — the projection joins the actuals with no gap or jump.

## Section 5 — What the revenue build produces for downstream sections

After Sections 1 – 2 are built, the workbook contains, for every period in the
window, a fully-footed revenue build beneath the `REVENUE` header: one
`Revenue from <Segment>` line (plus `YoY %` and a CAGR memo) per reporting
segment, and a `Total Revenue` line equal to their sum (with a `YoY %` and a
foot-check against any reported consolidated total). Every non-input cell is a
live formula, so any later change to a segment input or a forward growth
assumption propagates automatically into the total and keeps the foot intact.

Hand back to the restaurant router (`../restaurants.md`), which will continue with
any remaining REVENUE sub-sections or return to the parent revenue router.
Downstream operating-model sections (costs, consolidated financials) reference
`Total Revenue` and the segment lines directly.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's bare-bones per-segment CAGR lines; all non-revenue sections are
owned by their respective skills.*
