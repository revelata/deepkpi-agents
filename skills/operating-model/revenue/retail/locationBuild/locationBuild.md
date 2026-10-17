---
name: revenue-retail-location-build
description: >
  Location (retail store unit) roll-forward build for retail companies in the
  operating-model workbook. Invoked by the retail router
  (`revenue/retail/retail.md`) BEFORE it routes to a revenue sub-build, whenever
  the shared KPI inventory contains a **total store / location count** KPI for
  the company (the LOCATION GATE). Receives the resolved `company_id`, official
  company name, workbook path, and the shared KPI inventory; lays out a
  per-banner store unit roll-forward (Stores, Openings, Closures) beneath a
  bold + underlined `Location Build` header nested under the `REVENUE` ALL-CAPS
  header — one block per retail banner / chain for
  multi-banner parents, plus a consolidated Total block. Pulls series via
  `search_kpis` against the shared inventory; format per
  ../../../../_common/revelata-excel-styling-rules.md (one row per series, derived
  cells as live formulas) EXCEPT for time scope and column ordering, which this
  build overrides (see §1, "Time scope and column ordering"). Produces the store
  counts that any downstream revenue sub-build (`comparableStoresBuild/`,
  `unitsBuild/`, `sqftBuild/`, `other/`) can reference.
---

# revenue — retail — location build (store unit roll-forward)

This is the **store roll-forward** build for retail companies. It is invoked by
the retail router (`../retail.md`) **before** the router dispatches to a revenue
sub-build, whenever the shared KPI inventory contains a **total store / location
count** KPI for the company. Its job is to lay down the retail store count
roll-forward (Stores, Openings, Closures) so that whichever revenue sub-build
runs next — `comparableStoresBuild/`, `unitsBuild/`, `sqftBuild/`, or `other/` —
can reference these store counts.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, and the router's note that the **LOCATION GATE PASSED** — i.e. a
total store / location count KPI is present in the inventory.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
`../../../../_common/revelata-excel-units-and-scale.md` (see §3.14) and build with the **xlsx** skill. All conventions there apply here — one row per
distinct series, deepKPI-sourced values as pale-green hyperlinked input cells,
and **every** total / derived cell as a live `=` formula (never a hardcoded
number) — **except** for the **time scope** and **column ordering**, which this
build overrides per §1 below.

**Scope — what this build does NOT lay down.** This build writes **store unit
counts only**. Retail inventories are dense with **square-footage** series
(selling square footage, gross square footage, average store size, sales per
square foot) — those belong to `../sqftBuild/sqftBuild.md`, not here. Do not add
square-footage rows to the roll-forward, even when the data is abundant. Square
footage may be used as a *cross-check* (see §3.13), never as a line item in this block.

## Section 1 — Time scope and column ordering (overrides the common styling rules)

These rules **override** the corresponding conventions in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (per the
  mechanics below), then **extends every roll-forward into the projection window**
  following the **Projections (forecast years)** section near the end of this file.
  Do not fabricate projection values outside that procedure.
- **The store-count build is ANNUAL.** It is built as a roll-forward driven by
  **annual store activity** (openings and closures), which retailers report
  **annually** in the 10-K store-activity table — not by quarter. So this build
  uses **annual columns only** (one per fiscal year, oldest → newest, left →
  right). Do not add quarterly columns to the store roll-forward; a quarterly
  roll-forward is not possible because the opening and closing flows are not
  reported quarterly. Some retailers *do* file a quarterly period-end store count
  in the 10-Q — that is a **period-end level, not a flow**, and it does not make
  the roll-forward quarterly. (If a later section of the workbook is genuinely
  quarterly, the standard column-ordering rule applies there: put quarterly
  columns first, then a blank separator, then annual columns.)
- **Never silently substitute data.** If a deepKPI series for a specific cell is
  a clear data-quality artifact (order-of-magnitude scaling or tagging error), do
  not transcribe it. Prefer a clean alternate deepKPI series; if none exists,
  take the value from the company's 10-K store-activity / store-count table, mark
  that cell distinctly (see §3.14), and add one Notes line: *"Revenue: <row>
  FY<n> is taken from the 10-K store-activity table; the database series was
  <scaled / mis-tagged / missing>."* Retail
  store-count series carry these artifacts **often** — read
  §3.8 before you
  transcribe a single cell.

## Section 2 — The retail fiscal calendar — align columns before you align anything else

This is the **first** thing to get right in a retail build, and the one that
silently ruins the whole block if you get it wrong. Retailers are almost all on a
**52/53-week fiscal calendar ending in late January or early February**, so a
company's "fiscal 2025" ends in **calendar 2026**. deepKPI date stamps on retail
store-count series are therefore **not** interchangeable with calendar years, and
they are **not even consistent from issuer to issuer**:

- **Actual fiscal year-end stamps.** The Gap, Inc.'s fiscal 2025 is stamped
  `2026-01-31`; its 53-week fiscal 2023 is stamped `2024-02-03`. The stamp year is
  **one greater** than the fiscal-year label.
- **Calendar placeholder stamps.** Dollar General's fiscal years are stamped
  `2022-12-31 … 2025-12-31` even though its fiscal years end in late January /
  early February. Here the stamp year **equals** the fiscal-year label.
- **Different stamps for the same fiscal year within one issuer.** For TJX's
  fiscal 2024, `TJX Total Number of Stores at Year-End` and
  `TJX Canada Total Number of Stores at Year-End` are stamped `2025-01-31` while
  `Marmaxx Total Number of Stores at Year-End` and
  `HomeGoods Total Number of Stores at Year-End` are stamped `2025-02-01` — the
  **same** fiscal year under two different date strings.

Consequences you must design around:

- **Never join series on the raw date string.** Map each series' stamps to
  **fiscal-year ordinals** first (order the stamps within the series, then anchor
  the newest to the last fiscal year the filing reports), and write each value
  into the fiscal-year column it belongs to. Joining on the literal date will
  scatter one banner's counts across two columns and leave holes in another.
- **Anchor the mapping against the filing, not against the stamp.** Confirm the
  newest column's Total System EOP equals the total store count in the most recent
  10-K. If it does not, your fiscal-year alignment is off by one — fix the mapping
  before touching anything else.
- **Label columns by the company's own fiscal-year name** (the year the company
  calls it), and make the header date serial the company's real fiscal year-end
  date, formatted `yyyy` per the styling rules.
- **The 53rd week does not change store counts.** A 53-week year affects sales,
  never the period-end fleet. Do not adjust a count for it; it is a revenue-walk
  concern that belongs to the downstream revenue sub-build.

## Section 3 — Locations: retail store unit roll-forward

