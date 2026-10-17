---
name: revenue-retail
description: >
  ROUTER — retail-industry revenue router for the operating-model workbook.
  Invoked by the revenue router (`revenue/revenue.md`) once the company has been
  classified as a retail / consumer-merchandise business. This skill does NOT
  build the revenue model itself. It receives the resolved `company_id`, official
  company name, workbook path, and the shared KPI inventory; FIRST, if the
  inventory contains a total store / location count KPI, it invokes
  `locationBuild/locationBuild.md` to lay down the store unit roll-forward and
  records that the LOCATION GATE passed; THEN it evaluates which retail-revenue
  KPIs are available and routes the build to exactly one sub-build sub-skill:
  `comparableStoresBuild/` (full comparable-store-sales dataset including the
  comparable-cohort DOLLARS), `unitsBuild/` (product-level unit economics — two of
  revenue / units / selling price per product), `sqftBuild/` (square-footage or
  per-location build; requires the location gate to have passed), or `other/`
  (catch-all revenue CAGR). The chosen sub-skill performs the actual revenue
  deepKPI pulls and lays out line items beneath the `REVENUE` ALL-CAPS header,
  formatting per ../../../_common/revelata-excel-styling-rules.md.
---

# revenue — retail (location build + build-type router)

This sub-skill is part of the `operating-model` system and owns two
responsibilities within the **retail** industry for the **REVENUE** section:

1. **Lay down the store (location) roll-forward**, when the company reports total
   store counts, by invoking `locationBuild/locationBuild.md`.
2. **Route** to the correct revenue sub-build based on which retail-revenue KPIs
   are available.

By the time control reaches this file, two things are already known:

1. the company **is in the retail industry** (decided by the parent revenue
   router, `../revenue.md`), and
2. the **full set of KPIs available for the company** — the **shared KPI
   inventory** — has already been collected by the orchestrator.

This file does **not** build the revenue model itself and does **not** make new
deepKPI calls during routing. The location build is delegated to
`locationBuild/locationBuild.md`; the revenue build is delegated to one of the
four revenue sub-builds.

**Inputs expected from the parent router:** resolved `company_id`, official
company name, the path to the scaffold workbook, and the **shared KPI
inventory**.

**Data source:** deepKPI only — see `../../../_common/data-source-rules.md`. On
failure, follow `../../../_common/connection-failure.md`.

**Formatting:** the downstream sub-builds follow
`../../../_common/revelata-excel-styling-rules.md` and build with the **xlsx**
skill.

## Step 1 — Location build (conditional) — and the LOCATION GATE

Before routing, check the **shared KPI inventory** for a **total store /
location count** KPI for the company. This includes any series that reports the
company's total store or unit count — system-wide totals, company-operated store
counts, franchised or licensed store counts, or per-banner / per-segment counts
that together comprise the total. Match patterns include (non-exhaustive):
`"Number of stores"`, `"Store count"`, `"Total stores"`, `"Stores at end of
period"`, `"<Banner> store count"`, `"Number of retail locations"`,
`"Company-operated stores"`, `"Franchised stores"`, `"Licensed stores"`,
`"Warehouses"`, `"Clubs"`, `"Supercenters"`, `"Store openings"`,
`"Store closures"`, and similar total-store series.

