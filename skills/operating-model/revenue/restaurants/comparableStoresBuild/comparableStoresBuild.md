---
name: revenue-restaurants-comparable-stores
description: >
  Comparable-stores revenue build for restaurant companies in the
  operating-model workbook. Invoked by the restaurant router
  (`revenue/restaurants/restaurants.md`) when the company reports a full
  comparable-store-sales KPI set (comparable-store sales growth %, and
  beginning/end-of-period revenue split between comparable and non-comparable
  cohorts; the underlying unit-count roll-forward is laid down separately by
  `locationBuild/locationBuild.md` before this build runs). Receives the
  resolved `company_id`, official company name, workbook path, and the shared
  KPI inventory; builds the revenue model from the comparable-store-sales bridge
  beneath the `REVENUE` ALL-CAPS header (using the unit counts already in the
  workbook from the location build). The revenue build decomposes reported total
  revenue into four components plus a plug: Revenue from the Comparable Cohort
  (a recursive per-brand bridge — prior-year revenue per comparable restaurant
  grown by same-store sales, times the comparable count), Revenue from the
  Non-Comparable Cohort (blended revenue per location × a 0.5 partial-year factor
  × the non-comparable count), Revenue from Franchises (if franchised), and Other
  Revenue (the plug that foots the build to reported Total Revenue). Pulls series
  via `search_kpis` from the shared inventory; format per
  ../../../../_common/revelata-excel-styling-rules.md (one row per series, derived
  cells as live formulas) EXCEPT for time scope (last 4 fiscal years), which this
  build overrides. For multi-brand parents (e.g. Brinker), it runs the full
  per-brand revenue build for each concept and then a consolidated revenue table
  that combines the brands. Sections: §1 cohort partition, §2 comparable-cohort
  revenue, §3 non-comparable-cohort revenue, §4 franchise revenue, §5 other +
  total revenue, §6 multi-brand parents + consolidated table, §7 worked example,
  §8 downstream handoff.
---

# revenue — restaurants — comparable-stores build

This is the **comparable-stores** restaurant revenue build. It is invoked by the
restaurant router (`../restaurants.md`) when the company reports a rich
comparable-store-sales dataset — i.e. enough to bridge revenue from a beginning-
of-period base, comparable-cohort growth, and the contribution of stores not in
the comparable cohort (new units, closures).

By the time control reaches this build, the **unit-count roll-forward has
already been laid down** in the workbook by `../locationBuild/locationBuild.md`
(the router invokes it before routing). This build is therefore responsible only
for the **revenue** lines of the comparable-stores model and may reference the
unit counts already present.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook (with the unit roll-forward already laid
down), the **shared KPI inventory** from the orchestrator, and the router's note
of which KPIs satisfied the comparable-stores criteria.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
`../../../../_common/revelata-excel-units-and-scale.md` (see "Number format and units"
in the conventions for Sections 2 – 6) and build with the **xlsx** skill. All
conventions there apply here — one row per distinct series, deepKPI-sourced values as
pale-green hyperlinked input cells, and **every** total / derived cell as a live `=`
formula (never a hardcoded number) — **except** for the **time scope**, which this build
overrides per the "Time scope" section below.

## Aborting the build — the only exit other than completion

Reaching this build means the router's Step 2.0 scan found every necessary item
in the inventory. Two inputs can still prove **unobtainable** once the build
sources them in full — deepKPI first, then the 10-K where the section's text
sends you there: the **base-column comparable-cohort dollar seed** (§2.1
situations 1 and 2) and the **base-column comparable restaurant count** (§2.5). A
comp reported only on the **systemwide** universe (§1.8) is a third trigger the router's criteria should have caught.

When one of them is unobtainable, **stop writing**. Do not substitute a proxy
(blended restaurant sales, total restaurants, a residual dollar change). Return control to
the router with exactly this outcome and nothing else:

- **`ABORTED — <necessary item> unobtainable`**;
- the item, and what was searched for it (inventory captions tried, 10-K
  sections read);
- the sections and rows already laid by this build, so the router can drop them.

**Do not name another build.** Routing is the router's job (`../restaurants.md` Step
4.1 receives this outcome, drops the rows, and re-routes with this build
excluded); this build's text never says where the company goes next. Under the
compose-then-render mechanic the rows disappear by leaving this build's section
module out of the parts; the location build's rows are untouched.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 7), then **extends the entire revenue build into the projection window**
  following the **Projections (forecast years)** section near the end of this file.
  Do not fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §1 the
> cohort partition and §2 – §8 the revenue build (comparable-cohort revenue,
> non-comparable-cohort revenue, franchise revenue, other + total revenue,
> multi-brand parents + the consolidated table, a worked example, and the
> downstream handoff), plus the **Projections (forecast years)** section near the
> end that extends the build into `N+1 … N+5` — are the implemented scope. Do not
> build or add any new information outside the sections present here.

---

## Section 1 — Location Cohorts (Comparable vs. Non-Comparable)

This is the **first section** of the comparable-stores revenue build. It sits
**immediately beneath** the Location roll-forward laid down by
`../locationBuild/locationBuild.md` and **partitions** each brand's total
location count into a **Comparable** cohort and a single **Non-Comparable**
cohort (the Non-Comparable cohort is broken down by **year of opening only** —
not by internal age sub-buckets; see §1.3). Every downstream revenue section
(comparable-cohort sales growth bridge, new-unit revenue contribution,
ramping AUV math) refers back to the cohort counts produced here, so this
section **must** be built before any revenue lines.

The build proceeds in three logical steps that you **must do in order**:

1. **Read the comparable-store definition from the 10-K** (§1.1). The age
   threshold `T` **and** the measurement anchor ("in operation for T months",
   "T months before the beginning of the period", or "throughout both periods")
   together set the **effective reach `R`** (laid on the sheet as `New-store window`; `T` is laid as `Months to enter comp base`), which determines which fiscal years
   of openings are non-comparable and by what weight. Do not assume a default.
2. **Translate the definition into a fiscal-year partition** (§1.2 – §1.4).
   The Non-Comparable cohort is the set of unit openings that fall inside a
   **trailing window** ending at the comparability measurement anchor. Under a
   uniform-monthly-openings assumption, the **current** fiscal year is always
   **fully** non-comparable, and the **boundary** fiscal year (where the window
   cuts off) is counted **fractionally** — weight `(R mod 12) / 12` of its
   openings, **not** rounded up to a full year (§1.2, §1.4). For example, a "13
   full calendar months in operation" rule leaves only **1/12** of the prior
   year's openings non-comparable, not the whole year. §1.4 lists the
   year-of-opening rows and weights for the common thresholds. The
   Non-Comparable cohort is a **single** group broken down by year of opening
   only — §1.3 explains how to collapse any issuer-published age sub-buckets
   into that single structure.
3. **Build the cohort block in the workbook**, one block per brand (§1.5 –
   §1.10).

### 1.1 — Read the comparable-store definition from the 10-K

The definition of a **comparable restaurant** is **issuer-specific** and is
disclosed in the 10-K — typically in the MD&A section under "Key Performance
Indicators", "Performance Indicators", or "Restaurant and Other Sales". Two
parameters always vary; both **must** be extracted before any cohort row is
written:

1. The **age threshold** `T` at which a restaurant **enters** the comparable
   base. Common values are **12, 13, 18, or 24 months** (some issuers use **52
   or 65 weeks**, which round to 12 or 15 months).
