---
name: revenue-retail-other
description: >
  Catch-all (bare-bones) revenue build for retail companies in the
  operating-model workbook. Invoked by the retail router
  (`revenue/retail/retail.md`) as the DEFAULT route when the company reports
  neither a store / location count (so the LOCATION GATE FAILED, making the
  comparable-stores build and the square-footage build unavailable) nor two of the
  three product-level unit-economics families needed for a units build
  (→ unitsBuild). This is the simplest revenue model: a revenue CAGR / growth
  build by reporting segment. Receives the resolved `company_id`, official company
  name, workbook path, and the shared KPI inventory; builds the revenue model
  beneath the `REVENUE` ALL-CAPS header by laying down one Revenue-from-segment
  line (plus its YoY growth) for EACH reporting segment the company discloses,
  then a Total Revenue line equal to the sum of the segments. Historical segment
  revenue (in retail usually filed as NET SALES) comes from deepKPI inputs;
  projected periods grow each segment forward by its own growth driver (seeded by the default seed, guided else the latest change, then flat; a historical CAGR memo is
  informational). Pulls series via `search_kpis` from
  the shared inventory and segment structure via `get_company_segments`; format per
  ../../../../_common/revelata-excel-styling-rules.md (one row per series, derived
  cells as live formulas) EXCEPT for time scope (last 4 fiscal years), which this
  build overrides. Sections: §1 revenue by segment, §2 total revenue,
  §3 single-/no-segment, reconciliation and retail wrinkles, §4 worked example,
  §5 downstream handoff.
---

# revenue — retail — other / catch-all build (revenue CAGR by segment)

This is the **catch-all** retail revenue build — the **most bare-bones** revenue
model in the set. It is invoked by the retail router (`../retail.md`) when the
company is a retailer but does **not** have the KPIs required for any of the
three richer builds:

- the **Step 1 location gate FAILED** — the company reports no store / location
  count anywhere in the inventory — which makes the **comparable-stores build**
  (`comparableStoresBuild/`) and the **square-footage build** (`sqftBuild/`)
  unavailable by construction, **and**
- it does not report **two of the three** product-level families (revenue per
  product / units per product / selling price per product) for the same principal
  product, so it fails the **units build** (`unitsBuild/`).

So this build falls back to the simplest thing that still produces a defensible
revenue line: a **revenue CAGR / growth model by reporting segment**. For each
segment the company discloses, lay down the segment's revenue and its
year-over-year growth; **Total Revenue is simply the sum of the segments**.

> **You own the whole REVENUE section here.** Unlike every other retail build,
> this one runs **only after the location gate FAILED**, so
> `locationBuild/locationBuild.md` never ran and there is **no store roll-forward
> in the workbook** — the `REVENUE` header is empty when you arrive. There are no
> store counts to reference, and this build must not invent any. It is driven
> purely by reported revenue and a growth assumption.

> **Do not "rescue" the company into a richer build.** A retailer can land here
> while still reporting an incidental square-footage series, a wholesale-door
> count, or a units-and-price pair covering one minor category. The router already
> weighed those and deliberately excluded them: square footage with **no** store
> count fails build C on purpose, third-party `Doors` are not a fleet the company
> operates, and a non-principal product pair does not carry build B. Do **not**
> reconstruct a per-square-foot or per-unit engine here. If you believe the router
> mis-routed, say so and hand back — do not silently build a different model.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, and the router's note that the **location gate FAILED**, that the
units criteria were not met, and any Step 2.1 retail wrinkles it flagged.

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
  matches the sibling retail builds. (Keep at least the four years so a historical
  CAGR can be computed — see §1.1.)
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 4), then **extends every segment into the projection window** following the
  **Projections (forecast years)** section near the end of this file. Do not
  fabricate projection values outside that procedure.
- **The build is ANNUAL.** Segment revenue is a reported annual figure; do not add
  quarterly columns.

