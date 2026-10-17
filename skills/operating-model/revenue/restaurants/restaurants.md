---
name: revenue-restaurants
description: >
  ROUTER — restaurant-industry revenue router for the operating-model workbook.
  Invoked by the revenue router (`revenue/revenue.md`) once the company has been
  classified as a restaurant business. This skill does NOT build the revenue
  model itself. It receives the resolved `company_id`, official company name,
  workbook path, and the shared KPI inventory; FIRST, if the inventory contains
  a total location count KPI, it invokes `locationBuild/locationBuild.md` to lay
  down the restaurant unit roll-forward; THEN it evaluates which restaurant-
  revenue KPIs are available and routes the build to exactly one sub-build sub-
  skill: `comparableStoresBuild/` (full comparable-store-sales dataset),
  `comparableSalesGrowthBuild/` (comp % / price-traffic decomposition + revenue
  + location count, without cohort dollars), `revenuePerRestaurantBuild/`
  (revenue + total location count only), or `other/` (catch-all). The chosen sub-
  skill performs the actual revenue deepKPI pulls
  and lays out line items beneath the `REVENUE` ALL-CAPS header, formatting per
  ../../../_common/revelata-excel-styling-rules.md.
---

# revenue — restaurants (location build + build-type router)

This sub-skill is part of the `operating-model` system and owns two
responsibilities within the **restaurant** industry for the **REVENUE** section:

1. **Lay down the location (unit) roll-forward**, when the company reports total
   location counts, by invoking `locationBuild/locationBuild.md`.
2. **Route** to the correct revenue sub-build based on which restaurant-revenue
   KPIs are available.

By the time control reaches this file, two things are already known:

1. the company **is in the restaurant industry** (decided by the parent revenue
   router, `../revenue.md`), and
2. the **full set of KPIs available for the company** — the **shared KPI
   inventory** — has already been collected by the orchestrator.

This file does **not** build the revenue model itself, and its only deepKPI calls
are the narrow Step 2.0 confirmation lookups. The location build is delegated to
`locationBuild/locationBuild.md`; the franchise revenue lines inside the three
unit-based sub-builds (`comparableStoresBuild/`, `comparableSalesGrowthBuild/`,
`revenuePerRestaurantBuild/`) come from the shared block
`franchiseRevenueBuild/franchiseRevenueBuild.md`, which each of them reads inline
at its franchise section (it is a component, not a route — this router never
dispatches to it; `other/` has no franchise section and carries franchise revenue,
where reported, as a segment on its own growth rate); the revenue build is
delegated to one of the four revenue sub-builds.

**Inputs expected from the parent router:** resolved `company_id`, official
company name, the path to the scaffold workbook, and the **shared KPI
inventory**.

**Data source:** deepKPI only — see `../../../_common/data-source-rules.md`. On
failure, follow `../../../_common/connection-failure.md`.

**Formatting:** the downstream sub-builds follow
`../../../_common/revelata-excel-styling-rules.md` and build with the **xlsx**
skill.

## Step 1 — Location build (conditional)

Before routing, check the **shared KPI inventory** for a **total location count**
KPI for the company. This includes any series that reports the company's total
restaurant / unit count — system-wide totals, company-owned location counts,
franchised location counts, or per-concept counts that together comprise the
total. Match patterns include (non-exhaustive): `"<Brand> company restaurant
count"`, `"<Brand> franchise restaurant count"`, `"Number of <Brand> Restaurants
at End of Period"`, `"<Brand> restaurant count - company restaurants"`, and
similar total-units series.

- **If at least one total location count KPI is present in the inventory →**
  invoke **`locationBuild/locationBuild.md`**, passing it the resolved
  `company_id`, official company name, workbook path, and the shared KPI
  inventory. The location build will lay down the per-concept restaurant unit
  roll-forward (Locations, Openings, Closures) beneath the `REVENUE` ALL-CAPS
  header. When it returns, **continue** to Step 2.
- **If no total location count KPI is present →** skip the location build and
  proceed directly to Step 2.

State the outcome of this check (one line, citing the specific KPI(s) that did
or did not satisfy the trigger) before continuing, so the decision is auditable.

