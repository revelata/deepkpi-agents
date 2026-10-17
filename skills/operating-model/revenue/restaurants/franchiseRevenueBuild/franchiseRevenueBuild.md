---
name: revenue-restaurants-franchise-revenue-build
description: >
  Shared franchise-revenue block for restaurant companies in the operating-model
  workbook. Invoked INLINE by whichever restaurant revenue sub-build the router
  dispatched to — `revenuePerRestaurantBuild/` (its §2), `comparableSalesGrowthBuild/`
  (its §3) or `comparableStoresBuild/` (its §4) — at the point where that build lays
  its `Revenue from Franchises` lines. It is not a route and the router never
  dispatches to it directly. Receives the resolved `company_id`, official company
  name, workbook path (with the location roll-forward and the company-restaurant
  revenue lines already laid down), and the shared KPI inventory. Decides between
  two modes from the inventory: Mode A (unit-and-comp) projects the sales-linked
  franchise streams (royalties, advertising-fund contributions) as prior year ×
  (1 + franchised unit growth) × (1 + franchise same-restaurant sales growth), with
  unit growth referenced from the location build's Franchised EOP Balance and the
  non-sales streams (fees, rental income) on their own YoY drivers; Mode B
  (standalone) is the fallback — reported franchise revenue grown by its own YoY
  rate — used when the location build laid no Franchised roll or the inventory has
  no franchise comp series. The block is laid whenever the inventory carries a
  franchise-revenue series and omitted only when none exists.
  Historical values are deepKPI inputs; every total, ratio and driver is a live `=`
  formula. Pulls series via `search_kpis` against the shared inventory; format per
  ../../../../_common/revelata-excel-styling-rules.md.
---

# revenue — restaurants — franchise revenue build (shared block)

This is the **franchise revenue block** every restaurant revenue sub-build lays at
the same point in its layout. It is a **shared component, not a route**: the
restaurant router (`../restaurants.md`) dispatches to exactly one of
`../revenuePerRestaurantBuild/`, `../comparableSalesGrowthBuild/` or
`../comparableStoresBuild/`, and that build reads this file when it reaches its
franchise section. Reading it there is a sibling import, which the orchestrator's
GOLDEN RULE 1 permits; do not read it before the router has dispatched.

**Why a shared block.** For a franchisor, royalties and advertising-fund
contributions are percentages of **franchise restaurant sales**, and franchise
restaurant sales are **franchised units × sales per unit**. A franchise revenue
line that grows at its own standalone rate ignores both the franchised unit
roll-forward that `../locationBuild/locationBuild.md` already laid down and the
franchise comp the issuer reports, so comp and unit growth would move the
company-restaurant lines but not the franchise lines — for a heavily franchised
system that is most of revenue. This block wires the connection whenever the
inventory can support it (Mode A) and keeps the standalone rate as the documented
fallback (Mode B).