> **Retail fiscal calendars are 52/53 weeks — map the year, don't trust the date
> stamp.** Most retailers close on a Saturday near the end of January, so FY2025
> may be stamped `2026-01-31` in deepKPI, and stamps are frequently inconsistent
> **between series within one issuer**. Decide the fiscal-year label for each
> series from the filing's own fiscal-year convention, then write every segment's
> value into the column that fiscal year owns. Because there is no store
> roll-forward here to align against, **this build sets the column mapping for the
> whole workbook** — an off-by-one column silently corrupts every growth rate and
> the CAGR memo while still looking plausible. Add one Notes line stating the
> calendar (*"Revenue: fiscal years end on <the Saturday nearest January 31>; FY<n>
> is the year ended <month year>."*) and record the ordinal mapping itself in
> `BUILD_LOG.md`. See §2 of
> `../locationBuild/locationBuild.md` for the underlying problem.

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
- **"Revenue" is usually filed as "Net sales" in retail.** The concept is what
  matters, not the label. Search both, plus `Total revenues`, `Net revenues`, and
  `Total net sales`, and keep the issuer's own wording in the row label (a
  retailer that says `Net sales` should read `Net sales from <Segment>`, not
  `Revenue from <Segment>`). Throughout this file, "revenue" means whichever of
  the two the issuer reports.
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
  default, thousands where the digit test puts a small filer. Four points are specific
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
  - **Retail wrinkles (§3.3) add rows, not families.** A membership / fee-income block
    is an ordinary money segment block. A constant-currency or FX-impact memo row
    beneath a segment is `(USD in <scale>)` when the issuer reports a dollar impact and
    `(%)` when it reports a rate — tag it when you add it, and say which in its Col C
    comment.
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

- **Indentation — real cell indent, never leading spaces.** Every indent level in
  this build — "base indent", "indent once", "indent twice" — is the cell's
  **actual indent property**: openpyxl `Alignment(indent=n)` with `indent=0`, `1`,
  `2`, the equivalent of Excel's **Home → Increase Indent** (`Alt, H, 6`).
  **Never** pad the label string with leading spaces. Padding is prohibited
  because:

  - The segment-header underline (`Font(underline="single")`) draws under the
    padding characters and produces a **ragged rule running left of the text**; a
    real indent shifts the label without adding any underline-able characters.
  - A padded label breaks `MATCH` / `VLOOKUP` / `XLOOKUP` against it — which
    matters here, where the §2 total sums segment rows that repeat the same
    `Revenue from <Segment>` shape.
  - The spaces are **invisible in the Excel UI**, so a mis-padded row cannot be
    spotted or corrected by the user, and Increase/Decrease Indent will not clear
    it.

  When setting a cell's `Alignment`, **keep the existing `horizontal` / `vertical`
  settings and add `indent=n`** — do not replace the whole `Alignment` object:

  ```python
  # right
  c = ws["C8"]; c.value = "Revenue from Wholesale"     # no padding in the string
  a = c.alignment
  c.alignment = Alignment(horizontal=a.horizontal, vertical=a.vertical, indent=1)

  # wrong
  c.value = "  Revenue from Wholesale"                 # leading spaces — prohibited
  ```

  The ASCII row maps in this file draw the hierarchy with whitespace **for
  legibility only** — those spaces are diagram, not data. Read the stated indent
  level for each row and apply it with `Alignment(indent=n)`.

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

**Why per segment, not one blended rate.** Retail mix shifts are large and
persistent — a direct-to-consumer or digital segment compounding at a double-digit
rate alongside a flat or declining wholesale segment, or one banner growing while
another is being wound down. Growing each segment on its own CAGR preserves that
mix shift; the segments meet only at the **dollar level** in the Total (Section 2),
where summing is always valid. A single blended company-wide rate would freeze
today's mix forever and quietly overstate the shrinking segment.

### 1.2 — Discovering the segments

Determine the company's reporting segments **before** laying down rows:

1. Call **`get_company_segments`** (and, if useful, `get_company_summary`) to read
   the registrant's reportable segments and operating structure.
2. Cross-check against the **shared KPI inventory** for the matching revenue
   series — segment names appear inside the KPI strings (e.g. `Net sales -
   <Segment> - Annual`, `Revenue - <Segment> - Annual`, `<Segment> net sales -
   Annual`, `<Banner> revenue - Annual`). Pull each via `search_kpis` against the
   shared inventory (do **not** re-run `list_kpis`).