Do **not** re-run `list_kpis` for this check — only inspect the shared KPI
inventory that was passed down. This file lays down **no** line items and makes
**no** deepKPI calls of its own, with one narrow exception: the confirmation
`search_kpis` lookups permitted in Step 2.0, used solely to verify that a
candidate series carries values for the build window. The location build, if
invoked, performs its own `search_kpis` pulls against the shared inventory.

## Step 2 — Evaluate available KPIs against the build criteria

Inspect the **shared KPI inventory** (do **not** re-run `list_kpis`) and check,
in priority order, whether the company satisfies the requirements for each build
type. Pick the **first** build type whose **necessary** criteria are fully met.
The "if applicable" items are *not* required to route — they only enrich the
downstream build when present.

> **Strict ≠ hasty. The strictness below is a bar on the DATA, not a license to
> under-search.** The strict dollar test in build A decides whether the
> comparable-cohort **dollars exist in deepKPI** — it does **not** authorize you to
> stop looking for them. A false "not found" silently downgrades a comparable-stores
> company to a coarser build (B or C), which is a **worse**
> outcome than the harshness is meant to prevent. So you **must** complete the
> Step 2.0 exhaustive discovery below **before** evaluating any build's criteria.
> Never conclude a KPI is absent from a hunch, from the company's reputation ("they
> usually only give a comp %"), or from a couple of `search_kpis` guesses.

### Step 2.0 — Exhaustively search the FULL inventory for the comparable-revenue bridge (MANDATORY — do not rush)

This step runs **before** A/B/C/D are evaluated. Its sole purpose is to make sure
that if the comparable-cohort **dollar** series exists anywhere in deepKPI, you
find it — because that single series is what unlocks the richer build A. **If the
comparable-store-cohort dollars KPI is in the inventory, there is no acceptable
reason to miss it.**

1. **Use the COMPLETE inventory, not a sample.** The orchestrator's `list_kpis`
   returns the entire KPI catalog — often **hundreds** of entries, and frequently
   **too large to read inline, so it is saved to a file**. You must scan **all of
   it**, across **every** category (`Company KPIs`, `Segment Financials`,
   `Consolidated Income Statement`, `Consolidated Balance Sheet`,
   `Consolidated Cash Flow`, …). If it was saved to a file, **parse / grep the
   whole file** — do **not** skim the first screenful, and do **not** substitute
   your own recollection of what the company "typically" discloses.

2. **Hunt explicitly for the revenue-walk bridge lines.** Issuers that report a
   comp **%** almost always publish a dollar revenue walk in MD&A; its lines are
   what satisfy build A. Token-scan the full inventory **and** confirm with
   `search_kpis`, for each family below. Treat any hit carrying a **USD / dollar**
   unit as satisfying the corresponding bridge component:
   - **Comparable-cohort dollars (the situation-1/2 anchor):**
     `Change in Revenue from Comparable Restaurant Sales`,
     `Revenue from comparable restaurants`, `Comparable restaurant sales` *(USD)*,
     `Increase/(decrease) in revenue from comparable restaurant sales`,
     `Comparable sales contribution to revenue`,
     `Change in revenue attributable to comparable restaurants`,
     `Sales from restaurants in the comparable base`.
   - **Comparable-sales % (pairs with the dollar change for situation 2):**
     `Comparable restaurant sales increase/(decrease)`, `Same-store sales`,
     `Comparable sales growth`.
   - **Non-comparable / new-unit dollar contribution (the other necessary Revenue
     item):** `Change in Revenue from Restaurants Not Yet in Comparable Base`,
     `Revenue from non-comparable restaurants`, `New restaurant revenue`,
     `Change in Revenue from Closures`, `Change in Revenue from Other Adjustments`.

3. **Search EVERY category — the names hide.** These bridge lines are routinely
   filed under naming that does **not** sit in an obvious "comparable sales" bucket
   (e.g. they may appear as plain `… - Year ended` strings next to income-statement
   lines). Scan the whole inventory string for the tokens above, then `search_kpis`
   the **exact** names you find to confirm each series carries values for the build
   window.

4. **Read the `unit` field, not just the label.** A comparable-sales series with
   `unit: percent` is the **%** input; the same concept with `unit: USD` is the
   **dollar** input. Build A's strict test is met by the **USD** comparable-cohort
   level (situation 1) **or** by the **USD** comparable-sales *change* paired with
   the **%** (situation 2).

