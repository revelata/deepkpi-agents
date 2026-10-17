---
name: revenue-software-arr
description: >
  ARR revenue build for software / technology companies in the operating-model
  workbook. Invoked by the software router (`revenue/software/software.md`) after
  its Step 4 routing when the company reports a recurring-revenue franchise rich
  enough to drive an ARR model — Net Revenue Retention (or Net Dollar Retention),
  a total customer count, and a subscription / recurring revenue line. By the time
  this build runs, the shared KPI inventory is known and the customer roll-forward
  has already been laid down by `customerRollForward/customerRollForward.md`.
  Receives the resolved `company_id`, official company name, workbook path, the
  shared KPI inventory, the KPIs that satisfied the ARR criteria, and the row
  addresses of the customer roll-forward's `EOP` / `Net New Additions`. First
  isolates which revenue stream is truly recurring (subscription) and separates it
  from any non-recurring streams; only the recurring stream drives the ARR build,
  while non-recurring streams are projected on a YoY growth basis. Then builds an
  ARR roll forward (BOP ARR → Additional Spend from Existing Customers + Revenue
  from New Customers → EOP ARR) supported by an NRR-driven Additional-Spend build
  and an ACV-driven New-Customer-revenue build (both linking to the customer roll
  forward), plus the non-recurring streams, all collected into a consolidated
  revenue table that foots to reported total revenue. Pulls series via `search_kpis`
  from the shared inventory; format per ../../../../_common/revelata-excel-styling-rules.md
  (one row per series, derived cells as live formulas) EXCEPT for time scope (last
  4 fiscal years), which this build overrides. Sections: §1 isolate recurring
  revenue, §2 ARR roll forward, §3 Additional Spend from Existing Customers, §4
  Revenue from New Customers, §5 non-recurring revenue streams, §6 consolidated
  revenue + foot, §7 worked example, Projections, §8 downstream handoff.
---

# revenue — software — ARR build

This is the **ARR (annual recurring revenue)** software revenue build. It is
invoked by the software router (`../software.md`) at its Step 4 hand-off when the
company satisfied the ARR criteria — it reports **Net Revenue Retention** (or Net
Dollar Retention), a **total customer count**, and a **subscription / recurring
revenue** line.

By the time control reaches this build, three things are already established and
must **not** be re-litigated:

1. the company **is in the software / technology industry** (decided by the parent
   revenue router, `../../revenue.md`);
2. the company **qualifies for the ARR build** (decided by the software router's
   Step 2 criteria A); and
3. the **customer roll-forward has already been laid down** in the workbook by
   `../customerRollForward/customerRollForward.md` (the router runs it as a
   conditional pre-build before routing here). This build is therefore responsible
   only for the **revenue** lines of the ARR model and **references the customer
   counts already present** — it does not re-derive them.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook (with the customer roll-forward already laid
down), the **shared KPI inventory** from the orchestrator, the router's note of
which KPIs satisfied the ARR criteria (the NRR series, the customer-count series,
and the recurring-revenue series), and the **row addresses** of the customer
roll-forward's consolidated `EOP` and `Net New Additions` rows so this build can
reference them without re-deriving anything.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and build
with the **xlsx** skill. All conventions there apply here — the four-column label
system (Col A hidden deepKPI string, Col B hidden index, Col C display label, Col D
units tag, Col E onward data), one row per distinct series, deepKPI-sourced values
as pale-green hyperlinked input cells, and **every** total / derived cell as a live
`=` formula (never a hardcoded number) — **except** for the **time scope**, which
this build overrides per the "Time scope" section below.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped. Use
  the **same four annual period columns** the customer roll-forward used, so every
  ARR cell sits directly under the matching customer-count cell.
- **The ARR build is ANNUAL.** Recurring revenue, NRR, and the customer counts are
  modeled as an annual roll-forward, so this build uses **annual columns only**
  (one per fiscal year, oldest → newest, left → right), matching the customer
  roll-forward above it. Do **not** add quarterly columns.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 7), then **extends the entire ARR build into the projection window** following
  the **Projections (forecast years)** section near the end of this file. Do not
  fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §1 the
> recurring-revenue isolation and §2 – §8 the revenue build (ARR roll forward,
> Additional Spend from Existing Customers, Revenue from New Customers,
> non-recurring revenue streams, the consolidated revenue foot, a worked example,
> and the downstream handoff), plus the **Projections (forecast years)** section
> near the end that extends the build into `N+1 … N+5` — are the implemented scope.
> Do not build or add any new information outside the sections present here.

---

## Section 1 — Isolate the recurring (subscription) revenue stream

This is the **first section** of the ARR build and its analytical foundation. The
ARR roll forward may only be built on revenue that is **truly recurring** in
nature. Before any roll-forward row is written, you **must** decide, from the
filing and the KPI inventory, exactly which reported revenue stream is the
recurring one — and separate it from every non-recurring stream.

**Why this matters (STRICT).** If a company reports a subscription stream **and**
other revenue (services, hardware, professional services, licenses, transaction
fees, etc.), only the **recurring** stream may enter the ARR build. Feeding a
blended total-revenue figure into the ARR roll forward silently corrupts every
downstream figure: the NRR-driven Additional-Spend line, the ACV backsolve, and
the EOP ARR anchor all assume the dollars they operate on are recurring. Non-
recurring dollars do not retain, do not carry a per-customer ACV in the same way,
and must instead be projected separately (Section 5). The goal of this section is
that **the revenue used for the ARR build is genuinely recurring**, and everything
else is carved out and modeled on its own.

### 1.1 — Read the filing to identify the recurring stream

The recurring revenue stream is **issuer-specific** and is disclosed in the
income-statement revenue disaggregation and the MD&A. Two things must be extracted
before any ARR row is written:

1. **Which reported revenue line is recurring / subscription.** Common labels:
   `Subscription revenue`, `Recurring revenue`, `Subscription and support
   revenue`, `SaaS revenue`, `Platform subscription revenue`, `Cloud revenue`,
   `Software revenue`. It may **not** be literally labeled "subscription"; read
   the revenue-recognition footnote to confirm the stream is delivered on a
   subscription / term basis and **recurs** period to period.
2. **Which reported revenue lines are non-recurring.** Everything in reported
   total revenue that is **not** the recurring stream — e.g. `Professional
   services`, `Services and other`, `License revenue` (perpetual), `Hardware`,
   `Transaction revenue`, `One-time fees`. Each becomes a **non-recurring stream**
   in Section 5.

**Workflow:**

1. Pull the latest 10-K markdown via the **filing** skill
   (`list_sec_filing_markdowns` → `get_sec_filing_markdown`).
2. Search the markdown for the disaggregated revenue table (tokens: `Subscription`,
   `Recurring`, `Disaggregation of revenue`, `Revenue by type`, and the revenue-
   recognition footnote). Read the surrounding paragraph to confirm which stream(s)
   the issuer recognizes ratably / on a subscription basis.
