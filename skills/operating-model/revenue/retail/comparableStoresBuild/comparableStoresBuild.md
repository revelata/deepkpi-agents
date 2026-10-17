---
name: revenue-retail-comparable-stores
description: >
  Comparable-stores revenue build for retail companies in the operating-model
  workbook. Invoked by the retail router (`revenue/retail/retail.md`) when the
  company reports a full comparable-store-sales KPI set (comparable-store sales
  growth %, and beginning/end-of-period net sales split between comparable and
  non-comparable cohorts, including the comparable cohort's DOLLARS; the
  underlying store roll-forward is laid down separately by
  `locationBuild/locationBuild.md` before this build runs). Receives the resolved
  `company_id`, official company name, workbook path, the shared KPI inventory,
  and the location build's hand-back (block level, flow-disclosure tier,
  franchised roll, 10-K overrides); builds the revenue model from the
  comparable-store-sales bridge beneath the `REVENUE` ALL-CAPS header (using the
  store counts already in the workbook from the location build). The revenue
  build decomposes reported total net sales into five components plus a plug:
  Net Sales from the Comparable Cohort (a recursive per-banner bridge — prior-year
  net sales per comparable store grown by comparable-store sales, times the
  comparable count), Net Sales from the Non-Comparable Cohort (blended net sales
  per store x a 0.5 partial-year factor x the non-comparable count), Franchise &
  License Revenue (if franchised/licensed), Non-Store Channel Revenue (digital,
  wholesale, membership fee income — only the channels that sit OUTSIDE the comp
  base), and Other Revenue (the plug that foots the build to reported Total
  Revenue). Pulls series via `search_kpis` from the shared inventory; format per
  ../../../../_common/revelata-excel-styling-rules.md (one row per series, derived
  cells as live formulas) EXCEPT for time scope (last 4 fiscal years), which this
  build overrides. For multi-banner parents (e.g. The Gap, Inc., TJX), it runs the
  full per-banner revenue build for each banner and then a consolidated revenue
  table that combines the banners. Sections: §1 cohort partition, §2
  comparable-cohort net sales, §3 non-comparable-cohort net sales, §4 franchise /
  license / non-store channel revenue, §5 other + total revenue + the single NOTES
  block that carries every basis statement at the bottom of the build, §6
  multi-banner parents + consolidated table, §7 worked example, §8 downstream
  handoff.
---

# revenue — retail — comparable-stores build

This is the **comparable-stores** retail revenue build. It is invoked by the
retail router (`../retail.md`) when the company reports a comparable-store-sales
dataset rich enough to bridge net sales from a beginning-of-period base,
comparable-cohort growth, and the contribution of stores not in the comparable
cohort (new stores, closures).

By the time control reaches this build, the **store roll-forward has already been
laid down** in the workbook by `../locationBuild/locationBuild.md` (the router
invokes it before routing). This build is therefore responsible only for the
**revenue** lines of the comparable-stores model and may reference the store
counts already present.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook (with the store roll-forward already laid
down), the **shared KPI inventory** from the orchestrator, the router's note of
which KPIs satisfied the comparable-stores criteria, and the **location build's
hand-back** — the block level used (banner / banner × region / segment), the
**flow-disclosure tier** (1 gross, 2 net-only, 3 levels-only), whether a
**Franchised & Licensed** roll exists and at what level, and any cells taken as
**10-K overrides**. All five of those hand-back facts change what this build can
do; read them before writing a cell.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
`../../../../_common/revelata-excel-units-and-scale.md` (see "Number format and units"
in the conventions for Sections 2 – 6) and build with the **xlsx** skill. All
conventions there apply here — one row per distinct series, deepKPI-sourced values as
pale-green hyperlinked input cells, 10-K-sourced values as gold-filled override cells,
and **every** total / derived cell as a live `=` formula (never a hardcoded number) —
**except** for the **time scope**, which this build overrides per the "Time scope"
section below.

## Aborting the build — the only exit other than completion

Reaching this build means the router's Step 2.0 scan found every necessary item
in the inventory. Two inputs can still prove **unobtainable** once the build
sources them in full — deepKPI first, then the 10-K where the section's text
sends you there: the **base-column comparable-cohort dollar seed** (§2.1
situations 1 and 2) and the **base-column comparable store count** (§2.5). A
comp reported only on the **systemwide** universe (§1.9) is a third trigger the router's criteria should have caught.

When one of them is unobtainable, **stop writing**. Do not substitute a proxy
(blended net sales, total stores, a residual dollar change). Return control to
the router with exactly this outcome and nothing else:

- **`ABORTED — <necessary item> unobtainable`**;
- the item, and what was searched for it (inventory captions tried, 10-K
  sections read);
- the sections and rows already laid by this build, so the router can drop them.

**Do not name another build.** Routing is the router's job (`../retail.md` Step
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
- **The build is ANNUAL.** Comparable-store sales growth and the cohort counts are
  reported annually, not by quarter, and the store openings that drive the cohort
  partition are annual flows. Use **annual columns only** (Col E onward, oldest →
  newest), matching the store roll-forward's columns exactly, so every revenue
  cell sits directly under the matching cohort / store cell.

> This build is authored section by section. The sections present here — §1 the
> cohort partition and §2 – §8 the revenue build (comparable-cohort net sales,
> non-comparable-cohort net sales, franchise / license / non-store channel
> revenue, other + total revenue, multi-banner parents + the consolidated table, a
> worked example, and the downstream handoff), plus the **Projections (forecast
> years)** section near the end that extends the build into `N+1 … N+5` — are the
> implemented scope. Do not build or add any new information outside the sections
> present here.

---

## Section 0 — Two retail preconditions to settle before writing any cell

Restaurants can go straight to the cohort partition. Retail cannot: two things
routinely break a retail comparable-stores build before the first formula is
typed, and both are cheap to settle up front and expensive to discover later.

### 0.1 — The retail fiscal calendar and the stamp-join trap

`../locationBuild/locationBuild.md` opens with the retail fiscal calendar for a
reason, and **the same discipline applies to every series this build pulls** —
including the ones the location build never touched (comparable-sales %, net
sales, comparable-cohort dollars, online sales, membership fee income).

Retailers are almost all on a **52/53-week fiscal calendar ending in late January
or early February**, so a company's "fiscal 2025" ends in **calendar 2026**.
deepKPI date stamps are therefore not interchangeable with calendar years, and —
critically for this build — **the stamping convention can differ from series to
series within one issuer.**

**This is not hypothetical. It is the normal case, and it straddles the two
builds.** For Dollar General, fiscal 2025 (the year ended January 30, 2026)
appears as:

| Series | deepKPI stamp for fiscal 2025 | Convention |
|---|---|---|
| `Number of New Retail Stores Opened - annual` | `2025-12-31` | calendar **placeholder** (stamp year = FY label) |
| `Number of Retail Stores Closed - annual` | `2025-12-31` | calendar placeholder |
| `Number of Retail Stores at End of Period - annual` | `2025-12-31` | calendar placeholder |
| `Consolidated same-store sales for stores open at least 13 full fiscal months` | `2026-01-30` | **actual** fiscal year-end |
| `Annual net sales from same-stores …` | `2026-01-30` | actual fiscal year-end |

The **store counts** this build multiplies and the **comp rate** it multiplies
them by are stamped **a year apart for the same fiscal year**. Join those two on
the raw date string and every comparable-cohort dollar in the model is off by one
year — silently, with no formula error and no failed foot.

For The Gap, Inc. the split runs the other way and lands inside a single fiscal
year: `Comparable Sales Change for Gap Global` stamps fiscal 2024 as `2025-01-31`
while `Online Sales - Fiscal year` stamps the same fiscal 2024 as `2025-02-01`.
`Comparable sales - Annual` carries two different values under `2022-01-29` and
`2022-01-31` — a duplicate/mis-stamped pair for one fiscal year.

**What to do, in order, before transcribing anything:**

1. **Map every series to fiscal-year ordinals, never to date strings.** For each
   series, order its stamps, anchor the **newest** stamp to the last fiscal year
   the latest 10-K reports, and walk backward. Write each value into the
   fiscal-year **column**, not the date-matched column.
2. **Re-use the location build's column mapping verbatim.** The store roll-forward
   already fixed the fiscal-year columns and reconciled the newest one to the
   filing's total store count. This build **adopts that mapping** — it does not
   re-derive one. If a revenue series will not map cleanly onto those columns,
   the series is wrong or the stamp convention differs; resolve it, do not shift
   the columns.
3. **Anchor each new revenue series against the filing.** Confirm the newest
   column's `Total Revenue` equals the net sales figure in the most recent 10-K
   income statement, and the newest comp % equals the comp % in that 10-K's KPI
   table. Two anchors, both cheap, both catch an off-by-one immediately.