5. **Only after this full scan comes up empty** may you conclude the comparable
   dollars are absent. In the Step 2 / Step 3 audit line, state the **exact tokens
   you searched** and that they returned **no dollar series** — so "not found" is
   verifiable, never a guess.

### A. Comparable-stores build — `comparableStoresBuild/`

Route here when the company reports a **comparable-store-sales** dataset rich
enough to bridge revenue from a comparable cohort. All of the following
**necessary** items must be present:

- **Location**
  - *necessary:* Location count
  - *if applicable:* unit openings & closings; domestic vs. international split; franchise vs. company owned.
- **Revenue**
  - *necessary:* comparable-store sales growth % (with breakdown if available);
    **beginning-of-period and end-of-period revenue**; **the dollar revenue of
    the comparable cohort** (read the STRICT requirement below — this is a
    **dollar** requirement, not a percentage); and revenue from stores **not** in
    the comparable cohort (or the change in revenue attributable to
    non-comparable stores).
  - *necessary:* the comparable-store sales growth % is reported for the
    **company-operated universe** — a caption such as `company-owned comparable
    restaurant sales`, or a comp the issuer defines on company restaurants. An
    issuer whose **only** comp is **systemwide** (company and franchised units
    together) does **not** meet this item: the comparable-stores build partitions
    company-operated revenue, and franchise restaurant sales never pass through
    the income statement, so a system comp has no dollar base there. Read the
    universe off the caption in the inventory; it is an inventory test, not a
    judgment.
  - *if applicable:* company-owned revenue vs. franchised revenue.