3. Confirm each stream is present as its **own series** in the shared KPI inventory
   (via `search_kpis`), reading the `unit` field to confirm dollars. Record **which
   stream is the recurring one used for the ARR build** and **which streams are
   carved out as non-recurring** as one line in the workbook's Notes block, in the
   analyst's words: `Revenue: <stream> is the recurring stream rolled as ARR;
   <streams> are carried separately as non-recurring (FY<n> 10-K).` No note row is
   laid inside the block.

### 1.2 — Pure-play vs. mixed

Two cases result, and the whole build shape follows from which one applies:

- **Pure-play recurring (single stream).** The company's reported revenue **is**
  the recurring stream (or the non-recurring portion is immaterial and not
  separately reported). Then **EOP ARR = reported total revenue** and there are
  **no** non-recurring streams — Section 5 is omitted, and the Section 6
  consolidated table simply restates the ARR roll forward's EOP ARR as Total
  Revenue.
- **Mixed (recurring + non-recurring).** The company reports a recurring stream
  **and** one or more other streams. Only the recurring stream enters the ARR
  build (§2 – §4); each other stream is a **non-recurring stream** (§5) projected
  on a YoY basis; the consolidated table (§6) sums them and foots to reported total
  revenue.

Record which case applies in `BUILD_LOG.md` (the stage's hand-back report carries
the same); the rows themselves show it, and the Notes line from §1.1 names the
streams without the case name. Do **not** default to pure-play because it is
simpler — if a distinct non-recurring stream is reported, it must be carved out.
Record there as well the **segment map** (`../../../SKILL.md`, "The segment map"): the
keys of the stream rows that make up each issuer segment's revenue, or an empty map
when the streams do not follow the segment disclosure.

### 1.3 — "ARR" here means the reported recurring revenue stream

This build uses **the reported recurring (subscription) revenue P&L line** as the
ARR anchor — `EOP ARR` for a year is that year's **reported recurring revenue**,
and `BOP ARR` is the **prior year's** recurring revenue. Anchoring on the P&L
recurring line (rather than a point-in-time ARR snapshot) is deliberate: it keeps
the ARR build tied to the income statement and lets the consolidated table (§6)
foot to reported total revenue exactly.

If the issuer **also** reports a distinct point-in-time **ARR metric** (an
annualized run-rate as of period end), carry it as an optional **memo row** and
cross-check it against `EOP ARR`, but **do not** substitute it for the recurring
revenue line that anchors this build. Where the gap is material, add one Notes
line rather than reconciling it away: `Revenue: the issuer's reported ARR is a
point-in-time run rate; the model's ARR is the year's recurring revenue, so the two
differ.`

### 1.4 — Pre-delivery checklist (recurring-revenue isolation)

- [ ] One Notes line states **which reported stream is recurring** (used for the
      ARR build) and **which streams are carried separately as non-recurring**,
      citing the filing year, in the analyst's words (§1.1); no note row sits
      inside the block.
- [ ] The recurring stream is confirmed **recurring in nature** from the revenue-
      recognition footnote — not assumed from the label alone.
- [ ] The **pure-play vs. mixed** decision is recorded in `BUILD_LOG.md`. Pure-play ⇒ no §5 streams,
      EOP ARR = reported total revenue. Mixed ⇒ each non-recurring stream is
      identified for §5.
- [ ] Each identified stream (recurring and non-recurring) is present as its own
      deepKPI series in the shared inventory (confirmed via `search_kpis`, `unit` =
      dollars), or a sourcing gap is documented.
- [ ] No blended total-revenue figure is used as the ARR anchor when a distinct
      non-recurring stream exists.

---

## Revenue build — framework overview (Sections 2 – 6)

Section 1 isolated the **recurring revenue** stream. Sections 2 – 6 turn that
stream into an **ARR roll forward** driven by retention and new-customer economics,
model the **non-recurring** streams alongside it, and foot the whole build to the
company's **reported total revenue**. The build follows one fixed framework so that
**every** ARR-build company is modeled the same way and the workbook always foots.

**The master identity.** The recurring stream is decomposed by a roll forward, and
the consolidated revenue is the sum of the recurring stream and the non-recurring
streams:

```
  EOP ARR = BOP ARR + Additional Spend from Existing Customers + Revenue from New Customers   (Section 2 roll forward)

  Total Revenue = EOP ARR + Non-Recurring Stream 1 + Non-Recurring Stream 2 + … [+ Other]     (Section 6 foot)
