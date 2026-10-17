---
name: revenue-retail-sqft-build
description: >
  Square-footage / revenue-per-location build for retail companies in the
  operating-model workbook. Invoked by the retail router
  (`revenue/retail/retail.md`) when the LOCATION GATE has PASSED but the company
  qualifies for neither the comparable-stores build (A) nor the units build (B) —
  so revenue is driven off the store fleet itself. The store roll-forward is laid
  down separately by `locationBuild/locationBuild.md` before this build runs, so
  this build is responsible only for the square-footage and revenue lines and
  references the EOP store counts already in the workbook. Runs in one of two
  modes: MODE A (preferred) drives in-store revenue off **implied average revenue
  per square foot** × total square footage, where total square footage is itself
  driven off the projected store count; MODE B (fallback, when no usable square
  footage exists) drives it off **implied revenue per store** × store count.
  Non-store revenue streams (digital, wholesale, licensing, franchise, membership)
  are NOT modeled per square foot — each gets its own block projected off its own
  year-over-year growth. A Consolidated Revenue block sums in-store revenue and the
  streams to Total Revenue. Pulls series via `search_kpis` from the shared
  inventory; format per ../../../../_common/revelata-excel-styling-rules.md (one row
  per series, derived cells as live formulas) EXCEPT for time scope (last 4 fiscal
  years), which this build overrides. Sections: §0 mode gate, §1 square footage,
  §2 store economics, §3 other revenue streams, §4 consolidated revenue, §5
  multi-banner, §6 worked examples, projections, §7 downstream handoff.
---

# revenue — retail — square-footage / revenue-per-location build

This is the **square-footage** retail revenue build. It is invoked by the retail
router (`../retail.md`) when the **Step 1 location gate PASSED** but the company
qualifies for neither the comparable-stores build (A) nor the units build (B).
The company has a store fleet and a revenue line, and that is enough: revenue is
driven off the fleet. It is the **third-tier** revenue build — coarser than a
comparable-store bridge or product-level unit economics, finer than a top-down
revenue CAGR.

By the time control reaches this build, the **store roll-forward has already been
laid down** in the workbook by `../locationBuild/locationBuild.md` (the router
invokes it before routing). **This makes the build relatively straightforward:**
the fleet schedule is the hard part and it already exists, forecast through
`N+5`. This build is responsible only for the **square-footage and revenue**
lines and **references the EOP store counts already present** — it does not
rebuild the store roll-forward.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook (with the store roll-forward already laid
down and projected), the **shared KPI inventory** from the orchestrator, the
router's note that the **location gate PASSED** and that builds A and B were not
satisfied, plus the location build's hand-back report (block level, flow tier,
whether a Franchised & Licensed roll exists, and any 10-K override cells).

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
build with the **xlsx** skill. All conventions there apply here — one row per
distinct series, deepKPI-sourced values as pale-green hyperlinked input cells,
and **every** total / derived cell as a live `=` formula (never a hardcoded
number) — **except** for the **time scope**, which this build overrides per the
"Time scope" section below.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped.
  This matches the location build so every revenue cell sits directly under the
  matching store-count cell.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (§1 – §6),
  then **extends the entire build into the projection window** following the
  **Projections (forecast years)** section near the end of this file. Do not
  fabricate projection values outside that procedure.
- **The build is ANNUAL**, on the **same annual columns the location build used**.
  Do not add quarterly columns.

> **Use the location build's fiscal-year mapping — do not re-derive it.** The
> location build already resolved the retail 52/53-week calendar problem (deepKPI
> date stamps are inconsistent between issuers *and between series within one
> issuer*). Read that mapping off the workbook's existing columns and write every
> revenue and square-footage value into the column its fiscal year already owns.
> **Re-deriving the mapping here is how revenue ends up one column off its store
> count**, which corrupts every per-unit figure in the build while still looking
> plausible. See §2 of `../locationBuild/locationBuild.md`.

> This build is authored section by section. The sections present here — §0 the
> mode gate through §7 the downstream handoff, plus the **Projections (forecast
> years)** section that extends the build into `N+1 … N+5` — are the implemented
> scope. Do not build or add any new information outside the sections present here.

---

## Framework overview

This build turns the **store fleet** already in the workbook into **revenue
dollars** and foots to the company's **reported total revenue**. It follows one
fixed framework so that every square-footage company is modeled the same way and
the workbook always foots.

### The two modes

There are exactly two ways to drive revenue off a fleet, and the choice is made
once, in §0:

| | **Mode A — revenue per square foot** (preferred) | **Mode B — revenue per location** (fallback) |
|---|---|---|
| **Requires** | usable **total square footage**, *or* **average square footage per store** (from which total square footage is computed) | store count only — always available, since the location gate passed |
| **Primary driver** | `Implied Average Revenue per Square Foot` | `Implied Revenue per Store` |
| **Revenue engine** | `In-Store Revenue = Total Square Footage × Revenue per Square Foot` | `In-Store Revenue = Revenue per Store × Company-Operated EOP Store Count` |
| **How growth enters** | new stores add square footage (via the projected store count × average square footage per store), and revenue per square foot grows on its own driver | new stores add store count, and revenue per store grows on its own driver |
| **§1 Square Footage block** | present | **omitted entirely** |

**Always attempt Mode A.** Fall back to Mode B only after the §0 discovery has
actually run and come up empty. Square footage is the better denominator because
it separates *fleet expansion* from *format change* — a retailer shrinking its
average store while growing its store count is invisible to a revenue-per-store
model and obvious in a revenue-per-square-foot one.

### The master identity

The build decomposes reported total revenue into the modeled store engine plus
one block per non-store revenue stream:

```
  In-Store Revenue            (§2 — the square-footage / per-location engine)
+ Revenue from Stream 1       (§3 — e.g. digital, projected on its own growth)
+ Revenue from Stream 2       (§3 — e.g. wholesale / licensing / franchise / membership)
+ …
─────────────────────────────────────────
= Total Revenue               (§4 — the foot)
```

The components **sum to reported Total Revenue exactly, by construction** in the
historical columns (§3.3 specifies which line absorbs the residual), and
`Total Revenue` is the assembled sum in the projection columns. That identity is
the build's foot and must hold in every period.

**Non-store revenue is never modeled per square foot.** Digital, wholesale,
licensing, franchise and membership dollars are not produced by the company's
selling floor; running them through a revenue-per-square-foot driver inflates the
apparent productivity of the fleet and makes the driver unfalsifiable. Each gets
its own block and its own growth assumption (§3).

### Conventions that apply to all sections (read once)

- **Reference the location build — do not re-derive counts.** Every store count
  this build needs already exists in the workbook (the EOP balances in the store
  roll-forward, historical *and* projected). Reference those cells with live `=`
  formulas; never hardcode a count or rebuild the fleet schedule.
- **Universe consistency — the rule this build fails on most often.** The
  numerator, the denominator and the fleet must describe the **same** stores:
  **company-operated** revenue ÷ **company-operated** square footage ÷
  **company-operated** EOP store count. Franchised and licensed stores are *not*
  the company's square footage and their sales are *not* the company's revenue —
  the fee income they generate is an **other revenue stream** (§3), never part of
  In-Store Revenue. Mixing universes silently corrupts every per-unit figure in
  the build. State the universe in a Col C comment and one Notes line: *"Revenue:
  store economics are on company-operated stores; franchise and license fee income
  is a separate stream."*
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI are **input cells** (pale-green fill,
  dark-blue hyperlinked value linked to the filing). **Every other cell is a live
  `=` formula** (black font, no fill). Projection **drivers** are red font +
  dashed border, seeded per the **Projections (forecast years)** section — they
  are neither green inputs nor plain black formulas. Never hardcode a computed
  number.
- **Label / comment / spacing discipline.** Col C labels are **plain descriptive
  text**; the operand recipe for each formula row goes in a **cell comment on the
  Col C label cell** (author `Revenue Build`), not in the visible label.
  Indentation, bold / border, and the one-blank-row-between-blocks rule follow
  `../../../../_common/revelata-excel-styling-rules.md` — including its
  **Indentation — real cell indent, never leading spaces** rule, restated below.