The store-count build is laid out as a **per-banner roll-forward**, not a flat
list of period-end counts. The source of truth is the 10-K **store-activity /
store-count table** (a beginning balance, the period's openings and closings, and
an ending balance — commonly titled "Store count and square footage", "Number of
store locations", or "Stores in operation"), plus the period-end **company-
operated vs. franchised / licensed** table where the retailer has a franchised or
licensed fleet. Build one roll-forward block **per retail banner / chain** (e.g.
Old Navy, Gap, Banana Republic, Athleta; or T.J. Maxx, Marshalls, HomeGoods,
Sierra, Winners, TK Maxx), then a consolidated **Total** block.

### 3.1 — The `Location Build` section header

Everything this build writes lives inside **one** named block. Before the first
banner block, write a single header row in Col C reading **`Location Build`**,
directly beneath the `REVENUE` ALL-CAPS header:

- **`Location Build` is indented once** — `Alignment(indent=1)`, one level under the
  `REVENUE` header — and styled **bold + underlined**
  (`Font(bold=True, underline="single")`). It is **not** all caps and **not**
  enlarged: it is a sub-section under `REVENUE`, not a top-level section header.
- It is a **label-only** row — no data in any period column. No values, no fill, no
  sum bar, no hyperlink.
- **Every row this build writes is nested beneath it**, one indent level deeper —
  each banner header, both ownership rolls, every line item, and the consolidated
  `Total — all banners` block. Nothing in this build sits at or above the header's
  indent level.
- Indentation is the cell's **real indent property** — `Alignment(indent=n)`, the
  equivalent of Excel's **Home → Increase Indent** (`Alt, H, 6`) — per
  `../../../../_common/revelata-excel-styling-rules.md`, and **never** leading spaces
  in the label string. Leading spaces draw the header's underline under the padding
  and produce a ragged rule running left of the text. When setting a cell's
  `Alignment`, keep its existing `horizontal` / `vertical` settings and add
  `indent=n`; do not replace the whole `Alignment` object.
- One blank spacer row separates the header from the first banner block.

### 3.2 — What counts as a store (and what does not)

Before you map a single series, settle what belongs in the fleet. Retail
inventories are full of near-miss series that are **not** the company's store
count, and putting any of them in the roll-forward corrupts every downstream
build:

- **Distribution centers and fulfillment centers are not stores.** TJX's
  inventory carries `Owned/Leased Distribution Center Square Footage for <Segment>`
  right next to store square footage. DCs never enter the store fleet. If the user
  wants them, they are a separate, clearly-labeled block — not part of this one.
- **Merchandise units are not store units.** `Units sold`, `Pairs sold`,
  `Items sold`, `Retail units sold` are product volume and feed the router's
  build **B**, never this roll-forward. Read the `unit` field: a store series is
  `stores` / `locations`, a merchandise series is a goods count.
- **Wholesale "doors" are not the company's stores.** `Doors`,
  `Points of distribution`, `Wholesale doors` count *third-party* retail locations
  carrying the brand. They are a distribution metric and do not belong in a fleet
  the company operates.
- **Relocations and remodels do not change the count.** Dollar General reports
  `Annual store relocations across consolidated operations` and
  `Annual stores remodeled through Project Renovate` / `Project Elevate`. A
  relocated store closes one address and opens another — **net zero**; a remodel
  changes nothing. Never add these to Openings, and never let them into the
  `Other` plug's interpretation. (Some retailers *do* include relocations in both
  their gross "opened" and gross "closed" lines — if so the two offset and the
  roll-forward still foots; rather than stripping them, add one Notes line:
  *"Revenue: openings and closures both include relocations, which offset within
  the roll."*)
- **Temporarily closed stores are still in the fleet.** A store closed for
  refurbishment or a seasonal / emergency shutdown remains a period-end location
  unless the filing says it was permanently closed.
- **Average store count is not a period-end count.** A series describing an
  average or weighted-average store base over the year is a denominator for
  per-store metrics, not an EOP balance. It does not go in the `EOP Balance` row.
- **Franchised / licensed / partner-operated stores are a separate roll.** They
  are part of the *system* fleet but generate a different revenue type (royalty
  and wholesale, not owned-store sales), so they get their own roll — never
  blended into the company-operated roll.

### 3.3 — Per-banner block layout

For **each banner**, lay out a Company-Operated roll and (only if the banner has
a franchised / licensed fleet) a Franchised & Licensed roll — all of it nested one
indent level beneath the `Location Build` header. The indent shown in the diagram
below is the **real cell indent** (`Alignment(indent=n)`), never leading spaces:

```
Location Build                                                   [indent 1; bold + underlined section header — label only — no data]

  <Banner>                                                       [indent 2; banner header — bold + underlined]
    Company-Operated                                             [indent 3; ownership header — bold + underlined]
      BOP Balance                                   (locations)  [indent 4; FORMULA = prior FY EOP Balance; blank (dash) in the base year]
      Store Openings                                (locations)  [indent 4; deepKPI / 10-K INPUT; positive]
      Store Closures                                (locations)  [indent 4; deepKPI / 10-K INPUT; entered NEGATIVE]
      Program Closures — <Program> — % of <base>    (% of <base>)  [indent 4; ONLY where the filing states the program as a share of a base — §4.2; the share, a red INPUT hyperlinked to the 10-K in the year the program enters; dash elsewhere; directly above the count row]
      Program Closures — <Program>                  (locations)  [indent 4; ONLY where the filing discloses a closure program on this roll — §4.2; always a count; entered NEGATIVE; 10-K INPUT in history where the issuer states the year's program closures (an "of which" within Store Closures, outside the plug); forward a red driver hyperlinked to the 10-K for a program stated as a count, or FORMULA = −ROUND(<share> × <base row, year N>, 0) for one stated as a share; dash elsewhere]
      Other (transfers, conversions, acquisitions)  (locations)  [indent 4; FORMULA plug = EOP − BOP − SUM(flows); blank (dash) in the base year]
      EOP Balance                                   (locations)  [indent 4; deepKPI INPUT — reported period-end count; bold, SUM-BAR]
    Franchised & Licensed                                        [indent 3; ownership header — bold + underlined; OMIT entirely if the banner has no franchised/licensed fleet]
      BOP Balance                                   (locations)  [indent 4; FORMULA = prior FY Franchised & Licensed EOP Balance]
      Franchise Openings — <Geography>              (locations)  [indent 4; deepKPI / 10-K INPUT; one row per geography the filing reports, in its captions — ONLY where it splits franchise openings — §3.6]
      Franchise Openings — <Geography 2>            (locations)  [indent 4; deepKPI / 10-K INPUT; same condition]
      Franchise Openings                            (locations)  [indent 4; deepKPI / 10-K INPUT where reported as one line; FORMULA = SUM(geography rows) where split — §3.6]
      Store Closures                                (locations)  [indent 4; deepKPI / 10-K INPUT; entered NEGATIVE]
      Program Closures — <Program> — % of <base>    (% of <base>)  [indent 4; ONLY where the filing states the program as a share of a base — §4.2; same shape as the company roll's row]
      Program Closures — <Program>                  (locations)  [indent 4; ONLY where the filing discloses a closure program on this roll — §4.2; same shape as the company roll's row, its own values]
      Other (transfers, conversions)                (locations)  [indent 4; FORMULA plug = EOP Balance − BOP − SUM(flows); blank (dash) in the base year]
      Franchised EOP — <Geography>                  (locations)  [indent 4; deepKPI INPUT; one row per reported geography — §3.6]
      Franchised EOP — <Geography 2>                (locations)  [indent 4; deepKPI INPUT]
      Franchised & Licensed EOP Balance             (locations)  [indent 4; FORMULA = SUM(geography EOP rows), or the reported total; bold, SUM-BAR]
```

The row order makes the identity **`BOP + Openings + Closures + Other = EOP`**
read top-to-bottom within each ownership roll. **Closures are entered as negative
numbers** so the whole flow region is a single contiguous `SUM(...)` range; put a
cell comment on the Closures row stating that convention. The `Other` line is the
closing plug; `EOP Balance` is the reported period-end count (an input, or a sum
of the reported geography splits).

**When the retailer reports only a NET flow** (see §3.9), the two flow rows collapse into one:

```
      Net Stores Opened / (Closed)                  (locations)  [indent 4; deepKPI / 10-K INPUT; signed]
```

Keep the row in the same position the gross flow rows occupied, keep `Other` as
the plug beneath it (a `Program Closures — <Program>` row, where laid, sits between
the two, §4.2), and add one Notes line: *"Revenue: <banner> gross openings
and closures are not disclosed; the roll carries net openings."* **Do not** invent
a gross split from a net number.

Then a consolidated total:

```
  Total — all banners                                            [indent 2; bold + underlined sub-header]
    Company-Operated BOP Balance                    (locations)  [indent 3; FORMULA = prior FY Company-Operated EOP Balance; dash in the base year; ONLY when flows are disclosed for the consolidated fleet alone — see below]
    Store Openings                                  (locations)  [indent 3; deepKPI / 10-K INPUT; history only; same condition]
    Store Closures                                  (locations)  [indent 3; deepKPI / 10-K INPUT; entered NEGATIVE; history only; same condition]
    Other (transfers, conversions, acquisitions)    (locations)  [indent 3; FORMULA plug = EOP − BOP − SUM(flows); dash in the base year; history only; same condition]
    Company-Operated EOP Balance                    (locations)  [indent 3; FORMULA = sum of each banner's Company-Operated EOP]
    Franchised & Licensed EOP Balance               (locations)  [indent 3; FORMULA = sum of each banner's Franchised & Licensed EOP; ONLY where the issuer reports a franchised or licensed fleet]
    Total System EOP Balance                        (locations)  [indent 3; FORMULA = Company-Operated + Franchised & Licensed, or = Company-Operated EOP Balance where no franchised row is laid; bold, SUM-BAR]
```

**When flows are disclosed only for the consolidated fleet** — every banner roll is
Tier 3 while the 10-K store-activity table gives openings and closures for the
fleet as a whole (§3.9) — the Total block carries those flows in the four rows
above `Company-Operated EOP Balance`, so the issuer's only flow disclosure is on
the sheet as numbers, not in a comment. The rows roll the company-operated fleet:
`Company-Operated BOP Balance` chains off the prior column's summed
`Company-Operated EOP Balance`, the flow rows are the issuer's figures with the
provenance of §3.9, `Other` is the plug, and the roll foots to the summed EOP. In
the projection columns the four rows are dashes: the forward drivers are the banner
rolls' `Net Change` rows and the Total block stays their sum (§4.3). When the
issuer's table counts a franchised or licensed fleet together with the company
stores, say so in the `Store Openings` comment and foot the roll to `Total System
EOP Balance` instead, with the BOP row labeled `Total System BOP Balance`. The four
rows are omitted whenever any banner roll carries its own flows.

**Keys.** Each banner's `EOP Balance` is keyed `coeop_<banner>` (the banner's name
as a slug) and the Total block's `Company-Operated EOP Balance` is keyed
`coeop_total`: the contract-row keys of `../../../SKILL.md`, which the cost builds,
the NWC build and the revenue sub-builds reference.

**Row table** (the rows above, as the Step 5 audit reads them; `Lays when` per
`../../../SKILL.md`; a per-banner row is required at least once):