3. **Retail reports revenue under more cuts than any other vertical** — reportable
   segment, **banner / brand**, **channel** (retail stores vs. e-commerce /
   digital vs. wholesale vs. licensing), and **geography** are all common, and a
   single 10-K often shows two or three of them. Pick the **primary
   reportable-segment** cut the 10-K uses for its segment footnote, and record the
   choice, with the cuts set aside, in `BUILD_LOG.md`. **Do not build the same
   revenue twice under two different cuts** — that
   double-counts the top line, and the §2 foot-check will not catch it if both cuts
   individually foot.
   - *Tie-breaker:* if the segment footnote's cut is thin (e.g. one segment) but
     the issuer consistently reports a richer cut in MD&A that foots to the same
     total, prefer the richer cut and **say so** in `BUILD_LOG.md`. Choose
     one and only one.
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
bold + underlined at **base indent** (`indent=0`); the `Revenue from <Segment>` line is at
**`indent=1`** and **bold**; the `YoY %` and CAGR memo rows are at **`indent=2`** and
italic. Number formats follow each row's Col D tag (see "Number format and units" in the
conventions list above).

Those levels are set with `Alignment(indent=n)` — the cell's real indent
(`Alt, H, 6`) — **never** with leading spaces in the label. The whitespace in the
block layout above is diagram only; every stored `cell.value` begins at its first
non-space character.

### 1.4 — The formulas (cell-by-cell, per segment)

Row labels are the **plain Col C text**. "Prior col" = the period column
immediately to the left.

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Segment>` | | `(USD in <scale>)` | historicals: deepKPI **input** (reported segment revenue / net sales; green, hyperlinked). Projection: `= <prior col 'Revenue from <Segment>'> × (1 + <this col 'YoY %'>)` | `"Reported segment net sales (input) in history; prior × (1 + growth) in projections."` |
| `YoY %` | | `(%)` | base col: blank/dash; historical: `= <this col> ÷ <prior col> − 1`; projection: **driver** — red font + dashed border, seeded per **Projections (forecast years)** | `"Segment revenue growth, YoY. Projection: driver seeded at the guided growth where the issuer gives one, else the latest historical YoY, then held flat (see Projections)."` |
| `Memo: CAGR (window)` | | `(%)` | one cell: `= (<latest historical Revenue from <Segment>> ÷ <earliest historical Revenue from <Segment>>)^(1/n) − 1`, where **n** = number of YoY steps in the historical window (e.g. 3 for 4 years) | `"Historical CAGR across the window = (last ÷ first)^(1/n) − 1; anchor for the forward growth assumption."` |

- The **only deepKPI input** in a segment block is the historical
  `Revenue from <Segment>` cells; `YoY %` (historical) and the CAGR memo are
  **black live formulas**; `YoY %` (projection) is a **driver** (red font + dashed
  border).
- The projected `Revenue from <Segment>` cell uses the **same compounding recipe**
  as the sibling retail builds (`prior × (1 + growth)`), so the line is internally
  consistent across history and projection.
- Do **not** round revenue (it is a dollar figure); the CAGR memo and YoY rows are
  percentages.
- **A 53rd week distorts one year's growth.** If the router flagged a 52/53-week
  calendar and one historical year carries an extra week, the `YoY %` into and out
  of that year are both artifacts of the calendar, not of demand. Leave the
  formulas alone — they must keep reporting what actually happened — but add one
  Notes line: *"Revenue: FY<n> had 53 weeks; growth into and out of that year is
  distorted by about one week."* Keep it in mind when reading the CAGR memo (see
  §3.3). No note row goes inside the block.

### 1.5 — Pre-delivery checklist (Revenue by Segment)

- [ ] The italic note beneath the `REVENUE` header states the **segmentation
      used** (reportable segments / banner / channel / geography / single segment)
      and the **segment count**, citing `get_company_segments`.
- [ ] Only **one** segmentation cut is built — no revenue is double-counted across
      a segment cut and a channel or geography cut (§1.2 step 3).
- [ ] **One two-row block per reporting segment** (revenue + `YoY %`), in a
      stable, stated order; a company with k segments has **k** revenue lines and
      **k** YoY rows.
- [ ] Historical `Revenue from <Segment>` cells are deepKPI **inputs** (pale-green,
      hyperlinked); no hardcoded historical numbers.
- [ ] The fiscal-year column mapping is stated and every segment's values sit in
      the column their fiscal year owns (52/53-week retail calendars — see "Time
      scope").
- [ ] Each `YoY %` row is a **live formula** in history and a projection **driver**
      (red font + dashed border, seeded per the **Projections** section) in any
      projected column; the base column is blank/dash.
- [ ] A `Memo: CAGR (window)` cell is present per segment and is a **live formula**
      `(last ÷ first)^(1/n) − 1` with the correct **n**.
- [ ] Forward growth assumptions are **per segment** (not one blended company-wide
      rate) and are justified (segment CAGR + guidance).
- [ ] No store count, square-footage, or product-unit line has been introduced —
      this build is revenue-only (see the router-scope note at the top).
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
| `Memo: sum vs. reported total (must = 0)` *(only if reported total available)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <Total Revenue (this build)> − <reported consolidated total revenue (deepKPI input)>` | `"Foot check: summed segments less reported consolidated total; must be 0 (add a Corporate/Other or eliminations segment if not —)."` |

