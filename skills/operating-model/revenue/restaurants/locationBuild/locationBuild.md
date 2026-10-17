---
name: revenue-restaurants-location-build
description: >
  Location (restaurant unit) roll-forward build for restaurant companies in the
  operating-model workbook. Invoked by the restaurant router
  (`revenue/restaurants/restaurants.md`) BEFORE it routes to a revenue sub-build,
  whenever the shared KPI inventory contains a **total location count** KPI for
  the company. Receives the resolved `company_id`, official company name,
  workbook path, and the shared KPI inventory; lays out a per-concept restaurant
  unit roll-forward (Locations, Openings, Closures) beneath the `REVENUE`
  ALL-CAPS header — one block per restaurant concept / brand for multi-brand
  parents, plus a consolidated Total block. Pulls series via `search_kpis`
  against the shared inventory; format per
  ../../../../_common/revelata-excel-styling-rules.md (one row per series, derived
  cells as live formulas) EXCEPT for time scope and column ordering, which this
  build overrides (see §1, "Time scope and column ordering"). Produces the unit
  counts that any downstream revenue sub-build (`comparableStoresBuild/`,
  `comparableSalesGrowthBuild/`, `revenuePerRestaurantBuild/`, `other/`) can
  reference.
---

# revenue — restaurants — location build (unit roll-forward)

This is the **location roll-forward** build for restaurant companies. It is
invoked by the restaurant router (`../restaurants.md`) **before** the router
dispatches to a revenue sub-build, whenever the shared KPI inventory contains a
**total location count** KPI for the company. Its job is to lay down the
restaurant unit count roll-forward (Locations, Openings, Closures) so that
whichever revenue sub-build runs next — `comparableStoresBuild/`,
`comparableSalesGrowthBuild/`, `revenuePerRestaurantBuild/`, or `other/` — can
reference these unit counts.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, and the router's note that a **total location count KPI is
present** in the inventory.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
`../../../../_common/revelata-excel-units-and-scale.md` (see §2.7) and build with the **xlsx** skill. All conventions there apply here — one row per
distinct series, deepKPI-sourced values as pale-green hyperlinked input cells,
and **every** total / derived cell as a live `=` formula (never a hardcoded
number) — **except** for the **time scope** and **column ordering**, which this
build overrides per §1 below.

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
- **The unit-count build is ANNUAL.** It is built as a roll-forward driven by
  **annual unit activity** (openings), which the 10-K reports **only annually** —
  not by quarter. So this build uses **annual columns only** (one per fiscal
  year, oldest → newest, left → right). Do not add quarterly columns to the unit
  roll-forward; a quarterly roll-forward is not possible because the opening
  flows are not reported quarterly. The whole model is annual — the orchestrator's
  **Model timeline** defines only fiscal-year columns, and no section lays
  quarterly columns; where an annual value must be summed from quarters, the
  quarters appear as hidden supporting rows under it, never as columns.
- **Never silently substitute data.** If a deepKPI series for a specific cell is
  a clear data-quality artifact (order-of-magnitude scaling or tagging error), do
  not transcribe it. Prefer a clean alternate deepKPI series; if none exists,
  take the value from the company's 10-K "Restaurant Unit Activity" table, mark
  that cell distinctly (see §2.7), and add one Notes line: `Revenue: <row> FY<n>
  is taken from the 10-K unit-activity table; the database series was <scaled /
  mis-tagged / missing>.`

## Section 2 — Locations: restaurant unit roll-forward