| Row (Col C label) | Lays when | Units (Col D) | Cell |
|---|---|---|---|
| `BOP Balance` | | `(locations)` | `= prior FY EOP Balance`; dash in the base year |
| `Store Openings` / `Store Closures` | DATA_DEPENDENT | `(locations)` | Tier 1 gross flows, where the issuer discloses them |
| `Net Stores Opened / (Closed)` | DATA_DEPENDENT | `(locations)` | Tier 2 net flow, where only the net is disclosed |
| `Net Change` | DATA_DEPENDENT | `(locations)` | Tier 3: `= EOP − BOP` in history; the roll's driver forward (§4.1) |
| `Program Closures — <Program> — % of <base>` | DATA_DEPENDENT | `(% of <base>)` — `<base>` the issuer's words for its base (`the fleet`, `U.S. stores`) | where the filing states the program's size as a share of a base (§4.2): the share, a red input hyperlinked to the 10-K, in the year the program enters only; dash elsewhere. Directly above the count row. Its comment quotes the statement, names the row the share is applied to and, where the issuer's base spans both rolls, says the split is pro rata |
| `Program Closures — <Program>` | DATA_DEPENDENT | `(locations)` | where the filing discloses a closure program on this roll (§4.2), named as the issuer names it, directly beneath the roll's closures row (`Store Closures`, `Net Stores Opened / (Closed)` or `Net Change`): the program's closures by year, negative, always a count. 10-K input in the historical years the issuer states a figure for (an "of which" within the closures row, outside the plug). Forward, for a program stated as a count: a red driver hyperlinked to the 10-K in each projection year the program covers; for one stated as a share: `= −ROUND(<share row, this col> × <base row, year N>, 0)` in the year the program enters, the base row per §4.2's test; dash elsewhere. One row per roll the program covers |
| `Other (transfers, conversions, acquisitions)` | DATA_DEPENDENT | `(locations)` | plug `= EOP − BOP − SUM(flows)` in history |
| `EOP Balance` | | `(locations)` | deepKPI input, reported period-end count |
| `Franchise Openings — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where a franchised fleet's openings are split by geography; `Franchise Openings` is then their sum (§3.6) |
| `Franchise Openings` | DATA_DEPENDENT | `(locations)` | on every franchised roll: deepKPI / 10-K input where reported as one line; `= SUM(geography rows)` where split (§3.6) |
| `Franchised EOP — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where a franchised fleet is split by geography |
| `Franchised & Licensed EOP Balance` | DATA_DEPENDENT | `(locations)` | where the issuer reports a franchised or licensed fleet: `= SUM(geography EOP rows)`, or the reported total; omitted for an all-owned fleet, never a row of zeros or dashes |
| `Company-Operated EOP Balance` | | `(locations)` | Total block: `= Σ each banner's Company-Operated EOP` — contract row |
| `Total System EOP Balance` | | `(locations)` | Total block: `= Company-Operated + Franchised & Licensed`, or `= Company-Operated EOP Balance` where no franchised row is laid; SUM-BAR |
| `Company-Operated BOP Balance` | DATA_DEPENDENT | `(locations)` | Total block, flows disclosed only for the consolidated fleet: `= prior FY Company-Operated EOP Balance`; dash in the base year |
| `Store Openings` / `Store Closures` / `Other (transfers, conversions, acquisitions)` in the Total block | DATA_DEPENDENT | `(locations)` | the consolidated flows and their plug, history only; dashes in the projection columns |

### 3.4 — Roll-forward mechanics

Each ownership roll obeys the identity **`EOP = BOP + Openings + Closures +
Other`** (equivalently `EOP = BOP + Net flow + Other` on a net-disclosure
retailer). Build the rows so this holds as live formulas:

- **BOP Balance** of a year is a **live formula** equal to the **prior year's EOP
  Balance** for that same line (chain columns left → right; e.g. `=<prevCol><EOProw>`).
  The earliest / base year has no prior column, so its **BOP is blank (dash)**.
  - *Exception worth knowing:* some retailers publish a `… at Beginning of Period`
    series directly (Dollar General has `Number of Retail Stores at Beginning of
    Period - annual`). **Do not** use it as the BOP input — BOP stays a formula so
    the columns chain. Use the reported BOP as a **cross-check** that your chained
    formula matches the filing, and note any disagreement.
- **Openings / Closures** rows are **deepKPI or 10-K input flows** for the fiscal
  year (whole-store counts). Closures are entered **negative**.
- **Other (transfers, conversions, acquisitions)** is the **closing plug**, a
  **live formula** computed every non-base year as
  **`Other = EOP − BOP − SUM(flow rows)`**:
  - Company-Operated roll:
    `= EOP − BOP − SUM(Store Openings : Store Closures)`.
  - Franchised & Licensed roll:
    `= Franchised & Licensed EOP Balance − BOP − SUM(Franchise Openings : Store
    Closures)` — the grouped openings row (itself `SUM(...)` over its geography rows
    where split) through the closures row. Use `SUM(...)` over the contiguous flow
    rows (not bare addition/subtraction) so empty/dash flow cells don't throw
    `#VALUE!`. A `Program Closures — <Program>` row beneath the closures row (§4.2)
    stays **outside** this range: its historical values are already inside the
    closures row.
  - It represents everything that changes the balance other than the reported
    flows — chiefly **banner conversions / rebannering** (a store converted from
    Banner A to Banner B leaves A and joins B, with **no change to the system
    total**), **acquisitions and divestitures of store fleets**, and
    **franchise-status transfers** (stores the company **buys back from**
    franchise or license partners → adds to Company-Operated, removes from
    Franchised & Licensed; or stores it **transfers to** partners → the reverse).
    It **can be negative**. When the company converts N stores from Banner A to
    Banner B in a year, expect roughly **−N on A's `Other` and +N on B's `Other`,
    netting to zero at the Total block** — that offset is the check that a
    conversion was handled correctly.
  - **Blank (dash) in the base year** (no BOP to difference against).
  - **A large, persistent, unexplained `Other` is a defect, not a result.** If the
    plug is material and you cannot name what it represents, your flows or your
    EOP are wrong — go back to the filing before proceeding.
- **EOP Balance** is the **reported period-end count** — a deepKPI input, or (for
  a franchised roll with a geography split) a formula `= SUM(geography EOP rows)`.
  Because `Other` absorbs the residual, every roll now **foots
  exactly**.