**Inputs expected from the invoking build:** resolved `company_id`, official
company name, the workbook path (with the location roll-forward and the invoking
build's company-restaurant revenue lines already laid down), the **shared KPI
inventory**, and the position in the invoking build's layout where the block goes.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`. Do **not** re-run
`list_kpis`; pull the specific franchise-revenue and franchise-comp series with
`search_kpis` against the shared inventory.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
`../../../../_common/revelata-excel-units-and-scale.md` and build with the **xlsx**
skill. One row per distinct series; deepKPI-sourced values as pale-green hyperlinked
input cells; **every** total, ratio and driver cell a live `=` formula — never a
hardcoded number.

**Number format and units.** Storage, the number-format strings and the tag grammar
come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
family follows from that file's Rule 4 — an input row's from its deepKPI `unit`
field, a derived row's from the dimensions of its formula. **The Col D tag for every
row this block writes is shown in the layout blocks of §2.2 and §3.1** and in the
`Units (Col D)` column of their spec tables. Dollar rows show the placeholder
`(USD in <scale>)`: the contract's Rule 2 supplies the scale, millions by default,
thousands where the digit test puts a small filer. Two classifications are specific
to this block:

- **Every percent row is a bare `(%)`.** `Franchise comparable sales (SSS), %`,
  `Franchised units — YoY %`, each `<stream> — YoY %` driver and
  `Franchise Revenue YoY %` are period-over-period changes, the case the contract's
  Rule 5 reserves the bare tag for. Each stores the decimal fraction (`-0.048`,
  not `-4.8`).
- **`Revenue from Franchises` carries the SUM-BAR.** It is bold with a single thin
  top border across the data columns only, per the styling rules — never a double
  line, never a bottom border on the row above.

**Reading the layout blocks (§2.2, §3.1).** Each row's annotation has two columns,
left to right: the **Col D units tag in parentheses** — `(USD in <scale>)` means
the contract's Rule 2 sets the money scale; every other tag is written as it goes
in the cell — and the note in **square brackets**: `[deepKPI INPUT …]` for a pulled
value, `[FORMULA …]` for a computed row, `driver` for a projection assumption, plus
styling (`SUM-BAR`, `italic`).

## Time scope and columns (match the invoking build)

Use the **exact period columns the invoking build already laid down** — the four
most recent fiscal years (`N−3 … N`) in Col E onward, then the five projection
years (`N+1 … N+5`) per the **Model timeline** in `../../../SKILL.md`. Do not add or
remove periods here. All rows are annual.

> This block is authored section by section. The sections present here — §1 the
> gate and mode decision, §2 Mode A (unit-and-comp), §3 Mode B (standalone), §4 the
> handback to the invoking build, §5 the projection layer, §6 a worked example, and
> §7 the upgrade path — are the implemented scope. Do **not** build outside them.

---

## Section 1 — Gate and mode decision (no workbook writing yet)

Run these checks in order and state the outcome of each in one line before laying
any row, so the decision is auditable.

### 1.1 — Does the company report franchise revenue?

Search the **shared KPI inventory** for a franchise-revenue series: `Franchise
revenue`, `Franchise royalties and fees`, `Franchise royalty revenue`, `Franchise
fees`, `Franchise rental income`, `Advertising funds revenue`, `Franchise and other
revenue` (the series §1.4 classifies). The block is laid **only if** at least one
such series is present. If none is, the company reports no franchise revenue:
**omit the block entirely** (no empty rows) and tell the invoking build to drop the
franchise term from its Other plug.

This gate is on **reported revenue, not on unit counts**. Whether the location
build laid a **Franchised roll** decides the block's *mode* (§1.3), never whether
the block exists: an issuer that reports franchise revenue but no franchised
unit-count series still gets the block, in Mode B.

### 1.2 — Is there a franchise comp series?

Search the shared inventory for a **franchise same-restaurant-sales growth**
series. Try, in order, the tokens `franchise same-restaurant`, `franchised
same-restaurant`, `franchise comparable`, `franchise comp`, and — only if none of
those exist — `systemwide same-restaurant` / `system same-restaurant` (a comp the
issuer reports for the whole system, company and franchised together). Prefer the
**annual** series; note the matching quarterly series for the §5 recency seed.

**Universe match.** The location build's `Franchised EOP Balance` is the **whole
franchised system** (domestic + international, every concept). Use the comp series
on the same universe — a *global* or *total* franchise comp. If only a narrower
comp exists (e.g. U.S. franchise comp only), use it, **state the mismatch** in
the row's Col C comment, and add one Notes line: `Revenue: franchise sales growth
uses the U.S. franchise comp; no global franchise comp is reported.` Do not blend
series.

### 1.3 — Pick the mode

Read the location build: is there a **Franchised roll** (its §2.1 layout; its §2.4
step 2) for the concept, or for the Total block, that §1.5 will have this block
reference? The location build projects every roll it lays (its §3), so a roll that
is present is also projected.

| Franchised roll in the location build | Franchise comp series (§1.2) | Mode |
|---|---|---|
| present | present | **Mode A — unit-and-comp (§2)** |
| present | absent | **Mode B — standalone (§3)** — no comp term |
| absent | any | **Mode B — standalone (§3)** — no units term |

Mode A is the default whenever both inputs exist. Mode B is a fallback, never a
preference; when it is used, say which input was missing in one line.

### 1.4 — Identify the franchise streams and classify them

Pull the franchise-revenue series with `search_kpis` (e.g. `Franchise royalties
and fees - Annual`, `Franchise revenue - Annual`, `Franchise royalty revenue -
annual`, `Franchise fees - annual`, `Franchise rental income - annual`,
`Advertising funds revenue - annual`). Two presentations:

- **Sub-lines reported** (the issuer breaks franchise revenue into streams on the
  face of the income statement or in the revenue footnote). Carry **one row per
  stream**, in the issuer's order and wording, and classify each:
  - **Sales-linked** — a percentage of franchise restaurant sales: **royalties**,
    **advertising-fund contributions** (where the issuer consolidates its
    advertising funds and reports the contributions as revenue), and any fee the
    issuer describes as a percentage of sales. These streams take the Mode A
    unit-and-comp formula.
  - **Non-sales** — set by contracts or assets rather than by sales: **initial /
    development / technology fees**, **franchise rental income** (rent on
    properties leased or subleased to franchisees), and other miscellaneous fees.
    Each takes its **own** YoY driver (§2.2).
  State the classification of every stream in its Col C comment. When a stream is
  described as partly sales-linked (a technology fee charged per restaurant that
  varies with sales, for example), classify it by its **dominant** basis and say so.
- **Single line reported** (`Franchise royalties and fees`, `Franchise and other
  revenue`). Carry the one line; in Mode A the whole line takes the unit-and-comp
  formula. If the line bundles non-franchise items ("franchise and other revenue"),
  use it as reported and note the bundling — the invoking build's Other plug still
  makes the build foot.

### 1.5 — Placement: per brand or consolidated

- If the issuer reports franchise revenue **per brand**, lay one block per brand,
  inside that brand's revenue stack, and reference **that brand's** `Franchised EOP
  Balance` from the location build. The invoking build sums the brand lines.
- Otherwise (the common case — a single consolidated franchise line or set of
  sub-lines), lay the block **once**, where the invoking build places its
  consolidated franchise section, and reference the location build's **Total —
  all concepts → `Franchised EOP Balance`**, which already sums the brands.

---

## Section 2 — Mode A: the unit-and-comp build

### 2.1 — The logic

```
  Franchise restaurant sales (t)  ≈  Franchise restaurant sales (t−1)
                                     × (1 + franchised unit growth (t))
                                     × (1 + franchise same-restaurant sales growth (t))

  Sales-linked stream (t)         =  stream (t−1) × (1 + unit growth (t)) × (1 + franchise SSS (t))
  Non-sales stream (t)            =  stream (t−1) × (1 + <stream> YoY % driver (t))
  Revenue from Franchises (t)     =  Σ streams (t)
```

Royalty revenue is a contractual percentage of franchise restaurant sales, so it
grows as franchise sales grow, and franchise sales grow with the number of
franchised restaurants and with same-restaurant sales. The identity treats every
franchised unit as a mature unit (a new unit contributes a full unit of growth in
its opening year); §7 records the cohort-based refinement that would remove that
simplification. In the **historical** columns every stream is the reported deepKPI
input and the comp and unit-growth rows are memos; in the **projection** columns
the identity assembles each stream.

### 2.2 — Layout and formulas (sub-lines presentation)

```
  Franchise comparable sales (SSS), %                   (%)                [deepKPI INPUT — franchise comp; projection: N+1 recency seed, then driver (§5)]
  Franchised units — YoY %                              (%)                [FORMULA = Franchised EOP Balance ÷ prior col − 1 (location build); italic; dash in the base year]
    <sales-linked stream, e.g. Franchise royalty revenue>  (USD in <scale>) [deepKPI INPUT; projection: FORMULA = prior col × (1 + units YoY) × (1 + SSS)]
    <non-sales stream, e.g. Franchise fees>             (USD in <scale>)   [deepKPI INPUT; projection: FORMULA = prior col × (1 + its YoY % driver)]
      <non-sales stream> — YoY %                        (%)                [FORMULA = this col ÷ prior col − 1 in history; projection driver; italic]
    <non-sales stream, e.g. Franchise rental income>    (USD in <scale>)   [deepKPI INPUT; projection: FORMULA = prior col × (1 + its YoY % driver)]
      <non-sales stream> — YoY %                        (%)                [FORMULA; projection driver; italic]
    <sales-linked stream, e.g. Advertising funds revenue>  (USD in <scale>) [deepKPI INPUT; projection: FORMULA = prior col × (1 + units YoY) × (1 + SSS)]
  Revenue from Franchises                               (USD in <scale>)   [FORMULA = explicit sum of the stream rows; bold, SUM-BAR]
  Franchise Revenue YoY %                               (%)                [FORMULA = this col ÷ prior col − 1; memo in every column; italic]
```

Keep the streams in the issuer's order; the driver row of each non-sales stream
sits directly beneath it. With a **single-line** presentation, drop the stream rows
and give `Revenue from Franchises` itself the sales-linked formula (it is then a
deepKPI input in history and `= prior col × (1 + units YoY) × (1 + SSS)` in
projection), keeping the two rows above it and the memo below.

| Row (plain Col C label) | Lays when | Units (Col D) | Cell, historical | Cell, projection | Comment on Col C |
|---|---|---|---|---|---|
| `Franchise comparable sales (SSS), %` | | `(%)` | deepKPI **input** (green, hyperlinked), stored as a fraction | `N+1` recency seed or driver, `N+2 …` driver — §5 | `"Franchise same-restaurant sales growth, <universe>. Drives the sales-linked streams with franchised unit growth."` |
| `Franchised units — YoY %` | | `(%)` | `= <Franchised EOP Balance, this col> ÷ <Franchised EOP Balance, prior col> − 1` (location build; dash in the base year) | same formula — resolves to the projected roll | `"Memo = Franchised EOP Balance ÷ prior year − 1 (location build). Carries the franchised unit roll into franchise revenue."` |
| `<sales-linked stream>` | | `(USD in <scale>)` | deepKPI **input** | `= <this row, prior col> × (1 + <Franchised units — YoY %, this col>) × (1 + <Franchise comparable sales (SSS), %, this col>)` | `"Sales-linked: a percentage of franchise restaurant sales. Projection = prior year × (1 + unit growth) × (1 + franchise comp)."` |
| `<non-sales stream>` | | `(USD in <scale>)` | deepKPI **input** | `= <this row, prior col> × (1 + <its YoY % driver, this col>)` | `"Non-sales: <basis>. Projection = prior year × (1 + its YoY % driver)."` |
| `<non-sales stream> — YoY %` | | `(%)` | `= <stream, this col> ÷ <stream, prior col> − 1` (dash in the base year) | driver — §5 | `"Historical formula; projection driver."` |
| `Revenue from Franchises` | | `(USD in <scale>)` | `= <stream A> + <stream B> + …` | same | `"Σ of the franchise streams. Explicit sum so the driver and memo rows between the streams are not picked up."` |
| `Franchise Revenue YoY %` | | `(%)` | `= <Revenue from Franchises, this col> ÷ <prior col> − 1` (dash in the base year) | same formula (memo, not a driver) | `"Memo: franchise revenue growth, YoY, as produced by the stream drivers."` |

- **Explicit sum, never a range.** Write `Revenue from Franchises` as
  `= <row> + <row> + …` over the stream rows. A `SUM(first:last)` over the block
  would add the `— YoY %` driver rows and the units memo that sit between the
  streams.
- **Both growth rows are references, never re-keyed.** The units row points at the
  location build; the comp row is the deepKPI input. Neither is typed in a stream's
  formula.
- The block **foots to reported franchise revenue by construction** in history
  (the streams are the reported sub-lines); the invoking build's `Memo: components
  − Total (must = 0)` proves the whole revenue build foots.

### 2.3 — Pre-delivery checklist (Mode A)

- [ ] §1 outcomes stated: franchised roll present, the comp series matched (and its
      universe), the mode, each stream's classification, and the placement.
- [ ] `Franchise comparable sales (SSS), %` is a deepKPI input in every historical
      column, stored as a fraction; `Franchised units — YoY %` references the
      location build's `Franchised EOP Balance` (brand or Total block per §1.5).
- [ ] Every stream row is the reported deepKPI input in history; sales-linked streams
      carry the unit-and-comp formula forward, non-sales streams their own driver.
- [ ] `Revenue from Franchises` is an explicit sum of the stream rows (bold, SUM-BAR);
      `Franchise Revenue YoY %` is a memo formula in every column.
- [ ] Labels are exactly `Revenue from Franchises` and `Franchise Revenue YoY %` — the
      invoking build's Other plug and consolidated table reference them (§4).
- [ ] After recalculation (LibreOffice / the xlsx skill's `recalc.py`), **zero
      formula errors**.

---

## Section 3 — Mode B: the standalone build (fallback)

Use only when §1.3 lands here. Reported franchise revenue is taken as the input and
grown by its own year-over-year rate.

### 3.1 — Layout and formulas

```
    <stream, e.g. Franchise royalty revenue>            (USD in <scale>)   [deepKPI INPUT; projection: FORMULA = prior col × (1 + Franchise Revenue YoY %); ONLY when the issuer reports sub-lines — one row per stream]
    <stream, e.g. Advertising funds revenue>            (USD in <scale>)   [deepKPI INPUT; projection: FORMULA = prior col × (1 + Franchise Revenue YoY %)]
  Revenue from Franchises                               (USD in <scale>)   [sub-lines reported: FORMULA = explicit sum of the stream rows in both halves; single line: deepKPI INPUT, projection = prior col × (1 + YoY %); bold, SUM-BAR]
    Franchise Revenue YoY %                             (%)                [FORMULA = this col ÷ prior col − 1 in history; projection driver; italic]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell, historical | Cell, projection | Comment on Col C |
|---|---|---|---|---|---|
| `<stream>` *(one per reported sub-line)* | | `(USD in <scale>)` | deepKPI **input** (the reported sub-line, issuer's wording) | `= <this row, prior col> × (1 + <Franchise Revenue YoY %, this col>)` — pro rata off the single driver | `"Reported franchise sub-line. Grows with total franchise revenue (one standalone growth rate for the block)."` |
| `Revenue from Franchises` | | `(USD in <scale>)` | sub-lines reported: `= <stream A> + <stream B> + …` (explicit sum); single line: deepKPI **input** | sub-lines reported: the same explicit sum; single line: `= <prior col> × (1 + <Franchise Revenue YoY %, this col>)` | `"Reported franchise revenue. No franchise comp series or franchised unit count is reported, so franchise revenue grows on one standalone rate."` |
| `Franchise Revenue YoY %` | | `(%)` | `= <this col> ÷ <prior col> − 1` (dash in the base year) | driver — §5 | `"Franchise revenue growth, YoY. Projection driver."` |

- Franchise revenue is **not** derived from the per-restaurant figure or the
  company-owned units; it scales with the franchised system.
- **Carry the sub-lines whenever the issuer reports them**, projected pro rata off
  the one driver, so every stream row has a value in every column. The total still
  compounds at the driver rate (each component does), so nothing about Mode B's
  economics changes — but a stream row that existed only in history would hand a
  **blank** projection cell to anything that references it. The restaurant cost
  build's advertising-fund pass-through references the `Advertising funds revenue`
  stream in every projection column (`../../../costs/restaurants/restaurantsCosts.md`
  §9.3); a blank there would read as zero expense against revenue that is still
  being projected inside the total. A single consolidated line is used only when
  the issuer reports one.

### 3.2 — Pre-delivery checklist (Mode B)

- [ ] §1 outcomes stated, including **why** Mode A was not available.
- [ ] `Revenue from Franchises` is the reported deepKPI input in history (bold,
      SUM-BAR) — or, when sub-lines are reported, the explicit sum of the carried
      stream rows in both halves; `Franchise Revenue YoY %` is a live formula
      beneath it and the projection driver.
- [ ] Every carried stream row is projected `= prior col × (1 + Franchise Revenue
      YoY %)`; no stream row has a blank projection cell.
- [ ] Labels exactly as above (§4); after recalculation, **zero formula errors**.

---

## Section 4 — Handback to the invoking build

Two labels are this block's public surface and must not vary by mode or issuer:
**`Revenue from Franchises`** (the total the invoking build's Other plug and
consolidated table subtract) and **`Franchise Revenue YoY %`**. The invoking
build's own sections are unchanged by this block:

- its Other plug stays `= Total Revenue − <company-restaurant revenue> − Revenue
  from Franchises` (drop the franchise term when §1.1 omitted the block);
- its `Memo: components − Total (must = 0)` must still evaluate to 0 in every
  historical column;
- the costs build may set a consolidated advertising-fund **expense** equal to the
  `Advertising funds revenue` stream laid here (see
  `../../../costs/restaurants/restaurantsCosts.md` §9.3); keep that stream's label as
  the issuer reports it so the cost build can find it.

Hand control back to the invoking build at the section that follows its franchise
section.

---

## Section 5 — Projections (forecast years)

The invoking build's **Projections** section defines driver styling (red font,
dashed box, no fill, no hyperlink) and the default seed (`N+1` = the guided value or else the latest historical year, later years = the `N+1` cell). This block adds
only the following:

- **`Franchise comparable sales (SSS), %` — recency seed.** When deepKPI has a
  **quarterly** franchise comp for a fiscal quarter more recent than annual `N`,
  seed `N+1` to that latest reported quarter as a **pale-green hyperlinked input**
  (it is an actual, not an assumption) — the same rule the comparable-sales-growth
  build applies to company comp. Use the quarterly rate as the full-year `N+1`
  assumption; do not annualize. `N+2` = the average of the historical **annual**
  comps (the quarterly seed excluded); `N+3 … N+5` = the `N+2` cell. With no fresher
  quarter, `N+1` takes the guided franchise comp where the guidance table names one,
  else year `N`'s comp, the default seed.
- **`Franchised units — YoY %`** — no driver; the same formula carried across. It
  resolves to the location build's projected `Franchised EOP Balance`, which the
  location build drives with its franchise openings, its `Closures — % of
  Franchised BOP Balance` closure rate and, where the issuer discloses them, net
  transfers to or from the company roll (`../locationBuild/locationBuild.md` §3.1).
  This block reads the franchised roll's `Franchised EOP Balance` and nothing else
  on either roll.
- **Sales-linked streams** — black formulas `= prior col × (1 + units YoY) ×
  (1 + SSS)`.
- **Non-sales streams** — black formulas off their red `— YoY %` drivers (default
  seed). A fee line whose history is a step rather than a rate (a technology-fee
  roll-out, a one-off termination fee) may instead carry a **flat dollar increment**
  driver (`= prior col + increment`); when used, label the driver row `<stream> —
  annual increment`, tag it `(USD in <scale>)`, and record the bridge from the
  filing in its Col C comment.
- **Mode B** — `Franchise Revenue YoY %` is the red driver (default seed); each
  carried stream row compounds off it pro rata, and `Revenue from Franchises` is
  their explicit sum (or compounds off the driver directly when the issuer reports
  a single line).

### 5.1 — Checks (projection)

- [ ] Every non-driver projection cell is a live `=` formula; the two growth
      reference rows carry no driver.
- [ ] A recency seed, when used, is documented in the comp row's Col C comment and
      the quarterly rate is not annualized; the `N+2` average excludes it.
- [ ] `Revenue from Franchises` remains the explicit sum in every projection
      column; the invoking build's `components − Total (must = 0)` memo is 0.
- [ ] Zero formula errors after `recalc.py`.

---

## Section 6 — Worked example (illustrative): a four-stream franchisor, USD in millions

The figures below are round numbers for a made-up issuer; they illustrate the
mechanics and are not a target for any build.

The issuer reports four franchise streams in fiscal `N`: royalties 500.0, franchise
fees 100.0, rental income 240.0 and advertising funds 420.0, so `Revenue from
Franchises` is 1,260.0. The location build carries a `Franchised EOP Balance` of
7,000 at the end of `N` and projects 7,070 for `N+1` from its openings and closure
rate, a `Franchised units — YoY %` of +1.0%. deepKPI carries a franchise comp series:
−4.0% for fiscal `N`, and −6.0% for the first quarter after `N`. The guidance table
names no franchise comp. The inventory carries franchise revenue (§1.1) and both the
roll and the comp series exist (§1.3), so the block runs in **Mode A**.

Royalties and advertising funds are sales-linked; fees and rental income are
non-sales. For `N+1`:

- `Franchise comparable sales (SSS), %` seeds at the latest quarter, −6.0%, as a
  green input (§5).
- Royalties `= 500.0 × 1.010 × 0.940 = 474.7`; advertising funds
  `= 420.0 × 1.010 × 0.940 = 398.7`.
- Fees take the default seed, the latest year's `YoY %` of +2.0%, so 102.0; rental
  income likewise at +0.5%, so 241.2. Had the fee history been a step, a technology
  fee rolled out across the system, the flat-increment driver of §5 would apply
  instead, with the bridge from the filing in the driver's comment.
- `Revenue from Franchises = 474.7 + 398.7 + 102.0 + 241.2 = 1,216.6`, down 3.4%,
  and it recovers from `N+2` as the comp driver reverts to the historical annual
  average.

Under **Mode B** the single line would have compounded off its own latest-year rate,
+1.6%, to 1,280.2 for `N+1` regardless of the −6.0% comp. That inconsistency between
the unit roll, the comp series and the franchise line is what this block exists to
remove.

---

## Section 7 — Upgrade path (not implemented)

Mode A treats every franchised unit as mature. Where the issuer also reports
**franchise systemwide sales** in dollars (an operating KPI outside the income
statement), a cohort-based build is the more accurate successor: partition
franchised units by opening vintage as `../comparableStoresBuild/comparableStoresBuild.md`
§1 does for company units, apply the franchise comp to the mature cohort's sales and
a ramp to the new cohort, then bridge franchise sales to reported revenue through an
**effective royalty rate** (`royalty revenue ÷ franchise systemwide sales`) and an
**effective advertising-contribution rate**. That build would also be the only
sound way to model franchise restaurant sales in dollars, which the
comparable-stores build's company-owned universe (its §1.8) deliberately leaves
out. It is recorded here so the door stays open; it is not part of this block.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the chain.
- This block writes **only** the franchise revenue rows; the company-restaurant
  revenue, the Other plug and Total Revenue belong to the invoking build.