- `Total Revenue` gets the grand-total treatment (bold, SUM-BAR) and
  sits beneath the last segment block.
- If deepKPI exposes a **reported consolidated total revenue** series (in retail,
  `Total net sales` / `Total revenues`), pull it as an input **only** to feed the
  foot-check memo (it is not the driver — the driver is the segment sum). If the
  memo is **not 0**, the segments do not foot to the reported total — resolve via
  §3.2 before delivering.

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

## Section 3 — Single-segment, reconciliation, and retail wrinkles

### 3.1 — Single-segment / no segment disclosure

If the company reports **only one consolidated revenue line** (no segment
breakdown), build **one** segment block whose label is the company / sole
operating line (e.g. `Net sales`, `Revenue from Retail`, or the registrant's
single reportable segment name). `Total Revenue` then equals that one line. The
structure is identical — one revenue row, one `YoY %` row, one CAGR memo — and
Section 2's sum trivially reduces to the single segment.

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

### 3.3 — Retail wrinkles (carry them; do not let them change the structure)

The router's Step 2.1 may have flagged any of the following. **None of them adds a
new mechanic to this build** — it stays a per-segment CAGR — but each changes what
you put on a line or how you read the growth:

- **Membership / fee income** (club and warehouse retailers). This is a distinct
  revenue stream with economics nothing like merchandise sales. If the issuer
  reports it separately, give it **its own segment block** rather than folding it
  into a merchandise segment; its growth rate is genuinely different and the mix
  matters downstream.
- **Channel revenue that the segment cut already contains.** If the chosen cut is
  by channel (retail / digital / wholesale / licensing), those blocks *are* the
  segments — do not also add a channel block on top of a banner cut (§1.2 step 3).
- **53rd week.** On a 52/53-week fiscal calendar an extra week inflates one year's
  net sales and therefore two consecutive `YoY %` cells. The Notes line of §1.4
  names the year. When seeding the projection driver, consider whether `N` is that year — if it is, seed the growth driver from the issuer's 52-week figure where disclosed, else from `N−1`, and say so in the driver's comment.
- **Foreign-currency impact.** Reported segment revenue for international fleets
  is in USD and mixes volume with FX. If the issuer reports a constant-currency or
  FX-impact line, keep it as an **informational memo row** beneath the affected
  segment (italic, formula or input as appropriate) — do **not** build a separate
  FX-adjusted revenue engine.
- **Company-operated vs. franchised / licensed revenue.** These are different
  revenue types from the same brand. If the chosen cut separates them, they are
  simply two segment blocks with their own growth rates — which is exactly what
  this build wants.

In every case: add the Notes line, the memo row or the extra block, keep the identity
`Σ segments = Total Revenue`, and **do not introduce a driver that is not a
`YoY %`**.

### 3.4 — Pre-delivery checklist (reconciliation and wrinkles)

- [ ] Single-segment companies get **one** segment block; `Total Revenue` equals
      that line.
- [ ] If disclosed segments don't tie to the reported total, a `Corporate / Other`
      or `Intersegment eliminations` block is added as a **plug** so the sum foots.
- [ ] No revenue is **double-counted** (only one segmentation cut is built — §1.2).
- [ ] Membership / fee income, if separately reported, sits on its **own** block,
      not inside a merchandise segment.
- [ ] Any 53rd-week flag from the router is captured as a Notes line (§1.4) and any
      FX flag as a memo row — not as a new engine — and the `YoY %` formulas are
      unchanged.