```

The roll forward foots **by construction** because, in the historical columns,
`Revenue from New Customers` is defined as the **plug** (`EOP ARR − BOP ARR −
Additional Spend`). The consolidated table foots to reported total revenue because
the non-recurring streams (plus a residual `Other Revenue` line, if the identified
streams do not exhaust the non-recurring remainder) form an **exhaustive partition**
of `Total Revenue − EOP ARR` (see §5 / §6).

**Build the revenue lines in this order**, each beneath the customer roll-forward
that the router laid down:

1. **Section 2 — ARR Roll Forward.** `BOP ARR` → `Change from:` (`Additional Spend
   from Existing Customers`, `Revenue from New Customers`) → `EOP ARR`. This is the
   consolidated recurring-revenue roll-forward; its two `Change from:` lines
   reference the supporting builds below it.
2. **Section 3 — Additional Spend from Existing Customers.** An NRR-driven build:
   `BOP ARR × (NRR − 1)`. Its result feeds the §2 `Change from:` line.
3. **Section 4 — Revenue from New Customers.** A New-Customer-count × Average-ACV
   build linked to the customer roll-forward. Its result feeds the §2 `Change from:`
   line (in projection) / receives the §2 plug (in history).
4. **Section 5 — Non-Recurring Revenue Streams.** Each carved-out stream with a YoY
   growth memo — omitted entirely for a pure-play recurring company.
5. **Section 6 — Consolidated Revenue.** Sums `EOP ARR` + the non-recurring streams
   (+ residual `Other Revenue` if needed) and foots to reported `Total Revenue`.

**Conventions that apply to all of Sections 2 – 6 (read once):**

- **Annual columns only**, the same four the customer roll-forward uses.
- **Reference the customer roll-forward — do not re-derive counts.** The customer
  counts this build needs already exist in the workbook (the router laid them down):
  the consolidated `EOP` and, crucially, the consolidated `Net New Additions` (the
  count of net new customers per year). Reference those cells with live `=`
  formulas; never hardcode a count.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (reported recurring revenue, reported NRR, the reported
  non-recurring streams, reported total revenue, and the base-year BOP seed) are
  **input cells** (pale-green fill,
  dark-blue hyperlinked value
  linked to the filing). **Every other cell is a live `=` formula** (black font, no
  fill) — the BOP chain, the Additional-Spend product, the New-Customer-revenue
  plug / product, the ACV backsolve, every `YoY %` row, the consolidated sums, and
  the foot check. Never hardcode a computed number.
- **Label / comment / spacing discipline.** Col C labels are **plain descriptive
  text**; the operand recipe for each formula row goes in a **cell comment on the
  Col C label cell** (author `ARR Build`), not in the visible label. **Block headers
  are bold + underlined and indented once** (`Alignment(indent=1)` — the cell's real
  indent, never leading spaces); **main line items sit one level deeper** (`indent=2`), and a
  block's total (`EOP ARR`, `Total Revenue`) returns to `indent=1`, bold; **the rows
  under `Change from:` sit one level deeper than that label, memos at the items' level,
  a trend row one level deeper than the line it belongs to** — the renderer sets every
  data row's indent from its kind (styling rules). Blocks are separated by **one blank
  spacer row**.
- **Border discipline (whole sheet).** **Never use a double-lined border anywhere.**
  Every subtotal / total row (e.g. `EOP ARR`, each block's result row, `Total
  Revenue`) is marked with a **single-lined "sum bar"** — a thin top border applied
  **only across the data columns (Col E onward)**, never a double line and never a
  bottom border on the row above. Total rules never run through the label columns
  (Col A–D). Reserve the **font underline** (`Font(underline="single")`) for **block
  / section headers**; total rows are **bold only** (no label underline) — their
  total is conveyed by the single-lined sum bar across the data columns.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.3, §3.2, §4.3,
  §5.2 and §6.2 — and in the `Units (Col D)` column of that section's formula table.
  Dollar rows show the placeholder `(USD in <scale>)`: the contract's Rule 2 supplies
  the scale, millions by default, thousands where the digit test puts a small filer.
  Three classifications are specific to this build:
  - **`Average ACV` is `(USD thousands per customer)`, a declared coherence departure,
    and the customer count stays in ones.** ACV is conventionally quoted in thousands of
    dollars per customer, so the row displays that way. `Average ACV` divides `Revenue
    from New Customers` (millions) by `Total New Customers`; for the three rows to
    reconcile on the page the count would have to display in thousands, and a company
    that adds hundreds or low thousands of customers a year then reads `1.2` — unusable.
    So keep `Total New Customers` tagged `(customers)` in ones, keep ACV in thousands,
    and record the departure in the ACV row's Col C comment per the contract's Rule 2
    (the §7 example: `168 ÷ 380 = 0.442` million, shown as `442.1`). Only where the
    digit test itself puts the new-customer count in thousands does `(customers, in
    thousands)` become the readable choice, and then the three rows reconcile without a
    departure.
  - **Percent rows name their denominator.** `Net Revenue Retention (NRR)` divides
    retained spend by the opening book and is tagged `(% of BOP ARR)`; `Memo: recurring
    mix` is `(% of total revenue)`; every `YoY %` row is the bare `(%)`
    the contract's Rule 5 reserves for a period change, whether the cell is a historical
    formula or a projection driver.
  - **Everything else is money at one scale, memos included.** `BOP ARR`, the two
    `Change from:` lines, `EOP ARR`, `Reported ARR (memo)`, every non-recurring stream,
    the `Other Revenue` residual, `Revenue from <Stream>`, `Total Revenue` and `Memo:
    components − Total` all take the one Rule 2 scale — the memos too, because a scale
    mismatch between a modeled row and its comparator is exactly what a memo exists to
    expose. The four totals (`EOP ARR`, `Additional Spend from Existing Customers`,
    `Revenue from New Customers`, `Total Revenue`) carry the SUM-BAR named in their
    notes.
- **Reading the layout blocks (§2.3, §3.2, §4.3, §5.2, §6.2).** Each row's annotation
  has two columns, left to right: the **Col D units tag in parentheses** — `(USD in
  <scale>)` means the contract's Rule 2 sets the money scale; every other tag is written
  as it goes in the cell — and the note in **square brackets**: the row's real cell
  indent, then `deepKPI INPUT …` for a pulled value, `FORMULA …` for a computed row, the
  projection treatment, and styling (`bold`, `SUM-BAR`, `italic`). Block headers, stream
  header rows and the `Change from:` label row carry no tag.

The sub-sections below specify each component cell-by-cell. Build them in order; do
not add revenue lines outside this framework.

---

## Section 2 — ARR Roll Forward

This section is the **consolidated recurring-revenue roll-forward**. It reads
top-to-bottom as the master identity `EOP ARR = BOP ARR + Additional Spend from
Existing Customers + Revenue from New Customers`, with the two change lines gathered
under a `Change from:` bridge (exactly the Layout-B pattern the customer
roll-forward uses). It sits **directly beneath** the customer roll-forward.

### 2.1 — The roll-forward and its identity

For each period N, the ARR roll forward is built from these rows:

1. **BOP ARR** — the recurring revenue the **prior** period produced (see the
   base-year seed below).
2. **Change from:** — a bold, underlined label-only row (no values in any period
   column), heading the two change lines:
   - **Additional Spend from Existing Customers** = this period's result from the
     Section 3 build (`= §3 Additional Spend row, this col`).
   - **Revenue from New Customers** = **historical:** the roll-forward **plug**
     `EOP ARR − BOP ARR − Additional Spend from Existing Customers`; **projection:**
     this period's result from the Section 4 build (`= §4 Revenue from New Customers
     row, this col`). (The direction of this link inverts at the historical /
     projection boundary — see the Projections section.)
3. **EOP ARR** — **historical:** the **reported recurring revenue** (deepKPI input);
   **projection:** the formula `BOP ARR + Additional Spend from Existing Customers +
   Revenue from New Customers`.

Because, in the historical columns, `Revenue from New Customers` is the plug and
`EOP ARR` is the reported input, the identity holds **exactly** every historical
year by construction. In the projection columns the inversion holds it exactly too
(`EOP ARR` is defined as the sum).

### 2.2 — Base-year (leftmost column) BOP seed — recurring dollars only (STRICT)

Unlike the customer roll-forward (whose base-year BOP is blank), the ARR roll
forward **needs a BOP in the base year**, because both the Additional-Spend line
(`BOP × (NRR − 1)`) and the New-Customer plug (`EOP − BOP − Additional Spend`)
depend on it. Seed it as:

- **BOP ARR (base column)** = the **prior fiscal year's reported recurring
  revenue** — the recurring stream's value for the fiscal year immediately **before**
  the build window (e.g. for a FY2022–FY2025 window, pull FY2021 recurring revenue).
  Style it as a deepKPI **input** (green fill, dark-blue hyperlinked value linked to
  that year's filing).
  > **FORBIDDEN:** seeding base-column `BOP ARR` with the prior year's **total /
  > blended** revenue when a distinct non-recurring stream exists. That mixes
  > non-recurring dollars into the ARR base and corrupts the retention and ACV math
  > (the same conflation §1 exists to prevent). Use the **recurring** stream's prior-
  > year value only.

For **every non-base column**, `BOP ARR` is a **live formula** = the prior column's
`EOP ARR` (chain left → right, `=<prevCol><EOP ARR row>`). No new input.

### 2.3 — Layout

```
  ARR Roll Forward                                                                  [indent 1; bold + underlined block header]
    BOP ARR                                             (USD in <scale>)              [indent 2; base col: deepKPI INPUT — prior-FY recurring revenue; else FORMULA = prior col EOP ARR]
    Change from:                                                                      [indent 2; bold + underlined label-only row — no data]
      Additional Spend from Existing Customers          (USD in <scale>)              [indent 3; FORMULA = §3 Additional Spend result, this col]
      Revenue from New Customers                        (USD in <scale>)              [indent 3; historical: FORMULA plug = EOP ARR − BOP ARR − Additional Spend; projection: FORMULA = §4 result]
  EOP ARR                                             (USD in <scale>)              [indent 1, bold; SUM-BAR; historical: deepKPI INPUT — reported recurring revenue; projection: FORMULA = BOP + Additional Spend + Rev from New]
    Reported ARR (memo)                               (USD in <scale>)              [indent 2; deepKPI INPUT — optional; only if a point-in-time ARR metric is reported; italic memo]