The unit-count build is laid out as a **per-concept roll-forward**, not a flat
list of period-end counts. The source of truth is the 10-K **"Restaurant Unit
Activity"** table (a beginning balance, the period's openings, and an ending
balance), plus the period-end **company vs. franchise by concept** table beneath
it. Build one roll-forward block **per restaurant concept / brand** (e.g. Texas
Roadhouse, Bubba's 33, Jaggers), then a consolidated **Total** block.

### 2.1 — Per-concept block layout

For **each concept**, lay out a Company-Operated roll and (only if the concept is
franchised) a Franchised roll:

```
<Concept>                                                      [concept header: bold + underlined, indent 0]
  Company-Operated                                             [ownership header: bold + underlined, indent 1]
    BOP Balance                                   (locations)  [FORMULA = prior FY EOP Balance; blank (dash) in the base year]
    Company Openings — <Geography>                (locations)  [deepKPI INPUT; one row per geography the filing reports, in its captions — ONLY where it splits company openings — §2.3]
    Company Openings — <Geography 2>              (locations)  [deepKPI INPUT; same condition]
    Company Openings                              (locations)  [deepKPI INPUT where reported as one line; FORMULA = SUM(geography rows) where split — §2.3]
    Company Closures — <Geography>                (locations)  [deepKPI / 10-K INPUT; entered NEGATIVE; one row per geography the filing reports — ONLY where it splits company closures — §2.3]
    Company Closures — <Geography 2>              (locations)  [deepKPI / 10-K INPUT; same condition]
    Company Closures                              (locations)  [deepKPI / 10-K INPUT, entered NEGATIVE, where the issuer discloses company closures; FORMULA = SUM(geography rows) where split; where closures are not disclosed the row is `Company Net Closures (implied)` — §2.5]
    Program Closures — <Program> — % of <base>    (% of <base>)  [ONLY where the filing states the program as a share of a base — §3.1; the share, a red INPUT hyperlinked to the 10-K in the year the program enters; dash elsewhere; sits directly above the count row]
    Program Closures — <Program>                  (locations)  [ONLY where the filing discloses a closure program on this roll — §3.1; always a count; entered NEGATIVE; 10-K INPUT in history where the issuer states the year's program closures (an "of which" within Company Closures, outside the identity); forward a red driver hyperlinked to the 10-K for a program stated as a count, or FORMULA = −ROUND(<share> × <base row, year N>, 0) for one stated as a share; dash elsewhere]
    Closures — % of Company BOP Balance           (% of Company BOP Balance)  [FORMULA = Company Closures ÷ BOP Balance; blank (dash) in the base year; projection driver — §3.1; italic]
    Net Franchise Transfers                       (locations)  [deepKPI / 10-K INPUT; signed, + = units the company fleet gains from franchisees; ONLY where the issuer discloses transfers — §2.5]
    Other                                         (locations)  [FORMULA plug = EOP − BOP − SUM(Company Openings, Company Closures, Net Franchise Transfers); blank (dash) in the base year; ONLY when Company Closures is an input — §2.2]
    Company EOP — <Geography>                     (locations)  [deepKPI INPUT; one row per reported geography — ONLY where the filing splits the company count — §2.3]
    Company EOP — <Geography 2>                   (locations)  [deepKPI INPUT; same condition]
    EOP Balance                                   (locations)  [deepKPI INPUT — reported period-end count, or FORMULA = SUM(geography EOP rows) where split; bold, SUM-BAR]
  Franchised                                                   [ownership header: bold + underlined, indent 1; OMIT entirely if the concept has no franchise ops]
    BOP Balance                                   (locations)  [FORMULA = prior FY Franchised EOP Balance]
    Franchise Openings — <Geography>              (locations)  [deepKPI INPUT; one row per geography the filing reports, in its captions — ONLY where it splits franchise openings — §2.3]
    Franchise Openings — <Geography 2>            (locations)  [deepKPI INPUT; same condition]
    Franchise Openings                            (locations)  [deepKPI INPUT where reported as one line; FORMULA = SUM(geography rows) where split — §2.3]
    Franchise Closures — <Geography>              (locations)  [deepKPI / 10-K INPUT; entered NEGATIVE; one row per geography the filing reports — ONLY where it splits franchise closures — §2.3]
    Franchise Closures — <Geography 2>            (locations)  [deepKPI / 10-K INPUT; same condition]
    Franchise Closures                            (locations)  [deepKPI / 10-K INPUT, entered NEGATIVE, where the issuer discloses franchise closures; FORMULA = SUM(geography rows) where split; where not disclosed the row is `Franchise Net Closures (implied)` — §2.5]
    Program Closures — <Program> — % of <base>    (% of <base>)  [ONLY where the filing states the program as a share of a base — §3.1; same shape as the company roll's row]
    Program Closures — <Program>                  (locations)  [ONLY where the filing discloses a closure program on this roll — §3.1; same shape as the company roll's row, its own values]
    Closures — % of Franchised BOP Balance        (% of Franchised BOP Balance)  [FORMULA = Franchise Closures ÷ BOP Balance; blank (dash) in the base year; projection driver — §3.1; italic]
    Net Franchise Transfers                       (locations)  [FORMULA = −(the company roll's Net Franchise Transfers, same concept, same column); never an input; laid only when the company roll lays it — §2.2]
    Other                                         (locations)  [FORMULA plug = Franchised EOP Balance − BOP − SUM(Franchise Openings, Franchise Closures, Net Franchise Transfers); blank (dash) in the base year; ONLY when Franchise Closures is an input — §2.2]
    Franchised EOP — <Geography>                  (locations)  [deepKPI INPUT; one row per reported geography — §2.3]
    Franchised EOP — <Geography 2>                (locations)  [deepKPI INPUT]
    Franchised EOP Balance                        (locations)  [FORMULA = SUM(geography EOP rows), or the reported total; bold, SUM-BAR]
```

The row order makes the identity **`BOP + Openings + Closures + Transfers + Other =
EOP`** read top-to-bottom within each ownership roll. Openings and closures are the
issuer's reported flows, transfers the units that moved between the two rolls, and
`Other` the residual; `EOP Balance` is the reported period-end count (an input, or a
sum of the reported geography splits). The two rolls are separate roll-forwards: each
has its own closures row, its own rate row and its own `Other`, sourced and seeded on
its own, and the only cell that links them is `Net Franchise Transfers`, entered on the
company roll and mirrored by formula on the franchised roll (§2.2).

**Where the issuer discloses no closures for a roll** (neither a deepKPI series nor a
10-K unit-activity line, at any level — §2.5), that roll's closures row is laid as
**`Company Net Closures (implied)`** / **`Franchise Net Closures (implied)`**, a formula
`= EOP − BOP − Openings − Net Franchise Transfers` (the transfers term only where that
row is laid), and the roll has **no `Other` row** (it would be identically zero). The
rate row sits beneath it as usual. The cell comment and one Notes line state that the
figure is implied from the reported counts and, where transfers are not disclosed
either, that it is net of them. The two rolls decide this independently: an issuer
that discloses company closures but not franchise closures has an input row on the
company roll and an implied row on the franchised roll.

Then a consolidated total:

```
Total — all concepts                                           [bold + underlined sub-header]
  Company-Operated EOP Balance                    (locations)  [FORMULA = sum of each concept's Company EOP]
  Franchised EOP Balance                          (locations)  [FORMULA = sum of each concept's Franchised EOP]
  Total System EOP Balance                        (locations)  [FORMULA = Company + Franchised; bold, SUM-BAR]
```

**Row table** (the rows above, as the Step 5 audit reads them; `Lays when` per
`../../../SKILL.md`; a per-concept row is required at least once):

| Row (Col C label) | Lays when | Units (Col D) | Cell |
|---|---|---|---|
| `BOP Balance` | | `(locations)` | `= prior FY EOP Balance`; dash in the base year |
| `Company Openings — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where it splits company openings; `Company Openings` is then their sum (§2.3) |
| `Company Openings` | | `(locations)` | deepKPI input where reported as one line; `= SUM(geography rows)` where split (§2.3) |
| `Company Closures — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where it splits company closures; `Company Closures` is then their sum (§2.3) |
| `Company Closures` / `Company Net Closures (implied)` | | `(locations)` | entered negative. Input (deepKPI / 10-K) where the issuer discloses company closures, `= SUM(geography rows)` where split; else the implied formula `= EOP − BOP − Company Openings − Net Franchise Transfers` (§2.5). Forward `= ROUND(rate × BOP, 0)` (§3.1) |
| `Program Closures — <Program> — % of <base>` | DATA_DEPENDENT | `(% of <base>)` — `<base>` the issuer's words for its base (`U.S. restaurants`, `the fleet`) | where the filing states the program's size as a share of a base (§3.1): the share, a red input hyperlinked to the 10-K, in the year the program enters only; dash elsewhere. Directly above the count row. Its comment quotes the statement, names the row the share is applied to and, where the issuer's base spans both rolls, says the split is pro rata |
| `Program Closures — <Program>` | DATA_DEPENDENT | `(locations)` | where the filing discloses a closure program on this roll (§3.1), named as the issuer names it: the program's closures by year, negative, always a count. 10-K input in the historical years the issuer states a figure for (an "of which" within the closures row, outside the identity). Forward, for a program stated as a count: a red driver hyperlinked to the 10-K in each projection year the program covers; for one stated as a share: `= −ROUND(<share row, this col> × <base row, year N>, 0)` in the year the program enters, the base row per §3.1's test; dash elsewhere. One row per roll the program covers |
| `Closures — % of Company BOP Balance` | | `(% of Company BOP Balance)` | `= Company Closures ÷ BOP Balance`; red driver forward |
| `Net Franchise Transfers` | DATA_DEPENDENT | `(locations)` | where the issuer discloses transfers. Company roll: signed input, + = units gained from franchisees; franchised roll: `= −<company roll cell, same concept, same column>` (§2.2). Forward: driver on the company roll, default 0; the franchised cell stays the formula |
| `Other` | DATA_DEPENDENT | `(locations)` | the residual plug `= EOP − BOP − SUM(openings, closures, transfers)` in history, laid only on a roll whose closures are an input; driver, default 0, forward |
| `Company EOP — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where it splits the company count; `EOP Balance` is then their sum (§2.3) |
| `EOP Balance` | | `(locations)` | deepKPI input, reported period-end count, or `= SUM(geography EOP rows)` where split |
| `Franchise Openings — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where it splits franchise openings; `Franchise Openings` is then their sum (§2.3) |
| `Franchise Openings` | DATA_DEPENDENT | `(locations)` | on every franchised roll: deepKPI input where reported as one line; `= SUM(geography rows)` where split (§2.3) |
| `Franchise Closures — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where it splits franchise closures; `Franchise Closures` is then their sum (§2.3) |
| `Franchise Closures` / `Franchise Net Closures (implied)` | DATA_DEPENDENT | `(locations)` | on every franchised roll, as the company roll's closures row: input where the issuer discloses franchise closures, else implied `= Franchised EOP Balance − BOP − Franchise Openings − Net Franchise Transfers` |
| `Closures — % of Franchised BOP Balance` | DATA_DEPENDENT | `(% of Franchised BOP Balance)` | on every franchised roll: `= Franchise Closures ÷ BOP Balance`; red driver forward, seeded from this roll's own history |
| `Franchised EOP — <Geography>` | DATA_DEPENDENT | `(locations)` | one row per geography the issuer reports, where it splits the franchised fleet |
| `Franchised EOP Balance` | ALWAYS_DASHES_OK | `(locations)` | `= SUM(geography EOP rows)`, or the reported total; zeros for an all-owned fleet |
| `Company-Operated EOP Balance` | | `(locations)` | Total block: `= Σ each concept's Company EOP` — contract row |
| `Total System EOP Balance` | | `(locations)` | Total block: `= Company-Operated + Franchised`; SUM-BAR |

**Keys.** Each concept's `EOP Balance` is keyed `coeop_<brand>` (the brand's name as
a slug) and the Total block's `Company-Operated EOP Balance` is keyed `coeop_total`:
the contract-row keys of `../../../SKILL.md`, which the cost build, the NWC build
and the revenue sub-builds reference.