- **Indent mapping — real cell indents, never leading spaces.** "Indent once" =
  **`Alignment(indent=1)`** on the Col C cell; "indent twice" = **`indent=2`**.
  These are the cell's **actual indent property** — the openpyxl equivalent of
  Excel's **Home → Increase Indent** (`Alt, H, 6`) — and are applied with
  **no leading spaces in the label string**. Padding a label with spaces is
  prohibited: the block-header underline (`Font(underline="single")`) draws under
  the padding characters and produces a ragged rule running left of the text, the
  padded label breaks `MATCH` / `VLOOKUP` against it, and the spaces are invisible
  in the Excel UI so the user can neither see nor fix them. When setting a cell's
  `Alignment`, **keep the existing `horizontal` / `vertical` settings and add
  `indent=n`** — do not replace the whole `Alignment` object, and do not prepend
  spaces:

  ```python
  # right
  c = ws["C12"]; c.value = "Total Square Footage"     # no padding in the string
  a = c.alignment
  c.alignment = Alignment(horizontal=a.horizontal, vertical=a.vertical, indent=1)

  # wrong
  c.value = "  Total Square Footage"                  # leading spaces — prohibited
  ```

  The block headers in the layout below (`Square Footage`, `Store Economics`,
  `Consolidated Revenue`, each other-stream name) sit at **indent once — the same
  level as their own line items** — **bold and underlined**. A header is set apart
  by the bold + underline, **not** by a deeper or shallower indent than the rows it
  heads. They are sub-headers beneath the `REVENUE` ALL-CAPS header, not ALL-CAPS
  headers themselves, so they do **not** take the 16pt treatment.

  **The ASCII row map below draws the hierarchy with spaces for legibility only.**
  Those spaces are diagram, not data — read each row's `← indent once` / `← indent
  twice` annotation and apply it with `Alignment(indent=n)`.
- **Number format and units.** Storage, the number-format strings, and the tag
  grammar come from `../../../../_common/revelata-excel-units-and-scale.md`, and every
  row's family follows from that file's Rule 4 — an input row's from its deepKPI `unit`
  field, a derived row's from the dimensions of its formula. **The Col D tag for every
  row this build writes is shown in the row maps under "The row layout
  (authoritative)" below**, immediately after each row's formatting annotation, and in
  the `Units (Col D)` column of the §1–§4 formula tables. Money rows there show the
  placeholder `(USD in <scale>)`: the contract's Rule 2 supplies the scale — millions
  by default, thousands where the digit test puts a small filer.
  This build makes three scale decisions of its own:
  - **`Implied Revenue per Store` → `(USD millions per store)`.** Revenue displays in
    millions and the store count in ones, so revenue ÷ stores comes out in millions
    per store; displaying it so lets a reader divide the two rows above and land on
    this one.
  - **`Total Square Footage` → `(sq ft in millions)`, because the Mode A driver depends
    on it.** `Implied Average Revenue per Square Foot` is quoted in plain dollars; for
    revenue in millions to divide to plain dollars on the page, square footage must
    also be in millions (e.g. revenue `11,669` ÷ `82.0` million sq ft = `142` USD per
    sq ft). Keep millions even when a small-format retailer's total reads in low single
    digits (`2.0`) — the digit test yields to the driver here. In Mode B the
    `Square Footage` block is omitted and this decision does not arise.
  - **`Average Square Footage per Store` → `(sq ft per store)`, a declared coherence
    departure.** Because square footage is in millions and the store count in ones,
    this row does not reconcile on the page (`82.0 ÷ 1,170 = 0.070`, not `70,085`).
    Analysts quote it in plain square feet, so keep that and record in its Col C
    comment: *"Displayed in plain square feet by convention; the operands are in
    millions and ones, so this row does not reconcile on the page. The formula divides
    base-unit values and is exact."*
  - `YoY %` rows are an **italic label + italic data** accounting-style
    percent row per the styling rules.

---

## The row layout (authoritative)

Lay the rows in exactly this order beneath the store roll-forward the location
build produced. This layout is the specification — do not reorder it, do not add
rows outside it, and do not drop the memo rows.

**Read `← indent once` / `← indent twice` as `Alignment(indent=1)` /
`Alignment(indent=2)` on the Col C cell.** The whitespace inside the block below is
there to draw the hierarchy on the page; **no label is ever written with leading
spaces**.

**Each row's annotation has three columns, left to right:** the Col C formatting
after the `←` (indent, bold, underline, sum bar); the **Col D units tag in
parentheses** — `(USD in <scale>)` means the contract's Rule 2 sets the money scale,
every other tag is written as it goes in the cell; and the formula or note in
**square brackets** — `[= …]` is the cell formula, `[MODE A ONLY]` is a note, never a
tag. Block headers carry no tag.

```
[ store roll-forward — already laid down by locationBuild.md ]
[ … ]

  Square Footage                              ← indent once, BOLD, UNDERLINED                              [MODE A ONLY — omit the whole block in Mode B]
    Total Square Footage                      ← indent once                     (sq ft in millions)
    Average Square Footage per Store          ← indent once, BOLD               (sq ft per store)          [= Total Square Footage ÷ Company-Operated EOP Store Count]

  Store Economics                             ← indent once, BOLD, UNDERLINED
    Company-Operated EOP Store Count          ← indent once                     (locations)                [= location build's Company-Operated EOP Balance, same banner, same column — live reference, never re-entered]
    Implied Revenue per Store                 ← indent once                     (USD millions per store)   [= In-Store Revenue ÷ Company-Operated EOP Store Count]
    Implied Average Revenue per Square Foot   ← indent once, BOLD               (USD per sq ft)            [= In-Store Revenue ÷ Total Square Footage]   [MODE A ONLY]
      YoY %                    ← indent twice, BOLD              (%)                        [historical: derived · projection: DRIVER]
    In-Store Revenue                          ← indent once, BOLD, TOP SUM BAR  (USD in <scale>)           [= Total Square Footage × Revenue per Square Foot]
    Memo: rev/store cross-check               ← indent once, italic             (USD millions per store)   [= Avg Sq Ft per Store × Rev per Sq Ft − Rev per Store; must = 0]   [MODE A ONLY]

  <Stream Name>                               ← indent once, BOLD, UNDERLINED  (block header = the stream's name)
    <the issuer's caption>                    ← indent once                     (% of net sales)           [percentage-derived stream only (§3.2): deepKPI INPUT in history; dash forward]
    Revenue from <Stream Name>                ← indent once                     (USD in millions)
      YoY %                    ← indent twice                    (%)                        [historical: derived · projection: DRIVER]

  <Stream Name 2>                             ← one block per stream, same shape
    Revenue from <Stream Name 2>
      YoY %

  Consolidated Revenue                        ← indent once, BOLD, UNDERLINED
    In-Store Revenue                          ← indent once                     (USD in <scale>)           [= §2 In-Store Revenue]
    Revenue from <Stream>                     ← indent once                     (USD in <scale>)           [= that stream's row, same label; one row per stream inside net sales]
    Net Sales                                 ← indent once, BOLD, TOP SUM BAR  (USD in <scale>)           [= In-Store Revenue + Σ streams inside net sales]   [ONLY when the issuer reports a separate revenue face line]
    Net Sales (reported)                      ← indent once                     (USD in <scale>)           [deepKPI input — pale-green, hyperlinked, visible; historical only; the §2.1 residual reads it]   [ONLY with Net Sales]
    Revenue from <Stream>                     ← indent once                     (USD in <scale>)           [= that stream's row, same label; one row per face-line stream]
    Total Revenue                             ← indent once, BOLD, TOP SUM BAR  (USD in <scale>)           [= Net Sales + Σ face-line streams; or In-Store Revenue + Σ streams when no Net Sales row]
    Total Revenue (reported)                  ← indent once                     (USD in <scale>)           [deepKPI input — pale-green, hyperlinked, visible; historical only; the §2.1 residual reads it]
    Memo: Total − Reported (must = 0)         ← indent once, italic             (USD in <scale>)           [wiring check; historical only]
```

**In Mode B**, the `Square Footage` block is omitted entirely and the
`Store Economics` block loses two rows — the per-square-foot driver and its
cross-check memo:

```
  Store Economics                             ← indent once, BOLD, UNDERLINED
    Company-Operated EOP Store Count          ← indent once                     (locations)                [= location build's Company-Operated EOP Balance, same banner, same column — live reference, never re-entered]
    Implied Revenue per Store                 ← indent once, BOLD               (USD millions per store)   [= In-Store Revenue ÷ Company-Operated EOP Store Count]
      YoY %                    ← indent twice, BOLD              (%)                        [historical: derived · projection: DRIVER]
    In-Store Revenue                          ← indent once, BOLD, TOP SUM BAR  (USD in <scale>)           [= Revenue per Store × Company-Operated EOP Store Count]
```

Note the promotion: in Mode A, `Implied Revenue per Store` is a **diagnostic**
(plain weight, no `YoY %` row of its own) and
`Implied Average Revenue per Square Foot` is the **driver base** (bold, carries
the `YoY %` row). In Mode B, `Implied Revenue per Store` **becomes**
the driver base and takes the bold and the `YoY %` row.

**Forward references are expected and correct.** `Implied Revenue per Store` and
`Implied Average Revenue per Square Foot` reference `In-Store Revenue`, which sits
below them. That is deliberate — it puts the driver above the line it produces, so
the block reads top-to-bottom as *inputs → driver → revenue*. Excel resolves
forward references without complaint.

---

## Section 0 — The mode gate (choose Mode A or Mode B)

Decide the mode **before** laying down a single row, and state the decision in one
auditable line.

### 0.1 — Exhaustively search the FULL inventory for square footage (MANDATORY — do not rush)

Square footage is the difference between a good build and a coarse one, and retail
square-footage series hide under naming that does not contain the word "square" in
an obvious place. **If a usable square-footage series exists, there is no
acceptable reason to miss it.**

1. **Use the COMPLETE inventory, not a sample.** Scan **all** of the shared
   inventory across **every** category. If it was saved to a file, **parse / grep
   the whole file**. Do not skim, and do not substitute your recollection of what
   the company "typically" discloses.
2. **Hunt for both families.** Either one is sufficient for Mode A:
   - **Total square footage:** `Total square footage`, `Gross square feet`,
     `Selling square footage`, `Selling square footage at end of period`,
     `Total Company-Operated Store Square Footage at End of Period`,
     `Total Selling Square Footage at End of Period for <Segment>`,
     `<Banner> Selling Square Footage at End of Period`, `Selling space`,
     `Square footage of retail space`.
   - **Average square footage per store:** `Average square feet per store`,
     `Approximate average store size`, `<Banner> Approximate Average Store Size`,
     `Average selling space per store`, `Average selling square feet`,
     `Average store size`.
3. **Also find, but do not use as the driver:** directly reported
   `Sales per square foot`, `Average sales per square foot`,
   `Net sales per square foot`. These are the **cross-check** in §2.4 — never the
   driver, because the issuer computes them on its own (often average-of-period)
   denominator and its own revenue numerator.
4. **Exclude the decoys before you count a hit** (see §0.2).
5. **Only after this full scan comes up empty**, or after every candidate fails
   the §0.3 plausibility test, may you conclude square footage is unavailable. In
   the §0.4 audit line, state the **exact tokens you searched** and which returned
   hits vs. no series — so "not found" is verifiable, never a guess.

### 0.2 — Square-footage decoys (none of these satisfy the gate)

Retail inventories carry a great deal of square footage that is **not** selling
floor. Counting any of it as store square footage inflates the denominator and
deflates revenue per square foot:

- **Distribution / fulfillment center square footage.** TJX files
  `Owned Distribution Center Square Footage for <Segment>`,
  `Leased Distribution Center Square Footage for <Segment>` and
  `Total Distribution Center Square Footage Company-wide` right beside store
  square footage. Dollar General files
  `Total leased square footage of additional warehouse space supporting the
  distribution network`. **Never** in the store denominator.
- **Corporate and office square footage.** Dollar General files
  `Total square footage of owned executive office buildings in Goodlettsville,
  Tennessee` and `Total leased square footage of additional office space outside
  the United States`. Not selling floor.
- **Square footage of the *franchised* fleet**, where reported — a different
  universe (see the universe-consistency rule).
- **Per-new-store footprint series** such as DG's
  `Average square feet of selling space for new Standard and Large Format store
  openings`. This is the footprint of *newly opened* stores, not the fleet
  average. It is a useful sanity input for the projection driver (§Projections
  Part 1) but it is **not** the fleet's average square footage and must not be
  used as one.
- **Growth percentages wearing a square-footage label** — see §0.3, which is the
  reason this test exists at all.

### 0.3 — The magnitude test (a candidate is not square footage until it passes)

**Every square-footage candidate must be divided by the store count before it is
believed.** deepKPI square-footage series are frequently mis-extracted, and the
`unit` field does not protect you:

- **A correct `unit` tag does not make a series square footage.** TJX's
  `Selling square footage in the consolidated TJX retail operations` carries
  `unit: "square feet"` and returns **5, 4, 4, 2, 3** across recent fiscal years.
  TJX operates **5,214** stores. Three square feet across five thousand stores is
  absurd — the series is the *percentage growth* in selling square footage,
  mis-extracted into a series labeled and unit-tagged as an absolute level.
- **A blank `unit` tag does not make a series wrong.** The Gap, Inc.'s
  `Total Company-Operated Store Square Footage at End of Period` carries an
  **empty** `unit` field and returns `29600000`, `30100000`, `30600000` — which
  divided by its 2,474 / 2,506 / 2,562 stores gives ≈**12,000 sq ft per store**,
  entirely plausible for that fleet. The series is good; the metadata is just
  missing.
- **Scale ambiguity.** Filings report square footage in units, thousands, or
  millions. A total that implies 12 sq ft per store is a thousands-scaled series;
  one that implies 12,000,000 is a units/millions confusion. Resolve against the
  filing, never by guessing a divisor.

**The test:** compute `candidate ÷ company-operated EOP store count` and require
the result to land in a plausible retail range — roughly **1,000–200,000 sq ft per
store** depending on format (convenience / small-box ≈ 1,000–10,000; specialty
apparel ≈ 3,000–20,000; off-price and big-box ≈ 20,000–60,000; warehouse clubs and
home-improvement ≈ 100,000–200,000). Run it for **every** historical year, not
just the newest — a series can be clean at one end and corrupt at the other.

**If the consolidated candidate fails,** do not jump to Mode B. Try, in order:
(a) the **segment- or banner-level** square-footage series (they are often clean
when the consolidated roll-up is not); (b) the **average square footage per store**
family, which yields total square footage by multiplication; (c) the **10-K**
store-count-and-square-footage table directly, styled as a 10-K override input.
Mode B is reached only when all three fail.

**This test is the reason `Average Square Footage per Store` is a visible row in
the layout.** It is not decoration — it is the trap detector, permanently on
screen, in every column.

### 0.4 — State the decision

Before building, record one line in `BUILD_LOG.md` (the hand-back report carries
the same): the **mode chosen**, the **specific series** that satisfied (or failed)
the square-footage gate, the **per-store magnitude** it implies, whether the
footage is **selling** or **gross**, the **universe** (company-operated), and the
candidates rejected. The basis and the universe also go to the Notes block in
analyst words (§7); the mode and the search history do not. Example shape:

> *Mode A. `Total Company-Operated Store Square Footage at End of Period`
> (29.6M sq ft FY2025) ÷ company-operated EOP stores (2,474) = 11,964 sq ft/store —
> plausible for this fleet. Basis: gross company-operated store square footage.
> Rejected `<X>` (distribution-center footage) and `<Y>` (failed magnitude test at
> 0.0006 sq ft/store).*

### 0.5 — Pre-delivery checklist (mode gate)

- [ ] The **full** inventory was scanned for both square-footage families, with
      the searched tokens recorded.
- [ ] Every candidate was run through the **magnitude test** in **every**
      historical year, not just the newest.
- [ ] Distribution-center, office, franchised-fleet and per-new-store footprint
      series were **excluded**, explicitly.
- [ ] **Selling vs. gross** square footage was chosen once and stated in the
      `Total Square Footage` cell comment and a Notes line ("Revenue: square footage
      is gross selling area as the issuer reports it"), never in the row label, which
      stays `Total Square Footage`; the two are never mixed across years or banners.
- [ ] Mode B was reached only after segment-level series, the average-per-store
      family, **and** the 10-K table all failed.
- [ ] The §0.4 decision line is stated and auditable.

---

## Section 1 — Square Footage (Mode A only)

**Omit this entire block in Mode B** — no empty rows, no placeholder.

### 1.1 — The logic and the two historical paths

Total square footage and average square footage per store are locked by

```
  Total Square Footage = Average Square Footage per Store × Company-Operated EOP Store Count
```

so **one of the two is the deepKPI input and the other is the formula.** Which is
which depends on what the issuer reports — and it **inverts in the projection
columns**, where both paths converge. Get this right; it is the most confusable
part of the build.

| | **Total Square Footage** | **Average Square Footage per Store** |
|---|---|---|
| **Path 1 — total square footage reported** (Gap, TJX) | deepKPI **input** (pale green, hyperlinked) | **formula** `= Total Sq Ft ÷ Company-Operated EOP Store Count` |
| **Path 2 — only average per store reported** (Dollar General) | **formula** `= Avg Sq Ft per Store × Company-Operated EOP Store Count` | deepKPI **input** (pale green, hyperlinked) |
| **Projection columns — both paths** | **formula** `= Avg Sq Ft per Store × Company-Operated EOP Store Count` | **DRIVER** (red font, dashed border) |

**Path 1 is preferred** when both are available: a reported total is a measured
quantity, whereas a reported average is usually a rounded approximation ("our
stores average approximately 7,500 square feet") that will not multiply back to
the exact total. If both are reported, take the total as the input and let the
average fall out as the formula — then check the computed average against the
reported one and note any gap.

**Row order does not change with the path.** `Total Square Footage` sits above
`Average Square Footage per Store` in both, exactly as the layout specifies; only
the styling of the two cells swaps.

### 1.2 — Layout and formula (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Total Square Footage` | | `(sq ft in millions)` | Path 1: deepKPI **input**. Path 2 and **all projection columns**: `= <Average Square Footage per Store> × <Company-Operated EOP Store Count>` | `"Company-operated store square footage, <selling\|gross> basis. <Input \| = average per store × stores>."` |
| `Average Square Footage per Store` | | `(sq ft per store)` | Path 1 historicals: `= <Total Square Footage> ÷ <Company-Operated EOP Store Count>`. Path 2 historicals: deepKPI **input**. **Projection: DRIVER** | `"Fleet-average footprint. Historical: <= total ÷ EOP stores \| reported>. Projection: driver — held at the last historical actual."` |

- `Company-Operated EOP Store Count` is laid **once**, at the top of the Store
  Economics block (§2.3), as a **live reference into the location build's
  Company-Operated EOP Balance** for the same banner and column — the company
  roll, never the franchised & licensed roll or the system total. The two
  formulas above reference that row (a forward reference into §2, which this
  build expects — see "The row layout"). Never re-enter the count.
- Both rows carry the **same** universe as the store count they divide by.

### 1.3 — Pre-delivery checklist (Square Footage)

- [ ] Exactly **one** of the two rows is a deepKPI input in the historical
      columns; the other is a live formula. No cell is both, and neither is
      hardcoded.
- [ ] The store count in the denominator/multiplier is a **live reference to the
      location build**, on the **company-operated** universe.
- [ ] `Average Square Footage per Store` lands in a plausible range in **every**
      historical column (the §0.3 magnitude test, now permanently visible).
- [ ] Where both a total and a reported average exist, Path 1 was used and the
      computed average was compared to the reported one, with any gap recorded in
      `BUILD_LOG.md`.
- [ ] The selling-vs-gross basis is named in the label and constant across all
      columns and banners.
- [ ] Square footage moves **consistently with the store count** — a fleet that
      shrank while square footage grew needs one Notes line (*"Revenue: square
      footage <grew while the fleet shrank> because of <a format change / a change
      in the reported basis>."*), or it is an error.

---

## Section 2 — Store Economics

This is the analytical core of the build. It derives the per-unit productivity
figure from history, projects it forward by a year-over-year growth driver, and
rebuilds in-store revenue from the driver and the fleet.

### 2.1 — Isolating In-Store Revenue (do this before any per-unit math)

`In-Store Revenue` must be the revenue **the company's own selling floor
produced** — not total revenue. Dividing *total* revenue by store square footage
contaminates the driver and double-counts once the streams are added back in §4.

Establish the numerator by the **first** of these that applies:

1. **Direct method — store-channel revenue is separately reported.** Use it as the
   deepKPI **input** (pale green, hyperlinked). Then §3 carries the other reported
   streams, and a final `Other Revenue` stream absorbs any residual so §4 foots.
2. **Residual method — the non-store streams are reported but store revenue is
   not.** This is the common case. `In-Store Revenue` becomes a **historical
   formula** (black, no fill):
   `= <Net Sales (reported)> − SUM(<the stream rows inside net sales>)` when
   the issuer reports a separate revenue face line (§3.1), else
   `= <Total Revenue (reported)> − SUM(<other revenue stream rows>)`.
   The foot then holds by construction. Streams that are their own face line
   (membership fees, a reported `Other revenue` line) are never inside this
   residual — that is what keeps it close to store net sales.
3. **Neither — no separate non-store stream is reported in dollars.** All of
   revenue is treated as in-store. `In-Store Revenue` is the reported total
   revenue deepKPI input, §3 is empty, and the Notes line of §2.5 **must** say so:
   *"Revenue: in-store revenue is total revenue, since no non-store channel is
   reported in dollars, so any digital or wholesale sales sit inside revenue per
   square foot."*

**In the projection columns, `In-Store Revenue` is always the modeled formula**
(`= Total Square Footage × Revenue per Square Foot` in Mode A;
`= Revenue per Store × Company-Operated EOP Store Count` in Mode B), regardless of which
historical method produced it. That switch is the build's central inversion — see
Projections Part 2.

> **There is no circularity here, and it is worth being explicit about why.** In
> the historical columns causation runs **revenue → per-unit figure**: In-Store
> Revenue is sourced (or residualized) first, and the per-unit figure is defined
> as revenue ÷ fleet. In the projection columns causation **reverses**: the
> per-unit figure is grown by its driver first, and revenue is defined as per-unit
> × fleet. The same row therefore carries a different formula in each half, which
> is expected. What is **not** acceptable is a historical column in which In-Store
> Revenue is written as `= sq ft × rev per sq ft` while `rev per sq ft` is written
> as `= In-Store Revenue ÷ sq ft` — that is a genuine circular reference and Excel
> will flag it. Check for it after building.

**Worked caution — Gap.** The Gap, Inc. reports company-operated store square
footage of 29.6M sq ft against total net sales of $15,366M, giving an apparent
**$519 per square foot**. That figure is not store productivity: Gap's net sales
include online sales (a large share of the total) and franchise/licensing revenue,
neither of which its selling floor produced. Carve the streams out first; the
honest in-store figure is materially lower. A revenue-per-square-foot driver built
on the contaminated number will look stable and be wrong.

### 2.2 — The logic

**Mode A:**

```
  Implied Avg Revenue per Sq Ft      = In-Store Revenue ÷ Total Square Footage        [historicals]
  YoY %               = (this year's Rev/SqFt ÷ prior year's) − 1      [historicals]
  Implied Avg Revenue per Sq Ft      = <prior year's Rev/SqFt> × (1 + YoY %)  [projection]
  In-Store Revenue                   = Total Square Footage × Implied Avg Rev per SqFt [projection]
  Implied Revenue per Store          = In-Store Revenue ÷ Company-Operated EOP Store Count       [both halves — diagnostic]
```

**Mode B:**

```
  Implied Revenue per Store          = In-Store Revenue ÷ Company-Operated EOP Store Count       [historicals]
  YoY %               = (this year's Rev/Store ÷ prior year's) − 1     [historicals]
  Implied Revenue per Store          = <prior year's Rev/Store> × (1 + YoY %) [projection]
  In-Store Revenue                   = Implied Revenue per Store × Company-Operated EOP Store Count [projection]
```

- **Derive (historicals):** compute the per-unit figure from sourced revenue and
  the fleet.
- **Trend:** compute its year-over-year growth. This rate is the key driver to
  project forward — anchor the forward assumption on the historical trend plus
  management guidance, pricing / inflation, comparable-sales commentary and any
  disclosed format change.
- **Project:** grow the per-unit figure forward by the assumed rate, then multiply
  by the projected fleet (square footage in Mode A, store count in Mode B) to
  rebuild In-Store Revenue. **New store openings in the location build flow
  straight through**: more stores → more square footage → more in-store revenue.

**Rigor note — EOP vs. average fleet.** This build uses the **EOP** store count
and EOP square footage. Revenue is earned across the period, so an EOP denominator
slightly **understates** per-unit productivity in an expanding fleet and
**overstates** it in a shrinking one. This is acceptable because the same EOP
basis is used to derive the historical figure, to trend it, and to rebuild
revenue — so the distortion largely cancels. It does **not** cancel against an
issuer's own reported sales-per-square-foot figure, which is usually computed on
an average denominator; see §2.4.

### 2.3 — Layout and formula (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Company-Operated EOP Store Count` | | `(locations)` | `= <location build's Company-Operated EOP Balance, same banner, same column>` — a live reference in every column, historical and projected; never an input, never a driver | `"EOP company-operated store count — referenced from the store roll-forward, not re-entered. The denominator of the per-store rows below."` |
| `Implied Revenue per Store` | | `(USD millions per store)` | `= <In-Store Revenue> ÷ <Company-Operated EOP Store Count>`. **Mode B projection:** `= <prior col> × (1 + <YoY %>)` | Mode A: `"Diagnostic: in-store revenue ÷ EOP company-operated stores. Ties to avg sq ft/store × rev per sq ft."` · Mode B: `"Driver base: in-store revenue ÷ EOP stores; projection compounds prior × (1 + p/p)."` |
| `Implied Average Revenue per Square Foot` *(Mode A only)* | DATA_DEPENDENT | `(USD per sq ft)` | historicals: `= <In-Store Revenue> ÷ <Total Square Footage>`; projection: `= <prior col> × (1 + <YoY %>)` | `"Rev/sq ft = in-store revenue ÷ total square footage; projection compounds prior × (1 + p/p)."` |
| `YoY %` | | `(%)` | historicals: `= <this col driver base> ÷ <prior col> − 1`; **projection: DRIVER** — red font + dashed border, seeded per **Projections** | `"Growth in <revenue per square foot \| revenue per store>, period over period."` |
| `In-Store Revenue` | | `(USD in <scale>)` | historicals: deepKPI **input** (direct method) **or** `= <Total Revenue (reported)> − SUM(<stream rows>)` (residual method); projection: Mode A `= <Total Square Footage> × <Implied Avg Revenue per Sq Ft>`, Mode B `= <Implied Revenue per Store> × <Company-Operated EOP Store Count>` | `"Company-operated store revenue. Historical: <reported input \| residual of total less streams>. Projection: <sq ft × rev/sq ft \| rev/store × stores>."` |
| `Memo: rev/store cross-check` *(Mode A only; italic)* | DATA_DEPENDENT | `(USD millions per store)` | `= <Average Square Footage per Store> × <Implied Average Revenue per Square Foot> − <Implied Revenue per Store>` | `"Must equal 0: (sq ft/store) × (rev/sq ft) ≡ rev/store."` |

- `Company-Operated EOP Store Count` is the one row every per-unit formula in §1
  and §2 divides or multiplies by, so the count is visible beside the figures it
  produces — the same shape as the restaurant builds' `Company-Operated EOP
  Restaurant Count` and the cost builds' `Company-Operated EOP location count`.
- The base (leftmost) historical column has no prior year, so its
  `YoY %` cell is **blank (dash)** — not zero.
- `In-Store Revenue` carries the **top sum bar** (thin top border) and bold, per
  the layout: it is the output of the block above it.
- The `Memo: rev/store cross-check` row is a **true check only under Path 1**
  (where total square footage and in-store revenue are independently sourced).
  Under Path 2 it is tautological — keep it anyway for consistency and add to the
  row's comment: *"Under derived total footage this check cannot fail."*

### 2.4 — Cross-check against the issuer's reported sales per square foot

Where the inventory carries a reported `Average sales per square foot` /
`Net sales per square foot` series, compare it to your implied figure. **Do not
substitute it for the driver** — use it to validate the build:

- **A close match validates the whole chain** — numerator universe, denominator
  basis, fiscal-year alignment and scale are all consistent with the issuer's own
  computation.
- **A gap of a few percent is expected and benign** where the issuer uses an
  **average-of-period** square-footage denominator and you use EOP. In a growing
  fleet your implied figure will run **above** the reported one; in a shrinking
  fleet, below.
- **A gap of tens of percent, or an order of magnitude, is a defect** — almost
  always a contaminated numerator (§2.1), a wrong universe, a selling-vs-gross
  mismatch, or a scale error. Fix it before proceeding.

Record the comparison and its result in `BUILD_LOG.md` (the hand-back report
carries the same), not in the Notes. Do **not** add the reported series as a row
in the build — it is a diagnostic, not a line item.

### 2.5 — Pre-delivery checklist (Store Economics)

- [ ] `In-Store Revenue` numerator was established by §2.1 and the method is
      stated in the row's comment **and** in one Notes line: *"Revenue: in-store
      revenue is <the reported store line / total revenue less <channels> / total
      revenue, since no non-store channel is reported in dollars, so any digital or
      wholesale sales sit inside revenue per square foot>."*
- [ ] Numerator, denominator and fleet are all on the **company-operated**
      universe; franchise/license fee income is **not** in In-Store Revenue.
- [ ] The per-unit figure is computed for **every** historical column and its
      `YoY %` trend is visible in its own row, blank in the base
      year.
- [ ] The forward `YoY %` is a projection **driver** (red font +
      dashed border, seeded per the **Projections** section) that is justified
      (trend, guidance, pricing/inflation, format change), not an unexplained
      number.
- [ ] `In-Store Revenue` uses the **modeled formula** in every projection column
      and the **sourced/residual** value in every historical column — and there is
      **no circular reference** (§2.1).
- [ ] Mode A: `Memo: rev/store cross-check` evaluates to **0** in every column.
- [ ] Mode A: the implied revenue per square foot was compared to any reported
      sales-per-square-foot series, with the result and its direction recorded in
      `BUILD_LOG.md` (§2.4).
- [ ] After recalculation (LibreOffice / the xlsx skill's `recalc.py`), there are
      **zero formula errors**.

---

## Section 3 — Other revenue streams

One block per genuine non-store revenue stream, each projected on its **own**
growth — never through the square-footage or per-store engine.

### 3.1 — What qualifies as a stream (and what is a decomposition)

A line qualifies as an other revenue stream only if **both** tests pass:

1. **It is revenue the company's selling floor did not produce.** Ask: *would this
   dollar still exist if the fleet's square footage were zero?* Digital orders,
   wholesale shipments, licensing royalties, franchise fees and membership dues
   pass. Merchandise sold across the counter does not.
2. **It is separately reported in dollars, as its own revenue line** — not as a
   share of an existing line.

**Qualifying streams (typical retail):** e-commerce / digital / online net sales ·
wholesale net sales · licensing and royalty revenue · **franchise revenue**
(royalties + initial fees — the franchised fleet is not the company's square
footage, so its fee income belongs here) · membership / fee income (club and
warehouse formats) · credit-card and financial-services income · gift-card
breakage and other miscellaneous revenue.

**Decompositions — these are NOT streams, and adding them double-counts
in-store revenue:**

- **Merchandise category splits.** Dollar General files
  `Net Sales from Consumables Merchandise Category - annual`,
  `Net Sales from Seasonal Category`, `Net Sales from Home Products`,
  `Net Sales from Apparel`. These partition the *same* in-store net sales by what
  was sold. Carrying them as streams would count DG's revenue twice.
- **Geography splits of the same fleet** (`Net sales in the United States`,
  `Net sales in Canada`) — a partition of the same store revenue.
- **Banner or segment splits** (`Marmaxx Segment Net Sales`,
  `HomeGoods Segment Net Sales`) — a partition. These belong to the **multi-banner
  treatment** in §5, not to §3.
- **Comparable vs. non-comparable splits** — a partition.
- **Percentage-of-sales series.** `Combined e-commerce sales as a percentage of
  total sales`, `Consumables category net sales as a percentage of total net
  sales`. A percentage is not a dollar stream (§3.2).

**The partition test:** if adding the candidate to In-Store Revenue would make the
components sum to **more** than reported total revenue, it is a decomposition. The
§4 foot check catches this — but catch it here, before you build the row.

### 3.2 — Materiality, and streams reported only as a percentage

- **Materiality.** Carve out a stream when it is separately reported in dollars
  **and** is either **≥ ~5% of total revenue** or growing at a materially
  different rate from the store fleet. Below that, leaving it inside In-Store
  Revenue is the better modeling choice — a 2%-of-sales channel modeled as its own
  block adds a driver and no accuracy. **Whichever way you decide, state it in one
  Notes line** (*"Revenue: e-commerce, about <x>% of sales, is not carried
  separately; it stays inside in-store revenue and the per-square-foot rate."*);
  a stream silently left inside the fleet engine is the kind of choice a reader
  must be able to see. *Example:* TJX discloses combined e-commerce at roughly 2%
  of total sales — below the threshold, so it stays inside In-Store Revenue with
  that Notes line, and the per-square-foot driver carries it.
- **Reported only as a percentage.** When a channel is disclosed as a share of
  sales rather than a dollar line (TJX's
  `Combined e-commerce sales as a percentage of total sales in the consolidated
  TJX business`; `E-commerce sales as a percentage of TJX International net
  sales`; Macy's `Digital sales as a percentage of net sales`), you may derive the
  dollars as the percentage times the base the issuer states it on — `Net Sales
  (reported)` where the share is of net sales, `Total Revenue (reported)` where it
  is of total revenue — but only if the stream is material enough to warrant a
  block under the rule above. The percentage is its own row in the stream block,
  the `<the issuer's caption>` input row of §3.4, and the derived dollar row is a
  **live formula** referencing that row and the base, never a typed dollar figure.
  If it is immaterial, do not derive it at all.
- **A series labeled like a dollar level may be a percentage.** The Gap, Inc.'s
  `Online sales - Annual` carries an **empty** `unit` field and returns values of
  **2.0** and **4.0** — against a company with roughly **$15.4bn** of net sales.
  Those cannot be dollars. Run the same magnitude discipline on every stream
  candidate that §0.3 demands of square footage: a stream's value must be a
  plausible fraction of total revenue, in every historical year, before you
  transcribe it.

### 3.3 — Which line absorbs the residual (this is what makes §4 foot)

Exactly **one** line in the build is the residual, and which one depends on the
§2.1 method:

- **Residual method (§2.1 case 2):** `In-Store Revenue` is the residual, struck
  against reported net sales when a separate face line exists, else against
  reported total revenue. Every stream in §3 is a reported deepKPI input. No extra
  plug row is needed.
- **Direct method (§2.1 case 1):** `In-Store Revenue` is a reported input, so the
  residual moves to a final stream block headed **`Other`** (value row `Other Revenue`), inside net
  sales, computed as `= <Net Sales (reported)> − <In-Store Revenue> −
  SUM(<the stream rows inside net sales>)` (`Total Revenue (reported)` and all
  streams when no separate face line exists). It carries the same `YoY %` row as any other stream.
- **All-revenue method (§2.1 case 3):** there is no residual and §3 is empty.

**A large or swinging residual is a defect, not a result**, and each method has its
own diagnostic for it:

- **Direct method** (an `Other Revenue` residual block exists): the block's driver
  row `Other Revenue — % of modeled revenue` (§3.4) — the residual's share of in-store
  revenue plus the named streams. Its historical cells are the fit diagnostic: low
  single digits signals a healthy build; a double-digit share, or one that flips
  sign between years, means the numerator universe is wrong, a decomposition slipped
  into §3, or the fiscal-year alignment is off. In projection the same row is the
  driver the residual is projected off.
- **Residual method** (`In-Store Revenue` is itself the residual, so there is no
  `Other` to size): the fit diagnostic is §2.4's cross-check of the implied revenue
  per square foot against the issuer's reported figure.

Investigate before delivering; if a residual turns out to be a genuine, growing
revenue stream, **break it out as its own named block** rather than leaving it
buried.

### 3.4 — Layout and formula (cell-by-cell, per stream)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `<Stream Name>` *(block header — indent once, bold, underlined; the stream's name as the issuer captions it)* | | — | — | — |
| `<the issuer's caption>` *(indent once; a percentage-derived stream only, §3.2; above the value row)* | DATA_DEPENDENT | `(% of net sales)` or `(% of total revenue)`, on the base the issuer states | historicals: deepKPI **input** (green, hyperlinked), the issuer's disclosed share; projection: dash — the stream projects through its `YoY %` driver below | *(no comment — input row; the hyperlink is the provenance)* |
| `Revenue from <Stream Name>` *(value row — indent once; the block header above it is the bare stream name)* | | `(USD in <scale>)` | historicals: deepKPI **input** (or the §3.3 residual formula, or for a derived channel `= <the issuer's caption, this col> × <Net Sales (reported) or Total Revenue (reported), this col>` on the base the issuer states); projection: `= <prior col> × (1 + <YoY %>)` — the residual block instead: `= <Other Revenue — % of modeled revenue, this col> × (<In-Store Revenue, this col> + SUM(<named stream rows>, this col))` | `"<Reported \| derived \| residual> non-store revenue. Projection compounds prior × (1 + p/p)."` |
| `YoY %` *(indent twice; named streams only)* | DATA_DEPENDENT | `(%)` | historicals: `= <this col> ÷ <prior col> − 1`; **projection: DRIVER** — red font + dashed border, seeded per **Projections** (the default seed: guided, else the latest change, then flat) | `"Stream growth, period over period. Projection: driver seeded at the guided growth where the issuer gives one, else the latest change, then flat."` |
| `Other Revenue — % of modeled revenue` *(indent twice; the residual block only, in place of its `YoY %`; visible)* | DATA_DEPENDENT | `(% of modeled revenue)` | historicals: `= <Other Revenue, this col> ÷ (<In-Store Revenue, this col> + SUM(<named stream rows>, this col))`; **projection: DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The residual's share of the revenue the build models (in-store revenue + named streams). Historical: the fit diagnostic — low single digits expected. Projection: driver, guided or else the latest year, then flat."` |

- Name each block header after the stream as the issuer reports it (`Online`,
  `Wholesale`, `Licensing`, `Franchise`, `Membership Fees`) — spelled out,
  dash-separated qualifiers, per the styling rules — and label its value row
  `Revenue from <that name>`, the same label §4 uses when it restates the row. The
  residual block is headed `Other` with the value row `Other Revenue`.
- **Classify each stream by the income statement** — inside the issuer's net
  sales line, or its own face line (Costco's `Membership fees`, Macy's and
  Target's `Other revenue`). Record the classification in one Notes line per
  stream (*"Revenue: <stream> is presented <inside net sales / as its own line on
  the income statement> and sits <above / below> Net Sales."*); §4 places the
  stream above or below `Net Sales` accordingly. Read it off the statement,
  never off what the stream "ought" to be: Gap's franchise revenue is product
  shipped to franchisees and sits inside net sales.
- Keep the streams in a **stable order** across the build and repeat that order in
  §4; the consolidated block must list exactly the streams that exist here.
- The base historical column's `YoY %` is **blank (dash)**.

### 3.5 — Pre-delivery checklist (other revenue streams)

- [ ] Every block passes **both** §3.1 tests; no merchandise-category, geography,
      banner or comparable/non-comparable **decomposition** was carried as a
      stream.
- [ ] Every stream value survived the **magnitude test** (§3.2) in every
      historical year — no percentage transcribed as a dollar level.
- [ ] The materiality decision for each candidate channel is **stated in one
      Notes line** (§3.2 wording), including any channel deliberately left inside
      In-Store Revenue.
- [ ] Any percentage-derived stream is a **live formula** referencing its
      percentage input row and the reported base the issuer states the share on,
      not a typed figure.
- [ ] Exactly **one** line in the build is the residual, per §3.3, and it is the
      one §2.1 designates.
- [ ] The residual is **small and stable**; a large or sign-flipping residual was
      investigated, not absorbed.
- [ ] Each stream has its own `YoY %` row, blank in the base year.

---

## Section 4 — Consolidated Revenue

This block closes the build: it restates the components and foots to reported
total revenue.

### 4.1 — The logic

```
  Net Sales     = In-Store Revenue + Σ (streams inside net sales)        [only when the issuer reports a separate revenue face line]
  Total Revenue = Net Sales + Σ (streams that are their own face line)
                = In-Store Revenue + Σ (Other Revenue Streams)           [when no Net Sales row is laid]
```

`Net Sales` is laid only when the income statement shows a merchandise line
**and** at least one separate revenue line (§3.4); for a single-revenue-line
issuer it is omitted and `Total Revenue` is the reported net sales line. Both
totals are **live sum formulas in both halves** of the model, carrying the top
sum bar — exactly as the layout specifies. The **anchor** to reality is
enforced by construction (§3.3 designates a residual line). `Memo: Total −
Reported (must = 0)` beneath each total is a **wiring** check: because a residual
is `reported − everything else`, the difference is zero by construction, and what
it catches is a wrong reference, sign or column. Whether the model explains
revenue is a different question, answered by the fit diagnostic §3.3 names for the
method in use (the residual block's `Other Revenue — % of modeled revenue` row under the direct
method, §2.4's cross-check under the residual method).

- **Historical columns:** `Total Revenue (reported)` (and `Net Sales (reported)`
  when `Net Sales` is laid) is the reported deepKPI input (pale green,
  hyperlinked, visible — not a memo: the §2.1 residual reads it) — the figure the
  build must reproduce — and `Memo: Total − Reported (must = 0)` proves it does.
- **Projection columns:** there is no reported total to anchor to, so the anchor
  rows and the check memo are **blank (dash)** and `Net Sales` / `Total Revenue` are simply the
  assembled sums. Note in a comment which columns are reported-anchored and
  which are assembled.

### 4.2 — Layout and formula (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Consolidated Revenue` *(block header — indent once, bold, underlined)* | | — | — | — |
| `In-Store Revenue` | | `(USD in <scale>)` | `= <§2 In-Store Revenue, same column>` | `"Restated from Store Economics."` |
| `Revenue from <Stream>` *(one per stream inside net sales)* | | `(USD in <scale>)` | `= <that stream's value row, same column>` — same label as that row | `"Restated from the stream block. Inside the issuer's net sales line."` — one row per such stream, same order as §3 |
| `Net Sales` *(bold, top sum bar; only when a separate face line exists)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <In-Store Revenue> + SUM(<stream rows inside net sales>)` | `"Net sales = in-store + streams inside the issuer's net sales line (<caption>). Sum formula in both halves; the cost build strikes cost of sales against this row."` |
| `Net Sales (reported)` *(input row; only with `Net Sales`)* | HAS_NET_SALES_ROW | `(USD in <scale>)` | deepKPI **input** (pale-green, hyperlinked, visible), historical columns only; **blank in projections** | `"Reported net sales — the historical anchor for the in-store residual."` |
| `Revenue from <Stream>` *(one per face-line stream)* | | `(USD in <scale>)` | `= <that stream's value row, same column>` — same label as that row | `"Restated from the stream block. Reported as its own face line."` — one row per such stream |
| `Total Revenue` *(bold, top sum bar)* | | `(USD in <scale>)` | `= <Net Sales> + SUM(<face-line stream rows>)`; with no `Net Sales` row: `= <In-Store Revenue> + SUM(<stream rows>)` | `"Total revenue = net sales + face-line streams (or in-store + all streams). Sum formula in both halves."` |
| `Total Revenue (reported)` *(input row)* | | `(USD in <scale>)` | deepKPI **input** (pale-green, hyperlinked, visible), historical columns only; **blank in projections** | `"Reported total revenue — the historical anchor."` |
| `Memo: Total − Reported (must = 0)` *(italic)* | | `(USD in <scale>)` | `= <Total Revenue> − <Total Revenue (reported)>`, historical columns only | `"Wiring check: must equal 0 every historical period (zero by construction with a residual; a non-zero means a wrong reference, sign or column)."` |

- The consolidated rows are **restatements** — live references to the rows above,
  never re-entered values, and never a second copy of a deepKPI input.
- Use `SUM(...)` over the contiguous stream rows rather than chained addition, so
  a dashed stream cell cannot throw `#VALUE!`.

### 4.3 — Pre-delivery checklist (Consolidated Revenue)

- [ ] Every component row is a **live reference** to its source row; no value is
      re-entered.
- [ ] The stream rows listed here are **exactly** the streams built in §3 — none
      missing, none invented.
- [ ] `Total Revenue` is a live `SUM` formula with a top sum bar in **every**
      column, historical and projected; `Net Sales` likewise, and it is laid
      **iff** the issuer reports a separate revenue face line, with each stream
      placed above or below it per its §3.4 classification.
- [ ] `Memo: Total − Reported (must = 0)` evaluates to **0** in **every**
      historical column after recalculation (the wiring check).
- [ ] Under the direct method, the residual block's `Other Revenue — % of modeled revenue`
      row is laid, visible, and its historical cells read **low single digits** — or the cause is identified and stated in the row's comment; under
      the residual method, §2.4's cross-check was run and recorded in `BUILD_LOG.md`.
- [ ] The reported anchor row(s) and the check memo are **blank (dash)** in every
      projection column, and the reported-vs-assembled basis is noted in a comment.
- [ ] **Indentation across the whole build is real cell indent**, not padding:
      every Col C label satisfies `value == value.lstrip()`, and each row's level
      is carried by `Alignment(indent=n)` per the indent mapping in
      **Conventions**. Sweep the sheet programmatically before delivering —
      a single padded label is a defect.
- [ ] Applying the indent **preserved** each cell's existing `horizontal` /
      `vertical` alignment (no bare `Alignment(indent=n)` that wipes the rest).
- [ ] Every **block header** (`Square Footage`, `Store Economics`, each stream
      name, `Consolidated Revenue`) sits at the **same indent level** as its own
      line items, distinguished by **bold + underline** only.
- [ ] After recalculation there are **zero formula errors** anywhere in the build.

---

## Section 5 — Multi-banner parents

The location build may have produced **one store roll-forward per banner** (or per
banner × region). Whether this build follows that partition depends on whether the
revenue and square-footage data support it:

- **Full per-banner build** — when square footage **and** revenue are both
  reported at the banner level. Run the §1 Square Footage block and the §2 Store
  Economics block **once per banner**, in the **same banner order** as the location
  build, each with its own `Company-Operated EOP Store Count` row referencing that
  banner's company roll. Then §3 streams
  (consolidated, unless a stream is genuinely banner-specific) and a §4
  Consolidated Revenue block whose `In-Store Revenue` row is
  `= SUM(<per-banner In-Store Revenue rows>)`.
- **Consolidated build** — when either square footage or revenue exists only at
  the consolidated level. Run **one** §1 + §2 stack against the location build's
  **Total — all banners** Company-Operated EOP Balance, and add one Notes line:
  *"Revenue: square footage is reported only in total, so store economics are
  built for the whole fleet, not per banner."*
  Do **not** allocate a consolidated square-footage figure across banners by store
  count; that manufactures per-banner precision the filing does not support.
- **Mixed** — some banners reported, some not. Build the reported banners
  individually and group the remainder into a single clearly-labeled block (e.g.
  `Other Banners`). Never leave a banner out: the per-banner In-Store Revenue rows
  must cover the whole fleet, or §4 will not foot.

**Universe consistency applies per banner.** Each banner's square footage, store
count and revenue must be that banner's own — and every banner block must use the
same selling-vs-gross basis.

### 5.1 — Pre-delivery checklist (multi-banner)

- [ ] The partition matches the location build's blocks, or the deviation is
      stated with its reason.
- [ ] Per-banner blocks appear in the **same order** as the location build.
- [ ] Every banner block references **its own** EOP store count, on the
      company-operated universe.
- [ ] The per-banner In-Store Revenue rows **cover the whole fleet** — no banner
      omitted — and sum into §4.
- [ ] Consolidated square footage was **not** allocated across banners by store
      count.
- [ ] Single-banner retailers get **no** separate consolidated stack (the one
      banner's block plus §3 and §4 already foots).

---

## Section 6 — Worked examples

Three real retail shapes, with figures pulled from deepKPI and verified to foot.
They exist to record the **exact series, the traps, and the reconciliation
targets** — not to be copied into a build.

### 6.1 — Dollar General (Mode A, Path 2: total square footage derived)

Single banner, no non-store revenue streams reported in dollars — the cleanest
Mode A shape, and the one where the model validates against the issuer's own
disclosure.

- **Store count:** referenced from the location build
  (`Number of Retail Stores at End of Period - annual`).
- **Square footage — Path 2:** `Average selling space per store for Dollar General
  core retail operations` (**7,400** sq ft through FY2022, **7,500** FY2023
  onward) is the **input**; `Total Square Footage` is the **formula**
  `= avg × EOP stores`.
- **In-Store Revenue:** `Total Net Sales - annual` — §2.1 case 3 (no non-store
  stream is reported in dollars), so the fleet is credited with all of revenue and
  the Notes line of §2.5 says so.
- **Cross-check series:** `Average sales per square foot for Dollar General (Core
  Retail Operations) - annual`.

| Fiscal year | EOP stores | Avg sq ft/store | Total sq ft | Net sales | **Implied rev/sq ft** | p/p | Reported sales/sq ft |
|---|---|---|---|---|---|---|---|
| FY2022 | 19,104 | 7,400 | 141.4M | $37,844.9M | **$267.70** | — | — |
| FY2023 | 19,986 | 7,500 | 149.9M | $38,691.6M | **$258.12** | −3.6% | — |
| FY2024 | 20,594 | 7,500 | 154.5M | $40,612.3M | **$262.94** | +1.9% | **$263** |
| FY2025 | 20,893 | 7,500 | 156.7M | $42,724.4M | **$272.66** | +3.7% | **$270** |

The FY2024 implied figure of **$262.94** against DG's reported **$263** is a
near-exact match — the strongest possible validation that the numerator universe,
the denominator basis, the scale and the fiscal-year alignment are all right. The
FY2025 implied **$272.66** runs **+1.0%** above the reported **$270**, which is
the expected direction: the fleet grew, so an EOP denominator sits below an
average-of-period denominator and lifts the implied figure (§2.4).

**Traps on this issuer.** The inventory carries
`Total square footage of owned executive office buildings in Goodlettsville,
Tennessee`, `Total leased square footage of additional warehouse space supporting
the distribution network` and `Total leased square footage of additional office
space outside the United States` — **none** is selling floor. It also carries
`Average square feet of selling space for new Standard and Large Format store
openings`, which is the **new-store** footprint, not the fleet average (useful as
a sanity input for the projection driver, never as the historical input). The
merchandise-category net-sales series (Consumables, Seasonal, Home, Apparel) are a
**decomposition** of in-store revenue and must not be carried as §3 streams.
Finally, DG's store-count series are stamped with **calendar placeholders**
(`2025-12-31` for fiscal 2025) while its net-sales series are stamped with **true
fiscal year-ends** (`2026-01-30` for the same year) — join them by fiscal year,
never by date.

### 6.2 — The Gap, Inc. (Mode A, Path 1, with a contaminated numerator)

Multi-banner × region, a franchised fleet, and the example of why §2.1 exists.

- **Square footage — Path 1:** `Total Company-Operated Store Square Footage at End
  of Period` is the **input** (29.6M sq ft at FY2025), and `Average Square Footage
  per Store` is the **formula**. Note the series carries an **empty `unit` field**
  and still passes the magnitude test at ≈12,000 sq ft/store — metadata absence is
  not evidence of a bad series (§0.3).
- **Per-banner square footage exists** (`Company-Operated <Banner> <Region> Store
  Square Footage at End of Period`), so a full per-banner build is supportable if
  banner-level revenue is too.

| Fiscal year | EOP stores | Total sq ft | Avg sq ft/store | Net sales | Total ÷ sq ft |
|---|---|---|---|---|---|
| FY2022 | 2,685 | 31.8M | 11,844 | $15,616M | $491.07 |
| FY2023 | 2,562 | 30.6M | 11,944 | $14,889M | $486.57 |
| FY2024 | 2,506 | 30.1M | 12,011 | $15,086M | $501.20 |
| FY2025 | 2,474 | 29.6M | 11,964 | $15,366M | $519.12 |

**The last column is the wrong answer, deliberately shown.** Gap's net sales
include online sales (a large share of the total) and franchise/licensing revenue,
while the square footage is company-operated stores only — so ≈**$519/sq ft** is
not store productivity, it is a ratio of unlike things. It even looks *healthy*,
rising steadily as the fleet shrinks, which is exactly why the contamination is
dangerous. The build must isolate In-Store Revenue first (§2.1), carve online and
franchise revenue into §3 streams, and recompute.

**Traps on this issuer.** `Online sales - Annual` carries a blank `unit` and
returns **2.0** and **4.0** against $15.4bn of net sales — it cannot be the online
dollar stream and must not be transcribed as one (§3.2). `Total net sales in Other
Regions - annual` steps from 209 → 139 → **1,301** → 1,179 across FY2019–FY2022, a
**basis change**, not growth — a growth seed read off that window would be meaningless
(see the Projections basis-break guard). And the company-operated store-count series
carries intermittent ×10⁶ scaling artifacts, which the location build should
already have overridden — read its hand-back report rather than re-sourcing counts
here.

### 6.3 — TJX (Mode A only after rejecting the consolidated series)

The example of the magnitude test earning its place.

- **The consolidated square-footage series fails.** `Selling square footage in the
  consolidated TJX retail operations` carries `unit: "square feet"` and returns
  **3.0** for a fiscal year in which TJX operated **5,214** stores — 0.0006 sq ft
  per store. It is a growth percentage in a series labeled and unit-tagged as a
  level. **Reject it**, and do not fall to Mode B on the strength of that rejection.
- **Go to the segment/banner level next.** `Total Selling Square Footage at End of
  Period for <Segment>`, `<Banner> Selling Square Footage at End of Period` and
  `<Banner> Approximate Average Store Size` all exist and give both Path 1 and Path
  2 routes into Mode A. Take the 10-K store-count-and-square-footage table as the
  final fallback before Mode B.
- **Basis:** TJX reports **selling** square footage — name it in the label and
  never mix it with a gross figure from another source.
- **§3:** combined e-commerce runs at roughly **2%** of total sales and is
  disclosed as a **percentage**, not a dollar line — below the §3.2 materiality
  threshold, so it stays inside In-Store Revenue with the Notes line of §3.2.
- **Decoys:** `Owned/Leased/Total Distribution Center Square Footage` sit directly
  beside the store series and are not selling floor. Segment net-sales series
  (`Marmaxx Segment Net Sales`, `HomeGoods Segment Net Sales`) are a **banner
  partition** for §5, not §3 streams.

For reference, TJX revenue per store runs ≈**$11.6M** at FY2025 ($60,372M ÷ 5,214)
— the Mode B figure, useful as a magnitude sanity check even when Mode A is used.

---

## Projections (forecast years)

After the **historical** build above (§1 – §6) is laid down, recalculated and
footed (the §4 `Total − Reported (must = 0)` check passes in every historical
column), **extend the entire build into the projection window** before the
downstream handoff (§7). The projection window is the **five fiscal years after
the last historical year** (`N+1 … N+5`) per the **Model timeline** in
`../../../SKILL.md` — do not redefine it here. Add five more **annual** columns
immediately to the right of the historical block, continuing the same left →
right, oldest → newest order.

**The overwhelming majority of the build simply drags across as formulas.** Only a
small, enumerable set of **drivers** are entered as forward assumptions:

| # | Driver | Mode | Seed |
|---|---|---|---|
| 1 | `Average Square Footage per Store` | A only | **level driver** — flat at the last historical actual |
| 2 | `Implied Average Revenue per Square Foot` → `YoY %` | A only | **rate driver** — the default seed (guided, else the latest historical year), then flat |
| 3 | `Implied Revenue per Store` → `YoY %` | B only | **rate driver** — the default seed (guided, else the latest historical year), then flat |
| 4 | each stream block's `YoY %`; for the residual block, `Other Revenue — % of modeled revenue` | both | **rate driver** — the default seed (guided, else the latest historical year), then flat |

That is the complete list. **Any other typed value in a projection column is a
bug.**

### Driver styling (applies to every projection driver)

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **Dashed box border on all four sides** of the cell (e.g. openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom`).
- **No pale-green fill and no hyperlink** — projection drivers are assumptions,
  not deepKPI-sourced actuals.
- **Exception to the "formulas are black" rule.** A projection driver keeps the
  red font + dashed border **even though its default value is a live formula** (the
  seeding formula below). The red/dashed treatment marks it as the intended
  override point; every **non-driver** projection cell keeps standard formula
  styling — black font, no fill, no dashed border — identical to its historical
  styling, just dragged one column right.

### Driver value methodology (the default seeds)

Three seed rules, applied by driver **type**:

- **Rate drivers — the default seed, then flat.** `N+1` = the default seed ladder of
  `../../../SKILL.md` (Build mechanics: guided; else the latest year on the issuer's
  normalized basis, a 52-week comparable or a go-forward sales change; else the
  latest historical year `N`, written by the renderer as a live formula with an
  `ISNUMBER` fallback to `N−1` and `N−2`; else, only where `N` is a disclosed
  distortion, the latest undistorted year). `N+2 … N+5` = `= <driver N+1 cell>`
  (flat). This applies to drivers **2** and **3**. The seed stands as the ladder
  gives it: a build never drops a year, averages years or holds a driver at zero on
  its own judgment. Where the seed looks implausible — a rebound year that compounds
  to a figure out of line with the row's history — the driver's comment names the
  anomaly in analyst language (*"FY<N> growth of <x>% is a rebound from <a> to <b>;
  compounded it reaches about <c> by FY<N+5>; the analyst may override"*) and the
  seed is unchanged.
- **Other-stream rate drivers — the default seed, then flat.** The same rule as drivers 2
  and 3, applied to each named stream's `YoY %` and to the residual
  block's `Other Revenue — % of modeled revenue`. A CAGR is **not** used as a seed anywhere
  in this build. This applies to driver **4**.
  - **Basis-break guard.** Where a stream's basis changed mid-window (Gap's `Other
    Regions` line stepping 209 → 139 → 1,301 is the canonical case), seed from the
    latest year on the current basis or type an assumption — and add one Notes
    line: *"Revenue: <stream> growth is seeded from FY<a>; the FY<b> figure is on
    a different basis."* Never seed off a change computed across a basis break.
- **Level drivers — flat at the last actual.** `N+1 … N+5` = `= <the driver's `N`
  historical cell>`. This applies to driver **1**, `Average Square Footage per
  Store`, and it is a **deliberate departure** from the default seed, then flat rule used
  elsewhere in the model. The reason: average square footage per store is a slowly
  **drifting level**, not a rate. Averaging three years of a drifting level pulls
  the projection *backward* to a footprint the company has already moved away
  from; holding it at the last reported actual keeps the fleet's current format.
  Say so in the cell comment.

The modeler may type a specific assumption over any driver cell; the red/dashed
styling flags exactly which cells are meant to be overwritten.

### Part 1 — Square Footage (§1; Mode A only)

- **`Company-Operated EOP Store Count`** was **already forecast in the location build**, so
  it carries **no driver here** — keep it as a **live reference into the (now
  projected) store roll-forward** and drag the reference across. This is the
  mechanism the whole build turns on: a new store opening in the location build
  raises the projected store count, which raises total square footage, which
  raises in-store revenue.
- **`Average Square Footage per Store`** — the **level driver**. Historically it
  is either the reported input (Path 2) or `= total ÷ stores` (Path 1); in
  projection **both paths converge** on the driver treatment (red/dashed, flat at
  the `N` actual).
  - *Sanity input, not a substitute:* where the issuer reports a **new-store
    footprint** (DG's `Average square feet of selling space for new Standard and
    Large Format store openings`), compare it to the fleet average. A new-store
    footprint materially below the fleet average means the fleet average will
    **drift down** as the company opens stores, and the flat driver overstates
    future square footage — that is the signal to override the driver downward,
    with one Notes line: *"Revenue: average store size is held at the latest
    actual; new stores are <larger / smaller> than the fleet average, so the
    analyst may wish to adjust it."* Do **not** build a second incremental-footprint
    mechanism; this build projects square footage off the fleet average.
- **`Total Square Footage`** — **formula in every projection column**,
  `= <Average Square Footage per Store> × <Company-Operated EOP Store Count>`, regardless of
  which historical path was used. Under Path 1 this is the row's **inversion
  point**: reported input historically, formula in projection.

### Part 2 — Store Economics (§2)

This is the build's central inversion — it **flips which cells are inputs and
which are formulas**:

- In the **historical** columns, **In-Store Revenue is sourced** (reported input or
  residual) and the **per-unit figure is derived from it**.
- In the **projection** columns this **reverses**: the **per-unit figure is grown
  by its driver** and **In-Store Revenue is computed from it**.

Cell by cell:

- **`Implied Average Revenue per Square Foot`** *(Mode A)* — definition unchanged
  for historical (`= In-Store Revenue ÷ Total Square Footage`). For **projection**
  it switches to compounding off the prior year: `= <prior column> × (1 + <Period/
  period change, this column>)`.
- **`Implied Revenue per Store`** — *Mode A:* stays the **diagnostic formula**
  `= In-Store Revenue ÷ Company-Operated EOP Store Count` in both halves; it is **never** a
  driver in Mode A. *Mode B:* it **is** the driver base, and switches to
  `= <prior column> × (1 + <YoY %, this column>)` in projection.
- **`YoY %`** — the **rate driver** for whichever line is the driver
  base in this mode. Historically it is **derived** (`= this col ÷ prior col − 1`);
  in projection it **inverts** to the forward assumption (red/dashed;
  the default seed, then flat).
- **`In-Store Revenue`** — **formula in every projection column**: Mode A
  `= <Total Square Footage> × <Implied Average Revenue per Square Foot>`; Mode B
  `= <Implied Revenue per Store> × <Company-Operated EOP Store Count>`. Under the direct
  method (§2.1 case 1) this is the row's inversion point (reported input
  historically, formula in projection); under the residual method it changes from
  one formula to a different one.
- **`Memo: rev/store cross-check`** *(Mode A)* — drags across unchanged and must
  still evaluate to **0** in every projection column.

### Part 3 — Other revenue streams (§3)

- **`Revenue from <Stream Name>`** value row — **historical unchanged** (reported input,
  derived-from-percentage formula, or the §3.3 residual). For **projection**:
  `= <prior column> × (1 + <YoY %, this column>)` — the same
  input → compounding inversion as Part 2.
  - **The residual stream is the exception.** Under the direct method the
    `Other Revenue` block is historically a plug against reported total revenue.
    There is no reported total in the projection columns, so it **cannot** stay a
    plug — it is projected as a **share of modeled revenue**: `= <Other Revenue — % of modeled revenue,
    this col> × (<In-Store Revenue, this col> + SUM(<named stream rows>, this col))`,
    the driver row beneath it seeded by the default seed. The denominator excludes the
    residual itself, so there is no circularity. **State this inversion in one
    Notes line:** *"Revenue: in the forecast Other Revenue is a share of modeled
    revenue, held at the latest ratio, rather than a plug."*
- **`YoY %`** — the **rate driver** for each named stream (red/dashed;
  the default seed, then flat).

### Part 4 — Consolidated Revenue (§4)

- **`In-Store Revenue`** and each **`Revenue from <Stream>`** restatement row —
  the **same live references** as the historical columns; drag them across.
- **`Net Sales`** (when laid) and **`Total Revenue`** — the **same `SUM`
  formulas** as the historical columns; drag them across. Neither is **ever** a
  driver in either half. The only thing that changes across the boundary is
  *what anchors them*: historically the components are constructed to reproduce
  reported net sales and total revenue; in projection they are simply assembled.
- **`Net Sales (reported)`**, **`Total Revenue (reported)`** and
  **`Memo: Total − Reported (must = 0)`** — **blank (dash)** in every projection
  column. Do not extend a reported anchor into years that have not been reported.

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=`
  formula (no hardcoded numbers). The **only** seeded cells are the four driver
  types enumerated above.
- **Driver seeding.** Rate drivers: `N+1` = the default seed (the guided value where the guidance table names it, else the latest clean historical year), `N+2 … N+5 = N+1`. Stream drivers and the residual's ratio driver: the
  same rule. The level driver: flat at the `N` actual.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors**, and **no circular references**.
- **Continuity at the boundary.** `N+1` per-unit figure compounds off `N`'s value;
  `N+1` `Total Square Footage` = `N+1` projected stores × the average-footprint
  driver; each stream's `N+1` compounds off `N`. The projection joins the actuals
  with no gap or jump. Eyeball the `N` → `N+1` step on every driven line — a
  visible discontinuity means a reference is off by one column.
- **Fleet coherence.** Projected `Total Square Footage` must move in the **same
  direction** as the projected store count. If the location build projects net
  closures and square footage rises (or vice versa), the average-footprint driver
  or the store-count reference is wrong.
- **No sign or magnitude absurdities.** No projected revenue line goes negative;
  no per-unit figure compounds to an implausible level by `N+5` (check the
  cumulative effect of the driver, not just the annual rate — a +8% rate held flat
  for five years is +47%).
- **Mode A `Memo: rev/store cross-check`** still evaluates to **0** in every
  projection column.

---

## Section 7 — Downstream handoff

After the build is laid down, recalculated and footed:

- Confirm **zero formula errors** and **no circular references** (LibreOffice /
  `recalc.py`).
- Confirm the **foot**: `Memo: Total − Reported (must = 0)` equals **0** in every
  historical column, and `Total Revenue` is the assembled sum in every projection
  column.
- Confirm the **§2.4 cross-check** against any reported sales-per-square-foot
  series was run and its result recorded in `BUILD_LOG.md`.
- Hand back to the retail router (`../retail.md`), reporting: the **mode** (A or
  B), the **square-footage path** (1 or 2) and basis (selling / gross), the
  **In-Store Revenue isolation method** (direct / residual / all-revenue), the
  **streams carried** in §3 and any channel deliberately left inside In-Store
  Revenue, and the **residual line** and its typical size. The router reports the
  build method onward to the parent revenue router (its Step 5).
- The downstream **costs / margins** builds reference the revenue lines laid down
  here (e.g. store-level margin = in-store revenue − store operating costs), so
  keep the row labels stable and the universe explicit.

### Notes to record in the workbook

One line per fact, each written as `Revenue: <fact>` in an analyst's words: no
section numbers, no mode or path names, no skill vocabulary.

- The basis and the universe: *"Revenue: square footage is <selling / gross> area
  of company-operated stores."* and *"Revenue: store economics are on
  company-operated stores; franchise and license fee income is a separate
  stream."*
- The in-store revenue method: *"Revenue: in-store revenue is <the reported store
  line / total revenue less <channels> / total revenue, since no non-store channel
  is reported in dollars, so any digital or wholesale sales sit inside revenue per
  square foot>."*
- Each stream's materiality decision, including any channel left inside In-Store
  Revenue: *"Revenue: e-commerce, about <x>% of sales, is not carried separately;
  it stays inside in-store revenue and the per-square-foot rate."*
- Each stream's presentation: *"Revenue: <stream> is presented <inside net sales /
  as its own line on the income statement> and sits <above / below> Net Sales."*
- Any driver seeded from a year other than the latest, and why: *"Revenue:
  <stream> growth is seeded from FY<a>; the FY<b> figure is on a different
  basis."*
- The held-flat footprint, and any override driven by a new-store footprint that
  differs from the fleet average: *"Revenue: average store size is held at the
  latest actual; new stores are <larger / smaller> than the fleet average, so the
  analyst may wish to adjust it."*
- A consolidated-only build: *"Revenue: square footage is reported only in total,
  so store economics are built for the whole fleet, not per banner."*
- The residual in the forecast: *"Revenue: in the forecast Other Revenue is a
  share of modeled revenue, held at the latest ratio, rather than a plug."*

### Record in `BUILD_LOG.md`, not the Notes

The stage's hand-back report carries the same.

- The mode gate decision line from §0.4: the mode chosen, the series that passed
  or failed the gate, the per-store magnitude, and the rejected candidates.
- The result of the reported sales-per-square-foot cross-check (§2.4), with its
  direction and magnitude, and any gap between a computed and a reported average
  footprint (§1.2).
- The segment map (`../../../SKILL.md`, "The segment map"): each banner with revenue
  rows of its own, named as the inventory's segment series spell it, and the keys of
  those rows; an empty map for a single-banner build.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's square-footage / revenue-per-location lines; the store
roll-forward and all non-revenue sections are owned by their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Company-Operated EOP Balance` for the banner (`coeop_<banner>`) | location build (`../locationBuild/`) | the retail router's location gate PASSED | none — return `ABORTED` |
