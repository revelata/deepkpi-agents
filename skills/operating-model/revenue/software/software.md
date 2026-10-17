---
name: revenue-software
description: >
  ROUTER — software-industry revenue router for the operating-model workbook.
  Invoked by the revenue router (`revenue/revenue.md`) once the company has been
  classified as a software / technology business. This skill does NOT build the
  revenue model itself. It receives the resolved `company_id`, official company
  name, workbook path, and the shared KPI inventory; it evaluates which software-
  revenue KPIs are available and routes the build to exactly one sub-build sub-
  skill: `arrBuild/` (ARR build — NRR + customer count + subscription/recurring
  revenue), `trBuild/` (take-rate build — booking-based businesses with total
  bookings + corresponding revenue), `arpuBuild/` (ARPU build — user count +
  revenue), or `other/` (catch-all). Before that build runs, it also gates a
  **conditional pre-build**: if customer-count or user-count KPI data is present
  in the shared inventory, it first routes to
  `customerRollForward/customerRollForward.md` to lay down a customer / user
  roll forward on the series the chosen build anchors on, then returns here and
  continues to the chosen build; if neither family is present, the roll forward
  is skipped entirely. The chosen sub-skill performs the actual revenue deepKPI pulls and
  lays out line items beneath the `REVENUE` ALL-CAPS header, formatting per
  ../../../_common/revelata-excel-styling-rules.md.
---

# revenue — software (build-type router)

This sub-skill is part of the `operating-model` system and owns a single
responsibility within the **software / technology** industry for the **REVENUE**
section: **route** to the correct revenue sub-build based on which software-
revenue KPIs are available for the company.

By the time control reaches this file, two things are already known:

1. the company **is in the software / technology industry** (decided by the
   parent revenue router, `../revenue.md`), and
2. the **full set of KPIs available for the company** — the **shared KPI
   inventory** — has already been collected by the orchestrator.

This file does **not** build the revenue model itself and does **not** make new
deepKPI calls to lay down line items. Its only job is routing: read the shared
KPI inventory, decide which build type the company qualifies for, and hand off
to the matching sub-build. The revenue build is delegated to one of the four
revenue sub-builds.

Routing happens in **two stages**, and this router owns **both** of them end to
end:

1. **Conditional pre-build — customer / user roll forward.** If, and only if,
   customer-count or user-count KPI data is present in the shared inventory, route
   to `customerRollForward/customerRollForward.md` **first** (telling it which
   series to track — Step 3), let it finish, and then **return here**.
2. **Build routing.** Continue to exactly one of `arrBuild/`, `trBuild/`,
   `arpuBuild/`, or `other/`.

If customer data is **not** present, stage 1 is skipped entirely and control
goes straight to stage 2.

**Inputs expected from the parent router:** resolved `company_id`, official
company name, the path to the scaffold workbook, the **shared KPI inventory**, and
the **revenue model** the orchestrator's industry classification returned for this
company — `platform`, `subscription`, `advertising` or `mixed`, read once from the
business description at the orchestrator's Step 1.2. Route B and the ARPU anchor
(route C) consume it; this router never reads the description itself. If no
revenue model was passed, **stop** and return control.

**Data source:** deepKPI only — see `../../../_common/data-source-rules.md`. On
failure, follow `../../../_common/connection-failure.md`.

**Formatting:** the downstream sub-builds follow
`../../../_common/revelata-excel-styling-rules.md` and build with the **xlsx**
skill.

## Step 1 — Exhaustively search the FULL inventory for the routing KPIs (MANDATORY — do not rush)

This step runs **before** the build criteria are evaluated. Its sole purpose is
to make sure that if a routing KPI exists anywhere in deepKPI, you find it —
because the same concept is routinely filed under a **different name** than the
one used here. The routing below hinges on correctly recognizing these series;
a false "not found" silently downgrades a company to a coarser build. **If a
routing KPI is in the inventory, there is no acceptable reason to miss it.**

> **Strict ≠ hasty. The criteria below are a bar on the DATA, not a license to
> under-search.** Never conclude a KPI is absent from a hunch, from the company's
> reputation, or from a couple of `search_kpis` guesses. Complete this exhaustive
> discovery **before** evaluating any build's criteria.