```

**Row-spacing (strict):** zero blank rows from `BOP ARR` through `EOP ARR`. The
`Change from:` label sits immediately below `BOP ARR`; the two change lines are
indented twice beneath it; `EOP ARR` follows immediately. The optional
`Reported ARR (memo)` sits immediately below `EOP ARR`. One blank spacer row
follows the block.

**Borders:** `EOP ARR` carries a **single-lined sum bar** (thin top border) across
the data columns (it is the total of the roll-forward) and is **bold**; there is
**no bottom border on the row above** and **no double-lined border**. The `EOP ARR`
label is bold only (underline is reserved for the block header).

### 2.4 — The formulas (cell-by-cell)

Row labels are the **plain Col C text**. "Prior col" = the period column immediately
to the left; "§3 Additional Spend (col X)" = the Section 3 build's
`Additional Spend from Existing Customers` cell in column X; "§4 Rev from New
(col X)" likewise.

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `BOP ARR` | | `(USD in <scale>)` | deepKPI **input** — prior-FY reported **recurring** revenue (NOT blended total) | `= <prior col 'EOP ARR'>` | `"Base yr: prior-FY reported recurring revenue (input). Else = prior col EOP ARR. Recurring only — never blended total."` |
| `Change from:` | | — | dash (no value) | dash (no value) | `"Label row; heads the two ARR change lines. No values."` |
| `Additional Spend from Existing Customers` | | `(USD in <scale>)` | `= <§3 Additional Spend, this col>` | same | `"= BOP ARR × (NRR − 1), from the Additional Spend build below. Net expansion of the existing customer base."` |
| `Revenue from New Customers` | | `(USD in <scale>)` | historical: `= <EOP ARR> − <BOP ARR> − <Additional Spend from Existing Customers>` (plug) | historical: same plug; **projection:** `= <§4 Revenue from New Customers, this col>` | `"Historical: plug = EOP ARR − BOP ARR − Additional Spend. Projection: = New-Customer revenue from the block below (Total New Customers × Avg ACV)."` |
| `EOP ARR` | | `(USD in <scale>)` | deepKPI **input** — reported recurring revenue | historical: same input; **projection:** `= <BOP ARR> + <Additional Spend from Existing Customers> + <Revenue from New Customers>` | `"Historical: reported recurring revenue (input, the anchor). Projection: = BOP + Additional Spend + Rev from New."` |
| `Reported ARR (memo)` *(optional)* | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** — reported point-in-time ARR, if disclosed | same | *(no comment — input memo; cross-check vs EOP ARR; a material timing / annualization gap is the §1.3 Notes line)* |

**Units.** These are money rows; `../../../../_common/revelata-excel-units-and-scale.md`
sets their scale and tag.

### 2.5 — Pre-delivery checklist (ARR Roll Forward)

- [ ] Rows appear in order: `BOP ARR` → `Change from:` → `Additional Spend from
      Existing Customers` → `Revenue from New Customers` → `EOP ARR`.
- [ ] **Base column `BOP ARR`** is the prior-FY **recurring** revenue (deepKPI
      input), **not** blended total revenue. **All other columns** `BOP ARR` =
      `prior col EOP ARR` (formula).
- [ ] `Change from:` is a **label-only** row — no data in any period column.
- [ ] `Additional Spend from Existing Customers` references the **§3** result;
      `Revenue from New Customers` is the **plug** (`EOP − BOP − Additional Spend`)
      in the historical columns.
- [ ] `EOP ARR` is the **reported recurring revenue** deepKPI input in the
      historical columns (bold, single-lined sum bar on the data columns).
- [ ] After recalculation, **zero formula errors**, and the identity `EOP ARR =
      BOP ARR + Additional Spend + Revenue from New Customers` holds **exactly** for
      every historical period.
- [ ] `EOP ARR` ties to the filing's reported recurring revenue every historical
      year. If a `Reported ARR (memo)` was added, a material gap to `EOP ARR` has its
      Notes line (§1.3).

---

## Section 3 — Additional Spend from Existing Customers

This section values the **net change in recurring revenue from the customers who
already existed at the start of the year**, using the reported **Net Revenue
Retention (NRR)**. Its single result row feeds the §2 `Change from: Additional
Spend from Existing Customers` line. It sits directly beneath the ARR roll forward.

### 3.1 — What NRR is and the formula

**Net Revenue Retention** (a.k.a. Net Dollar Retention, Dollar-Based Net Retention)
measures the recurring revenue this year from **last year's customer cohort**, as a
percentage of what that same cohort produced last year — capturing expansion, minus
contraction, minus churn, on the **existing** base (it excludes new-logo revenue).
So:

> `BOP ARR × NRR` = the recurring revenue the existing (BOP) customer base
> generates **this** year, and therefore
> **Additional Spend from Existing Customers = BOP ARR × (NRR − 1)**.

An NRR of 112% means the existing base grew its spend by 12%, so Additional Spend =
`BOP ARR × 0.12`. NRR **below** 100% (net contraction) yields a **negative**
Additional Spend — that is expected and must **not** be floored at zero.

This also explains why §2's `Revenue from New Customers` plug is internally
consistent: `EOP ARR − BOP ARR − BOP ARR×(NRR−1) = EOP ARR − BOP ARR×NRR`, i.e. the
recurring revenue **not** attributable to the retained existing base — the
new-customer contribution.

### 3.2 — Layout

```
  Existing Customers                                                                [indent 1; bold + underlined block header]
    BOP ARR                                             (USD in <scale>)              [indent 2; FORMULA = §2 ARR Roll Forward BOP ARR, this col]
    Net Revenue Retention (NRR)                         (% of BOP ARR)                [indent 2; deepKPI INPUT; projection: driver]
  Additional Spend from Existing Customers            (USD in <scale>)              [indent 1, bold; SUM-BAR; FORMULA = BOP ARR × (NRR − 1)]
```

Zero blank rows within the block; one blank spacer row after it. Number formats follow
each row's Col D tag.

### 3.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `BOP ARR` | | `(USD in <scale>)` | `= <§2 ARR Roll Forward 'BOP ARR', this col>` | `"= BOP ARR from the ARR roll forward (prior-yr recurring revenue). Same value the roll forward opens on."` |
| `Net Revenue Retention (NRR)` | | `(% of BOP ARR)` | deepKPI **input** % (reported NRR / NDR / DBNRR) | *(no comment — input row; provenance via hyperlink)* |
| `Additional Spend from Existing Customers` | | `(USD in <scale>)` | `= <BOP ARR> × (<Net Revenue Retention (NRR)> − 1)` | `"= BOP ARR × (NRR − 1). Net expansion of the existing base; negative if NRR < 100%."` |

**Sourcing NRR.** Pull the reported NRR / NDR series via `search_kpis` against the
shared inventory. Read the `unit` to confirm it is a percentage. If NRR is stored as
a whole number (e.g. `112`) rather than a decimal fraction (`1.12`), normalize to
the sheet's percent convention (decimal fraction) so `(NRR − 1)` evaluates correctly
— confirm which convention the series uses before wiring the formula. If NRR is
reported only as a trailing / point-in-time figure, use the fiscal-year value that
best matches the annual cohort and say which figure was used in that cell's comment.

### 3.4 — Pre-delivery checklist (Additional Spend)

- [ ] `BOP ARR` references the **§2** BOP ARR cell (same value the roll forward
      opens on).
- [ ] `Net Revenue Retention (NRR)` is a reported deepKPI **input** %, normalized to
      the sheet's percent convention so `(NRR − 1)` is correct.
- [ ] `Additional Spend from Existing Customers = BOP ARR × (NRR − 1)` is a **live
      formula**; negative values (NRR < 100%) are preserved, not floored.
- [ ] The result row is the one §2's `Change from: Additional Spend` references.
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Revenue from New Customers

This section values the recurring revenue contributed by **customers newly acquired
during the year**, from the **net new customer count** (referenced from the customer
roll-forward) and an **Average ACV** (annual contract value per new customer). In
the historical columns the revenue is known (it is §2's plug) and ACV is
**backsolved**; in the projection columns ACV becomes a **driver** and the revenue
is **computed**, then flows up to §2. It sits directly beneath the Additional-Spend
block.

### 4.1 — The three rows, the ACV backsolve, and the link direction

For each period N, three rows:

1. **Total New Customers** = `= <customer roll-forward consolidated 'Net New
   Additions', this col>` — the net new customers added that year (referenced, not
   re-derived). Use the **consolidated** `Net New Additions` row the router laid
   down.