> **Two retail traps to avoid when reading this family.**
>
> - **"Units" is overloaded in retail.** A series called `Units`, `Units sold`,
>   `Retail units sold`, or `Pairs sold` is almost always **merchandise volume**
>   (product units the company sold), **not** the number of stores it operates.
>   Merchandise-volume series feed build **B** below; they **do not** satisfy this
>   gate. Conversely `Total units` inside a store-fleet activity table *is* a store
>   count. Read the `unit` field and the surrounding context, not the label alone.
> - **Wholesale "doors" are not the company's stores.** `Doors`, `Points of
>   distribution`, or `Wholesale doors` count *third-party* retail locations that
>   carry the brand's product. They are a distribution metric, not a fleet the
>   company operates, and they **do not** satisfy this gate on their own.

**Search this family with the same rigor Step 2.0 demands**, and for the same
reason: a missed store-count series does **double** damage here. It skips the
location roll-forward **and** it silently disqualifies the company from **two**
of the four builds — the comparable-stores build (A), whose necessary Location
item is a store count, and the square-footage build (C), which is hard-gated on
this check. Scan the **complete** inventory (grep the file if the inventory was
saved to one), not the first screenful, and never conclude "no store count" from
memory or from the company's reputation.

- **If at least one total store / location count KPI is present in the inventory →**
  the **location gate PASSES**. Invoke **`locationBuild/locationBuild.md`**,
  passing it the resolved `company_id`, official company name, workbook path, and
  the shared KPI inventory. The location build will lay down the per-banner store
  unit roll-forward (Stores, Openings, Closures) beneath the `REVENUE` ALL-CAPS
  header. When it returns, **continue** to Step 2.
- **If no total store / location count KPI is present →** the **location gate
  FAILS**. Skip the location build and proceed directly to Step 2. Carry the
  failed gate forward: it makes builds **A** and **C** unavailable, so the routing
  in Step 2 is a choice between **B** and **D** only.

**Record the gate outcome (PASSED / FAILED) explicitly** in the routing line and
in `BUILD_LOG.md` — Step 2 criterion C reads it directly rather than re-deriving
it, so the two decisions can never disagree. It is build history, not a workbook
note.

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
> retailer to a coarser build, which is a **worse** outcome than the harshness is
> meant to prevent. The same applies to the two-of-three test in build B and to the
> store-count gate in Step 1. So you **must** complete the Step 2.0 exhaustive
> discovery below **before** evaluating any build's criteria. Never conclude a KPI
> is absent from a hunch, from the company's reputation ("that retailer only gives a
> comp %"), or from a couple of `search_kpis` guesses.

### Step 2.0 — Exhaustively search the FULL inventory for every routing family (MANDATORY — do not rush)

This step runs **before** A/B/C/D are evaluated. Its sole purpose is to make sure
that if a routing series exists anywhere in deepKPI, you find it — because the
same concept is routinely filed under a **different name** than the one used
here, and because retail disclosure vocabulary varies more than any other vertical
in this system. **If a routing KPI is in the inventory, there is no acceptable
reason to miss it.**

1. **Use the COMPLETE inventory, not a sample.** The orchestrator's `list_kpis`
   returns the entire KPI catalog — often **hundreds** of entries, and frequently
   **too large to read inline, so it is saved to a file**. You must scan **all of
   it**, across **every** category (`Company KPIs`, `Segment Financials`,
   `Consolidated Income Statement`, `Consolidated Balance Sheet`,
   `Consolidated Cash Flow`, …). If it was saved to a file, **parse / grep the
   whole file** — do **not** skim the first screenful, and do **not** substitute
   your own recollection of what the company "typically" discloses.

2. **Hunt explicitly for each routing family below.** Token-scan the full
   inventory **and** confirm with `search_kpis`. The concept — not the exact
   wording — is what matters; treat any hit that matches the *definition* as
   satisfying that family:

   - **Comparable-cohort DOLLARS (the build-A situation-1/2 anchor):**
     `Change in Revenue from Comparable Store Sales`,
     `Change in net sales from comparable stores`,
     `Revenue from comparable stores`, `Net sales from comparable stores`,
     `Comparable store sales` *(USD)*,
     `Increase/(decrease) in net sales from comparable stores`,
     `Comparable sales contribution to net sales`,
     `Change in revenue attributable to comparable stores`,
     `Sales from stores in the comparable base`.
   - **Comparable-sales % (pairs with the dollar change for situation 2):**
     `Comparable sales increase/(decrease)`, `Comparable store sales` *(percent)*,
     `Same-store sales`, `Comp sales`, `Comparable sales growth`,
     `Comparable brand sales`, `Adjusted comparable sales`. Channel and driver
     decompositions — `Comparable store sales — retail`, `Comparable digital
     sales`, `Transactions / traffic`, `Average ticket / basket` — are the
     "breakdown if available" enrichment, not a substitute for the headline comp.
   - **Non-comparable / new-store DOLLAR contribution (the other necessary build-A
     Revenue item):** `Change in Revenue from Stores Not Yet in Comparable Base`,
     `Net sales from non-comparable stores`, `New store sales`,
     `Revenue from new stores`, `Change in Revenue from Closures`,
     `Change in net sales from closed stores`,
     `Change in Revenue from Other Adjustments`. For a retailer the non-comparable
     bucket often also carries the **channel** lines that sit outside the store
     cohort — `E-commerce / digital net sales`, `Wholesale net sales`,
     `Licensing revenue` — plus the calendar lines `53rd week` and
     `Impact of foreign currency`.
   - **Revenue per product (build-B family 1):** `Net sales by product category`,
     `Net sales by brand`, `Revenue by product`, `<Brand> net sales`,
     `<Category> revenue`, `Footwear revenue`, `Apparel revenue`,
     `Accessories revenue`, `Hardlines / Softlines net sales`,
     `New vehicle revenue`, `Used vehicle revenue`.
   - **Units per product (build-B family 2):** `Units sold`, `Pairs sold`,
     `Units shipped`, `Volume (units)`, `<Brand> units sold`, `Items sold`,
     `Cases sold`, `Retail units sold`, `Wholesale units sold`,
     `New vehicle units sold`. A **count** series, not dollars.
   - **Selling price per product (build-B family 3):** `Average Selling Price
     (ASP)`, `Average Unit Retail (AUR)`, `Average price per unit`,
     `Average selling price per pair`, `Revenue per unit`,
     `Revenue per retail unit sold`, `Revenue per vehicle sold`,
     `Net revenue per unit`. A **USD-per-unit** series.
   - **Square footage (the build-C driver):** `Total square footage`,
     `Gross square feet`, `Selling square feet`, `Square footage at end of
     period`, `Average square feet per store`, `Sales per square foot`,
     `Net sales per square foot`, `Selling space`.
   - **Store / location count:** the Step 1 family. Re-confirm it here as part of
     the full scan — this is the second look at the gate that controls two builds.
   - **Revenue (needed by every build):** in retail the top line is usually
     labeled **`Net sales`**, not `Revenue`. Search both, plus `Total revenues`,
     `Net revenues`, and the channel / segment / geography splits
     (`Direct-to-consumer`, `Wholesale`, `Digital`, `Membership fee income`).

3. **Search EVERY category — the names hide.** These lines are routinely filed
   under naming that does **not** sit in an obvious bucket (e.g. the net-sales walk
   may appear as plain `… - Year ended` strings next to income-statement lines, or
   under a `Net sales` heading with no occurrence of the word "comparable"; unit
   volumes may sit in `Segment Financials` rather than `Company KPIs`). Scan the
   whole inventory string for the tokens above, then `search_kpis` the **exact**
   names you find to confirm each series carries values for the build window.

4. **Read the `unit` field, not just the label.** This is decisive in retail:
   - A comparable-sales series with `unit: percent` is the **%** input; the same
     concept with `unit: USD` is the **dollar** input. Build A's strict test is met
     by the **USD** comparable-cohort level (situation 1) **or** by the **USD**
     comparable-sales *change* paired with the **%** (situation 2).
   - A units series must be a **count**; a price series must be **USD per unit**; a
     revenue series must be **USD**. Growth rates are **not** levels — `ASP growth
     %` is not a price and `unit growth %` is not a unit count, so neither counts
     toward build B's two-of-three.

5. **Only after this full scan comes up empty** may you conclude a series is
   absent. In the Step 2 / Step 3 audit lines, state the **exact tokens you
   searched** and which families returned hits vs. no series — so "not found" is
   verifiable, never a guess.

Do **not** re-run `list_kpis` for this step — only inspect the shared KPI
inventory that was passed down. The chosen sub-build performs its own
`search_kpis` pulls for the specific series it needs.

### Step 2.1 — Retail wrinkles to carry forward (context, not routing tests)

These are common in retail disclosure and matter to whichever build runs, but
**none of them changes the routing decision**. Note any that are present and pass
the series names down with the hand-off:

- **Membership / fee income** (club and warehouse retailers) is a revenue stream
  that no store-comp bridge and no unit-economics build explains. It belongs on
  its own line in the build, never folded into merchandise sales.
- **53rd week.** Retailers on a 52/53-week fiscal calendar report an extra-week
  contribution to net sales in some years. It is a walk line, not growth.
- **Foreign-currency impact** on net sales for international fleets.
- **Channel mix** — stores vs. digital vs. wholesale vs. licensing. For a
  store-comp retailer, digital and wholesale generally sit **outside** the
  comparable store cohort.
- **Company-operated vs. franchised / licensed** store economics, which generate
  different revenue types from the same fleet.

### A. Comparable-stores build — `comparableStoresBuild/`

Route here when the company reports a **comparable-store-sales** dataset rich
enough to bridge revenue from a comparable cohort. All of the following
**necessary** items must be present:

- **Location**
  - *necessary:* Store / location count — i.e. the **Step 1 location gate must
    have PASSED**. If it FAILED, build A is unavailable; skip to B.
  - *if applicable:* store openings & closures; domestic vs. international split;
    company-operated vs. franchised / licensed; per-banner or per-segment counts;
    square footage.
- **Revenue**
  - *necessary:* comparable-store sales growth % (with breakdown if available);
    **beginning-of-period and end-of-period revenue (net sales)**; **the dollar
    revenue of the comparable cohort** (read the STRICT requirement below — this
    is a **dollar** requirement, not a percentage); and revenue from stores
    **not** in the comparable cohort (or the change in revenue attributable to
    non-comparable stores).
  - *necessary:* the comparable-store sales growth % is reported for the
    **company-operated universe** — a caption such as `comparable store sales`
    on company stores, or a comp the issuer defines on its own stores. An issuer
    whose **only** comp is **systemwide** (company and franchised / licensed
    **stores** together) does **not** meet this item: the comparable-stores build
    partitions company-operated net sales, and franchisee sales never pass
    through the income statement, so a system comp has no dollar base there.
    A comp reported on an **owned-plus-licensed-departments** basis is **not**
    systemwide — licensed departments are counters inside company-operated
    stores — and meets this item; the build picks the basis (its §1.9). Read
    the universe off the caption in the inventory; it is an inventory test, not
    a judgment.
  - *if applicable:* channel split (store vs. digital vs. wholesale);
    company-operated revenue vs. franchised / licensed revenue; membership fee
    income; the 53rd-week and foreign-currency walk lines.

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
>    attributable to that %** (the reported dollar change in net sales from the
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
> build; fall through to the units build (B), and then to the square-footage build
> (C). **"Not met" is a conclusion you may reach only once the Step 2.0 scan has
> actually run and come up empty — never from memory, the company's reputation, or
> a couple of `search_kpis` guesses.** A dollar change that can only be derived as a
> **residual** (e.g. total net sales change minus a separately reported new-store
> contribution) is **not** a directly reported comparable-cohort dollar figure and
> does **not**, on its own, satisfy this item — hold the line.
>
> **Why this is strict (do not paper over it).** The comparable bridge must seed
> the base (leftmost) year's comparable-cohort **dollar** revenue. If no
> comparable-cohort dollar figure exists, the only fallback is to approximate that
> seed as *prior-year total net sales ÷ prior-year total store count* — the blended
> net sales per store across **all** units. In retail that proxy is wrong **twice
> over**:
>
> - It treats **comparable** and **non-comparable** (newly opened, still-ramping)
>   stores as identical, assuming the comparable cohort earns the brand-wide
>   average per store. Comparable stores are more mature and earn more per unit, so
>   the proxy **understates** true comparable per-store revenue.
> - Worse in retail than in restaurants: total net sales also includes **digital,
>   wholesale, licensing, and membership-fee revenue that no store produced**.
>   Dividing that total by the store count loads non-store revenue onto the store
>   base and **overstates** per-store sales in the opposite direction.
>
> The two errors do not cancel — they just make the seed unfalsifiable, and the
> whole discrepancy lands in the Other-revenue plug. Requiring the dollars up front
> (situation 1 or 2) is what prevents this. **But strictness is a bar on the data,
> not on your effort: when the comparable-cohort dollars are not obvious, re-run
> the Step 2.0 exhaustive scan in full before falling back — route onward to (B) or
> (C) only once you have positively confirmed those dollars are absent from the
> entire inventory, never on a hunch or a half-search.**

> **Worked example — the situation-2 arithmetic.** *(Illustrative figures showing
> the shape of the test, not a specific issuer's reported values.)* A specialty
> apparel retailer reports `Comparable sales increase/(decrease)` of **+6.2%** and,
> in its net-sales walk, `Change in net sales from comparable stores` of
> **+$248M**, alongside `Change in net sales from non-comparable stores` and
> `Change in net sales from closed stores`. The dollar comparable change is
> **directly reported** (not a residual), so **situation 2 is satisfied** — back
> into the prior-year comparable base as $248M ÷ 6.2% ≈ **$4.0bn** — and the
> company routes to **A (comparable-stores)**.

> **Worked example — the miss Step 2.0 exists to prevent.** The disclosure above is
> easy to under-read. Retail net-sales walks are routinely filed in the inventory
> under plain `… - Year ended` naming next to income-statement lines, or under a
> `Net sales` heading in which the word "comparable" never appears in the KPI
> label at all. A hasty scan that greps only for "comparable" and concludes "this
> retailer only publishes a comp %" wrongly falls through to (B) or (C) and
> produces a coarser build. Grep for the **walk** vocabulary — `Change in net
> sales`, `non-comparable`, `new stores`, `closures`, `53rd week`, `foreign
> currency` — as well as for "comparable", and check the `unit` field on every hit.

If every necessary Location and Revenue item above is available — **including the
strict comparable-cohort dollar requirement (situation 1 or 2 above), confirmed
present by the Step 2.0 exhaustive search** — route to
**`comparableStoresBuild/comparableStoresBuild.md`**.

### B. Units build — `unitsBuild/`

If the comparable-stores criteria are **not** fully met, check this build.

This build is **unit-economics driven**. The idea is simple: if you can get the
individual **units sold** and the **selling price per unit** for each product the
company sells, you project both forward and multiply them together to arrive at
that product's revenue. Because the three quantities are locked by the identity

```
revenue per product  =  units per product  ×  selling price per product
```

any **two** of them determine the third. That is exactly the routing bar.

**Necessary — at least TWO of the following three families must be present:**

1. **Revenue per product**
2. **Units per product**
3. **Selling price per product** (ASP / AUR / revenue per unit)

*If applicable (enriches the build, not required to route):* the third family
when all three are reported (use it as a cross-check against the implied value
rather than as a second input); product-mix or channel splits of the same
families; units and price split by geography or by retail vs. wholesale.

Apply these rules when testing the two-of-three:

- **Same-product rule.** The two families must describe the **same** product,
  brand, or category, over the **same** periods. Revenue for Brand X paired with
  units for Brand Y satisfies nothing — the identity does not hold across
  different products.
- **Granularity.** The pair must resolve at the level the build will project —
  per product, brand, category, or vehicle type. If the company sells essentially
  one product line, the company-level pair satisfies this.
- **Materiality of coverage.** The qualifying product(s) must be a **principal**
  revenue driver, not an incidental sub-line. A units-and-price pair covering one
  minor category of a broad assortment does not carry a units build; in that case
  fall through to (C) or (D) and pass the series along as enrichment.
- **Levels, not growth rates.** `Unit growth %` and `ASP growth %` are not levels
  and do **not** count toward the two-of-three. Confirm via the `unit` field:
  counts for family 2, USD-per-unit for family 3, USD for family 1.
- **Merchandise units, not store units.** Re-read the Step 1 trap — a store count
  is not a product-unit count, and vice versa.
- **Traffic × ticket does not qualify.** `Transactions`, `traffic`, and
  `average ticket / basket` are store-level footfall metrics, not product-level
  unit economics. They enrich build A; they do **not** satisfy build B.

Which pair you find determines what the build derives:

| Pair present | Derived third | Note |
| --- | --- | --- |
| Revenue + Units | Selling price (implied ASP = revenue ÷ units) | Ties to reported revenue. |
| Revenue + Selling price | Units (= revenue ÷ price) | Ties to reported revenue. |
| Units + Selling price | Revenue (= units × price) | Built bottom-up; will **not** automatically tie to reported total revenue — the residual belongs in a clearly labeled Other/plug line. |

**This build is independent of the Step 1 location gate.** A branded
consumer-products company that sells mostly through wholesale and operates few or
no stores of its own can fail the location gate entirely and still qualify here —
which is precisely why B is evaluated before C.

> **Worked examples — the shape to look for.** *(Illustrative patterns, not
> specific issuers' reported values.)*
>
> - A branded footwear company reporting `Footwear net sales` (family 1) and
>   `Pairs sold` (family 2) for the same brand → two of three present, implied ASP
>   = net sales ÷ pairs. **B is satisfied.**
> - An online used-vehicle retailer reporting `Retail units sold` (family 2) and
>   `Revenue per retail unit sold` (family 3) → two of three present, revenue built
>   as units × price for the retail-vehicle product. **B is satisfied.**
> - A retailer reporting only `Transactions` and `Average ticket` → these are
>   traffic metrics, **not** product-level unit economics. **B is NOT satisfied.**

If at least two of the three families are present for the same principal
product(s), route to **`unitsBuild/unitsBuild.md`**.

### C. Square-footage build — `sqftBuild/`

If neither the comparable-stores criteria nor the units criteria are met, check
this build.

The goal of this build is to project revenue on a **square-foot** basis, or
failing that on a **per-location** basis. So it needs to know the company's total
square footage, or at the very least its store count.

**Hard prerequisite — the Step 1 location gate must have PASSED.** The gate and
this build ask the same question, so the answers must agree by construction:

- **Location gate FAILED → build C is unavailable. Full stop.** If the company has
  no store-count KPI, the location build was skipped, there is no fleet in the
  workbook to divide revenue across, and this build cannot be attempted. Do not
  try to substitute square footage, a segment count, or any other proxy for the
  missing store count. Fall through to (D).
- **Location gate PASSED → build C is available**, and it is reached
  **automatically** whenever (A) and (B) have both failed. No further test is
  required: store count plus revenue is already enough to drive revenue per
  location, and square footage, where reported, simply upgrades the denominator.

**Necessary:**

- **Store / location count** — already established by the Step 1 gate.
- **Revenue** — the net sales / revenue line being divided.

*If applicable (this is what makes it a true square-footage build rather than a
per-location one):* total / gross / selling square footage; average square feet
per store; directly reported sales per square foot; any of these split by banner,
segment, or geography.

Two things to pass along rather than legislate here, since they are build
mechanics and belong to `sqftBuild/`:

- **Square footage preferred, per-location as the floor.** Despite the folder
  name, this build covers both. If a square-footage series exists, the build is
  driven off sales per square foot; if not, it falls back to revenue per location.
  Name which of the two the data supports in your routing line.
- **Match the fleet to the revenue.** The store base used as the denominator
  should be the one that actually generates the revenue in the numerator —
  company-operated stores for owned-store net sales, since franchised and licensed
  stores generate a different revenue type. Flag the split if the inventory has it.

If the location gate passed and (A) and (B) both failed, route to
**`sqftBuild/sqftBuild.md`**.

### D. Other — `other/`

The **catch-all default**, and the most bare-bones revenue model in the set: a
revenue CAGR / growth build by reporting segment. The only **necessary** item is:

- **Revenue.**

This route is reached when the location gate **FAILED** and the units criteria
were **not** met — i.e. the company gives neither a store fleet to build on nor
product-level unit economics to build from. It still needs a usable total
revenue series. If the Step 2.0 scan finds **no** usable revenue series at all,
that is a deepKPI coverage gap, not a route: **stop and ask the user** per
`../../../_common/connection-failure.md`. Do not route D a company with nothing
to build on.

Route to **`other/other.md`**.

## Step 3 — Route to the sub-build

Hand the build to exactly one sub-skill, passing it **all of the inputs this
router received** — resolved `company_id`, official company name, workbook path
(with the store roll-forward already laid down if Step 1 ran), and the shared KPI
inventory — plus a note of **which KPIs satisfied the criteria** for the chosen
build type, the **location gate outcome**, the **location build's §6 hand-back
report verbatim** when Step 1 ran (block level, flow-disclosure tier, whether a
Franchised & Licensed roll exists and at what level, 10-K override cells — the
sub-builds read all of these before writing a cell), and any Step 2.1 wrinkles
that are present.

Evaluated in order, stopping at the first match:

- Comparable-stores criteria met (gate PASSED + company-operated comp % +
  comparable-cohort **dollars** + non-comparable dollars + BOP/EOP revenue) →
  **`comparableStoresBuild/comparableStoresBuild.md`**
- Else, two of three product families present for the same principal product →
  **`unitsBuild/unitsBuild.md`**
- Else, location gate PASSED (square footage if reported, store count otherwise) →
  **`sqftBuild/sqftBuild.md`**
- Else (default) → **`other/other.md`**

The full decision is deterministic and can be read off this table:

| Step 1 location gate | A: comparable-cohort dollars met | B: two of three product families met | → Route |
| --- | --- | --- | --- |
| PASSED | yes | — | **A** `comparableStoresBuild/` |
| PASSED | no | yes | **B** `unitsBuild/` |
| PASSED | no | no | **C** `sqftBuild/` |
| FAILED | *unavailable* | yes | **B** `unitsBuild/` |
| FAILED | *unavailable* | no | **D** `other/` |

Note the two structural consequences of the gate, both intentional:

- When the gate **PASSED**, `other/` is unreachable — (C) always catches the
  company, because a fleet plus revenue is always enough for a per-location build.
- When the gate **FAILED**, only (B) and (D) remain, because both (A) and (C)
  require a store count.

Every retail company resolves to exactly one of these four routes — there is no
"no build" outcome.

State which route you picked and why (one line, citing the specific KPIs that did
or did not satisfy each criterion, and the location gate outcome) before handing
off, so the routing decision is auditable.

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
   "Revenue: modeled on units and price because the filing discloses no
   comparable-store cohort."
2. **Drop every row the aborted build laid.** Under the compose-then-render
   mechanic (`../../SKILL.md`, "Build mechanics") omit that build's section module
   from the parts and re-render; the location build's rows are untouched.
3. **Re-evaluate Step 2 with the aborted build excluded**, applying the same
   criteria in the same order, and hand off per Step 4. The hand-back is what
   excludes the build, not a new criterion: the router tests only what the
   inventory shows, and the aborted build has already tested the rest.

The "no build" outcome stays unreachable: with (A) excluded, the Step 3 table
still resolves — (B) if two product families are present, else (C) when the gate
PASSED, else (D).
## Step 4.2 — If a sub-build returns `DEFECT UPSTREAM`

A `DEFECT UPSTREAM` record returned by any stage beneath this router is **returned
unchanged as this router's own outcome** — this router never acts on it, names a level, or
re-runs anything on its own. When the orchestrator (`../../SKILL.md`, Step 4.2) asks this router
to **re-run from a named stage forward**, re-run that stage with the finding it carries and
then every stage after it in this router's order, running the route selection again as
part of that; return the re-issued hand-back reports.

The one case that stays inside this section — the comparable-stores build finding that
the location build laid no gross openings for a banner although the 10-K discloses them
— still goes up and comes back: the orchestrator's instruction to re-run from the
location build forward is what re-runs the location build (which lays the gross rows as
its own 10-K override), re-evaluates Step 2 and re-runs the sub-build.

## Step 5 — Report the build method back

The parent revenue router (`../revenue.md`, Step 4) expects this router to report
the **build method** it selected, so the orchestrator can carry it forward. When
the build returns, report back:

- the **build method** — comparable stores / units / square footage / other, and
- the one-line justification you stated in Step 3.

The Step 1 gate outcome is **not** reported upward. Its downstream effect travels
through the workbook itself: the location build lays the `Company-Operated EOP
Balance` contract row, and the retail cost build and the net-working-capital build
each test for that row's presence (`../../SKILL.md`, "Contract rows"). The location
build is a **pre-build, not a terminal route** — never report it as the build
method.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the
  chain. This router writes nothing to the workbook; it only reads the inventory
  to decide whether to invoke the location build and which revenue sub-build to
  hand off to. Its **only** permitted deepKPI calls are the narrow confirmation
  `search_kpis` lookups in Step 2.0 — never a pull to populate a cell.
- Evaluate revenue-build criteria in order (A → B → C → D) and stop at the first
  match, so the richest build a company qualifies for is always chosen. The
  ordering encodes a view about precision: a comparable-store bridge separates the
  mature cohort from new-store contribution and is the most precise engine for a
  store-based retailer; product-level unit economics (units × price) is the next
  most granular; a blended sales-per-square-foot or per-location figure is
  coarser; a revenue CAGR is coarsest.
- The location build runs **before** routing because every revenue sub-build can
  benefit from referencing store counts that are already in the workbook — and
  because build C is hard-gated on the same check.
- **The Step 1 gate does double duty.** It decides whether the location build runs
  *and* whether builds A and C are available at all. Under-searching the
  store-count family is therefore the single most costly mistake this router can
  make; treat it with the same rigor as the Step 2.0 scan.
- **Square footage without a store count deliberately fails build C.** A company
  that reports total square footage but no store count fails the Step 1 gate and
  therefore cannot route to C, even though a sales-per-square-foot model would in
  principle be computable. This is intentional: the gate keeps the location build
  and the square-footage build consistent with each other, and a fleet with no
  reported store count is a strong signal the disclosure is too thin to anchor a
  location-based model. Such a company routes to B if it has product unit
  economics, otherwise to D.
- This router never builds anything itself. If you find yourself pulling series
  with `search_kpis`, writing to the workbook, or reasoning about column layout,
  you have left the router's job — stop and hand off.
- Adding a new retail revenue build type later is a matter of creating a new
  sibling folder under `retail/` and adding one routing branch in Steps 2–3, plus
  a row in the decision table.