> **STRICT — BE HARSH HERE. The comparable-cohort revenue item is a DOLLAR
> requirement, not a percentage.** "Revenue from stores **in** the comparable
> cohort (or the change in revenue attributable to comparable stores)" is only
> satisfied when you can obtain an absolute **dollar** figure for the comparable
> cohort. A comparable-store **sales growth %** **alone does NOT satisfy it** — a
> percentage tells you how fast the cohort grew but not the dollars it generated,
> so the build cannot seed the comparable bridge from it without fabricating a
> base. Do not be lenient or "read the parenthetical generously." To route here,
> **exactly one** of these two situations must hold:
>
> 1. **The actual dollar revenue generated by the comparable store base** is
>    reported (directly usable as the cohort's revenue), **or**
> 2. **Both** the comparable-store sales growth **%** **and** the **dollar amount
>    attributable to that %** (the reported dollar change in revenue from the
>    comparable cohort) are reported. From these two you can back into the
>    comparable cohort's beginning-of-period dollar revenue
>    (`prior-period comparable revenue = dollar change ÷ growth %`), which is what
>    the build needs to seed the bridge.
>
> If **neither** situation holds — i.e. **after the mandatory Step 2.0 exhaustive
> search of the full inventory** the issuer is confirmed to report only a comp
> **%** plus a comparable store **count**, with no comparable-cohort dollar level
> and no directly reported dollar change attributable to the comparable cohort —
> then this necessary item is **NOT met**. Do **not** route to the comparable-stores
> build; fall through to the comparable-sales-growth build (B), then the
> revenue-per-restaurant build (C). **"Not met" is a
> conclusion you may reach only once the Step 2.0 scan has actually run and come up
> empty — never from memory, the company's reputation, or a couple of `search_kpis`
> guesses.** A dollar change that can only be derived as a **residual** (e.g. total
> sales change minus a separately reported new-store contribution) is **not** a
> directly reported comparable-cohort dollar figure and does **not**, on its own,
> satisfy this item — hold the line.
>
> **Why this is strict (do not paper over it).** The comparable bridge must seed
> the base (leftmost) year's comparable-cohort **dollar** revenue. If no
> comparable-cohort dollar figure exists, the only fallback is to approximate
> that seed as *prior-year total revenue ÷ prior-year total store count* — the
> blended revenue per store across **all** units. That silently treats
> **comparable** and **non-comparable** (newer, still-ramping) stores as
> identical: it divides total EOP revenue by total EOP stores and assumes the
> comparable cohort earns the same per-store revenue as the brand-wide average.
> That assumption is **invalid** — comparable stores are more mature and earn
> more per unit — and it understates true comparable per-store revenue, dumping
> the error into the Other-revenue plug. Requiring the dollars up front (situation
> 1 or 2) is what prevents this bad assumption. **But strictness is a bar on the
> data, not on your effort: when the comparable-cohort dollars are not obvious,
> re-run the Step 2.0 exhaustive scan in full before falling back — route to (B)
> or (C) only once you have positively confirmed those dollars are absent from the
> entire
> inventory, never on a hunch or a half-search.**

> **Worked example — Chipotle Mexican Grill (CMG): a comparable-stores company
> that is easy to mis-route to (B).** Chipotle reports comparable restaurant sales
> as a **%** (`Comparable restaurant sales increase/(decrease)` — e.g. +7.9% /
> +7.4% / −1.7%) **and** a directly reported **dollar** bridge: `Change in Revenue
> from Comparable Restaurant Sales` (e.g. +$636.3M / +$695.4M / −$191.3M), plus
> `Change in Revenue from Restaurants Not Yet in Comparable Base Opened in <year>`,
> `Change in Revenue from Closures`, and `Change in Revenue from Other Adjustments`.
> The dollar comparable-sales change is **directly reported** (not a residual), so
> **situation 2 is satisfied** — back into the prior-year comparable base as
> $695.4M ÷ 7.4% ≈ $9.4bn — and Chipotle routes to **A (comparable-stores)**. These
> series sit in the inventory under `… - Year ended` naming, **not** under an
> obvious "comparable sales" heading; a hasty scan that assumes "Chipotle only gives
> a comp %" wrongly falls through to (B) or (C) and produces a coarser build. This is the
> exact miss Step 2.0 exists to prevent.

If every necessary Location and Revenue item above is available — **including the
strict comparable-cohort dollar requirement (situation 1 or 2 above), confirmed
present by the Step 2.0 exhaustive search** — route to
**`comparableStoresBuild/comparableStoresBuild.md`**.

### B. Comparable-sales-growth build — `comparableSalesGrowthBuild/`

If the comparable-stores criteria are **not** fully met (no comparable-cohort
**dollar** series per build A's strict test — confirmed by Step 2.0), check this
build **before** the revenue-per-restaurant build. Route here when all **necessary**
items are present:

- **Restaurant**
  - *necessary:* **Revenue**, **total location count**, and **at least one**
    comparable-sales signal — either a reported **restaurant comparable-store
    sales growth %**, **or** its decomposition (menu price / average check /
    guest traffic).
  - *explicitly NOT required:* the comparable-cohort **dollar** series (situation
    1 or 2 from build A). That requirement is what separates this from build A.
  - *if applicable:* menu-price / mix / traffic split; quarterly comp series (for
    recency seeding in the downstream build); comp % on non-restaurant product
    lines (e.g. retail); unit openings / closures (via the location build).

> **Worked example — Cracker Barrel (CBRL):** reports restaurant comp %, average
> menu price increase, average check, guest traffic, restaurant revenue, and
> location count, but **not** a comparable-cohort dollar bridge → routes to **B
> (comparable-sales-growth)**, not A and not the blended rev/restaurant build (C).

If the criteria above are met, route to
**`comparableSalesGrowthBuild/comparableSalesGrowthBuild.md`**.

### C. Revenue-per-restaurant build — `revenuePerRestaurantBuild/`

If builds A and B are **not** met, check this build. Route here when both
**necessary** items are present:

- **Restaurant**
  - *necessary:* **Revenue** and **total location count**.
  - *and:* **no** comparable-store sales growth % or decomposition was found in
    the inventory (otherwise build B would have matched first).

This drives the model off **blended** revenue per restaurant (revenue ÷ total
units, single flat YoY %). If both are available and no comp signal exists, route
to **`revenuePerRestaurantBuild/revenuePerRestaurantBuild.md`**.

### D. Other — `other/`

If none of the comparable-stores, comparable-sales-growth, or
revenue-per-restaurant criteria are satisfied, route to the catch-all
**`other/other.md`**.

## Step 3 — Route to the sub-build

Hand the build to exactly one sub-skill, passing it **all of the inputs this
router received** — resolved `company_id`, official company name, workbook path
(with the unit roll-forward already laid down if Step 1 ran), and the shared KPI
inventory — plus a note of **which KPIs satisfied the criteria** for the chosen
build type.

- Comparable-stores criteria met → **`comparableStoresBuild/comparableStoresBuild.md`**
- Else, revenue + location count + comp % or decomposition present →
  **`comparableSalesGrowthBuild/comparableSalesGrowthBuild.md`**
- Else, revenue + total location count present (no comp signal) →
  **`revenuePerRestaurantBuild/revenuePerRestaurantBuild.md`**
- Else (default) → **`other/other.md`**

Every restaurant company resolves to exactly one of these four routes — there is
no "no build" outcome.

State which route you picked and why (one line, citing the specific KPIs that did
or did not satisfy each criterion) before handing off, so the routing decision is
auditable.

## Step 4 — Hand off

The chosen sub-build is responsible for its own deepKPI pulls (using
`search_kpis` against the shared inventory for the specific series it needs),
period columns, formulas, provenance hyperlinks, and styling for the revenue
section. This router does **not** write to the workbook itself; once it has
invoked the location build (if applicable) and routed, the revenue sub-build
takes over the rest of the REVENUE section.

## Step 4.1 — If the sub-build returns `ABORTED`

A sub-build may discover, after the Step 2.0 scan and its own sourcing (deepKPI,
then the 10-K where its text allows), that a **necessary input is unobtainable**
— the comparable-stores build's base-column seed or comparable count, for
example. It then stops writing and returns the fixed outcome
**`ABORTED — <necessary item> unobtainable`**, naming the item, what it searched,
and the sections and rows it had already laid. It never names another build;
routing belongs to this router. On receiving that outcome:

1. **Record it** in one line in `BUILD_LOG.md` — the aborted route, the missing
   item and the sources searched — so the decision is auditable; this router's
   hand-back report carries the same line. The workbook's Notes block carries
   none of that history. When the revenue section is complete it gets one line
   stating the approach actually taken, in the analyst's words, for example
   "Revenue: modeled on comparable-sales growth because the filing discloses no
   cohort dollars."
2. **Drop every row the aborted build laid.** Under the compose-then-render
   mechanic (`../../SKILL.md`, "Build mechanics") omit that build's section module
   from the parts and re-render; the location build's rows are untouched.
3. **Re-evaluate Step 2 with the aborted build excluded**, applying the same
   criteria in the same order, and hand off per Step 4. The hand-back is what
   excludes the build, not a new criterion: the router tests only what the
   inventory shows, and the aborted build has already tested the rest.

The "no build" outcome stays unreachable: with (A) excluded, the fall-through
(B), then (C), then (D) always catches the company.
## Step 4.2 — If a sub-build returns `DEFECT UPSTREAM`

A `DEFECT UPSTREAM` record returned by any stage beneath this router is **returned
unchanged as this router's own outcome** — this router never acts on it, names a level, or
re-runs anything on its own. When the orchestrator (`../../SKILL.md`, Step 4.2) asks this router
to **re-run from a named stage forward**, re-run that stage with the finding it carries and
then every stage after it in this router's order, running the route selection again as
part of that; return the re-issued hand-back reports.

The one case that stays inside this section — a cohort build finding that the location
build laid no row it is entitled to expect — still goes up and comes back: the
orchestrator's instruction to re-run from the location build forward is what re-runs the
location build, re-evaluates Step 2 and re-runs the sub-build.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the
  chain. Its **only** permitted deepKPI calls are the narrow confirmation
  `search_kpis` lookups of Step 2.0; otherwise it only reads the inventory to
  decide whether to invoke the location build and which revenue sub-build to
  hand off to.
- Evaluate revenue-build criteria in order (A → B → C → D) and stop at the first
  match, so the richest build a company qualifies for is always chosen.
- The location build runs **before** routing because every revenue sub-build can
  benefit from referencing unit counts that are already in the workbook.
- Adding a new restaurant revenue build type later is a matter of creating a new
  sibling folder under `restaurants/` and adding one routing branch in
  Steps 2–3.