2. **Average ACV** — **historical:** the backsolve `Revenue from New Customers ÷
   Total New Customers`; **projection:** a **driver**. It is the average annual
   recurring contract value each new customer contributes in its first year.
3. **Revenue from New Customers** — **historical:** `= <§2 ARR Roll Forward 'Revenue
   from New Customers', this col>` (the plug, referenced **up** from the roll
   forward); **projection:** `= Total New Customers × Average ACV` (computed here,
   and referenced **down** by §2).

**The link direction inverts at the boundary.** The §2 `Revenue from New Customers`
change line and this section's `Revenue from New Customers` row are always the
**same value**; only the driving direction flips:

- **Historical:** §2 computes the plug (`EOP − BOP − Additional Spend`); this row
  **references** that plug; `Average ACV` = this row ÷ `Total New Customers`.
- **Projection:** `Average ACV` is the driver; this row = `Total New Customers ×
  Average ACV`; §2's change line **references** this row.

There is **no circularity**: in each half exactly one side is the source and the
other is a reference.

### 4.2 — Base-year handling (ACV is blank when there are no new-customer counts)

The customer roll-forward's **base-year** `Net New Additions` is **blank** (no prior
BOP to difference against). So in the ARR build's base column, `Total New Customers`
is blank and **`Average ACV` cannot be backsolved** — leave the base-column
`Average ACV` **blank (dash)** rather than forcing a `÷ 0`. `Revenue from New
Customers` in the base column still carries §2's plug value; only its ACV decompo-
sition is unavailable that year. This is harmless: the projection ACV driver is
seeded from year `N`, which has a valid backsolved ACV.

### 4.3 — Layout

```
  New Customers                                                                     [indent 1; bold + underlined block header]
    Total New Customers                                 (customers)                   [indent 2; FORMULA = customer roll-forward 'Net New Additions', this col]
    Average ACV                                         (USD thousands per customer)  [indent 2; historical: FORMULA = Revenue from New Customers ÷ Total New Customers [base col: dash]; projection: driver]
  Revenue from New Customers                          (USD in <scale>)              [indent 1, bold; SUM-BAR; historical: FORMULA = §2 'Revenue from New Customers' plug; projection: FORMULA = Total New Customers × Average ACV]
```

Zero blank rows within the block; one blank spacer row after it. `Total New
Customers` is a **count** row whose display scale is declared in Col D;
`Revenue from New Customers` is a money row; `Average ACV` is a **per-customer**
figure, never scaled to millions, tagged `(USD thousands per customer)`. Their three
display scales must satisfy Rule 2's coherence test, or the ACV row carries the
declared departure.

### 4.4 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Total New Customers` | | `(customers)` | `= <customer roll-forward 'Net New Additions', base col>` (blank if the roll-forward base is blank) | `= <customer roll-forward 'Net New Additions', this col>` | `"= consolidated customer roll-forward Net New Additions (this col). Net new customers added."` |
| `Average ACV` | | `(USD thousands per customer)` | **dash** (Total New Customers blank ⇒ cannot backsolve) | historical: `= <Revenue from New Customers, this col> ÷ <Total New Customers, this col>`; **projection:** driver | `"Historical backsolve: Revenue from New Customers ÷ Total New Customers. Blank in base yr (no new-customer count). Projection: driver."` |
| `Revenue from New Customers` | | `(USD in <scale>)` | `= <§2 'Revenue from New Customers', base col>` | historical: `= <§2 'Revenue from New Customers', this col>`; **projection:** `= <Total New Customers> × <Average ACV>` | `"Historical: = the roll forward's plug (EOP − BOP − Additional Spend). Projection: = Total New Customers × Avg ACV; this value flows up to the roll forward."` |

### 4.5 — Pre-delivery checklist (Revenue from New Customers)

- [ ] `Total New Customers` references the **customer roll-forward's consolidated
      `Net New Additions`** row — not re-derived, not a different customer series.
- [ ] `Average ACV` is the **backsolve** (`Revenue from New Customers ÷ Total New
      Customers`) in the historical columns and **dash in the base column** (blank
      new-customer count).
- [ ] Historical `Revenue from New Customers` **references §2's plug**; the two are
      the same value (no double-build, no hardcode).
- [ ] No circular reference (one side sources, the other references, in each half).
- [ ] After recalculation, **zero formula errors**, and ACV values look economically
      sane (positive, same order of magnitude across years — a wild ACV flags a
      new-customer-count or plug problem upstream).

---

## Section 5 — Non-Recurring Revenue Streams (conditional)

**Include this section only for a mixed company** (§1.2) — one that reports a
recurring stream **and** at least one non-recurring stream. A **pure-play recurring**
company has no non-recurring streams, so this section is **omitted entirely**;
record the omit decision in one line in `BUILD_LOG.md`, citing §1 (the hand-back
report carries the same). It is not a Notes line.

### 5.1 — What the streams are, and making the partition exhaustive

Each non-recurring stream is a reported revenue line that is **not** the recurring
stream (professional services, license, hardware, transaction fees, etc.). These
are **not** put through the ARR roll forward — they do not retain and carry no
per-customer ACV in the same way. Each is carried as a **reported input** with a
**YoY growth** memo, and projected on that YoY basis (Section 6 / Projections).

**Make the streams an exhaustive partition of the non-recurring remainder.** The
recurring stream plus the non-recurring streams must sum to **reported total
revenue** in every historical year. After laying down the explicitly reported
non-recurring streams, check each year: if `EOP ARR + Σ (non-recurring streams) <
reported Total Revenue`, the reported streams do not exhaust revenue — add a final
**`Other Revenue`** stream whose historical value is the residual `Total Revenue −
EOP ARR − Σ (identified non-recurring streams)` (a formula), carried historically as
that formula and projected as a **share of modeled revenue** (EOP ARR plus the named
streams) off the driver row `Other Revenue — % of modeled revenue` laid beneath it — see
Projections, Part 4. This mirrors the residual-bucket rule in the customer
roll-forward: after it, the partition is exhaustive **by construction**.

### 5.2 — Layout

**There is NO oversized `Non-Recurring Revenue` section header.** Each non-recurring
stream is its own small block, laid out exactly like the §3 / §4 blocks: a bold +
underlined header row bearing the stream name (label only — no data), then the stream's value row, then its `YoY %` row. Blocks
are separated by **one blank spacer row**.