4. **The 53rd week changes sales, not stores.** A 53-week fiscal year adds roughly
   one week of net sales and **is excluded from the comp calculation by most
   issuers** (Dollar General: *"Changes in same-store sales are calculated based on
   the comparable 52 calendar weeks in the current and prior years"*). That extra
   week therefore lands **outside** the comparable bridge — see §4.4.

### 0.2 — The openings gate: can this fleet support an opening-vintage cohort?

The cohort partition in §1 is built from **store openings by fiscal year**. The
location build's **flow-disclosure tier** tells you whether those openings exist:

| Tier | What the issuer discloses | Can §1 build a vintage cohort? |
|---|---|---|
| **1 — Gross** | Gross openings **and** gross closures | **Yes** — build §1 exactly as written. |
| **2 — Net only** | A single net opened/(closed) figure | **Only after** the §1.5 recovery procedure. |
| **3 — Levels only** | Period-end counts, no flow at any level | **No** — use the §1.5 Tier-3 fallback. |

**Do not skip this check and do not treat a net flow as an openings count.** On a
Tier-2 fleet the net figure is `openings + closures`; using it as `openings`
understates the non-comparable cohort by exactly the year's closures, which in
retail can be hundreds of stores (Dollar General closed **290** stores in fiscal
2025 against **589** openings — using net **299** as openings would cut the
current-year non-comparable vintage roughly in half).

§1.5 gives the full procedure for each tier. Settle the tier **before** §1.1, and
record the tier and the path taken in `BUILD_LOG.md` (the stage's hand-back
report carries the same) so the decision is auditable. The Notes block carries
only the resulting modeling facts, in analyst words (§5.5).

---

## Section 1 — Store Cohorts (Comparable vs. Non-Comparable)

This is the **first section** of the comparable-stores revenue build. It sits
**immediately beneath** the store roll-forward laid down by
`../locationBuild/locationBuild.md` and **partitions** each banner's total store
count into a **Comparable** cohort and a single **Non-Comparable** cohort (the
Non-Comparable cohort is broken down by **year of opening only** — not by internal
age sub-buckets; see §1.3). Every downstream revenue section (comparable-cohort
sales growth bridge, new-store revenue contribution) refers back to the cohort
counts produced here, so this section **must** be built before any revenue lines.

The build proceeds in four logical steps that you **must do in order**:

1. **Read the comparable-store definition from the 10-K** (§1.1). The age
   threshold `T` **and** the measurement anchor ("open at least T full fiscal
   months", "open T months before the beginning of the period", or "open
   throughout both fiscal years") together set the **effective reach `R`** (laid on the sheet as `New-store window`; `T` is laid as `Months to enter comp base`), which
   determines which fiscal years of openings are non-comparable and by what
   weight. Retail definitions also carry **four extra clauses** — remodel /
   relocation / expansion treatment, the "remains open at period end" exclusion,
   the 52-week basis, and whether **digital sales are inside the comp base** —
   each of which changes something downstream. Do not assume a default.
2. **Translate the definition into a fiscal-year partition** (§1.2 – §1.4).
   The Non-Comparable cohort is the set of store openings that fall inside a
   **trailing window** ending at the comparability measurement anchor. Under a
   uniform-monthly-openings assumption, the **current** fiscal year is always
   **fully** non-comparable, and the **boundary** fiscal year (where the window
   cuts off) is counted **fractionally** — weight `(R mod 12) / 12` of its
   openings, **not** rounded up to a full year (§1.2, §1.4). For example, a "13
   full fiscal months" rule leaves only **1/12** of the prior year's openings
   non-comparable, not the whole year. §1.4 lists the year-of-opening rows and
   weights for the common thresholds. The Non-Comparable cohort is a **single**
   group broken down by year of opening only — §1.3 explains how to collapse any
   issuer-published age sub-buckets into that single structure.
3. **Resolve the openings source against the flow-disclosure tier** (§1.5). Retail
   fleets frequently disclose only a net flow, or only period-end levels; §1.5
   gives the recovery procedure and the permitted fallbacks.
4. **Build the cohort block in the workbook**, one block per banner (§1.6 – §1.10).

### 1.1 — Read the comparable-store definition from the 10-K

The definition of a **comparable store** is **issuer-specific** and is disclosed
in the 10-K — typically in MD&A under "Key Performance Indicators", "How We
Assess the Performance of Our Business", or in the "Net Sales" discussion.
Retail vocabulary varies more than any other vertical: the same concept is filed
as *same-store sales*, *comparable store sales*, *comparable sales*, *comp
sales*, or *comparable brand sales*. **Six** parameters vary, and all six must be
extracted before any cohort row is written:

1. The **age threshold** `T` at which a store **enters** the comparable base.
   Common retail values are **12, 13, 14, 15, 18, or 24 months** (some issuers
   express it in weeks — **52 weeks ≈ 12 months**, **65 weeks ≈ 15 months** — and
   some as "open at least one full fiscal year").
2. The **measurement anchor** — one of three, and it **materially** changes the
   partition (do **not** treat them as equivalent):
   - **"open at least T full fiscal months"** / **"in operation for T months"** —
     the test is applied **at / through the period** (effectively at the period
     **end**). Example: **Dollar General** ("open at least 13 full fiscal
     months"). Effective reach **R = T**.
   - **"open for T months before the beginning of the period measured"** — applied
     at the period **start**. Measuring from the start instead of the end pushes
     the test back one full period, so the effective reach is **R = T + 12**.
   - **"open throughout both fiscal years compared"** — must be open the entire
     current and entire prior fiscal year. Effective reach **R = 24**, regardless
     of the stated `T`. Off-price and department-store issuers use this shape.
3. **Remodel / relocation / expansion treatment.** This clause is **retail-only**
   and it changes the cohort count directly. Issuers split three ways:
   - **Included** (Dollar General: *"We include stores that have been remodeled,
     expanded or relocated in our same-store sales calculation"*) → a remodel or
     relocation does **not** reset the store's clock; no adjustment, and the
     `Other` line in the store roll-forward already nets relocations to zero.
   - **Excluded while under construction / for N months after reopening** → those
     stores leave the comparable base temporarily. If the issuer reports the count
     removed, carry it in a clearly-labeled row **inside the Non-Comparable
     cohort** (see §1.6, optional `Stores Removed from Comp Base — Remodel /
     Relocation`) — adding it there subtracts it from Comparable automatically,
     since Comparable is the `EOP − Non-Comparable` plug. If the issuer does not
     report the count, let the §5 plug absorb it — **do not invent a count** —
     and the Notes line reads *"Revenue: remodeled and relocated stores are
     removed from the comparable base; the filing gives no count, so none is
     carried."*
   - **Excluded when square footage changes by more than X%** (common where an
     "expansion" materially changes the box) → treat as the excluded case above.
4. The **"remains open at the end of the reporting period"** clause. Most retail
   definitions require the store to still be open at period end (Dollar General
   states it explicitly). This means **stores closed during the year are not in
   the comparable cohort** — which the §1.6 plug (`EOP − Non-Comparable`) already
   handles correctly, because closures have left the EOP balance. Do not build
   a separate closure adjustment row.
5. The **comp-period basis** — **52 weeks vs. 53 weeks.** Most issuers compute the
   comp change on the **comparable 52 calendar weeks** in both years, so the 53rd
   week's sales are **outside** the comp rate. That extra week's net sales must
   therefore be modeled outside the comparable bridge (§4.4).
6. **Is digital / e-commerce inside the comparable base?** Many retailers include
   online sales in comparable sales; many do not; several changed their policy
   mid-decade. **This single answer decides whether §4 carries a separate digital
   line at all** (§4.2), and getting it wrong double-counts or drops several
   billion dollars of revenue. Read the sentence, do not infer it.

**Workflow:**

1. Pull the latest 10-K markdown via the **filing** skill
   (`list_sec_filing_markdowns` → `get_sec_filing_markdown`).
2. The markdown is large and these tables render as **space-separated cells on a
   single very long line**, so a linear read will miss them. Search the saved
   markdown with **targeted tokens plus a trailing capture window**, e.g.
   `same-store sales are calculated.{0,900}` or `comparable (store )?sales
   (are|include).{0,900}` (case-insensitive, match-only). If those miss, try in
   order: `Key Performance Indicators`, `How We Assess`, `We define comparable`,
   `comparable sales include`, `open at least`, `full fiscal months`,
   `13 full`, `comparable 52`.
3. Extract **six** things and **record them** — **not** as note rows inside the
   build, but as two lines in the **Notes block** at the bottom of the build
   (§5.5), in analyst words: one quoting (or closely paraphrasing) the
   definition with its filing year, and one giving the resulting framework
   formula:
   *"Revenue: comparable definition: "<quote>" (per <issuer> FY<n> 10-K)."*
   *"Revenue: comparable base = stores open at least <T> months <anchor
   wording>; new-store window <R> months; stub-year fraction <x>."*
   The six parameters are:
   - the **age threshold**,
   - the **measurement anchor**,
   - the **remodel / relocation / expansion** treatment,
   - the **"remains open at period end"** clause,
   - the **52-week basis** (and whether the window contains a 53-week year),
   - whether **digital is inside the comp base**.
4. If the filing reports comp sales on a **company-operated-stores-only** basis
   (the most common pattern — comp sales is rarely reported for a franchised or
   licensed fleet), state that the cohort universe is **company-operated stores**
   for that banner. If the issuer also reports a franchise or systemwide comp,
   the cohort is **still company-operated** and the second comp goes unused
   (§1.9). If the issuer reports comp on more than one **sales basis** inside
   its own stores (owned vs. owned-plus-licensed departments, with or without
   marketplace), record which basis each series is on in `BUILD_LOG.md` — §1.9
   picks between them, and the chosen basis is what the Notes block states.

**Example — Dollar General (FY2025 10-K, MD&A "Key Performance Indicators"):**

> "Same-store sales are calculated based upon our stores that were open at least
> 13 full fiscal months and remain open at the end of the reporting period. We
> include stores that have been remodeled, expanded or relocated in our same-store
> sales calculation. Changes in same-store sales are calculated based on the
> comparable 52 calendar weeks in the current and prior years. The method of
> calculating same-store sales varies across the retail industry. As a result, our
> calculation of same-store sales is not necessarily comparable to similarly
> titled measures reported by other companies."

So for Dollar General:

- Age threshold **T = 13 full fiscal months**.
- Measurement anchor = **"open at least T months"** → applied at the period
  **end** → **R = T = 13**.
- Remodels, expansions and relocations are **included** → **no** removal row.
- Stores must **remain open at period end** → closures are already out of EOP, so
  the `EOP − Non-Comparable` plug handles it.
- Comp is computed on the **comparable 52 calendar weeks** → a 53rd week, in a
  year that has one, sits outside the comp rate (§4.4).
- Digital: Dollar General is effectively an all-store retailer with no material
  separately-reported e-commerce channel → **no** separate digital line (§4.2).
- Universe: **company-operated stores** (Dollar General has no franchised fleet →
  §4.1's franchise line is omitted entirely).

The anchor does **not** wash out. A "13 months **open**" rule (R = 13) leaves only
**1/12** of the prior year's openings non-comparable; a "13 months **before the
beginning**" rule (R = 25) leaves the **entire** prior year plus **1/12** of the
year before that non-comparable. `T`, the anchor and the resulting **R** live as
**cells** in the §1.6 assumptions rows; record the *reasoning* — the quoted
definition and the framework formula that produced `R` — in the **Notes block**
(§5.5), as the two lines §1.1 step 3 gives, so the basis is auditable.

### 1.2 — Translate the definition into a fiscal-year partition (trailing-window model)

The Non-Comparable cohort is every store opening that falls inside a **trailing
window of `R` months** ending at the comparability measurement anchor, where `R`
is the **effective reach** from §1.1:

- `R = T` for an **"open at least T full fiscal months"** rule (test applied at
  the period **end**; e.g. Dollar General),
- `R = T + 12` for an **"open T months before the beginning of the period"** rule
  (test applied at the period **start**),
- `R = 24` for an **"open throughout both fiscal years"** rule.

Assume stores open **evenly throughout each fiscal year** (uniform monthly
openings). Then FY(N−k)'s openings sit between **12k** and **12(k+1)** months
before the anchor, and the fraction of that year captured by the `R`-month window
— i.e. the **weight** of FY(N−k) openings in the Non-Comparable cohort — is:

> **w(k) = clamp( (R − 12·k) / 12 , 0 , 1 )**   for k = 0, 1, 2, …

This single formula **replaces** any "round the boundary year up to fully
non-comparable" heuristic. It yields four cases:

- **Current year, k = 0:** `w(0) = clamp(R/12, 0, 1) = 1` (R ≥ 12 always). The
  current fiscal year's openings are **always fully non-comparable**.
- **Fully non-comparable prior years:** any FY(N−k) with `12(k+1) ≤ R` →
  `w(k) = 1`.
- **The boundary year** (exactly one): the FY(N−k\*) where `12·k* < R <
  12·(k*+1)` → `w(k*) = (R − 12·k*) / 12 = (R mod 12) / 12`. This is the
  **fractional** weight; it is the source of the "13 months → **1/12** of the
  prior year" result.
- **Comparable years:** any FY(N−k) with `12·k ≥ R` → `w(k) = 0`.

The deepest contributing year is **k\* = ceil(R/12) − 1**, so the cohort block
carries **ceil(R/12)** year-of-opening rows (k = 0 … k\*). The cohort is then:

> **Total Non-Comparable = Σ\_k  w(k) · FY(N−k) openings**, and
> **Total Comparable = EOP − Total Non-Comparable** (plug; see §1.7).

**Worked weights.** Dollar General (open ≥ 13 full fiscal months ⇒ R = 13):
w(0)=1, w(1)=(13−12)/12=**1/12**, w(2)=0 → 2 rows. A "one full year / 52 weeks"
retailer (R = 12): w(0)=1, w(1)=0 → **1 row** (current year only). A 14-month
rule (R = 14): w(0)=1, w(1)=(14−12)/12=**2/12 = 1/6** → 2 rows. An "open
throughout both fiscal years" retailer (R = 24): w(0)=1, w(1)=1 → 2 rows, both
full. An "18 months before the beginning" retailer (R = 30): w(0)=1, w(1)=1,
w(2)=(30−24)/12=**½** → 3 rows.

### 1.3 — Combine any further non-comparable sub-buckets into one cohort

Some issuers report a finer age-bucket breakdown within the non-comparable cohort
(e.g. stores open <6 months vs. 6–12 months, or a separate "new stores" vs.
"closed stores" vs. "relocated stores" split in the net-sales walk). For
consistency across **every** comparable-stores company modeled in this build,
**always collapse any such issuer-provided sub-buckets into a single
Non-Comparable cohort**. The build does **not** carry an internal age-based split
(no `<6mo` row, no `6-to-T` row, no `Subtotal — less than 6 months` row). The only
structure preserved inside Non-Comparable is the **fiscal year in which the stores
were opened** — one row per contributing year (Current Yr, Previous Yr, and, if
the threshold reaches further back, one or more older prior FYs).

**Why a single cohort.** A standard two-bucket layout (Comparable vs.
Non-Comparable) makes companies directly comparable in downstream revenue sections
regardless of how the issuer chooses to slice the non-comp pool. Retail issuer age
cuts vary in their break points and in what they fold together (some walks put
closures and relocations in with new stores), so collapsing them produces a more
portable model and avoids forcing each name into an artificial split the
disclosure may not even support.

**Combination rule when the issuer pre-splits.** If a 10-K, supplement, or
investor deck breaks the non-comparable pool into sub-buckets, **sum those
sub-buckets** into the single Non-Comparable cohort total, and then express the
breakdown by **year of opening** using the framework in §1.4. Do **not** mirror
the issuer's sub-bucket labels in the workbook.

**Multi-banner.** The same rule applies banner by banner: per banner, sum any
issuer sub-buckets into one Non-Comparable cohort and break it down by fiscal year
of opening only.

### 1.4 — Explicit weights by threshold and anchor

Apply the weight `w(k) = clamp((R − 12·k)/12, 0, 1)` from §1.2. Each
year-of-opening row holds **openings × weight**, not the whole year. The current
year is always full; **only the boundary year is fractional**. Lay down one row
for each k = 0 … ceil(R/12) − 1. **Always confirm `T` and the anchor against the
10-K (§1.1) before choosing `R` — never carry a peer retailer's threshold across.**

**"Open at least T full fiscal months" anchor (R = T)** — the dominant retail
shape:

| T (months) | R | Year-of-opening rows (weights) |
|---|---|---|
| 12 (≈52 wks, "one full year") | 12 | Current ×1 only |
| 13 | 13 | Current ×1; **Previous ×1/12** |
| 14 | 14 | Current ×1; **Previous ×2/12 (1/6)** |
| 15 (≈65 wks) | 15 | Current ×1; **Previous ×3/12 (¼)** |
| 18 | 18 | Current ×1; **Previous ×6/12 (½)** |
| 24 | 24 | Current ×1; Previous ×1 |

**"Open T months before the beginning of the period" anchor (R = T + 12):**

| T (months) | R | Year-of-opening rows (weights) |
|---|---|---|
| 12 | 24 | Current ×1; Previous ×1 |
| 18 | 30 | Current ×1; Previous ×1; **2 FYs Prior ×6/12 (½)** |
| 24 | 36 | Current ×1; Previous ×1; 2 FYs Prior ×1 |

**"Open throughout both fiscal years" anchor (R = 24):** Current ×1; Previous ×1.

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

**Round each row to whole stores** (`ROUND(…, 0)`): the boundary year's weighted
count is fractional, but stores are whole units, so the displayed cohort counts
(and their totals) must be **integers**, not values like `87.5`. Round only the
resulting **count** — never round the **weight** up to a full year (see §1.7).

> **Why fractional, not rounded.** Counting the **whole** boundary year overstates
> Non-Comparable and understates Comparable. For a "13 full fiscal months" issuer
> (R = 13), the window reaches only **one month** into the prior year, so only
> **1/12** of that year's openings are still ramping — tagging the full 12/12 would
> wrongly classify a whole extra year of mature stores as non-comparable. In retail
> that error is large in absolute terms: for Dollar General fiscal 2025 it would
> move roughly **665 stores** (725 − 60) out of the comparable base and blow the
> §1.11 spot-check against the disclosed 20,268 same-stores wide open. The
> fractional weight is more accurate **and** stays consistent across periods, so
> comp-vs-non-comp **trends** remain clean.

### 1.5 — Resolve the openings source against the flow-disclosure tier (retail-specific)

The weighted year-of-opening rows need **gross store openings per fiscal year**,
per banner, for `ceil(R/12)` years — including `k\*` years **before** the build
window. The location build's **flow-disclosure tier** tells you whether that
exists. Work the tiers in order and **stop at the first one that succeeds**; do
not silently degrade.

**Tier 1 — gross openings and closures disclosed.** Build §1 exactly as written.
`Opened in Current Yr` references the location build's `Store Openings` row for
that banner; the lookback rows pull the pre-window openings per §1.8. Nothing
special is required. *(Dollar General is this shape.)* A reported comparable
store count, where one exists, is the §1.11 spot-check, not an input.

**Tier 2 — net opened/(closed) only.** The location build carries one
`Net Stores Opened / (Closed)` row and **no gross split**. A net figure is
`openings + closures` and is **not** an openings count. Recover gross openings in
this order:

1. **Re-read the 10-K store-activity table for a gross split.** deepKPI's flow
   series are often sparser than the filing. Search the saved markdown for
   `Stores opened`, `Stores closed`, `Stores at beginning of year`,
   `Store count and square footage`, `Number of store locations`, `Store
   activity`, `<Banner> North America` with a trailing capture window. A gross
   split found here means the location build **could have laid** `Store Openings`
   and `Store Closures` for that banner and did not — a row this build is entitled
   to expect (Dependencies, end of file). Do **not** lay it here: the openings row
   belongs to the location build. Stop and return **`DEFECT UPSTREAM — revenue,
   location build: no Store Openings for <banner>, <historical columns>; 10-K
   store activity table FY<n>`** per `../../../SKILL.md` Step 4.2. The location
   build is re-run, lays the gross rows as its own 10-K override, and re-issues its
   report with the tier upgraded to gross; this build is then re-run and `Opened in
   Current Yr` references the roll as in Tier 1. If the location build answers
   `RE-ENTRY FAILURE — gross split disclosed at the consolidated level only`, take
   path 2 below.
2. **Check the consolidated level.** Some retailers publish gross openings and
   closures consolidated while giving only net per banner. If so, allocate
   **nothing** — instead build the cohort at the **consolidated** level (§1.10's
   consolidation case) rather than fabricating a per-banner gross split.
3. **If the issuer reports a comparable store count, invert the plug** (the
   Tier-3 path 1 below): the reported comparable count is the input and
   `Total Non-Comparable Cohort` is the plug. The issuer's own count is strictly
   better than any proxy built from a net flow.
4. **Otherwise use the net flow as the openings proxy, floored at zero —
   and say so in writing.** `Opened in Current Yr` is
   `= MAX(0, <Net Stores Opened / (Closed)>)` (§1.7), and the lookback rows take
   the same floored net flow for their years. This is the analyst convention for
   net-only disclosure: stores open at the start of the year that survived it
   form the comparable base, and net new stores are the non-comparable cohort.
   In a net-closing year that makes the non-comparable count **zero** and the
   whole period-end fleet comparable — a shrinking banner opened few stores, and
   every store that survived the year existed last year. Add the cell comment
   *"Gross openings not disclosed; net opened/(closed) used as the openings
   proxy, floored at 0. Understates the non-comparable cohort by the year's
   closures (by the year's openings in a net-closing year),"* add one Notes
   line per banner (§5.5), *"Revenue: <banner> gross openings are not
   disclosed; net openings floored at zero stand in, which understates the
   new-store cohort by the year's closures,"* and flag it in the hand-back. Do
   **not** present a net figure in a row labeled `Store Openings` without that
   comment. No stop, no question to the user: the convention is the default.
5. **Never manufacture a gross split** by assuming a closure rate.

**Tier 3 — period-end levels only, no flow anywhere.** The location build's rolls
carry a derived `Net Change` (`= EOP − BOP`) row and no `Other` plug, and it has
already flagged that **an opening-vintage cohort is not supportable**. Two
permitted paths, in order:

1. **If the issuer reports a comparable store COUNT** (many do — Dollar General
   reports *"our 20,268 same-stores"*; off-price and specialty retailers often
   report "comparable stores" in the KPI table), **take the reported comparable
   count as a deepKPI / 10-K input** and **invert the plug**: `Total Comparable
   Cohort` becomes the **input**, and `Total Non-Comparable Cohort` becomes the
   **plug** (`= EOP − Total Comparable Cohort`). Drop the year-of-opening rows
   entirely, keep the assumptions rows (recording `T`, the anchor, and that the
   vintage rows are not supportable), and record the inversion in the **Notes
   block** (§5.5) as *"Revenue: <banner> comparable count is the issuer's
   reported figure; the non-comparable count is the remainder of the period-end
   fleet."* This is a **better** cohort than a vintage estimate, because it is
   the issuer's own count.
2. **If no comparable count is reported either**, use the derived `Net Change`
   (`= EOP − BOP`) as the openings proxy, floored at zero exactly as Tier 2
   step 4: `Opened in Current Yr = MAX(0, <Net Change>)`, the lookback rows
   likewise. Mark every affected cell with a comment (*"Openings not disclosed by
   banner; net change used as a proxy, floored at 0. The cohort split is an
   estimate"*), add a prominent line to the **Notes block** (§5.5), *"Revenue:
   <banner> openings are not disclosed by banner; net change floored at zero
   stands in, so the cohort split is an estimate,"* and flag it in the
   hand-back. The cohort is an estimate and the Notes say so; the build
   continues unattended — a cohort resting on a net-change proxy is the
   convention when the filing gives nothing finer, not a reason to stop.

**Record the tier and the path taken** in `BUILD_LOG.md` — never as a note row
inside the cohort block, and not in the Notes block, which carries only the
resulting facts (the openings proxy or the inversion, in the words above). The
checklist in §1.11 verifies it.

### 1.6 — Build the cohort row block (one per banner)

For **each retail banner / chain** the parent operates (the **same block set, at
the same level, in the same order** as the store roll-forward — banner, banner ×
region, or segment, whichever the location build used), lay down one cohort block.
Single-banner retailers get one block; multi-banner parents get one block per
banner (The Gap, Inc. at banner × region gets six: Old Navy North America, Gap
North America, Gap Asia, Banana Republic North America, Banana Republic Asia,
Athleta North America).

> **Match the location build's block level exactly.** Do not aggregate two of its
> blocks into one cohort block, and do not split one of its blocks into two. Every
> cohort formula references that block's flow row (`Store Openings` on Tier 1,
> `Net Stores Opened / (Closed)` on Tier 2, `Net Change` on Tier 3 — §1.7) and
> its `EOP Balance` cell; a level mismatch breaks the references and silently
> mixes fleets.

The block has five logical zones: **(0) cohort assumptions** (the single-value
threshold `T`, effective reach `R`, and stub-year fraction that drive the math),
**(a) cohort lookback inputs** (the prior fiscal years' openings the cohort math
needs and that the store roll-forward does not already contain), **(a′) the
base-year seed** (three rows, base column only, that give §2 the prior-year
comparable count its seed divides by — §1.7), **(b) the weighted year-of-opening
rows** (each = openings × weight, computed from the inputs / roll-forward
openings and the assumptions), and **(c) the totals + memo**.
There is a **single** Non-Comparable cohort — no internal age sub-bucketing.
Layout (all label text in Col C):

```
<Banner>                                                                                           [banner header: bold + underlined, indent 0]
  ⤷ Cohort assumptions (single values; not per-period)                                             [italic note, size 11, gray]
    Months to enter comp base                                           (months)                   [deepKPI/10-K INPUT, one cell — T, the comparable threshold (§1.1)]
    New-store window                                                    (months)                   [INPUT or FORMULA, one cell — R, the effective reach (§1.1): = T, T+12, or 24 by anchor; comment which anchor was read]
    Stub-year fraction                                                  (x)                        [FORMULA, one cell — (R mod 12)/12, or 1 when R is a multiple of 12]
  ⤷ Cohort lookback inputs (deepKPI/10-K; read across by period)                                   [italic note, size 11, gray]
    [Openings three fiscal years ago — only if ceil(R/12) ≥ 4]          (stores)                   [INPUT row]
    [Openings two fiscal years ago — only if ceil(R/12) ≥ 3]            (stores)                   [INPUT row]
    Openings one fiscal year ago                                        (stores)                   [INPUT row — only if ceil(R/12) ≥ 2]
  ⤷ Base-year seed (base column only; one fiscal year before the window)                           [italic note, size 11, gray]
    EOP stores — one fiscal year before the window                      (stores)                   [INPUT, base col only; dash elsewhere]
    Openings <k*+1> fiscal years ago                                    (stores)                   [INPUT, base col only; omit if k* = 0]
    Comparable cohort — one fiscal year before the window               (stores)                   [FORMULA = EOP − Σ ROUND(openings × w(k), 0), or INPUT = reported comparable count; base col only]
                                                                        ← one blank spacer row HERE only
  Non-Comparable Cohort                                                                            [sub-header: bold + underlined, indent 1]
    [Opened 3 FYs Prior — only if ceil(R/12) ≥ 4]                       (stores)                   [FORMULA = ROUND(openings × w(3), 0)]
    [Opened 2 FYs Prior — only if ceil(R/12) ≥ 3]                       (stores)                   [FORMULA = ROUND(openings × w(2), 0)]
    Opened in Previous Yr                                               (stores)                   [FORMULA = ROUND(openings × w(1), 0); boundary rounds to whole]
    Opened in Current Yr                                                (stores)                   [FORMULA — ref to the store roll-forward; always ×1, whole]
    [Stores Removed from Comp Base — Remodel / Relocation — optional]   (stores)                   [FORMULA or INPUT — only if §1.1 removes remodels / relocations from the comp base; see §1.7]
  Total Non-Comparable Cohort                                           (stores)                   [FORMULA sum; bold; SUM-BAR]
  Total Comparable Cohort                                               (stores)                   [FORMULA plug; bold; SUM-BAR]
    Memo: Comparable as % of total                                      (% of EOP Balance)         [FORMULA; italic]
    [Memo: Reported comparable store count]                             (stores)                   [INPUT, italic — ONLY if the issuer discloses it; spot-check row]
```

**The only three italic-gray rows in this block are the `⤷ Cohort assumptions`,
`⤷ Cohort lookback inputs` and `⤷ Base-year seed` zone labels above** — they
*head* the rows beneath them, so they stay. **No footnote-style note rows go inside the block.** The comparable
definition, the universe, the comp application level and every other basis
statement are recorded **once**, in the **Notes block** at the bottom of the
build (§5.5) — never interleaved between the cohort rows. The flow tier and the
path taken go to `BUILD_LOG.md`.

**Optional rows, used only when the disclosure supports them:**

- `Stores Removed from Comp Base — Remodel / Relocation` — a **positive** input
  row inside the Non-Comparable zone, **only** when §1.1 established that the
  issuer removes such stores from the comp base **and** reports the count. These
  stores are not comparable, so they belong in the Non-Comparable total; adding
  them there subtracts them from Comparable via the plug. Omit the row entirely
  otherwise; never estimate the count.
- `Memo: Reported comparable store count` — a deepKPI / 10-K **input** memo row
  carrying the issuer's own comparable count where disclosed. It **never feeds a
  formula**: it is the §1.11 spot-check and nothing else. On a Tier-2 or Tier-3
  fleet using the §1.5 inversion the reported count is entered **directly as the
  `Total Comparable Cohort` cell** (input styling, hyperlinked) and
  `Total Non-Comparable Cohort` becomes the plug; this memo row is then **not
  laid**, because it would be a second copy of the same input.

**Row-spacing rule (strict):** the **only** blank spacer row inside a banner's
cohort block is the **single** row between the lookback-inputs zone and the
`Non-Comparable Cohort` sub-header. From `Non-Comparable Cohort` **through
`Total Comparable Cohort`** — including the sub-header, every year-of-opening line
item, and the two grand-total rows — there are **zero blank rows**. The block reads
as one tight stack so the visual flow `sub-header → items → total non-comp → total
comp` is preserved. The `Memo:` rows sit **immediately** below
`Total Comparable Cohort` (no blank row above the first memo). A single blank
spacer row follows **after** the last memo to separate this banner's block from the
next banner.

**Label-text rule (strict):** **row labels in Col C are plain descriptive text
only** — `Opened 3 FYs Prior`, `Opened 2 FYs Prior`, `Opened in Previous Yr`,
`Opened in Current Yr`, `Total Non-Comparable Cohort`, `Total Comparable Cohort`.
**Do not** append the formula or its operand recipe (e.g. ` (FY(N-1) opens)`,
` (FY(N) full)`) to the visible row text — that information goes in the **cell
comment** on the label cell (see "Formula-in-comment rule" below). Users who need
to verify a value can either click the value cell and read the formula in the
formula bar or hover the label cell to read the comment. Col C display labels also
follow the sheet-wide pattern the location build uses — dash-separated qualifiers,
spelled-out words, no parenthetical modifiers, no opaque banner codes — and should
stay short enough that the column width (~50 chars) does not have to grow.

**Formula-in-comment rule:** for every **formula** row in zones (b) and (c) (i.e.
every row whose values are computed, not inputs), attach a **cell comment** to the
**Col C label cell** (not to the value cells). The comment states, in one or two
short lines, the formula used and what it represents — e.g. for the
`Opened in Previous Yr` row in a Dollar General build (R = 13, boundary year,
weight 1/12):

> `Formula: = ROUND(<Openings one fiscal year ago> * Stub-year fraction, 0)`
> `= w(1) × FY(N-1) opens; boundary year ⇒ weight (R mod 12)/12 = 1/12`

Comments are roughly **320 × 80 pixels** so the two lines fit cleanly. Author =
`Cohort Build` (or the build's standard author string). **Do not** add cell
comments on the deepKPI input rows in zone (a) — provenance there is already
carried by the value cell's hyperlink, and the row label ("Openings one fiscal
year ago") is self-explanatory. **Do** add a comment on any **10-K override** cell
citing the filing and table, matching the location build's convention.

The number of input rows in zone (a) equals **k\* = ceil(R/12) − 1** (one per prior
contributing year):

- R = 12: **no** lookback input rows (current year only — the prior year is fully
  comparable).
- R = 13–24: **one** lookback input row (FY(N-1)).
- R = 25–36: **two** lookback input rows (FY(N-2), FY(N-1)).
- R = 37–48: **three** lookback input rows.

(Dollar General, R = 13 → one lookback row; an "18 months before the beginning"
retailer, R = 30 → two.)

Indentation, fonts, and borders follow the **xlsx styling rules** the way the store
roll-forward does: banner header bold at **base indent** (`indent=0`), italic-gray zone
labels at **`indent=1`**, the `Non-Comparable Cohort` sub-header bold at **`indent=1`**,
year-of-opening line items at **`indent=2`**, the `Total Non-Comparable Cohort` and
`Total Comparable Cohort` rows bold with the SUM-BAR (a single thin top border across
the data columns only), memo rows italic.

**Every one of those levels is the cell's real indent property** —
`Alignment(indent=n)`, the openpyxl equivalent of Excel's **Home → Increase
Indent** (`Alt, H, 6`) — and **never leading spaces in the label string**. See
**Indentation — real cell indent, never leading spaces** below.

### 1.7 — The formulas (cell-by-cell) for the cohort block

Lay down a small **assumptions** sub-zone first (single cells, not per-period),
then the lookback inputs, then the **weighted** year-of-opening rows. Row labels
below are the **plain Col C text**. Every value cell is a **live formula** except
the threshold `T`, the lookback openings, and the optional memo inputs.

**Assumptions (one cell each — put the value in a single cell, e.g. the first
period column, and reference it absolutely):**

| Row (plain Col C label) | Lays when | Units (Col D) | Cell |
|---|---|---|---|
| `Months to enter comp base` | | `(months)` | **input** — `T`, the comparable threshold from the 10-K (13 for Dollar General). Input style. Comment: *"Months a store must be open before it enters the comparable base, per the 10-K's comparable definition."* |
| `New-store window` | | `(months)` | `R`, the effective reach: `= T`, `= T + 12`, or `24` per the anchor (§1.1). Comment: *"Months of openings still counted as new (non-comparable) this year: the threshold under an in-operation-through-the-period anchor, threshold + 12 under a before-the-period-start anchor, 24 under an open-throughout-both-periods anchor. Anchor read: <quote>."* |
| `Stub-year fraction` | | `(x)` | `= (R − 12*(CEILING(R/12,1) − 1)) / 12` → returns `(R mod 12)/12`, or **1** when R is a multiple of 12. Comment: *"Fraction of the oldest lookback year's openings still non-comparable: (new-store window mod 12) ÷ 12, or 1 when the window is a whole number of years."* |

**Lookback inputs (zone a), one row per prior contributing year k = 1 … k\*:**

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula |
|---|---|---|---|
| `Openings one fiscal year ago` | | `(stores)` | deepKPI / 10-K **input** — gross store openings for the FY **one year before** column N; where that FY is already in the store roll-forward's window it is instead the per-tier reference to the prior column: `= <Store Openings, prior column>` on Tier 1, `= MAX(0, <Net Stores Opened / (Closed), prior column>)` on Tier 2, `= MAX(0, <Net Change, prior column>)` on Tier 3 (§1.5). Green fill (or gold for a 10-K override), blue font, hyperlinked when an input. No comment unless it is an override or a proxy. |
| `Openings two fiscal years ago` (only if k\* ≥ 2) | | `(stores)` | input — openings **two** FYs before column N. Same styling. |
| `Openings three fiscal years ago` (only if k\* ≥ 3) | | `(stores)` | as above, **three** FYs before. |

**Base-year seed (zone a′) — values in the base (leftmost) column only; every
other column, historical and projection, is a dash.** These rows give §2 the
prior-year comparable count its seed divides by. The window never grows a
column for them: the cells sit in the base column, their labels carry the year
offset, and their provenance hyperlinks point at the earlier filing or series.

| Row (plain Col C label) | Lays when | Units (Col D) | Base-column cell |
|---|---|---|---|
| `EOP stores — one fiscal year before the window` | | `(stores)` | deepKPI / 10-K **input** — the company-operated (§1.9) period-end count for FY(M−1). Input style, hyperlinked. |
| `Openings <k\*+1> fiscal years ago` | | `(stores)` | deepKPI / 10-K **input** — openings for FY(M−1−k\*), one year further back than zone (a) reaches (label follows zone (a)'s naming: `two` when k\* = 1, `three` when k\* = 2). Omit when k\* = 0. On a Tier-2 / Tier-3 fleet this is the floored net flow for that year, sourced as §1.5 describes. |
| `Comparable cohort — one fiscal year before the window` | | `(stores)` | **If the issuer reports a comparable count for FY(M−1): input**, that figure (green or gold, hyperlinked) — the issuer's own count beats the model. **Otherwise formula**, the same arithmetic as `Total Comparable Cohort` shifted one year left: `= <EOP, one FY before> − <Openings one fiscal year ago, base col> − ROUND(<Openings two fiscal years ago, base col> × $<Stub-year fraction>, 0)` for k\* = 1, extending by one `ROUND(openings × w(k), 0)` term per further contributing year, each year's openings taken from zone (a)'s base cell or the row above. Comment on the label cell states the formula or the source. |

§2.4 references the third row for its base-column denominator; nothing else
reads these rows.

**Weighted year-of-opening rows (zone b) — each `= openings × w(k)`:**

| Row (plain Col C label, in order) | Lays when | Units (Col D) | Cell formula | Comment on Col C |
|---|---|---|---|---|
| `Opened 3 FYs Prior` (only if k\* ≥ 3) | DATA_DEPENDENT | `(stores)` | full year `= <Openings three fiscal years ago>`, or — if it is the boundary year — `= ROUND(<Openings three fiscal years ago> * $<Stub-year fraction>, 0)` | `"= w(3) × FY(N-3) opens; boundary ⇒ rounded to whole stores"` |
| `Opened 2 FYs Prior` (only if k\* ≥ 2) | DATA_DEPENDENT | `(stores)` | full year `= <Openings two fiscal years ago>`, or — if FY(N-2) is the boundary year (e.g. R=30) — `= ROUND(<Openings two fiscal years ago> * $<Stub-year fraction>, 0)` | `"= ROUND(w(2) × FY(N-2) opens, 0); boundary ⇒ × (R mod 12)/12, rounded to whole stores"` |
| `Opened in Previous Yr` | | `(stores)` | full year `= <Openings one fiscal year ago>`, or — if FY(N-1) is the boundary year (e.g. R=13 ⇒ ×1/12) — `= ROUND(<Openings one fiscal year ago> * $<Stub-year fraction>, 0)` | `"= ROUND(w(1) × FY(N-1) opens, 0); boundary ⇒ × (R mod 12)/12 (R=13 ⇒ 1/12), rounded to whole stores"` |
| `Opened in Current Yr` | | `(stores)` | per tier (§1.5), same banner, same column of the store roll-forward: **Tier 1** `= <Store Openings>`; **Tier 2** `= MAX(0, <Net Stores Opened / (Closed)>)`; **Tier 3** `= MAX(0, <Net Change>)`; or a gold **10-K override input** when §1.5 Tier-2 step 1 found a gross split | `"= w(0) × FY(N) opens = ALL current-year openings (always fully non-comparable)"` — on Tier 2 / 3 add the §1.5 proxy comment |
| `Stores Removed from Comp Base — Remodel / Relocation` *(optional)* | DATA_DEPENDENT | `(stores)` | **input**, entered **positive** | `"Reported count removed from the comp base while remodeled/relocated, per the 10-K's comparable definition. Not comparable ⇒ sits in the Non-Comparable total; the EOP−NonComp plug removes it from Comparable."` |
| `Total Non-Comparable Cohort` | | `(stores)` | `= SUM(` the weighted year-of-opening rows above, including the optional removal row `)` | `"Σ w(k)·FY(N-k) openings. No internal age sub-buckets."` |
| `Total Comparable Cohort` | | `(stores)` | `= <EOP Balance from the store roll-forward, same banner> − <Total Non-Comparable Cohort>` | `"Plug: EOP − Non-Comparable. Comp + Non-Comp = EOP exactly."` |
| `Memo: Comparable as % of total` | | `(% of EOP Balance)` | `= <Total Comparable Cohort> / <EOP Balance>` (percent) | `"Comparable / EOP"` |
| `Memo: Reported comparable store count` *(optional)* | DATA_DEPENDENT | `(stores)` | **input** — the issuer's own disclosed comparable store count | *(no comment — input row; spot-check against the row above)* |

**Which row gets the fractional weight.** Exactly **one** year-of-opening row —
the boundary year FY(N−k\*), k\* = ceil(R/12) − 1 — is multiplied by the
`Stub-year fraction` cell. All shallower prior years (k < k\*) are full
(`= <openings>`), and the current year is always full. So:

- **Dollar General (R = 13, k\* = 1):** one lookback row; `Opened in Previous Yr =
  ROUND(<one FY ago> * $<weight>, 0)` with weight = 1/12; `Opened in Current Yr =
  <store roll-forward openings>`. ⇒ Non-Comparable = current openings +
  ROUND((1/12)·prior openings).
- **A "12 months / one full year" retailer (R = 12, k\* = 0):** **no** lookback
  rows and **one** year-of-opening row — `Opened in Current Yr` only.
- **An "18 months before the beginning" retailer (R = 30, k\* = 2):** two lookback
  rows; `Opened in Previous Yr = <one FY ago>` (full, w=1); `Opened 2 FYs Prior =
  ROUND(<two FYs ago> * $<weight>, 0)` with weight = ½ (boundary);
  `Opened in Current Yr = <store roll-forward openings>`.

The **`Opened in Current Yr`** cell **must reference the store roll-forward's
flow row** — `Store Openings` on Tier 1, `MAX(0, Net Stores Opened / (Closed))`
on Tier 2, `MAX(0, Net Change)` on Tier 3 — so a single edit there flows
through; the only exception is the §1.5 Tier-2 step 1 override input. The
`MAX(0, …)` floor is the net-only convention: openings cannot be negative, and
in a net-closing year the whole fleet is treated as comparable. The
`Total Comparable Cohort` is always a **plug** (`EOP − non-comp`) so the identity
**Comp + Non-Comp = EOP** holds exactly — **except** on a Tier-2 or Tier-3 fleet
using the §1.5 inversion, where `Total Comparable Cohort` is the reported input
and `Total Non-Comparable Cohort` is the plug; the identity still holds either way.

**Round to whole stores.** The stub-year fraction yields a fractional count, but
stores are whole units — so wrap the boundary row in `ROUND(…, 0)` (the
full-weight rows are already integers). `Total Non-Comparable Cohort` then sums
whole numbers and `Total Comparable Cohort` (EOP − Non-Comparable) stays an exact
integer. Display **all** cohort rows as **whole stores** (`#,##0`), matching the
store counts above — no `87.5`-style fractional units. (Round only the displayed
**count**; never round the **weight** itself up to a full year.)

**Which EOP the plug points at.** `<EOP Balance>` is the banner's **Company-Operated
EOP Balance** (§1.9) — never a total system EOP. Point at the **banner's** EOP,
never at the `Total — all banners` block's `Company-Operated EOP Balance`, unless
the cohort itself is being built consolidated (§1.10).

**If the issuer reports its own non-comparable sub-buckets** (e.g. a net-sales
walk breaking the change into "new stores", "closed stores", "relocated stores"),
**do not** mirror those buckets as rows here. Sum them conceptually into a single
non-comparable total and express the breakdown via the weighted year-of-opening
rows above. The issuer's published figures are a useful sanity check (§1.11), but
they do not change the row structure.

### 1.8 — Sourcing the lookback inputs

For the cohort block to be self-contained, the **lookback input rows** must pull
openings for fiscal years that are **not in the store roll-forward's window**. For
a build window of FY(M)…FY(N) (currently the last 4 FYs), the lookback inputs need:

- **FY(M-2)** opens (for the FY(M) column's "two years ago" cell), if k\* ≥ 2
- **FY(M-1)** opens (for the FY(M) column's "one year ago" cell, and reused for
  the FY(M+1) column's "two years ago" cell)
- All fiscal years already in the roll-forward's openings row are reused as
  formulas in the cohort lookback rows where their period falls.
- **For the base-year seed (zone a′, §1.7):** the **FY(M-1) period-end
  company-operated count** and **FY(M-1-k\*)** opens (FY(M-2) for a 13-month
  retailer), unless the issuer reports a comparable count for FY(M-1), in which
  case that count is pulled instead and the openings row is still laid.

In practice, for a **13-month-threshold** retailer (k\* = 1) with a 4-year build
window (FY2022–FY2025), the single lookback row holds these values per column:

| Period column | "One year ago" cell holds |
|---|---|
| FY2022 | FY**2021** opens (new input) |
| FY2023 | FY**2022** opens (= store roll-forward openings row) |
| FY2024 | FY**2023** opens (= store roll-forward openings row) |
| FY2025 | FY**2024** opens (= store roll-forward openings row) |

So a 13-month retailer needs **exactly one** genuinely new pull: FY(M−1) openings.
A 24-month or "before the beginning" retailer needs two.

The cells holding values that are already in the roll-forward's openings row
**may** be formulas (`=<column in the openings row>`) for traceability, or they
may be re-pulled as deepKPI inputs — both are acceptable. Use re-pulled inputs when
it is simpler (one consistent input series) or use formulas when it makes the data
flow more transparent. **Either way, every cell carries a provenance hyperlink**
(input cells via `cell.hyperlink`; formula cells inherit provenance from the
referenced input cell).

Pull the openings from the **same KPI series** the store roll-forward's flow
row drew from (`Store Openings` on Tier 1; on Tier 2 / 3 the floored net flow
per §1.5) — e.g. `Number of New Retail Stores Opened`,
`<Banner> store openings`, `New stores opened` — or, if the roll-forward took them
from the 10-K store-activity table, take the lookback year from **that fiscal
year's 10-K** and style it as a **10-K override** cell. Use **company-operated**
openings only (§1.9) — never the sum of company-operated + franchised/licensed
openings.

**Two retail cautions on the lookback pull:**

- **Check the value for scaling and cross-tagging artifacts before writing it.**
  Retail opening series carry these at a high rate (Gap's consolidated net-flow
  series returns `-56000000` for **−56**; its franchise-location series carries a
  cross-tagged total store count in its earliest year). A lookback value that is
  orders of magnitude off its own neighbors is an artifact — take it from the
  10-K and mark it as an override; **never rescale silently**.
- **A pre-window year may predate the banner.** Where a banner did not exist (or
  was acquired mid-window), use **zero (display as a dash)** for that cell, **not**
  blank — downstream formulas return `#VALUE!` on blank operands.

### 1.9 — Cohort universe: company-operated only

The cohort partition is built on the **company-operated** universe — the banner's
`Company-Operated EOP Balance` row in the store roll-forward, with the lookback
and current-year openings referencing the **Company-Operated** roll's flow row
(`Store Openings` on Tier 1, the floored net flow on Tier 2 / 3 — §1.7). There is no total-system option: the cohort math
partitions **company-operated net sales** (§2, §3), and franchisee store sales
never pass through the income statement (in retail the franchise line is often
wholesale shipments to partners, which bear no relation to the partners' retail
sales at all — §4.1). A systemwide count therefore has no dollar base to pair
with, and a system cohort would double-count against `Franchise & License
Revenue` in the §5 foot. A system comp may only ever be a **rate**, never a
dollar base.

- If the issuer reports comp sales **only for company-operated stores** (the most
  common retail pattern), use that comp.
- If the issuer reports comp sales **only on a systemwide basis** (company and
  franchised / licensed stores together), **this build does not apply**. The
  router's A criteria test this universe from the comp caption, so this build
  should not have been reached; if it was, return the **`ABORTED`** hand-back
  ("Aborting the build", above). No retail build consumes a comp rate
  downstream, so the signal is lost on that route; that is accepted.
- If the issuer reports **both** a company-operated comp and a franchise or
  system comp, use the company-operated comp here. The second comp is **not
  consumed by this build** — §4.1 carries franchise & license revenue as a single
  line on its own YoY driver — so record it in the Notes block (*"Revenue: the
  issuer also reports a <franchise / system> comp; it is not used, since
  franchise revenue is carried on its own growth rate."*) and leave it. Do not
  build a second cohort block.

**Comp basis inside company stores is not a universe choice.** Department-store
issuers report comparable sales on an **owned** basis and on an
**owned-plus-licensed-departments** basis (sometimes also with marketplace
sales). Licensed departments are third-party counters inside company-operated
stores, so the store count is unchanged either way; what differs is the sales
the rate measures. Prefer the basis that matches the **seed dollars** §2.1 uses
(the owned basis, when the seed is the issuer's own net sales). If only the
wider basis is reported, use it as the rate, note the mismatch in the bridge's
Col C comment, and record it in the Notes block: *"Revenue: the comp rate is on
an owned-plus-licensed basis while the seed dollars are owned-only; the rate is
a proxy."* Never derive a dollar seed from the wider basis.

Record the universe and the comp series and basis used in the **Notes block** at
the bottom of the build (§5.5), so the basis is auditable: *"Revenue: cohorts
and comps are company-operated stores; comp series: <caption>, on an <owned /
owned-plus-licensed> basis."*

> **The universe binds §2 and §3.** Company-operated is the universe whose **net
> sales** §2 seeds from and §3 divides by. Company-operated store counts paired
> with total net sales (which in retail includes digital, wholesale, licensing
> and membership fee income that no store produced) is the single most damaging
> error available in this build — see §3.2.

### 1.10 — Multi-banner parents, and the comp-granularity mismatch

For a parent operating multiple banners, **build one cohort block per banner**,
at the location build's block level, every one on the company-operated universe
(§1.9). Do **not** build a single consolidated cohort across banners: such a sum
would mix banners with potentially different age thresholds and very different
unit economics.

**The retail wrinkle restaurants do not have: comp is often reported at a
different granularity than store counts.** The Gap, Inc. is the canonical case —
deepKPI carries `Comparable Sales Change for Gap Global`, `… Old Navy Global`,
`… Banana Republic Global`, `… Athleta Global` (**banner-global**), while the
store roll-forward's block level is **banner × region** (Gap North America, Gap
Asia, …). There is no `Gap North America` comp rate to pair with the
`Gap North America` cohort.

Resolve it by this rule, in order:

1. **Keep the cohort blocks at the location build's level** — do not collapse them.
   The cohort counts stay per block.
2. **Apply the comp rate at the level it is reported**, to the **sum** of the
   cohort counts that level covers. For Gap that means the §2 comparable bridge is
   built **per banner-global** (Gap, Old Navy, Banana Republic, Athleta), with the
   comparable count = `SUM` of that banner's regional `Total Comparable Cohort`
   cells. Record the roll-up in the bridge's Col C comment.
3. **Never allocate one banner's comp rate across its regions** as if each region
   grew at the global rate, and never average regional rates into a synthetic
   global rate. Apply the reported rate once, to the matched aggregate.
4. **If only a consolidated comp % exists** for a multi-banner parent, build a
   **single consolidated comparable bridge** (§2.6) whose comparable count is the
   sum of **all** banners' `Total Comparable Cohort` cells. The §1 cohort blocks
   remain per banner; only the revenue bridge consolidates.

Record which level each comp rate is applied at in the **Notes block** (§5.5):
*"Revenue: the comp rate is applied per <banner / banner and region / the whole
company>, as reported, over the summed cohort counts."*

### 1.11 — Pre-delivery checklist (Store Cohort section)

Before declaring this section done and moving to the next revenue sub-section,
verify every item:

- [ ] The **fiscal-year column mapping** was adopted from the store roll-forward,
      not re-derived, and every new series pulled here was mapped to fiscal-year
      **ordinals** rather than joined on its raw date stamp (§0.1). The newest
      column's comp % ties to the latest 10-K's KPI table.
- [ ] The **flow-disclosure tier** (1 / 2 / 3) and the §1.5 path taken are recorded
      in `BUILD_LOG.md`; on Tier 2 the openings source is a 10-K
      gross split (override input), the reported comparable count (inverted
      plug), or the net flow floored at zero with its comment and its Notes
      line; on Tier 3 either the reported comparable count drives the block
      (inverted plug, with its Notes line) or the floored net change does, with
      its comment and Notes line. No `Opened in Current Yr` cell is negative on
      any tier.
- [ ] The **Notes block** (§5.5) **quotes (or closely paraphrases) the comparable
      definition** from the 10-K, citing the filing year (e.g. "per DG FY2025
      10-K"), and its lines cover all six §1.1 parameters in analyst words:
      threshold, anchor, remodel/relocation treatment, the "remains open at
      period end" clause (inside the quoted definition), the 52-week basis, and
      whether digital is inside the comp base.
- [ ] **No footnote-style note rows sit inside the cohort block.** The only
      italic-gray rows there are the `⤷ Cohort assumptions`, `⤷ Cohort lookback
      inputs` and `⤷ Base-year seed` zone labels (§1.6); every basis statement
      lives in the Notes block.
- [ ] The framework / assumptions rows state **T**, the **anchor**, the resulting
      **effective reach R** (= T, T+12, or 24), and the **stub-year fraction**
      `(R mod 12)/12`, plus which **year-of-opening rows** are laid down (§1.2,
      §1.4).
- [ ] The Non-Comparable cohort is a **single block** — no internal age sub-bucket
      headers. Only the year-of-opening line items (and, where disclosure supports
      it, the single optional `Stores Removed from Comp Base` row, entered
      **positive**) appear.
- [ ] The **number of year-of-opening rows** is **ceil(R/12)**: 1 row for R = 12
      (Current only), 2 rows for R = 13–24 (+ `Opened in Previous Yr`), 3 rows for
      R = 25–36 (+ `Opened 2 FYs Prior`), 4 rows for R = 37–48.
- [ ] Exactly **one** year-of-opening row — the boundary year FY(N−k\*) — is
      multiplied by the **fractional** `Stub-year fraction` `(R mod 12)/12` (e.g.
      R = 13 ⇒ `Opened in Previous Yr` × 1/12). Shallower prior years and the
      current year are full (×1). Do **not** round the *weight* up to a full year.
- [ ] Each weighted year-of-opening row is **rounded to a whole store**
      (`ROUND(…, 0)`) and **all cohort rows display as integers** (`#,##0`) — no
      fractional units. `Comparable + Non-Comparable = EOP` still holds exactly.
- [ ] Exactly **one cohort block per banner**, at the **same block level and in
      the same order** as the store roll-forward; no consolidated cross-banner
      block (unless §1.10 case 4 applies, and then it is labeled as such).
- [ ] Every `Opened in Current Yr` and every `EOP` reference points at **that
      banner's own** rows in the store roll-forward — not at the
      `Total — all banners` block, and not at a sibling banner.
- [ ] The **universe** is company-operated (§1.9); the comp series and its sales
      basis (owned vs. owned-plus-licensed) are recorded in the Notes block in
      the §1.9 wording.
- [ ] Where comp is reported at a **different granularity** than the cohort blocks
      (§1.10), the roll-up level is recorded in the Notes block in the §1.10
      wording and the rate is applied **once** to the matched aggregate — never
      allocated across regions or averaged into a synthetic rate.
- [ ] **Lookback input rows** are present — **ceil(R/12) − 1** rows — each styled
      per the input convention (green fill + hyperlink for deepKPI, gold fill +
      comment + hyperlink for a 10-K override), and each checked for scaling /
      cross-tagging artifacts before transcription.
- [ ] **Base-year seed rows** (zone a′) are present with values in the base
      column only: the FY(M−1) period-end count, the FY(M−1−k\*) openings, and
      `Comparable cohort — one fiscal year before the window` as either the
      reported FY(M−1) comparable count (input) or the shifted cohort formula;
      every other column of those rows is a dash.
- [ ] Every cell that is not an input is a **live `=` formula** (no hardcoded
      numbers). The `Opened in Current Yr` cell references the roll-forward's
      openings cell; the Comparable cell is `EOP − non-comp` (or the inverse on a
      Tier-3 inversion); the memo row is `comp / EOP`.
- [ ] After recalculation (LibreOffice / `recalc.py`), there are **zero formula
      errors** and the identity **Comparable + Non-Comparable = EOP** holds
      **exactly** for every banner and every period (rounding included).
- [ ] **Spot-check against the issuer's own comparable count.** If the 10-K reports
      one (e.g. Dollar General's *"our 20,268 same-stores"*), the modeled
      `Total Comparable Cohort` must land **within ~2%** of it for the most recent
      FY. Larger gaps (>5%) flag either a misread definition (likely T, the anchor,
      or the universe) or a data problem in the openings series — resolve before
      proceeding. Show the comparison in the optional
      `Memo: Reported comparable store count` row and record the check and its
      result in `BUILD_LOG.md`; it is not a Notes line.
- [ ] **Row-spacing rule (§1.6):** the only blank spacer row inside each banner's
      cohort block sits **between the lookback-inputs zone and the
      `Non-Comparable Cohort` sub-header**. From `Non-Comparable Cohort` through
      `Total Comparable Cohort` (inclusive) there are **zero blank rows**. The
      `Memo:` rows sit immediately below `Total Comparable Cohort`. One blank row
      follows the last memo to separate banner blocks.
- [ ] **Label-text rule (§1.6):** Col C row labels are **plain descriptive text
      only**. No formula recipe appended to the visible label; no opaque banner
      codes; dash-separated qualifiers per the sheet-wide pattern.
- [ ] **Formula-in-comment rule (§1.6):** every **formula** row in the
      year-of-opening / totals zone has a **cell comment on its Col C label cell**
      stating the formula in plain text. **Input** rows in the lookback zone do
      **not** get cell comments unless they are 10-K overrides, which do.
- [ ] All formatting (Calibri 12, accounting number format, indentation,
      bold/border conventions, freeze panes) matches
      `../../../../_common/revelata-excel-styling-rules.md`.
- [ ] **Indentation is the cell's real indent property** — `Alignment(indent=n)`
      (`Alt, H, 6`) — on every Col C label in this section: banner header
      `indent=0`, zone labels and `Non-Comparable Cohort` sub-header `indent=1`,
      year-of-opening line items `indent=2`. **No label string begins with a
      space**; confirm `value == value.lstrip()` for every Col C cell.

### 1.12 — Worked example A — Dollar General FY2022 – FY2025 (R = 13, Tier 1, single banner)

Dollar General Corporation (`company_id` 29534) is the cleanest retail shape and
the same issuer the store roll-forward uses as its Tier-1 worked example, so the
two blocks chain directly. **All figures below are real deepKPI / 10-K values.**

**Definition (fiscal 2025 10-K, MD&A "Key Performance Indicators"):** same-store
sales are calculated on stores **open at least 13 full fiscal months** that
**remain open at the end of the reporting period**; **remodeled, expanded and
relocated stores are included**; the change is computed on the **comparable 52
calendar weeks**. That is the "open at least T months" anchor, so

> **T = 13, R = T = 13, k\* = ceil(13/12) − 1 = 1** → **two** year-of-opening rows,
> weights **w(0) = 1** and **w(1) = (13 mod 12)/12 = 1/12** — only **one twelfth**
> of the prior year's openings (the final month, still inside its first 13 months)
> is non-comparable.

**Universe:** company-operated stores (Dollar General has no franchised fleet).
**Flow tier:** 1 — gross openings and closures both disclosed, so the vintage rows
are fully supported.

**Inputs** (`Number of New Retail Stores Opened - annual`,
`Number of Retail Stores at End of Period - annual`; note the **calendar
placeholder** stamps — fiscal 2025 is stamped `2025-12-31` on these series but
`2026-01-30` on the comp-sales series, per §0.1):

| Fiscal year | Store Openings | Store Closures | Company-Operated EOP |
|---|---|---|---|
| FY2021 *(lookback only)* | 1,050 | (97) | — |
| FY2022 | 1,039 | (65) | 19,104 |
| FY2023 | 987 | (105) | 19,986 |
| FY2024 | 725 | (117) | 20,594 |
| FY2025 | 589 | (290) | 20,893 |

Only **one** genuinely new pull is needed: **FY2021 openings = 1,050**, the single
lookback row (k\* = 1). FY2022–FY2024 openings are already in the store
roll-forward and are referenced as formulas.

**Resulting cohort partition** (`Opened in Previous Yr` × 1/12, each row rounded
to whole stores per §1.7):

| Period | Company-Operated EOP | Opened in Previous Yr × 1/12 (rounded) | Opened in Current Yr | Total Non-Comp | **Modeled Comparable** | Comp % |
|---|---|---|---|---|---|---|
| FY2022 | 19,104 | 88 (=ROUND(1,050/12)) | 1,039 | 1,127 | **17,977** | 94.1% |
| FY2023 | 19,986 | 87 (=ROUND(1,039/12)) | 987 | 1,074 | **18,912** | 94.6% |
| FY2024 | 20,594 | 82 (=ROUND(987/12)) | 725 | 807 | **19,787** | 96.1% |
| FY2025 | 20,893 | 60 (=ROUND(725/12)) | 589 | 649 | **20,244** | 96.9% |

**Spot-check against the issuer's own count (§1.11).** The fiscal 2025 10-K states
*"In 2025, our **20,268 same-stores** accounted for sales of **$41.2 billion**"*
and *"In 2024, our **19,633 same-stores** accounted for sales of **$38.8
billion**"*:

| Period | Modeled Comparable | 10-K reported same-stores | Gap | Gap % |
|---|---|---|---|---|
| FY2025 | 20,244 | **20,268** | −24 | **−0.12%** |
| FY2024 | 19,787 | **19,633** | +154 | **+0.78%** |

Both land well inside the ±2% tolerance. Residual gaps come from non-uniform
opening timing within the year (Dollar General does not open evenly month by
month), not from the framework.

**What the fractional weight is worth here.** Counting the **whole** prior year
instead — the "round up" heuristic — would put FY2025 non-comparable at
589 + 725 = **1,314** and modeled Comparable at **19,579**, a **689-store (3.4%)**
miss against the disclosed 20,268, and it would push comp % down to 93.7% against
a fleet that is genuinely ~97% comparable. The 1/12 weight is what makes the
spot-check pass.

**Notes carried forward from this example:** Dollar General reports the
comparable-cohort **dollars** directly (`$41.2bn` / `$38.8bn`, and the deepKPI
series `Annual net sales from same-stores for Dollar General consolidated retail
operations`, unit USD), which is **§2.1 situation 1** — the strongest possible
base-year seed, and the reason this issuer routes to build A at all. It also
discloses the comp decomposition (fiscal 2025: **+1.6% traffic**, **+1.4% average
transaction amount**) for the §2.2 memo rows.

### 1.12b — Worked example B — The Gap, Inc. (Tier 2, banner × region, banner-global comp)

The Gap, Inc. (`company_id` 39911) is the hard retail shape, and it exercises
three traps at once. It is the same issuer the store roll-forward uses as its
Tier-2 worked example. **The threshold `T` must be read from Gap's own 10-K per
§1.1 — the arithmetic below assumes `R = 12` purely to illustrate the mechanics,
and you must not carry that assumption into a real build.**

**Trap 1 — the block level is banner × region, but comp is reported banner-global.**
The store roll-forward's blocks are `Old Navy North America`, `Gap North America`,
`Gap Asia`, `Banana Republic North America`, `Banana Republic Asia`,
`Athleta North America`. deepKPI's comp series are
`Comparable Sales Change for Gap Global`, `… Old Navy Global`,
`… Banana Republic Global`, `… Athleta Global`. Per §1.10: **keep six cohort
blocks**, then build the §2 comparable bridge **per banner-global**, whose
comparable count is `SUM` of that banner's regional `Total Comparable Cohort`
cells (e.g. Gap = Gap North America + Gap Asia). Do **not** apply
`Gap Global`'s rate separately to Gap North America and Gap Asia as if each grew
at the global rate.

**Trap 2 — Tier 2: net flow is not an openings count.** Gap publishes
`Net Number of Company-Operated <Banner> <Region> Stores Opened or Closed`, not
gross openings and closures. For Old Navy North America the real net flow and EOP
chain is **1,243 + 6 = 1,249**, then **1,249 − 7 = 1,242**. Under §1.5 you must
first re-read the 10-K store-activity table for a gross split; only if it is
genuinely absent, and no comparable store count is reported, may you use the net
figure as the openings proxy — floored at zero, with the mandated cell comment,
the §1.5 Notes line, and hand-back flag. On a fleet closing stores (Old Navy North
America's **−7**), `Opened in Current Yr = MAX(0, −7) = 0`: the non-comparable
cohort for that banner-year is zero and the whole 1,242-store fleet is
comparable, which is the net-only convention (a naive "openings = net" reading
would have produced a **negative** vintage row). The +6 year gives 6. Both
years carry the proxy comment and one Notes line.

**Trap 3 — digital sits inside the comp base while also being reported
separately.** deepKPI carries `Online Sales - Fiscal year` in USD (**$5,754M** for
fiscal 2024, **$5,981M** for fiscal 2025). If Gap's definition includes online in
comparable sales — read it (§1.1, parameter 6) — then those dollars are **already
inside** the comparable bridge and adding a separate `Digital / E-Commerce Net
Sales` line in §4 would **double-count roughly six billion dollars**. §4.2 is the
decision rule; this is the issuer that makes it matter.

**Trap 4 — stamp conventions differ inside one issuer.**
`Comparable Sales Change for Gap Global` stamps fiscal 2024 as `2025-01-31`;
`Online Sales - Fiscal year` stamps the same fiscal 2024 as `2025-02-01`; and
`Comparable sales - Annual` carries two different values under `2022-01-29` and
`2022-01-31` for one fiscal year. Map to fiscal-year ordinals and adopt the store
roll-forward's columns (§0.1) before writing anything.

**Trap 5 — the franchised fleet sits at parent level, not per banner.** Gap's
franchise fleet is reported as a single consolidated line (**998 / 1,063 / 1,000**
across the recent fiscal years), so the store roll-forward carries **one**
parent-level `Franchised & Licensed` roll rather than one inside each banner
block. The cohort universe for each banner is therefore **company-operated only**
(§1.9), and the franchise fleet's economics are picked up as a single
consolidated `Franchise & License Revenue` line in §4.1 — never allocated across
banners.

### 1.13 — What this section produces for downstream sections

After Section 1 is built, the workbook contains, for every banner and every period
in the build window:

- a `Total Comparable Cohort` count (Col E onward), and
- a `Total Non-Comparable Cohort` count broken down by **year of opening only** —
  one **weighted** row each for `Opened in Current Yr`, `Opened in Previous Yr`,
  and (when the reach extends further back) `Opened 2 FYs Prior` / `Opened 3 FYs
  Prior`. Each row is `w(k) × FY(N−k) openings`, with the boundary year carried
  fractionally `(R mod 12)/12`. No internal age sub-buckets.

each as a live formula that flows from the store roll-forward's EOP and openings
inputs plus the cohort lookback inputs added by this section. Subsequent revenue
sub-sections (the comparable-cohort sales bridge, the new-store revenue
contribution) reference `Total Comparable Cohort` and `Total Non-Comparable
Cohort` directly; if a downstream section needs to weight new-store revenue by
opening vintage, it can pick up the individual year-of-opening rows. Any later
change to the underlying store roll-forward (an openings correction, a 10-K
override, or a forecast year added) will propagate automatically through the
cohort partition and into revenue.

---

## Revenue build — framework overview (Sections 2 – 5)

Section 1 partitioned each banner's stores into a **Comparable** and a
**Non-Comparable** cohort. Sections 2 – 6 turn those **store counts** into
**revenue dollars** and foot the build to the company's **reported total revenue**
(the **net sales** line, in retail's vocabulary). The build follows one fixed
framework so that **every** comparable-stores company is modeled the same way and
the workbook always foots.

**The components and the master identity.** The revenue build decomposes reported
total revenue into modeled components plus a plug:

```
  Net Sales from the Comparable Cohort       (Section 2 — per banner, summed)
+ Net Sales from the Non-Comparable Cohort   (Section 3 — per banner, summed)
= Net Sales from Stores                      (Section 5 — modeled store net sales)
+ §4 lines inside net sales                  (Section 4 — franchise / channel lines the issuer keeps inside its net sales line; channels ONLY if outside the comp base)
+ Other Revenue                              (Section 5 — plug)
─────────────────────────────────────────
= Net Sales                                  (Section 5 — reported merchandise line; laid ONLY when a separate revenue face line exists)
+ §4 lines that are their own face line      (Section 4 — membership fees, a reported Other revenue line, franchise revenue where reported separately)
─────────────────────────────────────────
= Total Revenue                              (Section 5 — reported total revenue; the anchor / foot)
```

For a single-revenue-line issuer the `Net Sales` row is not laid and the two
sums collapse into one: `Net Sales from Stores + every §4 line + Other = Total
Revenue`, where `Total Revenue` is the reported net sales line. Because **Other
Revenue is defined as the plug** (`Net Sales − Net Sales from Stores − the §4
lines inside net sales`), the components **sum to the reported figures exactly,
by construction** — that identity is the build's foot/check and must hold for
every banner-set and every period.

> **The retail difference from restaurants, stated once.** A restaurant company's
> reported revenue is very nearly all restaurant sales, so a two-cohort build plus
> a small franchise line covers it. **A retailer's reported net sales routinely
> contains large streams no store produced** — e-commerce fulfilled from a
> distribution center, wholesale shipments to third-party doors, licensing
> royalties, membership fee income, and (in a 53-week year) an extra week of
> everything. Section 4 exists to carry those **on their own lines** rather than
> letting them distort the per-store math or disappear into the plug. Getting §4's
> scope right — specifically, which channels are **inside** the comp base and which
> are **outside** it — is the difference between a retail model that means something
> and one that merely foots.

**Build the revenue lines in this order**, each beneath the cohort block(s) that
Section 1 laid down:

1. **Section 2 — Net Sales from the Comparable Cohort.** A per-banner recursive
   bridge: prior-year comparable-cohort net sales → net sales per comparable store
   → grow by the reported comparable-store sales rate → multiply by this year's
   comparable count.
2. **Section 3 — Net Sales from the Non-Comparable Cohort.** A blended net-sales-
   per-store figure × a **0.5 partial-year factor** × this year's non-comparable
   count.
3. **Section 4 — Franchise & License Revenue and Non-Store Channel Revenue.**
   Reported lines with YoY growth — **each included only when it exists and only
   when it sits outside the comparable base**.
4. **Section 5 — Other Revenue and Total Revenue.** `Other Revenue` is the plug
   that ties the modeled components to reported total revenue; `Total Revenue` is
   the reported figure the plug closes to — the grand-total foot.

**Conventions that apply to all of Sections 2 – 6 (read once):**

- **Annual columns only.** Like the cohort and store sections, the revenue build is
  **annual** (comparable-store sales and the cohort counts are reported annually,
  not by quarter). Use the **same annual period columns** (Col E onward, oldest →
  newest) the cohort block uses, so every revenue cell sits directly under the
  matching cohort / store cell.
- **Per banner, then consolidate.** Comparable and Non-Comparable net sales are
  built **one block per banner** — the same banner set, at the same level, in the
  same order, as the Section 1 cohort blocks — then summed into a consolidated
  subtotal. Where comp is reported at a coarser granularity than the cohort blocks,
  build the bridge at the **reported** granularity over the summed cohort counts
  (§1.10). Do **not** synthesize a single cross-banner comparable bridge unless
  only a consolidated comp % exists. Franchise & License, Non-Store Channel, and
  Other Revenue are **consolidated** lines (Sections 4 – 5).
- **Universe consistency.** Build each banner's revenue on the **company-operated**
  universe Section 1 used for its cohort (§1.9). The comparable / non-comparable
  **counts** this build multiplies are company-operated, so the **net sales** and
  **store** figures it divides by must be too. Mixing universes silently corrupts
  every per-store figure.
- **Reference Section 1 and the store roll-forward — do not re-derive counts.**
  Every store count this build needs already exists in the workbook: the comparable
  / non-comparable cohort counts in the **Section 1 cohort block** (referenced by
  the phrases "# of stores in the comparable cohort" / "in the non-comparable
  cohort" throughout this framework), and the EOP store counts / openings in the
  **store roll-forward**. Reference those cells with live `=` formulas; never
  hardcode a count.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (reported net sales, reported comp %, reported franchise /
  licensing / membership / digital / wholesale revenue, and the base-year
  lookbacks) are **input cells** (pale-green fill, dark-blue
  hyperlinked value linked to the filing); values taken from the 10-K because the
  deepKPI series is scaled, cross-tagged or missing are **10-K override cells**
  (gold fill, hyperlinked, with a citing comment). **Every other revenue cell is a
  live `=` formula** (black font, no fill) — per-store figures, the grown
  estimates, the cohort-revenue products, subtotals, the Other plug, and every YoY
  % row. Never hardcode a computed number.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §1.6, §2.3, §3.3,
  §4.3, §5.3, §6.2 and §6.3 — and in the `Units (Col D)` column of that section's
  formula table. Dollar rows show the placeholder `(USD in <scale>)`: the contract's
  Rule 2 supplies the scale, millions by default, thousands where the digit test puts a
  small filer. Three classifications are specific to this build:
  - **Section 1 is counts and two assumptions.** Every cohort row — the lookback inputs,
    the weighted year-of-opening rows, the optional removal row, `Total Non-Comparable
    Cohort`, `Total Comparable Cohort`, the reported-count memo — is whole stores,
    tagged `(stores)` — the noun of this comparable-*stores* build, used for every count
    row here regardless of what the issuer or deepKPI calls its units (stores,
    warehouses, clubs); the store roll-forward's fleet rows carry `(locations)` — and
    displayed with the counts format (the `ROUND(…, 0)` in §1.7 keeps them integers).
    The two month cells are `(months)`. `Stub-year fraction` is a pure fraction
    tagged `(x)`; show it with two decimals so a weight of 1/12 reads `0.08`, not `0.1`.
  - **Per-store money is `(USD millions per store)`; every other dollar row shares one
    scale.** `Net Sales per Comparable Store — prior yr`, `Estimated Net Sales per
    Comparable Store` and `Net Sales per Store — system avg` each divide a net-sales row
    in millions by a count in ones, so millions per store is the coherent scale — a
    reader can divide the two rows above and land on the figure (§7: a Dollar General
    store runs about `2.0` a year). Never round these rows to whole units; they are
    dollar figures, not store counts. All the other dollar rows — cohort net sales,
    channel lines, membership income, the plug, `Total Revenue` — take the one Rule 2
    scale: a scale mismatch between a channel line and the cohort rows is a defect no
    foot-check catches, because the plug absorbs it.
  - **Percent rows.** `Comparable-Store Sales Growth`, its Transactions / Average
    Transaction Amount / Average Unit Retail / Units per Transaction component rows, and
    every `YoY %` row are period-over-period changes, so they take the bare `(%)` the
    contract's Rule 5 reserves for that case. The memo percents name their denominator:
    `Memo: Comparable as % of total` is `(% of EOP Balance)`; the plug's ratio driver
    `Other Revenue — % of modeled revenue` is `(% of modeled revenue)` — it divides by the
    modeled components, never by a total that contains the plug (§5.1); `Memo: revenue mix by banner` is `(% of Net Sales
    from Stores)`.
- **Reading the layout blocks (§1.6, §2.3, §3.3, §4.3, §5.3, §6.2, §6.3).** Each row's
  annotation has two columns, left to right: the **Col D units tag in parentheses** —
  `(USD in <scale>)` means the contract's Rule 2 sets the money scale; every other tag
  is written as it goes in the cell — and the note in **square brackets**: `[INPUT …]`
  for a pulled value (deepKPI, or a 10-K override), `[FORMULA …]` for a computed row,
  plus styling (`SUM-BAR`, `italic`) and any condition on the row's presence. Section
  sub-headers, `⤷` zone labels, banner headers and `<Banner 2> …` repeat markers carry no
  tag. In §6.2 a row with no bracketed note repeats, for that banner, the row of the
  section named on the sub-header above it. The two `Notes` blocks (§5.5, §7) are note
  text, not data rows, and carry no tags.
- **Label / comment / spacing discipline (same as §1.6).** Col C labels are **plain
  descriptive text**; the operand recipe for each formula row goes in a **cell
  comment on the Col C label cell** (author `Revenue Build`), not in the visible
  label. Indentation, bold / border, and the one-blank-row-between-blocks rule
  follow `../../../../_common/revelata-excel-styling-rules.md` exactly as the cohort
  section does.
- **No note rows inside the build — every note goes to the bottom.** Basis
  statements (universe, comp application level, whether digital is inside the comp
  base, the 0.5 partial-year factor, channel include / omit reasons, 10-K overrides,
  53-week years) are **not** written as italic-gray rows beneath section
  sub-headers. They are collected **once**, at the very bottom of the build, in the
  **Notes block** (§5.5). Nothing gray is interleaved between the revenue rows: a
  section sub-header is followed **immediately** by its first line item, so each
  block reads as one uninterrupted stack of numbers.

- **Indentation — real cell indent, never leading spaces.** Every indent level in
  this build — "base indent", "indent once", "indent twice", "indent three" — is
  the cell's **actual indent property**: openpyxl `Alignment(indent=n)` with
  `indent=0`, `1`, `2`, `3`, the equivalent of Excel's **Home → Increase Indent**
  (`Alt, H, 6`). **Never** pad the label string with leading spaces. Padding is
  prohibited because:

  - The block / banner-header underline (`Font(underline="single")`) draws under
    the padding characters and produces a **ragged rule running left of the text**;
    a real indent shifts the label without adding any underline-able characters.
  - A padded label breaks `MATCH` / `VLOOKUP` / `XLOOKUP` against it — which
    matters here, where per-banner blocks repeat the same line-item names and the
    §6 consolidated table references them by label.
  - The spaces are **invisible in the Excel UI**, so a mis-padded row cannot be
    spotted or corrected by the user, and Increase/Decrease Indent will not clear
    it.

  When setting a cell's `Alignment`, **keep the existing `horizontal` / `vertical`
  settings and add `indent=n`** — do not replace the whole `Alignment` object:

  ```python
  # right
  c = ws["C42"]; c.value = "Net Sales per Store — system avg"   # no padding
  a = c.alignment
  c.alignment = Alignment(horizontal=a.horizontal, vertical=a.vertical, indent=2)

  # wrong
  c.value = "    Net Sales per Store — system avg"              # prohibited
  ```

  **A banner or block header sits one level shallower than its own line items**,
  bold + underlined, with their total back at its level — the styling rules' indent
  hierarchy, which the renderer applies to every data row from the row's kind; a build
  gives an indent only to its headers. The ASCII row maps throughout this file draw
  the hierarchy with whitespace **for legibility only** — those spaces are diagram,
  not data.

The sub-sections below specify each component cell-by-cell. Build them in order;
do not add revenue lines outside this framework.

---

## Section 2 — Net Sales from the Comparable Cohort

This section converts each banner's **Comparable Cohort count** (from §1) into
**comparable-cohort net sales dollars** by carrying prior-year net sales per
comparable store forward at the reported comparable-store sales rate. It is built
**one block per banner** (or per comp-reporting level, §1.10), directly beneath
that banner's Section 1 cohort block, then summed into a consolidated
comparable-revenue subtotal.

### 2.1 — The bridge and its recursion

For each banner and each period N, comparable-cohort net sales is built from
**five ordered rows**, exactly mirroring the framework:

1. **Previous Year's Comparable-Cohort Net Sales** — the comparable-cohort net
   sales that the *prior* period produced (see the recursion and base-year seed
   below).
2. **Net Sales per Comparable Store — prior year (NSCS)** =
   `Previous Year's Comparable-Cohort Net Sales ÷ # stores in the previous year's
   comparable cohort`. The denominator is the **prior period's** `Total Comparable
   Cohort` count from §1.
3. **Comparable-Store Sales Growth** — the reported comp-sales rate for the banner
   and period (§2.2 covers the optional Transactions / Average Ticket
   decomposition).
4. **Estimated Net Sales per Comparable Store** = `NSCS × (1 + comp %)`.
5. **Net Sales from the Comparable Cohort** = `Estimated Net Sales per Comparable
   Store × # of stores in the comparable cohort` — the **current** period's
   `Total Comparable Cohort` count from §1.

**The recursion (why this chains cleanly).** Define the rows for period N as
above. Then `NSCS(N) = PrevCompSales(N) ÷ CompCount(N−1)`. If — as specified below
— `PrevCompSales(N)` is set equal to the **prior period's row 5** (`Net Sales from
the Comparable Cohort` of period N−1), and that row 5 equals
`EstSalesPerComp(N−1) × CompCount(N−1)`, then:

> `NSCS(N) = EstSalesPerComp(N−1) × CompCount(N−1) ÷ CompCount(N−1) =
> EstSalesPerComp(N−1)`

i.e. **this year's prior-net-sales-per-comparable-store equals last year's
estimated net sales per comparable store**, and the per-store figure simply
**compounds by the comp rate each year**:
`EstSalesPerComp(N) = EstSalesPerComp(N−1) × (1 + comp%_N)`. The cohort *count* can
grow year to year (new stores mature into the comparable base); the bridge handles
that by multiplying the per-store figure by the **current** comparable count in
row 5. This recursion is internally consistent and **only the base year needs a
seed**.

**Base-year (leftmost column) seed — DOLLAR comparable-cohort net sales only; NO
blended proxy (STRICT).** The leftmost period column has no prior modeled
comparable net sales, so its row 1 and the row-2 denominator must be seeded from
reported **comparable-cohort dollars** — the exact dollar requirement the router
enforced before routing here (`../retail.md`, Section A, situations 1 & 2).
**Do NOT seed the base year from blended company-wide figures.**

- **Previous Year's Comparable-Cohort Net Sales (base column)** = the **prior
  fiscal year's comparable-cohort dollar net sales**, obtained one of the two ways
  the router required:
  1. **Directly** — the issuer reports the comparable cohort's **dollar net sales**
     for the prior fiscal year → use it as-is (deepKPI / 10-K input). *(Dollar
     General: "In 2024, our 19,633 same-stores accounted for sales of $38.8
     billion.")*, **or**
  2. **Backed into** — from the reported comparable-store sales **%** and the
     reported **dollar change attributable to the comparable cohort** (the
     net-sales walk line): `prior comparable net sales = dollar change ÷ growth %`
     (a live formula over two inputs).
  > **FORBIDDEN:** seeding row 1 with the **prior year's total net sales** (blended
  > across all stores and all channels). In retail that figure is wrong **twice
  > over**: it includes non-comparable (newly opened, still-ramping) stores, which
  > **understates** true comparable per-store sales; **and** it includes digital,
  > wholesale, licensing and membership-fee revenue that **no store produced**,
  > which **overstates** per-store sales in the opposite direction. The two errors
  > do not cancel — they make the seed unfalsifiable, and the whole discrepancy
  > lands in the Other-Revenue plug. This is precisely the invalid assumption the
  > router's strict dollar requirement exists to prevent. The "any error is
  > absorbed by the Other plug" rationale does **not** license this shortcut: a plug
  > that hides a structural mis-seed is a defect, not a feature.
- **# stores in the previous year's comparable cohort (base-column denominator)** =
  the prior fiscal year's **comparable** store count — the cohort's own count, e.g.
  the issuer's reported comparable / same-store count for that year (Dollar
  General: **19,633**). Pull it as an input. **Do NOT** use the prior year's
  **total** store count as a proxy: that is the same comparable-vs-non-comparable
  conflation on the denominator side. (When situation 1 supplies the cohort's
  dollar net sales directly, the NSCS denominator must still be the **comparable**
  count, not total stores.) The count comes from the §1 base-year seed row
  `Comparable cohort — one fiscal year before the window` (§1.7, zone a′): the
  reported FY(M−1) comparable count where the issuer discloses one, otherwise the
  cohort formula shifted one year left over the FY(M−1) period-end count and the
  FY(M−1−k\*) openings. Do not substitute total stores, and do not add a column.

**If neither situation 1 nor situation 2 is available** — you can neither read the
prior comparable cohort's dollars directly nor back into them from a reported
`dollar change ÷ growth %` — then **STOP. Do not improvise a blended-average
seed.** The company did not actually satisfy the comparable-stores routing
criteria (`../retail.md`, Section A); this build should not have been selected.
Return the **`ABORTED`** hand-back ("Aborting the build", above); the router
re-routes.

For **every non-base column**, row 1 and the row-2 denominator are **live
formulas** referencing the prior column (no new inputs): row 1 = prior column's
`Net Sales from the Comparable Cohort`; denominator = prior column's `Total
Comparable Cohort` (§1).

### 2.2 — The comp rate and its optional decomposition

The bridge driver is the **reported comparable-store sales rate** for the banner
and period — an input (e.g. `Consolidated same-store sales for stores open at
least 13 full fiscal months`, `Comparable Sales Change for <Banner> Global`,
`Comparable sales - Annual`). Pull the rate on the **same universe and banner** the
cohort was built on, at the **granularity it is reported** (§1.10). Read the
`unit` field: the comp series you want is `percent`; the same concept in `USD` is
the dollar series §2.1 situation 1/2 uses, and confusing the two is a common miss.

**Decompose only when the issuer discloses it.** Retailers commonly break comp
sales into **transactions / traffic** and **average transaction amount (average
ticket / basket)**, and sometimes split the ticket further into **average unit
retail (AUR)** and **units per transaction (UPT)**. When that granularity is
disclosed, lay each disclosed component as its **own input row** beneath the total
comp row:

- `Comp — Transactions / Traffic` (input)
- `Comp — Average Transaction Amount` (input) — and, if further disclosed:
  - `Comp — Average Unit Retail` (input)
  - `Comp — Units per Transaction` (input)

*(Dollar General fiscal 2025 discloses exactly the first pair: "a 1.6% increase in
customer traffic and a 1.4% increase in average transaction amount", and then
attributes the ticket move to "higher average item retail prices and flat items
per transaction" — the AUR / UPT split.)*

Keep the **total reported comp rate** as the single value that drives row 4
(`NSCS × (1 + comp%)`). Treat the components as **memo / disclosure rows**, not as
additional bridge drivers — do not multiply the per-store figure by each component.
If the issuer discloses the components but **not** a total, compute the total on the
**same basis the issuer uses**: most present the pieces as **additive
contributions** (`comp ≈ Transactions% + Average Transaction Amount%`, and
`Average Transaction Amount% ≈ AUR% + UPT%`), so sum them as a formula and add a
comment noting the additive convention (the exact relationship is multiplicative,
`(1+traffic)(1+ticket) − 1`, but issuers almost always present additive
contributions). **If no decomposition is disclosed, lay down only the single total
comp row** — do not invent a split.

**Two retail-specific cautions on the comp rate:**

- **Digital inside the comp base changes what row 5 means.** If §1.1 established
  that the issuer includes online sales in comparable sales, then rows 1–5 measure
  the comparable cohort **plus** the digital channel, and §4.2 must **omit** the
  separate digital line. Record that in the **Notes block** (§5.5): *"Revenue:
  comparable sales <include / exclude> online sales; the comparable-cohort line
  therefore <carries the digital channel and no separate digital line exists /
  is stores only>."* Otherwise a later reader will see `Net Sales from the
  Comparable Cohort` and reasonably assume it is stores only.
- **Channel-split comp rates are enrichment, not the driver.** Where an issuer
  publishes `Comparable store sales — retail` alongside `Comparable digital sales`,
  the **headline** comp rate is the driver; the channel rates are memo rows. Never
  drive the bridge off a channel rate that covers only part of the base.

### 2.3 — Per-banner comparable block layout

For **each banner** (same set and order as §1, or the comp-reporting level per
§1.10), lay one comparable-revenue block directly beneath that banner's Section 1
cohort block. All label text in Col C; period values Col E onward (annual):

```
Comparable Cohort Net Sales                                                                        [section sub-header: bold + underlined, size 12, indent 0]
<Banner>                                                                                           [banner header: bold + underlined, indent 0]
    Previous Year's Comparable-Cohort Net Sales                         (USD in <scale>)           [base col: INPUT; else FORMULA = prior col row 5]
    Net Sales per Comparable Store — prior yr                           (USD millions per store)   [FORMULA = row above ÷ prior-yr comp count §1]
    Comparable-Store Sales Growth                                       (%)                        [INPUT; italic]
      Comp — Transactions / Traffic                                     (%)                        [INPUT — only if disclosed]
      Comp — Average Transaction Amount                                 (%)                        [INPUT — only if disclosed]
      Comp — Average Unit Retail                                        (%)                        [INPUT — only if ticket split disclosed]
      Comp — Units per Transaction                                      (%)                        [INPUT — only if ticket split disclosed]
    Estimated Net Sales per Comparable Store                            (USD millions per store)   [FORMULA = prior-yr per-store × (1 + comp %)]
    Net Sales from the Comparable Cohort                                (USD in <scale>)           [FORMULA = est per store × current comp count §1; bold, SUM-BAR]
<Banner 2> …                                                                                       [repeat the five-row block]
Total Net Sales from the Comparable Cohort                              (USD in <scale>)           [FORMULA = Σ each banner's row 5; bold, SUM-BAR]
```

**Row-spacing rule (strict, mirrors §1.6):** within a banner's block there are
**zero blank rows** from `Previous Year's Comparable-Cohort Net Sales` through
`Net Sales from the Comparable Cohort`. One blank spacer row separates one
banner's block from the next. One blank row precedes `Total Net Sales from the
Comparable Cohort`. The optional comp component rows sit **immediately** beneath
the total comp row (no blank row above them).

**No note rows here.** The section sub-header is followed **immediately** by the
first banner header — no italic-gray rows in between. The universe (§1.9), the
level the comp rate is applied at (§1.10) and whether digital is inside the comp
base (§1.1, §2.2) are recorded in the **Notes block** at the bottom of the build
(§5.5), each in the wording its section gives.

**Indentation / fonts / borders (per the styling contract):** the `Comparable Cohort
Net Sales` section sub-header is bold + underlined, size 12, at `Alignment(indent=0)`
— the one sub-header treatment every section uses; the banner header is bold +
underlined at **base indent** (`indent=0`); the five line items are at **`indent=2`**; comp component memo
rows are at **`indent=3`** and italic; `Net Sales from the Comparable Cohort` (row 5)
and `Total Net Sales from the Comparable Cohort` are bold with the SUM-BAR. Number
formats follow each row's Col D tag (see "Number format and units" in the conventions
list above).

Those indent levels are set with `Alignment(indent=n)` — the cell's real indent
(`Alt, H, 6`) — **never** with leading spaces in the label. The whitespace in the
row map above is diagram only; the stored `cell.value` for every one of the five
line items begins at its first non-space character.

**Multi-banner parents:** the per-banner five-row block above is unchanged, but for
a parent with 2+ banners the canonical workbook organization groups each banner's
**entire** revenue build together (comparable + non-comparable) and moves the
`Total Net Sales from the Comparable Cohort` consolidated total into a single
consolidated revenue table — see **§6**. Single-banner retailers keep the layout
exactly as shown here.

### 2.4 — The formulas (cell-by-cell) for the comparable bridge

Row labels are the **plain Col C text**. "Prior col" = the period column
immediately to the left; "§1 comp count (col X)" = that banner's `Total Comparable
Cohort` cell in column X of the Section 1 cohort block (or the `SUM` of the
regional cohort cells the comp rate covers, per §1.10).

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Previous Year's Comparable-Cohort Net Sales` | | `(USD in <scale>)` | **DOLLAR comparable-cohort net sales only** (§2.1): situation 1 **input** (reported prior-FY comparable-cohort dollars), or situation 2 `= <reported dollar change attributable to comparable stores> ÷ <comp %>`. **Never** the prior-FY total net sales. | `= <prior col 'Net Sales from the Comparable Cohort'>` | `"Prior-yr comparable-cohort DOLLAR net sales: the issuer's reported figure, or the reported dollar change divided by the comp rate. NOT blended total net sales; else = prior col row 5."` |
| `Net Sales per Comparable Store — prior yr` | | `(USD millions per store)` | `= <Previous Year's …Net Sales> ÷ <§1 'Comparable cohort — one fiscal year before the window', base col>` (the base-year seed row, §1.7 zone a′ — **not** total stores) | `= <Previous Year's …Net Sales> ÷ <§1 comp count (prior col)>` | `"= prior comparable-cohort net sales ÷ prior-yr COMPARABLE count. Base yr: the cohort block's base-year seed row (reported FY(M−1) comparable count, else the shifted cohort formula; NOT total stores)."` |
| `Comparable-Store Sales Growth` | | `(%)` | **input** % (reported comp), or `= Transactions% + Average Transaction Amount%` if only components disclosed | same | `"Reported comparable-store sales %, <banner>, <universe>, applied at <level>. Drives the bridge."` |
| `Comp — Transactions / Traffic` *(only if disclosed)* | DATA_DEPENDENT | `(%)` | **input** % | same | *(no comment — input row; provenance via hyperlink)* |
| `Comp — Average Transaction Amount` *(only if disclosed)* | DATA_DEPENDENT | `(%)` | **input** % | same | *(no comment — input row)* |
| `Comp — Average Unit Retail` / `Comp — Units per Transaction` *(only if ticket split disclosed)* | DATA_DEPENDENT | `(%)` | **input** % each | same | *(no comment — input rows; memo: AUR + UPT ≈ Average Transaction Amount)* |
| `Estimated Net Sales per Comparable Store` | | `(USD millions per store)` | `= <Net Sales per Comparable Store — prior yr> × (1 + <Comparable-Store Sales Growth>)` | same | `"= prior-yr net sales per comparable store × (1 + comp %). Compounds the per-store figure by this yr's comp."` |
| `Net Sales from the Comparable Cohort` | | `(USD in <scale>)` | `= <Estimated Net Sales per Comparable Store> × <§1 comp count (this col)>` | same | `"= est. net sales per comparable store × this yr's comparable count (from the cohort block)."` |
| `Total Net Sales from the Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each banner's `Net Sales from the Comparable Cohort` `)` | same | `"Σ comparable-cohort net sales across all banners."` |

### 2.5 — Sourcing the base-year lookback inputs

Only the **base (leftmost) column** needs new pulls for this section; all other
columns are formulas. The base-year seed must be **comparable-cohort dollars**
(§2.1) — not blended company-wide figures. Pull, per banner:

- **Prior-FY comparable-cohort dollar net sales** — obtained via §2.1 situation 1
  or 2:
  - *Situation 1:* the issuer's reported **comparable-cohort dollar net sales** for
    the fiscal year immediately before the build window (e.g. for a FY2022–FY2025
    window, pull FY2021). Look for `Annual net sales from same-stores`,
    `Net sales from comparable stores`, `Revenue from comparable stores`, or the
    MD&A sentence pattern *"our X same-stores accounted for sales of $Y"*.
  - *Situation 2:* the reported **dollar change attributable to comparable stores**
    (the net-sales walk line — `Change in net sales from comparable stores`,
    `Change in Revenue from Comparable Store Sales`) and the reported **comp %** for
    that year; the seed is then `dollar change ÷ growth %` (a live formula over
    those two inputs).
  **Do NOT** substitute the banner's prior-FY **total net sales** — that is the
  forbidden seed (§2.1). If neither situation is obtainable, return the
  **`ABORTED`** hand-back per §2.1; do not seed from blended net sales.
- **Prior-FY COMPARABLE store count** (the per-store denominator for the base
  column) — not pulled here. It is the §1 base-year seed row `Comparable cohort
  — one fiscal year before the window` (§1.7 zone a′), whose inputs §1.8 lists:
  the reported FY(M−1) comparable count where disclosed, else the FY(M−1)
  period-end count and FY(M−1−k\*) openings. **Do NOT** use the prior-FY
  **total** store count as a "comparable ≈ total" proxy.

Use the **filing / `search_kpis`** path against the shared inventory (do not re-run
`list_kpis`). Where a banner or its sales series did not exist in the pre-window
year, use **zero (display as a dash)**, not blank; a zero comparable base means
that banner's base-column comparable net sales is simply zero — note that rather
than forcing a `÷ 0` division.

### 2.6 — Banner-level vs. consolidated net sales

The comparable bridge is **per banner** because comp and the cohort counts are per
banner. This requires **banner-level net sales**:

- **If the issuer discloses banner-level net sales** (many multi-banner retailers
  report net sales by banner or by reportable segment), build one comparable block
  per banner as above.
- **If only consolidated net sales are disclosed**, build a **single consolidated
  comparable block** instead: row 1 seed = prior-FY consolidated comparable-cohort
  dollars; the per-store denominator = the **sum of the banners'** `Total
  Comparable Cohort` counts (a formula summing the §1 per-banner comparable
  counts); comp % = the reported **consolidated** comp; row 5 multiplier = the
  summed comparable count. State in the universe note that the comparable bridge is
  consolidated because banner-level net sales are not disclosed. (The §1 cohort
  blocks remain per banner; only the revenue bridge consolidates.)
- **If net sales are disclosed by banner but comp only banner-global while the
  cohort is banner × region** (the Gap shape), build the bridge **per
  banner-global** — one block per banner, comparable count = `SUM` of that banner's
  regional cohort cells (§1.10). This is the middle case and it is common; do not
  force it into either extreme.

Either way the section ends in a single `Total Net Sales from the Comparable
Cohort` line that feeds Sections 5 – 6.

### 2.7 — Pre-delivery checklist (Comparable Cohort net sales)

- [ ] One comparable block **per banner** (or per comp-reporting level §1.10, or
      one consolidated block §2.6), in the same order as the §1 cohort blocks, each
      on the **same universe** §1 used for that banner.
- [ ] The five rows appear in order: `Previous Year's Comparable-Cohort Net Sales`
      → `Net Sales per Comparable Store — prior yr` → `Comparable-Store Sales
      Growth` → `Estimated Net Sales per Comparable Store` → `Net Sales from the
      Comparable Cohort`.
- [ ] **Base column (STRICT — §2.1):** row 1 is the prior-FY **comparable-cohort
      dollar net sales** — situation 1 (reported comparable-cohort dollars) or
      situation 2 (`reported dollar change attributable to comparable stores ÷
      comp %`) — and is **NOT** the prior-FY total net sales; the per-store
      denominator is the prior-FY **comparable** store count, **NOT** the total
      store count. If neither situation 1 nor 2 is available, the build
      **returned the `ABORTED` hand-back** rather than seeding from a blended proxy.
      **All other columns:** row 1 = `prior col row 5` and the denominator =
      `§1 Total Comparable Cohort (prior col)` — both live formulas, **no** new
      inputs.
- [ ] The per-store denominator references the **prior** period's comparable count;
      the row-5 multiplier references the **current** period's comparable count
      (both from the §1 cohort block) — not reversed.
- [ ] The comp rate pulled is the series with `unit: percent` (not the USD series),
      on the right banner and universe, applied **once** at the reported
      granularity (§1.10) — never allocated across regions or averaged.
- [ ] Transactions / Average Transaction Amount / AUR / UPT rows appear **only if
      disclosed**, as memo input rows that do **not** re-drive the bridge. No
      invented decomposition.
- [ ] **No italic-gray note rows sit between the section sub-header and the first
      banner block.** The **universe**, the **comp application level**, and
      **whether digital is inside the comp base** are recorded in the Notes block
      (§5.5) in their sections' wording — the last of which must agree with
      §4.2's include/omit decision.
- [ ] `Estimated Net Sales per Comparable Store = prior-yr per store × (1 + comp %)`
      and `Net Sales from the Comparable Cohort = that × current comparable count`
      are **live formulas**; per-store dollar rows are **not** rounded to whole
      units.
- [ ] `Total Net Sales from the Comparable Cohort` = `SUM` of the per-banner row-5
      cells (formula; SUM-BAR).
- [ ] Every dollar row shares one display scale, and each row's **Col D** units tag
      says which.
- [ ] Row-spacing, plain Col C labels, and formula-in-comment rules match §1.6; number
      formats follow each row's Col D tag.
- [ ] After recalculation there are **zero formula errors**, and the recursion reads
      correctly (per-store net sales compounds by the comp rate; the count change
      flows through the current-year multiplier).

---

## Section 3 — Net Sales from the Non-Comparable Cohort

This section values the **Non-Comparable Cohort** — the stores that are too new to
be in the comparable base (the §1 `Total Non-Comparable Cohort` count). New stores
open at different points in the year, so on average they operate only **part** of
the fiscal year; the framework values them at **half a typical store's annual net
sales**. It is built **one block per banner**, beneath that banner's comparable
block, then summed.

### 3.1 — The two rows and the 0.5 partial-year factor

For each banner and period N, non-comparable net sales is built from **two rows**:

1. **Net Sales per Store — system average** = `Store Net Sales ÷ Total Stores` for
   the banner on its cohort universe — a blended average annual net sales per store
   across the whole banner. Carry a **YoY growth** memo row beneath it.
2. **Net Sales from the Non-Comparable Cohort** =
   `Net Sales per Store × 0.5 × # of stores in the non-comparable cohort`, where
   the count is the **current** period's `Total Non-Comparable Cohort` from §1.

**Why the 0.5 factor.** Non-comparable stores were opened across the fiscal year —
some early, some late — so on average a non-comparable store was open for roughly
**half** the year and therefore earned about **half** of a mature store's full
annual net sales. Multiplying the blended per-store figure by **0.5** before
applying the non-comparable count converts a full-year sales rate into the
**partial-year** sales those ramping stores actually contributed. **One stated
simplification:** the factor is applied to the whole non-comparable cohort, so where
the issuer's anchor makes last year's openings non-comparable for a second year (a
"before the beginning of the period" anchor), those stores — open for the full
current year — are also halved; the §5 `Other Revenue` plug absorbs the difference
historically.

> **Retail caveat, deliberately not acted on.** Retail opening cadence is often
> **seasonal** — apparel and specialty chains cluster openings ahead of
> back-to-school and holiday, which would push the true average part-year factor
> below 0.5; other formats open evenly all year, which lands near 0.5 exactly. **Do
> not adjust the 0.5 per company.** It is a deliberate, uniform simplification
> across every company in the build, so that cohort economics stay comparable
> across issuers, and any resulting imprecision is absorbed by the §5 Other plug.
> Note the seasonality in the block's comment where the issuer's opening cadence is
> visibly clustered, but leave the factor at 0.5.

### 3.2 — Defining Net Sales per Store on the right universe *and the right channel*

Define `Net Sales per Store — system average` on the **same universe as the
cohort** (§1.9, the same universe Section 2 used for the banner) **and on the
store channel only**:

- **Numerator — "Store Net Sales":** the banner's **company-operated store net
  sales**, **not** total consolidated net sales. In retail this is the single most
  important rule in the section, because reported net sales routinely bundles
  revenue no store produced:
  - **Exclude e-commerce / digital net sales** where the issuer reports them
    separately and they are fulfilled outside the store base. *(If digital is
    inside the comp base per §1.1, it is already inside §2's bridge, and it must
    still be excluded here — otherwise it is counted in both the comparable bridge
    and the per-store figure.)*
  - **Exclude wholesale net sales** — shipments to third-party doors are a
    different customer and a different fleet.
  - **Exclude licensing and royalty revenue** — no store produced it.
  - **Exclude membership / fee income** — club and warehouse retailers earn it on
    the membership base, not on a per-store transaction; it belongs on its own line
    (§4.2).
  - **Exclude franchise revenue** — modeled separately in §4.1.
  Including any of these overstates net sales per store, which then overstates the
  non-comparable contribution and understates the plug.
- **Denominator — "Total Stores":** the banner's **Company-Operated EOP Balance**
  from the store roll-forward (the same universe). Reference the cell with a
  formula.
**When the issuer does not split net sales by channel.** Some retailers report only
a single consolidated net-sales line. Then:

1. Use the reported net sales as the numerator, **and say so in the cell comment**
   (*"Channel split not disclosed; numerator is total net sales and therefore
   includes any non-store channels — per-store figure is an upper bound"*).
2. Do **not** estimate a channel split. The §5 plug absorbs the difference, and the
   plug's diagnostic memo (§5.1) makes its size visible.
3. Where a **digital dollar series exists** but no explicit "store net sales" line
   does (the common case — e.g. Gap reports `Online Sales` in USD alongside total
   net sales), **derive** the numerator as
   `= <total net sales> − <online sales> [− <wholesale> − <licensing> −
   <membership fee income>]` as a **live formula over input cells**, and comment
   it. A derived store-sales line built from reported components is far better than
   an undisclosed-split fallback.

So `Net Sales per Store` is a per-banner **blended average unit volume** (it
averages over both comparable and non-comparable stores). Using the *blended*
average — rather than trying to isolate a "new-store-only" volume — is intentional:
it is the figure the framework specifies, and any resulting imprecision in the
comparable / non-comparable split is absorbed by the **Other Revenue** plug (§5),
which keeps the build footed to reported total revenue.

**YoY growth row.** Beneath the `Net Sales per Store` row, add an italic `YoY %`
memo row = `<this col> ÷ <prior col> − 1` (blank/dash in the base column, which has
no prior period). It shows how blended net sales per store is trending and is a
quick sanity check — it should track roughly with the comp rate plus mix-of-new-
stores effects. **A `YoY %` that diverges sharply from the comp rate is a signal**,
usually that the numerator picked up a channel it should not have, or that a
53-week year is inflating one column (§4.4).

### 3.3 — Per-banner non-comparable block layout

```
Non-Comparable Cohort Net Sales                                                                    [section sub-header: bold + underlined, size 12, indent 0]
<Banner>                                                                                           [banner header: bold + underlined, indent 0]
    Store Net Sales                                                     (USD in <scale>)           [INPUT, or FORMULA = total net sales − non-store channels]
    Net Sales per Store — system avg                                    (USD millions per store)   [FORMULA = store net sales ÷ company-operated EOP]
      YoY %                                                             (%)                        [FORMULA = this col ÷ prior col − 1; italic]
    Net Sales from the Non-Comparable Cohort                            (USD in <scale>)           [FORMULA = per-store × 0.5 × non-comp count §1; bold, SUM-BAR]
<Banner 2> …                                                                                       [repeat]
Total Net Sales from the Non-Comparable Cohort                          (USD in <scale>)           [FORMULA = Σ each banner's row; bold, SUM-BAR]
```

Spacing / indentation mirror §1.6 and Section 2: banner header bold at **base
indent** (`indent=0`); the line items at **`indent=2`**; the `YoY %` memo at
**`indent=3`** and italic, immediately under the per-store row (no blank row above
it); zero blank rows within a banner block; one blank spacer between banner blocks;
one blank row before the consolidated total. As everywhere in this build, those
levels are `Alignment(indent=n)` on the Col C cell (`Alt, H, 6`) — **never**
leading spaces in the label string.

**No note rows here either.** The section sub-header runs straight into the first
banner header. The universe (§1.9), the store-only numerator (§3.2) and the **0.5
partial-year factor** are recorded in the **Notes block** at the bottom of the
build (§5.5): *"Revenue: net sales per store divides store net sales only
(excluding <digital, wholesale, licensing, membership>) by company-operated
stores."* and *"Revenue: new stores are assumed open half the year on average;
the 0.5 factor is uniform across companies."* The 0.5 also stays visible in the
`Net Sales from the Non-Comparable Cohort` cell comment, per §3.4.

**Multi-banner parents:** as in §2.3, the per-banner block is unchanged, but for a
2+ banner parent these non-comparable rows sit inside each banner's grouped build
and the `Total Net Sales from the Non-Comparable Cohort` total moves into the
consolidated revenue table — see **§6**.

### 3.4 — The formulas (cell-by-cell) for the non-comparable block

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Store Net Sales` | | `(USD in <scale>)` | **input** where the issuer reports a store-channel net-sales line; otherwise `= <total net sales, this col> − <online sales> [− <wholesale> − <licensing> − <membership fee income>]`; otherwise (no split at all) `= <total net sales, this col>` | `"Store-channel net sales only. Excludes digital / wholesale / licensing / membership. If undisclosed, total net sales used; the per-store figure is then an upper bound."` |
| `Net Sales per Store — system avg` | | `(USD millions per store)` | `= <Store Net Sales, this col> ÷ <banner Company-Operated EOP Balance, store roll-forward, this col>` | `"= store net sales ÷ company-operated stores (same universe as the cohort block). Blended avg net sales per store."` |
| `YoY %` | | `(%)` | base col: blank/dash; else `= <this col> ÷ <prior col> − 1` | `"YoY change in blended net sales per store. Should track the comp rate plus new-store mix."` |
| `Net Sales from the Non-Comparable Cohort` | | `(USD in <scale>)` | `= <Net Sales per Store — system avg, this col> × 0.5 × <§1 Total Non-Comparable Cohort, this col>` | `"= net sales per store × 0.5 × non-comparable count (from the cohort block). 0.5 = avg part-year for stores opened across the year."` |
| `Total Net Sales from the Non-Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each banner's `Net Sales from the Non-Comparable Cohort` `)` | `"Σ non-comparable-cohort net sales across all banners."` |

The `Store Net Sales` row is the **same figure family** Section 2 seeds from — keep
them consistent. Where that figure is an input, reference the input cell; where it
is derived, keep it a **live formula over input cells** so every operand carries
provenance. The **per-store cell itself is always a formula** (a ratio of two
cells), never a hardcoded number. The `0.5` is a literal constant inside the
formula (a framework assumption, not a reported value); state it in the cell
comment.

### 3.5 — Banner-level vs. consolidated (same rule as §2.6)

If banner-level net sales are not disclosed, build the non-comparable block at the
**consolidated company-operated level**: `Net Sales per Store` = consolidated store
net sales ÷ consolidated `Company-Operated EOP Balance` (the `Total — all banners`
block), and the multiplier = the **sum** of the banners' `Total Non-Comparable
Cohort` counts. Keep the universe and the channel exclusions consistent with
Section 2's consolidation choice.

### 3.6 — Pre-delivery checklist (Non-Comparable Cohort net sales)

- [ ] One non-comparable block **per banner** (or consolidated per §3.5), same
      banner order and same universe as Sections 1 – 2.
- [ ] `Store Net Sales` is the **store channel only** — digital, wholesale,
      licensing, membership fee income and franchise revenue are **excluded**,
      either because the issuer reports a store line directly or because the row is
      a live subtraction formula over reported components. Where no split exists at
      all, the cell comment says so explicitly.
- [ ] `Net Sales per Store — system avg` = banner **store net sales ÷ banner
      Company-Operated EOP Balance** — numerator and denominator on the **same
      universe**.
- [ ] A `YoY %` memo row sits directly beneath the per-store row (formula; dash in
      the base column), and its value is plausible against the comp rate.
- [ ] `Net Sales from the Non-Comparable Cohort = Net Sales per Store × 0.5 ×
      non-comparable count (§1)` — the **0.5 factor is present and unmodified**, the
      count is the **current** period's `Total Non-Comparable Cohort`, and the cell
      is a **live formula**.
- [ ] `Total Net Sales from the Non-Comparable Cohort` = `SUM` of the per-banner
      rows (formula; SUM-BAR).
- [ ] Row-spacing / label / comment rules match §1.6; number formats follow each row's
      Col D tag.
- [ ] **No italic-gray note rows** between the section sub-header and the first
      banner block — the universe, the store-only numerator and the 0.5 factor are
      recorded in the Notes block (§5.5) in the §1.9 and §3.3 wording.
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Franchise & License Revenue and Non-Store Channel Revenue (conditional)

This section carries the revenue streams the two cohort sections do **not**
explain. **Every line here is conditional** — include a line only when the issuer
reports that stream **and** it sits **outside** the comparable base. State the
include / omit decision for **each** line in one sentence, citing the series (or
its absence) and the §1.1 comp-base finding.

> **This section is where retail diverges most from restaurants, and where the
> build most often goes quietly wrong.** A restaurant build has one conditional
> line (franchise). A retailer can have four or five, they can be very large
> relative to store sales, and one of them (digital) may already be inside §2's
> bridge. Work the decision rule in §4.2 line by line; do not batch it.

### 4.1 — Franchise & License Revenue

**Include only if the shared KPI inventory carries a franchise or license revenue
series** (the captions listed below). An issuer with no such series reports no
franchise revenue, so this line is **omitted entirely**. The gate is on
**reported revenue, not on unit counts**: whether the store roll-forward laid a
**Franchised & Licensed** roll decides nothing here — an issuer that reports
royalty or license revenue but no partner-store counts still gets the line.

Franchise & license revenue is **not** store net sales — it is the **royalties,
franchise and license fees**, and sometimes **wholesale shipments to franchise
partners**, that the company collects from partner-operated stores. It is reported
as its own line (or inside a combined "other revenue" line) and is
**consolidated** — never split into the comparable / non-comparable cohort math,
which applies only to company-operated stores. So this is a **single consolidated
line** (plus a YoY memo), not a per-banner cohort build.

**Placement.** If the issuer reports franchise revenue **per banner**, put each
banner's line inside that banner's block and include it in the banner subtotal
(§6.2). If it is reported **only at the consolidated level** — the common retail
case, and the case for The Gap, Inc., whose franchised fleet is reported at parent
level — place a single line in the consolidated table (§6.3) and **omit** it from
the per-banner blocks. It must appear **exactly once**.

Series to look for: `Franchise revenue`, `Franchise and license revenue`,
`Royalty revenue`, `Licensing revenue`, `Revenue from franchise partners`,
`Wholesale revenue from franchisees`. If franchise revenue is bundled into a
combined "franchise and other revenue" line that also contains non-franchise items,
use the reported line here and state the bundling in the row's Col C comment
(*"Reported line bundles franchise revenue with <other items>; carried as
reported."*). §5's plug still makes the build foot.

### 4.2 — Non-Store Channel Revenue — the include / omit decision rule

For **each** candidate channel below, answer two questions **in order**. The
answers decide whether the line appears at all.

> **Q1 — Does the issuer report this channel as a separate revenue figure?**
> If **no** → **omit the line**. Do not estimate a channel from a percentage, a
> chart, or a peer. The §5 plug will carry it.
>
> **Q2 — Is this channel INSIDE the comparable base (§1.1, parameter 6)?**
> If **yes** → **omit the line.** Its dollars are already inside §2's comparable
> bridge; adding them here double-counts. Record the omission in the **Notes
> block** (§5.5): *"Revenue: <channel> sits inside comparable sales and is not
> carried separately."*
> If **no** → **include the line** as a reported input with a `YoY %` memo, and
> record it in the Notes block: *"Revenue: <channel> is carried as its own line;
> it is reported and sits outside comparable sales."*
>
> A channel omitted at Q1 because the issuer reports nothing is build history:
> one line in `BUILD_LOG.md`, no Notes line.

The four candidate channels:

| Channel | Typical series | Usually inside the comp base? |
|---|---|---|
| **Digital / E-commerce net sales** | `Online sales`, `Digital net sales`, `E-commerce revenue`, `Direct-to-consumer net sales` | **Varies by issuer — this is the one you must read.** Many retailers include online in comparable sales; many do not. |
| **Wholesale net sales** | `Wholesale net sales`, `Wholesale revenue` | **No** — wholesale is outside every store-comp base. Include when reported. |
| **Membership / fee income** | `Membership fee income`, `Membership and other income` | **No** — earned on the membership base, not per store. Include when reported; never fold it into merchandise sales. |
| **Licensing / royalty (non-franchise)** | `Licensing revenue`, `Royalty income` | **No.** Include when reported (or fold into §4.1 if the issuer reports one combined franchise-and-license line — once, not twice). |

**The double-count test, run before delivery.** For every line included here,
confirm the same dollars are **not** also inside `Total Net Sales from the
Comparable Cohort`. The cheapest check: if the Notes block records digital as
*inside* the comp base, then §4 must have **no** digital line; if *outside*, §4
**must** have one whenever the issuer reports the figure. The digital note and the
§4 lines must agree, and the §5.1 residual memo will be visibly large if they do
not.

**Face-line classification (run after the include test, before §5).** Read the
issuer's income statement. Most retailers report a single revenue line (`Net
sales`); some report a merchandise line **and** one or more separate revenue
lines on the face — Costco (`Net sales` + `Membership fees` = `Total revenue`),
Macy's and Target (`Net sales` + `Other revenue`). For `Franchise & License
Revenue` and for every §4 channel line included, record in the Notes block
(§5.5) whether the issuer presents it **inside its net sales line** or as **its
own face line**: *"Revenue: <line> is presented <inside net sales / as its own
line on the income statement> and sits <above / below> Net Sales."* Where the
issuer reports a single revenue line: *"Revenue: the issuer reports a single
revenue line, so no Net Sales row is laid."* The placement decides the §5
foot: lines inside net sales sit
above `Net Sales`; face lines sit between `Net Sales` and `Total Revenue`. Gap's
franchise revenue is product shipped to franchisees and sits inside net sales;
Costco's membership fees are a face line. Read it off the statement — never
decide by what the stream "ought" to be.

### 4.3 — Layout and formulas

```
Franchise & License Revenue                                                                        [section sub-header: bold + underlined, size 12, indent 0; OMIT if none]
    Franchise & License Revenue                                         (USD in <scale>)           [INPUT — royalties & fees; green, hyperlinked]
      YoY %                                                             (%)                        [FORMULA = this col ÷ prior col − 1; italic]

Non-Store Channel Revenue                                                                          [section sub-header: bold + underlined, size 12, indent 0; OMIT if none]
    Digital / E-Commerce Net Sales                                      (USD in <scale>)           [INPUT — ONLY if reported AND outside the comp base]
      YoY %                                                             (%)                        [FORMULA]
    Wholesale Net Sales                                                 (USD in <scale>)           [INPUT — only if reported]
      YoY %                                                             (%)                        [FORMULA]
    Membership Fee Income                                               (USD in <scale>)           [INPUT — only if reported]
      YoY %                                                             (%)                        [FORMULA]
    Licensing Revenue                                                   (USD in <scale>)           [INPUT — only if reported and not already in §4.1]
      YoY %                                                             (%)                        [FORMULA]
  Total Non-Store Channel Revenue                                       (USD in <scale>)           [FORMULA = SUM of the channel lines; bold, SUM-BAR]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Franchise & License Revenue` | | `(USD in <scale>)` | **input** — reported franchise / license royalties & fees | *(no comment — input row; provenance via hyperlink)* |
| `Digital / E-Commerce Net Sales` | | `(USD in <scale>)` | **input** — reported digital net sales | `"Included because the 10-K's comparable definition puts digital OUTSIDE the comp base. If it were inside, this line would be omitted."` |
| `Wholesale Net Sales` | | `(USD in <scale>)` | **input** — reported wholesale net sales | *(no comment — input row)* |
| `Membership Fee Income` | | `(USD in <scale>)` | **input** — reported membership / fee income | `"Earned on the membership base, not per store; never folded into merchandise sales."` |
| `Licensing Revenue` | DATA_DEPENDENT | `(USD in <scale>)` | **input** — reported licensing / royalty income | *(no comment — input row; omit if already inside §4.1)* |
| `YoY %` *(one under each line)* | | `(%)` | base col: blank/dash; else `= <this col> ÷ <prior col> − 1` | `"YoY change in <line>."` |
| `Total Non-Store Channel Revenue` | | `(USD in <scale>)` | `= SUM(` the channel lines `)` | `"Σ reported non-store channels sitting outside the comparable base."` |

**No note rows here.** The `Non-Store Channel Revenue` sub-header runs straight
into its first channel line. Each channel carried, and each channel left inside
comparable sales, gets one line in the **Notes block** (§5.5) in the §4.2
wording; a channel the issuer does not report goes to `BUILD_LOG.md` only.
`Total Non-Store Channel Revenue` is the block's
own subtotal; the §5 foot references the channel **lines individually**, each
placed by its §4.2 face-line classification, not this subtotal.

If the issuer breaks a stream into sub-lines (e.g. royalties vs. franchise fees vs.
advertising-fund revenue), you **may** carry them as input sub-rows one indent
level deeper than the stream line (`Alignment(indent=n+1)` — the real cell indent,
never leading spaces) with a bold subtotal `= SUM(sub-lines)`, but a single
consolidated line per stream is sufficient and preferred unless the user asks for
the breakdown.

### 4.4 — Calendar and currency walk lines (53rd week, foreign exchange)

Two more retail-only items can appear in the issuer's net-sales walk. **Neither is
a revenue stream** — each is a *reconciling* effect — so handle them as follows:

- **53rd week.** Retailers on a 52/53-week calendar report an extra week of net
  sales in some fiscal years, and most **exclude** it from the comp calculation
  (§1.1, parameter 5). It therefore sits outside §2's bridge. **If the issuer
  reports the 53rd week's dollar contribution**, carry it as its own input line
  inside the Non-Store Channel block, labeled `53rd-Week Net Sales Contribution`,
  present only in the column of the 53-week year and **dash in every other column**.
  If it is not quantified, **omit the line** — the §5 plug absorbs it, and the
  `YoY %` rows in §3 will visibly bulge in that column, which is why the **Notes
  block** (§5.5) must record which fiscal year had 53 weeks: *"Revenue: FY<n>
  had 53 weeks; the extra week's sales <are carried as their own line at $x /
  are not quantified and sit in Other Revenue>."* A projected 53-week year goes
  on the same line (Projections, Part 3).
- **Foreign-currency impact.** For international fleets the walk often carries an
  FX line. **Do not** add it as a revenue line: it is a decomposition of growth
  already inside reported net sales, not an incremental stream. Record the fiscal
  years and magnitude in the Notes block (§5.5) only: *"Revenue: reported net
  sales include a foreign-currency effect of <x> in FY<n>; no FX line is
  carried."* The one exception is a reported FX line
  the issuer presents as a distinct component of the net-sales walk that you are
  using for the §2.1 situation-2 arithmetic — in which case it belongs in that
  calculation, not as a workbook row.

### 4.5 — Pre-delivery checklist (Franchise, License & Non-Store Channel Revenue)

- [ ] `Franchise & License Revenue` is **present iff** the inventory carries a
      franchise or license revenue series (§4.1); otherwise omitted, with the
      inventory test recorded in `BUILD_LOG.md` (an absent line needs no Notes
      line). It appears **exactly once** — per banner **or** consolidated, never
      both.
- [ ] Each non-store channel line passed **both** §4.2 questions: the issuer
      reports it **and** it sits **outside** the comp base. No line was estimated,
      inferred from a percentage, or carried over from a peer.
- [ ] The digital decision **agrees** with the digital line in the Notes block
      (§2.2 wording): digital inside the comp base ⇒ **no** digital line here;
      outside ⇒ a digital line here whenever reported.
- [ ] **No italic-gray note rows** under the `Non-Store Channel Revenue`
      sub-header; each channel carried or left inside comparable sales is a line
      in the Notes block (§4.2 wording); unreported channels are in the log.
- [ ] `Membership Fee Income`, where the issuer has it, is on **its own line** and
      is **not** inside `Store Net Sales` (§3.2) or the comparable bridge.
- [ ] Every included line is a reported **input** (not cohort-derived), with a
      `YoY %` memo row beneath it (dash in the base column).
- [ ] A `53rd-Week Net Sales Contribution` line exists **only** if the issuer
      quantified it, carries a value **only** in the 53-week column, and dashes
      elsewhere. The 53-week year and any FX impact are Notes lines in the §4.4
      wording, **not** rows.
- [ ] `Total Non-Store Channel Revenue` = `SUM` of the channel lines (formula).
- [ ] All lines are in the **same unit** as the reported net-sales line.
- [ ] Styling per §1.6 / the styling rules; after recalculation, **zero formula
      errors**.

---

## Section 5 — Other Revenue (the plug) and Total Revenue (the foot)

This final section closes the build to the company's **reported total revenue**.
`Other Revenue` is the **plug**; `Total Revenue` is the **reported anchor** that
the plug closes to. Together they make the modeled components sum to reported total
revenue **exactly**. Beneath them, **§5.5** lays down the build's single **`Notes`**
block — every basis statement from §§0 – 5 collected in one place, at the bottom of
the sheet.

> **Row-label contract.** Label the grand-total row **`Total Revenue`** even though
> the retail income statement calls the line *net sales*. `Total Revenue` is a contract
> row (see `../../../SKILL.md`, "Contract rows"): the costs, consolidated-financials,
> depreciation-schedule and net-working-capital sections reference it by that exact
> label, so renaming it to `Total Net Sales` breaks those references. The **source** is
> the reported net-sales line; the **label** is `Total Revenue`. Record the mapping in
> the cell comment.

### 5.1 — Other Revenue is the plug — and what it absorbs

`Other Revenue` is defined as:

> **Other Revenue = Net Sales (reported) − Net Sales from Stores − every §4 line
> inside net sales**

where `Net Sales from Stores` is the comparable plus non-comparable subtotal
(§5.3) and the §4 lines inside net sales are those the §4.2 face-line
classification placed there (omit any term whose section was not built). When
the issuer reports a single revenue line, no `Net Sales` row is laid and the plug
is struck against `Total Revenue` instead, which is then the reported net sales
line. It is a **live formula**, never an input.

Be honest in the cell comment about what this plug captures. It is **not** purely
the issuer's reported "other revenue" line. It absorbs **three** things at once:

1. Any **genuine other revenue** the company reports that is outside store net
   sales, franchise/license revenue and the modeled non-store channels (gift-card
   breakage, credit-card program income, shipping and handling revenue, scrap and
   salvage, miscellaneous income);
2. **Unmodeled non-store channels** — every stream §4 had to omit because the
   issuer did not quantify it (an undisclosed digital split, an unquantified 53rd
   week, a bundled licensing figure); **and**
3. The **modeling residual** — the difference between **reported** store net sales
   and the **modeled** store net sales (`Comparable + Non-Comparable`), which are
   approximations (the comparable bridge compounds a seed by the comp rate; the
   non-comparable line uses a blended per-store figure and a flat 0.5 factor).

Because Other is a plug, none of this breaks the foot — but the analyst should be
able to see its size.

**Ratio driver row.** Add one row beneath the plug, `Other Revenue — % of modeled revenue`
= `Other Revenue ÷ (Net Sales from Stores + each §4 line inside net sales)`, tagged
`(% of modeled revenue)`. It divides by the modeled components, never by `Net Sales`
or `Total Revenue`, which contain the plug. Historically it is a live ratio; in
projection it is the driver `Other Revenue` is projected off (Part 3). It is a
visible driver row, not a memo.
**Interpretation guide:** for a retailer whose channels are fully disclosed and
correctly placed, `Other` should be a **low single-digit percentage** of net
sales. A double-digit `Other` is not a result — it means a large stream is
unmodeled, the per-store math picked up the wrong channel, or the comp series,
the seed or the universe is wrong. Investigate before delivering. The memo is a
diagnostic only and does not enter the foot; it is the only memo on the plug (a
"modeled store sales vs. reported" memo would need a reported store-sales series
most issuers do not publish, and with `Net Sales from Stores` laid it would equal
the plug).

### 5.2 — Total Revenue is the reported anchor and the grand-total foot

`Total Revenue` is the company's **reported total revenue** (an input — the net
sales line itself when the issuer reports a single revenue line) and serves as
the **grand total** of the revenue build. `Net Sales`, laid only when the issuer
reports a separate revenue face line, is the reported merchandise line. Because
`Other Revenue` is the plug, the identities

> **Net Sales from Stores + §4 lines inside net sales + Other = Net Sales**
> **Net Sales + §4 face lines = Total Revenue**

(one combined identity when `Net Sales` is not laid) hold **by construction**
for every period. Verify with a zero-check rather than assuming it: a
`Memo: components − Total (must = 0)` row.

### 5.3 — Layout and formulas

```
Net Sales from Stores                                                   (USD in <scale>)           [FORMULA = Comp total + Non-Comp total; bold, SUM-BAR]
Other Revenue                                                           (USD in <scale>)           [FORMULA plug = Net Sales (or Total Revenue) − Net Sales from Stores − §4 lines inside net sales]
  Other Revenue — % of modeled revenue                                  (% of modeled revenue)     [FORMULA historical = Other Revenue ÷ (Net Sales from Stores + §4 lines inside net sales); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]

Net Sales                                                               (USD in <scale>)           [INPUT — reported merchandise line; bold, SUM-BAR; ONLY when the issuer reports a separate revenue face line]

Total Revenue                                                           (USD in <scale>)           [INPUT — reported total revenue; bold, SUM-BAR]
  Memo: components − Total (must = 0)                                   (USD in <scale>)           [FORMULA check, italic; should be 0 every period]
```

| Row (plain Col C label) | Lays when | Units (Col D) | Cell | Comment on Col C label cell |
|---|---|---|---|---|
| `Net Sales from Stores` | | `(USD in <scale>)` | `= <Total Net Sales from the Comparable Cohort> + <Total Net Sales from the Non-Comparable Cohort>` | `"Modeled store net sales = comparable + non-comparable cohorts. The store-level base the cost build divides by."` |
| `Other Revenue` | | `(USD in <scale>)` | `= <Net Sales, this col> − <Net Sales from Stores> − <each §4 line inside net sales>` — `Total Revenue` in place of `Net Sales` when no `Net Sales` row is laid; drop any term whose section was not built; projection: `= <Other Revenue — % of modeled revenue, this col> × (<Net Sales from Stores> + <each §4 line inside net sales>)` | `"Plug = reported net sales − modeled store net sales − the franchise and channel lines inside net sales. Absorbs genuine other revenue, unmodeled channels, AND the cohort-model residual."` |
| `Other Revenue — % of modeled revenue` *(driver row under the plug; visible)* | | `(% of modeled revenue)` | historical: `= <Other Revenue> ÷ (<Net Sales from Stores> + <each §4 line inside net sales>)`; projection: **DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The plug's share of the revenue the build models (store net sales + the franchise and channel lines inside net sales). Historical: a fit diagnostic; low single digits expected when channels are fully disclosed and correctly placed, double digits = investigate. Projection: driver, guided or else the latest year, then flat."` |
| `Net Sales` *(only when a separate face line exists)* | DATA_DEPENDENT | `(USD in <scale>)` | **input** — the reported merchandise net sales line (green, hyperlinked) | `"Reported net sales (<issuer caption>). Laid because the issuer also reports <face line(s)> separately; the cost build strikes cost of sales against this row."` |
| `Total Revenue` | | `(USD in <scale>)` | **input** — reported total revenue (green, hyperlinked); the reported net sales line when the issuer reports a single revenue line | `"Reported total revenue; labeled Total Revenue because the cost and consolidated sections reference this row by that name."` |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= (<Net Sales> + <each §4 face line>) − <Total Revenue>`; with no `Net Sales` row: `= (<Net Sales from Stores> + <each §4 line> + <Other Revenue>) − <Total Revenue>` | `"Foot check: must equal 0 every period (Other is the plug)."` |

`Net Sales` and `Total Revenue` are totals, styled like every other total in the
workbook (bold, SUM-BAR — a single thin top border across the data columns; no
underline). The rows read top-to-bottom into each total: the store subtotal and
the plug into `Net Sales`; `Net Sales` and the §4 face lines (which stay in their
§4 blocks and are not restated here) into `Total Revenue`. The foot-check memo
sits immediately beneath `Total Revenue`. Nothing is laid between `Net Sales` and
`Total Revenue` for a single-revenue-line issuer, because `Net Sales` itself is
not laid: the plug and the check are struck against `Total Revenue`, which is
then the reported net sales line.

### 5.4 — Pre-delivery checklist (Other + Total Revenue)

- [ ] `Net Sales from Stores` is a live `= Comp total + Non-Comp total` formula,
      bold with the SUM-BAR.
- [ ] `Other Revenue` is a **live formula plug** = `Net Sales (or Total Revenue) −
      Net Sales from Stores − the §4 lines inside net sales` (each term present iff
      its section was built, placement per the §4.2 face-line classification);
      never an input.
- [ ] Its cell comment **honestly states** that the plug absorbs genuine other
      revenue, unmodeled channels, **and** the cohort-model residual.
- [ ] `Net Sales` is laid **iff** the issuer reports a separate revenue face line,
      is the **reported** merchandise net sales input, and is bold with the SUM-BAR.
- [ ] `Total Revenue` is the **reported** total revenue input (the anchor) — the net
      sales line itself for a single-revenue-line issuer — keeps the label
      `Total Revenue` for the downstream contract, and is bold with the SUM-BAR.
- [ ] The `components − Total` foot-check memo evaluates to **0** in every period
      after recalculation (proves the build foots).
- [ ] `Other as % of net sales` (`… of total revenue` for a single-revenue-line
      issuer) is in **low single digits** — or, if not, the cause
      has been identified and noted rather than absorbed silently.
- [ ] Every component and memo is in the **same unit** as the reported net-sales
      line.
- [ ] After recalculation, **zero formula errors**, and the master identity holds
      exactly for every period.

### 5.5 — The Notes block (every note, once, at the bottom of the build)

**All footnote-style notes in this build live here — nowhere else.** No
italic-gray note rows are interleaved between the build's rows: every section
sub-header is followed immediately by its first line item, and every basis
statement, decision and caveat the sections above tell you to record is collected
into a **single Notes block** at the **very bottom of the entire revenue build**.

**Placement.** Two blank spacer rows below the last row of the build — for a
single-banner retailer that is `Memo: components − Total` under `Total Revenue`
(§5.3); for a multi-banner parent it is the last row of the `Consolidated Revenue`
table (§6.3). The block is the last thing on the revenue build; nothing is written
beneath it.

**Layout** (all label text in Col C; the notes span the label column only — they
carry no period values):

```
                                                                ← two blank spacer rows
Notes                                                           (section sub-header: bold + underlined, size 12; base indent)
  Revenue: comparable definition: "<quoted or closely paraphrased 10-K definition>" (per <issuer> FY<n> 10-K)   (italic, size 11, gray)
  Revenue: comparable base = stores open at least <T> months <anchor wording>; new-store window <R> months; stub-year fraction <x>   (italic, size 11, gray)
  Revenue: remodeled and relocated stores <remain in / are removed from> the comparable base; <the filing gives no count, so none is carried>   (italic, size 11, gray)
  Revenue: <banner> gross openings are not disclosed; net openings floored at zero stand in, which understates the new-store cohort by the year's closures   (italic, size 11, gray; only when §1.5 used the net-flow proxy; one line per banner)
  Revenue: <banner> openings are not disclosed by banner; net change floored at zero stands in, so the cohort split is an estimate   (italic, size 11, gray; only on the §1.5 levels-only proxy)
  Revenue: <banner> comparable count is the issuer's reported figure; the non-comparable count is the remainder of the period-end fleet   (italic, size 11, gray; only on the §1.5 inversion)
  Revenue: cohorts and comps are company-operated stores; comp series: <caption>, on an <owned / owned-plus-licensed> basis   (italic, size 11, gray)
  Revenue: the comp rate is on an owned-plus-licensed basis while the seed dollars are owned-only; the rate is a proxy   (italic, size 11, gray; only when §1.9 took the wider basis)
  Revenue: the issuer also reports a <franchise / system> comp; it is not used, since franchise revenue is carried on its own growth rate   (italic, size 11, gray; only when such a comp is reported)
  Revenue: the comp rate is applied per <banner / banner and region / the whole company>, as reported, over the summed cohort counts   (italic, size 11, gray)
  Revenue: comparable sales <include / exclude> online sales; the comparable-cohort line therefore <carries the digital channel and no separate digital line exists / is stores only>   (italic, size 11, gray)
  Revenue: base-year comparable-cohort sales are <the issuer's reported figure / backed out of the reported dollar change divided by the comp rate> for FY<n>   (italic, size 11, gray)
  Revenue: net sales per store divides store net sales only (excluding <digital, wholesale, licensing, membership>) by company-operated stores   (italic, size 11, gray)
  Revenue: new stores are assumed open half the year on average; the 0.5 factor is uniform across companies   (italic, size 11, gray)
  Revenue: <channel> is carried as its own line; it is reported and sits outside comparable sales   (italic, size 11, gray; one line per channel carried)
  Revenue: <channel> sits inside comparable sales and is not carried separately   (italic, size 11, gray; one line per channel left inside the comp base)
  Revenue: <line> is presented <inside net sales / as its own line on the income statement> and sits <above / below> Net Sales   (italic, size 11, gray; one line per franchise or channel line laid)
  Revenue: the issuer reports a single revenue line, so no Net Sales row is laid   (italic, size 11, gray; only when that is the case)
  Revenue: FY<n> had 53 weeks; the extra week's sales <are carried as their own line at $x / are not quantified and sit in Other Revenue>   (italic, size 11, gray; a projected 53-week year goes on the same line)
  Revenue: reported net sales include a foreign-currency effect of <x> in FY<n>; no FX line is carried   (italic, size 11, gray; note only, never a row)
  Revenue: Other Revenue, the plug, is <x>% of <net sales / total revenue> in FY<n> (<range> across the window); it holds other income, unquantified channels and the cohort-model residual   (italic, size 11, gray)
  Revenue: in the forecast the comparable count is a share of the period-end fleet, held at the latest reported share; the non-comparable count is the remainder   (italic, size 11, gray; only when the projection inverts the plug)
  Revenue: <row> FY<n> is taken from the 10-K; the database series was <scaled / mis-tagged / missing>   (italic, size 11, gray; one line per override cell)
```

**Content rule — what must appear.** Every modeling fact the sections above say
to record in the Notes block is a line here, in the wording its section gives.
At minimum: the **comparable definition** and its source filing year; the
**comparable base** line carrying **T**, the anchor, **R** and the stub-year
fraction; the **remodel / relocation** treatment; any **openings proxy** or
**inversion** the cohort rests on; the **universe** and the comp series and its
basis (§1.9); the **comp application level** (§1.10); whether **digital** is
inside the comp base (§2.2) and one line for each channel carried or left inside
comparable sales (§4.2); how the **base-year seed** was obtained (§2.1); the
store-only **numerator** and the **0.5 partial-year factor** (§3.3); the
**face-line** placement of every franchise or channel line (§4.2); which fiscal
year in the window had **53 weeks** and any **FX** impact (§4.4); the **`Other
Revenue` plug** as a % of net sales (of total revenue for a single-revenue-line
issuer) by year; and every **10-K override** cell with its reason. Where a note
carries a projection-period counterpart (a driver switched basis, a projected
53-week year), record that on the same line rather than opening a second block.

What is **not** here: the flow-disclosure tier and the §1.5 path, the sales basis
of each candidate comp series, the cohort spot-check and the banner net-sales
cross-check with their results, the adoption of the store roll-forward's
fiscal-year mapping, and any channel or franchise line omitted because the issuer
reports nothing. Those are build history and go to `BUILD_LOG.md`.

**Style.** `Notes` is a section sub-header — bold + underlined, size 12 — at **base
indent** (`indent=0`); every note line is **italic, size 11,
gray** at **`indent=1`**, with **zero blank rows** between them so the block reads
as one list. Each line is **plain text in Col C only** — no values in the period
columns, no formulas, no fills, no hyperlinks (provenance stays on the input cells
it belongs to). Every line opens with the `Revenue:` prefix and reads as an
analyst would write it: no section numbers, no tier, path, situation or layout
names, no driver colors, no skill vocabulary, no em dashes. Order the lines as the
layout above lists them (definition and cohort facts first, the plug and the 10-K
overrides last). Indent is the real cell indent (`Alignment(indent=1)`,
`Alt, H, 6`) — **never** leading spaces.

**Checklist (Notes block):**

- [ ] The block sits at the **very bottom** of the build, two blank rows beneath the
      last row of §5.3 (or of the §6.3 consolidated table), under a bold underlined
      `Notes` sub-header.
- [ ] **Nothing gray appears anywhere else in the build.** Sweep Col C for italic
      gray rows: the only ones outside this block are §1.6's three zone labels
      (`⤷ Cohort assumptions`, `⤷ Cohort lookback inputs`, `⤷ Base-year seed`).
- [ ] Every Notes-block instruction in §§0 – 5 (and the projection drivers) has a
      corresponding line here; each line opens with `Revenue:` and carries no
      section number, tier, path, situation or layout name, driver color or skill
      vocabulary. Build history (tier, path, checks and their results, series
      comparisons, the adopted column mapping) is in `BUILD_LOG.md`, not here.
- [ ] Notes are **text only** — no period values, formulas, fills or hyperlinks —
      and no note repeats a fact already carried by a cell comment.

---

## Section 6 — Multi-banner parents: per-banner full build + consolidated revenue table

Many retail parents operate **more than one banner** — e.g. **The Gap, Inc.** (Old
Navy, Gap, Banana Republic, Athleta), **TJX** (T.J. Maxx, Marshalls, HomeGoods,
Sierra, Winners, TK Maxx), and multi-segment parents generally. For these, **do
not** blend the banners into a single bridge. Instead:

1. **Run the entire revenue build once per banner** — each banner gets its **own
   complete build** (the §2 comparable bridge and the §3 non-comparable lines, plus
   — only if that banner's franchise revenue is reported separately — its §4.1
   line), producing a per-banner modeled revenue subtotal; then
2. **Build one consolidated revenue table** that **combines the banners** — summing
   each component across banners, adding the company-level franchise / non-store
   channel lines and the **Other Revenue** plug, and tying to the **reported
   consolidated Total Revenue**.

A **single-banner retailer** (e.g. Dollar General) skips this section: it has one
banner, so the "consolidated" table simply restates that banner's build. This
section is the **canonical workbook organization for multi-banner parents** — the
§2 – §5 formulas are unchanged; they are just **arranged banner-by-banner**, with
the component totals and the company-level plug/foot collected into the
consolidated table at the bottom.

### 6.1 — Why per banner, never blended

Each banner can have a **different comparable-store sales rate**, a **different
comparable definition / effective reach** (§1.1 — some parents use a different `T`
per banner), a **different franchise and channel mix**, and **very different unit
economics** (net sales per store, average ticket, box size). Averaging them into
one bridge would apply one banner's comp rate and per-store net sales to another's
store count — silently wrong. Building each banner on its own §1 cohort counts and
its own comp rate keeps every per-store figure honest; the banners only meet at
the **dollar level** in the consolidated table, where summing is always valid.

**Two retail-specific placements to get right before you start:**

- **Comp granularity (§1.10).** If comp is reported banner-**global** while the
  cohort blocks are banner × **region**, the per-banner revenue block is built at
  the **banner-global** level over summed regional cohort counts — so a parent with
  six cohort blocks may have only four revenue blocks. State the mapping.
- **Franchise / non-store channels (§4.1, §4.2).** These almost always sit at the
  **parent** level in retail. Put them in the consolidated table, not in the banner
  blocks, unless the issuer genuinely reports them per banner.

### 6.2 — Per-banner block: the full build for one banner

For **each banner**, lay a self-contained revenue block directly beneath that
banner's §1 cohort block, containing that banner's complete build in order:

```
<Banner>                                                                                           [banner header: bold + underlined, indent 0 — full revenue build for this banner]
  Comparable Cohort Net Sales                                                                      [sub-header: bold + underlined, indent 1 — §2 five-row bridge, this banner]
    Previous Year's Comparable-Cohort Net Sales                         (USD in <scale>)
    Net Sales per Comparable Store — prior yr                           (USD millions per store)
    Comparable-Store Sales Growth                                       (%)                        [+ Transactions / Ticket / AUR / UPT memo rows if disclosed]
    Estimated Net Sales per Comparable Store                            (USD millions per store)
    Net Sales from the Comparable Cohort                                (USD in <scale>)           [= est × this banner's comparable count §1]
  Non-Comparable Cohort Net Sales                                                                  [sub-header: bold + underlined, indent 1 — §3 rows, this banner]
    Store Net Sales                                                     (USD in <scale>)
    Net Sales per Store — system avg                                    (USD millions per store)
      YoY %                                                             (%)
    Net Sales from the Non-Comparable Cohort                            (USD in <scale>)           [= per-store × 0.5 × this banner's non-comp count §1]
  Franchise & License Revenue                                           (USD in <scale>)           [§4.1 — INCLUDE only if reported for THIS banner]
      YoY %                                                             (%)
  Total Revenue — <Banner> (modeled)                                    (USD in <scale>)           [FORMULA = comp + non-comp + franchise(this banner); bold subtotal, SUM-BAR]
<Banner 2> …                                                                                       [repeat the whole block]
```

Notes on the per-banner block:

- The five comparable rows and the non-comparable rows use the **exact formulas of
  §2.4 and §3.4** — only this banner's §1 cohort counts, this banner's comp rate,
  and this banner's store net sales feed them.
- **`Total Revenue — <Banner> (modeled)`** is a **modeled** subtotal. It is **not**
  generally a reported figure — retailers rarely publish a full banner-level total
  revenue — so do **not** try to tie it to a reported banner total; the
  reconciliation to reported revenue happens **only** at the consolidated level
  (§6.3), via the Other plug. Where the issuer *does* report banner or segment net
  sales, use it as a **cross-check**, recorded with its result in `BUILD_LOG.md`,
  not as a forced tie and not as a Notes line.
- **The segment map.** Record in `BUILD_LOG.md` (the stage's hand-back report
  carries the same) each banner's name as the inventory's segment series spell it and
  the key of its `Total Revenue — <Banner> (modeled)` row — the segment map of
  `../../../SKILL.md`, "The segment map", which the cost build and the consolidated
  section read for that banner's revenue.
- **Franchise and non-store channel placement.** If the issuer reports these **per
  banner**, put them inside that banner's block and include them in the banner
  subtotal. If they are reported **only at the consolidated level** (the common
  retail case — The Gap, Inc.'s franchised fleet is one), **omit** them from the
  per-banner blocks (each banner subtotal is then comparable + non-comparable only)
  and place single lines in the consolidated table (§6.3). Exactly once, either way.
- One blank spacer row separates each banner's full block from the next, exactly as
  §1.6 separates cohort blocks.

### 6.3 — The consolidated revenue table

After the per-banner blocks, lay one **consolidated revenue table** that combines
the banners and foots to reported total revenue:

```
Consolidated Revenue                                                                               [section sub-header: bold + underlined, size 12, indent 0]
    Total Net Sales from the Comparable Cohort                          (USD in <scale>)           [FORMULA = Σ each banner's 'Net Sales from the Comparable Cohort']
    Total Net Sales from the Non-Comparable Cohort                      (USD in <scale>)           [FORMULA = Σ each banner's 'Net Sales from the Non-Comparable Cohort']
  Net Sales from Stores                                                 (USD in <scale>)           [FORMULA = the two cohort totals; bold, SUM-BAR]
    <§4 lines inside net sales>                                         (USD in <scale>)           [Franchise & License Revenue and/or channel lines the §4.2 classification placed inside net sales; Σ banners or reported consolidated INPUT]
    Other Revenue                                                       (USD in <scale>)           [FORMULA plug = Net Sales (or Total Revenue) − Net Sales from Stores − the inside lines; projection: = the ratio row beneath × (Net Sales from Stores + the inside lines)]
      Other Revenue — % of modeled revenue                              (% of modeled revenue)     [FORMULA historical = Other Revenue ÷ (Net Sales from Stores + the inside lines); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]
  Net Sales                                                             (USD in <scale>)           [INPUT — reported consolidated net sales; bold, SUM-BAR; ONLY when a separate face line exists]
    <§4 face lines>                                                     (USD in <scale>)           [Franchise & License Revenue and/or channel lines reported as their own face line; INPUT]
      YoY %                                                             (%)                        [FORMULA, one under each §4 line]
  Total Revenue                                                         (USD in <scale>)           [INPUT — reported consolidated total revenue; bold, SUM-BAR]
    Memo: components − Total (must = 0)                                 (USD in <scale>)           [FORMULA check; 0 every period]
    Memo: revenue mix by banner                                         (% of Net Sales from Stores) [FORMULA, optional — each banner's modeled store net sales ÷ Net Sales from Stores]
```

**Formulas (consolidated table):**

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Total Net Sales from the Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each banner's `Net Sales from the Comparable Cohort` `)` | `"Σ comparable-cohort net sales across all banners."` |
| `Total Net Sales from the Non-Comparable Cohort` | | `(USD in <scale>)` | `= SUM(` each banner's `Net Sales from the Non-Comparable Cohort` `)` | `"Σ non-comparable-cohort net sales across all banners."` |
| `Net Sales from Stores` | | `(USD in <scale>)` | `= <Total Net Sales from the Comparable Cohort> + <Total Net Sales from the Non-Comparable Cohort>` | `"Modeled store net sales = comparable + non-comparable cohorts, all banners. The store-level base the cost build divides by."` |
| each §4 line *(placed by the §4.2 face-line classification)* | | `(USD in <scale>)` | `= SUM(` each banner's line `)` if reported per banner; **else** **input** = the reported consolidated line | `"Σ banner lines, or the reported consolidated line. Appears exactly once. <Inside net sales | own face line> per the income statement."` |
| `Other Revenue` | | `(USD in <scale>)` | `= <Net Sales> − <Net Sales from Stores> − <each §4 line inside net sales>` — `Total Revenue` in place of `Net Sales` when no `Net Sales` row is laid; drop terms not built | `"Plug = reported net sales − modeled store net sales − the franchise and channel lines inside net sales."` |
| `Net Sales` *(only when a separate face line exists)* | DATA_DEPENDENT | `(USD in <scale>)` | **input** — reported **consolidated** net sales (green, hyperlinked) | `"Reported consolidated net sales (<issuer caption>); the cost build strikes cost of sales against this row."` |
| `Total Revenue` | | `(USD in <scale>)` | **input** — reported **consolidated** total revenue (green, hyperlinked); the net sales line itself for a single-revenue-line issuer | `"Reported consolidated total revenue; labeled Total Revenue because the cost and consolidated sections reference this row by that name."` |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= (<Net Sales> + <each §4 face line>) − <Total Revenue>`; with no `Net Sales` row: `= (<Net Sales from Stores> + <each §4 line> + <Other>) − <Total Revenue>` | `"Foot check: must equal 0 every period."` |
| `Memo: revenue mix by banner` *(optional)* | DATA_DEPENDENT | `(% of Net Sales from Stores)` | per banner: `= (<Banner Comp> + <Banner Non-Comp>) ÷ <Net Sales from Stores>` | `"Each banner's modeled store net sales as a share of the total."` |

**The Notes block goes below this table.** For a multi-banner parent the
`Consolidated Revenue` table is the last numeric block in the build, so the §5.5
`Notes` block sits two blank rows beneath `Memo: revenue mix by banner` — one block
for the whole build, not one per banner. Where a note differs by banner, name the
banner in the line (`Revenue: comp rates are applied per banner (Gap, Old Navy,
Banana Republic, Athleta) over the summed regional cohorts`).

This **is** the Section 5 logic, lifted to the consolidated level: `Other Revenue`
is still the plug and `Total Revenue` is still the reported anchor, so the master
identity holds for the **parent**. The per-banner `Total Net Sales from the
Comparable Cohort` and `… Non-Comparable Cohort` totals that §2.3 / §3.3 describe
**live here**, in the consolidated table, for a multi-banner parent (rather than at
the foot of each component section). For a single-banner retailer the consolidated
table's component sums reduce to that one banner's lines.

### 6.4 — Pre-delivery checklist (multi-banner parents)

- [ ] **One full revenue build per banner** — each banner has its own §2 comparable
      bridge and §3 non-comparable lines (and, only if reported per banner, its
      §4.1 franchise line), plus a bold `Total Revenue — <Banner> (modeled)`
      subtotal.
- [ ] The revenue blocks sit at the **comp-reporting level** (§1.10), and the
      mapping from cohort blocks to revenue blocks is stated where the two levels
      differ (e.g. six banner × region cohort blocks → four banner-global revenue
      blocks).
- [ ] No blended cross-banner bridge: each banner uses **its own** §1 cohort counts,
      **its own** comp rate, and **its own** store net sales / store counts.
- [ ] A single **`Consolidated Revenue`** table sums each component across banners,
      carries the company-level franchise / non-store channel lines and the **Other
      Revenue** plug, and anchors to the **reported consolidated** `Total Revenue`.
- [ ] **Franchise & license revenue and every non-store channel appear exactly
      once** — either per banner (then summed in the consolidated table) or only in
      the consolidated table — never double-counted.
- [ ] The consolidated `components − Total` foot-check = **0** every period; the
      master identity holds for the parent.
- [ ] Per-banner `Total Revenue — <Banner> (modeled)` subtotals are **not** forced to
      tie to a reported banner total (reconciliation is consolidated only); where a
      reported banner/segment net-sales figure exists, it is used as a cross-check
      whose result is recorded in `BUILD_LOG.md`.
- [ ] **One Notes block for the whole build**, two blank rows beneath the
      consolidated table — not one per banner, and no italic-gray note rows inside
      any banner block.
- [ ] Banner blocks are ordered and labeled the same as the §1 cohort blocks;
      spacing / labels / comments follow §1.6.
- [ ] **Indentation across the whole workbook is real cell indent**, not padding:
      every Col C label satisfies `value == value.lstrip()`, and each row's level
      is carried by `Alignment(indent=n)` (`Alt, H, 6`). Sweep the sheet
      programmatically before delivering — with per-banner blocks repeating the
      same line-item names, a single padded label breaks the §6 label references
      and the header underlines, and is invisible in the Excel UI.
- [ ] Applying the indent **preserved** each cell's existing `horizontal` /
      `vertical` alignment (no bare `Alignment(indent=n)` that wipes the rest).
- [ ] After recalculation, **zero formula errors**.

---

## Section 7 — Worked example: the full Dollar General revenue bridge (real figures)

This walks **Dollar General** through the complete build to show how the rows
chain. Unlike a synthetic illustration, **every input below is a real deepKPI or
10-K value**, so the outputs can be checked against the filing — which is the
point: a correctly built comparable-stores model should land close to the issuer's
own disclosures without being forced to.

Universe = company-operated stores (no franchised fleet). Figures in **$ millions**;
per-store figures in **$ millions per store**. Build window FY2022 (base) → FY2025.
Single banner, so §6's consolidated table reduces to this one build.

**Section 1 inputs and outputs (from §1.12, plus one extra year to the left so the
base column has a seed denominator):**

| | FY2021 *(seed yr)* | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|
| Store Openings | 1,050 | 1,039 | 987 | 725 | 589 |
| Company-Operated EOP | 18,130 | 19,104 | 19,986 | 20,594 | 20,893 |
| `Opened in Previous Yr` × 1/12 | 83 | 88 | 87 | 82 | 60 |
| **Total Non-Comparable Cohort** | 1,133 | 1,127 | 1,074 | 807 | 649 |
| **Total Comparable Cohort** | **16,997** | **17,977** | **18,912** | **19,787** | **20,244** |
| Memo: Comparable as % of total | 93.8% | 94.1% | 94.6% | 96.1% | 96.9% |

**Base-year seed (FY2022 column only) — §2.1 situation 1.** Dollar General reports
the comparable cohort's **dollars** directly (deepKPI: `Annual net sales from
same-stores for Dollar General consolidated retail operations`, unit USD; and in
MD&A as *"our X same-stores accounted for sales of $Y"*), so no back-solve is
needed:

- `Previous Year's Comparable-Cohort Net Sales` (FY2021) = **$32,400M**
- `# stores in the previous year's comparable cohort` (FY2021) = **16,997** — the
  §1 base-year seed row `Comparable cohort — one fiscal year before the window`
  in the FY2022 column: FY2021 EOP **18,130** − FY2021 openings **1,050** −
  ROUND(FY2020 openings × 1/12) **83**, the two extra inputs pulled per §1.8.
  (Where the filing states the FY2021 same-store count directly, that reported
  figure is the input instead.) **Not** the FY2021 total store count of 18,130.

**Section 2 — Comparable Cohort bridge** (comp % = the reported same-store sales
rate: `Consolidated same-store sales for stores open at least 13 full fiscal
months`):

| Row | Lays when | Units (Col D) | FY2022 (base) | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Previous Year's Comparable-Cohort Net Sales | | `(USD in millions)` | 32,400.0 *(seed)* | 35,741.6 *(=FY22 row 5)* | 37,675.8 | 39,970.8 |
| Net Sales per Comparable Store — prior yr | | `(USD millions per store)` | 1.9062 *(÷16,997)* | 1.9882 *(÷17,977)* | 1.9922 *(÷18,912)* | 2.0201 *(÷19,787)* |
| Comparable-Store Sales Growth | | `(%)` | +4.3% | +0.2% | +1.4% | +3.0% |
| ⤷ Comp — Transactions / Traffic *(memo)* | | `(%)` | n/d | n/d | +1.1% | +1.6% |
| ⤷ Comp — Average Transaction Amount *(memo)* | | `(%)` | n/d | n/d | +0.3% | +1.4% |
| Estimated Net Sales per Comparable Store | | `(USD millions per store)` | 1.9882 | 1.9922 | 2.0201 | 2.0807 |
| **Net Sales from the Comparable Cohort** = est × comp count | | `(USD in millions)` | **35,741.6** *(×17,977)* | **37,675.8** *(×18,912)* | **39,970.8** *(×19,787)* | **42,120.8** *(×20,244)* |

Note how `Net Sales per Comparable Store — prior yr (N)` reproduces
`Estimated Net Sales per Comparable Store (N−1)` exactly (FY2023's 1.9882 = FY2022's
estimate; FY2025's 2.0201 = FY2024's estimate) — the recursion of §2.1. **Only
FY2022 used inputs; FY2023–FY2025 are pure formulas** apart from the comp rate.

**Validation against the issuer's own comparable-cohort dollars:**

| Period | Modeled comparable-cohort net sales | 10-K / deepKPI reported same-store sales | Diff |
|---|---|---|---|
| FY2022 | 35,741.6 | 35,300 | +1.3% |
| FY2023 | 37,675.8 | 36,900 | +2.1% |
| FY2024 | 39,970.8 | 38,800 | +3.0% |
| FY2025 | 42,120.8 | 41,200 | +2.2% |

A 1–3% band across four years, from a single seed compounded by the reported comp
rate — with part of that band being rounding, since the reported same-store dollars
are disclosed to three significant figures ($41.2bn). This is what a healthy
comparable bridge looks like. A build drifting 10%+ from the reported figure has a
seed, universe, or comp-granularity error.

**Section 3 — Non-Comparable Cohort.** Dollar General reports no separate digital,
wholesale, licensing or membership revenue, so `Store Net Sales` = total net sales
(and the §3.2 cell comment says so):

| Row | Lays when | Units (Col D) | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|
| Store Net Sales *(= total net sales; no non-store channels)* | | `(USD in millions)` | 38,691.6 | 40,612.3 | 42,724.4 |
| Net Sales per Store — system avg | | `(USD millions per store)` | 1.9359 | 1.9720 | 2.0449 |
| ⤷ YoY % | | `(%)` | — | +1.9% | +3.7% |
| Total Non-Comparable Cohort (§1) | | `(stores)` | 1,074 | 807 | 649 |
| **Net Sales from the Non-Comparable Cohort** = per-store × 0.5 × count | | `(USD in millions)` | **1,039.6** | **795.7** | **663.6** |

*(FY2022's column is built the same way from that year's reported net sales; it is
omitted here only to keep the table narrow.)*

**Section 4 — omitted entirely.** No franchised or licensed fleet ⇒ no
`Franchise & License Revenue` line. No separately reported digital, wholesale,
licensing or membership revenue ⇒ no `Non-Store Channel Revenue` block. Both
omissions are recorded in `BUILD_LOG.md`, citing the absence of the series — per
§4's requirement that the include/omit decision be explicit; an absent line gets
no Notes line.

**Section 5 — the foot:**

| Row | Lays when | Units (Col D) | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|
| Total Net Sales from the Comparable Cohort | | `(USD in millions)` | 37,675.8 | 39,970.8 | 42,120.8 |
| Total Net Sales from the Non-Comparable Cohort | | `(USD in millions)` | 1,039.6 | 795.7 | 663.6 |
| **Net Sales from Stores** | | `(USD in millions)` | **38,715.4** | **40,766.5** | **42,784.4** |
| **Other Revenue** *(plug)* | | `(USD in millions)` | **(23.8)** | **(154.2)** | **(59.9)** |
| Other Revenue — % of modeled revenue *(= Other ÷ Net Sales from Stores; no §4 lines inside net sales here)* | | `(% of modeled revenue)` | (0.06)% | (0.38)% | (0.14)% |
| **Total Revenue** *(reported net sales — Dollar General reports a single revenue line, so no `Net Sales` row is laid)* | | `(USD in millions)` | **38,691.6** | **40,612.3** | **42,724.4** |
| Memo: components − Total (must = 0) | | `(USD in millions)` | 0.0 | 0.0 | 0.0 |

**Reading a small negative plug.** `Other Revenue` here is **negative but tiny** —
between −0.06% and −0.38% of total revenue. That is the expected shape for a
single-channel retailer with no non-store revenue: the modeled store sales
(comparable + non-comparable) slightly **overshoot** reported net sales, because §3
values non-comparable stores off the **blended** per-store figure, which is pulled
up by the mature comparable base. The framework accepts this and the plug closes
it.

**When a negative plug is a defect instead.** Escalate rather than absorb when
`Other Revenue` is negative by **more than ~2% of total revenue**, or negative and
**growing** across the window. In practice that means one of:

- the comparable bridge was seeded from **blended** net sales rather than
  comparable-cohort dollars (the §2.1 forbidden seed — it inflates the per-store
  figure, which then compounds);
- a **non-store channel is inside `Store Net Sales`** (§3.2), inflating the per-store
  figure that §3 multiplies by the non-comparable count;
- **digital was counted twice** — inside the comp base *and* on a §4.2 line;
- the **universe** is mismatched (company-operated counts against systemwide sales);
- the **comp rate was applied at the wrong granularity** (§1.10).

Fix the cause; do not widen the plug's definition to hide it.

**The Notes block for this build (§5.5)** — two blank rows beneath
`Memo: components − Total (must = 0)`, and the only gray text anywhere in the sheet:

```
Notes
  Revenue: comparable definition: "stores open at least 13 full fiscal months that remain open at period end; comp on the comparable 52 calendar weeks" (per DG FY2025 10-K, MD&A Key Performance Indicators)
  Revenue: comparable base = stores open at least 13 months; new-store window 13 months; stub-year fraction 1/12
  Revenue: remodeled, relocated and expanded stores remain in the comparable base; no removal row is carried
  Revenue: cohorts and comps are company-operated stores; comp series: same-store sales, on an owned basis; there is no franchised fleet
  Revenue: the comp rate is applied to the whole company, as reported, over the summed cohort counts
  Revenue: the issuer reports no separate e-commerce figure, so no digital line exists; the comparable-cohort line and net sales per store carry every channel
  Revenue: base-year comparable-cohort sales are the issuer's reported figure for FY2021, $32,400M
  Revenue: net sales per store divides total net sales by company-operated stores; the issuer reports no non-store channel, so the per-store figure is exact
  Revenue: new stores are assumed open half the year on average; the 0.5 factor is uniform across companies
  Revenue: the issuer reports a single revenue line, so no Net Sales row is laid
  Revenue: no fiscal year in FY2022 to FY2025 had 53 weeks
  Revenue: Other Revenue, the plug, is (0.06)% to (0.38)% of total revenue across the window; a small negative is the expected shape for a single-channel retailer
```

The flow tier, the spot-check against the reported same-store count and the
adopted fiscal-year mapping are in `BUILD_LOG.md`; no 10-K override was needed,
so no override line appears.

**If this were a multi-banner parent**, the entire block above would repeat for
each banner, and all of the component totals, the franchise / non-store channel
lines, the `Other Revenue` plug and the reported consolidated `Total Revenue` would
live in a single **`Consolidated Revenue`** table per §6 — not in any one banner's
block. The `Notes` block would still appear **once**, beneath that table.

---

## Projections (forecast years)

After the **historical** build above (Sections 1 – 7) is laid down, recalculated,
and footed (the §5 / §6 `components − Total (must = 0)` check passes), **extend the
entire revenue build into the projection window** before the downstream handoff
(§8). The projection window is the **five fiscal years after the last historical
year** (`N+1 … N+5`) per the **Model timeline** in `../../../SKILL.md` — do not
redefine it here. Add five more **annual** columns immediately to the right of the
historical block, continuing the same left → right, oldest → newest order; the build
stays **annual** in the projection window too. The overwhelming majority of the
build simply **drags across as formulas**; only a small set of **drivers** per
banner are entered as forward assumptions.

### Driver styling (applies to every projection driver below)

Mark **every** projection driver cell so it reads as a forward assumption —
visually distinct from both the formula cells and the historical input cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **Dashed box border on all four sides** of the cell (e.g. openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom`).
- **No pale-green fill, no gold fill, and no hyperlink** — projection drivers are
  assumptions, not deepKPI- or 10-K-sourced actuals.
- **Exception to the "formulas are black" rule.** A projection driver keeps the red
  font + dashed border **even though its default value is a live formula** (the
  seeding formula below). The red/dashed treatment marks it as the intended
  override point; every **non-driver** projection cell stays standard formula
  styling (black font, no fill, no dashed border) — identical to its historical
  styling, just dragged one column right.

This is the same convention the store roll-forward uses for its projected flow and
`Other` drivers, so the two halves of the sheet read consistently.

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
  styling flags exactly which cells are meant to be overwritten.

**One exception**, stated again where it arises: the **53rd-week** line stays a
**dash** unless the issuer's fiscal calendar puts a 53-week year inside the window
(Part 3).

The three major parts of the build — **the cohort partition**, **the revenue build**
(comparable + non-comparable cohorts), and **the consolidated revenue build** —
project as follows, and **repeat per banner** exactly as the historical sections do.

### Part 1 — Cohort partition (§1): no new drivers

The comparable / non-comparable cohort partition introduces **no new projection
drivers** — its only forward-moving dependencies are **store openings** and the
**EOP balance**, and **both already live in the store roll-forward**, where they
were turned into drivers by `../locationBuild/locationBuild.md` (its Projections
section, which inverts EOP from input to formula and makes the flows and `Other`
the drivers). Every cohort cell is a formula, so **drag the entire §1 block across
into the projection columns unchanged**:

- The cohort assumptions (`T`, `R`, stub-year fraction) are **single
  absolutely-referenced cells** — they do not change by period and need nothing for
  projection.
- The **lookback-openings rows** and the **weighted year-of-opening rows** reference
  the store roll-forward's flow row through the per-tier reference of §1.7. In
  every projection column those references resolve to the roll-forward's
  **projected driver** cells — `Store Openings` on Tier 1, `MAX(0, Net Stores
  Opened / (Closed))` on Tier 2, `MAX(0, Net Change)` on Tier 3 (an `N+2`
  column's "one fiscal year ago" cell, for instance, points at the projected
  `N+1` flow); they remain **formulas**, never new inputs.
- `Opened in Current Yr` = the same per-tier reference to the projected driver;
  `Total Non-Comparable Cohort` = the `SUM` of the weighted rows;
  `Total Comparable Cohort` = roll-forward **EOP (projected)** − `Total
  Non-Comparable Cohort`; the `Comparable as % of total` memo = comp ÷ EOP.
- The optional `Memo: Reported comparable store count` row is a **historical-only**
  disclosure. Leave it **blank (dash)** in every projection column.

**Two retail-specific projection cases the restaurant build does not have:**

1. **Tier-2 (net-flow) fleets.** If §1.5 put the openings rows on the floored
   net-flow proxy historically, the **same proxy carries forward automatically** —
   the roll-forward's projected driver on a Tier-2 roll is a single
   `Net Stores Opened / (Closed)` cell, and the cohort's `Opened in Current Yr`
   references it through the same `MAX(0, …)` as in history. A driver set
   negative for a shrinking banner therefore yields zero openings and a fully
   comparable fleet in that year, with no special case. Repeat the caveat
   comment in the first projection column so it is visible on the forecast side
   too.
2. **Tier-2 or Tier-3 fleets using the §1.5 inversion.** Where `Total Comparable Cohort` is
   the **reported input** historically and `Total Non-Comparable Cohort` is the
   plug, there is **no reported comparable count to project**. Invert once more:
   relabel the row **`Comparable as % of total`** — no `Memo:` prefix, because a
   formula now reads it: derived in history, red driver forward, the same shape as
   every rate-driver row in the revenue builds — and make it the
   projection driver (red/dashed;
   `N+1` = the default seed (the latest historical percentage), `N+2 … N+5` = `N+1`), then
   `Total Comparable Cohort = ROUND(<projected EOP> × <Comparable as % of total>, 0)`
   and `Total Non-Comparable Cohort = <projected EOP> − <Total Comparable Cohort>`.
   Record the switch in the Notes block (§5.5), *"Revenue: in the forecast the
   comparable count is a share of the period-end fleet, held at the latest
   reported share; the non-comparable count is the remainder,"* and keep the
   identity `Comparable + Non-Comparable = EOP` intact.

**Logic double-checked — confirmed no ordinary §1 driver is needed.** Because
openings is the sole forward dependency and it is sourced upstream from the
(already-projected) store roll-forward, the cohort partition foots forward purely
by dragging its formulas. `R` is a fixed single-cell assumption, so the
comparability anchor needs nothing forward. If a future issuer ever needs a forward
cohort assumption beyond openings (or the Tier-3 percentage above), flag it rather
than inventing a hidden driver.

### Part 2 — Revenue build

**Net Sales from the Comparable Cohort (§2) — driver: `Comparable-Store Sales
Growth` only.** Per banner (at the comp-reporting level, §1.10), the **single**
projection driver is the comp row; apply the driver styling and the
default-seed methodology to it (`N+1` = the guided comp for `N+1` at this banner's
scope, else the latest reported quarter's comp after `N` as a green hyperlinked
input, else year `N`'s comp; `N+2` = `=AVERAGE(<comp N−2>:<comp N>)` over the
historical annual values, the long-run reversion that is the comparable-sales
builds' one average seed; `N+3 … N+5` = `= <comp N+2>`). Every other row in the
five-row bridge is a **formula dragged across unchanged**:

- `Previous Year's Comparable-Cohort Net Sales` = prior column's `Net Sales from the
  Comparable Cohort` (row 5).
- `Net Sales per Comparable Store — prior yr` = `Previous Year's …` ÷ prior column's
  `Total Comparable Cohort` (§1).
- `Estimated Net Sales per Comparable Store` = `prior-yr per store × (1 + comp %)`.
- `Net Sales from the Comparable Cohort` = `Estimated Net Sales per Comparable Store
  × this column's Total Comparable Cohort` (§1, projected).
- `Total Net Sales from the Comparable Cohort` = `SUM` of each banner's row 5.

If the optional comp decomposition rows (Transactions / Average Transaction Amount /
AUR / UPT) were carried historically, **leave them blank (dash) in the projection
columns** — they are disclosure-only memos and never drove the bridge.

**Net Sales from the Non-Comparable Cohort (§3) — driver: `YoY %`.** Take each line
item as follows:

- **`Store Net Sales`** (the `Net Sales per Store` numerator) is a **historical-only**
  input or derivation. Keep its historical cells exactly as §3.2 / §3.4 set them,
  and **leave every projection-year cell blank (dash)** — it is not projected.
  *(This applies whether the historical cell was a reported input or the derived
  `total net sales − non-store channels` formula: in projection, total net sales is
  itself an output of the build, so the derivation would be circular.)*
- **`Net Sales per Store — system avg`** — **definition unchanged for historical**
  (= store net sales ÷ company-operated EOP). For **projection** columns it switches
  to compounding off the prior year:
  `= <prior column Net Sales per Store> × (1 + <YoY %, this column>)`. (Because
  `Store Net Sales` is blank in projection, the historical ratio definition cannot
  be used; the line instead grows off its own prior value by the driver.)
- **`YoY %`** — the **driver** for this block. Historically it is **derived**
  (`= this col ÷ prior col − 1`); in projection it **inverts** to become the forward
  assumption (red/dashed; `N+1` = the default seed: the guided value, else the latest
  historical `YoY %` value; `N+2 … N+5` = `N+1`).
- **`Net Sales from the Non-Comparable Cohort`** — **unchanged formula**:
  `= Net Sales per Store × 0.5 × Total Non-Comparable Cohort (§1, projected)`.
- `Total Net Sales from the Non-Comparable Cohort` = `SUM` of each banner's row.

(The inversion mirrors the store roll-forward: historically the level is the
formula and the change is derived from it; in projection the change is the driver
and the level compounds off it.)

### Part 3 — Consolidated revenue build (§4 franchise & channels, §5 Other + Total, §6 table)

- **`Total Net Sales from the Comparable Cohort`** and **`Total Net Sales from the
  Non-Comparable Cohort`** — the **same `SUM` formulas** as the historical columns;
  drag them across.
- **`Franchise & License Revenue` (§4.1) — driver: its `YoY %`.** Only if the
  line was laid (a franchise or license revenue series exists, §4.1):
  - The franchise **`YoY %`** row becomes the **driver** (red/dashed; the default seed, then flat).
  - **`Franchise & License Revenue`** is **unchanged for historical** (reported
    input). For **projection**: `= <prior column Franchise & License Revenue> × (1 +
    <YoY %, this column>)` — the same input → compounding inversion as the lines
    above.
  - Apply this wherever the line lives: **per banner** if the issuer reports it per
    banner, otherwise **once** in the consolidated table (§6.3).
- **Each `Non-Store Channel Revenue` line (§4.2) — driver: its own `YoY %`.** Every
  channel line that survived the §4.2 include test gets the **same** treatment as
  franchise revenue: its `YoY %` row becomes the red/dashed driver (default seed,
  then flat), and the level line becomes
  `= <prior column level> × (1 + <YoY %, this column>)` in the projection columns.
  Channels are **independent drivers** — do **not** grow digital, wholesale and
  membership off one shared rate; each has its own.
- **`53rd-Week Net Sales Contribution` (§4.4) — dash by default.** Leave every
  projection cell a **dash** unless the issuer's 52/53-week fiscal calendar places a
  53-week year inside `N+1 … N+5`. If it does, style that one cell as a driver
  (red/dashed), seed it to the **most recent historical 53-week contribution** (not
  year `N`'s cell, which is a zero in a 52-week year), and
  record it on the §4.4 calendar line of the Notes block (§5.5): *"Revenue:
  FY<n+k> is a 53-week year on the issuer's calendar; its extra-week sales are
  seeded from FY<n>."*
- **`Other Revenue` — a share of modeled revenue.** Historically `Other Revenue` is
  the **plug**. There is no reported total in the projection columns, so it cannot
  stay a plug, and it is never seeded to zero dollars (that would step projected
  revenue down at `N+1`). Its row beneath, `Other Revenue — % of modeled revenue`, holds
  the historical ratio of the plug to `Net Sales from Stores + the §4 lines inside
  net sales` and, in projection, is the **driver** (red/dashed, the default seed then flat, like every other driver); `Other Revenue = that driver
  × (Net Sales from Stores + the §4 lines inside net sales)`. The denominator
  excludes the plug itself, so there is no circularity. *(Where the historical plug
  was persistently non-trivial because a channel could not be quantified, say so in
  the driver's cell comment so the modeler knows what the ratio is carrying.)*
- **`Net Sales from Stores`** — the **same sum formula** as the historical columns.
- **`Net Sales` and `Total Revenue` — the foot.** The identities **`Net Sales from
  Stores + §4 lines inside net sales + Other = Net Sales`** and **`Net Sales + §4
  face lines = Total Revenue`** hold in **both** halves, so both totals are always
  the sum of their components and **never a driver** (no red/dashed) in either
  half. The only thing that changes is *which* cell is the free input:
  historically `Net Sales` and `Total Revenue` are **reported inputs** and `Other`
  is the plug; in projection `Other` is driven off its ratio row, so each total is
  written **directly as the sum of its components** (drop any term not built; with
  no `Net Sales` row, `Total Revenue` is the single sum `Net Sales from Stores +
  every §4 line + Other`). The `components − Total (must = 0)` foot-check memo
  then evaluates to **0** in every projection year (trivially, since each total is
  defined as its sum).

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=`
  formula (no hardcoded numbers). The **only** seeded/typed cells are the drivers:
  per-banner comp % (§2), per-banner non-comparable `YoY %` (§3), franchise
  `YoY %` (§4.1), each non-store channel's `YoY %` (§4.2), the optional 53rd-week
  cell (§4.4), the consolidated `Other Revenue — % of modeled revenue`, and — on a
  Tier-2 / Tier-3 inversion fleet only — `Comparable as % of total` (Part 1's
  inversion driver). `Store Net Sales`
  projection cells are **blank**.
- **Driver seeding.** Each driver's `N+1` = the default seed (the guided value where the guidance table names it, else the latest historical year) and `N+2 … N+5` = `N+1`, the ratio driver included — except the
  53rd-week cell.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors**.
- **Foot.** The consolidated `components − Total (must = 0)` memo equals **0** in
  every projection year, and the cohort identity `Comparable + Non-Comparable = EOP`
  still holds (store roll-forward EOP projected).
- **Continuity at the boundary.** `N+1` `Previous Year's Comparable-Cohort Net Sales`
  equals `N` `Net Sales from the Comparable Cohort`; `N+1` `Net Sales per Store`,
  `N+1` `Franchise & License Revenue` and each `N+1` channel level compound off their
  `N` values — the projection joins the actuals with no gap or jump.
- **Plausibility.** No projected cohort count goes negative; the projected
  `Comparable as % of total` does not exceed 100% or fall below its historical range
  without a reason; and projected `Net Sales per Store` does not diverge implausibly
  from its historical trend. A projected non-comparable cohort that collapses to
  near zero means the store roll-forward's openings drivers were set to zero —
  check that this was intended.

## Section 8 — What the revenue build produces for downstream sections

After Sections 2 – 6 are built, the workbook contains, for every period in the
window, a fully-footed revenue build beneath the §1 cohort blocks:
`Total Net Sales from the Comparable Cohort`, `Total Net Sales from the
Non-Comparable Cohort`, `Net Sales from Stores` (their sum — the store-level
base the cost build divides by), `Franchise & License Revenue` (if applicable),
the non-store channel lines (if applicable), `Other Revenue` (plug), `Net Sales`
(reported; only when the issuer reports a separate revenue face line — the base
the cost build strikes cost of sales against), and `Total Revenue` (reported) —
every component a live formula flowing from the §1
cohort counts, the store roll-forward's EOP / openings, and the comp / net-sales
inputs. Downstream operating-model sections (costs, consolidated financials)
reference **`Total Revenue`** and the component lines directly; any later change to
the store roll-forward, the cohort partition, or a comp input propagates
automatically through the entire revenue build and keeps the foot intact. Beneath
it all sits the single **`Notes`** block (§5.5) carrying every basis statement for
the build — the last rows on the sheet.

**Hand back to the router** with:

- the **comparable definition** read (T, anchor, R, remodel/relocation treatment,
  52-week basis, and whether digital is inside the comp base),
- the **flow-disclosure tier** and the §1.5 path taken (including any net-flow proxy
  or Tier-3 inversion),
- the **cohort spot-check** result against the issuer's reported comparable store
  count, where one is disclosed,
- which **§4 lines were included and which omitted**, with the reason for each,
- the size of the **`Other Revenue` plug** as a % of total revenue in the most
  recent year, and
- any cells taken as **10-K overrides** because the deepKPI series was scaled,
  cross-tagged, or missing.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the
  chain. Pull specific series via `search_kpis` against that inventory, and use the
  **filing** skill (`list_sec_filing_markdowns` → `get_sec_filing_markdown`) for the
  comparable-store definition, the net-sales walk, and any 10-K override values.
- **Adopt the store roll-forward's fiscal-year column mapping; never re-derive one.**
  Retail stamp conventions differ between series within a single issuer (§0.1), so a
  date-string join is the highest-probability silent error in this build.
- This build writes **only** the revenue lines beneath the store roll-forward.
  Square footage belongs to `../sqftBuild/sqftBuild.md`; product-level unit
  economics belong to `../unitsBuild/unitsBuild.md`. Do not add rows from either
  here, even when the data is abundant — square footage may be used as a *diagnostic*
  cross-check (e.g. `net sales per store ÷ average store size ≈ reported sales per
  square foot`), never as a line item.
- **Every note goes in one `Notes` block at the very bottom of the build (§5.5) —
  never as italic-gray rows under section sub-headers.** Record there, in analyst
  words: the comparable-store definition and its source filing year; the
  comparable base with its new-store window and stub-year fraction; any openings
  proxy or inversion the cohort rests on; the universe and the comp application
  level; each channel carried or left inside comparable sales; every 10-K
  override cell and why; which fiscal year in the window (if any) had 53 weeks;
  and the `Other Revenue` plug as a percentage of net sales (of total revenue for
  a single-revenue-line issuer) in each year. The flow tier and path, the cohort
  spot-check result, the adopted fiscal-year mapping and every channel omitted
  because nothing is reported go to `BUILD_LOG.md`. The only italic-gray rows left inside
  the build are §1.6's three zone labels (`⤷ Cohort assumptions`, `⤷ Cohort
  lookback inputs`, `⤷ Base-year seed`), which head the rows beneath them rather
  than footnoting them.
- The **0.5 partial-year factor** and the **`(R mod 12)/12` stub-year fraction** are
  framework constants. Do not tune either per company — that is what makes cohort
  economics comparable across issuers, and any resulting imprecision is carried
  visibly by the `Other Revenue` plug and the §5.1 residual memo rather than hidden
  inside an unfalsifiable assumption.

## Dependencies — rows this build references but does not lay

Per `../../../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Company-Operated EOP Balance` for the banner (`coeop_<banner>`; the `EOP Balance` from the store roll-forward) | location build (`../locationBuild/`) | the retail router's location gate PASSED | none — return `ABORTED` |
| `Store Openings` / `Store Closures` for the banner (the rows `Opened in Current Yr` references; store roll-forward openings) | location build | a gross split is disclosed — the deepKPI flow series (Tier 1) or the 10-K store activity table per banner (§1.5 Tier 2, path 1) | §1.5 Tier 2 paths 2–3 (consolidated-level cohort; invert the reported comparable count); Tier 3 per §1.5 |
| `Net Stores Opened / (Closed)` for the banner | location build | the issuer publishes only a net figure (Tier 2) | — |