### 2.2 — Roll-forward mechanics

Each ownership roll obeys the identity **`EOP = BOP + Openings + Closures + Transfers +
Other`**, with each term a row (the transfers and `Other` rows only where laid, §2.1).
Build the rows so this holds as live formulas:

- **BOP Balance** of a year is a **live formula** equal to the **prior year's EOP
  Balance** for that same line (chain columns left → right; e.g. `=<prevCol><EOProw>`).
  The earliest / base year has no prior column, so its **BOP is blank (dash)**.
- **Openings** rows are **deepKPI input flows** for the fiscal year (whole-unit counts).
- **Closures** rows (`Company Closures`, `Franchise Closures`) are the issuer's reported
  closures for that roll's fleet, **entered negative** so the flow rows add up (put a
  cell comment on each closures row stating the sign convention), sourced per §2.5
  for that roll alone: the company roll from the company-operated closures series or
  the 10-K table's company column, the franchised roll from the franchised series or
  column, never one from the other and never either from a system-wide series. Where a
  roll's closures are not disclosed, its row is the implied formula of §2.1.
- **Net Franchise Transfers** is the net count of units that moved between the two
  rolls of a concept in the year — the company **buying** franchised units (positive on
  the company roll) and **selling or refranchising** company units (negative), as the
  issuer reports it (a `Net purchased from (sold to) franchisees` line, or acquired
  less sold). It is laid only where the issuer discloses it. **The company roll holds
  the input; the franchised roll's cell is `= −<company roll cell>`** for the same
  concept and column, so a unit that leaves one roll enters the other and the system
  total is invariant by construction. Franchisee-to-franchisee sales touch no roll and
  are not transfers.
- **Other** is the **residual plug**, a **live formula** computed every non-base year
  as **`Other = EOP − BOP − SUM(Openings, Closures, Net Franchise Transfers)`** — the
  terms as separate arguments (never a contiguous range: the rate row sits inside the
  block), the transfers term only where that row is laid. It is laid only on a roll
  whose closures are an input. With openings, closures and transfers all reported it
  is **expected to be zero or a unit or two of timing**; a material `Other` you cannot
  name is a transcription error or a transfer the issuer disclosed and you did not
  lay — go back to the filing before proceeding. **Blank (dash) in the base year.**
- **Closures — % of Company BOP Balance** and **Closures — % of Franchised BOP
  Balance** are each roll's **rate row**: a derived formula in the historical columns,
  `= that roll's Closures ÷ BOP Balance` (blank in the base year) — the closure rate
  on that roll's opening units — and the roll's **closures driver** in the projection
  columns (§3.1). The same shape as every `YoY %` driver in the revenue builds:
  derived in history, red driver forward, and referenced by the projected closures
  formula. It is not a memo row. Each roll's rate is its own: the franchised rate is
  never seeded from the company rate or vice versa.
- **Program Closures — <Program>** (only where the filing discloses a closure
  program on this roll, §3.1) sits directly beneath the roll's closures row, always
  a count; a program the filing states as a share of a base carries that share in
  its own row directly above, `Program Closures — <Program> — % of <base>`, and the
  count row computes from it (§3.1). In the
  historical columns it carries the issuer's own count of the year's closures under
  the program, where the filing states one, as a 10-K input: an "of which" within the
  closures row above, so it is **outside the identity** (`Other` subtracts the
  closures row, never this one). In the projection columns it carries the program's
  forward closures (§3.1). Each roll the program covers gets its own row with its own
  values; a program the issuer states for one fleet is laid on that roll only.
- **EOP Balance** is the **reported period-end count** — a deepKPI input, or (for a
  roll with a geography split) a formula `= SUM(geography EOP rows)`. Because `Other`
  (or the implied closures row) absorbs the residual, every roll **foots exactly**.
- Every non-input cell (BOP, the implied closures row, the franchised transfers cell,
  Other, EOP subtotals, Total block) is a live `=` formula — never a hardcoded number. After building, **recalculate** (LibreOffice /
  the xlsx skill's `recalc.py`) and confirm **zero formula errors**, then confirm
  the **Total System EOP** ties to the filing.

### 2.3 — Geography — only when reported, and as the issuer reports it

Show a geography split **only where the filing reports it**, otherwise use a single
grouped line. Where it is reported, the rows follow the issuer: **one `<Row> —
<Geography>` line per geography in the filing's unit-activity table, captioned and
ordered as that table gives them** (U.S. and International for one issuer; U.S.,
Canada and International for another; Americas, EMEA and APAC for a third). Carry
only the table's top-level split: a sub-split inside a geography (countries inside
International) stays in the filing. The grouped row (`Company Openings`, `Company
Closures`, `Franchise Openings`, `Franchise Closures`, `EOP Balance`, `Franchised EOP
Balance`) is `SUM(...)` over the geography rows, so any number of them foots. Each
flow decides its own split: an issuer may split openings by geography and report
closures as one line, or the reverse; lay what the table gives for each row. Never rename a geography to a house vocabulary, and never
drop a reported geography.

- **Company openings, closures and counts** are reported by most issuers as a single
  line per concept; then the roll carries **one grouped `Company Openings` row**, one
  grouped `Company Closures` row and the reported `EOP Balance`. Where the filing splits them by geography (Wendy's
  reports U.S. and International company restaurants and openings separately, and
  no series carries the company total), carry `Company Openings — <Geography>` and
  `Company EOP — <Geography>` rows as the inputs, with `Company Openings` and `EOP
  Balance` as their sums — the same shape as the franchised roll. Do **not** invent a split the filing does not report, and do not
  fold a reported split into one typed input: the grouped row is a formula over the
  reported rows, so the filing's figures stay visible.