```
  <Stream 1 name>                                                                   [indent 1; bold + underlined block header — label only — no data]
    Revenue from <Stream 1 name>                        (USD in <scale>)              [indent 2; deepKPI INPUT historical; projection: = prior col × (1 + YoY %)]
      YoY %                              (%)                           [indent 3; FORMULA historical = this col ÷ prior col − 1; driver in projection; italic]

  <Stream 2 name>                                                                   [indent 1; bold + underlined block header — label only]
    Revenue from <Stream 2 name>                        (USD in <scale>)              [indent 2; deepKPI INPUT historical; projection: = prior col × (1 + YoY %)]
      YoY %                              (%)                           [indent 3; FORMULA historical; driver in projection]

  Other                                                                             [indent 1; bold + underlined block header — label only; only if streams don't exhaust]
    Other Revenue                                       (USD in <scale>)              [indent 2; FORMULA residual historical = Total − EOP ARR − Σ streams; projection: = the driver row beneath × (EOP ARR + Σ named streams), this col]
      Other Revenue — % of modeled revenue                (% of modeled revenue)        [indent 3; FORMULA historical = Other Revenue ÷ (EOP ARR + Σ named streams); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]
```

Each stream's header row is **bold + underlined, indent once** (no data values) and
carries the stream's name as the issuer captions it; the value row beneath it is a
plain **indent-once** row labeled `Revenue from <Stream>` — the same label the §6
consolidated table uses when it restates the row — (no bold, no sum bar — a stream
is a single reported figure, not a sum); the `YoY %` row is
**indent twice**, italic, immediately beneath (no blank row above). The residual
block, when needed, is headed `Other` with the value row `Other Revenue`. One blank
spacer row separates one stream's block from the next.

### 5.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Stream n>` *(value row; the block header above it is the bare stream name)* | | `(USD in <scale>)` | deepKPI **input** — reported non-recurring stream revenue (historical) | *(no comment — input row; provenance via hyperlink)* |
| `YoY %` | | `(%)` | base col: dash; else `= <this col> ÷ <prior col> − 1` | `"YoY % in <stream>. Historical: derived. Projection: driver."` |
| `Other Revenue` *(residual, only if needed)* | DATA_DEPENDENT | `(USD in <scale>)` | historical: `= <Total Revenue, this col> − <EOP ARR, this col> − SUM(<identified non-recurring streams, this col>)`; projection: `= <Other Revenue — % of modeled revenue, this col> × (<EOP ARR, this col> + SUM(<identified non-recurring streams, this col>))` | `"Residual non-recurring revenue = reported total − EOP ARR − identified streams. Makes the partition exhaustive. Projection: a share of modeled revenue, off the driver row beneath."` |
| `Other Revenue — % of modeled revenue` *(driver row under the residual, in place of a `YoY %`; visible)* | DATA_DEPENDENT | `(% of modeled revenue)` | historical: `= <Other Revenue, this col> ÷ (<EOP ARR, this col> + SUM(<identified non-recurring streams, this col>))`; projection: **DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The residual's share of the revenue the build models (EOP ARR + named streams). Historical: a fit diagnostic — low single digits expected. Projection: driver, guided or else the latest year, then flat."` |

Pull each non-recurring stream series via `search_kpis` against the shared inventory.
If a stream is bundled with others in a single reported line, use that reported line
and name the bundled components in that row's Col C comment; the `Other Revenue`
residual (§5.1) still makes the build foot.

### 5.4 — Pre-delivery checklist (Non-Recurring streams)

- [ ] Section is **present iff** the company is **mixed** (§1.2); omitted for
      pure-play, with the decision in `BUILD_LOG.md`.
- [ ] Each stream is its own mini-block — a **bold + underlined header** row, a
      reported deepKPI **input** value row (historical), and a `YoY %`
      row beneath it (dash in the base column) — with **no** oversized
      `Non-Recurring Revenue` section header above them.