2. The **measurement anchor** — one of three, and it **materially** changes the
   partition (do **not** treat them as equivalent):
   - **"in operation for at least T full calendar months"** — the test is
     applied **at / through the period** (effectively at the period **end**).
     Example: **Chipotle** ("…company-owned restaurants in operation for at
     least 13 full calendar months"). Effective reach **R = T**.
   - **"open for T months before the beginning of the period measured"** —
     applied at the period **start**. Examples: **Texas Roadhouse, Darden**.
     Measuring from the start instead of the end pushes the test back one full
     period, so the effective reach is **R = T + 12**.
   - **"open throughout both periods compared"** — must be open the entire
     current and entire prior period. Effective reach **R = 24** (full current +
     full prior year non-comparable), regardless of the stated `T`.

The anchor does **not** wash out. A "13 months **in operation**" rule (R = 13)
leaves only **1/12** of the prior year's openings non-comparable; a "13 months
**before the beginning**" rule (R = 25) leaves the **entire** prior year plus
**1/12** of the year before that non-comparable. Record `T`, the anchor and the
resulting **R** as one line in the Notes block (§5.5) so the basis is auditable;
the values themselves sit in the cohort assumptions cells (§1.5).

**Workflow:**

1. Pull the latest 10-K markdown via the **filing** skill (`list_sec_filing_markdowns`
   → `get_sec_filing_markdown`).
2. Search the markdown for the literal token **`comparable`** and read the
   surrounding paragraph in the MD&A KPI subsection. Look for a sentence that
   begins **"We define the comparable restaurant base to include…"** or
   **"Comparable restaurant sales reflect…"**.
3. Extract **three** things and **record them** — **not** as note rows inside the
   build, but as two lines in the **Notes block** at the bottom of the build
   (§5.5): one quoting (or closely paraphrasing) the definition with its filing
   year, and one giving the resulting framework formula:
   - the **age threshold** (e.g. 18 months, 65 weeks),
   - the **measurement anchor** (before the beginning, or throughout both
     periods),
   - any **exclusions** (e.g. "excluding restaurants permanently closed during
     the period").
4. If the filing reports comp sales on a **company-restaurants-only** basis (the
   most common pattern — comp sales is rarely reported for the franchised
   system), state that the cohort universe is **company-owned locations** for
   that brand. If the issuer also reports a franchise or systemwide comp, the
   cohort is **still company-owned**: the franchise comp is consumed by the
   franchise revenue block (§4, Mode A), never by a second partition (§1.8).

**Example — Texas Roadhouse (FY2025 10-K MD&A):**

> "Comparable restaurant sales reflect the change in sales for all company
> restaurants across all concepts, unless otherwise noted, over the same period
> of the prior year for the comparable restaurant base. We define the
> comparable restaurant base to include those restaurants open for a full 18
> months before the beginning of the period measured excluding restaurants
> permanently closed during the period, if applicable."

So for Texas Roadhouse:
- Age threshold **T = 18 months**.
- Measurement anchor = **before the beginning of the period**. **Critical:**
  this anchors against the **start** of the comp period, not the end. For
  FY2025 (period start ≈ end of FY2024), a store must have been open by **mid
  FY2023** to be comparable, **not** by mid FY2024. This is the
  most-frequently-misread part of the definition.
- Exclusion: restaurants permanently closed during the period.
- Universe: **company-owned restaurants** (the 10-K reports comp sales for
  "company restaurants" only — at consolidated, TXRH-brand, and Bubba's 33
  levels; Jaggers comp sales is not disclosed).

### 1.2 — Translate the definition into a fiscal-year partition (trailing-window model)

The Non-Comparable cohort is every unit opening that falls inside a **trailing
window of `R` months** ending at the comparability measurement anchor, where
`R` is the **effective reach** from §1.1:

- `R = T` for an **"in operation for at least T months"** rule (test applied at
  the period **end**; e.g. Chipotle),
- `R = T + 12` for an **"open T months before the beginning of the period"**
  rule (test applied at the period **start**; e.g. Texas Roadhouse, Darden),
- `R = 24` for an **"open throughout both periods"** rule.

Assume restaurants open **evenly throughout each fiscal year** (uniform monthly
openings). Then FY(N−k)'s openings sit between **12k** and **12(k+1)** months
before the anchor, and the fraction of that year captured by the `R`-month
window — i.e. the **weight** of FY(N−k) openings in the Non-Comparable cohort —
is:

> **w(k) = clamp( (R − 12·k) / 12 , 0 , 1 )**   for k = 0, 1, 2, …

This single formula **replaces** the old "round the boundary year up to fully
non-comparable" heuristic. It yields four cases:

- **Current year, k = 0:** `w(0) = clamp(R/12, 0, 1) = 1` (R ≥ 12 always). The
  current fiscal year's openings are **always fully non-comparable**.
- **Fully non-comparable prior years:** any FY(N−k) with `12(k+1) ≤ R` →
  `w(k) = 1`.
- **The boundary year** (exactly one): the FY(N−k\*) where `12·k* < R <
  12·(k*+1)` → `w(k*) = (R − 12·k*) / 12 = (R mod 12) / 12`. This **fractional**
  weight is the source of the "13 months → **1/12** of the prior year" result; it is
  never rounded up to a full year (§1.4).
- **Comparable years:** any FY(N−k) with `12·k ≥ R` → `w(k) = 0`.

The deepest contributing year is **k\* = ceil(R/12) − 1**, so the cohort block
carries **ceil(R/12)** year-of-opening rows (k = 0 … k\*). The cohort is then:

> **Total Non-Comparable = Σ\_k  w(k) · FY(N−k) openings**, and
> **Total Comparable = EOP − Total Non-Comparable** (plug; see §1.6).

**Worked weights.** Chipotle (in operation ≥ 13 months ⇒ R = 13): w(0)=1,
w(1)=(13−12)/12=**1/12**, w(2)=0 → 2 rows. Texas Roadhouse (18 months before the
beginning ⇒ R = 30): w(0)=1, w(1)=1, w(2)=(30−24)/12=**6/12 = ½**, w(3)=0 → 3
rows. A 17-month in-operation rule (R = 17): w(0)=1, w(1)=(17−12)/12=**5/12**.

### 1.3 — Combine any further non-comparable sub-buckets into one cohort

Some issuers report a finer age-bucket breakdown within the non-comparable
cohort (e.g. <6 months open vs. 6–12 months open, or <12 months vs. 12–24
months). For consistency across **every** comparable-stores company modeled in
this build, **always collapse any such issuer-provided sub-buckets into a
single Non-Comparable cohort**. The build does **not** carry an internal
age-based split (no `<6mo` row, no `6-to-T` row, no `Subtotal — less than 6
months` row). The only structure preserved inside Non-Comparable is the
**fiscal year in which the units were opened** — one row per contributing year
(Current Yr, Previous Yr, and, if the threshold reaches further back, one or
more older prior FYs).

**Why a single cohort.** A standard two-bucket layout (Comparable vs.
Non-Comparable) makes companies directly comparable in downstream revenue
sections regardless of how the issuer chooses to slice the non-comp pool.
Issuer age cuts vary in their break points (some at 6mo, some at 12mo, some
not at all), so collapsing them produces a more portable model and avoids
forcing each name into an artificial 6mo / 6-to-T split that the disclosure
may not even support.

**Combination rule when the issuer pre-splits.** If a 10-K, supplement, or
investor deck breaks the non-comparable pool into sub-buckets (e.g.
"Restaurants in operation less than 6 months" and "Restaurants in operation
between 6 and 18 months"), **sum those sub-buckets** into the single
Non-Comparable cohort total, and then express the breakdown by **year of
opening** using the framework in §1.4. Do **not** mirror the issuer's
age sub-bucket labels in the workbook.

**Multi-brand / multi-segment.** The same rule applies brand by brand: per
brand, sum any issuer sub-buckets into one Non-Comparable cohort and break it
down by fiscal year of opening only.

### 1.4 — Explicit weights by threshold and anchor

Apply the weight `w(k) = clamp((R − 12·k)/12, 0, 1)` from §1.2. Each
year-of-opening row holds **openings × weight**, not the whole year. The current
year is always full; **only the boundary year is fractional**. Lay down one row
for each k = 0 … ceil(R/12) − 1. **Always confirm `T` and the anchor against the
10-K (§1.1) before choosing `R`.**

**"In operation for at least T months" anchor (R = T)** — e.g. Chipotle,
Cheesecake Factory:

| T (months) | R | Year-of-opening rows (weights) |
|---|---|---|
| 12 | 12 | Current ×1 only |
| 13 | 13 | Current ×1; **Previous ×1/12** |
| 15 (≈65 wks) | 15 | Current ×1; **Previous ×3/12 (¼)** |
| 17 | 17 | Current ×1; **Previous ×5/12** |
| 18 | 18 | Current ×1; **Previous ×6/12 (½)** |
| 24 | 24 | Current ×1; Previous ×1 |

**"Open T months before the beginning of the period" anchor (R = T + 12)** —
e.g. Texas Roadhouse, Darden:

| T (months) | R | Year-of-opening rows (weights) |
|---|---|---|
| 12 | 24 | Current ×1; Previous ×1 |
| 18 | 30 | Current ×1; Previous ×1; **2 FYs Prior ×6/12 (½)** |
| 24 | 36 | Current ×1; Previous ×1; 2 FYs Prior ×1 |

**"Open throughout both periods" anchor (R = 24):** Current ×1; Previous ×1.

#### General rule (any R)

Let **k\* = ceil(R/12) − 1** (the boundary year). Lay down a Non-Comparable
year-of-opening row for **each** k = 0, 1, …, k\*, each holding
`w(k) · FY(N−k) openings`:

- k = 0 … k\*−1 → weight **1** (full year; write the bare `= <openings>`).
- k = k\* (the boundary year) → weight **(R − 12·k\*)/12 = (R mod 12)/12** (which
  equals **1** when R is an exact multiple of 12, e.g. R = 24 or 36).

Then **Total Non-Comparable = Σ w(k)·FY(N−k) openings** and **Total Comparable =
EOP − Total Non-Comparable**. There is **no internal age sub-bucketing** inside
Non-Comparable — only weighted year-of-opening rows.

Row counts: **ceil(R/12)** year-of-opening rows ⇒ R = 12 → 1 row; R = 13–24 →
2 rows; R = 25–36 → 3 rows; R = 37–48 → 4 rows.

**Round each row to whole restaurants** (`ROUND(…, 0)`): the boundary year's
weighted count is fractional, but restaurants are whole units, so the displayed
cohort counts (and their totals) must be **integers**, not values like `25.3`.
Round only the resulting **count** — never round the **weight** up to a full year
(see §1.6).

> **Why fractional, not rounded.** Counting the **whole** boundary year
> overstates Non-Comparable and understates Comparable. For an "in operation for
> 13 months" issuer (R = 13), the window reaches only **one month** into the
> prior year, so only **1/12** of that year's openings are still ramping —
> tagging the full 12/12 would wrongly classify a whole extra year of mature
> units as non-comparable. The fractional weight is more accurate **and** stays
> consistent across periods, so comp-vs-non-comp **trends** remain clean.

### 1.5 — Build the cohort row block (one per brand)

For **each restaurant concept / brand** the parent operates (the same set the
location roll-forward enumerated), lay down one cohort block. Single-brand
operators get one block; multi-brand parents get one block per brand (Texas
Roadhouse, Inc. gets three: Texas Roadhouse, Bubba's 33, Jaggers).

The block has five logical zones: **(0) cohort assumptions** (the single-value
threshold `T`, effective reach `R`, and stub-year fraction that drive the
math), **(a) cohort lookback inputs** (the prior fiscal years' openings the
cohort math needs and that the Location section does not already contain),
**(a′) the base-year seed** (three rows, base column only, that give §2 the
prior-year comparable count its seed divides by — §1.6), **(b) the weighted
year-of-opening rows** (each = openings × weight, computed from the
inputs/Location openings and the assumptions), and **(c) the totals + memo**. There is a **single** Non-Comparable cohort — no internal age
sub-bucketing. Layout (all label text in Col C):

```
<Concept>                                                                                        [concept header: bold + underlined, indent 0]
  ⤷ Cohort assumptions (single values; not per-period)                                           [italic note, size 11, gray]
    Months to enter comp base                                     (months)                       [deepKPI/10-K INPUT, one cell — T, the comparable threshold (§1.1)]
    New-store window                                              (months)                       [INPUT or FORMULA, one cell — R, the effective reach (§1.1): = T, T+12, or 24 by anchor; comment which anchor was read]
    Stub-year fraction                                            (x)                            [FORMULA, one cell — (R mod 12)/12, or 1 when R is a multiple of 12]
  ⤷ Cohort lookback inputs (deepKPI; read across by period)                                      [italic note, size 11, gray]
    [Openings three fiscal years ago — only if ceil(R/12) ≥ 4]    (stores)                       [deepKPI INPUT row]
    [Openings two fiscal years ago — only if ceil(R/12) ≥ 3]      (stores)                       [deepKPI INPUT row]
    Openings one fiscal year ago                                  (stores)                       [deepKPI INPUT row — only if ceil(R/12) ≥ 2]
  ⤷ Base-year seed (base column only; one fiscal year before the window)                         [italic note, size 11, gray]
    EOP restaurants — one fiscal year before the window           (stores)                       [INPUT, base col only; dash elsewhere]
    Openings <k*+1> fiscal years ago                              (stores)                       [INPUT, base col only; omit if k* = 0]
    Comparable cohort — one fiscal year before the window         (stores)                       [FORMULA = EOP − Σ ROUND(openings × w(k), 0), or INPUT = reported comparable count; base col only]
                                                                  ← one blank spacer row HERE only
  Non-Comparable Cohort                                                                          [sub-header: bold + underlined, indent 1]
    [Opened 3 FYs Prior — only if ceil(R/12) ≥ 4]                 (stores)                       [FORMULA = ROUND(openings × w(3), 0)]
    [Opened 2 FYs Prior — only if ceil(R/12) ≥ 3]                 (stores)                       [FORMULA = ROUND(openings × w(2), 0)]
    Opened in Previous Yr                                         (stores)                       [FORMULA = ROUND(openings × w(1), 0); boundary rounds to whole]
    Opened in Current Yr                                          (stores)                       [FORMULA — ref to Locations; always ×1, whole]
  Total Non-Comparable Cohort                                     (stores)                       [FORMULA sum; bold; SUM-BAR]
  Total Comparable Cohort                                         (stores)                       [FORMULA plug; bold; SUM-BAR]
    Memo: Comparable as % of total                                (% of EOP Balance)             [FORMULA; italic]
```

The blank spacer rule below applies to the **inputs zone → `Non-Comparable
Cohort` sub-header** boundary as before; the assumptions zone (0) sits directly
above the lookback inputs with no extra blank row between zones (0) and (a).

**Row-spacing rule (strict):** the **only** blank spacer row inside a concept's
cohort block is the **single** row between the lookback-inputs zone and the
`Non-Comparable Cohort` sub-header. From `Non-Comparable Cohort` **through
`Total Comparable Cohort`** — including the sub-header, every year-of-opening
line item, and the two grand-total rows — there are **zero blank rows**. The
block reads as one tight stack so the visual flow `sub-header → items →
total non-comp → total comp` is preserved. The `Memo: Comparable as % of
total` row sits **immediately** below `Total Comparable Cohort` (no blank
row above the memo). A single blank spacer row follows **after** the memo to
separate this concept's block from the next concept.

**Label-text rule (strict):** **row labels in Col C are plain descriptive
text only** — `Opened 3 FYs Prior`, `Opened 2 FYs Prior`, `Opened in Previous
Yr`, `Opened in Current Yr`, `Total Non-Comparable Cohort`, `Total Comparable
Cohort`. **Do not** append the formula or its operand recipe (e.g.
` (FY(N-2) opens)`, ` (FY(N-1) opens)`, ` (FY(N) full)`) to the visible row
text — that information goes in the **cell comment** on the label cell (see
"Formula-in-comment rule" below). Users who need to verify a value can either
click the value cell and read the formula in the formula bar or hover the
label cell to read the comment. The visible Col C text should stay short
enough that the column width (~50 chars) does not have to grow.

**Formula-in-comment rule:** for every **formula** row in zones (b) and (c)
(i.e. every row whose values are computed, not deepKPI inputs), attach a
**cell comment** to the **Col C label cell** (not to the value cells). The
comment states, in one or two short lines, the formula used and what it
represents — e.g. for the `Opened 2 FYs Prior` row in a Texas Roadhouse build
(R = 30, boundary year, weight ½):

> `Formula: = <Openings two fiscal years ago> * Stub-year fraction`
> `= w(2) × FY(N-2) opens; boundary year ⇒ weight (R mod 12)/12 = 6/12 = ½`

Comments are roughly **320 × 80 pixels** so the two lines fit cleanly.
Author = `Cohort Build` (or the build's standard author string). **Do not**
add cell comments on the deepKPI input rows in zone (a) — provenance there
is already carried by the value cell's hyperlink, and the row label
("Openings two fiscal years ago") is self-explanatory.

The number of input rows in zone (a) equals **k\* = ceil(R/12) − 1** (one per
prior contributing year):
- R = 12: **no** lookback input rows (current year only — the prior year is
  fully comparable).
- R = 13–24: **one** lookback input row (FY(N-1)).
- R = 25–36: **two** lookback input rows (FY(N-2), FY(N-1)).
- R = 37–48: **three** lookback input rows.

(Chipotle, R = 13 → one lookback row; Texas Roadhouse, R = 30 → two.)

Indentation, fonts, and borders follow the **styling contract** the way the Location
section does: concept header bold + underlined at `Alignment(indent=0)`, italic-gray
zone labels at `Alignment(indent=1)`, the `Non-Comparable Cohort` sub-header bold +
underlined at `Alignment(indent=1)`, year-of-opening line items at
`Alignment(indent=2)`, the `Total Non-Comparable Cohort` and `Total Comparable Cohort`
rows bold with the SUM-BAR (a single thin top border across the data columns only),
memo row italic. Indent is the cell's real indent property — never leading spaces.

**The only three italic-gray rows in this block are the `⤷ Cohort assumptions`,
`⤷ Cohort lookback inputs` and `⤷ Base-year seed` zone labels above** — they
*head* the rows beneath them, so they stay. **No footnote-style note rows go inside
the block.** The comparable definition, the framework formula, the universe, the
comp series and every other basis statement are recorded **once**, in the **Notes
block** at the bottom of the build (§5.5) — never interleaved between the cohort
rows.

### 1.6 — The formulas (cell-by-cell) for the cohort block

Lay down a small **assumptions** sub-zone first (single cells, not per-period),
then the lookback inputs, then the **weighted** year-of-opening rows. Row labels
below are the **plain Col C text**. Every value cell is a **live formula** except
the threshold `T` and the lookback openings, which are inputs.

**Assumptions (one cell each — put the value in a single cell, e.g. the first
period column, and reference it absolutely):**

| Row (plain Col C label) | Lays when | Units (Col D) | Cell |
|---|---|---|---|
| `Months to enter comp base` | | `(months)` | **input** — `T`, the comparable threshold from the 10-K (13 for Chipotle, 18 for TXRH). Blue/input style. Comment: *"Months a restaurant must be open before it enters the comparable base, per the 10-K's comparable definition."* |
| `New-store window` | | `(months)` | `R`, the effective reach: `= T`, `= T + 12`, or `24` per the anchor (§1.1). Comment: *"Months of openings still counted as new (non-comparable) this year: the threshold under an in-operation-through-the-period anchor, threshold + 12 under a before-the-period-start anchor, 24 under an open-throughout-both-periods anchor. Anchor read: <quote>."* |
| `Stub-year fraction` | | `(x)` | `= (R − 12*(CEILING(R/12,1) − 1)) / 12` → returns `(R mod 12)/12`, or **1** when R is a multiple of 12. Comment: *"Fraction of the oldest lookback year's openings still non-comparable: (new-store window mod 12) ÷ 12, or 1 when the window is a whole number of years."* |

**Lookback inputs (zone a), one row per prior contributing year k = 1 … k\*:**

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula |
|---|---|---|---|
| `Openings one fiscal year ago` | | `(stores)` | deepKPI **input** — openings for the FY **one year before** column N; where that FY is already in the Location window it may instead be `= <Location Company Openings, prior column>`. Green fill, blue font, hyperlinked. No comment. |
| `Openings two fiscal years ago` (only if k\* ≥ 2) | | `(stores)` | deepKPI input — openings **two** FYs before column N. Same styling. |
| `Openings three fiscal years ago` (only if k\* ≥ 3) | | `(stores)` | as above, **three** FYs before. |

**Base-year seed (zone a′) — values in the base (leftmost) column only; every
other column, historical and projection, is a dash.** These rows give §2 the
prior-year comparable count its seed divides by. The window never grows a
column for them: the cells sit in the base column, their labels carry the year
offset, and their provenance hyperlinks point at the earlier filing or series.

| Row (plain Col C label) | Lays when | Units (Col D) | Base-column cell |
|---|---|---|---|
| `EOP restaurants — one fiscal year before the window` | | `(restaurants)` | deepKPI / 10-K **input** — the company-owned (§1.8) period-end count for FY(M−1). Input style, hyperlinked. |
| `Openings <k\*+1> fiscal years ago` | | `(restaurants)` | deepKPI / 10-K **input** — openings for FY(M−1−k\*), one year further back than zone (a) reaches (label follows zone (a)'s naming: `two` when k\* = 1, `three` when k\* = 2). Omit when k\* = 0. Sourced like every other opening: the deepKPI series first, then the 10-K development tables (§1.7). |
| `Comparable cohort — one fiscal year before the window` | | `(restaurants)` | **If the issuer reports a comparable count for FY(M−1): input**, that figure (green or gold, hyperlinked) — the issuer's own count beats the model. **Otherwise formula**, the same arithmetic as `Total Comparable Cohort` shifted one year left: `= <EOP, one FY before> − <Openings one fiscal year ago, base col> − ROUND(<Openings two fiscal years ago, base col> × $<Stub-year fraction>, 0)` for k\* = 1, extending by one `ROUND(openings × w(k), 0)` term per further contributing year, each year's openings taken from zone (a)'s base cell or the row above. Comment on the label cell states the formula or the source. |

§2.4 references the third row for its base-column denominator; nothing else
reads these rows.

**Weighted year-of-opening rows (zone b) — each `= openings × w(k)`:**

| Row (plain Col C label, in order) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Opened 3 FYs Prior` (only if k\* ≥ 3) | DATA_DEPENDENT | `(stores)` | full year `= <Openings three fiscal years ago>`, or — if it is the boundary year — `= ROUND(<Openings three fiscal years ago> * $<Stub-year fraction>, 0)` | `"= w(3) × FY(N-3) opens; boundary ⇒ rounded to whole units"` |
| `Opened 2 FYs Prior` (only if k\* ≥ 2) | DATA_DEPENDENT | `(stores)` | full year `= <Openings two fiscal years ago>`, or — if FY(N-2) is the boundary year (e.g. R=30) — `= ROUND(<Openings two fiscal years ago> * $<Stub-year fraction>, 0)` | `"= ROUND(w(2) × FY(N-2) opens, 0); boundary ⇒ × (R mod 12)/12, rounded to whole units"` |
| `Opened in Previous Yr` | | `(stores)` | full year `= <Openings one fiscal year ago>`, or — if FY(N-1) is the boundary year (e.g. R=13 ⇒ ×1/12) — `= ROUND(<Openings one fiscal year ago> * $<Stub-year fraction>, 0)` | `"= ROUND(w(1) × FY(N-1) opens, 0); boundary ⇒ × (R mod 12)/12 (R=13 ⇒ 1/12), rounded to whole units"` |
| `Opened in Current Yr` | | `(stores)` | `= <Company Openings cell in the Location section, same column>` | `"= w(0) × FY(N) opens = ALL current-year openings (always fully non-comparable)"` |
| `Total Non-Comparable Cohort` | | `(stores)` | `= SUM(` the weighted year-of-opening rows above `)` | `"Σ w(k)·FY(N-k) openings. No internal age sub-buckets."` |
| `Total Comparable Cohort` | | `(stores)` | `= <EOP Balance from the Location section> − <Total Non-Comparable Cohort>` | `"Plug: EOP − Non-Comparable. Comp + Non-Comp = EOP exactly."` |
| `Memo: Comparable as % of total` | | `(% of EOP Balance)` | `= <Total Comparable Cohort> / <EOP Balance>` (percent) | `"Comparable / EOP"` |

**Which row gets the fractional weight.** Exactly **one** year-of-opening row —
the boundary year FY(N−k\*), k\* = ceil(R/12) − 1 — is multiplied by the
`Stub-year fraction` cell. All shallower prior years (k < k\*) are full
(`= <openings>`), and the current year is always full. So:

- **Chipotle (R = 13, k\* = 1):** one lookback row; `Opened in Previous Yr =
  ROUND(<one FY ago> * $<weight>, 0)` with weight = 1/12; `Opened in Current Yr =
  <Location openings>`. ⇒ Non-Comparable = current openings + ROUND((1/12)·prior
  openings).
- **Texas Roadhouse (R = 30, k\* = 2):** two lookback rows; `Opened in Previous
  Yr = <one FY ago>` (full, w=1); `Opened 2 FYs Prior = ROUND(<two FYs ago> *
  $<weight>, 0)` with weight = ½ (boundary); `Opened in Current Yr = <Location
  openings>`.

The **`Opened in Current Yr`** cell **must reference the Location section's
Company Openings** cell so a single edit there flows through. The `Total
Comparable Cohort` is always a **plug** (`EOP − non-comp`) so the identity
**Comp + Non-Comp = EOP** holds exactly.

**Round to whole restaurants.** The stub-year fraction yields a fractional count,
but restaurants are whole units — so wrap the boundary row in `ROUND(…, 0)` (the
full-weight rows are already integers). `Total Non-Comparable Cohort` then sums
whole numbers and `Total Comparable Cohort` (EOP − Non-Comparable) stays an exact
integer. Display **all** cohort rows as **whole restaurants** (`#,##0`), matching
the Location counts above — no `25.3`-style fractional units. (Round only the
displayed **count**; never round the **weight** itself up to a full year.)

**If the issuer reports its own non-comparable sub-buckets** (e.g. a 10-K
table breaking the pool into "<6 months" and "6-to-18 months" lines), **do
not** mirror those buckets as rows in the workbook. Sum the issuer's
sub-buckets to a single non-comparable total, then express the breakdown via
the weighted year-of-opening rows above. The issuer's published total is a
useful sanity check against `Total Non-Comparable Cohort` (§1.10), but it does
not change the row structure.

### 1.7 — Sourcing the lookback inputs

For the cohort block to be self-contained, the **lookback input rows** must
pull openings for fiscal years that are **not in the Locations build window**.
For a build window of FY(M)…FY(N) (currently the last 4 FYs), the lookback
inputs need:

- **FY(M-2)** opens (for the FY(M) column's "two years ago" cell)
- **FY(M-1)** opens (for the FY(M) column's "one year ago" cell, and reused for
  the FY(M+1) column's "two years ago" cell)
- All fiscal years already in the Locations openings row are reused as
  formulas in the cohort lookback rows where their period falls.
- **For the base-year seed (zone a′, §1.6):** the **FY(M-1) period-end
  company-owned count** and **FY(M-1-k\*)** opens (FY(M-2) for a 13-month
  issuer, FY(M-3) for an 18-months-before-the-beginning issuer), unless the
  issuer reports a comparable count for FY(M-1), in which case that count is
  pulled instead and the openings row is still laid.

In practice, for an 18-month-threshold issuer with a 4-year build window
(FY2022–FY2025), the lookback rows hold these values per column:

| Period column | "Two years ago" cell holds | "One year ago" cell holds |
|---|---|---|
| FY2022 | FY**2020** opens (new input) | FY**2021** opens (new input) |
| FY2023 | FY**2021** opens (new input) | FY**2022** opens (= Locations row) |
| FY2024 | FY**2022** opens (= Locations row) | FY**2023** opens (= Locations row) |
| FY2025 | FY**2023** opens (= Locations row) | FY**2024** opens (= Locations row) |

The cells holding values that are already in the Locations openings row
**may** be formulas (`=<column in Locations row>`) for traceability, or they
may be re-pulled as deepKPI inputs — both are acceptable. Use re-pulled inputs
when it is simpler (one consistent input series) or use formulas when it makes
the data flow more transparent. **Either way, every cell carries a deepKPI
hyperlink** (input cells via `cell.hyperlink`; formula cells inherit
provenance from the referenced input cell).

Pull the openings from the **same KPI series** the Location section's
`Company Openings` row drew from — typically `<Brand> company restaurant
openings - Annual` — the company-owned universe, per §1.8; never the sum of
company + franchise openings. That series is often sparse (the location build's
§2.5 says so), and the location build pulled filings for the window years only:
where a pre-window year is missing from deepKPI, take it from **that fiscal
year's 10-K** Item 1 development table yourself, styled as a **10-K override**
cell with the filing cited in its comment, exactly as the location build styles
its own overrides. The same applies to the base-year seed inputs (zone a′).

For the earliest cohort columns, the lookback may go before a concept's
existence (e.g. Bubba's 33's first year was FY2014, so FY2013 opens are zero;
Jaggers's first year was FY2014). Use **zero (display as dash)** for those
cells, **not** blank — formulas downstream will return `#VALUE!` on blank
operands.

### 1.8 — Cohort universe: company-owned only

The cohort partition is built on the **company-owned** universe — the concept's
`Company-Operated EOP Balance` row in the Location section, with the lookback and
current-year openings referencing the **Company Openings** row / KPI series.
There is no total-system option: the cohort math partitions **company-operated
revenue** (§2, §3), and franchise restaurant sales never pass through the income
statement, so a systemwide count has no dollar base to pair with. A system comp
may only ever be a **rate**, never a dollar base.

- If the issuer reports comp sales **only for company restaurants** (the most
  common pattern, including Texas Roadhouse, Darden), use that comp.
- If the issuer reports comp sales **only on a systemwide basis** (company and
  franchised units together — used by some QSR franchisors), **this build does not
  apply**. The router's A criteria test this universe from the comp caption, so
  this build should not have been reached; if it was, return the **`ABORTED`**
  hand-back ("Aborting the build", above). The system comp is applied as a
  documented proxy rate in the comparable-sales-growth build instead.
- If the issuer reports **both** a company (or consolidated) comp and a
  franchise or system comp, use the company comp here; the franchise comp is
  consumed by the franchise revenue block (§4, Mode A), never by a second cohort
  block.

State the universe and the comp series used as one line in the Notes block
(§5.5), so the basis is auditable: `Revenue: cohorts and comps are company-owned
restaurants; comp series: <caption>.` No note row goes beneath the section
sub-header.

### 1.9 — Multi-brand parents

For a parent operating multiple restaurant concepts, **build one cohort block
per brand**. Follow the universe rule (§1.8) per brand — every brand runs on the
company-owned universe.

Do **not** build a single consolidated cohort across brands. Such a sum would
mix brands with potentially different age thresholds (some multi-brand groups
use a different comp definition per concept), different universes, and very
different unit economics. The consolidated comp-sales line that downstream
revenue sections will need is sourced **directly from the issuer's reported
consolidated comp %**, not synthesized from per-brand cohort counts.

### 1.10 — Pre-delivery checklist (Location Cohort section)

Before declaring this section done and moving to the next revenue sub-section,
verify every item:

- [ ] The Notes block (§5.5) **quotes (or closely paraphrases) the comparable
      definition** from the 10-K, citing the filing year.
- [ ] The Notes block and the cohort assumptions cells state **T**, the
      **anchor**, the resulting **effective reach R** (= T, T+12, or 24), and
      the **stub-year fraction** `(R mod 12)/12`, plus which **year-of-opening
      rows** are laid down (per §1.2, §1.4).
- [ ] **No footnote-style note rows sit inside the cohort block.** The only
      italic-gray rows there are the `⤷ Cohort assumptions`, `⤷ Cohort lookback
      inputs` and `⤷ Base-year seed` zone labels (§1.5); every basis statement
      is a line in the Notes block (§5.5).
- [ ] The Non-Comparable cohort is a **single block** — no internal age
      sub-bucket headers (no `Stores opened 6 – <T> months ago …`, no
      `Stores opened in last 6 months …`, no `Subtotal — less than 6 months`).
      Only the year-of-opening line items appear.
- [ ] The **number of year-of-opening rows** is **ceil(R/12)**: 1 row for
      R = 12 (Current only), 2 rows for R = 13–24 (+ `Opened in Previous Yr`),
      3 rows for R = 25–36 (+ `Opened 2 FYs Prior`), 4 rows for R = 37–48.
- [ ] Exactly **one** year-of-opening row — the boundary year FY(N−k\*) — is
      multiplied by the **fractional** `Stub-year fraction` `(R mod 12)/12`
      (e.g. R = 13 ⇒ `Opened in Previous Yr` × 1/12; R = 30 ⇒ `Opened 2 FYs
      Prior` × ½). Shallower prior years and the current year are full (×1). Do
      **not** round the *weight* up to a full year.
- [ ] Each weighted year-of-opening row is **rounded to a whole restaurant**
      (`ROUND(…, 0)`) and **all cohort rows display as integers** (`#,##0`) — no
      fractional units like `25.3`. `Comparable + Non-Comparable = EOP` still
      holds exactly (integer − integer).
- [ ] If the issuer publishes its own non-comparable sub-buckets, those have
      been **collapsed** into the single cohort here; the workbook does not
      mirror issuer age-band labels.
- [ ] Exactly **one cohort block per brand**; no consolidated cross-brand
      block.
- [ ] The **universe** is company-owned (§1.8), the comp series used is the
      company (or consolidated-company) comp, and both are stated in the Notes
      block (§5.5).
- [ ] **Lookback input rows** are present — **ceil(R/12) − 1** rows (one for
      R = 13–24, two for R = 25–36) — each styled per the deepKPI input
      convention (green fill, dark blue font, hyperlinked to the matching
      `<Brand> company restaurant openings - Annual` series).
- [ ] **Base-year seed rows** (zone a′) are present with values in the base
      column only: the FY(M−1) period-end count, the FY(M−1−k\*) openings, and
      `Comparable cohort — one fiscal year before the window` as either the
      reported FY(M−1) comparable count (input) or the shifted cohort formula;
      every other column of those rows is a dash.
- [ ] Every cell that is not a lookback or base-year seed input is a **live `=`
      formula** (no hardcoded numbers). The `Opened in Current Yr` cell references the
      Location section's openings cell; the Comparable cell is `EOP −
      non-comp`; the memo row is `comp / EOP`.
- [ ] After recalculation (LibreOffice / `recalc.py`), there are **zero
      formula errors** and the identity **Comparable + Non-Comparable = EOP**
      holds **exactly** for every brand and every period (rounding included).
- [ ] If the issuer reports a **comparable count** in the MD&A (e.g. "Comparable
      restaurants (586 and 549 units)"), spot-check that the modeled
      Comparable Cohort is **within a small fraction** of the reported figure
      for the most recent FY — typically **within ~2% (1–10 stores)**. Larger
      gaps (>5%) flag either a misunderstanding of the issuer's comp definition
      (likely T or universe wrong) or a data problem in the openings series.
      Record the comparison and its result in `BUILD_LOG.md`, not in the Notes
      block; resolve before proceeding.
- [ ] **Row-spacing rule (§1.5):** the only blank spacer row inside each
      concept's cohort block sits **between the lookback-inputs zone and the
      `Non-Comparable Cohort` sub-header**. From `Non-Comparable Cohort`
      through `Total Comparable Cohort` (inclusive of the sub-header, every
      year-of-opening line item, and the two grand totals) there are **zero
      blank rows**. The `Memo:` row sits immediately below
      `Total Comparable Cohort`. One blank row follows the memo to separate
      concept blocks.
- [ ] **Label-text rule (§1.5):** Col C row labels are **plain descriptive
      text only** (`Opened 3 FYs Prior`, `Opened 2 FYs Prior`,
      `Opened in Previous Yr`, `Opened in Current Yr`,
      `Total Non-Comparable Cohort`, `Total Comparable Cohort`). No formula
      recipe (e.g. `(FY(N-2) opens)`) appended to the visible label.
- [ ] **Formula-in-comment rule (§1.5):** every **formula** row in the
      year-of-opening / totals zone has a **cell comment on its Col C label
      cell** stating the formula in plain text (e.g. *"= w(1) × FY(N-1) opens;
      boundary ⇒ × (R mod 12)/12 = 1/12"*). Deep-KPI **input** rows in the
      lookback zone do **not** get cell comments (provenance is already carried
      by the value cell's hyperlink).
- [ ] All formatting (Calibri 12, accounting number format, indentation,
      bold/border conventions, freeze panes) matches
      `../../../../_common/revelata-excel-styling-rules.md`.

### 1.11 — Worked example A — Texas Roadhouse FY2022 – FY2025 (R = 30)

Texas Roadhouse, Inc. (3 concepts: Texas Roadhouse, Bubba's 33, Jaggers) defines
comp as **open 18 months before the beginning of the period** (2025 10-K MD&A),
on the **company-owned** universe. That is the "before the beginning" anchor, so
**R = T + 12 = 30** and **k\* = ceil(30/12) − 1 = 2**: three year-of-opening rows
with weights w(0) = 1, w(1) = 1, **w(2) = (30 mod 12)/12 = 6/12 = ½** (the
`Opened 2 FYs Prior` boundary row is halved, **not** rounded to full).

**Lookback input values** by concept and period column (deepKPI: `<Brand>
company restaurant openings - Annual`):

| Concept | Cell | FY2022 col | FY2023 col | FY2024 col | FY2025 col |
|---|---|---|---|---|---|
| Texas Roadhouse | Openings two FYs ago | **18** (FY20) | **29** (FY21) | **18** (FY22) | **22** (FY23) |
| Texas Roadhouse | Openings one FY ago  | **29** (FY21) | **18** (FY22) | **22** (FY23) | **26** (FY24) |
| Bubba's 33      | Openings two FYs ago | **3** (FY20)  | **5** (FY21)  | **4** (FY22)  | **5** (FY23)  |
| Bubba's 33      | Openings one FY ago  | **5** (FY21)  | **4** (FY22)  | **5** (FY23)  | **4** (FY24)  |

**Resulting cohort partition** (formulas applied; `Opened 2 FYs Prior` × ½, then
each row **rounded to whole restaurants** per §1.6):

| Concept | Period | Company-Operated EOP | Opened 2 FYs Prior × ½ (rounded) | Opened in Previous Yr | Opened in Current Yr | Total Non-Comp | **Modeled Comparable** | **10-K reported** |
|---|---|---|---|---|---|---|---|---|
| Texas Roadhouse | FY2025 | 648 | 11 | 26 | 20 | 57 | **591** | **586** |
| Texas Roadhouse | FY2024 | 608 | 9 | 22 | 26 | 57 | **551** | **549** |
| Texas Roadhouse | FY2023 | 582 | 15 | 18 | 22 | 55 | **527** | (not disclosed) |
| Texas Roadhouse | FY2022 | 552 | 9 | 29 | 18 | 56 | **496** | (not disclosed) |
| Bubba's 33 | FY2025 | 56 | 3 | 4 | 7 | 14 | **42** | **41** |
| Bubba's 33 | FY2024 | 49 | 2 | 5 | 4 | 11 | **38** | **37** |

Modeled Comparable lands within **~1% (1–5 stores)** of the disclosed counts for
the most recent fiscal years. With the boundary year **halved** rather than
rounded up, the model now sits slightly **above** the disclosed figure (e.g.
TXRH FY2025: 591 vs 586) instead of below — both within the ±2% tolerance
(§1.10). Residual gaps come from non-uniform opening timing, not from the
framework.

### 1.11b — Worked example B — Chipotle FY2022 – FY2025 (R = 13)

Chipotle Mexican Grill, Inc. (single concept) defines comp as company-owned
restaurants **in operation for at least 13 full calendar months** (FY2025 10-K
MD&A). That is the "in operation" anchor, so **R = T = 13** and
**k\* = ceil(13/12) − 1 = 1**: two year-of-opening rows with w(0) = 1 and
**w(1) = (13 mod 12)/12 = 1/12** — only **one twelfth** of the prior year's
openings (the final month, still inside its first 13 months) is non-comparable.

**Inputs** (deepKPI total company-owned openings; one lookback row only):
openings FY2021 = 215, FY2022 = 236, FY2023 = 271, FY2024 = 304, FY2025 = 334;
company-owned EOP = 3,187 / 3,437 / 3,726 / 4,042 (FY2022–FY2025).

| Period | Company-Operated EOP | Opened in Previous Yr × 1/12 (rounded) | Opened in Current Yr | Total Non-Comp | **Modeled Comparable** | Comp % |
|---|---|---|---|---|---|---|
| FY2022 | 3,187 | 18 (=ROUND(215/12)) | 236 | 254 | **2,933** | 92.0% |
| FY2023 | 3,437 | 20 (=ROUND(236/12)) | 271 | 291 | **3,146** | 91.5% |
| FY2024 | 3,726 | 23 (=ROUND(271/12)) | 304 | 327 | **3,399** | 91.2% |
| FY2025 | 4,042 | 25 (=ROUND(304/12)) | 334 | 359 | **3,683** | 91.1% |

Chipotle does not disclose a comparable restaurant count, so there is no direct
spot-check; but ~91% comparable is the expected level for a ~9%-unit-growth
operator under a 13-month window (roughly one year plus one month of openings
non-comparable ≈ 9% of the base). Counting the **whole** prior year instead — as
the old "round up" heuristic did — would have pushed non-comparable to ~16% and
understated Comparable by a full extra year of openings.

**Base-year seed for Chipotle.** No comparable count is reported, so the FY2022
column's `Comparable cohort — one fiscal year before the window` is the shifted
formula: FY2021 company-owned EOP − FY2021 openings (215, already in the
lookback row) − ROUND(FY2020 openings × 1/12). The FY2021 period-end count and
the FY2020 openings are the two extra pulls §1.7 lists; deepKPI's restaurant
count and openings series for Chipotle begin later than those years, so both
come from the fiscal 2021 10-K unit activity table as 10-K override cells. The
result is the denominator §2 divides the FY2021 comparable-cohort dollars by.

### 1.12 — What this section produces for downstream sections

After Section 1 is built, the workbook contains, for every brand and every
period in the build window:

- a `Total Comparable Cohort` count (Col E onward), and
- a `Total Non-Comparable Cohort` count broken down by **year of opening only**
  — one **weighted** row each for `Opened in Current Yr`, `Opened in Previous
  Yr`, and (when the reach extends further back) `Opened 2 FYs Prior` / `Opened
  3 FYs Prior`. Each row is `w(k) × FY(N−k) openings`, with the boundary year
  carried fractionally `(R mod 12)/12`. No internal age sub-buckets.

each as a live formula that flows from the Location section's EOP and openings
inputs plus the cohort lookback inputs added by this section. Subsequent
revenue sub-sections (comparable-cohort sales growth bridge, new-unit revenue
contribution, ramping AUV math) reference `Total Comparable Cohort` and
`Total Non-Comparable Cohort` directly; if a downstream section needs to weight
new-unit revenue by opening vintage, it can pick up the individual
year-of-opening rows. Any later change to the underlying location roll-forward
(e.g. an opening-series correction or a forecast year added) will propagate
automatically through the cohort partition and into revenue.

---

## Revenue build — framework overview (Sections 2 – 5)

Section 1 partitioned each brand's units into a **Comparable** and a
**Non-Comparable** cohort. Sections 2 – 6 turn those **unit counts** into
**revenue dollars** and foot the build to the company's **reported total
revenue**. The build follows one fixed framework so that **every**
comparable-stores company is modeled the same way and the workbook always foots.

**The five revenue components and the master identity.** The revenue build
decomposes reported total revenue into four modeled components plus a plug:

```
  Revenue from the Comparable Cohort        (Section 2 — per brand, summed)
+ Revenue from the Non-Comparable Cohort    (Section 3 — per brand, summed)
+ Revenue from Franchises                   (Section 4 — consolidated; only if franchise revenue is reported)
+ Other Revenue                             (Section 5 — plug)
─────────────────────────────────────────
= Total Revenue                             (Section 5 — reported; the anchor / foot)
```

Because **Other Revenue is defined as the plug** (`Total − Comp − Non-Comp −
Franchise`), the four components **sum to reported Total Revenue exactly, by
construction** — that identity is the build's foot/check and must hold for every
brand-set and every period.

**Build the revenue lines in this order**, each beneath the cohort block(s) that
Section 1 laid down:

1. **Section 2 — Revenue from the Comparable Cohort.** A per-brand recursive
   bridge: prior-year comparable-cohort revenue → revenue per comparable
   restaurant → grow by same-store-sales (SSS) → multiply by this year's
   comparable count.
2. **Section 3 — Revenue from the Non-Comparable Cohort.** A blended
   revenue-per-location figure (TRTL) × a **0.5 partial-year factor** × this
   year's non-comparable count.
3. **Section 4 — Revenue from Franchises.** Laid by the shared block
   `../franchiseRevenueBuild/franchiseRevenueBuild.md` — **included only if the
   shared KPI inventory carries a franchise-revenue series** (the block's §1.1).
4. **Section 5 — Other Revenue and Total Revenue.** `Other Revenue` is the plug
   that ties the modeled components to reported total revenue; `Total Revenue` is
   the reported figure the plug closes to — the grand-total foot.

**Conventions that apply to all of Sections 2 – 6 (read once):**

- **Annual columns only.** Like the cohort and location sections, the revenue
  build is **annual** (the comparable-store-sales growth rate and the cohort
  counts are reported annually, not by quarter). Use the **same four annual
  period columns** (Col E onward, oldest → newest) the cohort block uses, so
  every revenue cell sits directly under the matching cohort / location cell.
- **Per brand, then consolidate.** Comparable and Non-Comparable revenue are
  built **one block per brand** — the same brand set, in the same order, as the
  Section 1 cohort blocks — then summed into a consolidated subtotal. Do **not**
  synthesize a single cross-brand comparable bridge; brands can carry different
  SSS rates and different per-store economics. Franchise revenue and Other
  Revenue are **consolidated** lines (Sections 4 – 5).
- **Universe consistency.** Build each brand's revenue on the **company-owned**
  universe Section 1 used for its cohort (§1.8). The comparable / non-comparable
  **counts** this build multiplies are company-owned, so the **revenue** and
  **location** figures it divides by must be too (company-owned restaurant sales
  ÷ company-owned locations). Mixing universes (company sales ÷ system
  locations, or applying a comp count to systemwide revenue) silently corrupts
  every per-store figure.
- **Reference Section 1 and the location build — do not re-derive counts.**
  Every store count this build needs already exists in the workbook: the
  comparable / non-comparable cohort counts in the **Section 1 cohort block**
  (referenced by the phrases "# of stores in the comparable cohort" / "in the
  non-comparable cohort" throughout this framework), and the EOP location counts
  / openings in the **location build**. Reference those cells with live `=`
  formulas; never hardcode a count.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (reported revenue, reported SSS %, reported franchise
  revenue, and the base-year lookbacks) are **input cells** (pale-green fill,
  dark-blue hyperlinked value linked to the filing). **Every
  other revenue cell is a live `=` formula** (black font, no fill) — per-store
  figures, the grown estimates, the cohort-revenue products, subtotals, the
  Other plug, and every YoY % row. Never hardcode a computed number.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §1.5, §2.3, §3.3,
  §5.3, §6.2 and §6.3, and, for the franchise rows, the shared block's §2.2 / §3.1
  (`../franchiseRevenueBuild/franchiseRevenueBuild.md`) — and in the `Units (Col D)` column of that
  section's formula table. Dollar rows show the placeholder `(USD in <scale>)`: the contract's
  Rule 2 supplies the scale, millions by default, thousands where the digit test puts a
  small filer. Three classifications are specific to this build:
  - **Section 1 is counts and two assumptions.** Every cohort row — the lookback inputs,
    the weighted year-of-opening rows, `Total Non-Comparable Cohort`, `Total Comparable
    Cohort` — is whole restaurants, tagged `(stores)` — the noun of this
    comparable-*stores* build, used for every count row here regardless of what the
    issuer or deepKPI calls its units; the location build's fleet rows carry
    `(locations)` — and displayed with the counts format (the `ROUND(…, 0)` in §1.6
    keeps them integers). The two month cells are `(months)`. `Stub-year fraction`
    is a pure fraction tagged `(x)`; show it with two decimals so a weight of 1/12 reads
    `0.08`, not `0.1`.
  - **Per-unit money takes the noun of its own label.** PRCC and `Estimated Revenue per
    Comparable Restaurant` are `(USD millions per restaurant)`; `Revenue per Location —
    system avg` is `(USD millions per location)`. Each divides a revenue row in millions
    by a count in ones, so millions per unit is the coherent scale — a reader can divide
    the two rows above and land on the figure (§7: `5,900.0 ÷ 648 = 9.1049`). Never
    round these rows to whole units; they are dollar figures, not store counts.
  - **Percent rows.** `Comparable-Store Sales Growth (SSS)`, its Transactions / Average
    Check / Menu Price / Product Mix component rows, and every `YoY %` row are
    period-over- period changes, so they take the bare `(%)` the contract's Rule 5
    reserves for that case. The two memo percents name their denominator: `Memo:
    Comparable as % of total` is `(% of EOP Balance)`, `Memo: revenue mix by brand` is
    `(% of modeled company sales)`.
- **Reading the layout blocks (§1.5, §2.3, §3.3, §5.3, §6.2, §6.3, and the shared
  block's §2.2 / §3.1).** Each row's
  annotation has two columns, left to right: the **Col D units tag in parentheses** —
  `(USD in <scale>)` means the contract's Rule 2 sets the money scale; every other tag
  is written as it goes in the cell — and the note in **square brackets**: `[deepKPI
  INPUT …]` for a pulled value, `[FORMULA …]` for a computed row, plus styling
  (`SUM-BAR`, `italic`) and any condition on the row's presence. Section sub-headers,
  `⤷` zone labels, brand / concept headers and `<Brand 2> …` repeat markers carry no tag.
  In §6.2 a row with no bracketed note repeats, for that brand, the row of the section
  named on the sub-header above it.
- **Label / comment / spacing discipline (same as §1.5).** Col C labels are
  **plain descriptive text**; the operand recipe for each formula row goes in a
  **cell comment on the Col C label cell** (author `Revenue Build`), not in the
  visible label. Indentation, bold / border, and the one-blank-row-between-blocks
  rule follow `../../../../_common/revelata-excel-styling-rules.md` exactly as the
  cohort section does.

The sub-sections below specify each component cell-by-cell. Build them in order;
do not add revenue lines outside this framework.

---

## Section 2 — Revenue from the Comparable Cohort

This section converts each brand's **Comparable Cohort count** (from §1) into
**comparable-cohort revenue dollars** by carrying prior-year revenue per
comparable restaurant forward at the reported same-store-sales (SSS) growth rate.
It is built **one block per brand**, directly beneath that brand's Section 1
cohort block, then summed into a consolidated comparable-revenue subtotal.

### 2.1 — The bridge and its recursion

For each brand and each period N, comparable-cohort revenue is built from **five
ordered rows**, exactly mirroring the framework:

1. **Previous Year's Revenue from the Comparable Cohort** — the comparable-cohort
   revenue that the *prior* period produced (see the recursion and base-year seed
   below).
2. **Revenue per Comparable Restaurant — prior year (PRCC)** =
   `Previous Year's Revenue from the Comparable Cohort ÷ # restaurants in the
   previous year's comparable cohort`. The denominator is the **prior period's**
   `Total Comparable Cohort` count from §1 (per the framework note: store counts
   always refer to the §1 cohort breakdown).
3. **Comparable-Store Sales Growth (SSS)** — the reported comp-sales growth %
   for the brand and period (§2.2 covers the optional Price / Mix / Transactions
   decomposition).
4. **Estimated Revenue per Comparable Restaurant** = `PRCC × (1 + SSS)`.
5. **Revenue from the Comparable Cohort** = `Estimated Revenue per Comparable
   Restaurant × # of stores in the comparable cohort` — the **current** period's
   `Total Comparable Cohort` count from §1.

**The recursion (why this chains cleanly).** Define the rows for period N as
above. Then `PRCC(N) = PrevCompRev(N) ÷ CompCount(N−1)`. If — as specified below —
`PrevCompRev(N)` is set equal to the **prior period's row 5** (`Revenue from the
Comparable Cohort` of period N−1), and that row 5 equals
`EstRevPerComp(N−1) × CompCount(N−1)`, then:

> `PRCC(N) = EstRevPerComp(N−1) × CompCount(N−1) ÷ CompCount(N−1) =
> EstRevPerComp(N−1)`

i.e. **this year's prior-revenue-per-comparable-restaurant equals last year's
estimated revenue per comparable restaurant**, and the per-store figure simply
**compounds by SSS each year**:
`EstRevPerComp(N) = EstRevPerComp(N−1) × (1 + SSS_N)`. The cohort *count* can grow
year to year (new stores mature into the comparable base); the bridge handles
that by multiplying the per-store figure by the **current** comparable count in
row 5. This recursion is internally consistent and **only the base year needs a
seed**.

**Base-year (leftmost column) seed — DOLLAR comparable-cohort revenue only; NO
blended proxy (STRICT).** The leftmost period column has no prior modeled
comparable revenue, so its row 1 and the row-2 denominator must be seeded from
reported **comparable-cohort dollars** — the exact dollar requirement the router
enforced before routing here (`../restaurants.md`, Section A, situations 1 & 2).
**Do NOT seed the base year from blended brand-wide figures.**

- **Previous Year's Revenue from the Comparable Cohort (base column)** = the
  **prior fiscal year's comparable-cohort dollar revenue**, obtained one of the
  two ways the router required:
  1. **Directly** — the issuer reports the comparable cohort's **dollar revenue**
     for the prior fiscal year → use it as-is (deepKPI input), **or**
  2. **Backed into** — from the reported comparable-store sales growth **%** and
     the reported **dollar change attributable to the comparable cohort**:
     `prior comparable revenue = dollar change ÷ growth %` (a live formula over
     two deepKPI inputs).
  > **FORBIDDEN:** seeding row 1 with the **prior year's full / total company
  > restaurant sales** (blended across all units). That figure includes
  > non-comparable (newer, lower-volume, still-ramping) stores, so it is **not**
  > the comparable cohort's revenue. Using it understates true comparable
  > per-store revenue and silently dumps the error into the Other-Revenue plug —
  > the precise invalid assumption the router's strict dollar requirement exists
  > to prevent. The "any error is absorbed by the Other plug" rationale does
  > **not** license this shortcut: a plug that hides a structural mis-seed is a
  > defect, not a feature.
- **# restaurants in the previous year's comparable cohort (base-column
  denominator)** = the prior fiscal year's **comparable** store count (the
  cohort's own count) — e.g. the issuer's reported comparable / comp-base store
  count for that year. Pull it as a deepKPI input. **Do NOT** use the prior
  year's **total** location count as a proxy for the comparable count: that is
  the same comparable-vs-non-comparable conflation on the denominator side. (When
  situation 1 supplies the cohort's dollar revenue directly, the PRCC denominator
  must still be the **comparable** count, not total units.) The count comes from
  the §1 base-year seed row `Comparable cohort — one fiscal year before the
  window` (§1.6, zone a′): the reported FY(M−1) comparable count where the
  issuer discloses one, otherwise the cohort formula shifted one year left over
  the FY(M−1) period-end count and the FY(M−1−k\*) openings. Do not add a column.

**If neither situation 1 nor situation 2 is available** — you can neither read
the prior comparable cohort's dollars directly nor back into them from a reported
`dollar change ÷ growth %` — then **STOP. Do not improvise a blended-average
seed.** The company did not actually satisfy the comparable-stores routing
criteria (`../restaurants.md`, Section A); this build should not have been
selected. Return the **`ABORTED`** hand-back ("Aborting the build", above); the
router re-routes.

For **every non-base column**, row 1 and the row-2 denominator are **live
formulas** referencing the prior column (no new inputs): row 1 = prior column's
`Revenue from the Comparable Cohort`; denominator = prior column's
`Total Comparable Cohort` (§1).

### 2.2 — SSS growth and its optional Price / Mix / Transactions decomposition

The bridge driver is the **reported comparable-store sales growth %** for the
brand and period — a deepKPI input (e.g. `<Brand> comparable restaurant sales
growth - Annual`, `Comparable restaurant sales` change %, or the consolidated
`Comparable sales growth`). Pull the rate on the **same universe and brand** the
cohort was built on; if the issuer reports comp only at the consolidated level
for a multi-brand parent, see §1.9 (use the reported consolidated comp %; the
Notes line in §2.6 records it).

**Decompose only when the issuer discloses it.** Restaurants commonly break comp
sales into **traffic / transactions** and **average check**, and sometimes split
average check further into **menu price** and **product mix**. When that
granularity is disclosed, lay each disclosed component as its **own deepKPI input
row** beneath the total SSS row:

- `SSS — Transactions / Traffic` (input)
- `SSS — Average Check` (input) — and, if further disclosed:
  - `SSS — Menu Price` (input)
  - `SSS — Product Mix` (input)

Keep the **total reported SSS** as the single value that drives row 4
(`PRCC × (1 + SSS)`). Treat the components as **memo / disclosure rows**, not as
additional bridge drivers — do not multiply the per-store figure by each
component. If the issuer discloses the components but **not** a total, compute the
total on the **same basis the issuer uses**: most present the pieces as
**additive contributions** (`SSS ≈ Transactions% + Average Check%`, and
`Average Check% ≈ Menu Price% + Mix%`), so sum them as a formula and add a comment
noting the additive convention (the exact relationship is multiplicative,
`(1+traffic)(1+check) − 1`, but issuers almost always present additive
contributions). **If no decomposition is disclosed, lay down only the single
total SSS row** — do not invent a split.

### 2.3 — Per-brand comparable block layout

For **each brand** (same set and order as §1), lay one comparable-revenue block
directly beneath that brand's Section 1 cohort block. All label text in Col C;
period values Col E onward (annual):

```
Comparable Cohort Revenue                                                                        [section sub-header: bold + underlined, size 12, indent 0]
<Brand>                                                                                          [concept header: bold + underlined, indent 0]
    Previous Year's Comparable-Cohort Revenue                     (USD in <scale>)               [base col: deepKPI INPUT; else FORMULA = prior col row 5]
    Revenue per Comparable Restaurant — prior yr (PRCC)           (USD millions per restaurant)  [FORMULA = row above ÷ prior-yr comp count §1]
    Comparable-Store Sales Growth (SSS)                           (%)                            [deepKPI INPUT; italic]
      SSS — Transactions / Traffic                                (%)                            [deepKPI INPUT — only if disclosed]
      SSS — Average Check                                         (%)                            [deepKPI INPUT — only if disclosed]
      SSS — Menu Price                                            (%)                            [deepKPI INPUT — only if check split disclosed]
      SSS — Product Mix                                           (%)                            [deepKPI INPUT — only if check split disclosed]
    Estimated Revenue per Comparable Restaurant                   (USD millions per restaurant)  [FORMULA = PRCC × (1 + SSS)]
    Revenue from the Comparable Cohort                            (USD in <scale>)               [FORMULA = est rev/comp × current comp count §1; bold, SUM-BAR]
<Brand 2> …                                                                                      [repeat the five-row block]
Total Revenue from the Comparable Cohort                          (USD in <scale>)               [FORMULA = Σ each brand's row 5; bold, SUM-BAR]
```

**No note rows here.** The section sub-header is followed **immediately** by the
first brand header; the universe and the comp series are stated in the Notes
block (§5.5).

**Row-spacing rule (strict, mirrors §1.5):** within a brand's block there are
**zero blank rows** from `Previous Year's Comparable-Cohort Revenue` through
`Revenue from the Comparable Cohort`. One blank spacer row separates one brand's
block from the next. One blank row precedes `Total Revenue from the Comparable
Cohort`. The optional SSS component rows sit **immediately** beneath the total
SSS row (no blank row above them).

**Indentation / fonts / borders (per the styling contract):** the `Comparable Cohort
Revenue` section sub-header is bold + underlined, size 12, at `Alignment(indent=0)` —
the one sub-header treatment every section uses; the brand header is bold + underlined
at `Alignment(indent=0)`; the five line items are at `Alignment(indent=2)`; SSS
component memo rows are at `Alignment(indent=3)` and italic; `Revenue from the
Comparable Cohort` (row 5) and `Total Revenue from the Comparable Cohort` are bold with
the SUM-BAR. Indent is the cell's real indent property — never leading spaces. Number formats follow each row's Col D
tag (see "Number format and units" in the conventions list above).

**Multi-brand parents:** the per-brand five-row block above is unchanged, but for
a parent with 2+ concepts the canonical workbook organization groups each brand's
**entire** revenue build together (comparable + non-comparable + franchise) and
moves the `Total Revenue from the Comparable Cohort` consolidated total into a
single consolidated revenue table — see **§6**. Single-brand operators keep the
layout exactly as shown here.

### 2.4 — The formulas (cell-by-cell) for the comparable bridge

Row labels are the **plain Col C text**. "Prior col" = the period column
immediately to the left; "§1 comp count (col X)" = that brand's
`Total Comparable Cohort` cell in column X of the Section 1 cohort block.

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Previous Year's Comparable-Cohort Revenue` | | `(USD in <scale>)` | **DOLLAR comparable-cohort revenue only** (§2.1): situation 1 deepKPI **input** (reported prior-FY comparable-cohort dollars), or situation 2 `= <reported dollar change attributable to comparable cohort> ÷ <comp growth %>`. **Never** the prior-FY total/blended company sales. | `= <prior col 'Revenue from the Comparable Cohort'>` | `"Prior-yr comparable-cohort DOLLAR revenue: reported, or backed out of the reported dollar change divided by the comp rate. NOT blended total company sales; else = prior col row 5."` |
| `Revenue per Comparable Restaurant — prior yr (PRCC)` | | `(USD millions per restaurant)` | `= <Previous Year's …Revenue> ÷ <§1 'Comparable cohort — one fiscal year before the window', base col>` (the base-year seed row, §1.6 zone a′ — **not** total locations) | `= <Previous Year's …Revenue> ÷ <§1 comp count (prior col)>` | `"= prior comparable-cohort revenue ÷ prior-yr COMPARABLE count. Base yr: the reported prior-year comparable count, else the shifted cohort formula; NOT total units."` |
| `Comparable-Store Sales Growth (SSS)` | | `(%)` | deepKPI **input** % (reported comp growth), or `= Transactions% + Avg Check%` if only components disclosed | same | `"Reported comparable-store sales growth %, <brand>, <universe>. Drives the bridge."` |
| `SSS — Transactions / Traffic` *(only if disclosed)* | DATA_DEPENDENT | `(%)` | deepKPI **input** % | same | *(no comment — input row; provenance via hyperlink)* |
| `SSS — Average Check` *(only if disclosed)* | DATA_DEPENDENT | `(%)` | deepKPI **input** % | same | *(no comment — input row)* |
| `SSS — Menu Price` / `SSS — Product Mix` *(only if check split disclosed)* | DATA_DEPENDENT | `(%)` | deepKPI **input** % each | same | *(no comment — input rows; memo: Price + Mix ≈ Avg Check)* |
| `Estimated Revenue per Comparable Restaurant` | | `(USD millions per restaurant)` | `= <PRCC> × (1 + <SSS>)` | same | `"= PRCC × (1 + SSS). Compounds prior-yr revenue per comp store by this yr's SSS."` |
| `Revenue from the Comparable Cohort` | | `(USD in <scale>)` | `= <Estimated Revenue per Comparable Restaurant> × <§1 comp count (this col)>` | same | `"= est. revenue per comparable restaurant × this yr's comparable count (cohort block above)."` |
| `Total Revenue from the Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each brand's `Revenue from the Comparable Cohort` `)` | same | `"Σ comparable-cohort revenue across all brands."` |

### 2.5 — Sourcing the base-year lookback inputs

Only the **base (leftmost) column** needs new deepKPI pulls for this section; all
other columns are formulas. The base-year seed must be **comparable-cohort
dollars** (§2.1) — not blended brand-wide figures. Pull, per brand:

- **Prior-FY comparable-cohort dollar revenue** — obtained via §2.1 situation 1
  or 2:
  - *Situation 1:* the issuer's reported **comparable-cohort dollar revenue** for
    the fiscal year immediately before the build window (e.g. for a FY2022–FY2025
    window, pull FY2021).
  - *Situation 2:* the reported **dollar change attributable to the comparable
    cohort** and the reported **comparable-store sales growth %** for that year;
    the seed is then `dollar change ÷ growth %` (a live formula over those two
    inputs).
  **Do NOT** substitute the brand's prior-FY **total / blended** company
  restaurant sales (`<Brand> restaurant sales - Annual`, the income-statement
  company-sales line, etc.) — that mixes comparable and non-comparable units and
  is the forbidden seed. If neither situation is obtainable, return the
  **`ABORTED`** hand-back per §2.1; do not seed from blended sales.
- **Prior-FY COMPARABLE store count** (the PRCC denominator for the base column)
  — not pulled here. It is the §1 base-year seed row `Comparable cohort — one
  fiscal year before the window` (§1.6 zone a′), whose inputs §1.7 lists: the
  reported FY(M−1) comparable count where disclosed, else the FY(M−1) period-end
  count and FY(M−1−k\*) openings. **Do NOT** use the prior-FY **total** location
  count as a "comparable ≈ total" proxy.

Use the **filing / `search_kpis`** path against the shared inventory (do not
re-run `list_kpis`). Where a brand or its sales series did not exist in the
pre-window year, use **zero (display as a dash)**, not blank; a zero comparable
base means that brand's base-column comparable revenue is simply zero; put a cell
comment on that cell (`<Brand> opened in FY<n>; prior-year comparable base is
zero.`) rather than forcing a `÷ 0` division.

### 2.6 — Brand-level vs. consolidated revenue

The comparable bridge is **per brand** because SSS and the cohort counts are per
brand. This requires **brand-level company restaurant sales**:

- **If the issuer discloses brand-level restaurant sales** (e.g. Texas Roadhouse
  reports Texas Roadhouse and Bubba's 33 sales separately), build one comparable
  block per brand as above.
- **If only consolidated company restaurant sales are disclosed**, build a
  **single consolidated comparable block** instead: row 1 seed = prior-FY
  consolidated company restaurant sales; PRCC denominator = the **sum of the
  brands'** `Total Comparable Cohort` counts (a formula summing the §1 per-brand
  comparable counts); SSS = the reported **consolidated** comp %; row 5 multiplier
  = the summed comparable count. Add one line to the Notes block (§5.5):
  `Revenue: the comparable bridge is built for all brands together; brand-level
  restaurant sales and comps are not disclosed.` (The §1 cohort blocks remain
  per brand; only the revenue bridge consolidates.)

Either way the section ends in a single `Total Revenue from the Comparable
Cohort` line that feeds Sections 5 – 6.

### 2.7 — Pre-delivery checklist (Comparable Cohort revenue)

- [ ] One comparable block **per brand** (or one consolidated block per §2.6),
      in the same brand order as the §1 cohort blocks, each on the **same
      universe** §1 used for that brand.
- [ ] The five rows appear in order: `Previous Year's Comparable-Cohort
      Revenue` → `PRCC` → `Comparable-Store Sales Growth (SSS)` → `Estimated
      Revenue per Comparable Restaurant` → `Revenue from the Comparable Cohort`.
- [ ] **Base column (STRICT — §2.1):** row 1 is the prior-FY **comparable-cohort
      dollar revenue** — situation 1 (reported comparable-cohort dollars) or
      situation 2 (`reported dollar change attributable to comparable cohort ÷
      growth %`) — and is **NOT** the prior-FY total/blended company sales; the
      PRCC denominator is the prior-FY **comparable** store count, **NOT** the
      total location count. If neither situation 1 nor 2 is available, the build
      **returned the `ABORTED` hand-back** rather than seeding from a blended proxy.
      **All other columns:** row 1 = `prior col row 5` and the PRCC denominator =
      `§1 Total Comparable Cohort (prior col)` — both live formulas, **no** new
      inputs.
- [ ] PRCC denominator references the **prior** period's comparable count; the
      row-5 multiplier references the **current** period's comparable count (both
      from the §1 cohort block) — not reversed.
- [ ] SSS is a reported deepKPI **input** %; Price / Mix / Transactions rows
      appear **only if disclosed**, as memo input rows that do **not** re-drive
      the bridge. No invented decomposition.
- [ ] `Estimated Revenue per Comparable Restaurant = PRCC × (1 + SSS)` and
      `Revenue from the Comparable Cohort = that × current comparable count` are
      **live formulas**; per-store dollar rows are **not** rounded to whole units.
- [ ] `Total Revenue from the Comparable Cohort` = `SUM` of the per-brand row-5
      cells (formula; SUM-BAR).
- [ ] Row-spacing, plain Col C labels, and formula-in-comment rules match §1.5;
      no note row sits beneath the section sub-header; number formats follow
      each row's Col D tag.
- [ ] After recalculation there are **zero formula errors**, and the recursion
      reads correctly (per-store revenue compounds by SSS; the count change flows
      through the current-year multiplier).

---

## Section 3 — Revenue from the Non-Comparable Cohort

This section values the **Non-Comparable Cohort** — the stores that are too new
to be in the comparable base (the §1 `Total Non-Comparable Cohort` count). New
stores open at different points in the year, so on average they operate only
**part** of the fiscal year; the framework values them at **half a typical
store's annual revenue**. It is built **one block per brand**, beneath that
brand's comparable block, then summed.

### 3.1 — The two rows and the 0.5 partial-year factor

For each brand and period N, non-comparable revenue is built from **two rows**:

1. **Revenue per Location — system average (TRTL)** =
   `Total Revenue ÷ Total Locations` for the brand on its cohort universe — a
   blended average annual revenue per store across the whole brand. Carry a
   **YoY growth** memo row beneath it.
2. **Revenue from the Non-Comparable Cohort** =
   `TRTL × 0.5 × # of stores in the non-comparable cohort`, where the count is
   the **current** period's `Total Non-Comparable Cohort` from §1.

**Why the 0.5 factor.** Non-comparable stores were opened across the fiscal year —
some early, some late — so on average a non-comparable store was open for roughly
**half** the year and therefore earned about **half** of a mature store's full
annual revenue. Multiplying the blended per-store figure (TRTL) by **0.5** before
applying the non-comparable count converts a full-year revenue rate into the
**partial-year** revenue those ramping stores actually contributed. This is a
deliberate, uniform simplification across every company in the build — stores open
in both halves of the year and average out at 0.5 — so do not adjust the 0.5 per
company. It is the same partial-year factor the comparable-sales-growth build
applies to this year's openings. **One stated simplification:** the factor is applied
to the whole non-comparable cohort, so where the issuer's anchor makes last year's
openings non-comparable for a second year (a "before the beginning of the period"
anchor), those restaurants — open for the full current year — are also halved; the
§5 `Other Revenue` plug absorbs the difference historically.

### 3.2 — Defining TRTL (Total Revenue ÷ Total Locations) on the right universe

"TRTL" is the framework's shorthand; in the workbook use a clearer Col C label —
**`Revenue per Location — system avg`** — and define it **on the same universe as
the cohort** (§1.8, the same universe Section 2 used for the brand):

- **Numerator — "Total Revenue":** the brand's **company-owned restaurant sales**
  (the same series Section 2 seeds from), **not** total consolidated revenue. Do
  **not** include franchise royalties / fees in the numerator — those are not
  earned by the company-owned stores whose count is the denominator, and they are
  modeled separately in Section 4. Including them would overstate per-store
  revenue.
- **Denominator — "Total Locations":** the brand's **company-owned EOP location
  count** from the location build (the same universe). Reference the location cell
  with a formula.
So TRTL is a per-brand **blended average unit volume** (it averages over both
comparable and non-comparable stores). Using the *blended* average — rather than
trying to isolate a "new-store-only" AUV — is intentional: it is the figure the
framework specifies, and any resulting imprecision in the comparable / non-
comparable split is absorbed by the **Other Revenue** plug (§5), which keeps the
build footed to reported total revenue.

**YoY growth row.** Beneath the TRTL row, add an italic `YoY %` memo row =
`<TRTL this col> ÷ <TRTL prior col> − 1` (blank/dash in the base column, which has
no prior period). It shows how blended revenue per location is trending and is a
quick sanity check (it should track roughly with SSS plus mix-of-new-stores
effects).

### 3.3 — Per-brand non-comparable block layout

```
Non-Comparable Cohort Revenue                                                                    [section sub-header: bold + underlined, size 12, indent 0]
<Brand>                                                                                          [concept header: bold + underlined, indent 0]
    Revenue per Location — system avg                             (USD millions per location)    [FORMULA = brand company sales ÷ brand company-owned EOP]
      YoY %                                                       (%)                            [FORMULA = this col ÷ prior col − 1; italic]
    Revenue from the Non-Comparable Cohort                        (USD in <scale>)               [FORMULA = above × 0.5 × non-comp count §1; bold, SUM-BAR]
<Brand 2> …                                                                                      [repeat]
Total Revenue from the Non-Comparable Cohort                      (USD in <scale>)               [FORMULA = Σ each brand's row; bold, SUM-BAR]
```

**No note rows here either.** The section sub-header runs straight into the first
brand header. The universe, the comp series and the half-year convention are
lines in the Notes block (§5.5); the 0.5 constant also sits in the row's cell
comment (§3.4).

Spacing / indentation mirror §1.5 and Section 2: brand header bold + underlined at
`Alignment(indent=0)`; the two line items at `Alignment(indent=2)`; the `YoY %` memo
at `Alignment(indent=3)` and italic, immediately under the TRTL row (no blank row above it); zero
blank rows within a brand block; one blank spacer between brand blocks; one blank
row before the consolidated total.

**Multi-brand parents:** as in §2.3, the per-brand two-row block is unchanged, but
for a 2+ concept parent these non-comparable rows sit inside each brand's grouped
build and the `Total Revenue from the Non-Comparable Cohort` total moves into the
consolidated revenue table — see **§6**.

### 3.4 — The formulas (cell-by-cell) for the non-comparable block

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue per Location — system avg` | | `(USD millions per location)` | `= <brand company restaurant sales, this col> ÷ <brand company-owned EOP count, location build, this col>` | `"TRTL = company restaurant sales ÷ company-owned locations (same universe as the cohort block). Blended avg revenue per store."` |
| `YoY %` | | `(%)` | base col: blank/dash; else `= <this col> ÷ <prior col> − 1` | `"YoY change in blended revenue per location."` |
| `Revenue from the Non-Comparable Cohort` | | `(USD in <scale>)` | `= <Revenue per Location — system avg, this col> × 0.5 × <§1 Total Non-Comparable Cohort, this col>` | `"= TRTL × 0.5 × non-comparable count (cohort block above). 0.5 = avg part-year for stores opened across the year."` |
| `Total Revenue from the Non-Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each brand's `Revenue from the Non-Comparable Cohort` `)` | `"Σ non-comparable-cohort revenue across all brands."` |

The numerator of TRTL is the **same company restaurant-sales figure** Section 2
relies on. Where that figure is a deepKPI input (it is for in-window years if you
choose to pull reported sales as a check, or for the base-year seed), reference
the input cell; otherwise TRTL's numerator may reference reported brand sales
pulled for this section. Either way the numerator carries deepKPI provenance and
the **TRTL cell itself is a formula** (a ratio of two cells), never a hardcoded
number. The `0.5` is a literal constant inside the formula (it is a framework
assumption, not a deepKPI value); state it in the cell comment. The convention
itself is one line in the Notes block (§5.5): `Revenue: new restaurants are
assumed open half the year on average; the 0.5 factor is uniform across
companies.`

### 3.5 — Brand-level vs. consolidated (same rule as §2.6)

If brand-level company restaurant sales are not disclosed, build the non-
comparable block at the **consolidated company-owned level**: TRTL = consolidated
company restaurant sales ÷ consolidated company-owned EOP locations, and the
multiplier = the **sum** of the brands' `Total Non-Comparable Cohort` counts.
Keep the universe consistent with Section 2's consolidation choice.

### 3.6 — Pre-delivery checklist (Non-Comparable Cohort revenue)

- [ ] One non-comparable block **per brand** (or consolidated per §3.5), same
      brand order and same universe as Sections 1 – 2.
- [ ] `Revenue per Location — system avg` (TRTL) = brand **company restaurant
      sales ÷ brand company-owned EOP locations** — numerator and denominator on
      the **same universe**, and the numerator **excludes franchise revenue**.
- [ ] A `YoY %` memo row sits directly beneath TRTL (formula; dash in the base
      column).
- [ ] `Revenue from the Non-Comparable Cohort = TRTL × 0.5 × non-comparable
      count (§1)` — the **0.5 factor is present**, the count is the **current**
      period's `Total Non-Comparable Cohort`, and the cell is a **live formula**.
- [ ] `Total Revenue from the Non-Comparable Cohort` = `SUM` of the per-brand
      rows (formula; SUM-BAR).
- [ ] Row-spacing / label / comment rules match §1.5; number formats follow each row's
      Col D tag.
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Revenue from Franchises (conditional)

**Include this section only if the shared KPI inventory carries a
franchise-revenue series** (the block's §1.1 gate). If none exists, the company
reports no franchise revenue and this section is **omitted entirely** (no empty
rows). Record the include / omit decision in `BUILD_LOG.md`, citing the series
found (or its absence); an omitted section needs no workbook note. The location
build's Franchised roll decides the block's mode, not whether the block exists.

Franchise revenue is **not** restaurant sales — it is the royalties, franchise and
license fees, and (sometimes) advertising-fund contributions the company collects
from franchisee-operated units. It is reported as its own line and is **not** split
into the comparable / non-comparable cohort math, which applies only to
company-operated stores.

Lay the franchise lines through the **shared franchise revenue block**,
`../franchiseRevenueBuild/franchiseRevenueBuild.md` (a sibling import, read at this
point): its §1 selects **Mode A** (sales-linked streams = prior year × (1 +
franchised unit growth from the location build) × (1 + franchise same-restaurant
sales growth); non-sales streams on their own drivers) or the fallback **Mode B**
(reported franchise revenue grown by `Franchise Revenue YoY %`); its §2 / §3 give
the layout, formulas and checklist; its §5 the projection seeds. Its placement rule
(§1.5) decides per brand vs. consolidated, matching §6.3 below. The labels
**`Revenue from Franchises`** and **`Franchise Revenue YoY %`** are fixed — §5 and
§6 below reference the former.

### 4.1 — Pre-delivery checklist (Franchise revenue)

- [ ] Section is **present iff** the inventory carries a franchise-revenue series
      (block §1.1); otherwise omitted, with the decision recorded in `BUILD_LOG.md`.
- [ ] The block's §1 outcomes (mode, comp series and universe, stream
      classification, placement) are stated, and its checklist for the chosen mode
      passes.
- [ ] The series are the **franchise revenue** lines, not company restaurant sales
      and not total revenue; labels exactly `Revenue from Franchises` /
      `Franchise Revenue YoY %`.

---

## Section 5 — Other Revenue (the plug) and Total Revenue (the foot)

This final section closes the build to the company's **reported total revenue**.
`Other Revenue` is the **plug**; `Total Revenue` is the **reported anchor** that
the plug closes to. Together they make the four modeled components sum to reported
total revenue **exactly**.

### 5.1 — Other Revenue is the plug — and what it absorbs

`Other Revenue` is defined as:

> **Other Revenue = Total Revenue (reported) − Revenue from the Comparable Cohort
> − Revenue from the Non-Comparable Cohort − Revenue from Franchises**

(omit the franchise term if Section 4 was not built). It is a **live formula**,
never an input.

Be honest in the cell comment about what this plug captures. It is **not** purely
the issuer's reported "other revenue" line. It absorbs **two** things at once:

1. Any **genuine other revenue** the company reports that is outside restaurant
   sales and franchise royalties (e.g. gift-card breakage, supply-chain / branded
   product sales, licensing, miscellaneous income); **and**
2. The **modeling residual** — the difference between **reported** company
   restaurant sales and the **modeled** company restaurant sales
   (`Comparable + Non-Comparable`), which are approximations (the comparable
   bridge compounds a seed by SSS; the non-comparable line uses a blended TRTL and
   a flat 0.5 factor). Because Other is a plug, this residual never breaks the
   foot — but the analyst should be able to see its size (see the memo below).

**Optional residual memo (recommended).** To keep the approximation visible, add
an italic memo row `Memo: modeled company sales vs. reported` =
`(Total Revenue from the Comparable Cohort + Total Revenue from the Non-Comparable
Cohort) − <reported company restaurant sales>`. A small residual relative to
total revenue means the cohort build is tracking the reported company sales well;
a large one flags a problem in the SSS series, the seed, or the universe choice.
This memo is for diagnostics only and does not enter the foot.

### 5.2 — Total Revenue is the reported anchor and the grand-total foot

`Total Revenue` is the company's **reported total revenue** (a deepKPI input) and
serves as the **grand total** of the revenue build. Because `Other Revenue` is
the plug, the identity

> **Comparable + Non-Comparable + Franchise + Other = Total Revenue**

holds **by construction** for every period — that is exactly the "Total Revenue …
should sum up all of the different revenue components" property. Verify it with a
zero-check rather than assuming it: a `Memo: components − Total (must = 0)` row.

### 5.3 — Layout and formulas

```
Other Revenue                                                     (USD in <scale>)               [FORMULA plug = Total − Comp − Non-Comp − Franchise]
  Memo: modeled company sales vs. reported                        (USD in <scale>)               [FORMULA memo, italic; diagnostics only — optional]

Total Revenue                                                     (USD in <scale>)               [deepKPI INPUT — reported total revenue; bold, SUM-BAR]
  Memo: components − Total (must = 0)                             (USD in <scale>)               [FORMULA check, italic; should be 0 every period]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Other Revenue` | | `(USD in <scale>)` | `= <Total Revenue, this col> − <Total Revenue from the Comparable Cohort> − <Total Revenue from the Non-Comparable Cohort> − <Revenue from Franchises>` (drop the franchise term if no Section 4); projection: `= <Other Revenue — % of modeled revenue, this col> × (<Total Rev Comparable Cohort> + <Total Rev Non-Comparable Cohort> + <Revenue from Franchises>)` | `"Plug = reported total − comparable − non-comparable − franchise. Absorbs genuine other revenue AND the cohort-model residual. Projection: a share of modeled revenue, off the ratio row beneath."` |
| `Other Revenue — % of modeled revenue` *(driver row under the plug; visible)* | | `(% of modeled revenue)` | historical: `= <Other Revenue, this col> ÷ (<Total Rev Comparable Cohort> + <Total Rev Non-Comparable Cohort> + <Revenue from Franchises>)`; projection: **DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The plug's share of the revenue the build models (comparable + non-comparable + franchise). Historical: a fit diagnostic — low single digits expected. Projection: driver, guided or else the latest year, then flat."` |
| `Memo: modeled company sales vs. reported` *(optional)* | DATA_DEPENDENT | `(USD in <scale>)` | `= (<Total Rev Comparable Cohort> + <Total Rev Non-Comparable Cohort>) − <reported company restaurant sales>` | `"Diagnostic: modeled company sales (comp + non-comp) less reported company restaurant sales. Not part of the foot."` |
| `Total Revenue` | | `(USD in <scale>)` | deepKPI **input** — reported total revenue (green, hyperlinked) | *(no comment — input row; this is the anchor the Other plug closes to)* |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= (<Total Rev Comparable Cohort> + <Total Rev Non-Comparable Cohort> + <Revenue from Franchises> + <Other Revenue>) − <Total Revenue>` | `"Foot check: must equal 0 every period (Other is the plug)."` |

`Total Revenue` is a total, styled like every other total in the workbook (bold, SUM-BAR
— a single thin top border across the data columns; no underline). The `Other Revenue`
line sits **above** it (so the four components read top-to-bottom into the total); the
foot-check memo sits immediately beneath `Total Revenue`.

### 5.4 — Pre-delivery checklist (Other + Total Revenue)

- [ ] `Other Revenue` is a **live formula plug** = `reported Total − Comparable −
      Non-Comparable − Franchise` (franchise term present iff Section 4 was
      built); never an input.
- [ ] Its cell comment **honestly states** that the plug absorbs both genuine
      other revenue and the cohort-model residual.
- [ ] `Total Revenue` is the **reported** deepKPI input (the anchor), bold with the SUM-BAR.
- [ ] The `components − Total` foot-check memo evaluates to **0** in every period
      after recalculation (proves the build foots). The optional `modeled vs.
      reported` residual memo, if included, is a reasonable (small) fraction of
      total revenue.
- [ ] After recalculation, **zero formula errors**, and the master identity
      `Comparable + Non-Comparable + Franchise + Other = Total Revenue` holds
      exactly for every period.

### 5.5 — The Notes block (every note, once, at the bottom of the build)

**All footnote-style notes in this build live here — nowhere else.** No
italic-gray note rows are interleaved between the build's rows: every section
sub-header is followed immediately by its first line item or brand header, and
every basis statement the sections above tell you to record is collected into a
**single Notes block** at the **very bottom of the entire revenue build**.

**Placement.** Two blank spacer rows below the last row of the build — for a
single-brand operator that is `Memo: components − Total (must = 0)` under `Total
Revenue` (§5.3); for a multi-brand parent it is the last row of the `Consolidated
Revenue` table (§6.3). The block is the last thing on the revenue build; nothing
is written beneath it.

**Layout** (all label text in Col C; the notes span the label column only — they
carry no period values). Each line is one modeling fact, prefixed `Revenue:`, in
the analyst's words, for a reader who has not read this skill — no section
numbers, no route, mode or case names, no driver colors:

```
                                                                ← two blank spacer rows
Notes                                                           (section sub-header: bold + underlined, size 12; base indent)
  Revenue: comparable definition: "<quoted or closely paraphrased 10-K definition>" (per <issuer> FY<n> 10-K).   (italic, size 11, gray)
  Revenue: comparable base = restaurants open at least <T> months <anchor wording>, per the FY<n> 10-K; new-restaurant window <R> months.   (italic, size 11, gray)
  Revenue: cohorts and comps are company-owned restaurants; comp series: <caption>.   (italic, size 11, gray)
  Revenue: the comparable bridge is built for all brands together; brand-level restaurant sales and comps are not disclosed.   (italic, size 11, gray; only a multi-brand parent built on one consolidated bridge)
  Revenue: new restaurants are assumed open half the year on average; the 0.5 factor is uniform across companies.   (italic, size 11, gray)
  Revenue: <row> FY<n> is taken from the 10-K; the database series was <scaled / mis-tagged / missing>.   (italic, size 11, gray; one line per override cell)
```

**Content rule — what must appear.** Every item the sections above say to record
as a Notes line is a line here: the **comparable definition** with its filing
year; **T**, the anchor and **R**; the **universe** and the **comp series**; the
consolidated-bridge line where §2.6 applies; the **half-year convention**; and
every cell taken from the 10-K rather than the database (§1.7), one line each.
Where a note carries a projection-period counterpart, record it on the same line
rather than opening a second block. Nothing here repeats a fact a cell comment
already carries, and nothing here is build history — the route taken, a series
set aside, a check and its result go to `BUILD_LOG.md`.

**Style.** `Notes` is a section sub-header — bold + underlined, size 12 — at **base
indent** (`indent=0`); every note line is **italic, size 11, gray** at
**`indent=1`**, with **zero blank rows** between them so the block reads as one
list. Each line is **plain text in Col C only** — no values in the period columns,
no formulas, no fills, no hyperlinks (provenance stays on the input cells it
belongs to). Order the lines as the sections above produce them. Indent is the
real cell indent (`Alignment(indent=1)`) — **never** leading spaces.

**Checklist (Notes block):**

- [ ] The block sits at the **very bottom** of the build, two blank rows beneath the
      last row of §5.3 (or of the §6.3 consolidated table), under a bold underlined
      `Notes` sub-header.
- [ ] **Nothing gray appears anywhere else in the build.** Sweep Col C for italic
      gray rows: the only ones outside this block are §1.5's three zone labels
      (`⤷ Cohort assumptions`, `⤷ Cohort lookback inputs`, `⤷ Base-year seed`).
- [ ] Every Notes line the sections above call for is here, and every line reads
      `Revenue: <fact>` with no section number, route, mode or case name.
- [ ] Notes are **text only** — no period values, formulas, fills or hyperlinks —
      and no note repeats a fact already carried by a cell comment.

---

## Section 6 — Multi-brand parents: per-brand full build + consolidated revenue table

Many restaurant parents operate **more than one concept** — e.g. **Brinker
International** (Chili's Grill & Bar + Maggiano's Little Italy), **Texas
Roadhouse, Inc.** (Texas Roadhouse + Bubba's 33 + Jaggers), Darden, Bloomin'
Brands. For these, **do not** blend the brands into a single bridge. Instead:

1. **Run the entire revenue build once per brand** — each concept gets its **own
   complete build** (the §2 comparable-cohort bridge, the §3 non-comparable-cohort
   lines, and — if that brand franchises — its §4 franchise line), producing a
   per-brand modeled revenue subtotal; then
2. **Build one consolidated revenue table** that **combines the brands** — summing
   each component across brands, adding the company-level **Other Revenue** plug,
   and tying to the **reported consolidated Total Revenue**.

A **single-brand operator** (e.g. Chipotle) skips this section: it has one brand,
so the "consolidated" table simply restates that brand's build. This section is
the **canonical workbook organization for multi-brand parents** — the §2 – §5
formulas are unchanged; they are just **arranged brand-by-brand**, with the
component totals and the company-level plug/foot collected into the consolidated
table at the bottom.

### 6.1 — Why per brand, never blended

Each concept can have a **different comparable-store-sales rate**, a **different
comparable definition / effective reach** (§1.1 — some parents use a different
`T` per brand), a **different franchise mix**, and **very different unit
economics** (AUV, check). Averaging them into one bridge would apply one brand's
SSS and per-store revenue to another's store count — silently wrong. Building each
brand on its own §1 cohort counts and its own SSS keeps every per-store figure
honest; the brands only meet at the **dollar level** in the consolidated table,
where summing is always valid.

### 6.2 — Per-brand block: the full build for one concept

For **each brand**, lay a self-contained revenue block directly beneath that
brand's §1 cohort block, containing that brand's complete build in order:

```
<Brand>                                                                                          [brand header: bold + underlined, indent 0 — full revenue build for this concept]
  Comparable Cohort Revenue                                                                      [sub-header: bold + underlined, indent 1 — §2 five-row bridge, this brand]
    Previous Year's Comparable-Cohort Revenue                     (USD in <scale>)
    Revenue per Comparable Restaurant — prior yr (PRCC)           (USD millions per restaurant)
    Comparable-Store Sales Growth (SSS)                           (%)                            [+ Price/Mix/Transactions memo rows if disclosed]
    Estimated Revenue per Comparable Restaurant                   (USD millions per restaurant)
    Revenue from the Comparable Cohort                            (USD in <scale>)               [= est × this brand's comparable count §1]
  Non-Comparable Cohort Revenue                                                                  [sub-header: bold + underlined, indent 1 — §3 two rows, this brand]
    Revenue per Location — system avg                             (USD millions per location)
      YoY %                                                       (%)
    Revenue from the Non-Comparable Cohort                        (USD in <scale>)               [= TRTL × 0.5 × this brand's non-comp count §1]
  [shared franchise block — §4]                                                                  [the block's rows, laid HERE only if franchise revenue is reported per brand (block §1.5); ends in the two fixed rows below]
    Revenue from Franchises                                       (USD in <scale>)               [laid by the block: explicit sum of its stream rows (or the reported line when the issuer reports a single line)]
    Franchise Revenue YoY %                                       (%)                            [laid by the block; its fixed label — never `YoY %`]
  Total Revenue — <Brand> (modeled)                               (USD in <scale>)               [FORMULA = comp + non-comp + franchise(this brand); bold subtotal, SUM-BAR]
<Brand 2> …                                                                                      [repeat the whole block]
```

Notes on the per-brand block:

- The five comparable rows and two non-comparable rows use the **exact formulas of
  §2.4 and §3.4** — only this brand's §1 cohort counts, this brand's SSS, and this
  brand's company sales feed them.
- **`Total Revenue — <Brand> (modeled)`** is a **modeled** subtotal (comparable +
  non-comparable + that brand's franchise revenue). It is **not** generally a
  reported figure — issuers rarely publish a full brand-level total revenue — so do
  **not** try to tie it to a reported brand total; the reconciliation to reported
  revenue happens **only** at the consolidated level (§6.3), via the Other plug.
- **The segment map.** Record in `BUILD_LOG.md` (the stage's hand-back report
  carries the same) each brand's name as the inventory's segment series spell it and
  the key of its `Total Revenue — <Brand> (modeled)` row — the segment map of
  `../../../SKILL.md`, "The segment map", which the cost build and the consolidated
  section read for that brand's revenue.
- **Franchise revenue placement.** The franchise rows are the shared block's (§4);
  this build never lays a franchise input of its own. If the issuer reports
  franchise revenue **per brand**, the block is laid once inside each brand's
  stack (block §1.5) and the brand subtotal includes that brand's `Revenue from
  Franchises`. If franchise revenue is reported **only at the consolidated level**
  (common — e.g. a single "franchise and other revenues" line, or consolidated
  sub-lines), **omit** franchise from the per-brand blocks (each brand subtotal is
  then comparable + non-comparable only) and lay the block **once**, in the
  consolidated table's franchise position (§6.3).
- One blank spacer row separates each brand's full block from the next, exactly as
  §1.5 separates concept blocks.

### 6.3 — The consolidated revenue table

After the per-brand blocks, lay one **consolidated revenue table** that combines
the brands and foots to reported total revenue:

```
Consolidated Revenue                                                                             [section sub-header: bold + underlined, size 12, indent 0]
    Total Revenue from the Comparable Cohort                      (USD in <scale>)               [FORMULA = Σ each brand's 'Revenue from the Comparable Cohort']
    Total Revenue from the Non-Comparable Cohort                  (USD in <scale>)               [FORMULA = Σ each brand's 'Revenue from the Non-Comparable Cohort']
    Revenue from Franchises                                       (USD in <scale>)               [per-brand case: FORMULA = Σ brands' 'Revenue from Franchises'; consolidated case: the shared block is laid HERE (§4, block §1.5) and this is its row; only if franchise revenue is reported]
    Franchise Revenue YoY %                                       (%)                            [per-brand case: FORMULA = this col ÷ prior col − 1, laid by this table; consolidated case: the block's row]
    Other Revenue                                                 (USD in <scale>)               [FORMULA plug = Total Revenue − the three lines above; projection: = the ratio row beneath × the three lines above]
      Other Revenue — % of modeled revenue                        (% of modeled revenue)         [FORMULA historical = Other Revenue ÷ (comparable + non-comparable + franchise); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]
  Total Revenue                                                   (USD in <scale>)               [deepKPI INPUT — reported consolidated total revenue; bold, SUM-BAR]
    Memo: components − Total (must = 0)                           (USD in <scale>)               [FORMULA check; 0 every period]
    Memo: revenue mix by brand                                    (% of modeled company sales)   [FORMULA, optional — each brand's modeled Total Revenue ÷ consolidated]
```

**Formulas (consolidated table):**

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Total Revenue from the Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each brand's `Revenue from the Comparable Cohort` `)` | `"Σ comparable-cohort revenue across all brands."` |
| `Total Revenue from the Non-Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each brand's `Revenue from the Non-Comparable Cohort` `)` | `"Σ non-comparable-cohort revenue across all brands."` |
| `Revenue from Franchises` *(if franchise revenue is reported)* | DATA_DEPENDENT | `(USD in <scale>)` | **per brand:** `= SUM(` each brand's `Revenue from Franchises` `)`, laid by this table, with a `Franchise Revenue YoY %` formula beneath it; **consolidated:** the shared block (§4) is laid in this position and `Revenue from Franchises` is **its** row — an explicit sum of its stream rows, or the reported line when the issuer reports a single line — never re-entered here | per brand: `"Σ brand franchise revenue (each brand's Revenue from Franchises row)."`; consolidated: the block's own comment |
| `Other Revenue` | | `(USD in <scale>)` | `= <Total Revenue> − <Total Rev Comparable Cohort> − <Total Rev Non-Comparable Cohort> − <Revenue from Franchises>` (drop franchise term if none); projection: `= <Other Revenue — % of modeled revenue, this col> × (<Total Rev Comparable Cohort> + <Total Rev Non-Comparable Cohort> + <Revenue from Franchises>)` | `"Plug = reported total − comparable − non-comparable − franchise. Absorbs genuine other revenue AND the cohort-model residual. Projection: a share of modeled revenue, off the ratio row beneath."` |
| `Other Revenue — % of modeled revenue` *(driver row under the plug; visible)* | | `(% of modeled revenue)` | historical: `= <Other Revenue, this col> ÷ (<Total Rev Comparable Cohort> + <Total Rev Non-Comparable Cohort> + <Revenue from Franchises>)`; projection: **DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The plug's share of the revenue the build models (comparable + non-comparable + franchise). Historical: a fit diagnostic — low single digits expected. Projection: driver, guided or else the latest year, then flat."` |
| `Total Revenue` | | `(USD in <scale>)` | deepKPI **input** — reported **consolidated** total revenue (green, hyperlinked) | *(no comment — the anchor the Other plug closes to)* |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= (<Total Rev Comp> + <Total Rev Non-Comp> + <Revenue from Franchises> + <Other Revenue>) − <Total Revenue>` | `"Foot check: must equal 0 every period."` |
| `Memo: revenue mix by brand` *(optional)* | DATA_DEPENDENT | `(% of modeled company sales)` | per brand: `= <Total Revenue — <Brand> (modeled)> ÷ (<Total Rev Comp> + <Total Rev Non-Comp> [+ <Franchise>])` | `"Each brand's modeled revenue as a share of modeled company sales."` |

This **is** the Section 5 logic, lifted to the consolidated level: `Other Revenue`
is still the plug and `Total Revenue` is still the reported anchor, so the master
identity **Comparable + Non-Comparable + Franchise + Other = Total Revenue** holds
for the **parent**. The per-brand `Total Revenue from the Comparable Cohort` and
`… Non-Comparable Cohort` totals that §2.3 / §3.3 describe **live here**, in the
consolidated table, for a multi-brand parent (rather than at the foot of each
component section). For a single-brand operator the consolidated table's component
sums reduce to that one brand's lines.

### 6.4 — Pre-delivery checklist (multi-brand parents)

- [ ] **One full revenue build per brand** — each concept has its own §2
      comparable bridge, §3 non-comparable lines, and (if it franchises and
      franchise revenue is reported per brand) §4 franchise line, plus a bold
      `Total Revenue — <Brand> (modeled)` subtotal.
- [ ] No blended cross-brand bridge: each brand uses **its own** §1 cohort counts,
      **its own** SSS, and **its own** company sales / locations.
- [ ] A single **`Consolidated Revenue`** table sums each component across brands,
      carries the company-level **Other Revenue** plug, and anchors to the
      **reported consolidated** `Total Revenue`.
- [ ] **Franchise revenue** appears **once** — either per brand (then summed in the
      consolidated table) or only in the consolidated table (if reported
      consolidated) — never double-counted.
- [ ] The consolidated `components − Total` foot-check = **0** every period; the
      master identity holds for the parent.
- [ ] Per-brand `Total Revenue — <Brand> (modeled)` subtotals are **not** forced to
      tie to a reported brand total (reconciliation is consolidated only).
- [ ] Brand blocks are ordered and labeled the same as the §1 cohort blocks;
      spacing / labels / comments follow §1.5; no note rows sit inside the brand
      blocks or the consolidated table — the Notes block (§5.5) sits two blank
      rows beneath the consolidated table.
- [ ] After recalculation, **zero formula errors**.

---

## Section 7 — Worked example (illustrative): Texas Roadhouse revenue bridge

This walks the **Texas Roadhouse** brand through the full bridge to show how the
rows chain. **The cohort counts are the real ones from §1.11**; the **revenue and
SSS figures are illustrative** (rounded for transparency, not pulled reported
values) — the point is the mechanics, not the exact dollars. Universe =
company-owned; figures in **$ thousands**; per-restaurant figures in **$ thousands
per restaurant**. The build window is FY2022 (base) → FY2025.

**Section 1 inputs reused (real cohort counts):**

| | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|
| Total Comparable Cohort (§1) | 496 | 527 | 551 | 591 |
| Total Non-Comparable Cohort (§1) | 56 | 55 | 57 | 57 |
| Company-Operated EOP (location build) | 552 | 582 | 608 | 648 |

**Base-year seed (FY2022 column only):** prior-FY (FY2021) **comparable-cohort
dollar revenue** = **3,600.0** (USD in millions) and prior-FY (FY2021) **comparable**
store count = **524** (illustrative — the §1 base-year seed row, FY2021 EOP
minus the weighted FY2021 and FY2020 openings, or the reported FY2021 comparable
count if disclosed). **Per the STRICT rule in §2.1, these must be the
comparable cohort's own dollars and count — obtained via situation 1 (reported
comparable-cohort revenue) or situation 2 (`dollar change ÷ growth %`) — NOT the
prior-FY total/blended company sales ÷ total store count.** The round numbers
here are illustrative of the mechanics only; do not read them as endorsing a
blended-average seed.

**Section 2 — Comparable Cohort bridge** (illustrative SSS in the SSS row):

| Row | Lays when | Units (Col D) | FY2022 (base) | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Previous Year's Comparable-Cohort Revenue | | `(USD in millions)` | 3,600.0 *(seed)* | 3,680.2 *(=FY22 row 5)* | 4,262.2 | 4,835.1 |
| PRCC = prev rev ÷ prior comp count | | `(USD millions per restaurant)` | 6.8702 *(÷524 proxy)* | 7.4198 *(÷496)* | 8.0876 *(÷527)* | 8.7751 *(÷551)* |
| Comparable-Store Sales Growth (SSS) | | `(%)` | +8.0% | +9.0% | +8.5% | +8.0% |
| Estimated Revenue per Comparable Restaurant | | `(USD millions per restaurant)` | 7.4198 | 8.0876 | 8.7751 | 9.4771 |
| **Revenue from the Comparable Cohort** = est × comp count | | `(USD in millions)` | **3,680.2** *(×496)* | **4,262.2** *(×527)* | **4,835.1** *(×551)* | **5,601.0** *(×591)* |

Note how `PRCC(N)` reproduces `Estimated Revenue per Comparable Restaurant (N−1)`
exactly (e.g. FY2023 PRCC 7.4198 = FY2022 est. rev/comp 7.4198; FY2025 PRCC
8.7751 = FY2024 est. rev/comp 8.7751) — the recursion of §2.1. Only FY2022 used
inputs; FY2023–FY2025 are pure formulas.

**Section 3 — Non-Comparable Cohort** (illustrative FY2025; company sales
5,900.0, company-owned EOP 648; USD in millions):

- `Revenue per Location — system avg (TRTL)` = 5,900.0 ÷ 648 = **9.1049**.
- `Revenue from the Non-Comparable Cohort` = 9.1049 × **0.5** × 57 = **259.5**.

**Section 5 — foot (illustrative FY2025, USD in millions):** Comparable 5,601.0 +
Non-Comparable 259.5 = modeled company sales 5,860.5 vs. reported company
sales 5,900.0 → residual ≈ 39.5 (the `modeled vs. reported` memo). With
franchise revenue (say 24.0) and reported Total Revenue (say 5,930.0),
`Other Revenue = 5,930.0 − 5,601.0 − 259.5 − 24.0 = 45.5`, and the
foot-check `components − Total` = 0. The plug quietly absorbs the cohort-model
residual plus genuine other revenue, and the build foots exactly.

This example walks **one brand**. Texas Roadhouse, Inc. is a multi-brand parent,
so the full workbook repeats this entire block for **Bubba's 33** and **Jaggers**,
then combines all three in a single **`Consolidated Revenue`** table per §6 — where
the reported consolidated `Total Revenue` (and the consolidated `Other Revenue`
plug) live, not in any one brand's block.

## Projections (forecast years)

After the **historical** build above (Sections 1 – 7) is laid down, recalculated,
and footed (the §5 / §6 `components − Total (must = 0)` check passes), **extend the
entire revenue build into the projection window** before the downstream handoff
(§8). The projection window is the **five fiscal years after the last historical
year** (`N+1 … N+5`) per the **Model timeline** in `../../../SKILL.md` — do not
redefine it here. Add five more **annual** columns immediately to the right of the
historical block, continuing the same left → right, oldest → newest order; the build
stays **annual** in the projection window too. The overwhelming majority of the
build simply **drags across as formulas**; only a small set of **drivers** per brand
are entered as forward assumptions.

### Driver styling (applies to every projection driver below)

Mark **every** projection driver cell so it reads as a forward assumption — visually
distinct from both the formula cells and the historical deepKPI input cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **Dashed box border on all four sides** of the cell (e.g. openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom`).
- **No pale-green fill and no hyperlink** — projection drivers are assumptions, not
  deepKPI-sourced actuals.
- **Exception to the "formulas are black" rule.** A projection driver keeps the red
  font + dashed border **even though its default value is a live formula** (the
  seeding formula below). The red/dashed treatment marks it as the intended
  override point; every **non-driver** projection cell stays standard formula
  styling (black font, no fill, no dashed border) — identical to its historical
  styling, just dragged one column right.

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
  this seed, the consolidated `Other Revenue — % of modeled revenue` ratio driver included
  (see Part 3).

The three major parts of the build — **Comp Stores Roll-forward**, **Revenue Build**
(comparable + non-comparable cohorts), and **Consolidated Revenue Build** — project
as follows, and **repeat per brand / segment** exactly as the historical sections do.

### Part 1 — Comp Stores Roll-forward (§1 cohort partition): no new drivers

The comparable / non-comparable cohort partition (§1) introduces **no new projection
drivers** — its only forward-moving dependency is **unit openings** (and the EOP
balance), and **both already live in the location build**, where they were turned
into drivers by `../locationBuild/locationBuild.md` (its Projections section). Every
cohort cell is a formula, so **drag the entire §1 block across into the projection
columns unchanged**:

- The cohort assumptions (`T`, `R`, stub-year fraction) are **single
  absolutely-referenced cells** — they do not change by period and need nothing for
  projection.
- The **lookback-openings rows** and the **weighted year-of-opening rows** reference
  the location build's openings. In every projection column those references resolve
  to the location build's **projected Company Openings** cells (a `N+2` column's
  "one fiscal year ago" cell, for instance, points at the projected `N+1` openings);
  they remain **formulas**, never new inputs.
- `Opened in Current Yr` = the location `Company Openings` cell (projected driver);
  `Total Non-Comparable Cohort` = the `SUM` of the weighted rows; `Total Comparable
  Cohort` = location **EOP (projected)** − `Total Non-Comparable Cohort`; the
  `Comparable as % of total` memo = comp ÷ EOP.

**Logic double-checked — confirmed no §1 driver is needed.** Because openings is the
sole forward dependency and it is sourced upstream from the (already-projected)
location build, the cohort partition foots forward purely by dragging its formulas.
The one situation that would break this assumption — an issuer whose comparability
**anchor** itself requires a forward assumption that cannot be derived from openings
— does not arise under the trailing-window model (§1.2), since `R` is a fixed
single-cell assumption. If a future issuer ever needs a forward cohort assumption
beyond openings, flag it rather than inventing a hidden driver.

### Part 2 — Revenue Build

**Revenue from the Comparable Cohort (§2) — driver: `Comparable-Store Sales Growth
(SSS)` only.** Per brand, the **single** projection driver is the SSS row; apply the
driver styling and the default-seed methodology to it (`N+1` = the guided comp for
`N+1` at this brand's scope, else the latest reported quarter's comp after `N` as a
green hyperlinked input, else year `N`'s comp; `N+2` = `=AVERAGE(<SSS N−2>:<SSS N>)`
over the historical annual values, the long-run reversion that is the
comparable-sales builds' one average seed; `N+3 … N+5` = `= <SSS N+2>`). Every other
row in the five-row bridge is a **formula dragged across unchanged**:

- `Previous Year's Comparable-Cohort Revenue` = prior column's `Revenue from the
  Comparable Cohort` (row 5).
- `Revenue per Comparable Restaurant — prior yr (PRCC)` = `Previous Year's …` ÷ prior
  column's `Total Comparable Cohort` (§1).
- `Estimated Revenue per Comparable Restaurant` = `PRCC × (1 + SSS)`.
- `Revenue from the Comparable Cohort` = `Estimated Revenue per Comparable Restaurant
  × this column's Total Comparable Cohort` (§1, projected).
- `Total Revenue from the Comparable Cohort` = `SUM` of each brand's row 5.

If the optional SSS decomposition rows (Transactions / Average Check / Menu Price /
Product Mix) were carried historically, **leave them blank (dash) in the projection
columns** — they are disclosure-only memos and never drove the bridge.

**Revenue from the Non-Comparable Cohort (§3) — driver: `YoY %`.** Take each line
item as follows:

- **`Company Restaurant Sales`** (the reported company-restaurant-sales figure that
  serves as the `Revenue per Location` numerator) is a **historical-only** input.
  Keep its historical cells exactly as the existing methodology sets them, and
  **leave every projection-year cell blank (dash)** — it is not projected.
- **`Revenue per Location — system avg`** — **definition unchanged for historical**
  (= company restaurant sales ÷ company-owned EOP locations). For **projection**
  columns it switches to compounding off the prior year:
  `= <prior column Revenue per Location> × (1 + <YoY %, this column>)`. (Because
  `Company Restaurant Sales` is blank in projection, the historical ratio definition
  cannot be used; the line instead grows off its own prior value by the driver.)
- **`YoY %`** — the **driver** for this block. Historically it is **derived**
  (`= this col ÷ prior col − 1`); in projection it **inverts** to become the forward
  assumption (red/dashed; `N+1` = the default seed: the guided value, else the latest historical `YoY %` value; `N+2 … N+5` = `N+1`).
- **`Revenue from the Non-Comparable Cohort`** — **unchanged formula**:
  `= Revenue per Location × 0.5 × Total Non-Comparable Cohort (§1, projected)`.
- `Total Revenue from the Non-Comparable Cohort` = `SUM` of each brand's row.

(Note the inversion mirrors the location build: historically `Revenue per Location`
is the formula and `YoY %` is derived from it; in projection `YoY %` is the driver
and `Revenue per Location` compounds off it.)

### Part 3 — Consolidated Revenue Build (§4 franchise, §5 Other + Total, §6 table)

- **`Total Revenue from the Comparable Cohort`** and **`Total Revenue from the
  Non-Comparable Cohort`** — the **same `SUM` formulas** as the historical columns;
  drag them across.
- **Revenue from Franchises (§4 / consolidated).** Only if franchise revenue is reported (block §1.1):
  project the block exactly as `../franchiseRevenueBuild/franchiseRevenueBuild.md`
  §5 specifies for the mode its §1 selected — Mode A compounds the sales-linked
  streams off the projected franchised roll and the franchise comp driver
  (latest-quarter recency seed where available), non-sales streams off their own
  `— YoY %` drivers; Mode B makes `Franchise Revenue YoY %` the driver (the default seed, then flat) and `Revenue from Franchises`
  compounds off it. Apply this wherever the line lives: **per brand** if the issuer
  reports franchise revenue per brand, otherwise **once** in the consolidated table
  (§6.3).
- **`Other Revenue` — a share of modeled revenue.** Historically `Other Revenue` is
  the **plug** (`= Total − Comparable − Non-Comparable − Franchise`). There is no
  reported total in the projection columns, so it cannot stay a plug, and it is never
  seeded to zero dollars (that would step projected revenue down at `N+1`). Its row
  beneath, `Other Revenue — % of modeled revenue`, holds the historical ratio of the plug to
  `Comparable + Non-Comparable + Franchise` and, in projection, is the **driver**
  (red/dashed, the default seed then flat, like every other driver); `Other Revenue = that driver × (Comparable + Non-Comparable + Franchise)`.
  The denominator excludes the plug itself, so there is no circularity.
- **`Total Revenue` — the foot.** The identity **`Comparable + Non-Comparable +
  Franchise + Other = Total Revenue`** holds in **both** halves, so `Total Revenue`
  is always the foot/sum of its components and is **never a driver** (no red/dashed)
  in either half. The only thing that changes is *which* cell is the free input:
  historically `Total Revenue` is the **reported deepKPI input** and `Other` is the
  plug; in projection `Other` is driven off its ratio row, so `Total Revenue` is written
  **directly as the sum of the components**:
  `= Total Rev Comparable + Total Rev Non-Comparable + Revenue from Franchises + Other
  Revenue` (drop the franchise term if no franchise revenue is reported). The `components − Total (must
  = 0)` foot-check memo then evaluates to **0** in every projection year (trivially,
  since Total is defined as that sum).

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=`
  formula (no hardcoded numbers). The **only** seeded/typed cells are the drivers:
  per-brand SSS (§2), per-brand non-comparable `YoY %` (§3), franchise block drivers (§4 /
  §6), and the consolidated `Other Revenue — % of modeled revenue`. `Company Restaurant
  Sales` projection cells are **blank**.
- **Driver seeding.** Each driver's `N+1` = the default seed (the guided value where the guidance table names it, else the latest historical year) and `N+2 … N+5` = `N+1`, the `Other Revenue — % of modeled revenue`
  ratio driver included.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors**.
- **Foot.** The consolidated `components − Total (must = 0)` memo equals **0** in
  every projection year, and the cohort identity `Comparable + Non-Comparable = EOP`
  still holds (location EOP projected).
- **Continuity at the boundary.** `N+1` `Previous Year's Comparable-Cohort Revenue`
  equals `N` `Revenue from the Comparable Cohort`; `N+1` `Revenue per Location` and
  `N+1` `Revenue from Franchises` compound off their `N` values — the projection joins the
  actuals with no gap or jump.

## Section 8 — What the revenue build produces for downstream sections

After Sections 2 – 5 are built, the workbook contains, for every period in the
window, a fully-footed revenue build beneath the §1 cohort blocks:
`Total Revenue from the Comparable Cohort`, `Total Revenue from the
Non-Comparable Cohort`, `Revenue from Franchises` (if applicable), `Other Revenue`
(plug), and `Total Revenue` (reported) — every component a live formula flowing
from the §1 cohort counts, the location build's EOP / openings, and the SSS /
revenue inputs. Downstream operating-model sections (costs, consolidated
financials) reference `Total Revenue` and the component lines directly; any later
change to the location roll-forward, the cohort partition, or an SSS input
propagates automatically through the entire revenue build and keeps the foot
intact.

## Dependencies — rows this build references but does not lay

Per `../../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Company-Operated EOP Balance` for the brand (`coeop_<brand>`; the `EOP Balance` from the Location section; the brand company-owned EOP count) | location build (`../locationBuild/`) | the restaurant router ran the location build | none — return `ABORTED` (the "Aborting the build" section) |
| `Company Openings` for the brand (the `Opened in Current Yr` reference) | location build | the location build ran and the issuer discloses openings (deepKPI flow series or the 10-K development table) | §1.5 flow-tier paths; else `ABORTED` |