- Every non-input cell (BOP, Other, EOP subtotals, Total block) is a live `=`
  formula — never a hardcoded number. After building, **recalculate** (LibreOffice /
  the xlsx skill's `recalc.py`) and confirm **zero formula errors**, then confirm
  the **Total System EOP** ties to the filing.

### 3.5 — Choosing the banner partition — the retail hierarchy trap

Restaurant concepts are flat; **retail store counts are nested**, and the
inventory publishes counts at **every** level of the nest under near-identical
names. A retailer's fleet is typically reported as

```
consolidated total  →  reportable segment  →  banner / chain  →  country / state / province
```

and deepKPI will happily give you all four. TJX's inventory, for example, carries
`Store count for the consolidated company`, `TJX Canada Total Number of Stores at
Year-End` (segment), `Winners Number of Stores at Year-End` (chain), and
`Number of Winners stores in Ontario - Canada` (province) — plus several
differently-worded duplicates of each.

Rules for building the partition:

1. **Pick exactly one level as the block level, and make it the finest level that
   is reported consistently across all four historical years** — normally the
   **banner / chain**. Segment-level blocks are acceptable when the retailer only
   reports at segment level.
2. **Never mix levels inside the Total block.** A Total that sums one segment
   total, two chain totals, and a state-level count is wrong even if the arithmetic
   happens to land near the right number.
3. **Never sum geography-level series to build a banner.** They are a
   decomposition of a count you already have, and they are frequently incomplete
   (states with no stores are simply absent). Use the reported banner total.
4. **Do not trust a series' "Total" label to mean what it says.** Verify by
   footing. Summing TJX's four labeled segment series —
   `Marmaxx Total Number of Stores at Year-End` (2,603),
   `HomeGoods Total Number of Stores at Year-End` (1,042),
   `TJX Canada Total Number of Stores at Year-End` (589) and
   `TJX International Total Number of Stores at Year-End` (835) — gives **5,069**
   for the latest fiscal year against a reported consolidated
   `TJX Total Number of Stores at Year-End` of **5,214**: a **145-store gap**.
   Adding the separately-named
   `Number of Homesense stores in the HomeGoods segment in the U.S.` (79) closes
   only part of it. The labeled "segment totals" are **chain-level counts wearing
   a segment name**, and chains omitted from that naming are simply missing. The
   partition is not finished until the parts foot to the consolidated total —
   see §5.
5. **Deduplicate aggressively — one row per fleet, not one row per KPI string.**
   Retail inventories carry heavy synonym duplication for the same concept
   (`Number of Winners Stores in Operation at End of Period for TJX Canada
   Segment`, `Number of Winners Stores in Operation in TJX Canada Segment at End
   of Period`, `Winners Number of Stores at Year-End`, `Total number of Winners
   stores in Canada` are all one series). Pick the **cleanest and longest-covered**
   string as the canonical input, put it in the hidden Col A audit trail, and use
   the others only to cross-check. Per the styling rules this is **one row**, not
   four.

### 3.6 — Geography and ownership splits — only when reported

Show a split **only where the filing reports it**, otherwise use a single grouped
line:

- **Company-operated openings** are usually reported as a single line per banner
  (no geography split), so use **one grouped "Store Openings" row** — do **not**
  invent a domestic/international split for company openings.
- Where a retailer reports its banners **by region** (Gap files
  `Number of Company-Operated Gap North America Store Locations at End of Period`
  and `… Gap Asia …` as separate series), the **banner × region** pair is the
  block level — treat `Gap North America` and `Gap Asia` as two blocks, not one
  block with a geography sub-split. Their EOPs both roll into the same Total.
- **Franchise / license openings and franchise EOP stores** are reported split by
  geography by some retailers and as a single line by others. The roll mirrors the
  company roll: one grouped `Franchise Openings` row and the reported `Franchised
  & Licensed EOP Balance` where the filing reports them as one line; where it
  splits them, **one `<Row> — <Geography>` line per geography in the filing's
  store-activity table, captioned and ordered as that table gives them** (U.S. and
  International; North America, Europe and Asia; whatever the issuer uses), only
  the table's top-level split, with `Franchise Openings` and `Franchised & Licensed
  EOP Balance` as `SUM(...)` over the geography rows, so any number of them foots.
  Never rename a geography to a house vocabulary, and **never drop a reported
  geography** (the international rows are the ones most often missed).
- A banner with **no franchised or licensed fleet** (Old Navy, HomeGoods) gets
  **no Franchised & Licensed block at all**.

### 3.7 — Generic build procedure (any retailer)

Follow these steps in order; they reproduce the same structure for any retail
issuer:

1. **Fix the fiscal-year mapping first.** Per §2,
   map every candidate series' date stamps to fiscal-year ordinals and confirm the
   newest column against the latest 10-K's total store count. Everything after this
   depends on the columns being right.
2. **Identify the banners / chains and pick the partition level.** From the shared
   KPI inventory (and, if needed, `get_company_summary` / `get_company_segments`),
   list every banner the registrant operates and apply the hierarchy rules above. A
   single-banner retailer yields **one** block; a multi-banner parent yields **one
   block per banner** (or banner × region where that is the reporting level).
   Banner names appear inside the KPI strings (e.g. `"<Banner> Number of Stores at
   Year-End"`, `"Number of Company-Operated <Banner> <Region> Store Locations at
   End of Period"`).
3. **Decide each banner's ownership coverage.** A banner may be company-operated
   only, franchised / licensed only, or both. Build the Company-Operated roll
   whenever company-operated stores are reported; build the Franchised & Licensed
   roll **only** if franchised, licensed, or partner-operated stores are reported
   for that banner (otherwise omit it entirely).
4. **Map the KPI families per banner**, pulling each with `search_kpis` against the
   shared inventory (never re-run `list_kpis`). Match on these patterns:
   - **Company-operated EOP (period-end count):**
     `"<Banner> Number of Stores at Year-End"`,
     `"<Banner> Stores in Operation at End of Period"`,
     `"Number of Company-Operated <Banner> <Region> Store Locations at End of Period"`,
     `"Store count for <Banner>"`, `"Number of Retail Stores at End of Period"`,
     `"Total Number of Company-Operated Store Locations at End of Period"`,
     `"Warehouses"`, `"Clubs"`, `"Supercenters"`.
   - **Franchised / licensed EOP:** `"Franchise store locations"`,
     `"Franchise store count operated by franchise partners"`,
     `"Franchise partner-operated franchise stores"`, `"Licensed stores"`,
     `"Partner-operated stores"`, plus `"Franchise countries"` for context.
   - **Company-operated openings:** `"Number of New Retail Stores Opened"`,
     `"<Banner> store openings"`, `"Stores opened"`, `"New stores opened"`.
     **This series is frequently sparse or entirely absent in deepKPI even when the
     retailer fully discloses openings in its filing — do NOT conclude openings are
     unavailable from deepKPI alone.** If it is incomplete or missing, source
     openings from the 10-K store-activity table (see §3.9).
   - **Closures:** `"Number of Retail Stores Closed"`, `"Stores closed"`,
     `"Store closures"`, `"Annual store closures across consolidated operations"`.
   - **Net flow (when gross is not disclosed):**
     `"Net Number of Company-Operated <Banner> <Region> Stores Opened or Closed"`,
     `"Net Number of Total Company-Operated Stores Opened or Closed"`,
     `"Net Increase in Number of Retail Stores"`, `"Net new stores"`.
   - **Decoys to exclude** (see §3.2): relocations, remodels,
     distribution-center counts and square footage, merchandise units, wholesale
     doors, average store counts, state/province-level counts.
5. **Pick the cleanest series and validate every cell.** Prefer annual series
   covering all four historical fiscal years. For each cell, sanity-check the value
   against the series trend, against the sibling banners, and against the 10-K
   store-count table. **Reject obvious artifacts** per §3.8, and
   instead take that cell from the 10-K (mark it; see styling).
6. **Build the rolls and the Total block, then reconcile.** Confirm, for every
   year, that the banner EOPs sum to `Company-Operated EOP + Franchised & Licensed
   EOP = Total System EOP` (`Company-Operated EOP = Total System EOP` for an
   all-owned fleet) and that the Total System EOP matches the filing's
   reported total store count. Confirm each ownership roll foots via the `Other`
   plug. Recalculate and confirm zero formula errors before delivering.

### 3.8 — Data-quality artifacts in retail store-count series (read before transcribing)

Retail store-count series in deepKPI carry scaling and tagging artifacts at a
**higher rate** than restaurant unit series, and — critically — the artifacts are
often **intermittent within a single series**, so a blanket "divide the whole row
by a million" fix is itself a defect. Check **every cell**, not every series.

The four artifact shapes, each observed in live retail inventories:

- **Order-of-magnitude scaling (×10⁶).** The Gap, Inc.'s
  `Total Number of Company-Operated Store Locations at End of Period` returns
  `3200000000`, `2562000000`, `2506000000`, `2474000000` where the filed counts are
  **3,200 / 2,562 / 2,506 / 2,474**. Its
  `Net Number of Total Company-Operated Stores Opened or Closed` returns
  `-56000000` and `-32000000` for **−56** and **−32**.
- **Intermittent scaling inside one series.** Gap's
  `Number of Company-Operated Old Navy North America Store Locations at End of
  Period` is **clean** for three consecutive fiscal years (`1252`, `1238`, `1243`)
  and then **scaled** for the next two (`1249000000`, `1242000000`). A row that
  looks fine at the left edge can be corrupt at the right edge. Scan the whole row.
- **Cross-tagged series.** Gap's `Franchise store locations - Annual` reads
  `459`, `429`, `472`, `574` … in every year except its earliest, which reads
  `3721` — that value is the company's **total** store count mis-tagged into the
  franchise row. A single point wildly out of line with its own series is a tagging
  error, not a data point.
- **Duplicate or mis-stamped periods.** `TJX Total Number of Stores at Year-End`
  carries the value `4070` under **two** date stamps (`2017-02-03` and
  `2018-02-03`) — one is the fiscal 2017 count filed under a wrong-year stamp. If
  you write by date without mapping to fiscal years first, a duplicate like this
  silently overwrites a column.

How to handle them:

- **Detect by identity, not by eye.** After transcribing, the roll must foot and
  the parts must sum to the whole (below). A scaled or cross-tagged cell blows
  those checks open immediately — which is exactly why the checks are mandatory
  and run before delivery.
- **Never rescale silently.** Converting a series from the delivered base its
  `unit` field declares (thousands, millions) to base units is Rule 1 of
  `../../../../_common/revelata-excel-units-and-scale.md`, not rescaling, and applies
  here as everywhere. This rule is for a value that does **not** match its declared
  unit. Do not divide such a value by 10⁶ and present it
  as a deepKPI input. Take the value from the 10-K, style it as a **10-K override**
  cell (see §3.14), and add the Notes line of §3.14 (*"Revenue: <row> FY<n> is
  taken from the 10-K store-activity table; the database series was scaled."*).
  The rescaled number may well be
  right, but a cell whose provenance link does not show the number in the cell is
  not a sourced input.
- **Prefer a clean alternate deepKPI series first.** The synonym duplication
  described in the hierarchy trap (§3.5) is useful here: the same fleet often exists under
  three names and only one of them is corrupted.

### 3.9 — Sourcing the flows — the three flow-disclosure tiers (do this for every issuer)

Openings and closures are a **required input** for the roll-forward (and for the
downstream comparable-stores cohort build, which partitions stores by opening
vintage). **Never collapse the flows into a bare `EOP − BOP` plug if the company
discloses them anywhere.** Retailers fall into three tiers, and you must establish
which tier the issuer is in **before** you decide what the roll-forward can carry.

**Step A — deepKPI structured series (try first, but never stop here).** Search
the shared inventory for the flow patterns in step 4 above. Treat these series as
*often partial*: an issuer may have a net-flow series populated for only the two
most recent fiscal years (Gap's `Net Number of Total Company-Operated Stores
Opened or Closed` covers exactly two) while the flows are fully disclosed in the
filing for all four. **A sparse or missing deepKPI flow series does NOT mean the
flows are unavailable.** Do not infer "flows missing" from deepKPI (or from a
handful of `search_kpis` guesses) alone.

**Step B — the 10-K store-activity table (authoritative; always check).** US
retail registrants disclose store activity in **Item 2 (Properties)** and/or in
**MD&A**, usually under a heading like "Store count and square footage", "Number
of store locations", "Stores in operation", or "Store activity". Item 1
(Business) carries the **growth plan** (next year's planned openings). The table
is shaped like one of:

```
                                   FY2024    FY2025          # Tier 1 — gross
Stores at beginning of year         19,986    20,594
   Stores opened                        725       589
   Stores closed                       (117)     (290)
Stores at end of year               20,594    20,893

                          Stores    Net opened/(closed)   Sq ft   # Tier 2 — net only
<Banner A> North America   1,249            6              …
<Banner B> North America     …             (14)            …
```

Rely on these properties:

- **Each fiscal year's 10-K reports that year's actual store activity** plus, in
  Item 1, next year's planned openings. To fill a build window FY(M)…FY(N) you may
  need to pull **each** of those years' 10-Ks — and only those years. Any
  pre-window year a revenue build needs (a cohort lookback, a base-year seed) is
  that build's own pull, made when it runs; this build does not know which
  revenue build will follow and pulls nothing for it. Use the **filing** skill
  (`list_sec_filing_markdowns` → `get_sec_filing_markdown`); do not web-search to
  avoid the call.
- **A "—" entry means zero** stores that year — record **0** (display as a dash),
  not blank, so downstream formulas don't return `#VALUE!`.
- **Closings are often shown in parentheses.** Parentheses mean negative; record
  the sign, don't strip it.

**The three tiers, and what each permits:**

| Tier | What the issuer discloses | Roll-forward rows | Example |
| --- | --- | --- | --- |
| **1 — Gross** | Gross openings **and** gross closures | `Store Openings` + `Store Closures`, `Other` plug ≈ 0 | Dollar General |
| **2 — Net only** | A single net opened/(closed) figure | one `Net Stores Opened / (Closed)` row, `Other` plug | The Gap, Inc. |
| **3 — Levels only** | Period-end counts for the banner; flows absent, or disclosed only for the consolidated fleet | `Net Change` row **derived** as `EOP − BOP`, `Other` omitted; consolidated flows, where disclosed, in the Total block (§3.3) | TJX; Macy's (consolidated flows only) |

- **Tier 1 is the target.** Reach it whenever the filing supports it, even if
  deepKPI only has the levels.
- **Tier 2 is legitimate** when the filing genuinely publishes only a net figure —
  which is common in apparel retail. Do **not** manufacture a gross split.
- **Re-entry on a `DEFECT UPSTREAM` for openings.** If a later build reports that the
  10-K store activity table discloses a gross split this build did not lay (`no Store
  Openings for <banner>`), re-read that table yourself. Where it gives per-banner gross
  openings and closures, lay `Store Openings` and `Store Closures` for the banner as
  **10-K override** inputs (§3.8 styling), drop the banner's `Net Stores Opened /
  (Closed)` row, re-foot the roll, and re-issue the hand-back report with the tier as
  gross for that banner. Where the table gives the split **only at the consolidated
  level**, lay it in the Total block if it is not already there (§3.3) and return
  `RE-ENTRY FAILURE — gross split disclosed at the consolidated level only`; the
  reporting build has its own path for that. Never allocate a consolidated split to
  banners.
- **Tier 3 is a last resort**, permitted **only** after you have confirmed the
  banner's flows are absent from **both** deepKPI **and** the 10-K store-activity
  table. In Tier 3 the `Net Change` row is a **formula** (`= EOP − BOP`), not an
  input, the `Other` plug is omitted (it would be identically zero and add
  nothing), and you **state the fallback in one Notes line**: *"Revenue: <banner>
  openings and closures are not disclosed; the roll carries the period-end counts
  and their net change."* Flag it to the router too: a Tier-3 fleet cannot support
  an opening-vintage cohort, which constrains the downstream
  `comparableStoresBuild/`.
- **Flows disclosed only for the consolidated fleet** put every banner roll in Tier
  3 and the flows themselves in the Total block (§3.3), as inputs with the
  provenance of this section — never as a comment or a Notes line alone. The Notes
  line for this case reads: *"Revenue: openings and closures are disclosed only for
  the company as a whole, not by banner; each banner roll carries its period-end
  counts and their net change, and the total block carries the company-wide
  openings and closures."* Never allocate the consolidated flows to banners.
- **Base-year flows.** The base year is a window year like any other: its flows are
  sourced per Steps A and B and laid even though, with no BOP, they feed no
  formula. A dash there means the filing does not give them, not that they were
  skipped.
- **A banner flow proven zero by the consolidated series.** Where a banner's flow
  is missing for a year and the consolidated flow for that year equals the sum of
  the other banners' flows, the missing flow is zero: enter 0, hyperlinked to the
  consolidated series, with the inference in the cell comment (*"consolidated
  closures of 11 equal the Crocs Brand's 11, so HEYDUDE closed none"*). It is a
  value the filing establishes, not a judgment item.

**Finding the table in the markdown (extraction technique).** These store-activity
tables render as **space-separated cells on a single very long line**, so a linear
read or `offset`/`limit` paging will not surface them, and a vague search will
miss them. Search the saved markdown with **targeted tokens plus a trailing
capture window** (the numbers follow the header on the same line), e.g. the regex
`Store count and square footage.{0,600}` (case-insensitive, match-only). If that
token does not hit (retail wording varies more than any other vertical), try, in
order: `Number of store locations`, `Stores at beginning of year`,
`beginning of period`, `Stores opened`, `Stores closed`, `Stores in operation`,
`Store activity`, `net (opened|closed)`, `<Banner> North America`,
`Total stores`. **Do not** rely on generic phrases like `"we opened"` or
`"store growth"` — they routinely miss the table and will lead you to the wrong
conclusion that the flows aren't disclosed. If `get_sec_filing_markdown` returns
output too large to read inline, search the **saved file** directly with these
tokens rather than abandoning the pull.

**Cross-check before trusting the numbers.** Confirm the transcribed flows
reproduce the reported period-end counts (`BOP + Openings + Closures = EOP`), and
reconcile against any deepKPI net-change series (`Net Increase in Number of Retail
Stores`) for the same year. Then confirm the roll-forward foots and that the
resulting `Other` is explainable by conversions, acquisitions, or franchise
transfers — not by a transcription error.

**Provenance & styling for 10-K-sourced flows.** When a flow value comes from the
10-K store-activity table rather than a deepKPI series, style the cell as a
**10-K-sourced input** (gold fill, dark-blue hyperlinked value linked to **that
fiscal year's** 10-K filing URL) and attach a cell comment like *"Source: FY20XX
10-K, Item 2 Properties / MD&A store-activity table."* Add one Notes line:
*"Revenue: store openings and closures are taken from the 10-K store-activity
tables."* The comment keeps the table reference.

### 3.10 — Worked example — Dollar General (Tier 1, single banner, clean roll-forward)

Dollar General Corp. (`company_id` 29534) is the cleanest shape in retail: one
banner, a fully disclosed gross roll-forward, and deepKPI series that foot
exactly. The mapping is:

- **BOP (cross-check only):** `Number of Retail Stores at Beginning of Period - annual`
- **Openings:** `Number of New Retail Stores Opened - annual`
- **Closures:** `Number of Retail Stores Closed - annual` *(enter negative)*
- **EOP:** `Number of Retail Stores at End of Period - annual`
- **Net-change cross-check:** `Net Increase in Number of Retail Stores - annual`

Reconciliation target — the roll foots **exactly**, with `Other = 0` in every
year:

| Fiscal year | BOP | Opened | Closed | Other | EOP |
| --- | --- | --- | --- | --- | --- |
| FY2022 | 18,130 | 1,039 | (65) | 0 | **19,104** |
| FY2023 | 19,104 | 987 | (105) | 0 | **19,986** |
| FY2024 | 19,986 | 725 | (117) | 0 | **20,594** |
| FY2025 | 20,594 | 589 | (290) | 0 | **20,893** |

**Traps on this issuer.** The inventory carries ~48 `Number of Retail Stores in
<State>` series — a state-level decomposition that must **not** be summed into the
banner (see §3.5). It also carries
`Annual store relocations across consolidated operations` and
`Annual stores remodeled through Project Renovate` / `Project Elevate`, neither of
which changes the fleet — do not add them to Openings. The Mexico fleet has its
own series (`Annual new store openings in Mexico`, plus a cumulative
Mexico store-count series) — treat it as a **separate** block only if it is
material and reported at period-end, and check whether the consolidated openings
row already includes it before adding anything, so Mexico is not counted twice.
Finally, deepKPI stamps DG's fiscal years with calendar placeholders
(`2025-12-31` for fiscal 2025) even though the fiscal year ends in early 2026.

### 3.11 — Worked example — The Gap, Inc. (Tier 2, banner × region, franchised fleet, scaled series)

The Gap, Inc. (`company_id` 39911) is the multi-banner, net-flow shape — and it
carries the scaling artifacts described above, so it is also the example of when
**not** to transcribe a deepKPI value.

- **Block level = banner × region:** Old Navy North America, Gap North America,
  Gap Asia, Banana Republic North America, Banana Republic Asia, Athleta North
  America — each a `Number of Company-Operated <Banner> <Region> Store Locations at
  End of Period` series.
- **Flow = net only:**
  `Net Number of Company-Operated <Banner> <Region> Stores Opened or Closed` —
  Gap publishes a net opened/(closed) column, **not** gross openings and closures.
  One `Net Stores Opened / (Closed)` row per block; `Other` remains the plug.
- **Franchised & Licensed roll:** `Franchise store locations - Annual`,
  `Franchise store count operated by franchise partners`,
  `Franchise partner-operated franchise stores`. Gap's franchise fleet is reported
  as a single consolidated line, **not** split by banner — so it becomes **one**
  Franchised & Licensed block at the parent level rather than a franchised roll
  inside each banner block. Add one Notes line (*"Revenue: the franchised fleet
  is reported only in total, so it is carried as one block at the company level,
  not per banner."*); do not allocate it across banners.
- **Consolidated cross-check:**
  `Total Number of Company-Operated Store Locations at End of Period` and
  `Net Number of Total Company-Operated Stores Opened or Closed`.

**Data-quality traps hit on this issuer (override from the 10-K store-count
table):** the consolidated company-operated count returns `2506000000` /
`2474000000` for filed **2,506** / **2,474**; the consolidated net flow returns
`-56000000` / `-32000000` for filed **−56** / **−32**; and the Old Navy North
America count is **clean** for fiscal 2021–2023 (`1252`, `1238`, `1243`) but
**scaled** for fiscal 2024–2025 (`1249000000`, `1242000000`) — the intermittent
case. `Franchise store locations - Annual` additionally carries a cross-tagged
earliest point (`3721`, which is a total store count, against a franchise series
that otherwise runs in the 400–1,000 range). Once descaled from the filing the
identity holds exactly: **2,562 − 56 = 2,506** and **2,506 − 32 = 2,474** at the
consolidated level, and **1,243 + 6 = 1,249**, **1,249 − 7 = 1,242** for Old Navy
North America. Reconciliation target — **Total Company-Operated EOP = 2,562 /
2,506 / 2,474** for the three most recent fiscal years, plus the franchise fleet
(**998 / 1,063 / 1,000**) at the system level. Note Gap's fiscal 2023 was a
**53-week year** (stamped `2024-02-03`) — that changes sales, not store counts.

### 3.12 — Worked example — TJX (Tier 3, nested hierarchy, no flows in deepKPI)

The TJX Companies, Inc. (`company_id` 109198) is the hardest retail shape and the
reason the hierarchy rules exist. Its inventory contains **hundreds** of
store-count series — consolidated, segment, chain, country and
state/province-level — and **no openings or closures series at any level**. Every
"open" token in the inventory belongs to `Stores in Operation`, a period-end
level.

- **Levels available:** consolidated (`TJX Total Number of Stores at Year-End`);
  segment-named (`Marmaxx / HomeGoods / TJX Canada / TJX International Total Number
  of Stores at Year-End`); chain (`TJ Maxx`, `Marshalls`, `Sierra`, `HomeGoods`,
  `Homesense`, `Winners`, `TK Maxx (Europe)`, `TK Maxx (Australia)` — each with
  several synonymous strings); geography (`Number of Winners stores in Ontario -
  Canada`, `Total Number of Stores in the United Kingdom`, …).
- **The footing failure to expect.** For the latest fiscal year the four labeled
  segment totals sum to **2,603 + 1,042 + 589 + 835 = 5,069** against a reported
  consolidated **5,214** — a **145-store gap** that adding
  `Number of Homesense stores in the HomeGoods segment in the U.S.` (**79**) only
  partly closes. The labeled totals are chain-level counts under segment names;
  chains not covered by that naming are simply absent. **Do not deliver a partition
  that does not foot** — go back to the chain-level series and the 10-K store table
  until the parts sum to the whole.
- **Tier-3 treatment.** With no flow series in deepKPI, check the 10-K store table
  first. If the flows are genuinely not disclosed at the chain level, each roll
  carries a derived `Net Change` (`= EOP − BOP`) formula row, no `Other` plug, and
  the Notes line of §3.9 stating that openings and closures are not disclosed —
  and the router is told the fleet cannot support an opening-vintage
  cohort.
- **Other traps on this issuer.** Distribution-center square-footage series
  (`Owned/Leased Distribution Center Square Footage for <Segment>`) sit right next
  to store series and are **not** stores. The consolidated series carries the value
  `4070` under two date stamps (`2017-02-03`, `2018-02-03`) — map to fiscal years
  before writing. And the same fiscal year is stamped `2025-01-31` on some series
  and `2025-02-01` on others.

### 3.13 — Sanity checks that do not belong in the workbook

Use these to catch errors; do **not** add them as rows (square footage is
`sqftBuild/`'s section, and these are diagnostics, not line items):

- **Average store size × store count ≈ total square footage.** Where the inventory
  has both `<Banner> Approximate Average Store Size` and total selling square
  footage, the product should approximate the reported square footage. A large
  miss usually means the store count is at the wrong hierarchy level.
- **Year-over-year fleet change vs. new-store capex.** A retailer reporting
  `Capital Expenditures for New Stores` that grew while your openings row fell to
  near zero is a signal your openings are wrong.
- **Sibling-banner plausibility.** A banner whose count moves 10× in one year is
  an artifact, not growth.

### 3.14 — Indentation & styling

- **Indent map — real cell indents, never leading spaces.** Every level below is
  applied with the cell's actual indent property (`Alignment(indent=n)`, Excel's
  **Home → Increase Indent** / `Alt, H, 6`) per
  `../../../../_common/revelata-excel-styling-rules.md`; **never** pad the label
  string with spaces, and preserve each cell's existing `horizontal` / `vertical`
  alignment when setting `indent=n`.
  - `Location Build` section header: **indent 1**, **bold + underlined**, label only (no data).
  - Banner header: **indent 2**, **bold + underlined**.
  - `Company-Operated` / `Franchised & Licensed`: **indent 3**, **bold + underlined**.
  - Line items (BOP, openings, closures, `Other`, EOP rows): **indent 4**.
  - `Total — all banners`: **indent 2**, **bold + underlined** (a sub-header); its
    lines (the consolidated flow rows where laid, and the three EOP lines):
    **indent 3**.

  The line that closes each ownership roll (`EOP Balance`, `Franchised & Licensed EOP
  Balance`) and `Total System EOP Balance` are totals: **bold with the SUM-BAR** — a
  single thin top border across the data columns only. No bottom border on the row
  above, never a double line.
- **Sum bars run across the data columns only — never the row-header column.** Every sum
  bar in this build — the single thin top border on the line that closes each ownership
  roll and on `Total System EOP Balance` — is applied **only to the value cells** — the
  annual and quarterly data columns, **Col E onward**. **Never** border **Col C** (the
  row-header / label column), and never Col A, Col B, or Col D. The bar starts at the
  first data column and stops at the last one, so it sits under the numbers it totals
  and does not run beneath the label text. If a spacer column separates the annual block
  from the quarterly block, leave that spacer **unbordered** too — the bar breaks across
  the gap rather than running through it.

  ```python
  # right — the rule spans value cells only
  for col in range(first_data_col, last_data_col + 1):
      if col == spacer_col:
          continue
      ws.cell(row=total_row, column=col).border = Border(top=Side(style="thin"))

  # wrong — starting at the label column draws the bar under the row header
  for col in range(3, last_data_col + 1):
      ...
  ```

  Same loop for every `… EOP Balance` line that closes an ownership roll.
- **deepKPI input** cells: pale-green fill, dark-blue hyperlinked value. **10-K
  override** cells (used when the deepKPI series is scaled, cross-tagged, or
  missing): distinct fill (e.g. light gold) + a cell comment citing the 10-K
  store-activity table, and one matching Notes line: *"Revenue: <row> FY<n> is
  taken from the 10-K store-activity table; the database series was <scaled /
  mis-tagged / missing>."* **Formula cells** (BOP,
  `Other` plug, EOP subtotals, Total block): black font, no fill.
- The `Other` plug carries a cell comment stating its definition
  (`= EOP − BOP − SUM(flows)`) and what it captures (banner conversions,
  acquisitions/divestitures, franchise-status transfers).
- The `Store Closures` row carries a cell comment stating the **negative-entry
  convention**, so nobody later "fixes" the sign.
- Col C display labels follow the single sheet-wide pattern in the styling rules —
  dash-separated qualifiers (`Franchise Openings — <Geography>`), spelled-out words,
  no parenthetical modifiers, no opaque banner codes.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the three layout blocks of §3.3**
  (the per-banner block, the net-flow one-liner, and the `Total — all banners` block).
  Two points are specific to this build:
  - **One family.** Every data row — BOP, openings, closures, `Net Stores Opened /
    (Closed)`, `Other`, every EOP row, and the three Total rows — is a count of stores,
    in both the historical and the projection columns (the forward drivers are counts
    too). Each is tagged `(locations)` — the tag the cost builds put on the row they
    reference from here, so the count shows the same unit wherever it appears — stored
    in ones and displayed with the contract's counts format. No row in this build is
    money, a percent, or a per-unit figure.
  - **A dash in some columns does not remove the tag.** Base-year `BOP Balance` and
    `Other`, and the geography-split EOP rows in the projection columns, are dashes in
    those cells only; the row holds values elsewhere and keeps its `(locations)` tag.
    The `Location Build` row is dashes in every column because it is a header, not a
    data row — it carries no tag.
- **Reading the layout blocks.** Each row's annotation has two columns, left to right:
  the **Col D units tag in parentheses**, written as it goes in the cell, and the note
  in **square brackets**, which opens with the row's real cell indent (`indent n;`) and
  then gives `[… deepKPI INPUT …]` / `[… deepKPI / 10-K INPUT …]` for a pulled value,
  `[… FORMULA …]` for a computed row, plus styling (`bold`, `SUM-BAR`), sign conventions
  and where the cell is blank. The `Location Build`, banner, ownership and Total header
  lines carry no tag.

### 3.15 — Pre-delivery checklist (historical roll-forward)

Run this before touching a projection column. Every item is a rule stated above;
verify with **live formulas in the workbook** (not by eye).

- [ ] Columns are the fiscal years by **ordinal** per §2 — no cell was placed by joining
      on a raw deepKPI date stamp — the calendar is stated in one Notes line
      (*"Revenue: fiscal years end on <the Saturday nearest January 31>; FY<n> is
      the year ended <month year>."*) and the ordinal mapping itself is recorded
      in `BUILD_LOG.md`.
- [ ] A single `Location Build` header row sits directly beneath `REVENUE` at **indent
      1**, bold + underlined, label-only (no data); every row this
      build wrote is nested one level deeper, with the cell's **real indent property**
      and no leading spaces in any label (§3.1).
- [ ] The banner blocks **partition** the fleet at one level of the hierarchy (§3.5):
      no consolidated, segment, banner and region series for the same stores appear
      together, and no store is counted in two blocks.
- [ ] Only stores are counted (§3.2): distribution centers, offices, relocations,
      remodels and other non-fleet series are excluded from every count and flow row.
- [ ] Every `BOP Balance` is a **live formula** equal to the prior column's
      `EOP Balance` on the same line — a reported "at Beginning of Period" series was
      used only as a cross-check, never as the input — and the base-year `BOP Balance`
      and `Other` cells are **blank (dash)**, not zero (§3.4).
- [ ] Flow rows follow the issuer's disclosure tier (§3.9): Tier 1 gross `Store
      Openings` + `Store Closures` (closures entered **negative**); Tier 2 one `Net
      Stores Opened / (Closed)` row in the same position; Tier 3 a **derived**
      `Net Change = EOP − BOP` row with the `Other` plug omitted and the fallback
      stated in the Notes line of §3.9; flows the issuer discloses only for the
      consolidated fleet sit in the Total block as inputs (§3.3). The tier itself is recorded in
      `BUILD_LOG.md`, not the Notes. No gross split was manufactured from a net
      figure.
- [ ] Every `Other` cell is the **live plug** `= EOP − BOP − SUM(flow rows)` over the
      contiguous flow rows, so each roll foots `EOP = BOP + Openings + Closures + Other`
      exactly; banner conversions net to zero at the Total block; any material `Other`
      you cannot name was traced back to the filing, not accepted (§3.4).
- [ ] Every `EOP Balance` is the **reported** period-end count (deepKPI input, or
      `= SUM(geography EOP rows)` where a geography split is reported); no EOP is
      typed in or back-solved (§3.4).
- [ ] Geography and ownership splits appear **only where the filing reports them**
      (§3.6): one grouped `Store Openings` row unless a split is reported; one
      franchise row per reported geography, in the issuer's captions; no Franchised & Licensed block
      for a banner with no such fleet.
- [ ] Every cell passed the magnitude check of §3.8 — no ×1,000 scaling, no
      cross-tagged series — and any cell taken from the 10-K store-activity table
      carries the override fill, a cell comment citing the table, and the matching
      Notes line of §3.14.
- [ ] `Company-Operated EOP Balance + Franchised & Licensed EOP Balance = Total System
      EOP Balance` in every column (no franchised row for an all-owned fleet), and `Total System EOP Balance` **ties to the
      filing's** total store count in every historical year (§3.7 step 6).
- [ ] Every data row — BOP, openings, closures or net flow, `Other`, every EOP row, the
      three Total rows — carries `(locations)` in Col D; the `Location Build`, banner,
      ownership and Total header rows carry no tag (§3.14).
- [ ] Styling per §3.14: `EOP Balance`, `Franchised & Licensed EOP Balance` and `Total
      System EOP Balance` bold with the SUM-BAR across the data columns only — no bottom
      border on the row above, never a double line, never a border on Col A–D or a
      spacer column; deepKPI inputs pale-green and hyperlinked; formula cells black with
      no fill; the `Other` plug and the `Store Closures` row carry their comments.
- [ ] After recalculation (LibreOffice / the xlsx skill's `recalc.py`), **zero formula
      errors**.

## Section 4 — Projections (forecast years)

After the **historical** roll-forward above is laid down, recalculated, and
reconciled to the filing's Total System EOP, **extend every roll-forward into the
projection window** before handing back to the router. The projection window is
the **five fiscal years after the last historical year** (`N+1 … N+5`) per the
**Model timeline** in `../../../SKILL.md` — do not redefine it here. Add these as
five more **annual** columns immediately to the right of the historical annual
block, continuing the same left → right, oldest → newest order. The store
roll-forward stays **annual** in the projection window too (openings and closures
are annual flows); do **not** add quarterly projection columns.

### 4.1 — The driver inversion (historical vs. projection)

This is the one structural difference between the two halves of each roll-forward
— it **flips which cells are inputs and which are formulas**:

- In the **historical** columns, the **EOP Balance is the reported input**
  (deepKPI / 10-K) and **Other is the closing plug formula**
  (`Other = EOP − BOP − SUM(flows)`).
- In the **projection** columns this **inverts**: **the flow rows and Other become
  the forward drivers** (assumption inputs the modeler sets), and **EOP Balance
  becomes the formula** (`EOP = BOP + SUM(flows) + Other`).
- **BOP stays a formula in both halves** — always equal to the prior period's EOP.

So in each projection column, for **every** roll (each Company-Operated roll and
each Franchised & Licensed roll, across every banner):

- **BOP Balance** — **formula**, `= prior period EOP Balance` for that same line
  (chain left → right, `=<prevCol><EOProw>`). For the first projection year
  (`N+1`), BOP equals the **last historical year `N` EOP Balance**, so projections
  pick up exactly where the actuals end with no gap.
- **Store Openings / Store Closures** — **drivers** (assumption inputs). Closures
  stay **negative**, matching the historical convention. On a **Tier 2** (net-only)
  roll there is a single `Net Stores Opened / (Closed)` driver instead of two.
- **Franchise Openings** — the driver on a franchised roll reported as one line;
  where the issuer splits franchise openings by geography, each **Franchise
  Openings — <Geography>** row is its own driver and the grouped row their sum.
- **Other (transfers, conversions, acquisitions)** — **driver** (assumption
  input), one cell per projection year. In the projection columns it is **no longer
  a plug**: it is set directly as the modeler's forward conversion /
  acquisition / franchise-transfer assumption (still can be negative). Default it
  to **0** unless there is a disclosed reason to forecast a transfer — an
  unexplained forward `Other` is an unfalsifiable fudge.
- **EOP Balance** — **formula**, `= BOP + SUM(flow rows) + Other`. Use `SUM(...)`
  over the contiguous flow rows (not bare addition) so a dash flow cell does not
  throw `#VALUE!`. Where the roll lays a `Program Closures — <Program>` row (§4.2)
  the range runs through it (`SUM(Store Openings : Program Closures)`): forward,
  the closures driver is the run-rate and the program row adds the program's
  closures on top, and the dash in a year the program does not cover drops out, so
  the roll reverts to the run-rate by itself.

**Tier 3 rolls project differently.** A roll whose historical half carries a
derived `Net Change` (`= EOP − BOP`) formula must **invert that row's behavior**
in the projection columns: `Net Change` becomes the **driver** and `EOP` becomes
`= BOP + Net Change` — `= BOP + SUM(Net Change, Program Closures)` where the roll
lays a program row (§4.2). Style the projected `Net Change` cells as drivers even
though their historical counterparts are formulas, and add one Notes line:
*"Revenue: net openings for <banner> is the forecast assumption; in history it is
the difference of reported counts."*

The geography-split **EOP rows** (`Franchised EOP — <Geography>`) are **reported
actuals that exist only in the historical columns** — there is no reported geo
split to forecast. Leave those rows as **dashes** in the projection columns and carry the projected period-end
balance only at the **Franchised & Licensed EOP Balance** total level via the
identity above (its BOP then chains off that same total). The franchise
**openings** drivers stay split by geography; only the projected EOP is carried at
the total level.

### 4.2 — Seeding `N+1` from the filing's disclosed store plan

The orchestrator's guidance table is the first source for the `N+1` openings and
closures drivers: where it carries unit development for `N+1` at this roll's scope,
seed the midpoint, red, hyperlinked to the exhibit, the comment quoting the issuer.
Where it does not, retailers routinely publish a **next-year store-growth plan** in
Item 1 or MD&A ("we plan to open approximately X new stores and close approximately
Y in fiscal 20XX"), and it is the next best seed for the first projection column;
absent both, the driver takes the latest historical year's count. Where the latest
10-K discloses a plan:

- use it for the **`N+1`** openings (and closures, where given) driver;
- keep it styled as a **driver**, not an input — it is guidance, not a reported
  actual, so it gets the red font and dashed border, **not** the pale-green input
  fill or a provenance hyperlink;
- attach a cell comment citing the filing (*"FY20XX 10-K store-growth plan:
  approximately X openings"*), and add one Notes line: *"Revenue: FY<n+1> openings
  and closures follow the company's stated plan of about <x> openings and <y>
  closings (FY<n> 10-K). A default the analyst may override."*

**A closure program.** A closure plan the filing **names**, or states as a
**cumulative total**, with an **end year**, or as a **percentage of the fleet**
(*"approximately 150 store closures under the strategy, of which 64 have been
completed, by the end of fiscal 20XX"*; *"close approximately 5% of the fleet in
fiscal 20XX"*) is a program, not the annual plan above, and is never typed into
the closures driver. It is laid as its own row on each roll it covers, `Program
Closures — <Program>`, named as the issuer names it, directly beneath the roll's
closures row (`Store Closures`, `Net Stores Opened / (Closed)` or, on a Tier-3
roll, `Net Change`), always in `(locations)` — a count, because the row sits inside
the `SUM` of the roll's flows — and
entered negative, as closures are. The row carries a value in every year the
issuer's statement covers and a dash elsewhere: in the historical columns the
year's program closures where the filing states them, as 10-K inputs (an "of
which" within the closures row, outside the plug); in the projection columns a
red driver hyperlinked to the 10-K — a cumulative total with progress enters as
the remainder (planned less completed), spread evenly over the years to the
program's end year where one is given; a total with no end year
enters in `N+1` only. **A program stated as a share of a base** (*"close
approximately 5% of the fleet"*) is a cumulative total whose count the issuer
gives as a fraction, not an annual rate. Its share is laid in its own row directly
above the count row, `Program Closures — <Program> — % of <base>`, a red input
hyperlinked to the 10-K in the year the program enters (the midpoint of a range)
and a dash elsewhere; the count row's cell in that year is `= −ROUND(<share, this
col> × <base row, year N>, 0)`, and the total is then handled as any cumulative
total above. The base row is fixed by this test, never chosen: the roll's `BOP
Balance` at `N+1` (the year-`N` count) for a share of the fleet; the roll's
geography EOP row at year `N` for a share of a geography; and where the issuer's
base spans both ownership rolls, each roll's own matching row, the same share on
each, the comment stating the split is pro rata. The closures driver (or the Tier-3 `Net Change` driver) is
then the roll's **run-rate without the program**: where the program row carries a
value in year `N`, the `N+1` cell is the formula `= <closures row, N> − <Program
Closures, N>` (for `Net Change`, `= <Net Change, N> − <Program Closures, N>`);
where the program had not begun by `N`, the seed above applies unchanged; where
it had and the filing states no figure for `N`, year `N` is a program year and
the seed references the latest year before the program, the comment naming it.
Later years reference `N+1` as always; the program ends on the sheet when its row
turns to dashes, and the roll reverts to the run-rate through the `SUM` in `EOP`
(§4.1). The driver cell's comment carries the arithmetic (*"FY20XX 10-K: about
150 planned, 64 completed, 86 remaining over two years"*); the share row's comment
quotes the statement and names the row the share is applied to; one Notes line: *"Revenue: FY<n+1> closings add the company's stated
program of about <x> closings (<y> completed by FY<n>) to the roll's run-rate. A
default the analyst may override."*

`N+2 … N+5` have no disclosed plan behind them beyond a program's stated years and
are the modeler's assumptions.

### 4.3 — Drivers are the only projection inputs; everything else drags across

The **only** cells you type values into in the projection columns are each roll's
**flow row(s)**, its **Other** row and, where laid, its **Program Closures** row (or, for a share-stated program, the share row above it, the count row being a formula). Every other projection cell is a **formula
dragged across** from the roll-forward identity:

- **BOP** from the prior column's EOP;
- **EOP** from the current column's `BOP + SUM(flows) + Other`;
- the consolidated **Total — all banners** block continues its existing sum
  formulas across the projection columns (`Company-Operated EOP Balance = Σ each
  banner's Company-Operated EOP`, `Franchised & Licensed EOP Balance = Σ each
  banner's Franchised & Licensed EOP`, `Total System EOP Balance = Company-Operated
  + Franchised & Licensed`). **No drivers appear in the Total block**: forward it is
  formula-only, and the consolidated flow rows it carries when flows are disclosed
  only for the whole fleet (§3.3) are history-only inputs, dashes in the projection
  columns.

### 4.4 — One independent set of drivers per roll-forward

Every distinct roll-forward block carries **its own** flow + Other drivers —
drivers are **never shared** across rolls:

- **Multi-banner parent.** If parent A owns banners B and C, then B and C each
  have their own store roll-forward (per the §3.3 layout), so B and C
  each get their **own** flow + Other driver set.
- **Banner × region.** Where the block level is banner × region (Gap North America
  vs. Gap Asia), each region block is its **own** roll-forward with its **own**
  driver set — a shared banner name does not merge them.
- **Company-operated vs. franchised within one banner.** Per this skill, a
  banner's Company-Operated roll and Franchised & Licensed roll are **each their
  own roll-forward**, so each gets its **own** driver set.
- Therefore the **number of projection driver sets = the number of ownership rolls
  across all blocks.** For the Gap example that is, e.g., Old Navy North America,
  Gap North America, Gap Asia, Banana Republic North America, Banana Republic Asia,
  Athleta North America, and the parent-level Franchised & Licensed roll — each
  with its own flow + Other drivers, set independently.

### 4.5 — Driver (assumption) cell styling

Mark **every** projection driver cell so it reads as a forward assumption —
visually distinct from both the formula cells and the historical deepKPI input
cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **Dashed box border on all four sides** of the cell (e.g. openpyxl
  `Side(border_style="dashed")` applied to `left`, `right`, `top`, `bottom`).
- **No pale-green fill and no hyperlink** — projection drivers are assumptions, not
  deepKPI-sourced actuals, so they do **not** receive the pale-green input fill or
  the provenance hyperlink reserved for historical input cells. This holds even for
  an `N+1` driver seeded from the filing's disclosed store plan.
- **Formula** cells in the projection columns (BOP, EOP Balance, the Total block)
  keep the standard formula styling — **black** font, no fill, no dashed border —
  identical to their historical-column formula styling.

### 4.6 — Checks (projection)

- By construction each projected roll **foots**
  (`EOP = BOP + SUM(flows) + Other`); recalculate (LibreOffice / the xlsx skill's
  `recalc.py`) and confirm **zero formula errors**.
- Confirm **`N+1` BOP equals `N` EOP** for every line — the projection joins the
  actuals with no gap or discontinuity.
- Confirm the consolidated Total block's projected **Total System EOP Balance**
  still equals **Company-Operated EOP + Franchised & Licensed EOP** in every
  projection year, and that each banner's projected EOPs sum into it.
- Confirm no projected EOP goes **negative** and no roll shrinks faster than its
  own closures driver allows — a negative fleet is a sign the drivers were entered
  with the wrong sign.

## Section 5 — Final check — sub-banner store counts reconcile to the total

Before handing back, run one last reconciliation specifically on the store counts
sourced from **SEC Filing Markdowns**:

- **Verify every sub-banner (banner / chain / region) count is completely
  accurate.** For each block, re-read the store counts taken from the filing
  markdown and confirm each one matches that fiscal year's 10-K store-activity /
  period-end count exactly — no transcription, scaling, geography-split, or
  hierarchy-level errors per banner.
- **Confirm the parts sum to the whole.** The total of all the individual store
  counts listed across every sub-banner block in the build **must equal** the
  company's reported total store count for that year. Sum each banner's
  Company-Operated EOP + Franchised & Licensed EOP across all blocks and confirm it
  ties to the consolidated **Total System EOP Balance**, and that this total in turn
  matches the total store count reported in the filing. Do this for **every** column
  (each historical year). If the sub-banner counts do not add up to the reported
  total, the build is wrong — fix the offending banner cell(s) before proceeding,
  do not hand back a build whose parts don't foot to the whole.
- **This check is where retail builds fail most often**, because the hierarchy
  makes a plausible-looking partition easy to assemble and the labeled "segment
  totals" are not reliable (see §3.12: a 145-store gap that looks like
  nothing until you foot it). Treat a gap as a missing banner to find, never as a
  rounding difference to absorb into `Other`.
- **Confirm no double-count.** The complement of the gap test: no store may appear
  in two blocks. A count that ties to the total *and* includes a segment-level
  series alongside its own chains would over-foot — so check that your blocks
  partition the fleet, not merely that they reach the right sum.
- **Confirm the `Location Build` header and its nesting.** A single `Location Build`
  row exists directly beneath the `REVENUE` header at **indent 1**, bold +
  underlined, with no data in the period columns — and every row this build wrote
  sits **beneath it at a deeper indent** (banner 2, ownership roll 3, line items 4,
  `Total — all banners` 2 / 3). Confirm each indent is the cell's **real indent
  property** and that **no** label string carries leading spaces.
- **Confirm no sum bar bleeds into the label column.** Walk every row that carries a
  sum bar and check that **Col C has no border**
  (and neither do Col A / B / D, or any spacer column) — the rule must exist only on
  the data cells it totals.

## Section 6 — Hand back to the router

Once the store roll-forward is laid down, recalculated, and reconciled to the
filing's Total System EOP, hand control back to the retail router
(`../retail.md`). Report to it:

- the **block level** you used (banner, banner × region, or segment),
- the **flow-disclosure tier** (1 gross / 2 net / 3 levels-only) and, if Tier 3,
  that an opening-vintage cohort is not supportable,
- whether a **Franchised & Licensed** roll exists and at what level,
- any cells taken as **10-K overrides** because the deepKPI series was corrupted.

The router will then evaluate the shared KPI inventory and dispatch to exactly one
of the revenue sub-builds (`comparableStoresBuild/`, `unitsBuild/`, `sqftBuild/`,
or `other/`), which will reference these store counts as needed. Recording the
gate as **PASSED** is the router's job, not this build's — but it is only true
because this build ran.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the
  chain. Pull specific series via `search_kpis` against that inventory.
- This build writes **only** the store roll-forward block(s); the revenue lines
  themselves are the downstream sub-build's responsibility, and **square footage is
  `sqftBuild/`'s**, not this build's.
- For multi-banner parents, build one block per banner (or banner × region where
  that is the reporting level) and then a consolidated Total block; for a
  single-banner retailer, the Total block still appears (it just reduces to the one
  banner's EOPs).
- Record in the workbook Notes, one line per fact, each written as `Revenue:
  <fact>` in an analyst's words (no section numbers, tier names or skill
  vocabulary): the fiscal calendar (*"Revenue: fiscal years end on <the Saturday
  nearest January 31>; FY<n> is the year ended <month year>."*); every 10-K
  override cell and why (*"Revenue: <row> FY<n> is taken from the 10-K
  store-activity table; the database series was <scaled / mis-tagged /
  missing>."*); a franchised fleet reported only at parent level (*"Revenue: the
  franchised fleet is reported only in total, so it is carried as one block at the
  company level, not per banner."*); and any roll with no disclosed flows
  (*"Revenue: <banner> openings and closures are not disclosed; the roll carries
  the period-end counts and their net change."*), or the §3.9 line for flows
  disclosed only for the consolidated fleet.
- Record in `BUILD_LOG.md` (the stage's hand-back report carries the same): the
  flow-disclosure tier of each roll, the ordinal column mapping adopted and the
  fact that no date-stamp join was used, and every series searched and set aside.