- [ ] The streams (plus the `Other Revenue` residual, if added) form an **exhaustive
      partition** of `Total Revenue − EOP ARR` in every historical year (verified in
      §6's foot check).
- [ ] No non-recurring dollars leaked into the ARR roll forward (§2 – §4).
- [ ] After recalculation, **zero formula errors**.

---

## Section 6 — Consolidated Revenue (the foot)

This final section collects the recurring stream and the non-recurring streams into
a single table and foots to the company's **reported total revenue**.

### 6.1 — The partition and the foot

Consolidated revenue is the sum of `EOP ARR` and the non-recurring streams:

> **Total Revenue = EOP ARR + Non-Recurring Stream 1 + Non-Recurring Stream 2 + …
> [+ Other Revenue residual]**

Because §5 made the streams an **exhaustive partition** of `Total Revenue − EOP
ARR`, this sum equals reported total revenue exactly. In the **historical** columns,
`Total Revenue` is the **reported** deepKPI input (the anchor), and a foot-check memo
confirms the components tie to it. In the **projection** columns the inversion
applies: `Total Revenue` is written **directly as the sum** of its components (§ see
Projections). For a **pure-play** company the table has a single component
(`Revenue from <Stream>`, which equals EOP ARR) and `Total Revenue = EOP ARR`.

### 6.2 — Layout

```
  Consolidated Revenue                                                              [indent 1; bold + underlined header — NOT all caps, NOT enlarged; it is still under REVENUE]
    Revenue from <Stream>                               (USD in <scale>)              [indent 2; the recurring stream, <Stream> = its issuer caption; FORMULA = §2 ARR Roll Forward 'EOP ARR', this col]
    Revenue from <Stream 1>                             (USD in <scale>)              [indent 2; non-recurring stream 1; FORMULA = §5 stream row, this col]
    Revenue from <Stream 2>                             (USD in <scale>)              [indent 2; non-recurring stream 2; FORMULA = §5 stream row, this col]
    Other Revenue                                       (USD in <scale>)              [indent 2; FORMULA = §5 'Other Revenue' residual, this col; only if §5 has it]
  Total Revenue                                       (USD in <scale>)              [indent 1, bold; SUM-BAR; historical: deepKPI INPUT — reported total revenue; projection: FORMULA = sum of components]
    Memo: components − Total (must = 0)               (USD in <scale>)              [indent 2; FORMULA check; 0 every period]
    Memo: recurring mix                               (% of total revenue)          [indent 2; FORMULA, optional = Revenue from <Stream> (recurring) ÷ Total Revenue]
```

**Row labels are `Revenue from <Stream>`** for every component — the contract-row
pattern every software revenue build lays (`../../../SKILL.md`, "Contract rows") — with
`<Stream>` the issuer's own caption for that stream: the recurring stream identified in
§1 becomes e.g. `Revenue from Subscription`, a services stream `Revenue from
Professional Services`. The recurring row's Col C comment states that it is the §2
EOP ARR; the label does not say "ARR", because the downstream cost build matches a
cost-of-revenue line to its stream by this label, and a reader of the workbook reads
the issuer's caption. The optional `Memo: recurring mix` row still identifies which
stream is recurring.

The `Consolidated Revenue` header is **bold + underlined, indent once**, and is
**not** all caps or enlarged (it is a sub-section under the `REVENUE` header, not a
top-level section header). `Total Revenue` is **bold** with a **single-lined sum bar**
(thin top border) across the data columns — **no** double border and **no** label
underline; the component rows read top-to-bottom into it; the foot-check memo sits
immediately beneath it.

### 6.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Stream>` *(the recurring stream)* | | `(USD in <scale>)` | `= <§2 ARR Roll Forward 'EOP ARR', this col>` | `"Recurring revenue = EOP ARR from the ARR roll forward; the year's reported recurring revenue is treated as ARR."` |
| `Revenue from <Stream n>` *(one per §5 non-recurring stream)* | | `(USD in <scale>)` | `= <§5 stream row, this col>` | `"= the <stream n> line above, outside the recurring stream."` |
| `Other Revenue` *(if §5 has it)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <§5 'Other Revenue' residual, this col>` | `"= the Other Revenue residual above: revenue outside the recurring stream and the named streams."` |
| `Total Revenue` | | `(USD in <scale>)` | historical: deepKPI **input** — reported total revenue; **projection:** `= <Revenue from <Stream> (recurring)> + SUM(<non-recurring stream rows>)` | `"Historical: reported total revenue (input, the anchor). Projection: = EOP ARR + Σ non-recurring streams."` |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= (<Revenue from <Stream> (recurring)> + SUM(<non-recurring stream rows>)) − <Total Revenue>` | `"Foot check: must equal 0 every period."` |
| `Memo: recurring mix` *(optional)* | DATA_DEPENDENT | `(% of total revenue)` | `= <Revenue from <Stream> (recurring)> ÷ <Total Revenue>` (percent) | `"Recurring revenue as a share of total."` |

### 6.4 — Pre-delivery checklist (Consolidated Revenue)

- [ ] The table sums `Revenue from <Stream>` + every non-recurring stream (+ `Other
      Revenue` residual if §5 has it).
- [ ] `Total Revenue` is the **reported** deepKPI input in the historical columns
      (bold, single-lined sum bar on the data columns; the `Consolidated Revenue`
      header is bold + underlined but not all caps or enlarged).
- [ ] The `components − Total (must = 0)` memo evaluates to **0** in every historical
      period after recalculation.
- [ ] For a **pure-play** company, the table has one component and `Total Revenue =
      Revenue from <Stream>` (which equals EOP ARR).
- [ ] After recalculation, **zero formula errors**, and the master identity `Total
      Revenue = EOP ARR + Σ non-recurring streams` holds exactly every period.

---

## Section 7 — Worked example (illustrative)

This walks a mixed software company through the full ARR build to show how the rows
chain. **The figures are illustrative** (round numbers for transparency, not any
real issuer's reported data) — the point is the mechanics. Universe = consolidated;
**revenue figures in $ millions**; ACV in **$ thousands per customer** (per-customer
figures are not scaled to millions). Build window FY2022 (base) → FY2025. Reported
streams: `Subscription revenue` (recurring) and `Professional services`
(non-recurring). NRR and net new customers as shown.

**Customer roll-forward reused (consolidated `Net New Additions`, per the router's
pre-build):** FY2022 blank (base), FY2023 = 300, FY2024 = 340, FY2025 = 380.

**Base-year seed (FY2022 column only):** prior-FY (FY2021) **recurring** revenue =
**$800M** (deepKPI input — the recurring stream only, NOT blended total).

**Section 2 / 3 / 4 — ARR roll forward** (illustrative NRR and reported EOP ARR; all
dollar rows in $ millions):

| Row | Lays when | Units (Col D) | FY2022 (base) | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| BOP ARR | | `(USD in millions)` | 800 *(seed)* | 1,000 *(=FY22 EOP)* | 1,240 | 1,520 |
| NRR *(§3)* | | `(% of BOP ARR)` | 110% | 112% | 111% | 110% |
| Additional Spend from Existing Customers *(§3 = BOP × (NRR−1))* | | `(USD in millions)` | 80 | 120 | 136.4 | 152 |
| Revenue from New Customers *(§2 plug = EOP − BOP − Add'l)* | | `(USD in millions)` | 120 | 120 | 143.6 | 168 |
| **EOP ARR** *(reported recurring revenue, input)* | | `(USD in millions)` | **1,000** | **1,240** | **1,520** | **1,840** |
| Total New Customers *(§4, = roll-forward NNA)* | | `(customers)` | — *(base blank)* | 300 | 340 | 380 |
| Average ACV *(§4 backsolve = Rev from New ÷ New Customers)* | | `(USD thousands per customer)` | — | 400.0 | 422.4 | 442.1 |

Note the identity foots every year (e.g. FY2025: 1,520 + 152 + 168 = 1,840, all in
USD millions). Average ACV is blank in FY2022 (no new-customer count) and backsolved
FY2023–FY2025 (e.g. FY2023: 120 ÷ 300 customers = 0.4 million = **400.0 thousand per
customer**). Only FY2022 `BOP ARR` and the `EOP ARR` / `NRR` inputs are deepKPI
inputs; everything else is a formula.

> **A declared coherence departure.** Revenue displays in **millions** and the customer
> count in **ones**, so the displayed operands do not divide to the displayed ACV
> (120 ÷ 300 = 0.4, not 400.0). Rescaling the count to thousands would show `0.3`,
> which reads badly, and ACV is conventionally quoted in thousands per customer — so
> the conventional display wins and the `Average ACV` row's Col C comment records it,
> per Rule 2's coherence test.

**Section 5 — Non-recurring stream** (illustrative `Professional services`, USD in
millions):
FY2022 90, FY2023 96, FY2024 101, FY2025 105 (reported inputs), each with a
`YoY %` memo. Suppose reported total revenue FY2025 = $1,945M. Then
`Revenue from Subscription 1,840 + Revenue from Professional services 105 = 1,945` — the streams exhaust
total, so **no `Other Revenue` residual is needed**, and the §6 `components − Total`
foot-check = 0.

**Section 6 — Consolidated (FY2025, USD in millions):** `Revenue from Subscription 1,840 +
Revenue from Professional services 105 = Total Revenue 1,945`; recurring mix = 94.6%.
The build foots exactly.

## Projections (forecast years)

After the **historical** build above (Sections 1 – 7) is laid down, recalculated,
and footed (the §6 `components − Total (must = 0)` check passes and each roll-forward
identity holds), **extend the entire ARR build into the projection window** before
the downstream handoff (§8). The projection window is the **five fiscal years after
the last historical year** (`N+1 … N+5`) per the **Model timeline** in
`../../../SKILL.md` — do not redefine it here. Add five more **annual** columns
immediately to the right of the historical block, continuing the same left → right,
oldest → newest order; the build stays **annual**. Most of the build **drags across
as formulas**; only a small set of **drivers** are entered as forward assumptions.

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
- Every **non-driver** projection cell stays standard formula styling (black font, no
  fill, no dashed box) — identical to its historical styling, dragged one column
  right.

### Driver value methodology (the default seed for every driver)

Unless a driver is called out as an exception below, seed each driver cell as:

- **First projection year (`N+1`)** — the **default seed** (`SKILL.md`, Build
  mechanics): the guided value where the orchestrator's guidance table names this
  driver for `N+1`; else the latest year on the issuer's normalized basis where the
  filing discloses one; else the **latest historical year** (`N`), which the renderer
  writes as a live `ISNUMBER`-guarded formula over `N`, `N−1`, `N−2` (0 when none is
  numeric). No year is averaged into the seed.
- **Each later projection year (`N+2 … N+5`)** — **equal to the `N+1` cell** (flat):
  `= <driver N+1 cell>`.
- The modeler may type a specific assumption over any driver cell; the red/dashed
  styling flags exactly which cells are meant to be overwritten.

The projection **drivers** in this build are exactly:

1. **NRR** (§3) — per year.
2. **Average ACV** (§4) — per year.
3. **Each non-recurring stream's `YoY %`** (§5), and the `Other
   Revenue` residual's `Other Revenue — % of modeled revenue` if present.

`Total New Customers` is **not** a new driver here — it references the customer
roll-forward's **projected** `Net New Additions`, which
`../customerRollForward/customerRollForward.md` already turned into a driver in its
own Projections section. Reference the projected count; do not re-seed it.

### Part 1 — ARR Roll Forward (§2): the plug inverts to a sum

In the projection columns the roll forward **inverts** — `Revenue from New Customers`
stops being the plug and `EOP ARR` stops being the reported input:

- **`BOP ARR`** — **formula in both halves**, `= prior column EOP ARR`. For `N+1`,
  BOP ARR equals the last historical year `N` EOP ARR, so projections pick up exactly
  where the actuals end.
- **`Additional Spend from Existing Customers`** — **unchanged formula**, `= §3
  Additional Spend (this col)` (driven by the projected NRR — Part 2).
- **`Revenue from New Customers`** — now **references §4** (`= §4 Revenue from New
  Customers, this col`), which in projection computes `Total New Customers × Average
  ACV`. (Historical: this was the plug; projection: it is the §4 product.)
- **`EOP ARR`** — now the **formula** `= BOP ARR + Additional Spend from Existing
  Customers + Revenue from New Customers` (no longer a reported input).

No new driver appears in §2 itself; its drivers live in §3 (NRR) and §4 (ACV).

### Part 2 — Additional Spend from Existing Customers (§3): driver = NRR

- **`BOP ARR`** — unchanged formula (`= §2 BOP ARR, this col`).
- **`Net Revenue Retention (NRR)`** — the **driver** (red/dashed; `N+1` = the default seed: the guided value, else the latest historical NRR value; `N+2 … N+5` = `N+1`).
- **`Additional Spend from Existing Customers`** — unchanged formula `= BOP ARR ×
  (NRR − 1)`.

### Part 3 — Revenue from New Customers (§4): driver = Average ACV

- **`Total New Customers`** — unchanged formula, now resolving to the customer
  roll-forward's **projected** `Net New Additions` (this col).
- **`Average ACV`** — the **driver** (red/dashed; `N+1` = the default seed: the guided value, else the latest historical **backsolved** ACV (`N`); `N+2 … N+5` = `N+1`).
- **`Revenue from New Customers`** — now the **formula** `= Total New Customers ×
  Average ACV` (this is the value §2 references in projection).

### Part 4 — Non-Recurring Revenue Streams (§5): driver = each stream's YoY %

For each non-recurring stream:

- **`YoY %`** — the **driver** (red/dashed; `N+1` = the default seed: the guided value, else the latest historical `YoY %` value; `N+2 … N+5` = `N+1`).
- **`Revenue from <Stream n>`** — unchanged **for historical** (reported deepKPI input). For
  **projection**: `= <prior column stream value> × (1 + <YoY %, this
  column>)` — the input → compounding inversion (the stream compounds off its own
  prior value by the driver).
- The `Other Revenue` residual, if it exists, is **no longer a subtraction** in
  projection (that would be circular against `Total Revenue`). It is projected as a
  **share of modeled revenue**: `= <Other Revenue — % of modeled revenue, this col> × (<EOP
  ARR, this col> + SUM(<named stream rows>, this col))`, the driver row beneath it
  seeded by the default seed like every other driver. The denominator excludes the
  residual itself, so there is no circularity. Add one Notes line: `Revenue: in the
  forecast Other Revenue is a share of modeled revenue, held at the latest ratio,
  rather than a plug.`

### Part 5 — Consolidated Revenue (§6): Total becomes the sum

- **`Revenue from <Stream>`** (recurring) and each non-recurring **`Revenue from <Stream n>`** / **`Other Revenue`**
  component row — the **same reference formulas** as the historical columns; drag them
  across (they now point at the projected §2 / §5 values).
- **`Total Revenue`** — the **foot**. The identity `Total Revenue = EOP ARR + Σ
  non-recurring streams` holds in both halves, so `Total Revenue` is **never a
  driver**. Historically it is the **reported deepKPI input**; in projection it is
  written **directly as the sum** of its component rows: `= <Revenue from <Stream> (recurring)> +
  SUM(<non-recurring stream rows>)`. The `components − Total (must = 0)` foot-check
  then evaluates to **0** in every projection year (trivially).

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=` formula
  (no hardcoded numbers). The **only** seeded/typed cells are the drivers: NRR (§3),
  Average ACV (§4), and each non-recurring stream's `YoY %` (§5).
- **Driver seeding.** Each driver's `N+1` = the default seed (the guided value where the guidance table names it, else the latest historical year) and `N+2 … N+5` = `N+1`.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors** and **no circular references** (confirm §2 `Revenue from New Customers` ↔
  §4 is a one-directional reference in each half, and the §5 residual is a share of modeled revenue
  rather than a subtraction in projection).
- **Foot.** The §6 `components − Total (must = 0)` memo equals **0** in every
  projection year; each roll-forward identity `EOP ARR = BOP ARR + Additional Spend +
  Revenue from New Customers` holds.
- **Continuity at the boundary.** `N+1` `BOP ARR` equals `N` `EOP ARR`; `N+1` for each
  non-recurring stream compounds off its `N` value — the projection joins the actuals
  with no gap or jump.

## Section 8 — What the ARR build produces for downstream sections

After Sections 1 – 6 are built, the workbook contains, for every period in the
window, a fully-footed recurring-revenue build beneath the customer roll-forward: an
`ARR Roll Forward` (`BOP ARR` → `Additional Spend from Existing Customers` +
`Revenue from New Customers` → `EOP ARR`), its NRR-driven Additional-Spend and
ACV-driven New-Customer supporting builds, any non-recurring streams, and a
`Consolidated Revenue` table whose `Total Revenue` foots to reported revenue — every
component a live formula flowing from the customer counts, the NRR / ACV / stream
inputs, and the base-year seed. Downstream operating-model sections (costs,
consolidated financials) reference `Total Revenue` and the component lines (each
`Revenue from <Stream>` row) directly, by label; any later change to the customer
roll-forward, an NRR input, or a stream input propagates automatically through the
entire ARR build and keeps the foot intact.

Report back to the router, in one line each: whether the company was **pure-play or
mixed** (and which stream was the recurring anchor), the historical window used, and
the row addresses of `EOP ARR`, `Total Revenue`, and each non-recurring stream so
downstream sections can reference them without re-deriving anything.

## Dependencies — rows this build references but does not lay

Per `../../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| customer roll-forward `Net New Additions` and `EOP` (consolidated, or per bucket) | customer roll-forward (`../customerRollForward/`) | the software router's Step 3 ran the roll forward (route A requires it) | none — return `ABORTED` |