1. **Use the COMPLETE inventory, not a sample.** The orchestrator's `list_kpis`
   returns the entire KPI catalog — often **hundreds** of entries, and frequently
   **too large to read inline, so it is saved to a file**. You must scan **all of
   it**, across **every** category (`Company KPIs`, `Segment Financials`,
   `Consolidated Income Statement`, `Consolidated Balance Sheet`,
   `Consolidated Cash Flow`, …). If it was saved to a file, **parse / grep the
   whole file** — do **not** skim the first screenful, and do **not** substitute
   your own recollection of what the company "typically" discloses.

2. **Hunt explicitly for each routing family below.** Token-scan the full
   inventory **and** confirm with `search_kpis`. Read the `unit` field, not just
   the label, to confirm dollars vs. counts vs. percentages. The concept — not the
   exact wording — is what matters; treat any hit that matches the *definition* as
   satisfying that family:

   - **Net revenue retention (the ARR anchor):** `Net Revenue Retention`,
     `Net Dollar Retention`, `Dollar-Based Net Retention Rate`,
     `Net Revenue Retention Rate`, `Net expansion rate`. Any series carrying the
     net-retention meaning (expansion + contraction + churn on the existing
     customer base, expressed as a %) satisfies this — the "net dollar retention"
     naming follows the same logical definition.
   - **Customer count (the recurring-revenue base — and the customer roll-forward
     gate):** `Customers`, `Total customers`, `Customer count`, `Paying
     customers`, `Enterprise customers`, `Customers with ARR > $X`, `Active
     customers`, `Customer additions`, `Net customer adds`, `Customers added`,
     `Customer churn`, `Logo retention`, `Gross retention`. For the ARR build
     this must be the **total** customer count carrying the recurring revenue
     streams, not a narrow sub-cohort only. For the **customer / user roll
     forward** (Step 3) the bar is looser: **any** customer-count series — total,
     a meaningful cohort, or an adds / churn series — counts as customer data
     being present. This family and the **user count** family below together
     gate that pre-build, so search both especially carefully; a missed series
     silently skips the roll forward as well as downgrading the build.
   - **Subscription / recurring revenue (the ARR revenue line):**
     `Subscription revenue`, `Recurring revenue`, `Annual Recurring Revenue
     (ARR)`, `Subscription and support revenue`, `SaaS revenue`, `Platform
     subscription revenue`. This may **not** be literally labeled "subscription
     revenue" — determine which revenue stream is **recurring** in nature and
     confirm it is present as its own line.
   - **Total bookings / platform volume (the take-rate anchor):** `Gross
     Bookings`, `Gross Merchandise Value (GMV)`, `Gross Order Volume (GOV)`,
     `Total Payment Volume (TPV)`, `Gross Transaction Value (GTV)`, `Bookings`,
     `Merchandise volume`. This is the total **$ amount of orders / transactions
     booked on the platform** — a dollar (USD) series, not a count.
   - **Revenue corresponding to those bookings (the take-rate numerator):** the
     revenue the company recognizes from the platform volume above — `Revenue`,
     `Net revenue`, `Marketplace revenue`, `Transaction revenue`, or a segment
     revenue line that clearly maps to the booked volume. It need only be
     **loosely related** to the bookings, but it must have a clear connection to
     that volume.
   - **Take rate (enriches the take-rate build if present):** `Take rate`,
     `Net revenue margin`, `Revenue as a % of bookings/GMV/GOV`. If it is reported
     directly, capture it; if not, it can be **calculated** downstream as
     revenue ÷ bookings — which is exactly why finding the correct bookings and
     revenue series is crucial.
   - **User count (the ARPU anchor):** `Monthly Active Users (MAU)`, `Daily
     Active Users (DAU)`, `Active users`, `Paying users`, `Subscribers`,
     `Members`, `Monthly Active Platform Consumers`, `Registered accounts`. Any
     series representing the count of users the revenue is earned from. This
     family also gates the roll forward (Step 3); for an ARPU build the series
     selected as the ARPU anchor (criterion C, by the revenue model) is the one
     the roll forward tracks.
   - **Revenue (needed by every build; the sole ARPU / Other requirement):`**
     total `Revenue` / `Net revenue`, plus any segment or stream revenue lines.

3. **Search EVERY category — the names hide.** These lines are routinely filed
   under naming that does **not** sit in an obvious bucket (e.g. a bookings series
   filed next to segment financials, or recurring revenue split across two stream
   lines). Scan the whole inventory string for the tokens above, then `search_kpis`
   the **exact** names you find to confirm each series carries values for the
   build window.

4. **Only after this full scan** may you conclude a series is absent. In the
   Step 2 / Step 3 / Step 4 audit lines, state the **exact tokens you searched**
   and which families returned hits vs. no series — so "not found" is
   verifiable, never a guess.

Do **not** re-run `list_kpis` for this step — only inspect the shared KPI
inventory that was passed down. The chosen sub-build performs its own
`search_kpis` pulls for the specific series it needs.

## Step 2 — Evaluate available KPIs against the build criteria

Inspect the **shared KPI inventory** (do **not** re-run `list_kpis`) and check,
in priority order, whether the company satisfies the requirements for each build
type. Pick the **first** build type whose **necessary** criteria are fully met.
The "if found" items are *not* required to route — they only enrich the
downstream build when present.

### A. ARR build — `arrBuild/`

Route here when the company reports a recurring-revenue franchise rich enough to
drive an ARR model. **All** of the following **necessary** items must be present:

- **Net Revenue Retention** — may be listed as **Net Dollar Retention** (or a
  dollar-based net retention rate); both follow the same logical definition and
  either satisfies this item.
- **Customer Count** — the **total** customer count carrying the recurring
  revenue streams (not merely a narrow sub-cohort).
- **Subscription Revenue** — the revenue that is **recurring** in nature. It may
  not be literally labeled "subscription revenue"; determine which revenue
  stream is recurring and confirm it is present as its own line.

If all three are available, route to **`arrBuild/arrBuild.md`**.

### B. Take-rate build — `trBuild/`

Check this build **only if the orchestrator's revenue model is `platform`** — the
company intermediates orders / transactions between parties and recognizes
revenue as a slice of that volume (Uber, DoorDash, Block). That is a fact about
the nature of the business, decided once from the business description by the
`industry-classification` sub-skill and passed down; this router does not judge it
and does not read the description. A `subscription`, `advertising` or `mixed`
company does **not** route here even when a volume-like series appears in its
inventory — a software issuer's reported **bookings** or **billings** are contract
value, not platform volume.

When the revenue model is `platform`, **both** of the following **necessary** items
must be present in the inventory:

- **Total Bookings** — may be listed as **Gross Order Volume**, **Gross
  Merchandise Value**, **Total Payment Volume**, or another name, but it must
  represent the total **$ amount of orders booked on the platform**.
- **Revenue corresponding to those bookings** — a revenue line that maps to that
  booked volume. It can be loosely related but must have a clear connection to
  the total bookings amount.

*If found (enriches the build, not required to route):*

- **Take Rate** — the **%** of bookings captured as revenue. If reported
  directly, capture it; if not, it is calculated downstream as
  **revenue ÷ bookings**, which is why finding the correct bookings and revenue
  series is crucial.

If the revenue model is `platform` and both necessary items are present, route to
**`trBuild/trBuild.md`**.

**Sanity check, not a gate.** Platform volume exceeds the revenue it generates by a
clear multiple (take rates run from a few percent to a few tens of percent). Compute
`revenue ÷ bookings` for every historical year; if it is not well below one, the
series matched is probably contract bookings or a sub-segment of volume, not the
platform's gross volume. Say so in the routing line and in `BUILD_LOG.md` (the
check and what it returned; the bookings input row's comment names the series
used) and confirm the mapping before building; do not re-route on the ratio
alone.

### C. ARPU build — `arpuBuild/`

If neither the ARR nor the take-rate criteria are met, check this build. Route
here when both **necessary** items are present:

- **User count** — the count of users the revenue is earned from (MAU, DAU,
  active users, paying users, subscribers, members, etc.).
- **Revenue.**

This is enough to drive the model off ARPU (revenue ÷ users). If both are
available, route to **`arpuBuild/arpuBuild.md`**.

**Which user series is the ARPU anchor — decided by the revenue model, not by
precedence.** The anchor must be the population that **earns the revenue**:

- `advertising` → the **audience** series (DAU, MAU, daily active people): the
  audience is what advertisers buy.
- `subscription`, `platform` or `mixed` → the **paying** series (paying users,
  subscribers, members, customers) where the inventory has one; the audience
  series only when no paying series exists.

State the anchor and the revenue model in the routing line. A customer count that
also satisfied the Step 3 gate is set aside, not rolled, when it is not the anchor
(Step 3's table).

### D. Other — `other/`

The **catch-all default**, reached when none of the ARR, take-rate, or ARPU
criteria are satisfied. The only **necessary** item is:

- **Revenue.**

Route to **`other/other.md`**.

## Step 3 — Customer / user roll forward gate (conditional pre-build)

Evaluate this **after** Step 2 has determined the build type but **before**
handing off to that build. This step decides whether a **customer / user roll
forward** is laid down first, and **which series it tracks**.

### The condition

Route to `customerRollForward/customerRollForward.md` **if and only if customer
or user count data is present** in the shared KPI inventory — i.e. the
**customer-count** family or the **user-count** family from Step 1, item 2
returned **at least one** usable series. Any of the following satisfies the
condition:

- a total customer count (`Customers`, `Total customers`, `Customer count`), or
- a paying / active / enterprise customer count, or a customer cohort series
  (`Customers with ARR > $X`), or
- a customer **flow** series — additions, net adds, churned customers, logo /
  gross retention — even without a reported ending balance, or
- a user count (`Monthly Active Users`, `Daily Active Users`, `Daily Active
  People`, `Active users`, `Paying users`, `Subscribers`, `Members`).

If **none** of these exist anywhere in the inventory, customer and user data are
**absent**: **skip this step entirely**, do not invoke `customerRollForward/`, and
proceed directly to Step 4.

Whether the gate fires is independent of the build type chosen in Step 2. A
company routed to `arrBuild/`, `trBuild/`, `arpuBuild/`, or `other/` all get the
roll forward if — and only if — customer or user data is present. **Which series
the roll forward tracks does depend on the build type**, because the build that
follows references the roll forward's `EOP`, and that `EOP` must be the population
the build's own metric is defined on.

### Which series the roll forward tracks

Exactly **one** roll forward is built, on the series the chosen build anchors on:

| Families present | Build chosen (Step 2) | Series the roll forward tracks |
|---|---|---|
| customer count only | ARR | the **total customer count** (the recurring-revenue base) |
| customer count only | take-rate / other | the total customer count (a supporting block; neither build references it) |
| customer count only | ARPU | unreachable — the ARPU route requires a user count |
| user count only | ARR | unreachable — ARR requires a total customer count |
| user count only | ARPU | the **ARPU anchor** — the user-count series Step 2 selected |
| user count only | take-rate / other | the user-count series (a supporting block) |
| both | ARR | the **total customer count**; the user series is not rolled |
| both | ARPU | the **ARPU anchor**; the customer count is **not** rolled, even though it also satisfied the gate — the ARPU build divides revenue by the roll forward's `EOP`, which must be the ARPU population |
| both | take-rate / other | the total customer count |

Any series that is a **breakdown of the tracked series** (cohorts, types,
products, geographies) goes to the roll forward with it, for its Layout B. A count
from the family that was set aside is named in the audit line and in
`BUILD_LOG.md` (a series chosen over a sibling is build history, not a workbook
note); it is not rolled.

### If customer or user data IS present

1. **Invoke `customerRollForward/customerRollForward.md`**, passing it **all of
   the inputs this router received** — resolved `company_id`, official company
   name, workbook path, and the shared KPI inventory — plus the **exact series it
   is to track** (from the table above), the **exact series that are breakdowns
   of it**, and a note of **which build type Step 2 selected** so the roll forward
   can align its layout with the revenue build that follows it.
2. **Let it run to completion.** The customer roll forward performs its own
   `search_kpis` pulls and writes its own line items; do not duplicate that work
   here.
3. **Return to this file (`software.md`) when it finishes.** Control comes back
   here — the roll forward does **not** route onward to a revenue build itself,
   and it is **not** a substitute for one.
4. **Continue to Step 4** and hand off to the build type already selected in
   Step 2. The roll forward never changes that decision.

**This router owns the full round trip.** Do not end the turn after the customer
roll forward completes, and do not leave the revenue build unrouted. Reaching
`customerRollForward/` is a detour, not a destination — every path through this
router still terminates in exactly one of the four revenue sub-builds.

### Audit line

State, in one line, whether customer or user data was found (naming the exact
series), which series the roll forward tracks and why (the table above), which
family was set aside if both were present, and therefore whether the roll forward
ran or was skipped — so the conditional is auditable alongside the build-type
decision.

## Step 4 — Route to the sub-build

Hand the build to exactly one sub-skill, passing it **all of the inputs this
router received** — resolved `company_id`, official company name, workbook path,
and the shared KPI inventory — plus a note of **which KPIs satisfied the
criteria** for the chosen build type, and **whether the customer / user roll
forward ran and which series it tracks** (so the build knows the count lines are
already on the sheet and does not duplicate them).

- ARR criteria met (NRR/NDR + total customer count + recurring/subscription
  revenue) → **`arrBuild/arrBuild.md`**
- Else, booking-based business with total bookings + corresponding revenue →
  **`trBuild/trBuild.md`**
- Else, user count + revenue present → **`arpuBuild/arpuBuild.md`**
- Else (default) → **`other/other.md`**

Every software company resolves to exactly one of these four routes — there is
no "no build" outcome.

State which route you picked and why (one line, citing the specific KPIs that did
or did not satisfy each criterion) before handing off, so the routing decision is
auditable.

Reaching this step is **mandatory on every path**, including the path that went
through the customer roll forward in Step 3.

**Before dispatching the ARPU build, check the roll-forward's population.** Step 3
designated the series the roll forward tracks; the roll-forward's hand-back report states
the population it actually built on. If they differ, the roll forward did not follow the
designation: re-run `customerRollForward/` on the designated series **now**, before the
ARPU build runs, and only then dispatch it. The ARPU build divides revenue by the count it
references, so a mismatch here is a wrong model, not a cosmetic one; it is caught at this
dispatch, never left for the ARPU build to find.

## Step 5 — Hand off

The chosen sub-build is responsible for its own deepKPI pulls (using
`search_kpis` against the shared inventory for the specific series it needs),
period columns, formulas, provenance hyperlinks, and styling for the revenue
section. This router does **not** write to the workbook itself; once it has
routed, the revenue sub-build takes over the rest of the REVENUE section.

## Step 6 — Findings from a stage

A `DEFECT UPSTREAM` record returned by any stage beneath this router is **returned
unchanged as this router's own outcome** — this router never acts on it, names a level, or
re-runs anything on its own. When the orchestrator (`../../SKILL.md`, Step 4.2) asks this router
to **re-run from a named stage forward**, re-run that stage with the finding it carries and
then every stage after it in this router's order, running the route selection again as
part of that; return the re-issued hand-back reports.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the
  chain. This router makes **no** new deepKPI calls; it only reads the inventory
  to decide which revenue sub-build to hand off to.
- Evaluate revenue-build criteria in order (A → B → C → D) and stop at the first
  match, so the richest build a company qualifies for is always chosen. The
  take-rate build (B) additionally requires that the company **is** a booking-
  based business, not merely that a volume-like series exists.
- The customer / user roll forward (Step 3) is a **conditional pre-build, not a
  fifth build type**. It runs only when customer-count or user-count KPI data
  exists, it runs **before** the revenue build on the series that build anchors
  on, and control always returns here afterward. It never replaces the revenue
  build and never alters which build was selected.
- The two possible flows through this router are exactly:
  - customer or user data present → Step 2 (decide build) →
    `customerRollForward/` (on the series Step 3 designates) → back here → Step
    4/5 (hand off to the build)
  - neither present → Step 2 (decide build) → Step 4/5 (hand off to the build)
- Adding a new software revenue build type later is a matter of creating a new
  sibling folder under `software/` and adding one routing branch in Steps 2 and
  4.
