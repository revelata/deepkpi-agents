---
name: revenue-software-other
description: >
  Catch-all (bare-bones) revenue build for software / technology companies in the
  operating-model workbook. Invoked by the software router
  (`revenue/software/software.md`) as the DEFAULT route (Step 4, branch D) when the
  company qualifies for none of the richer software builds — it lacks Net Revenue
  Retention + total customer count + a recurring/subscription revenue line (→
  arrBuild), is not a booking-based business with total bookings + corresponding
  revenue (→ trBuild), and has no user count + revenue pair (→ arpuBuild). This is
  the simplest revenue model: a revenue CAGR / growth build by reported revenue
  stream. Receives the resolved `company_id`, official company name, workbook path,
  the shared KPI inventory, and the router's note that the company fell through to
  the catch-all route (and whether a customer roll forward was laid down above).
  Builds the revenue model beneath the `REVENUE` ALL-CAPS header by laying down one
  Revenue-from-stream line for EACH reported revenue stream the company discloses,
  a Total Revenue line that foots to reported total revenue, and a parallel
  YoY % block. Historical stream revenue comes from deepKPI inputs;
  projected periods grow each stream forward by its own YoY % driver
  (seeded by the default seed, then flat; the stream's historical CAGR is an informational memo).
  Pulls series via `search_kpis` from the shared inventory and revenue disaggregation
  via the filing + `get_company_segments`; format per
  ../../../../_common/revelata-excel-styling-rules.md and this file's own conventions
  block (four-column label system, one row per series, single-lined sum bars,
  derived cells as live formulas) EXCEPT for time scope (last 4 fiscal years), which
  this build overrides. Sections: §1 identify revenue streams,
  §2 revenue by stream, §3 YoY %, §4 single-/no-stream handling +
  reconciliation, §5 worked example, Projections, §6 downstream handoff.
---

# revenue — software — other / catch-all build (revenue CAGR by stream)

This is the **catch-all** software revenue build — the **most bare-bones** revenue
model in the software set. It is invoked by the software router
(`../software.md`) at its Step 4 hand-off (branch **D**) when the company is a
software / technology business but does **not** have the KPIs required for any
richer software build:

- it lacks the **ARR** trio (Net Revenue Retention **and** a total customer count
  **and** a recurring/subscription revenue line) (→ `arrBuild/`), **and**
- it is **not** a booking-based business with **total bookings + corresponding
  revenue** (→ `trBuild/`), **and**
- it has **no user count + revenue** pair to drive an ARPU model (→ `arpuBuild/`).

So this build falls back to the simplest thing that still produces a defensible
revenue line: a **revenue CAGR / growth model by reported revenue stream**. For each
revenue stream the company discloses (e.g. `Subscription`, `Services`, `License`,
`Hardware`, `Transaction`), lay down the stream's revenue and its period-over-period
change; **Total Revenue foots to the company's reported total revenue**.

Unlike the ARR / take-rate / ARPU builds, this build does **not** depend on
retention, bookings, ACV, or a user / customer count — it is driven purely by
reported revenue and a growth assumption per stream. If the router laid a
**customer roll forward** on the sheet above (the roll-forward gate is independent
of build type), this build simply writes the revenue lines **beneath** it and
references **nothing** from it.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, the router's note that the company fell through to the catch-all
route, and whether the customer roll forward ran (so this build knows what already
sits above its rows and does not duplicate it).

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and the
**Conventions** block in this file's framework overview, and build with the **xlsx**
skill. All conventions there apply here — the
**four-column label system** (Col A hidden deepKPI string, Col B hidden index, Col
C display label, Col D units tag, Col E onward data), **one row per distinct
series**, deepKPI-sourced values as **pale-green hyperlinked input
cells** (dark-blue value linked to the filing), and **every** total /
derived cell as a live `=` formula (never a hardcoded number) — **except** for the
**time scope**, which this build overrides per the "Time scope" section below.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped. If a
  customer roll forward sits above this build, use the **same four annual period
  columns** it used, so every revenue cell sits directly under the matching column.
  (Keep at least the four years so a historical CAGR can be computed — see §3.1.)
- **This build is ANNUAL.** Reported stream revenue is modeled on annual columns
  only (one per fiscal year, oldest → newest, left → right). Do **not** add
  quarterly columns.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 5), then **extends every stream into the projection window** following the
  **Projections (forecast years)** section near the end of this file. Do not
  fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §1 the