- [ ] **Indentation across the whole build is real cell indent**, not padding:
      every Col C label satisfies `value == value.lstrip()`, and each row's level
      is carried by `Alignment(indent=n)` (`Alt, H, 6`) — segment header
      `indent=0`, `Revenue from <Segment>` `indent=1`, `YoY %` and CAGR memo
      `indent=2`. Sweep the sheet programmatically before delivering.
- [ ] Applying the indent **preserved** each cell's existing `horizontal` /
      `vertical` alignment (no bare `Alignment(indent=n)` that wipes the rest).

---

## Section 4 — Worked example (illustrative)

A two-segment retailer on a FY2022 (base) → FY2025 window. Figures illustrative
(the actual build pulls every historical from deepKPI and lets the formulas
compute growth, CAGR, and the total); $ thousands.

**Section 1 — segment net sales (deepKPI inputs in history):**

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Revenue from Direct-to-Consumer | | `(USD in millions)` | 3,200 | 3,520 | 3,890 | 4,300 |
| YoY % | | `(%)` | — | +10.0% | +10.5% | +10.5% |
| Memo: CAGR (window) | | `(%)` | | | | **+10.3%** *(=(4,300 ÷ 3,200)^(1/3) − 1)* |
| Revenue from Wholesale | | `(USD in millions)` | 2,100 | 2,040 | 1,960 | 1,900 |
| YoY % | | `(%)` | — | −2.9% | −3.9% | −3.1% |
| Memo: CAGR (window) | | `(%)` | | | | **−3.3%** *(=(1,900 ÷ 2,100)^(1/3) − 1)* |

**Section 2 — total (sum of segments):**

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| **Total Revenue** = Σ segments | | `(USD in millions)` | **5,300** | **5,560** | **5,850** | **6,200** |
| YoY % | | `(%)` | — | +4.9% | +5.2% | +6.0% |
| Memo: sum vs. reported total (=0) | | `(USD in millions)` | 0 | 0 | 0 | 0 |

**Projecting FY2026** (illustrative): grow each segment by its own driver, seeded to
its latest historical change — Direct-to-Consumer +10.5% → 4,300 × 1.105 = 4,751.5;
Wholesale −3.1% → 1,900 × 0.969 = 1,841.1; **Total Revenue =
4,745.1 + 1,837.7 = 6,582.7** (USD in millions; the sum of the grown segments, not a
separate top-level growth). Note that one segment compounds up while the other
shrinks — exactly why each carries its own driver, and exactly the mix shift a single
blended company-wide rate would erase.

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
- **A declining segment stays declining.** Retail routinely has a shrinking channel
  or banner alongside a growing one. If the latest-year seed is **negative**, leave
  it negative — do not floor it at zero and do not "fade" it toward the company
  average. The modeler overrides it if they disagree.
- **53rd-week caveat (§3.3).** If `N` is the 53rd-week year, seed from the
  issuer's 52-week figure where disclosed, else from `N−1`, and say so in the
  driver's comment. The Notes line of §1.4 already names the year.

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
- **Sanity on the total.** Projected `Total Revenue` `YoY %` should land inside the
  range of the segment drivers, weighted by mix. If it sits outside that range, a
  segment sum or a driver reference is wrong — find it before delivering.

## Section 5 — What the revenue build produces for downstream sections

After Sections 1 – 2 are built, the workbook contains, for every period in the
window, a fully-footed revenue build beneath the `REVENUE` header: one
`Revenue from <Segment>` line (plus `YoY %` and a CAGR memo) per reporting
segment, and a `Total Revenue` line equal to their sum (with a `YoY %` and a
foot-check against any reported consolidated total). Every non-input cell is a
live formula, so any later change to a segment input or a forward growth
assumption propagates automatically into the total and keeps the foot intact.

Because the location gate FAILED, the workbook carries **no store roll-forward** —
downstream sections must not expect store counts, square footage, or per-unit
lines from the REVENUE section. State this in the hand-back so costs and
consolidated-financials do not attempt per-store drivers.

Hand back to the retail router (`../retail.md`), which will report the build
method (**other**) and the failed location gate up to the parent revenue router.
Downstream operating-model sections (costs, consolidated financials) reference
`Total Revenue` and the segment lines directly.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's bare-bones per-segment CAGR lines; all non-revenue sections are
owned by their respective skills.*