- **Franchise openings, closures and franchise EOP units** follow the same rule,
  mirrored: one grouped `Franchise Openings` row, one grouped `Franchise Closures` row
  and the reported `Franchised EOP Balance` where the filing reports them as one
  line; where it splits them (most franchisors do),
  one `Franchise Openings — <Geography>` and one `Franchised EOP — <Geography>` row
  per reported geography as the inputs, with `Franchise Openings` and `Franchised
  EOP Balance` as their sums. **Never drop a reported geography** (the
  international rows are the ones most often missed).
- A concept with **no franchise operations** (e.g. Bubba's 33) gets **no Franchised
  block at all**.

### 2.4 — Generic build procedure (any restaurant)

Follow these steps in order; they reproduce the same structure for any restaurant issuer:

1. **Identify the concepts/brands.** From the shared KPI inventory (and, if needed,
   `get_company_summary` / `get_company_segments`), list every restaurant concept the
   registrant operates. A single-brand operator yields **one** concept block; a
   multi-brand parent yields **one block per brand**. Brand names appear inside the
   KPI strings (e.g. "`<Brand> company restaurant count - Annual`").
2. **Decide each concept's ownership coverage.** A concept may be company-owned only,
   franchised only, or both. Build the Company-Operated roll whenever company units are
   reported; build the Franchised roll **only** if franchise units are reported for
   that concept (otherwise omit it entirely).
3. **Map the four KPI families per concept**, pulling each with `search_kpis` against
   the shared inventory (never re-run `list_kpis`). Match on these patterns:
   - **Company EOP (period-end count):** `"<Brand> company restaurant count - Annual"`,
     or `"Number of <Brand> Restaurants at End of Period"`, or `"<Brand> restaurant
     count - company restaurants"`.
   - **Franchise EOP by geography:** `"Domestic <Brand> franchise restaurant count -
     Annual"`, `"International <Brand> franchise restaurant count - Annual"`.
   - **Company openings:** `"<Brand> company restaurant openings - Annual"`. **This
     series is frequently sparse or entirely absent in deepKPI even when the company
     fully discloses openings in its filing — do NOT conclude openings are unavailable
     from deepKPI alone. If it is incomplete or missing, source openings from the 10-K
     Item 1 development tables (see §2.5).**
   - **Franchise openings by geography:** `"<Brand> Domestic Franchise Restaurant
     Openings"`, `"<Brand> International Franchise Restaurant Openings"` (plus the
     consolidated `"Total Domestic / Total International Franchise Restaurant Openings"`
     for cross-checks). Same caveat applies: if these are sparse or missing, take them
     from the 10-K Item 1 **Franchise Development** table (see §2.5).
   - **Company closures:** `"<Brand> company restaurant closures - Annual"`,
     `"Company-owned <Brand> restaurant closures - Annual"`, `"Restaurants closed for
     <Brand> <Geography> Company-operated restaurants"`. **Franchise closures:**
     `"Restaurants closed for <Brand> <Geography> Franchised restaurants"`,
     `"Generally underperforming restaurants closed, franchisee-operated - Annual"`.
     A system-wide closures series (`"Number of Restaurants Closed During Period in
     the <Brand> System"`, `"Systemwide restaurants closed"`) is a cross-check, never
     a roll's input. Same caveat: sparse or missing in deepKPI does not mean
     undisclosed — the 10-K unit-activity table carries closures by ownership (§2.5).
   - **Transfers (franchisors):** `"Number of Restaurants Acquired from Franchisee"`,
     `"Number of Restaurants Sold to Franchisees - annual"`, `"Net restaurants sold to
     franchisees for <Brand> <Geography> Company-operated restaurants"`, or the 10-K
     table's `Net purchased from (sold to) franchisees` line (§2.5).
4. **Pick the cleanest series and validate.** Prefer annual ("- Annual") series for
   the four most recent fiscal years. For each cell, sanity-check the value against
   the series trend and against the 10-K "Restaurant Unit Activity" table. **Reject
   obvious artifacts** — order-of-magnitude scaling (e.g. a 480 reported as 480000),
   impossible jumps, or a year-end below a mid-year quarter — and instead take that
   cell from the 10-K table (mark it; see styling).
5. **Build the rolls and the Total block, then reconcile.** Confirm, for every year,
   `Company EOP + Franchise EOP = System total` and that the System total matches the
   filing's total restaurant count. Confirm each ownership roll foots and that its
   `Other`, where laid, is at or near zero. Recalculate and confirm zero formula
   errors before delivering.

### 2.5 — Sourcing openings, closures and transfers — deepKPI series first, then the 10-K tables (do this for every issuer)

Openings are a **required input** for the roll-forward (and for the downstream
comparable-stores cohort build, which partitions units by opening vintage); closures
are an input wherever the issuer discloses them, by the same two steps, and transfers
wherever a franchisor reports them. Each roll is sourced on its own: the company roll
from company-operated series and the 10-K table's company column, the franchised roll
from franchised series and the franchised column.
**Never collapse openings into a single net-change plug if the company discloses
them anywhere.** A bare net-change line (`EOP − BOP`) is a last resort, permitted
**only** after you have confirmed openings are absent from **both** deepKPI **and**
the 10-K — and if you must fall back, add one Notes line: `Revenue: openings are
not disclosed in the filings or the database; the <brand> roll carries net change
only.` The sources searched go to `BUILD_LOG.md`.

**Step A — deepKPI structured series (try first, but never stop here).** Search the
shared inventory for the openings patterns in step 3. Treat these series as
*often partial*: an issuer may have `"... Restaurant Openings - annual"` populated
for only one or two fiscal years, or not at all, while the openings are fully
disclosed in the filing. **A sparse or missing deepKPI openings series does NOT
mean openings are unavailable.** Do not infer "openings missing" from deepKPI (or
from a handful of `search_kpis` guesses) alone.

**Step B — the 10-K Item 1 development tables (authoritative; always check).** US
restaurant registrants disclose unit openings in **Item 1 (Business)** under the
**"Company Development"** and **"Franchise Development"** subsections. Each carries
a short table shaped like:

```
                          Fiscal Year Openings    Projected Openings
Company-owned restaurants
   <Brand> domestic               <n>                  <proj>
   <Brand> international           —                     —
Franchise-operated restaurants
   <Brand> domestic               <n>                  <proj>
   <Brand> international          <n>                  <proj>
   Total openings                <sum>                <range>
```

Rely on these properties:

- **Each fiscal year's 10-K reports that year's actual openings** (the "Fiscal Year
  Openings" column) plus next year's projection. To fill a build window FY(M)…FY(N)
  you must pull **each** of those years' 10-Ks — and only those years. Any
  pre-window year a revenue build needs (a cohort lookback, a base-year seed) is
  that build's own pull, made when it runs; this build does not know which
  revenue build will follow and pulls nothing for it. Use the **filing** skill
  (`list_sec_filing_markdowns` → `get_sec_filing_markdown`); do not web-search to
  avoid the call.
- **Company openings are usually a single line per concept** — the grouped
  `Company Openings` row; where the table splits them by geography, the geography
  rows of §2.3. **Franchise openings are split by geography** — carry one row per
  geography in the table.
- A **"—"** entry means **zero** openings that year — record **0** (display as a
  dash), not blank, so downstream formulas don't return `#VALUE!`.

**Finding the table in the markdown (extraction technique).** These development
tables render as **space-separated cells on a single very long line**, so a linear
read or `offset`/`limit` paging will not surface them, and a vague search will miss
them. Search the saved markdown with **targeted tokens plus a trailing capture
window** (the numbers follow the header on the same line), e.g. the regex
`Fiscal Year Openings.{0,400}` (case-insensitive, match-only). If that token does
not hit (older filings vary the wording), try, in order: `Projected Openings`,
`Company Development`, `Franchise Development`, `<Brand> domestic`,
`Total openings`. **Do not** rely on generic phrases like `"we opened"` or
`"openings and closings"` — they routinely miss the table and will lead you to the
wrong conclusion that openings aren't disclosed. If `get_sec_filing_markdown`
returns output too large to read inline, search the **saved file** directly with
these tokens rather than abandoning the pull.

**Closures — the same two steps, per roll.** Step A: the closures series for that
roll's fleet (§2.4 step 3 patterns). Step B: the 10-K **Restaurant Unit Activity** /
MD&A restaurant count table, which carries a `Closed` line per ownership column
(and per geography where the issuer splits it). A closures row is an **input only
when it is complete across the window** from one of these; a series populated for
some years and not others is not patched with blanks — take the missing years from
the table, or, if the table does not give them either, lay the roll's closures as
the implied formula of §2.1 and say so. Never fill a roll's closures from the other
roll's series or from a system-wide series: a system figure that equals the sum of
the two rolls is a cross-check, recorded in `BUILD_LOG.md`.

**Transfers — franchisors only.** Where the 10-K table carries a `Net purchased from
(sold to) franchisees` line, or deepKPI carries acquired-from and sold-to series, lay
`Net Franchise Transfers` as §2.2 describes: the net figure as the issuer's table
states it (gross acquired and sold go in the cell comment), the company roll's cell
the input, the franchised roll's cell its negative. Where the issuer discloses no
transfers, lay no transfers row; the company's `Other` (or its implied closures row)
carries them.

**Cross-check before trusting the numbers.** Sum the franchise opening rows and
confirm they equal the filing's **"Total openings"** line, and reconcile against any
deepKPI `"Total ... Franchise Restaurant Openings - annual"` value for the same
year. Sum the two rolls' closures and confirm they equal the filing's system-wide
closures (`"Restaurants closed during period"`), and confirm the two transfer cells
net to zero. Then confirm each roll foots (`BOP + Openings + Closures + Transfers +
Other = EOP`) and that **Other**, where laid, is at or near zero.

**Provenance & styling for 10-K-sourced flows.** When an openings, closures or
transfers value comes from a 10-K table rather than a deepKPI series, style the cell
as a **10-K-sourced input** (gold fill, dark-blue hyperlinked value linked to **that
fiscal year's** 10-K filing URL) and attach a cell comment like *"Source: FY20XX
10-K, Item 1, Company/Franchise Development openings table"* or *"… MD&A restaurant
count table, Closed line, company-operated column."* Add one Notes line per flow:
`Revenue: restaurant openings are taken from the 10-K development tables.`,
`Revenue: restaurant closures are taken from the 10-K restaurant count table.` The
comment keeps the table.

**Worked example — Brinker International (EAT).** deepKPI exposes clean period-end
counts and `"Company-owned <Brand> restaurant closures - Annual"`, but **no clean
annual company-openings series** (its franchise-openings series are sparse). All
openings live in each year's 10-K Item 1 tables: company-owned **Chili's domestic**
openings FY2020–FY2025 = **6, 8, 5, 14, 9, 5** (Chili's-international and
Maggiano's company openings were nil); franchise openings
(Chili's dom / Chili's intl / Maggiano's dom) FY2022–FY2025 = **2/12/0, 2/18/0,
0/20/0, 3/30/1**. The franchise rows reconcile to the filing's "Total openings"
(e.g. FY2025: 3 + 30 + 1 = 34) and to deepKPI's total-franchise-openings value. The
company roll's `Company Closures` row is the deepKPI closures series (e.g. FY2024
−23), so the company `Other` is zero; the franchised roll's closures are not a
deepKPI series and come from the 10-K table's franchised column, else that roll
carries `Franchise Net Closures (implied)`. Sourcing openings from deepKPI alone here
would have wrongly forced a net-change plug and blocked the comparable-stores cohort
build.

### 2.6 — Worked example — Texas Roadhouse (records the exact series + traps)

For Texas Roadhouse, Inc. (concepts: Texas Roadhouse, Bubba's 33, Jaggers), the
mapping that reproduces the FY2022–FY2025 build is:

- **Company EOP:** `Texas Roadhouse company restaurant count - Annual`,
  `Jaggers company restaurant count - Annual`, and (Bubba's, which has no franchise)
  `Number of Bubba's 33 Restaurants at End of Period`.
- **Franchise EOP:** `Domestic/International Texas Roadhouse franchise restaurant
  count - Annual`, `Domestic/International Jaggers franchise restaurant count - Annual`.
- **Company openings:** `Texas Roadhouse / Bubba's 33 / Jaggers company restaurant
  openings - Annual`.
- **Franchise openings:** `Texas Roadhouse International Franchise Restaurant
  Openings`, `Jaggers Domestic Franchise Restaurant Openings` (+ the two `Total …`
  series for checks).

**Data-quality traps hit on this issuer (override from the 10-K Restaurant Unit
Activity table):** the "`<Brand> company restaurant count - Annual`" series were
corrupted in the latest two fiscal years (Texas Roadhouse year-end showed 26/20 vs.
filed 608/648; Bubba's and Jaggers similar); "`Number of … Restaurants at End of
Period`" quarterly series carry ×1000 scaling errors on many periods; and
`International Texas Roadhouse franchise restaurant count - Annual` was wrong for
FY2024 (11 vs. filed 57). The openings series and the domestic franchise count series
were clean. Reconciliation target — **Total System EOP = 697 / 741 / 784 / 816**
(FY2022–FY2025), with FY2024 (784) and FY2025 (816) matching the 10-K exactly.

### 2.7 — Indentation & styling

- Concept header: `Alignment(indent=0)`, **bold + underlined**. `Company-Operated` /
  `Franchised`: `Alignment(indent=1)`, **bold + underlined**. Line items (BOP, openings,
  closures, transfers, `Other`, EOP rows): `Alignment(indent=2)`. Indent is the cell's real indent property —
  never leading spaces. The line that closes each ownership roll (`EOP Balance`, `Franchised EOP
  Balance`) and `Total System EOP Balance` are totals: **bold with the SUM-BAR** — a
  single thin top border across the data columns only, per
  `../../../../_common/revelata-excel-styling-rules.md`. No bottom border on the row
  above, never a double line.
- **deepKPI input** cells: pale-green fill, dark-blue hyperlinked value. **10-K
  override** cells (used only when the deepKPI series is corrupted): distinct fill
  (e.g. light gold) + a cell comment citing the 10-K Restaurant Unit Activity table,
  and a matching Notes line worded as the "Time scope" bullet gives it. **Formula
  cells** (BOP, an implied closures row, the franchised roll's transfers cell, the
  `Other` plug, EOP subtotals, Total block): black font, no fill.
- Each closures row carries a cell comment stating the negative-entry convention;
  `Net Franchise Transfers` one stating its sign (+ = units this roll gains) and, on
  the franchised roll, that it mirrors the company cell; the `Other` plug one stating
  its definition (`= EOP − BOP − openings − closures − transfers`) and that it is
  expected to be zero; an implied closures row one stating that it is derived from the
  reported counts.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the two layout blocks of §2.1** (the per-concept block and the `Total — all concepts` block). Two points are specific to
  this build:
  - **One family, one exception.** Every data row — BOP, openings, closures,
    transfers, `Other`, every EOP row, and the three Total rows — is a count of
    restaurant units, in both the historical and the projection columns (the forward
    openings and transfers drivers are counts too). Each is tagged `(locations)` — the
    tag the cost builds put on the row they reference from here, so the count shows
    the same unit wherever it appears — stored in ones and displayed with the
    contract's counts format. The two exceptions are the rate rows, `Closures — % of
    Company BOP Balance` and `Closures — % of Franchised BOP Balance`: a count
    divided by a count, tagged `(% of Company BOP Balance)` / `(% of Franchised BOP
    Balance)` per the contract's Rule 4, stored as a fraction, italic. No row in this
    build is money or a per-unit figure.
  - **A dash in some columns does not remove the tag.** Base-year `BOP Balance`,
    closures rate and `Other`, and the geography-split EOP rows in the projection
    columns, are dashes in those cells only; the row holds values elsewhere and keeps
    its tag.
- **Reading the layout blocks.** Each row's annotation has two columns, left to right:
  the **Col D units tag in parentheses**, written as it goes in the cell, and the note
  in **square brackets**: `[deepKPI INPUT …]` for a pulled value, `[FORMULA …]` for a
  computed row, plus styling (`bold`, `SUM-BAR`) and where the cell is blank. Concept,
  ownership and Total header lines carry no tag.

### 2.8 — Pre-delivery checklist (historical roll-forward)

Run this before touching a projection column. Every item is a rule stated above;
verify with **live formulas in the workbook** (not by eye).

- [ ] One block per concept in the §2.1 layout, a Franchised roll **only** where the
      concept reports franchised units (§2.4 step 2), and the `Total — all concepts`
      block last; one blank spacer row between blocks.
- [ ] Every `BOP Balance` cell is a **live formula** equal to the prior column's `EOP
      Balance` on the same line; the base-year `BOP Balance` and `Other` cells are
      **blank (dash)**, not zero (§2.2).
- [ ] Each roll's closures row is the issuer's reported closures for **that roll's
      fleet**, entered negative, complete across the window — or the implied formula
      with the `(implied)` label and no `Other` row (§2.1, §2.5); no roll's closures
      came from the other roll's series or a system-wide series.
- [ ] `Net Franchise Transfers`, where laid, is an input on the company roll and
      `= −<company cell>` on the franchised roll, never an input on both; the two cells
      net to zero in every column (§2.2).
- [ ] Every `Other` cell, where laid, is the **live plug** `= EOP − BOP −
      SUM(openings, closures, transfers)` as separate arguments, so each roll foots
      `EOP = BOP + Openings + Closures + Transfers + Other` exactly in every non-base
      column, and every material `Other` was traced to the filing (§2.2).
- [ ] Every `EOP Balance` is the **reported** period-end count (deepKPI input, or
      `= SUM(geography EOP rows)` where the geography split is reported); no EOP is
      typed in or back-solved (§2.2).
- [ ] Company openings and company counts are **one grouped row each** unless the
      issuer reports a geography split, in which case one `— <Geography>` row per
      reported geography, in the issuer's captions, is the input and the grouped row
      their sum (§2.3); franchise openings and counts are split the same way, only
      where reported.
- [ ] Every openings, closures, transfers and count value came from deepKPI first;
      any cell taken from the 10-K development or restaurant count tables (§2.5)
      carries the override fill, a cell comment citing the filing table, and a
      matching Notes line worded as the "Time scope" bullet gives it.
- [ ] `Company-Operated EOP Balance + Franchised EOP Balance = Total System EOP Balance`
      in every column, and `Total System EOP Balance` **ties to the filing's** total
      restaurant count in every historical year (§2.4 step 5).
- [ ] Every data row — BOP, openings, closures, transfers, `Other`, every EOP row, the
      three Total rows — carries `(locations)` in Col D; each roll's rate row
      (`Closures — % of Company BOP Balance`, `Closures — % of Franchised BOP Balance`)
      is a live `= that roll's Closures ÷ BOP Balance` formula tagged `(% of Company BOP
      Balance)` / `(% of Franchised BOP Balance)`; concept, ownership and Total header
      rows carry no tag (§2.7).
- [ ] Styling per §2.7: concept and ownership headers bold + underlined at their indent; `EOP Balance`, `Franchised
      EOP Balance` and `Total System EOP Balance` bold with the SUM-BAR across the data
      columns only — no bottom border on the row above, never a double line, never a
      border on Col A–D; deepKPI inputs pale-green and hyperlinked; formula cells black
      with no fill; each closures row, the transfers row and the `Other` plug carry
      the comments of §2.7.
- [ ] After recalculation (LibreOffice / the xlsx skill's `recalc.py`), **zero formula
      errors**.

## Section 3 — Projections (forecast years)

After the **historical** roll-forward above is laid down, recalculated, and
reconciled to the filing's Total System EOP, **extend every roll-forward into the
projection window** before handing back to the router. The projection window is the
**five fiscal years after the last historical year** (`N+1 … N+5`) per the **Model
timeline** in `../../../SKILL.md` — do not redefine it here. Add these as five more
**annual** columns immediately to the right of the historical annual block,
continuing the same left → right, oldest → newest order. The unit roll-forward stays
**annual** in the projection window too (openings are an annual flow); do **not** add
quarterly projection columns.

### 3.1 — The driver inversion (historical vs. projection)

This is the one structural difference between the two halves of each roll-forward —
it **flips which cells are inputs and which are formulas**:

- In the **historical** columns, the **EOP Balance is the reported input** (deepKPI /
  10-K), openings, closures and transfers are reported flows, and **`Other` is the
  closing plug formula** (`Other = EOP − BOP − Openings − Closures − Transfers`).
- In the **projection** columns this **inverts**: **openings, the closure rate,
  transfers and `Other` become the forward drivers** (assumption inputs the modeler
  sets), and **EOP Balance becomes the formula** (`EOP = BOP + Openings + Closures +
  Transfers + Other`).
- **BOP stays a formula in both halves** — always equal to the prior period's EOP.

So in each projection column, for **every** roll (each Company-Operated roll and each
Franchised roll, across every concept):

- **BOP Balance** — **formula**, `= prior period EOP Balance` for that same line
  (chain left → right, `=<prevCol><EOProw>`). For the first projection year (`N+1`),
  BOP equals the **last historical year `N` EOP Balance**, so projections pick up
  exactly where the actuals end with no gap.
- **Openings** — **driver** (assumption input). Company roll: the grouped
  **Company Openings** row, or, where the filing splits company openings by
  geography (§2.3), one **Company Openings — <Geography>** row per reported
  geography, with the grouped row their sum. Franchised roll: the same, mirrored —
  the grouped **Franchise Openings** row, or one **Franchise Openings —
  <Geography>** row per reported geography with the grouped row their sum. (A roll
  with one openings row therefore has its openings driver and its closure rate, plus
  a transfers driver and an `Other` driver where those rows are laid; a roll split
  into two geographies has one openings driver per geography.) Seed each openings driver by the default
  seed: the **guided** figure when the orchestrator's guidance table gives openings
  or net new units for `N+1` at this roll's scope (a system-level figure seeds the
  rolls only where the issuer splits it; otherwise it is recorded and the roll takes
  the next rung), hyperlinked to the exhibit; else the **10-K's stated development
  plan** for `N+1` where one is disclosed, cited in the comment; else the **latest
  historical year's** count. Later years reference `N+1`.
- **Closures** (`Company Closures` / `Franchise Closures`, or the implied row) — in
  the projection columns a **formula** on both rolls,
  `= ROUND(<Closures — % of … BOP Balance, this col> × <BOP Balance, this col>, 0)`
  (the rate is negative, since closures are entered negative, so the product is
  negative and the row keeps its sign),
  with the roll's **rate row as the driver** (red/dashed, one cell per projection
  year). Where the roll lays a `Program Closures — <Program>` row (below), the
  program is added on top of the rate: `= SUM(ROUND(<rate> × <BOP>, 0), <Program
  Closures, this col>)`, the program row always a count; `SUM`,
  so the dash in a year the program does not cover drops out and the roll reverts to
  the rate on its own. The `ROUND(…, 0)` keeps every projected count a whole unit, so `EOP` and
  everything that references it (the cohort partition, the per-location cost rows)
  stay whole too. Seed each roll's rate from **that roll's own history** by the
  default seed: a **guided** closures count or closure rate for `N+1` at this roll's
  scope (a count seeds `guided ÷ N EOP Balance`, hyperlinked to the exhibit); else
  the latest historical ratio, then flat — **unless year `N` itself carried a closure
  sweep** the filing describes as such on this roll. Then seed from the latest year
  without one (`N−1`, else `N−2`), as a reference to that cell, and say why in the
  cell comment; a sweep on one roll does not move the other roll's seed.
  **A closure program** — a closure plan the filing names, or states as a cumulative
  total, with an end year, or as a percentage of the fleet (*"about 150 closures
  under the plan, of which 64 are completed"*; *"close approximately 5–6% of U.S.
  restaurants in fiscal 20XX"*) — is never typed into the rate. It is laid as its own
  row on each roll it covers, `Program Closures — <Program>`, named as the issuer
  names it, directly beneath the roll's closures row, always in `(locations)` — a
  count, because the row sits inside the roll's count identity — and entered
  negative, as closures are. The row carries
  a value in every year the issuer's statement covers and a dash elsewhere: in the
  historical columns the year's program closures where the filing states them, as
  10-K inputs; in the projection columns a red driver hyperlinked to the 10-K — a
  cumulative total with progress enters as the remainder (planned less completed),
  spread evenly over the years to the program's end year where one is given; a
  total with no end year enters in `N+1` only. **A program stated as a share of a
  base** (*"5% to 6% of our total restaurants in the United States"*) is a
  cumulative total whose count the issuer gives as a fraction, not an annual rate.
  Its share is laid in its own row directly above the count row, `Program Closures
  — <Program> — % of <base>`, a red input hyperlinked to the 10-K in the year the
  program enters (the midpoint of a range) and a dash elsewhere; the count row's
  cell in that year is `= −ROUND(<share, this col> × <base row, year N>, 0)`, and the
  total is then handled as any cumulative total above. The base row is fixed by
  this test, never chosen: the roll's `BOP Balance` at `N+1` (the year-`N` count)
  for a share of the fleet; the roll's `<EOP — Geography>` row at year `N` for a
  share of a geography; and where the issuer's base spans both fleets (the system,
  or the U.S. system), each roll's own matching row, the same share on each, the
  comment stating the split is pro rata. The rate row is then
  the roll's **run-rate without the program**: where the program row carries a
  value in year `N`, the `N+1` rate is the formula `= (<Closures, N> − <Program
  Closures, N>) ÷ <BOP Balance, N>` (a share-stated program has no history, so this
  arises only for a count the issuer reports by year); where the program had not begun by `N`, the ladder
  above applies unchanged; where it had and the filing states no figure for `N`,
  year `N` is a program year and the seed references the latest year before the
  program, as for a sweep. Later years reference `N+1` as always; the program ends
  on the sheet when its row turns to dashes, and the closures formula reverts to
  the rate by itself. The driver cell's comment carries the arithmetic (*"FY20XX
  10-K: about 150 planned, 64 completed, 86 remaining over two years"*); the share
  row's comment quotes the statement and names the row the share is applied to;
  one Notes line: *"Revenue: FY<n+1> <company /
  franchised> closings add the company's stated program of about <x> closings
  (<y> completed by FY<n>) to the roll's closure rate. A default the analyst may
  override."* Scaling closures to the opening base is what lets each roll shrink with
  the system rather than by a fixed count: the company roll's `EOP Balance` is what
  the cohort partition and the per-location cost rows read, and the franchised roll's
  `Franchised EOP Balance` is what the shared franchise revenue block
  (`../franchiseRevenueBuild/franchiseRevenueBuild.md`) reads as franchised unit
  growth. A zero default would assume no restaurant ever closes; the rate is the
  conventional default and needs no question to the user.
- **Net Franchise Transfers** (where laid) — the **company roll's** cell is a
  **driver**, default 0, written with `drivers_fixed`: a disclosed `N+1` figure where
  the filing states a refranchising or acquisition program for the year (cited in
  the comment), else 0, later years referencing `N+1`. The **franchised roll's** cell
  stays the formula `= −<company cell>`, never a driver, so the two rolls move
  together in every projection column as they do in history.
- **Other** (where laid) — a **driver**, default 0 (`drivers_fixed`), one cell per
  projection year; an unexplained forward residual is an unfalsifiable fudge, and a
  known event belongs on the transfers row.
- **EOP Balance** — **formula**, `= BOP + SUM(<grouped openings>, <closures>, <Net
  Franchise Transfers>, <Other>)` with the terms as **separate arguments** (the rate
  row sits inside the block, so never a contiguous range), the last two only where
  those rows are laid. Company roll: `= Company BOP + SUM(Company Openings, Company
  Closures, Net Franchise Transfers, Other)`. Franchised roll: `= Franchised BOP +
  SUM(Franchise Openings, Franchise Closures, Net Franchise Transfers, Other)`. The
  grouped openings and closures rows are `SUM(...)` over their geography rows where
  split, so a dash in one geography does not throw `#VALUE!`.

The geography-split **EOP rows** (`Company EOP — <Geography>`, `Franchised EOP —
<Geography>`) are **reported actuals that exist only in the historical columns** — there is no
reported geo split to forecast. Leave those rows as **dashes** in the projection
columns and carry the projected period-end balance only at the **EOP Balance** /
**Franchised EOP Balance** total level via the identity above (each BOP then
chains off its own total). The **openings** drivers stay split by geography
wherever the history is; only the projected EOP is carried at the total level.

### 3.2 — Drivers are the only projection inputs; everything else drags across

The **only** cells you type values into in the projection columns are each roll's
**openings row(s)**, its **closure rate row** (`Closures — % of Company BOP Balance` /
`Closures — % of Franchised BOP Balance`), the **company roll's `Net Franchise
Transfers`** and each roll's **`Other`** where those rows are laid; the closures count
itself is a formula off the rate, and the franchised transfers cell a formula off the
company cell. Every other projection cell is a **formula dragged across** from the
roll-forward identity:

- **BOP** from the prior column's EOP;
- **EOP** from the current column's `BOP + SUM(openings, closures, transfers, Other)`;
- the consolidated **Total — all concepts** block continues its existing sum
  formulas across the projection columns (`Company-Operated EOP Balance = Σ each
  concept's Company EOP`, `Franchised EOP Balance = Σ each concept's Franchised EOP`,
  `Total System EOP Balance = Company + Franchised`). **No new drivers appear in the
  Total block** — it is formula-only in both halves.

### 3.3 — One independent set of drivers per roll-forward

Every distinct roll-forward block carries **its own** openings and closure-rate
drivers (and its own `Other` driver where laid) — drivers are **never shared** across
rolls:

- **Multi-brand parent.** If parent A owns companies B and C, then B and C each have
  their own location roll-forward (per the §2.1 layout), so B and C each
  get their **own** driver set.
- **Company-owned vs. franchised within one concept.** Per this skill, a concept's
  Company-Operated roll and Franchised roll are **each their own roll-forward**, so each
  gets its **own** driver set — Company Openings + the `Closures — % of Company BOP
  Balance` rate for the company roll; Franchise Openings (the grouped row, or one
  per reported geography) + the `Closures — % of Franchised BOP Balance` rate for the
  franchised roll, seeded from the franchised roll's own history. The one cell the
  two rolls share is `Net Franchise Transfers`: one driver, on the company roll,
  mirrored by formula on the franchised roll, because a transfer is one event seen
  from both sides.
- Therefore the **number of projection driver sets = the number of ownership rolls
  across all concepts.** For the Texas Roadhouse example that is, e.g., Texas
  Roadhouse company, Texas Roadhouse franchised, Bubba's 33 company, Jaggers company,
  and Jaggers franchised — each with its own openings and closure-rate drivers, set
  independently.

### 3.4 — Driver (assumption) cell styling

Mark **every** projection driver cell so it reads as a forward assumption — visually
distinct from both the formula cells and the historical deepKPI input cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **Dashed box border on all four sides** of the cell (e.g. openpyxl
  `Side(border_style="dashed")` applied to `left`, `right`, `top`, `bottom`).
- **No pale-green fill and no hyperlink** — projection drivers are assumptions, not
  deepKPI-sourced actuals, so they do **not** receive the pale-green input fill or the
  provenance hyperlink reserved for historical input cells.
- **Formula** cells in the projection columns (BOP, EOP Balance, the Total block)
  keep the standard formula styling — **black** font, no fill, no dashed border —
  identical to their historical-column formula styling.

### 3.5 — Checks (projection)

- By construction each projected roll **foots** (`EOP = BOP + Openings + Closures +
  Transfers + Other`); recalculate (LibreOffice / the xlsx skill's `recalc.py`) and
  confirm **zero formula errors**.
- Confirm **`N+1` BOP equals `N` EOP** for every line — the projection joins the
  actuals with no gap or discontinuity.
- Confirm every roll's projected closures equal `ROUND(rate row × BOP, 0)` (negative) in every
  projection column, that every projected count is a whole number, that the rate row
  (not the closures row) carries the driver styling, and that the two rolls' `Net
  Franchise Transfers` cells net to zero in every projection column with the driver
  styling on the company cell only.
- Confirm the consolidated Total block's projected **Total System EOP Balance** still
  equals **Company EOP + Franchised EOP** in every projection year, and that each
  concept's projected EOPs sum into it.

## Section 4 — Final check — sub-company location counts reconcile to the total

Before handing back, run one last reconciliation specifically on the location
counts sourced from **SEC Filing Markdowns**:

- **Verify every sub-company (concept / brand) count is completely accurate.**
  For each concept block, re-read the location counts taken from the filing
  markdown and confirm each one matches that fiscal year's 10-K "Restaurant Unit
  Activity" / period-end count exactly — no transcription, scaling, or
  geography-split errors per concept.
- **Confirm the parts sum to the whole.** The total of all the individual
  locations listed across every sub-company block in the build **must equal** the
  company's reported total location count for that year. Sum each concept's
  Company EOP + Franchised EOP across all concepts and confirm it ties to the
  consolidated **Total System EOP Balance**, and that this total in turn matches
  the total location count reported in the filing. Do this for **every** column
  (each historical year). If the sub-company counts do not add up to the reported
  total, the build is wrong — fix the offending concept cell(s) before proceeding,
  do not hand back a build whose parts don't foot to the whole.

## Section 5 — Hand back to the router

Once the unit roll-forward is laid down, recalculated, and reconciled to the
filing's Total System EOP, hand control back to the restaurant router
(`../restaurants.md`). The router will then evaluate the shared KPI inventory and
dispatch to exactly one of the revenue sub-builds (`comparableStoresBuild/`,
`comparableSalesGrowthBuild/`, `revenuePerRestaurantBuild/`, or `other/`), which
will reference these unit
counts as needed.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the
  chain. Pull specific series via `search_kpis` against that inventory.
- This build writes **only** the unit roll-forward block(s); the revenue lines
  themselves are the downstream sub-build's responsibility.
- For multi-brand parents, build one concept block per brand and then a
  consolidated Total block; for a single-brand operator, the Total block still
  appears (it just reduces to the one concept's EOPs).
- Record in the workbook Notes, one line per fact in the analyst's words: an implied
  closures row (*"Revenue: <brand> <company / franchised> closures are not disclosed;
  the roll carries the net change in the reported counts after openings."*), flows
  taken from a 10-K table (§2.5), and the closure program of §3.1 where laid.
  Record in `BUILD_LOG.md`, per roll: whether closures are an input or implied and
  the series or table they came from; whether transfers were laid and from where;
  and every series searched and set aside.