> revenue-stream identification through §6 the downstream handoff, plus the
> **Projections (forecast years)** section near the end that extends the build into
> `N+1 … N+5` — are the implemented scope. Do not build or add any new information
> outside the sections present here.

---

## Revenue build — framework overview

This build turns each **reported revenue stream** into a small CAGR-driven line and
foots the streams to the company's reported total revenue. The framework is
deliberately minimal and **repeats once per stream**. It is presented as a single
**consolidated revenue table** in two grouped blocks — a **Revenue** block (every
stream's dollar line, then `Total Revenue`) and a **YoY %** block
(every stream's growth, then the total's growth):

```
  Revenue                                                         (block header — label only)
    Revenue from <Stream 1>     (deepKPI input historicals; grown by its rate in projections)
    Revenue from <Stream 2>
    Revenue from <Stream 3>
    …repeat for every stream…
    Total Revenue = reported total (input) in history; Σ (streams) in projection

  YoY %                                            (block header — label only)
    Revenue from <Stream 1>     (historical = this ÷ prior − 1; projection = driver)
    Revenue from <Stream 2>
    Revenue from <Stream 3>
    …repeat for every stream…
    Total Revenue               (this ÷ prior − 1)
```

**The master identity.** Consolidated revenue is the **sum of the stream revenue
lines**, and it foots to the company's reported total revenue exactly. In the
**historical** columns `Total Revenue` is the **reported** deepKPI input (the
anchor); the streams (plus a residual `Other Revenue` line, if the disclosed streams
do not exhaust reported revenue) form an **exhaustive partition** of it, verified by
a foot-check memo. In the **projection** columns the inversion applies —
`Total Revenue` is written **directly as the sum** of the grown streams. Either way:

> **Σ (Revenue from each stream) = Total Revenue**, exactly, every period.

If the disclosed streams do **not** sum to reported total revenue (because one
reported line bundles several sub-streams, or a small stream is not separately
disaggregated), capture the difference as its **own residual stream block**
(`Other Revenue`) so the partition stays exhaustive — see §4.2. A single-stream
company simply has one stream line that equals total revenue (§4.1).

**Build the lines in this order:**

1. **Section 1 — Identify the revenue streams.** Read the filing's revenue
   disaggregation and the KPI inventory to decide, before any row is written,
   exactly which reported revenue streams the company discloses.
2. **Section 2 — Revenue by stream.** One dollar row per reported stream, then a
   `Total Revenue` line that foots to reported total revenue.
3. **Section 3 — YoY %.** One growth row per stream (plus a CAGR
   memo to anchor the forward assumption), then the total's growth.

**Conventions that apply to all sections (read once):**

- **Annual columns.** Stream revenue and total revenue are reported annually. Use
  the **same four annual period columns** (Col E onward, oldest → newest).
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (reported stream revenue, reported total revenue) are
  **input cells** (pale-green fill,
  dark-blue hyperlinked value
  linked to the filing). **Every other cell is a live `=` formula** (black font, no
  fill) — the `YoY %` rows, the CAGR memo, the residual `Other
  Revenue` line, the stream sum, and the projected stream values. **Projected-period
  growth rates are drivers — red font + dashed-border cells** seeded per the
  **Projections (forecast years)** section near the end of this file (not pale-green
  deepKPI inputs). Never hardcode a computed number.
- **Label / comment / spacing discipline.** Col C labels are **plain
  descriptive text**; the operand recipe for each formula row goes in a **cell
  comment on the Col C label cell** (author `Revenue Build`), not in the visible
  label. **Block headers are bold + underlined and indented once**
  (`Alignment(indent=1)` — the cell's real indent, never leading spaces); **each
  stream's value row sits one level deeper** (`indent=2`) and `Total Revenue` returns
  to the header's level, bold; **memos sit at the items' level and a trend row one
  level deeper than the line it belongs to** — the renderer sets every data row's
  indent from its kind (styling rules).
  Blocks are separated by **one blank spacer row**.
- **Border discipline (whole sheet).** **Never use a double-lined border anywhere.**
  Every subtotal / total row (`Total Revenue`) is marked with a **single-lined "sum
  bar"** — a thin top border applied **only across the data columns (Col E onward)**,
  never a double line and never a bottom border on the row above. Total rules never
  run through the label columns (Col A–D). Reserve the **font underline**
  (`Font(underline="single")`) for **block headers**; total rows are **bold only**
  (no label underline) — their total is conveyed by the single-lined sum bar across
  the data columns.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.2 and §3.2 — and
  in the `Units (Col D)` column of that section's formula table. Dollar rows show the
  placeholder `(USD in <scale>)`: the contract's Rule 2 supplies the scale, millions by
  default, thousands where the digit test puts a small filer. Two points are specific to
  this build:
  - **Every §2 row is money at one scale, the memo included.** Each `Revenue from
    <Stream>`, the `Other Revenue` residual, `Total Revenue` and `Memo: components −
    Total` take the one Rule 2 scale — the memo too, because a scale mismatch between
    the stream rows and the reported total is exactly what it exists to expose. `Total
    Revenue` carries the SUM-BAR named in its note. Revenue is a dollar figure — never
    round it.
  - **Every §3 row is bare `(%)`.** Each `YoY %` row is the period-over-
    period change the contract's Rule 5 reserves the bare tag for, whether the cell is a
    historical formula or a projection driver, and the `Memo: CAGR (window)` rows are
    the same change annualized over the historical window. Each stores the decimal
    fraction (`0.074`, not `7.4`). The block's `Total Revenue` change row keeps the
    SUM-BAR as the block's total line.
- **Reading the layout blocks (§2.2, §3.2).** Each row's annotation has two columns,
  left to right: the **Col D units tag in parentheses** — `(USD in <scale>)` means the
  contract's Rule 2 sets the money scale — and the note in **square brackets**: the
  row's real cell indent, then `deepKPI INPUT …` for a pulled value, `FORMULA …` for a
  computed row, the projection treatment, and styling (`bold`, `SUM-BAR`, `italic`). A
  row with a tag and no bracketed note repeats the row above it for the next stream. The
  `REVENUE` header and the block headers carry no tag.

The sub-sections below specify each component cell-by-cell. Build them in order; do
not add revenue lines outside this framework.

---

## Section 1 — Identify the revenue streams

This is the **first section** of the build and its foundation. Before any revenue
row is written, decide — from the filing and the KPI inventory — exactly which
reported revenue streams the company discloses and how they partition reported total
revenue.

### 1.1 — Read the filing to identify the streams

The revenue streams are **issuer-specific** and are disclosed in the income-
statement revenue disaggregation and the MD&A. Two things must be extracted before
any revenue row is written:

1. **Which reported revenue lines the company breaks total revenue into.** Common
   software labels: `Subscription`, `Recurring`, `SaaS`, `Cloud`, `License`
   (perpetual), `Software`, `Services`, `Professional services`, `Support and
   maintenance`, `Hardware`, `Transaction`, `Advertising`, `Other`. Read the
   revenue-recognition footnote and the "Disaggregation of revenue" table to see the
   cut the issuer actually reports revenue on.
2. **Whether the disclosed streams exhaust reported total revenue.** Sum the
   disclosed streams against reported total revenue for each historical year. Any
   remainder becomes a residual `Other Revenue` stream (§4.2) so the partition stays
   exhaustive.

**Workflow:**

1. Call **`get_company_segments`** (and, if useful, `get_company_summary`) to read
   the registrant's reportable structure, and pull the latest 10-K markdown via the
   **filing** skill (`list_sec_filing_markdowns` → `get_sec_filing_markdown`).
2. Search the markdown for the disaggregated revenue table (tokens: `Disaggregation
   of revenue`, `Revenue by type`, `Revenue by product`, `Subscription`, `License`,
   `Services`, and the revenue-recognition footnote). Read the surrounding paragraph
   to confirm the cut and the stream names.
3. Cross-check against the **shared KPI inventory** for the matching revenue series —
   stream names appear inside the KPI strings (e.g. `Revenue - <Stream> - Annual`,
   `<Stream> revenue - Annual`, `Net revenue - <Stream> - Annual`). Pull each via
   `search_kpis` against the shared inventory (do **not** re-run `list_kpis`), reading
   the `unit` field to confirm dollars.

### 1.2 — Choosing the revenue cut

Use the segmentation the issuer **actually reports revenue on**. Software companies
typically disaggregate revenue **by type / product** (subscription vs. services vs.
license, etc.); some report **reportable segments** instead. Pick the **primary
cut** the 10-K uses for its revenue disaggregation, and record the choice in
`BUILD_LOG.md` (the hand-back report carries the same); the segment rows show the
result. If the
company reports revenue on more than one cut (e.g. by product **and** by geography),
pick one — the primary revenue-disaggregation cut — and do **not** build the same
revenue twice under two different cuts.

If the company reports **no** breakdown (a single consolidated revenue line), treat
the whole company as **one stream** — see §4.1.

Record in `BUILD_LOG.md` **which cut was used** (revenue by type / reportable
segment / single stream), **how many stream blocks will be built**, and **whether an
`Other Revenue` residual is needed** to make the streams foot — citing the filing
year and `get_company_segments`, so the basis is auditable — and the **segment map**
with it (`../../../SKILL.md`, "The segment map"): when the cut is by reportable
segment, each stream's key under its segment's name; otherwise an empty map. No note row is laid on
the sheet for this; the stream rows show the cut.

### 1.3 — Pre-delivery checklist (stream identification)

- [ ] `BUILD_LOG.md` states the **revenue cut used**, the **stream count**, and
      whether an **`Other Revenue` residual** was added — citing the filing year. No
      note row sits beneath the `REVENUE` header.
- [ ] The disclosed streams were read from the filing's **disaggregation-of-revenue**
      table / revenue-recognition footnote, not assumed from the label alone.
- [ ] Each identified stream is present as its **own deepKPI series** in the shared
      inventory (confirmed via `search_kpis`, `unit` = dollars), or a sourcing gap is
      documented.
- [ ] Only **one** revenue cut is built (no double-count across type and geography).
- [ ] The disclosed streams (plus an `Other Revenue` residual if needed) **exhaust**
      reported total revenue in every historical year.

---

## Section 2 — Revenue by stream

This section lays down the **Revenue** block: one dollar row per reported revenue
stream, followed by the `Total Revenue` line that foots to reported total revenue.

### 2.1 — The logic (revenue CAGR by stream)

```
  Revenue from <Stream>   = reported stream revenue (deepKPI input)                 [historicals]
  Revenue from <Stream>   = <prior-year stream revenue> × (1 + YoY %) [projection]
  Total Revenue           = reported total revenue (deepKPI input)                  [historicals]
  Total Revenue           = Σ (Revenue from each stream)                            [projection]
```

- **Historicals:** pull each stream's reported revenue from deepKPI as an input;
  `Total Revenue` is the reported total revenue input (the anchor).
- **Project:** grow each stream forward by its own **YoY % driver**
  (a red-font + dashed-border assumption seeded per the **Projections** section).
  Each projected stream revenue = prior-year revenue × (1 + change); `Total Revenue`
  becomes the **sum** of the grown streams. Because streams can grow at very
  different rates, **each stream carries its own growth assumption** — do not apply
  one company-wide rate to all of them.

**Why per stream, not one blended rate.** A software company's mix can shift
materially (e.g. fast-growing subscription revenue alongside a flat or declining
perpetual-license line). Growing each stream on its own rate preserves that mix
shift; the streams meet only at the **dollar level** in `Total Revenue`, where
summing is always valid.

### 2.2 — Layout

All label text in Col C; period values Col E onward (annual):

```
REVENUE                                                                         [ALL CAPS section header — bold, underlined, size 16]

  Revenue                                                                       [indent once; bold + underlined block header — label only — no data]
    Revenue from <Stream 1>                                   (USD in <scale>)  [indent once; deepKPI INPUT historicals; projection: = prior col × (1 + YoY %)]
    Revenue from <Stream 2>                                   (USD in <scale>)  [indent once; …repeat per stream…]
    Revenue from <Stream 3>                                   (USD in <scale>)
    Other Revenue                                             (USD in <scale>)  [indent once; residual — only if streams don't exhaust; FORMULA historical = Total − Σ streams; projection: = its §3 ratio driver × Σ streams]
  Total Revenue                                               (USD in <scale>)  [indent once, bold; SUM-BAR; historical: deepKPI INPUT — reported total; projection: FORMULA = Σ streams]
    Memo: components − Total (must = 0)                       (USD in <scale>)  [indent twice; FORMULA check; 0 every period; italic]
```

**Row-spacing (strict):** zero blank rows from the `Revenue` block header through the
`Memo: components − Total` row. The stream rows sit immediately beneath the block
header; `Total Revenue` follows immediately after the last stream (or `Other
Revenue`) row; the foot-check memo sits immediately beneath `Total Revenue`. One
blank spacer row follows the block.

**Borders / fonts:** the `REVENUE` section header gets the build-section treatment
(bold, underlined, size 16); the `Revenue` block header is bold + underlined at indent
once; each `Revenue from <Stream>` line is a plain indent-once row (no bold, no sum bar
— a stream is a single reported figure, not a sum); `Total Revenue` is **bold** with a
**single-lined sum bar** (thin top border across the data columns, no double line, no
label underline). Every row carries its Col D units tag (see "Number format and units"
in the conventions above); the foot-check memo is italic.

### 2.3 — The formulas (cell-by-cell)

Row labels are the **plain Col C text**. "Prior col" = the period column immediately
to the left.

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Stream>` | | `(USD in <scale>)` | historicals: deepKPI **input** (reported stream revenue; green, hyperlinked). Projection: `= <prior col 'Revenue from <Stream>'> × (1 + <this col YoY %>)` | `"Reported stream revenue (input) in history; prior × (1 + YoY %) in projections."` |
| `Other Revenue` *(residual, only if streams don't exhaust)* | DATA_DEPENDENT | `(USD in <scale>)` | historical: `= <Total Revenue, this col> − SUM(<identified stream rows, this col>)`; projection: `= <Other Revenue — % of modeled revenue, this col> × SUM(<identified stream rows, this col>)` | `"Residual revenue = reported total − Σ identified streams. Makes the partition exhaustive. Projection: a share of modeled revenue, off the driver row beneath it."` |
| `Total Revenue` | | `(USD in <scale>)` | historical: deepKPI **input** — reported total revenue; **projection:** `= SUM(` each `Revenue from <Stream>` row `[+ Other Revenue]` `)` | `"Historical: reported total revenue (input, the anchor). Projection: Σ streams (never grown by a separate top-level rate)."` |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= SUM(<all stream rows [+ Other Revenue], this col>) − <Total Revenue, this col>` | `"Foot check: summed streams less reported total; must be 0 every period (add an Other Revenue residual if not)."` |

- The **only deepKPI inputs** in this block are the historical `Revenue from
  <Stream>` cells and the historical `Total Revenue` cells; `Other Revenue`
  (historical residual) and the foot-check memo are **black live formulas**.
- The projected `Revenue from <Stream>` cell uses the **compounding recipe** `prior ×
  (1 + YoY %)`, so the line is internally consistent across history and
  projection.
- In projection, `Total Revenue` is the **sum of the grown streams** — never grown
  directly by a separate top-level rate, which would double-count the stream growth.
- Do **not** round revenue (it is a dollar figure); the CAGR memo and YoY % rows are percentages.

### 2.4 — Pre-delivery checklist (Revenue by stream)

- [ ] **One dollar row per reported stream** (`Revenue from <Stream>`), in a stable,
      stated order; a company with k streams has **k** revenue lines.
- [ ] Historical `Revenue from <Stream>` cells are deepKPI **inputs** (pale-green,
      hyperlinked); no hardcoded historical numbers.
- [ ] `Total Revenue` is the **reported** deepKPI input in the historical columns
      (bold, single-lined sum bar on the data columns); in projection it is the
      **sum** of the grown streams (a formula), **not** grown by a separate top-level
      rate.
- [ ] If the disclosed streams don't exhaust reported total, an `Other Revenue`
      residual block is added as a **plug** so the sum foots (§4.2).
- [ ] The `components − Total (must = 0)` memo evaluates to **0** in every historical
      period after recalculation.
- [ ] After recalculation (LibreOffice / the xlsx skill's `recalc.py`), there are
      **zero formula errors**.

---

## Section 3 — YoY % (and the CAGR memo)

This section lays down the **YoY %** block — one growth row per
stream and the total's growth — plus a `Memo: CAGR (window)` per stream that anchors
the forward assumption. It sits directly beneath the Revenue block (§2).

### 3.1 — The logic

```
  YoY % (stream)  = (this year's stream revenue ÷ prior year's) − 1
  YoY % (total)   = (this year's Total Revenue ÷ prior year's) − 1
  Memo: CAGR (window)            = (latest historical ÷ earliest historical)^(1/n) − 1
```

- Compute each stream's **year-over-year change** in its own row, and the total's
  change in its own row.
- Compute a single **historical CAGR memo** per stream across the window (n = number
  of year-over-year steps — for a 4-year window, n = 3). This memo is informational:
  it anchors the modeler's judgment on the forward growth assumption, but the default
  projection **driver** is the default seed, then flat (see Projections).

### 3.2 — Layout

```
  YoY %                                                          [indent once; bold + underlined block header — label only — no data]
    Revenue from <Stream 1>                                   (%)               [indent once; FORMULA historical = this col ÷ prior col − 1; driver in projection]
    Revenue from <Stream 2>                                   (%)               [indent once; …repeat per stream…]
    Revenue from <Stream 3>                                   (%)
    Other Revenue — % of modeled revenue                      (% of modeled revenue)  [indent once; only if §2 has an Other Revenue line; FORMULA historical = Other Revenue ÷ Σ identified streams; DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]
  Total Revenue                                               (%)               [indent once, bold; NO sum bar — a growth rate is not a sum; FORMULA = this col ÷ prior col − 1]

  Memo: CAGR (window)                                                           [indent once; bold + underlined block header — label only]
    Revenue from <Stream 1>                                   (%)               [indent once; FORMULA, one cell in the last historical column]
    Revenue from <Stream 2>                                   (%)
    Revenue from <Stream 3>                                   (%)
```

**Row-spacing (strict):** zero blank rows within each block; one blank spacer row
between the Revenue block (§2), the YoY % block, and the CAGR memo
block. The stream change rows mirror the stream order used in §2 exactly.

**Borders / fonts:** each block header is bold + underlined at indent once; each stream
change row is a plain indent-once row; the total's change row is **bold** with a
**single-lined sum bar** across the data columns. Number formats follow each row's Col D
tag. The CAGR memo carries **one value cell per stream** in the last historical column
(leave its other cells blank).

### 3.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Stream>` *(under YoY %)* | | `(%)` | base col: blank/dash; historical: `= <Revenue from <Stream>, this col> ÷ <Revenue from <Stream>, prior col> − 1`; projection: **driver** — red font + dashed border, seeded per **Projections** | `"Stream revenue growth, year over year. Projection: driver seeded at the guided growth where the issuer gives one, else the latest historical value, then held flat (see Projections)."` |
| `Other Revenue — % of modeled revenue` *(in place of a growth row for the residual; only if §2 has one)* | | `(% of modeled revenue)` | historical: `= <Other Revenue, this col> ÷ SUM(<identified stream rows, this col>)` (every column, including the base column); projection: **driver** — red font + dashed border, seeded per **Projections** | `"The residual's share of the revenue the build models (Σ identified streams). Historical: a fit diagnostic — low single digits expected. Projection: driver, guided or else the latest year, then flat."` |
| `Total Revenue` *(under YoY %)* | | `(%)` | base col: blank/dash; else `= <Total Revenue, this col> ÷ <Total Revenue, prior col> − 1` | `"Total revenue growth, year over year."` |
| `Revenue from <Stream>` *(under Memo: CAGR (window))* | | `(%)` | one cell (last historical col): `= (<latest historical 'Revenue from <Stream>'> ÷ <earliest historical 'Revenue from <Stream>'>)^(1/n) − 1`, where **n** = number of year steps in the window (e.g. 3 for 4 years) | `"Historical CAGR across the window = (last ÷ first)^(1/n) − 1; informational anchor for the forward growth assumption."` |

- Historical `YoY %` rows and the CAGR memo are **black live
  formulas**; the projection `YoY %` cells are **drivers** (red font +
  dashed border).
- The base column of every `YoY %` row is blank/dash (no prior period
  to difference against).

### 3.4 — Pre-delivery checklist (YoY %)

- [ ] **One `YoY %` row per stream** (plus the residual's, if §2 has an
      `Other Revenue` line) and one for `Total Revenue`, in the same order as §2.
- [ ] Each stream / total change row is a **live formula** in history and (for the
      streams) a projection **driver** (red font + dashed border, seeded per the
      **Projections** section) in projected columns; the base column is blank/dash.
- [ ] A `Memo: CAGR (window)` cell is present per stream and is a **live formula**
      `(last ÷ first)^(1/n) − 1` with the correct **n**.
- [ ] Forward growth assumptions are **per stream** (not one blended company-wide
      rate) and are justified (stream CAGR + guidance).
- [ ] Each row's number format follows its Col D tag; row-spacing, plain Col C labels,
      and formula-in-comment rules follow this file's Conventions block.
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Single-stream and reconciliation handling

### 4.1 — Single-stream / no breakdown disclosure

If the company reports **only one consolidated revenue line** (no revenue
disaggregation), build **one** stream block whose label is the company's sole
revenue line (e.g. `Revenue from Software`, or the registrant's single reported
revenue caption). `Total Revenue` then equals that one line. The structure is
identical — one revenue row, one `YoY %` row, one CAGR memo — and
§2's sum trivially reduces to the single stream (the `components − Total` memo is
still 0).

### 4.2 — When streams don't foot to the reported total

If the disclosed streams **sum to less than** the reported total revenue (because a
small stream is not separately disaggregated, or several sub-streams are bundled),
capture the difference as **its own residual stream block** so the identity still
holds:

- Add a block labeled `Other Revenue`.
- Its historical values are the **plug** = reported total revenue − Σ disclosed
  streams (a live formula referencing the reported-total input), so the build foots
  exactly.
- Carry and project it like any other stream — a `YoY %` driver and
  `prior × (1 + change)` compounding (see Projections). It is an explicit, visible
  reconciling line rather than a silent gap.

### 4.3 — Pre-delivery checklist (reconciliation)

- [ ] Single-stream companies get **one** stream block; `Total Revenue` equals that
      line and the foot-check memo is 0.
- [ ] If disclosed streams don't tie to the reported total, an `Other Revenue` block
      is added as a **plug** so the streams foot (`components − Total` = 0).
- [ ] No revenue is **double-counted** (only one revenue cut is built — §1.2).

---

## Section 5 — Worked example (illustrative)

A two-stream software company on a FY2022 (base) → FY2025 window. Figures
illustrative (the actual build pulls every historical from deepKPI and lets the
formulas compute the change, CAGR, and the foot); **revenue in $ millions**.
Reported streams: `Subscription` and `Services`.

**Revenue block (deepKPI inputs in history; Total Revenue = reported input):**

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Revenue from Subscription | | `(USD in millions)` | 800 | 960 | 1,152 | 1,370 |
| Revenue from Services | | `(USD in millions)` | 120 | 130 | 138 | 145 |
| **Total Revenue** *(reported input)* | | `(USD in millions)` | **920** | **1,090** | **1,290** | **1,515** |
| Memo: components − Total (=0) | | `(USD in millions)` | 0 | 0 | 0 | 0 |

**YoY % block:**

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Revenue from Subscription | | `(%)` | — | +20.0% | +20.0% | +18.9% |
| Revenue from Services | | `(%)` | — | +8.3% | +6.2% | +5.1% |
| **Total Revenue** | | `(%)` | — | +18.5% | +18.3% | +17.4% |

**Memo: CAGR (window):** Subscription **+19.6%** *(=(1,370 ÷ 800)^(1/3) − 1)*;
Services **+6.5%** *(=(145 ÷ 120)^(1/3) − 1)*.

**Projecting FY2026** (illustrative): grow each stream by its own driver (seeded at its latest historical change; no guidance assumed) — Subscription ≈ +19.6% →
1,370 × 1.196 = 1,639; Services ≈ +6.5% → 145 × 1.065 = 154; **Total Revenue =
1,639 + 154 = 1,793** (the sum of the grown streams, not a separate top-level
growth). Note the two streams grow at very different rates — exactly why each carries
its own assumption.

---

## Projections (forecast years)

After the **historical** build above (Sections 1 – 5) is laid down, recalculated,
and footed (the §2 `components − Total (must = 0)` check passes), **extend every
stream into the projection window** before the downstream handoff (§6). The
projection window is the **five fiscal years after the last historical year**
(`N+1 … N+5`) per the **Model timeline** in `../../../SKILL.md` — do not redefine it
here. Add five more **annual** columns immediately to the right of the historical
block, continuing the same left → right, oldest → newest order; the build stays
**annual**. The whole build simply **drags across as formulas**; the only forward
assumptions are **one driver per stream**.

> This section is the **single source of truth** for projection styling and seeding.
> Projection **drivers** use the **red font + dashed-border** convention and the
> **default seed** (guided, else the latest year, then flat) methodology defined here. The `Memo: CAGR (window)` row
> stays only as an informational reference the modeler may also consider.

### Driver styling (applies to every projection driver below)

Mark **every** projection driver cell so it reads as a forward assumption — visually
distinct from both the formula cells and the historical deepKPI input cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **A dashed box on all four sides of each individual driver cell** (openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom` — one complete
  box **per cell**, applied **after** any shared row-border pass so a later border
  write cannot overwrite the box). Do **not** reduce it to a single bottom border.
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
  styling flags exactly which cells are meant to be overwritten. This **default seed** (guided, else the latest change) is the default; the `Memo: CAGR (window)` row stays only as an informational
  reference the modeler may also consider (leave its projection cells blank — it is a
  single historical memo).

### Per stream — the only driver is `YoY %`

This build repeats one stream line per reported revenue stream, and projects **every
stream identically**:

- **`Revenue from <Stream>`** — **historical unchanged** (reported deepKPI input).
  For **projection**: `= <prior column 'Revenue from <Stream>'> × (1 + <YoY %, this column>)` — exactly the compounding recipe §2.3 specifies.
- **`YoY %`** — the **driver** for the stream. Historically it is
  **derived** (`= this col ÷ prior col − 1`); in projection it **inverts** to the
  forward assumption (red/dashed; `N+1` = the default seed: the guided value, else the
  latest historical `YoY %` value; `N+2 … N+5` = `N+1`).
- **Repeat for every stream.** Each stream carries its **own independent**
  `YoY %` driver, seeded and styled the same way — never apply one
  company-wide rate to all streams (streams can grow at very different rates; this
  preserves the mix shift).

### Other Revenue residual (§4.2) — a ratio driver, not a growth driver

If an `Other Revenue` line was added to make the streams foot (§4.2), it is **no
longer a subtraction** in projection (that would be circular against `Total
Revenue`). It is projected as a **share of modeled revenue**: `= <Other Revenue — % of modeled revenue,
this col> × SUM(<identified stream rows, this col>)`, where that §3 row holds the
historical ratio and, in projection, the same default seed, then flat seed as every other
driver (red/dashed). The denominator excludes the residual itself, so there is no
circularity. Add one Notes line: `Revenue: in the forecast Other Revenue is a share
of modeled revenue, held at the latest ratio, rather than a plug.`

### Total Revenue — no new driver

- **`Total Revenue`** = `Σ` stream revenue rows `[+ Other Revenue]` — written
  **directly as the sum** in the projection columns (the inversion of its historical
  reported-input role). It is **never** grown by a separate top-level rate in
  projection (that would double-count the stream growth), so there is **no
  Total-level driver**.
- **`YoY %`** (total) = `= this col ÷ prior col − 1` — formula, drags
  across.
- **`Memo: components − Total (must = 0)`** evaluates to **0** in every projection
  year trivially (Total is defined as the sum), so leave it live and confirm it foots.

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=`
  formula (no hardcoded numbers). The **only** seeded/typed cells are the per-stream
  `YoY %` drivers (and the `Other Revenue` residual's
  `Other Revenue — % of modeled revenue`, if present).
- **Driver seeding.** Every driver's `N+1` = the default seed (the guided value where the guidance table names it, else the latest historical year) and `N+2 … N+5` = `N+1`, the residual's ratio driver included.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors** and **no circular references** (confirm the §4.2 residual is a share of
  modeled revenue rather than a subtraction in projection).
- **Foot.** `Total Revenue` = `Σ` streams in every projection year (by construction);
  the `components − Total (must = 0)` memo equals **0**.
- **Continuity at the boundary.** `N+1` `Revenue from <Stream>` compounds off `N`'s
  value for every stream — the projection joins the actuals with no gap or jump.

---

## Section 6 — What the revenue build produces for downstream sections

After Sections 1 – 5 are built, the workbook contains, for every period in the
window, a fully-footed revenue build beneath the `REVENUE` header: one
`Revenue from <Stream>` line per reported stream (plus a residual `Other Revenue`
line if needed), a `Total Revenue` line that foots to reported total revenue, a
parallel `YoY %` block, and a `Memo: CAGR (window)` per stream. Every
non-input cell is a live formula, so any later change to a stream input or a forward
growth assumption propagates automatically into the total and keeps the foot intact.

Report back to the software router (`../software.md`) in one line each: the **revenue
cut used** (by type / reportable segment / single stream) and the **stream count**,
the historical window used, and the **row addresses** of `Total Revenue` and each
`Revenue from <Stream>` line so downstream operating-model sections (costs,
consolidated financials) can reference them without re-deriving anything. The router
will continue with any remaining REVENUE sub-sections or return to the parent revenue
router.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's bare-bones per-stream CAGR lines; all non-revenue sections are
owned by their respective skills.*
