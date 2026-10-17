---
name: revenue-retail-units-build
description: >
  Units (unit-economics) revenue build for retail companies in the operating-model
  workbook. Invoked by the retail router (`revenue/retail/retail.md`) at its Step 3
  hand-off when the company reports at least **two of the three** product-level
  families — revenue per product, units sold per product, selling price per product
  (ASP / AUR / revenue per unit) — for the same principal product(s). This build is
  **independent of the location gate**: it runs whether or not a store roll-forward
  was laid down, because merchandise units, not stores, drive it. The build
  reconstructs revenue from the identity `Revenue per product = Units Sold per
  product × Selling Price per product`, decided **per product**, and supports three
  pairing cases: Case A1 (revenue + units reported, price backsolved), Case A2
  (revenue + price reported, units backsolved), and Case B (units + price reported,
  revenue built bottom-up and therefore not self-anchoring to reported revenue).
  It lays down a `Unit Economics` block containing a `Units Sold` sub-block and a
  `Selling Price` sub-block (each with its own `YoY %` sub-block whose
  per-product rows are the projection drivers), a `Unit Revenue` block
  (`Units × Price` per product summed to `Total Unit Revenue`), one small block per
  non-unit revenue stream (each projected on its own `YoY %` driver), and a
  `Consolidated Revenue` table that sums unit revenue and the streams and foots to
  reported total revenue. Pulls series via `search_kpis` from the shared inventory;
  format per ../../../../_common/revelata-excel-styling-rules.md (one row per series,
  derived cells as live formulas) EXCEPT for time scope (last 4 fiscal years), which
  this build overrides. Sections: §0 retail preconditions, §1 isolate the
  unit-driven revenue + enumerate products + pick each product's case, §2 Unit
  Economics — Units Sold, §3 Unit Economics — Selling Price, §4 Unit Revenue, §5
  other revenue streams, §6 Consolidated Revenue + foot, §7 worked examples,
  Projections, §8 downstream handoff.
---

# revenue — retail — units (unit-economics) build

This is the **units** retail revenue build. It is invoked by the retail router
(`../retail.md`) at its Step 3 hand-off when the company did **not** qualify for
the comparable-stores build (no comparable-cohort dollars) but **does** report at
least **two of the three** product-level families for the same principal
product(s).

At its core a units build is one identity, applied **per product**:

```
  Revenue per product  =  Units Sold per product  ×  Selling Price per product
```

Because the three quantities are locked by that identity, any **two** of them
determine the third. Everything below is the disciplined way to (a) decide which
two the company actually reports for each product, (b) derive the third, (c)
project units and price **separately** so that volume growth and price growth are
visible as distinct assumptions, and (d) wire the whole thing so it foots to
reported total revenue.

The economic reason this build sits **above** the square-footage build in the
router's priority order is exactly that separation: a retailer whose revenue is
flat because it sold 5% fewer units at a 5% higher price is telling a completely
different story from one whose revenue is flat because volume and price both held.
A per-square-foot or per-location model cannot see the difference; this one puts it
on two adjacent rows.

By the time control reaches this build, three things are already established and
must **not** be re-litigated:

1. the company **is in the retail industry** (decided by the parent revenue router,
   `../../revenue.md`);
2. the company **qualifies for the units build** (decided by the retail router's
   Step 2 criteria B — two of three product families present for the same
   principal product(s), confirmed by its mandatory Step 2.0 exhaustive scan); and
3. **if the location gate PASSED**, the store roll-forward has already been laid
   down in the workbook by `../locationBuild/locationBuild.md`. This build does
   **not** reference those store counts as a line item — merchandise units are not
   store units — but it may use them as a **cross-check**, recorded in
   `BUILD_LOG.md` (see §0.3).
   If the gate FAILED there is no roll-forward above this build, which is normal:
   a branded consumer-products company selling mostly through wholesale can fail
   the location gate entirely and still be a textbook units build.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, the router's note of **which KPIs satisfied the units criteria**
(which two of the three families, for which product(s)), the **location gate
outcome**, any Step 2.1 retail wrinkles that are present (membership fee income,
53rd week, foreign currency, channel mix, company-operated vs. franchised), and —
if the location build ran — its hand-back report (block level, flow tier,
franchised roll, 10-K overrides) so this build can adopt its **fiscal-year column
mapping** without re-deriving one.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and build
with the **xlsx** skill. All conventions there apply here — the four-column label
system (Col A hidden deepKPI string, Col B hidden index, Col C display label, Col D
units tag, Col E onward data), one row per distinct series, deepKPI-sourced values
as pale-green hyperlinked input cells, and **every** total / derived cell as a live
`=` formula (never a hardcoded number) — **except** for the **time scope**, which
this build overrides per the "Time scope" section below.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped. If a
  store roll-forward was laid down, use the **same four annual period columns** it
  used, so every unit / price / revenue cell sits directly under the matching
  store-count cell.
- **The units build is ANNUAL.** Units sold, selling price and product revenue are
  modeled as an annual build, so this build uses **annual columns only** (one per
  fiscal year, oldest → newest, left → right). Do **not** add quarterly columns.
- **No quarterly supporting rows (unless an annual value must be summed from
  quarters).** Every KPI is sourced at its **reported annual value**. The lone
  exception: if deepKPI has **no reported annual value** for a needed series and the
  annual figure must be built by **summing that series' four quarters**, bring the
  four quarterly rows in as supporting rows and sum them, placed in an outline group
  left expanded (no row is hidden; styling rules). Note that **units sold and revenue sum across
  quarters; selling price does NOT** — an annual ASP built by averaging four
  quarterly ASPs is wrong (it is unweighted). If price must be annualized, derive it
  as `annual revenue ÷ annual units`, never as a mean of quarterly prices.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (§0 – §7),
  then **extends the entire build into the projection window** following the
  **Projections (forecast years)** section near the end of this file. Do not
  fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §0 the
> retail preconditions, §1 the unit-driven-revenue isolation, and §2 – §8 the
> revenue build (Units Sold, Selling Price, Unit Revenue, other revenue streams,
> the consolidated revenue foot, worked examples, and the downstream handoff), plus
> the **Projections (forecast years)** section near the end that extends the build
> into `N+1 … N+5` — are the implemented scope. Do not build or add any new
> information outside the sections present here.

---

## Section 0 — Retail preconditions to settle before writing any cell

Two things routinely break a retail units build before the first formula is typed,
and both are cheap to settle up front and expensive to discover later.

### 0.1 — The retail fiscal calendar and the stamp-join trap

`../locationBuild/locationBuild.md` opens with the retail fiscal calendar for a
reason, and **the same discipline applies to every series this build pulls** —
units, prices, product revenue, and the non-unit streams alike.

Retailers are almost all on a **52/53-week fiscal calendar ending in late January
or early February**, so a company's "fiscal 2025" ends in **calendar 2026**. deepKPI
date stamps are therefore not interchangeable with calendar years, and — critically
— **the stamping convention can differ from series to series within one issuer**
(Dollar General stamps its store counts `2025-12-31` and its same-store sales
`2026-01-30` for the *same* fiscal year; The Gap, Inc. stamps one series
`2025-01-31` and another `2025-02-01` for the same fiscal 2024).

This build is **more** exposed to the trap than most, because it divides one series
by another. A units series joined one column off its revenue series produces a
selling price that is wrong in **every** year, with no formula error, no failed
foot, and a perfectly plausible-looking trend.

**What to do, in order, before transcribing anything:**

1. **Map every series to fiscal-year ordinals, never to date strings.** For each
   series, order its stamps, anchor the **newest** stamp to the last fiscal year the
   latest 10-K reports, and walk backward. Write each value into the fiscal-year
   **column**, not the date-matched column.
2. **Re-use the location build's column mapping verbatim, if it ran.** It already
   fixed the fiscal-year columns and reconciled the newest one to the filing. This
   build **adopts** that mapping; it does not re-derive one. If the gate FAILED and
   there is no roll-forward, fix the mapping here once, against the filing, and use
   it for every series in the build.
3. **Anchor each new series against the filing.** Confirm the newest column's
   reported total revenue equals the net sales figure in the most recent 10-K income
   statement, and the newest units figure equals the units figure in that 10-K's KPI
   table. Two anchors, both cheap, both catch an off-by-one immediately.
4. **The 53rd week changes sales and units, not price.** A 53-week fiscal year adds
   roughly one week of net sales **and** roughly one week of unit volume. It
   therefore inflates that year's `Units Sold` and its `YoY %`, while
   leaving `Selling Price` roughly unaffected. Identify any 53-week year in the window; when it is `N`, seed the growth driver from the issuer's 52-week-basis change where disclosed, else from `N−1`, and note it (§Projections). An earlier 53-week year no longer touches the seed. Do **not** add a 53rd-week adjustment row —
   this build has no walk.

### 0.2 — Series integrity: the magnitude test every candidate must pass

**Every units candidate and every price candidate must be reconciled against
revenue before it is believed.** deepKPI retail series are frequently mis-extracted,
and the `unit` field does not protect you — the same failure mode the square-footage
build documents for square footage applies here to units and prices:

- **A correct `unit` tag does not make a series a level.** A series labeled
  `Units sold` and unit-tagged as a count can in fact be the **percentage growth**
  in units, mis-extracted into a series presented as an absolute level. A retailer
  with hundreds of millions of dollars of revenue whose "units sold" series returns
  `3`, `5`, `4` is not selling four items a year.
- **A blank `unit` tag does not make a series wrong.** Metadata absence is not
  evidence of a bad series. Test it, do not reject it on the tag alone.
- **Scale ambiguity is the normal case.** Filings report units in ones, thousands,
  or millions, and revenue in ones, thousands, or millions — independently. Resolve
  each against the filing, never by guessing a divisor.

**The test:** compute `product revenue ÷ product units` and require the result to
land in a plausible **retail selling price** for that product — a pair of shoes is
tens of dollars, a piece of apparel tens of dollars, a used vehicle tens of
thousands of dollars, a case of consumables tens of dollars. Run it for **every**
historical year, not just the newest — a series can be clean at one end and corrupt
at the other. A result that is 1,000× or 1/1,000× a plausible price is a **scale
error**, not a finding: fix the base (§ scale discipline in the framework overview),
do not build on it.

**This test is the reason `Selling Price` is a visible block in the layout and not a
buried intermediate.** It is the trap detector, permanently on screen, in every
column — and in Case B (§1.2), where price is a reported input rather than a
backsolve, the mirror test is `Units × Price` against reported revenue.

### 0.3 — Decoys: what is not product-level unit economics

None of the following satisfies a family, and carrying any of them corrupts the
build:

- **Store counts are not merchandise units.** The router's Step 1 trap runs both
  ways: a series called `Units`, `Total units`, `Warehouses`, or `Clubs` inside a
  store-fleet activity table is a **store count**, and dividing revenue by it gives
  revenue per store — the square-footage build's Mode B figure, not a selling price.
  If the location build ran, that ratio is a legitimate **cross-check, recorded in
  `BUILD_LOG.md`** (does revenue per store move sensibly?), but it is **never** a
  row in this build and never a Notes line.
- **Wholesale "doors" are not units.** `Doors`, `Points of distribution`, and
  `Wholesale doors` count third-party retail locations carrying the brand. A
  distribution metric, not a volume.
- **Transactions and traffic are not product units; average ticket is not a selling
  price.** `Transactions`, `Traffic`, `Average ticket`, and `Average basket` are
  store-level footfall metrics. `Average ticket` is dollars **per visit**, which
  bundles an unknown number of items at an unknown mix — it is not an ASP and must
  not be used as one. These enrich the comparable-stores build; they do **not**
  belong here.
- **Growth rates are not levels.** `Unit growth %`, `ASP growth %`, and
  `AUR increase/(decrease)` are changes, not levels, and cannot seed a level row.
  They may be used to **validate** a derived `YoY %` row — if the
  company reports ASP growth of +3.1% and your backsolved price row shows +3.1%, the
  whole chain (universe, scale, fiscal-year alignment) is confirmed — but they are
  never transcribed as `Units Sold` or `Selling Price` values.
- **Merchandise-category revenue splits without units are not products.** A
  breakdown such as `Net Sales from Consumables` / `Seasonal` / `Home` / `Apparel`
  partitions the same revenue by what was sold. Without a matching **units** series
  (or a matching **price** series) for the same category, a category is not a
  product for this build — it has only one of the three families. Carrying it as a
  product with an invented denominator is the single most damaging error available
  here.
- **Units of a *different* product than the revenue.** Revenue for Brand X paired
  with units for Brand Y satisfies nothing; the identity does not hold across
  different products. The router's same-product rule is a **build-time discipline**,
  not just a routing test — re-verify it for every pair you use.

### 0.4 — Pre-delivery checklist (preconditions)

- [ ] Every series was mapped to **fiscal-year ordinals**, not date strings, and the
      newest column was **anchored against the 10-K** (revenue and units both).
- [ ] The location build's column mapping was adopted verbatim where one exists; no
      column was re-derived or shifted.
- [ ] Any **53-week year** in the window is identified; if it is `N`, the units growth seed is on the issuer's 52-week basis or from `N−1`, and the comment says so.
- [ ] Every units and price candidate passed the **magnitude test** in **every**
      historical year, and the stored **base** (ones / thousands / millions) of each
      series is recorded in Col D.
- [ ] Store counts, doors, transactions, average ticket, growth-rate series, and
      units-less category splits were **excluded**, explicitly.
- [ ] Each pair in use describes the **same product, same universe, same periods**.

---

## Section 1 — Isolate the unit-driven revenue, enumerate the products, and pick each product's case

This is the **analytical foundation** of the build. Before any Units Sold, Selling
Price, or Unit Revenue row is written, you **must** decide, from the filing and the
KPI inventory: **which revenue the units identity covers**, **how many products**
there are, **which two families each product reports** (its case), and **which
revenue (if any) the units do not generate** and must be modeled separately.

**Why this matters (STRICT).** `Units × Price` only reconstructs the revenue those
units actually generate. If a company reports a unit-driven product **and** revenue
the units do not produce (licensing royalties, franchise fees, membership fee
income, financing / extended-warranty income, advertising, shipping), running the
identity on blended total revenue silently corrupts the selling price and
double-counts once the other stream is added back. The goal of this section is that
**the revenue fed through the units identity is genuinely unit-driven revenue**,
everything else is carved out as an other revenue stream (§5), and the whole build
foots to reported total revenue (§6).

### 1.1 — Read the filing and inventory to fix the products, the units, and the prices

Three things must be extracted before any row is written:

1. **Which reported revenue the units monetize** — the numerator (Cases A1 / A2) or
   the target (Case B) of the identity. For a single-product company this is usually
   total revenue. For a company with a distinct non-unit stream it is the
   **product revenue only** (e.g. `Footwear net sales`, `Retail vehicle revenue`,
   `Wholesale net sales`). Read the revenue-disaggregation footnote and the MD&A to
   confirm which line each unit series actually produces.
2. **How the company partitions its products** — one blended product line, or
   several (footwear / apparel / accessories; retail vehicles / wholesale vehicles;
   new / used). Each becomes a **product line item** in every block of the build.
3. **Which two of the three families each product reports**, read off the `unit`
   field: **USD** for revenue, a **count** for units, **USD per unit** for price.
   This decides each product's case (§1.2).

**Workflow:**

1. Pull the latest 10-K markdown via the **filing** skill
   (`list_sec_filing_markdowns` → `get_sec_filing_markdown`).
2. Search the markdown for the disaggregated-revenue table and the key-metrics /
   operating-metrics table (tokens: `Units sold`, `Pairs`, `Units shipped`,
   `Retail units`, `Wholesale units`, `Average selling price`, `ASP`,
   `Average unit retail`, `AUR`, `Revenue per unit`, `Revenue per retail unit`,
   `Disaggregation of revenue`, `Revenue by product`, `Net sales by category`). Read
   the surrounding paragraph to confirm the product definition, the universe, and
   the reporting basis (gross vs. net of returns and allowances).
3. Confirm each series you intend to use is present in the shared KPI inventory (via
   `search_kpis`), reading the `unit` field. Do **not** re-run `list_kpis` — the
   inventory was already collected once by the orchestrator.
4. Record the isolation decision in **one Notes line**, in an analyst's words:
   *"Revenue: units × price covers <product revenue>; products: <list>; <stream>
   is carried separately (FY<n> 10-K)."* No note row goes inside the block. Each
   product's pairing case (A1 / A2 / B) is build history and goes to
   `BUILD_LOG.md`, never onto the sheet.

### 1.2 — The three pairing cases (decided per product, not once for the build)

Exactly one case applies **per product**, and it determines which rows are deepKPI
inputs and which are formulas:

| | **Case A1 — Revenue + Units** | **Case A2 — Revenue + Price** | **Case B — Units + Price** |
|---|---|---|---|
| **Reported (inputs)** | product revenue, units sold | product revenue, selling price | units sold, selling price |
| **Derived (formula)** | `Selling Price = Revenue ÷ Units` | `Units Sold = Revenue ÷ Price` | `Unit Revenue = Units × Price` |
| **Historical `Unit Revenue`** | deepKPI **input** (the anchor) | deepKPI **input** (the anchor) | **formula** `= Units × Price` |
| **Foots to reported product revenue?** | **Yes, by construction** | **Yes, by construction** | **No** — see the warning below |

**A build may mix cases across products.** A used-vehicle retailer commonly reports
`Retail units sold` + `Revenue per retail unit sold` (Case B) for one product and
`Wholesale revenue` + `Wholesale units sold` (Case A1) for another. Decide per
product, record each in `BUILD_LOG.md`, and keep the product order fixed everywhere.

> **STRICT — Case B does not anchor itself, and you must say so.** In Cases A1 and
> A2 the reported product revenue is the anchor, so `Units × Price` reproduces it
> exactly every historical year. In **Case B** nothing anchors the product's revenue:
> `Units × Price` is a construction, and it will generally **not** tie to any
> reported figure. Two consequences, both mandatory:
>
> 1. **Cross-check it.** Where the company reports *any* revenue figure that overlaps
>    the Case-B product (a segment line, a channel line, a "revenue from vehicle
>    sales" caption), compare `Units × Price` against it in every historical year and
>    record it in one Notes line: *"Revenue: <product> revenue is built as units ×
>    price and runs <x>% <above / below> the reported <caption>, a <gross-versus-net
>    / channel> difference; the gap sits in Other Revenue."* A gap of a few percent
>    is usually a definitional difference (gross vs. net of returns, delivery revenue
>    included or not); a gap of tens of percent is a defect.
> 2. **The gap lands in the §5 residual.** `Total Unit Revenue` plus the streams must
>    still foot to reported total revenue (§6), so whatever Case B's construction does
>    not explain is absorbed by the residual `Other Revenue` stream. Its size is the
>    build's fit diagnostic — the §5 `Other Revenue — % of modeled revenue` row: a residual
>    that is **large or that flips sign between years is a defect, not a result** —
>    investigate the price basis, the units universe, and the fiscal-year alignment
>    before delivering.

**When all three families are reported.** Use two of them as the inputs (prefer the
pair the issuer presents as its headline metrics) and carry the third as a
**memo cross-check** row — `Memo: Reported <selling price | units> —
<Product>` — comparing the reported figure to the derived one. Record the gap and
its likely cause in one Notes line: *"Revenue: the issuer's reported <ASP / units>
differs from the derived figure by <x>%; the issuer's is <net of returns / on a
different channel mix>."* (An issuer-reported ASP is often computed on a different
revenue base, net of returns, or on a mix of channels.) **Do not** substitute the
reported third
family for the derived one that anchors the identity; if you did, `Units × Price`
would no longer reproduce reported revenue and the build would stop footing.

### 1.3 — One product or several, and the commensurability rule for units

The build is laid out with **one line item per product**, repeated in the same order
in every block. Two structural rules govern how many products can sit in one
`Unit Economics` group:

- **Single-product build.** When the company sells essentially one product line,
  drop the per-product line items and let the block's single line carry the figure:
  `Units Sold` has one row, `Selling Price` has one row, `Unit Revenue` has one row.
  The `Total Units`, `Average Selling Price`, and `Total Unit Revenue` roll-up rows
  are **omitted** — a total of one number adds nothing. The lone line is a **plain**
  row: no bold and no sum bar, because a sum bar marks a row that sums the rows
  above it and a single figure sums nothing. The block header's bold + underline is
  what sets the block apart.

- **Commensurability (STRICT).** Every product inside one `Units Sold` block must be
  counted in the **same physical unit** — all pairs, or all vehicles, or all cases.
  `Total Units` is a genuine sum only then, and `Average Selling Price` is a genuine
  weighted average only then. Name the unit in Col D on every row of the block.
  **Revenue dollars are always additive; unit counts are not.** If the company's
  products are counted in different units (pairs *and* vehicles *and* cases), they
  do not belong in one block: lay down **one `Unit Economics` group per unit family**
  — each with its own `Units Sold` and `Selling Price` sub-blocks, its own
  `Total Units` and `Average Selling Price`, and its unit named in the sub-block
  label (e.g. `Units Sold — pairs`, `Units Sold — vehicles`) — and let the single §4
  `Unit Revenue` block list **every** product across all groups and sum them to one
  `Total Unit Revenue`. Nothing else about the layout changes.

Never manufacture a product. If a category has revenue but no units and no price, it
is **not** a product for this build — it is either folded into another product's
line or, if separately reported and material, carried as an other revenue stream
(§5).

### 1.4 — Carve out non-unit revenue streams

Independently of the cases and the product count, the unit-driven revenue may be
**only part of reported total revenue**:

- **Units cover all revenue** — the unit-driven revenue **is** reported total
  revenue. There are no §5 stream blocks, and §6's `Total Revenue` is simply
  `Unit Revenue`, which foots to the reported figure.
- **Units cover only part (mixed)** — the company also earns revenue the units do
  **not** generate. Each such stream is its own **§5 block**, projected on its own
  `YoY %` driver, and §6 sums unit revenue and the streams to reported total revenue.

Typical retail non-unit streams: **licensing and royalty revenue**, **franchise
revenue** (royalties and initial fees — the franchised fleet's sales are not the
company's units), **membership / fee income** (club and warehouse formats),
**credit-card and financial-services income**, **financing, extended-warranty and
other ancillary income** (large for vehicle retailers), **advertising revenue**,
**shipping and handling revenue**, and **gift-card breakage / other**.

Whether the build is **covers-all** or **mixed** is recorded in `BUILD_LOG.md`;
the Notes line of §1.1 shows it by naming the streams carried separately, or
none. Do **not** bury a genuine, material non-unit stream inside the selling
price — it makes
the price row unfalsifiable and hides a line that grows on a completely different
driver.

### 1.5 — Pre-delivery checklist (isolation)

- [ ] One Notes line (§1.1 wording) states **which revenue the units identity
      covers**, **the products and their order**, and **the streams carried
      separately**, citing the filing year; no note row sits inside the block.
      Each product's case (A1 / A2 / B) and covers-all vs. mixed are in
      `BUILD_LOG.md`.
- [ ] The identity numerator is the **product revenue** those units generate — not a
      blended total when a distinct non-unit stream exists.
- [ ] Each product's case was decided from the **`unit` field**, not the label, and
      is recorded in `BUILD_LOG.md`.
- [ ] Where all three families exist, the third is carried **only** as a
      memo cross-check and does **not** replace the derived row.
- [ ] Every product inside one `Units Sold` block shares the **same physical unit**;
      otherwise a separate `Unit Economics` group per unit family was laid down.
- [ ] Any **Case B** product has been cross-checked against every overlapping
      reported revenue figure, with the gap and its direction in the Notes line of
      §1.2.
- [ ] No non-unit revenue leaked into the units identity.
- [ ] Every series in use was confirmed present via `search_kpis` against the
      **shared inventory** (`list_kpis` was **not** re-run), or a sourcing gap is
      documented.

---

## Revenue build — framework overview (§2 – §6)

§0 settled the calendar and the series; §1 fixed the products, the cases, and the
carve-out. §2 – §6 turn units and prices into revenue, model any non-unit streams
alongside, and foot the whole build to the company's **reported total revenue**. The
build follows one fixed framework so that **every** units-build company is modeled
the same way and the workbook always foots.

**The master identity:**

```
  Unit Revenue — Product n   =  Units Sold — Product n  ×  Selling Price — Product n     (§2 / §3 / §4)
  Total Unit Revenue         =  Σ Unit Revenue — Product n                                (§4)

  Total Revenue              =  Total Unit Revenue + Stream 1 + Stream 2 + … [+ Other]    (§6 foot)
```

In the **historical** columns, Cases A1 / A2 anchor each product's revenue to the
reported figure and backsolve the missing family from it, so `Units × Price`
reproduces reported revenue **by construction**; Case B constructs the product's
revenue from two reported inputs. In the **projection** columns the direction
reverses for every product: units and price are each grown by their **own driver**,
and revenue is computed as their product. §6 foots because the §5 streams — plus a
residual `Other Revenue` line where the identified streams do not exhaust the
remainder — form an **exhaustive partition** of `Total Revenue − Total Unit Revenue`.

**Build the revenue lines in this order**, beneath the store roll-forward if one
exists, otherwise beneath the `REVENUE` ALL-CAPS header:

1. **§2 — Unit Economics: Units Sold.** One row per product, a `Total Units` roll-up,
   and a `YoY %` sub-block whose **per-product rows are projection
   drivers**.
2. **§3 — Unit Economics: Selling Price.** One row per product, an
   `Average Selling Price` (revenue-weighted, **not** a simple average), and a
   `YoY %` sub-block whose **per-product rows are projection drivers**.
3. **§4 — Unit Revenue.** One row per product (`Units × Price`), summed to
   `Total Unit Revenue`.
4. **§5 — Other revenue streams.** One small block per non-unit stream, each
   projected on its own `YoY %` driver — omitted entirely for a covers-all company.
5. **§6 — Consolidated Revenue.** Sums `Unit Revenue` and the streams to
   `Total Revenue` and foots to the reported figure.

### Conventions that apply to all of §2 – §6 (read once)

- **Annual columns only**, the same four the store roll-forward uses if one exists,
  oldest → newest, left → right.

- **Scale discipline — settle this before the first backsolve.** deepKPI delivers each
  series at whatever scale the filing reported, and units and revenue are scaled
  **independently**. Read each series' delivered base (ones / thousands / millions)
  from its `unit` field and by eye against the filing, then **convert it to base units
  on ingest** per Rule 1 of
  `../../../../_common/revelata-excel-units-and-scale.md` — units in ones, money in
  dollars. Do **not** record the delivered base in Col D; Col D
  declares the **display** scale (Rule 4).
  - Both rows are then on their base units, so `Revenue ÷ Units` is **dollars per
    unit** with **no multiplier**, and `Units × Price` returns the revenue exactly. A
    formula in this build never carries a scaling constant; if one seems necessary, a
    series was not converted on ingest — fix the stored value.
  - Re-run the §0.2 magnitude test on the resulting price. A price 1,000× or 1/1,000×
    a plausible retail price means the **conversion was wrong**, not that the series is
    interesting: fix the stored value and re-run.

- **Reference, do not re-derive.** Every figure this build needs from elsewhere in
  the workbook (a store count, if you cite one in a Notes cross-check) is referenced
  with a live `=` formula, never re-entered. Within the build, the §6 consolidated
  rows are **references** to §4 and §5 — never a second copy of an input.

- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI — each reported product revenue (Cases A1 / A2), each
  reported units series, each reported selling-price series, each reported non-unit
  stream, any reported third family carried as a memo, and reported total revenue
  (which lives **only** in the §6 `Total Revenue (reported)` row) — are **input
  cells** (pale-green fill,
  dark-blue hyperlinked value linked to
  the filing). **Every other cell is a live `=` formula** (black font, no fill): the
  backsolves, the `Units × Price` products, `Total Units`, `Average Selling Price`,
  `Total Unit Revenue`, every `YoY %` row, the §5 residual, the §6
  `Total Revenue` sum, and the foot check. Never hardcode a computed number.
  Projection **drivers** are red font + dashed border — neither green inputs nor plain
  black formulas (see **Projections**).

- **Label / comment / spacing discipline.** Col C labels are **plain descriptive
  text**; the operand recipe for each formula row goes in a **cell comment on the
  Col C label cell** (author `Units Build`), not in the visible label. Line-item
  labels are the **product's own name** (`Footwear`, `Retail Vehicles`) — the
  sub-block header above supplies the metric, so the label does not repeat it — and
  the **same product names in the same order** are repeated in every block (§2, its
  `YoY %`, §3, its `YoY %`, and §4).

  **Indentation is applied with the cell's actual indent property** — openpyxl
  `Alignment(indent=n)` (`indent=1`, `2`, `3`), the equivalent of Excel's
  **Home → Increase Indent** (`Alt, H, 6`) — and **never with leading spaces**.
  Leading spaces are prohibited because the block-header underline
  (`Font(underline="single")`) draws under the padding characters and produces a
  ragged rule running left of the text; an actual indent shifts the label without
  adding any underline-able characters. Padded labels also break `MATCH` /
  `VLOOKUP` against them, and the spaces are invisible in the Excel UI, so a
  mis-padded row cannot be spotted or corrected by the user. When setting a cell's
  `Alignment`, keep the existing `horizontal` / `vertical` settings and add
  `indent=n` — do not replace the whole `Alignment` object, and do not prepend
  spaces to the string:

  ```python
  # right
  c = ws["C12"]; c.value = "Average Selling Price"     # no padding in the string
  a = c.alignment
  c.alignment = Alignment(horizontal=a.horizontal, vertical=a.vertical, indent=2)

  # wrong
  c.value = "    Average Selling Price"                # leading spaces — prohibited
  ```

  **A block header sits one level shallower than its own line items**, which it frames
  with their total back at its own level — the styling rules' indent hierarchy, which the
  renderer applies to every data row from the row's kind. This holds for `Units Sold`,
  `Selling Price`, every `YoY %` header, `Unit Revenue`, each stream header, and
  `Consolidated Revenue`. `Unit Economics` is a group header one level above the two
  sub-block headers it groups (`Units Sold` and `Selling Price` at `indent=2`, their
  items at `indent=3`).

  **Blank rows.** Blocks are separated by **one blank spacer row**. Additionally,
  leave **one blank spacer row directly above a full `YoY %`
  sub-block** — a `YoY %` label row that heads **two or more** trend
  rows, as it does in §2 and §3 for any multi-product build. Do **not** leave one
  above a `YoY %` that heads a **single** trend row (the row beneath
  each §5 stream's value, and the §2 / §3 blocks of a single-product build) — those
  sit flush beneath their parent.

- **Border discipline (whole sheet).** **Never use a double-lined border anywhere.**
  Every subtotal / total row (`Total Units`, `Total Unit Revenue`, `Total Revenue`) is
  marked with a **single-lined "sum bar"** — a thin border applied **only across
  the data columns (Col E onward)**, and never a double line. Total rules never run
  through the label columns (Col A–D).

  **The sum bar sits ABOVE the total — on top of the total cell, never below it.**
  It is a **thin `top` border on the total row's own data cells**
  (`Border(top=Side(style="thin"))`), so the rule separates the line items being
  summed from the total that sums them. Never write the bar as a **`bottom` border
  on the total row** — that draws the rule underneath the number, which reads as an
  underline rather than a sum bar — and never as a bottom border on the row above,
  which puts the rule in the wrong cell's border set even though it lands in the
  same place on screen.

  ```python
  # right — thin TOP border on the total row's data cells
  for col in range(first_data_col, last_data_col + 1):
      ws.cell(row=total_row, column=col).border = Border(top=Side(style="thin"))

  # wrong — bottom border draws the bar beneath the total
  ws.cell(row=total_row, column=col).border = Border(bottom=Side(style="thin"))
  ```

  This applies to **every** row carrying a sum bar, and specifically to
  **`Total Units`** in the §2 `Units Sold` block and **`Total Unit Revenue`** in §4:
  in both, the bar sits on **top** of the total row. Reserve
  the **font underline** (`Font(underline="single")`) for **block / sub-block /
  `YoY %` headers**; total rows are **bold only** (no label underline).
  **A `YoY %` row never carries a sum bar** — a growth rate is not a
  sum, so the `Total Units` row *inside* a `YoY %` block is **bold with
  no sum bar**, even though the `Total Units` row it mirrors carries one.

- **Memo rows stay visible.** Every **memo** line item (`Memo: Reported <family> —
  <Product>` in §1.2 / §3, `Memo: Total − Reported (must = 0)` in §6) is an ordinary
  visible italic row, as are the reported anchors `Total Revenue (reported)` / `Net
  Sales (reported)`; no row on the sheet is hidden or collapsed (styling rules). The
  visible layout is exactly the row map below.

- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.2, §3.2, §4.2,
  §5.3 and §6.2 — and in the `Units (Col D)` column of that section's formula table.
  Dollar rows show the placeholder `(USD in <scale>)`: the contract's Rule 2 supplies
  the scale, millions by default, thousands where the digit test puts a small filer.
  Three classifications are specific to this build:
  - **The units scale is set by the price, and the price tag names the physical unit.**
    `Units Sold` rows and `Total Units` are counts in the product's own physical unit,
    so their tag `(<unit>, in <scale>)` is filled with that unit — pairs, vehicles,
    cases — and the tag declares the **display** scale, never the base the series was
    delivered in. `Selling Price` rows divide a money row by a units row, so money scale
    ÷ units scale = price scale: work backward from the price the product actually
    carries. A high-volume, low-price item (footwear, apparel) wants its price in plain
    dollars, so display units in **millions** to match the money rows — `(pairs, in
    millions)` with `(USD per pair)`. A low-volume, high-price item (vehicles) wants
    units in **thousands**, which puts the price in thousands — `(vehicles, in
    thousands)` with `(USD thousands per vehicle)` — **unless** the price is a figure
    analysts quote in plain dollars, as a vehicle ASP is, in which case keep `(USD per
    vehicle)` and record the departure in the row's Col C comment as the contract's Rule
    2 (the coherence paragraph) prescribes. `Memo: Reported selling price` and `Average
    Selling Price` take the same tag as the price rows they sit with. Never scale a
    price to millions.
  - **Percent rows.** Every `YoY %` row — per product, `Total Units`,
    `Average Selling Price`, each stream — is the bare `(%)` the contract's Rule 5
    reserves for a period change, whether the cell is a historical formula or a
    projection driver; it is an italic label + italic data row.
  - **Everything else is money at one scale, memos included.** Each `Unit Revenue`
    product row, `Total Unit Revenue`, every stream value row, the `Other Revenue`
    residual, `Unit Revenue` and `Total Revenue` in §6, `Total Revenue (reported)`
    and `Memo: Total − Reported` all take the one Rule 2 scale — the memos too, because
    a scale mismatch between the modeled total and its reported comparator is exactly
    what they exist to expose. `Total Units`, `Total Unit Revenue` and `Total Revenue`
    carry the SUM-BAR named in their notes; `Average Selling Price` is a weighted
    figure, not a sum, and carries none.
- **Reading the layout blocks (§2.2, §3.2, §4.2, §5.3, §6.2).** Each row's annotation
  has two columns, left to right: the **Col D units tag in parentheses** — `(USD in
  <scale>)` and `(<unit>, in <scale>)` mean the scale is set as described above,
  `<unit>` is the product's physical unit; every other tag is written as it goes in the
  cell — and the note in **square brackets**: the row's real cell indent, then the
  case-by-case source (`deepKPI INPUT` / `FORMULA`), the projection treatment, and
  styling (`bold`, `SUM-BAR`, `italic`). Group, sub-block and
  block headers and the `YoY %` label-only rows carry no tag.
- **Empty data cells show a dash**, not a blank — including every base-column
  `YoY %` cell (there is no prior year to difference against).

### Canonical formatting template (indent / bold / underline / sum-bar map)

Every units build lays its blocks out in exactly this row order and cell formatting.
**Indent** is the **actual cell indent** (`Alignment(indent=n)`), never leading
spaces. Extend the product list (`Product 1 … Product k`) to whatever the company
reports, and repeat the `Unit Economics` group once per unit family where §1.3's
commensurability rule requires it. **This map is the specification — do not reorder
it, do not add rows outside it, and do not drop the memo rows.**

```
[ store roll-forward — already laid down by locationBuild.md, if the location gate passed ]
[ … ]

  Unit Economics                     indent 1 · bold + underline            (group header; label only — no data)
    Units Sold                       indent 2 · bold + underline            (sub-block header; label only — no data)
    <Product 1>                      indent 2                               (input / backsolve; driven forward)
    <Product 2>                      indent 2
    <Product 3>                      indent 2
    Total Units                      indent 2 · bold · single-lined sum bar ON TOP (= SUM(product rows); derived display, never a driver)
    [ blank spacer row ]
      YoY %           indent 3 · bold + underline            (label only — no data)
      <Product 1>                    indent 3                               (YoY; PROJECTION DRIVER)
      <Product 2>                    indent 3                               (YoY; PROJECTION DRIVER)
      <Product 3>                    indent 3                               (YoY; PROJECTION DRIVER)
      Total Units                    indent 3 · bold · NO sum bar           (YoY; derived display, never a driver)

    [ blank spacer row ]
    Selling Price                    indent 2 · bold + underline            (sub-block header; label only — no data)
    <Product 1>                      indent 2                               (backsolve / input; driven forward)
    <Product 2>                      indent 2
    <Product 3>                      indent 2
      Memo: Reported selling price — <Product n>
                                     indent 3 · italic (OPTIONAL — only where the company reports its own ASP / AUR)
    Average Selling Price            indent 2 · plain · NO sum bar          (= Total Unit Revenue ÷ Total Units — weighted, not a sum)
    [ blank spacer row ]
      YoY %           indent 3 · bold + underline            (label only — no data)
      <Product 1>                    indent 3                               (YoY; PROJECTION DRIVER)
      <Product 2>                    indent 3                               (YoY; PROJECTION DRIVER)
      <Product 3>                    indent 3                               (YoY; PROJECTION DRIVER)
      Average Selling Price          indent 3 · plain                       (YoY; derived display, never a driver)

  Unit Revenue                       indent 1 · bold + underline            (block header; label only — no data)
  <Product 1>                        indent 1                               (input / = Units × Price)
  <Product 2>                        indent 1
  <Product 3>                        indent 1
  Total Unit Revenue                 indent 1 · bold · single-lined sum bar ON TOP (= SUM(product rows))

  <Stream 1>                         indent 1 · bold + underline            (block header = the stream's name; label only — no data)
  Revenue from <Stream 1>            indent 1                               (value row; input / = prior × (1 + p/p))
    YoY %             indent 2                               (YoY; PROJECTION DRIVER; no blank row above)

  <Stream 2>                         indent 1 · bold + underline            (one block per stream, same shape)
  Revenue from <Stream 2>            indent 1
    YoY %             indent 2

  Consolidated Revenue               indent 1 · bold + underline            (sub-section header; NOT all caps, NOT enlarged)
  Unit Revenue                       indent 1                               (= §4 Total Unit Revenue)
  Revenue from <Stream 1>            indent 1                               (= that stream's value row; same label)
  Revenue from <Stream 2>            indent 1
  Total Revenue                      indent 1 · bold · single-lined sum bar (= Unit Revenue + Σ streams, in BOTH halves; never the reported input)
    Total Revenue (reported)         indent 2 · input styling · visible (deepKPI input — the anchor the §5 residual reads; historical only)
    Memo: Total − Reported (must = 0) indent 2 · italic (foot check; historical only)
```

**Rules baked into the map above:**

- **Bold rows** are exactly: `Unit Economics`, `Units Sold`, `Selling Price`, each
  `YoY %` header, `Unit Revenue`, each stream header, and
  `Consolidated Revenue` (all also **underlined**); plus `Total Units`,
  `Total Unit Revenue`, and `Total Revenue` (bold + sum bar, **no** underline), and
  the `Total Units` row inside the units `YoY %` block (bold, **no**
  sum bar). Every other row is plain.
- **`Average Selling Price` is deliberately plain — not bold, no sum bar.** It is a
  **weighted average**, not a summation, and marking it like a total invites the
  reader (and the next modeler) to treat it as one. The same applies to its row
  inside the price `YoY %` block.
- **Never underline a total row.** Totals convey themselves with the single-lined sum
  bar across the data columns (Col E onward) — never a font underline, never a double
  border.
- **Forward references are expected and correct.** `Average Selling Price` references
  `Total Unit Revenue`, which sits in the block below it. That is deliberate: it keeps
  the drivers above the revenue they produce, so the build reads top-to-bottom as
  *volume → price → revenue*. Excel resolves forward references without complaint.
- **Single-product build:** drop the per-product rows and the `Total Units` /
  `Average Selling Price` / `Total Unit Revenue` roll-ups per §1.3; each block's lone
  line is **plain** (no bold, no sum bar — it sums nothing), and each
  `YoY %` heads a single trend row (so it gets **no** blank row above
  it).
- **Covers-all build:** there are no `<Stream>` blocks and no stream
  rows in §6 — the consolidated table is `Unit Revenue` straight into `Total Revenue`.

---

## Section 2 — Unit Economics: Units Sold

This block carries the **volume** half of the identity. It sits directly beneath the
`Unit Economics` group header (which is itself the first row of the build, beneath
the store roll-forward if one exists). One row per product, a `Total Units` roll-up,
and a `YoY %` sub-block whose per-product rows become the projection
**volume drivers**.

### 2.1 — The logic

```
  Units Sold — Product n     = reported input                                     [historicals, Cases A1 and B]
  Units Sold — Product n     = Unit Revenue ÷ Selling Price                       [historicals, Case A2 — backsolve]
  Units Sold — Product n     = <prior col> × (1 + YoY %)           [projection]

  Total Units                = Σ Units Sold — Product n                           [both halves]
  YoY %       = this col ÷ prior col − 1                           [historicals, derived]
                             = DRIVER                                             [projection, per product]
```

> **Naming reminder.** The logic blocks in this document write qualified names
> (`Units Sold — Product n`, `Selling Price — Product n`, `Unit Revenue — Product n`)
> so the identity reads unambiguously on the page. **In the delivered workbook the
> Col C label is the product's bare name** (`Footwear`, `Retail Vehicles`) — the
> sub-block header above it supplies the metric. Wherever this document prints a
> qualified name, write the bare product name in the sheet.

- **Derive (historicals):** in Cases A1 and B the units series is a reported deepKPI
  input; in Case A2 it is the backsolve `product revenue ÷ selling price`. Note the
  backsolve foots by construction — `Units × Price` returns the reported revenue
  exactly — so a Case-A2 build never distorts the historical anchor.
- **Trend:** the `YoY %` sub-block shows each product's year-over-year
  volume growth, and `Total Units`' growth as a derived display. This is the trend
  that anchors the forward volume assumption.
- **Project:** each product's units compound off its **own** `YoY %`
  driver; `Total Units` re-sums the driven product rows.

**Rigor note — `Total Units` is a display, never a driver.** It sums the product
rows in both halves. Driving `Total Units` forward independently while also driving
the products would double-drive the block and break the sum; the row would stop
equalling its own components and the reader would have no way to see it. If the only
volume figure a company reports is a single blended total, that is a
**single-product build** (§1.3) — not a license to drive the total.

**Rigor note — commensurability.** `Total Units` is only meaningful when every
product in the block is counted in the same physical unit (§1.3). Name that unit in
Col D on every row of the block, including the total.

**Rigor note — reported basis.** Units are usually reported **net of returns** where
revenue is, but not always. If the filing reports gross units against net revenue,
the backsolved price will sit below the true list price by the return rate. Record
the basis in one Notes line: *"Revenue: <product> units are gross of returns while
revenue is net, so the derived price sits below list price by the return rate;
units are <retail / wholesale>, <company-operated / all channels>."* It is a
definitional gap to disclose, not an error to correct with an invented adjustment.

### 2.2 — Layout

```
  Unit Economics                                                              [indent 1; bold + underlined group header — label only — no data]
    Units Sold                                                                [indent 2; bold + underlined sub-block header — label only — no data]
      <Product 1>                                       (<unit>, in <scale>)    [indent 3; Cases A1/B: deepKPI INPUT; Case A2: FORMULA = §4 Unit Revenue ÷ §3 Selling Price; projection: = prior col × (1 + p/p)]
      <Product 2>                                       (<unit>, in <scale>)    [indent 3; …repeat per product, fixed order…]
      <Product 3>                                       (<unit>, in <scale>)    [indent 3]
    Total Units                                       (<unit>, in <scale>)    [indent 2, bold; SUM-BAR; FORMULA = SUM(product rows) in both halves]
    [ blank spacer row ]
      YoY %                                                    [indent 3; bold + underlined; label-only row — no data]
        <Product 1>                                     (%)                     [indent 4; FORMULA = this col ÷ prior col − 1; italic; base col dash; projection: DRIVER]
        <Product 2>                                     (%)                     [indent 4; …repeat per product…]
        <Product 3>                                     (%)                     [indent 4]
      Total Units                                     (%)                     [indent 3, bold, NO sum bar; FORMULA = this col ÷ prior col − 1; derived display, never a driver]
```

Zero blank rows within the block except the single spacer above the
`YoY %` sub-block (which heads two or more trend rows in any
multi-product build; a single-product build gets **no** blank row there). One blank
spacer row follows the block, before `Selling Price`. `YoY %` is a
**label-only** row — no data in the period columns — and its trend rows sit one
indent deeper at `indent=3`.

### 2.3 — The formulas (cell-by-cell)

"prior col" = the period column immediately to the left. "§3 Selling Price
(col X)" / "§4 Unit Revenue (col X)" = that product's row in the named block, same
column.

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Unit Economics` *(group header)* | | — | dash | dash | `"Group header for the Units Sold and Selling Price sub-blocks. No values."` |
| `Units Sold` *(sub-block header)* | | — | dash | dash | `"Sub-block header; heads the per-product volume rows. No values."` |
| `<Product n>` — **Cases A1 / B** | | `(<unit>, in <scale>)` | deepKPI **input** — reported units sold | historical: same input; **projection:** `= <prior col> × (1 + <YoY %: Product n, this col>)` | `"Reported units sold — <product>, <basis: gross/net of returns>, stored in <ones\|thousands\|millions>. Projection: compounds off its YoY % driver."` |
| `<Product n>` — **Case A2** | | `(<unit>, in <scale>)` | historical: `= <§4 Unit Revenue — Product n, this col> ÷ <§3 Selling Price — Product n, this col>` | historical: same backsolve; **projection:** `= <prior col> × (1 + <YoY %: Product n, this col>)` | `"Backsolve: product revenue ÷ selling price. Projection: compounds off its YoY % driver."` |
| `Total Units` | | `(<unit>, in <scale>)` | `= SUM(<product rows>, this col)` | same | `"= Σ units sold across products. Same physical unit throughout. Derived display — never a driver."` |
| `YoY %` *(label row)* | | — | dash | dash | `"Label row; heads the per-product volume trend rows. No values."` |
| `<Product n>` *(under YoY %)* | | `(%)` | dash | `= <this col Units Sold — Product n> ÷ <prior col Units Sold — Product n> − 1` | `"Volume growth, period over period. Historical: derived. Projection: DRIVER (seeded by the default seed)."` |
| `Total Units` *(under YoY %)* | | `(%)` | dash | `= <this col Total Units> ÷ <prior col Total Units> − 1` | `"Total volume growth, period over period. Derived display — never a driver; it is the mix-weighted result of the per-product drivers."` |

**Sourcing.** Pull each product's units series via `search_kpis` against the shared
inventory, reading the `unit` field to confirm it is a **count**. Confirm the newest
value against the 10-K's key-metrics table before transcribing (§0.1).

### 2.4 — Pre-delivery checklist (Units Sold)

- [ ] One row per product, in the **fixed product order** repeated in every block.
- [ ] Each product's units row is the **reported input** (Cases A1 / B) or the
      **backsolve** `revenue ÷ price` (Case A2) — a live formula, never a hardcode.
- [ ] Every units value passed the **§0.2 magnitude test** in every historical year,
      was **converted to base units on ingest**, and has its **display** scale tagged
      in Col D.
- [ ] All products in the block share the **same physical unit**; `Total Units` is a
      live `SUM` with a single-lined sum bar in **every** column, and that bar is a
      **thin `top` border on the `Total Units` row** — above the total, never below.
- [ ] `Total Units` is **not** a driver, in either half.
- [ ] Each product has a `YoY %` trend row, **dash in the base
      column**, and `Total Units` has one as a derived display (bold, **no** sum bar).
- [ ] One blank spacer row sits directly above the `YoY %` sub-block
      (multi-product builds only).
- [ ] Any **53-week year** in the window is flagged; if it is `N`, the volume growth seed is on the issuer's 52-week basis or from `N−1`, and the comment says so.
- [ ] After recalculation, **zero formula errors**.

---

## Section 3 — Unit Economics: Selling Price

This block carries the **price** half of the identity. It sits directly beneath the
`Units Sold` block, inside the same `Unit Economics` group. One row per product, an
`Average Selling Price` line, and a `YoY %` sub-block whose
per-product rows become the projection **price drivers**.

### 3.1 — The logic

```
  Selling Price — Product n  = Unit Revenue ÷ Units Sold                          [historicals, Case A1 — backsolve]
  Selling Price — Product n  = reported input                                     [historicals, Cases A2 and B]
  Selling Price — Product n  = <prior col> × (1 + YoY %)           [projection]

  Average Selling Price      = Total Unit Revenue ÷ Total Units                   [both halves]
  YoY %       = this col ÷ prior col − 1                           [historicals, derived]
                             = DRIVER                                             [projection, per product]
```

- **Derive (historicals):** in Case A1 the price is the backsolve
  `product revenue ÷ units sold`; in Cases A2 and B it is a reported deepKPI input.
- **Trend:** the `YoY %` sub-block shows each product's year-over-year
  price growth, and the blended `Average Selling Price`'s growth as a derived display.
- **Project:** each product's price compounds off its **own** `YoY %`
  driver; `Average Selling Price` recomputes from the driven totals.

> **`Average Selling Price` is a REVENUE-WEIGHTED average, not a simple average.**
> It is `Total Unit Revenue ÷ Total Units` — never `AVERAGE(<product price rows>)`.
> The distinction is the entire analytical point of the row: an unweighted mean
> ignores mix, so a retailer shifting volume from a $26,000 product to a $7,100
> product shows a *falling* blended ASP on the weighted line and a flat one on the
> unweighted line. The unweighted version is not a cruder approximation of the
> weighted one — it is a different, meaningless number. Write the formula, not the
> shortcut.

**Rigor note — `Average Selling Price` is a display, never a driver.** Like
`Total Units`, it is recomputed in both halves from rows above and below it. Driving
it forward alongside the per-product prices would double-drive the block. Its
forward path is entirely determined by the per-product price drivers and the
per-product volume drivers (which set the mix).

**Rigor note — a reported ASP will not tie exactly.** Where the company also reports
its own ASP / AUR / revenue-per-unit, carry it as a **memo cross-check**
row (`Memo: Reported selling price — <Product>`) and record the gap. Issuers compute
these on their own base — net of returns and allowances, excluding delivery or
shipping revenue, on a channel mix that differs from the revenue line, sometimes as
an average of quarterly figures. **Do not substitute the reported figure for the
backsolved one that anchors the identity**; a close match validates the whole chain
(universe, scale, fiscal-year alignment), and a wide gap is a defect to investigate,
not a number to adopt.

### 3.2 — Layout

```
    Selling Price                                                             [indent 2; bold + underlined sub-block header — label only — no data]
      <Product 1>                                       (USD per <unit>)        [indent 3; Case A1: FORMULA = §4 Unit Revenue ÷ §2 Units Sold; Cases A2/B: deepKPI INPUT; projection: = prior col × (1 + p/p)]
      <Product 2>                                       (USD per <unit>)        [indent 3; …repeat per product, same order as §2…]
      <Product 3>                                       (USD per <unit>)        [indent 3]
      Memo: Reported selling price — <Product n>      (USD per <unit>)        [indent 3; italic; deepKPI INPUT — optional, only where a reported ASP/AUR exists; visible]
      Average Selling Price                             (USD per <unit>)        [indent 3, plain, NO sum bar; FORMULA = §4 Total Unit Revenue ÷ §2 Total Units in both halves]
    [ blank spacer row ]
      YoY %                                                    [indent 3; bold + underlined; label-only row — no data]
        <Product 1>                                     (%)                     [indent 4; FORMULA = this col ÷ prior col − 1; italic; base col dash; projection: DRIVER]
        <Product 2>                                     (%)                     [indent 4; …repeat per product…]
        <Product 3>                                     (%)                     [indent 4]
        Average Selling Price                           (%)                     [indent 4, plain; FORMULA = this col ÷ prior col − 1; derived display, never a driver]
```

Any `Memo: Reported selling price — <Product n>` rows sit together as visible italic
rows beneath the block; where no reported price exists, the memo rows are omitted
entirely. Zero blank rows within the
block except the single spacer above the `YoY %` sub-block. One blank
spacer row follows the block, before `Unit Revenue`.

### 3.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Selling Price` *(sub-block header)* | | — | dash | dash | `"Sub-block header; heads the per-product price rows. No values."` |
| `<Product n>` — **Case A1** | | `(USD per <unit>)` | historical: `= <§4 Unit Revenue — Product n, this col> ÷ <§2 Units Sold — Product n, this col>` | historical: same backsolve; **projection:** `= <prior col> × (1 + <YoY %: Product n, this col>)` | `"Backsolve: product revenue ÷ units sold. Projection: compounds off its YoY % driver."` |
| `<Product n>` — **Cases A2 / B** | | `(USD per <unit>)` | deepKPI **input** — reported selling price / ASP / AUR / revenue per unit | historical: same input; **projection:** `= <prior col> × (1 + <YoY %: Product n, this col>)` | `"Reported selling price — <product>, <basis>. Projection: compounds off its YoY % driver."` |
| `Memo: Reported selling price — <Product n>` *(optional, italic)* | | `(USD per <unit>)` | deepKPI **input** — the company's own ASP / AUR | same input; **blank (dash) in every projection column** | *(no comment — input memo; cross-check vs. the derived price; record the basis gap in the Notes)* |
| `Average Selling Price` | | `(USD per <unit>)` | `= <§4 Total Unit Revenue, this col> ÷ <§2 Total Units, this col>` | same | `"Revenue-weighted ASP = total unit revenue ÷ total units. NOT an average of the product price rows. Derived display — never a driver."` |
| `YoY %` *(label row)* | | — | dash | dash | `"Label row; heads the per-product price trend rows. No values."` |
| `<Product n>` *(under YoY %)* | | `(%)` | dash | `= <this col Selling Price — Product n> ÷ <prior col Selling Price — Product n> − 1` | `"Price growth, period over period. Historical: derived. Projection: DRIVER (seeded by the default seed)."` |
| `Average Selling Price` *(under YoY %)* | | `(%)` | dash | `= <this col Average Selling Price> ÷ <prior col Average Selling Price> − 1` | `"Blended ASP growth, period over period. Derived display — moves with both price and mix; never a driver."` |

- **There is no circularity**, and it is worth being explicit about why. In the
  historical columns causation runs **revenue → price** (Case A1: revenue is sourced
  first, price is defined as revenue ÷ units) or **price → revenue** (Case B: price
  and units are sourced, revenue is their product). In the projection columns
  causation is uniform: **units and price are driven, revenue is their product.** The
  same row therefore carries different formulas in the two halves, which is expected.
  What is **not** acceptable is a *single* historical column in which `Unit Revenue`
  is written as `= Units × Price` while `Price` is written as `= Unit Revenue ÷
  Units` — that is a genuine circular reference and Excel will flag it. Check for it
  after building.

### 3.4 — Pre-delivery checklist (Selling Price)

- [ ] One row per product, in the **same order** as §2, with the **same product
      names**.
- [ ] Each product's price row is the **backsolve** `revenue ÷ units` (Case A1) or
      the **reported input** (Cases A2 / B) — a live formula where derived, never a
      hardcode.
- [ ] Every price value passed the **§0.2 magnitude test** in every historical year,
      and **no formula carries a scale constant** — `revenue ÷ units` on base-unit
      values is already dollars per unit.
- [ ] `Average Selling Price` is `Total Unit Revenue ÷ Total Units` — **not**
      `AVERAGE(product prices)` — in every column, and is **plain** (no bold, no sum
      bar).
- [ ] Neither `Average Selling Price` nor its trend row is a driver.
- [ ] Any company-reported ASP / AUR is carried **only** as a memo
      cross-check, with the basis gap in the Notes line of §1.2.
- [ ] Each product has a `YoY %` trend row, **dash in the base
      column**; one blank spacer row sits above the sub-block (multi-product builds).
- [ ] After recalculation, **zero formula errors** and **no circular reference**
      between §3 and §4 in any single column.

---

## Section 4 — Unit Revenue

This block converts the volume and price rows into dollars. One row per product, in
the same order as §2 and §3, summed to `Total Unit Revenue` — the figure §6 carries
into the consolidated table.

### 4.1 — The logic

```
  Unit Revenue — Product n   = reported input                                     [historicals, Cases A1 and A2 — the anchor]
  Unit Revenue — Product n   = Units Sold × Selling Price                         [historicals, Case B]
  Unit Revenue — Product n   = Units Sold × Selling Price                         [projection, ALL cases]

  Total Unit Revenue         = Σ Unit Revenue — Product n                         [both halves]
```

- **Cases A1 / A2:** the product's revenue is the **reported deepKPI input** in the
  historical columns — the anchor the missing family was backsolved from — and
  becomes the **`Units × Price` product** in projection. That input → formula switch
  is the build's central inversion.
- **Case B:** the product's revenue is the **`Units × Price` product in both
  halves**, because nothing anchors it (§1.2). The row's formula does not change
  across the boundary; only the units and price rows feeding it do.
- **`Total Unit Revenue`** is a live `SUM` in both halves and carries the
  single-lined sum bar **on top of the row** — a thin `top` border across the data
  columns, never a border beneath the total.

**This block has no `YoY %` sub-block.** Product revenue growth is the
arithmetic consequence of the volume and price drivers already visible two blocks
above, and a third growth block would invite a modeler to drive revenue directly —
which would break the identity. Revenue growth is shown once, at the consolidated
level, and only as a derived display if the Notes call for it.

**Rigor note — dollars are always additive.** Even where the §1.3 commensurability
rule forced more than one `Unit Economics` group (products counted in different
physical units), there is **one** §4 block listing **every** product across all
groups, summed to a single `Total Unit Revenue`.

### 4.2 — Layout

```
  Unit Revenue                                                                [indent 1; bold + underlined block header — label only — no data]
    <Product 1>                                         (USD in <scale>)        [indent 2; Cases A1/A2: deepKPI INPUT historical; Case B: FORMULA = Units × Price; projection: FORMULA = Units × Price]
    <Product 2>                                         (USD in <scale>)        [indent 2; …repeat per product, same order as §2 / §3…]
    <Product 3>                                         (USD in <scale>)        [indent 2]
  Total Unit Revenue                                  (USD in <scale>)        [indent 1, bold; SUM-BAR; FORMULA = SUM(product rows) in both halves]
```

Zero blank rows within the block; one blank spacer row after it. These rows are the
**money** family; the **Number format and units** bullet above governs their scale
and tag.

### 4.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Unit Revenue` *(block header)* | | — | dash | dash | `"Block header; heads the per-product revenue rows. No values."` |
| `<Product n>` — **Cases A1 / A2** | | `(USD in <scale>)` | deepKPI **input** — reported product revenue (the anchor) | historical: same input; **projection:** `= <§2 Units Sold — Product n, this col> × <§3 Selling Price — Product n, this col>` | `"Historical: reported product revenue (input, the anchor the <price\|units> backsolve uses). Projection: = units × price."` |
| `<Product n>` — **Case B** | | `(USD in <scale>)` | `= <§2 Units Sold — Product n, this col> × <§3 Selling Price — Product n, this col>` | same formula in both halves | `"= units × price. Constructed, not anchored to a reported revenue line — see the Notes."` |
| `Total Unit Revenue` | | `(USD in <scale>)` | `= SUM(<product rows>, this col)` | same | `"= Σ product revenue across every product and every Unit Economics group. Carried into the consolidated revenue table."` |

### 4.4 — Pre-delivery checklist (Unit Revenue)

- [ ] One row per product, **same names and same order** as §2 and §3, covering
      **every** product across **every** `Unit Economics` group.
- [ ] Cases A1 / A2: the row is the **reported deepKPI input** in every historical
      column and the **`Units × Price` formula** in every projection column.
- [ ] Case B: the row is the **`Units × Price` formula** in **both** halves, and the
      §1.2 cross-check against any overlapping reported revenue was run and its gap
      stated in the Notes line of §1.2.
- [ ] `Units × Price` returns the revenue exactly with **no constant on either
      side** — both rows are on base units (Rule 1).
- [ ] `Total Unit Revenue` is a live `SUM` with a single-lined sum bar in **every**
      column, and that bar is a **thin `top` border on the `Total Unit Revenue`
      row** — above the total, never below.
- [ ] **No `YoY %` sub-block** was added to this section.
- [ ] After recalculation, **zero formula errors**, and in Cases A1 / A2
      `Units × Price` reproduces the reported product revenue exactly in every
      historical column (it does, by construction — verify it anyway).

---

## Section 5 — Other revenue streams (conditional)

**Include this section only for a mixed company** (§1.4) — one whose units cover
only part of reported total revenue. A **covers-all** company has no non-unit
streams, so this section is **omitted entirely**; record the omit decision in one
line in `BUILD_LOG.md`, citing §1. Each stream is its own small block, and each is
projected on its
own `YoY %` driver — never through the units identity; the residual,
when one is needed, is projected as a share of modeled revenue (§5.2).

### 5.1 — What qualifies as a stream (and what is a decomposition)

A line qualifies as an other revenue stream only if **both** tests pass:

1. **The units did not produce it.** Ask: *would this dollar still exist if the
   company sold zero units?* Licensing royalties, franchise fees, membership dues,
   credit-card and financial-services income, financing and extended-warranty
   income, advertising, and shipping revenue all pass. Merchandise sold across the
   counter does not.
2. **It is separately reported in dollars, as its own revenue line** — not as a
   share of another line, and not as a re-cut of revenue already inside §4.

**Decompositions — these are NOT streams, and carrying one double-counts unit
revenue:**

- **Merchandise-category splits** (`Net Sales from Consumables`, `Seasonal`, `Home`,
  `Apparel`) — a partition of the same merchandise revenue by what was sold. If a
  category has its own units or price series it is a **product** (§4); if it does
  not, it is neither a product nor a stream and stays folded into the product it
  belongs to.
- **Geography splits of the same products** (`Net sales in the United States`,
  `Net sales in Canada`) — a partition.
- **Channel splits of the same products** (`Retail net sales` vs.
  `Wholesale net sales` for the *same* goods) — a partition, **unless** each channel
  has its own units and price, in which case they are two **products** in §4, not
  streams.
- **Comparable vs. non-comparable splits** — a partition.
- **Percentage-of-sales series** — a percentage is not a dollar stream (§5.2).

**The partition test:** if adding the candidate to `Total Unit Revenue` would make
the components sum to **more** than reported total revenue, it is a decomposition.
The §6 foot check catches this — but catch it here, before you build the row.

### 5.2 — Materiality, percentage-only streams, and the residual

- **Materiality.** Carve out a stream when it is separately reported in dollars
  **and** is either **≥ ~5% of total revenue** or growing at a materially different
  rate from the products. Below that, leaving it inside the residual is the better
  modeling choice — a 2%-of-sales line modeled as its own block adds a driver and no
  accuracy. **Whichever way you decide, state it in one Notes line:** *"Revenue:
  <channel>, about <x>% of sales, is not carried separately; it stays inside Other
  Revenue."*
- **Reported only as a percentage.** Where a stream is disclosed as a share of sales
  rather than a dollar line, you may derive the dollars as `% × Total Revenue` — but
  only if it clears the materiality bar, and the derived row must be a **live
  formula** referencing both the percentage input and the total, never a typed dollar
  figure.
- **A series labeled like a dollar level may be a percentage.** Run the §0.2
  magnitude discipline on every stream candidate: a stream's value must be a
  plausible fraction of total revenue, in **every** historical year, before you
  transcribe it. A stream returning `2.0` and `4.0` against a company with $15bn of
  net sales is a percentage, not dollars.

**Exactly one line in the build is the residual, and it is always the final stream
block, named `Other Revenue`.** Its historical value is the plug

```
  Other Revenue = <Net Sales (reported)> − <Total Unit Revenue> − SUM(<identified stream rows inside net sales>)      [when the issuer reports a separate revenue face line]
                = <Total Revenue (reported)> − <Total Unit Revenue> − SUM(<identified stream rows>)                  [otherwise]
```

In projection there is no reported total to plug against, so the residual is
projected as a **share of modeled revenue**. Its block carries, in place of a
`YoY %` row, the driver row `Other Revenue — % of modeled revenue` tagged
`(% of modeled revenue)`: historically the live ratio `Other Revenue ÷ (Total Unit
Revenue + Σ named stream rows)`, in projection the default seed (guided, else the latest year, then flat), and `Other Revenue = that driver × (Total Unit
Revenue + Σ named stream rows)`. The denominator excludes the residual itself, so
there is no circularity. The same row's historical cells are the build's fit
diagnostic (§6.1).

which makes the §6 partition exhaustive **by construction**. **Classify each
stream by the income statement** — inside the issuer's net sales line, or its own
face line (Costco's `Membership fees`, Macy's and Target's `Other revenue`) — and
record it in one Notes line per stream: *"Revenue: <stream> is presented <inside
net sales / as its own line on the income statement> and sits <above / below> Net
Sales."* §6 places the stream above or below `Net Sales` accordingly, and a
face-line stream is never inside the residual. Read it off the
statement, never off what the stream "ought" to be. `Unit Revenue` is
**never** the residual in this build — in Cases A1 / A2 it is anchored to reported
product revenue, and in Case B it is a construction whose gap to reality is exactly
what the residual is there to expose. If every stream is reported and they exhaust
revenue, the residual block is omitted.

> **A large or swinging residual is a defect, not a result.** A stable residual of a
> few percent of revenue signals a healthy build. One that is large, or that flips
> sign between years, means a units or price universe is wrong, a decomposition
> slipped into §5, a Case-B product's price basis is off (gross vs. net, delivery
> revenue included or excluded), or the fiscal-year alignment is wrong. Investigate
> before delivering; if the residual turns out to be a genuine, growing revenue
> stream, **break it out as its own named block** rather than leaving it buried.

### 5.3 — Layout (per stream)

```
  <Stream 1>                                                                  [indent 1; bold + underlined block header = the stream's name; label only — no data]
    Revenue from <Stream 1>                             (USD in <scale>)        [indent 2; deepKPI INPUT historical; projection: = prior col × (1 + YoY %)]
      YoY %                              (%)                     [indent 3; FORMULA historical = this col ÷ prior col − 1; DRIVER in projection (the default seed: guided, else the latest change, then flat); italic; no blank row above]

  <Stream 2>                                                                  [indent 1; bold + underlined block header — one block per stream, same shape]
    Revenue from <Stream 2>                             (USD in <scale>)        [indent 2]
      YoY %                              (%)                     [indent 3]

  Other                                                                       [indent 1; bold + underlined block header — the residual; only if the identified streams do not exhaust]
    Other Revenue                                       (USD in <scale>)        [indent 2; FORMULA historical = Reported Total − Total Unit Revenue − Σ named streams; projection: = the driver row beneath × (Total Unit Revenue + Σ named streams), this col]
      Other Revenue — % of modeled revenue                (% of modeled revenue)  [indent 3; FORMULA historical = Other Revenue ÷ (Total Unit Revenue + Σ named streams); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible — its historical cells are the fit diagnostic]
```

Each stream's header row is **bold + underlined at `indent=1`** with dashes in the
data columns and carries the stream's name as the issuer captions it; the value row
beneath it is a **plain `indent=1`** row labeled `Revenue from <Stream>` — the same
label §6 uses when it restates the row — (no bold, no sum bar — a stream is a single
reported figure, not a sum); its `YoY %`
row is at **`indent=2`**, italic, immediately beneath with **no blank row above it**
(it heads a single trend row). **One blank spacer row separates one stream's block
from the next**, and from `Consolidated Revenue`.

Name each block header after the stream as the issuer reports it — `Licensing`,
`Franchise`, `Membership Fees`, `Financing and Other Income`, `Advertising` — spelled
out, dash-separated qualifiers, per the styling rules — and label its value row
`Revenue from <that name>`. The residual block is headed `Other` with the value row
`Other Revenue`. Keep the streams in a **stable order** and repeat that order in §6.

### 5.4 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `<Stream n>` *(block header)* | | — | dash | dash | `"Block header for a non-unit revenue stream. No values."` |
| `Revenue from <Stream n>` *(value row)* | | `(USD in <scale>)` | deepKPI **input** — reported stream revenue (or `= <% input> × <Total Revenue>` for a percentage-derived channel) | historical: same; **projection:** `= <prior col> × (1 + <YoY %, this col>)` | `"<Reported \| derived-from-percentage> non-unit revenue. Projection: compounds off its YoY % driver."` |
| `Other Revenue` *(residual value row)* | DATA_DEPENDENT | `(USD in <scale>)` | historical: `= <§6 Total Revenue (reported), this col> − <§4 Total Unit Revenue, this col> − SUM(<identified stream rows>, this col)` | **projection:** `= <Other Revenue — % of modeled revenue, this col> × (<§4 Total Unit Revenue, this col> + SUM(<identified stream rows>, this col))` | `"Residual = reported total − total unit revenue − identified streams. Makes the consolidated revenue table's partition exhaustive. Projection: a share of modeled revenue, off the driver row beneath — it cannot stay a plug (there is no reported total to plug against, and it would be circular)."` |
| `Other Revenue — % of modeled revenue` *(driver row under the residual, in place of its `YoY %`; visible)* | DATA_DEPENDENT | `(% of modeled revenue)` | `= <Other Revenue, this col> ÷ (<§4 Total Unit Revenue, this col> + SUM(<identified stream rows>, this col))` | **projection: DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The residual's share of the revenue the build models (unit revenue + named streams). Historical: the fit diagnostic — low single digits expected; double digits = a large stream unmodeled, a wrong price basis or a wrong units universe. Projection: driver, guided or else the latest year, then flat."` |
| `YoY %` | DATA_DEPENDENT | `(%)` | dash | `= <this col> ÷ <prior col> − 1`; **projection: DRIVER** — red font + dashed border, seeded per **Projections** (the default seed: guided, else the latest change, then flat) | `"Stream growth, period over period. Historical: derived. Projection: driver, guided or else the latest change, then held flat."` |

Pull each stream series via `search_kpis` against the shared inventory, reading the
`unit` field. If a stream is bundled with others in a single reported line, use that
reported line and state the bundling in the row's cell comment; the residual still
makes the build foot.

### 5.5 — Pre-delivery checklist (other revenue streams)

- [ ] Section is **present iff** the company is **mixed** (§1.4); omitted for
      covers-all, with the decision recorded in `BUILD_LOG.md`.
- [ ] Every block passes **both** §5.1 tests; no merchandise-category, geography,
      channel, or comparable/non-comparable **decomposition** was carried as a stream.
- [ ] Every stream value survived the **magnitude test** in every historical year —
      no percentage transcribed as a dollar level.
- [ ] The **materiality decision** for each candidate is stated in one Notes line
      (§5.2 wording), including any channel deliberately left inside the residual.
- [ ] Any percentage-derived stream is a **live formula** referencing the percentage
      input and total revenue, not a typed figure.
- [ ] Exactly **one** line in the build is the residual, and it is the final
      block, headed `Other` with the value row `Other Revenue` — never `Unit Revenue`.
- [ ] The residual is **small and stable**; a large or sign-flipping residual was
      investigated, not absorbed.
- [ ] Each stream is its own mini-block (bold + underlined header, plain value row,
      `YoY %` at `indent=2` with **no** blank row above it), separated
      from the next by **one** blank spacer row.
- [ ] After recalculation, **zero formula errors**.

---

## Section 6 — Consolidated Revenue (the foot)

This block closes the build: it restates the components and foots to reported total
revenue.

### 6.1 — The partition and the foot

```
  Net Sales     = Unit Revenue + Σ (streams inside net sales) [+ Other Revenue residual]     [only when the issuer reports a separate revenue face line]
  Total Revenue = Net Sales + Σ (streams that are their own face line)
                = Unit Revenue + Σ (Other Revenue Streams) [+ Other Revenue residual]        [when no Net Sales row is laid]
```

Because §5 made the streams an **exhaustive partition** of the reported figure
less `Total Unit Revenue`, each sum equals the reported figure exactly in every
historical column. `Net Sales` is laid only when the income statement shows a
merchandise line **and** at least one separate revenue line (§5.2); for a
single-revenue-line issuer it is omitted and `Total Revenue` is the reported net
sales line.

**`Total Revenue` is a live sum formula in BOTH halves**, carrying the sum bar —
exactly as the layout specifies. The **anchor** to reality is enforced by
construction (§5.2 designates the residual line). Two different things are then
checked, by two different rows:

- **Wiring** — `Memo: Total − Reported (must = 0)`. Because the residual is
  `reported − everything else`, this difference is **zero by construction whenever
  a residual row exists**; what it catches is a wrong cell reference, a sign error
  or a mis-mapped column, any of which breaks the identity. It does not say whether
  the model explains revenue.
- **Fit** — the §5 driver row `Other Revenue — % of modeled revenue`: its historical
  cells are the residual's share of the revenue the build models (unit revenue plus
  the named streams). For an issuer whose streams are disclosed and correctly placed
  it should be a **low single-digit percentage**; a double-digit share is not a
  result but a large stream left unmodeled, a wrong price basis or a wrong units
  universe — investigate before delivering. This is the row an analyst reads; it is
  visible, and in projection it is the driver the residual is projected off.


- **Historical columns:** `Total Revenue (reported)` (and `Net Sales (reported)`
  when `Net Sales` is laid) is the reported deepKPI input — the figure the build
  must reproduce — and `Memo: Total − Reported (must = 0)` proves the wiring. The
  anchors are visible input rows (the §5 residual reads them); the wiring memo is a
  visible italic row; the fit diagnostic is the visible §5 driver row.
- **Projection columns:** there is no reported total to anchor to, so the memo rows
  are **blank (dash)** and `Net Sales` / `Total Revenue` are simply the assembled
  sums. Note in a comment which columns are reported-anchored and which are
  assembled.

> **Do not make `Total Revenue` itself the reported input.** If the row that the
> wiring check subtracts from is the same reported figure it compares to, the check
> reads 0 even when a component references the wrong cell. The sum must be
> assembled from the rows above it, and the reported figure must sit in its own
> input row. (That the check also reads 0 whenever a residual exists is by design —
> that is what the §5 fit row is for.)

`Total Revenue` is **never a driver** in either half.

### 6.2 — Layout

```
  Consolidated Revenue                                                        [indent 1; bold + underlined sub-section header — NOT all caps, NOT enlarged; it is still under REVENUE]
    Unit Revenue                                        (USD in <scale>)        [indent 2; FORMULA = §4 Total Unit Revenue, this col]
    Revenue from <Stream>                               (USD in <scale>)        [indent 2; FORMULA = that stream's value row, this col — same label; one row per stream inside net sales, same order as §5]
    Other Revenue                                       (USD in <scale>)        [indent 2; FORMULA = the §5 residual value row, this col; only if §5 has one]
  Net Sales                                           (USD in <scale>)        [indent 1, bold; SUM-BAR; FORMULA = Unit Revenue + SUM(rows above) in BOTH halves; ONLY when the issuer reports a separate revenue face line]
    Net Sales (reported)                              (USD in <scale>)        [indent 2; deepKPI INPUT — pale-green, hyperlinked, visible; historical only — dash in projections; ONLY with Net Sales]
    Revenue from <Stream>                               (USD in <scale>)        [indent 2; FORMULA = that stream's value row, this col — same label; one row per stream that is its own face line]
  Total Revenue                                       (USD in <scale>)        [indent 1, bold; SUM-BAR; FORMULA = Net Sales + SUM(face-line stream rows), or Unit Revenue + SUM(stream rows) when no Net Sales row — in BOTH halves]
    Total Revenue (reported)                          (USD in <scale>)        [indent 2; deepKPI INPUT — the anchor the §5 residual reads; pale-green, hyperlinked, visible; historical only — dash in projections]
    Memo: Total − Reported (must = 0)                 (USD in <scale>)        [indent 2; italic; FORMULA check; historical only — dash in projections; visible]
```

The `Consolidated Revenue` header is **bold + underlined at `indent=1`** and is
**not** all caps or enlarged — it is a sub-section under the `REVENUE` header, not a
top-level section header. `Total Revenue` is **bold** with a **single-lined sum bar**
across the data columns — no double border, no label underline. The two memo rows sit
immediately beneath it as visible italic rows. Every row here is a **restatement** — a
live reference to the row it names, never a re-entered value and never a second copy
of a deepKPI input.

### 6.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Consolidated Revenue` *(header)* | | — | dash | `"Sub-section header. No values."` |
| `Unit Revenue` | | `(USD in <scale>)` | `= <§4 Total Unit Revenue, this col>` | `"= total unit revenue (Σ units × price across products). Restated, not re-entered."` |
| `Revenue from <Stream>` *(one per stream inside net sales)* | | `(USD in <scale>)` | `= <that stream's §5 value row, this col>` — same label as that row | `"= the stream block's value (reported input historical / driver-compounded projection). Inside the issuer's net sales line."` |
| `Other Revenue` *(residual, if §5 has one)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <§5 Other Revenue value row, this col>` | `"= the residual non-unit revenue."` |
| `Net Sales` *(only when a separate face line exists)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <Unit Revenue> + SUM(<rows above>)` — **the same live sum in both halves** | `"= unit revenue + streams inside net sales (+ residual). Assembled sum in both halves; historically it reproduces reported net sales by construction. The cost build strikes cost of sales against this row."` |
| `Net Sales (reported)` *(input row; only with `Net Sales`)* | HAS_NET_SALES_ROW | `(USD in <scale>)` | deepKPI **input** (pale-green, hyperlinked, visible), historical columns only; **blank (dash) in projections** | `"Reported net sales — the historical anchor the residual plugs against."` |
| `Revenue from <Stream>` *(one per stream that is its own face line)* | | `(USD in <scale>)` | `= <that stream's §5 value row, this col>` — same label as that row | `"= the stream block's value. Reported as its own face line."` |
| `Total Revenue` | | `(USD in <scale>)` | `= <Net Sales> + SUM(<face-line stream rows>)`; with no `Net Sales` row: `= <Unit Revenue> + SUM(<stream rows>)` — **the same live sum in both halves** | `"= net sales + face-line streams (or unit revenue + Σ non-unit streams). Assembled sum in both halves; historically it reproduces reported total revenue by construction. Never a driver, never the reported input."` |
| `Total Revenue (reported)` *(input row)* | | `(USD in <scale>)` | deepKPI **input** (pale-green, hyperlinked, visible), historical columns only; **blank (dash) in projections** | `"Reported total revenue — the historical anchor."` |
| `Memo: Total − Reported (must = 0)` *(italic)* | | `(USD in <scale>)` | `= <Total Revenue> − <Total Revenue (reported)>`, historical columns only; **blank (dash) in projections** | `"Wiring check: must equal 0 every historical period (zero by construction when a residual exists; a non-zero means a wrong reference, sign or column)."` |

- Use `SUM(...)` over the contiguous stream rows rather than chained addition, so a
  dashed stream cell cannot throw `#VALUE!`.
- For a **covers-all** company there are no stream rows: the table is
  `Unit Revenue` → `Total Revenue`, and the foot check still applies.

### 6.4 — Pre-delivery checklist (Consolidated Revenue)

- [ ] Every component row is a **live reference** to its source row; no value is
      re-entered.
- [ ] The stream rows listed here are **exactly** the streams built in §5, in the
      same order — none missing, none invented.
- [ ] `Total Revenue` is a live **`SUM` formula in every column, historical and
      projected** — **not** the reported input — bold with a single-lined sum bar
      throughout; `Net Sales` likewise, laid **iff** the issuer reports a separate
      revenue face line, with each stream placed above or below it per its §5.2
      classification; the `Consolidated Revenue` header is bold + underlined but
      not all caps or enlarged.
- [ ] `Total Revenue (reported)` is the deepKPI **input** and is the *only* place
      the reported total appears, so the foot check compares two independently
      constructed numbers.
- [ ] `Memo: Total − Reported (must = 0)` evaluates to **0** in **every** historical
      column after recalculation.
- [ ] The wiring memo `Memo: Total − Reported (must = 0)` is **blank (dash)** in
      every projection column and is a visible italic row; the §5
      driver row `Other Revenue — % of modeled revenue` (where a residual exists) is
      **visible** and its historical cells read **low single digits** — or the cause
      is identified and stated in the row's comment.
- [ ] `Total Revenue` is **not** a driver in either half.
- [ ] **Indentation across the whole build is real cell indent**, not padding:
      every Col C label satisfies `value == value.lstrip()`, and each row's level
      matches the **Canonical formatting template** via `Alignment(indent=n)`
      (`Alt, H, 6`). Sweep the sheet programmatically before delivering — the
      product names repeat across §2, §3 and §4, so a single padded label breaks
      the parallelism and the header underlines.
- [ ] Applying the indent **preserved** each cell's existing `horizontal` /
      `vertical` alignment (no bare `Alignment(indent=n)` that wipes the rest).
- [ ] Every **block header** sits at the **same indent** as its own line items
      (bold + underline sets it apart), with `Unit Economics` at `indent=1` as the
      one documented exception.
- [ ] After recalculation there are **zero formula errors** anywhere in the build,
      and **no circular references**.

---

## Section 7 — Worked examples (illustrative)

Two illustrative companies, walked through the build to show how the rows chain.
**The figures are illustrative** — round numbers chosen for transparency, not any
real issuer's reported data. The point is the mechanics, the case selection, and the
traps. Build window FY2022 (base) → FY2025.

### 7.1 — Case A1, mixed: a branded footwear company (revenue + units reported)

Reported: `Footwear net sales` and `Apparel net sales` in dollars, `Pairs sold` and
`Apparel units sold` as counts, plus a non-unit `Licensing Revenue` line. deepKPI
delivers units
**in thousands** and revenue **in millions**; both are converted to base units on
ingest (units to ones, revenue to dollars), so the price backsolve is a plain
`revenue ÷ units` with no constant. Volume is high and the price is tens of dollars,
so units **display in millions** to match the money rows and the price lands in plain
dollars. Both products are counted in commensurable retail units, so one
`Unit Economics` group serves.

**§2 Units Sold** *(units, in millions)*

| Row | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|
| Footwear *(input)* | 40.0 | 42.0 | 43.0 | 45.0 |
| Apparel *(input)* | 12.0 | 12.5 | 13.0 | 14.0 |
| **Total Units** *(= SUM)* | **52.0** | **54.5** | **56.0** | **59.0** |
| *YoY % — Footwear* | — | +5.0% | +2.4% | +4.7% |
| *YoY % — Apparel* | — | +4.2% | +4.0% | +7.7% |
| *YoY % — Total Units* | — | +4.8% | +2.8% | +5.4% |

**§3 Selling Price** *(backsolved = §4 revenue ÷ §2 units; USD per unit)*

| Row | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|
| Footwear | $60.00 | $63.00 | $65.00 | $67.00 |
| Apparel | $40.00 | $41.00 | $42.00 | $43.00 |
| Average Selling Price *(= Total Unit Revenue ÷ Total Units)* | $55.38 | $57.95 | $59.66 | $61.31 |
| *YoY % — Footwear* | — | +5.0% | +3.2% | +3.1% |
| *YoY % — Apparel* | — | +2.5% | +2.4% | +2.4% |
| *YoY % — Average Selling Price* | — | +4.6% | +2.9% | +2.8% |

> **Read the ASP row against the shortcut.** The simple average of the two FY2025
> price rows is `(67.00 + 43.00) ÷ 2 = $55.00`. The weighted ASP is **$61.31** —
> 11% higher, because footwear is 76% of the volume. `AVERAGE(price rows)` is not a
> rough version of this number; it is a different number with no economic meaning.

**§4 Unit Revenue** *(reported inputs — the anchors; USD in millions)*

| Row | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|
| Footwear *(input)* | 2,400.0 | 2,646.0 | 2,795.0 | 3,015.0 |
| Apparel *(input)* | 480.0 | 512.5 | 546.0 | 602.0 |
| **Total Unit Revenue** *(= SUM)* | **2,880.0** | **3,158.5** | **3,341.0** | **3,617.0** |

**§5 Other revenue streams:** `Revenue from Licensing` (input, under a `Licensing` block header) 90 / 100 / 110 / 120 —
its three historical changes are +11.1% / +10.0% / +9.1%, so its projection
driver seeds to the latest, **+9.1%**. The identified stream exhausts the remainder, so **no residual block** is
needed.

**§6 Consolidated Revenue (FY2025, USD in millions):** `Unit Revenue 3,617 +
Revenue from Licensing 120 = Total Revenue 3,737`, which equals reported total revenue — `Memo: Total
− Reported (must = 0)` = **0**.

**Projecting FY2026 (footwear only, illustrative).** The units driver seeds to the
latest historical change, **+4.7%** → 45.0 × 1.047 = **47.1** million units. The
price driver seeds to its latest change, **+3.1%** → $67.00 × 1.031 = **$69.08**.
Footwear revenue = 47.1 × $69.08 = **$3,254M**. Volume and price each carry their own visible, overrideable assumption
— which is the whole reason this build exists.

### 7.2 — Case B, mixed: an online used-vehicle retailer (units + price reported)

Reported: `Retail units sold` and `Revenue per retail unit sold`, `Wholesale units
sold` and `Wholesale revenue per unit` — **units and price, no product revenue
line**. Revenue is therefore **constructed**, not anchored (§1.2), and the gap to
reported total revenue lands in the residual. deepKPI delivers units as **actual
counts** and prices in **actual dollars**, so the ingest conversion is a no-op.
Vehicles are commensurable across both products, so one `Unit Economics` group
serves.

**§2 Units Sold** *(vehicles; both inputs)* and **§3 Selling Price** *(USD per
vehicle; both inputs)*

> **A declared coherence departure.** Units display in **ones** and revenue in
> **millions**, so the displayed operands do not divide to the displayed price
> (11,960 ÷ 460,000 ≠ 26,000). Rescaling units to thousands would put the price at
> `26.0`, which is not how a used-vehicle ASP is quoted, so the conventional display
> wins and each `Selling Price` row's Col C comment records it: `"Displayed in plain
> USD per vehicle by convention; operands are in millions and ones, so this row does
> not reconcile on the page. The formula divides base-unit values and is exact."`

| Row | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|
| Units — Retail | 400,000 | 380,000 | 420,000 | 460,000 |
| Units — Wholesale | 250,000 | 240,000 | 270,000 | 300,000 |
| **Total Units** | **650,000** | **620,000** | **690,000** | **760,000** |
| Price — Retail | $28,000 | $27,000 | $26,500 | $26,000 |
| Price — Wholesale | $7,000 | $6,800 | $6,900 | $7,100 |
| Average Selling Price *(weighted)* | $19,923 | $19,181 | $18,830 | $18,539 |

> The weighted ASP falls **−6.9%** across the window while the retail price falls
> only −7.1% and the wholesale price *rises* +1.4% — because wholesale volume grew
> faster than retail, shifting mix toward the cheaper unit. The simple average of
> the two FY2025 prices is **$16,550**, which is neither a price the company charges
> nor a number that reconciles to anything.

**§4 Unit Revenue** *(= units × price, a formula in **both** halves; USD in millions)*

| Row | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|
| Retail | 11,200 | 10,260 | 11,130 | 11,960 |
| Wholesale | 1,750 | 1,632 | 1,863 | 2,130 |
| **Total Unit Revenue** | **12,950** | **11,892** | **12,993** | **14,090** |

**§5 residual:** reported total revenue is 13,400 / 12,300 / 13,440 / 14,600, so the
`Other Revenue` residual is **450 / 408 / 447 / 510** — **3.3% – 3.5%** of total in
every year. Small, same sign, stable: a healthy Case-B build, and the residual is
plausibly the financing / extended-warranty income the filing describes. Its driver
row `Other Revenue — % of modeled revenue` reads 3.5% / 3.4% / 3.4% / 3.6% of modeled
revenue, and its projection seeds to the latest year, **3.6%**. Had the residual
run at 25% of revenue, or flipped from +450 to −300, the build would be wrong and no
amount of plugging would fix it.

**§6 Consolidated Revenue (FY2025, USD in millions):** `Unit Revenue 14,090 + Other
Revenue 510 =
Total Revenue 14,600` = reported — foot check **0**.

---

## Projections (forecast years)

After the **historical** build above (§0 – §7) is laid down, recalculated and footed
(the §6 `Total − Reported (must = 0)` check passes in every historical column),
**extend the entire build into the projection window** before the downstream handoff
(§8). The projection window is the **five fiscal years after the last historical
year** (`N+1 … N+5`) per the **Model timeline** in `../../../SKILL.md` — do not
redefine it here. Add five more **annual** columns immediately to the right of the
historical block, continuing the same left → right, oldest → newest order; the build
stays **annual**.

**The overwhelming majority of the build simply drags across as formulas.** Only a
small, enumerable set of **drivers** are entered as forward assumptions:

| # | Driver | Where | Seed |
|---|---|---|---|
| 1 | `<Product n>` under **Units Sold**'s `YoY %` | §2, one per product | **default seed, then flat** |
| 2 | `<Product n>` under **Selling Price**'s `YoY %` | §3, one per product | **default seed, then flat** |
| 3 | `<Stream n>`'s `YoY %`; for the residual block, `Other Revenue — % of modeled revenue` | §5, one per stream | **default seed, then flat** |

That is the complete list. **Any other typed value in a projection column is a bug.**
In particular, **`Total Units`, `Average Selling Price`, every `Unit Revenue` row,
`Total Unit Revenue`, and `Total Revenue` are never drivers** — they are computed
results, and driving any of them would break the identity the build is built on.

### Driver styling (applies to every projection driver)

Mark **every** projection driver cell so it reads as a forward assumption — visually
distinct from both the formula cells and the historical deepKPI input cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **A dashed box on all four sides of each individual driver cell** (openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom` — one complete box
  **per cell**, applied **after** any shared row-border pass so a later border write
  cannot overwrite the box). Do **not** reduce it to a single bottom border.
- **No pale-green fill and no hyperlink** — projection drivers are assumptions, not
  deepKPI-sourced actuals.
- **Exception to the "formulas are black" rule.** A projection driver keeps the red
  font + dashed box **even though its default value is a live formula** (the seeding
  formula below). The red/dashed treatment marks it as the intended override point.
  Every **non-driver** projection cell keeps standard formula styling — black font,
  no fill, no dashed box — identical to its historical styling, dragged one column
  right.

### Driver value methodology (the default seeds)

Two seed rules, applied by driver **type**:

- **Rate drivers — the default seed, then flat (drivers 1 and 2).** `N+1` = the guided value where the guidance table names the driver; else the latest year on the issuer's normalized basis where disclosed (a 52-week comparable, organic growth after an acquisition); else the **latest historical year** (`N`), written by the renderer as a live formula with an `ISNUMBER` fallback to `N−1` and `N−2`. When `N` itself is the 53-week year or the first comparison after an acquisition and no normalized figure exists, the seed references `N−1` and the comment says why. `N+2 … N+5` = `= <driver N+1 cell>` (flat).
- **Stream rate drivers — the default seed, then flat (driver 3).** The same rule as drivers 1 and 2: `N+1` = the guided value if any, else the stream's latest historical `YoY %` (the `ISNUMBER`-guarded latest-year formula the renderer writes), `N+2 … N+5` flat. A CAGR is **not** used as a seed anywhere in this build.
  - **Basis-break guard.** Where a stream's basis changed mid-window (a line stepping
    209 → 139 → 1,301 is a basis break, not growth), seed from the latest year on
    the current basis or type an assumption — and add one Notes line: *"Revenue:
    <stream> growth is seeded from FY<a>; the FY<b> figure is on a different
    basis."* Never seed off a change computed across a basis break.
  - **The residual is a ratio driver, not a growth driver.** Its row is
    `Other Revenue — % of modeled revenue`, seeded by the same default-seed rule; see Part 4.

The modeler may type a specific assumption over any driver cell; the red/dashed
styling flags exactly which cells are meant to be overwritten. Anchor the forward
assumptions on the historical trend plus management guidance, disclosed pricing
actions, inflation, and any announced product-mix shift — not on an unexplained
number.

### Part 1 — Units Sold (§2)

- **`<Product n>`** — now the **formula** `= <prior col> × (1 + <its YoY %, this col>)` in every projection column, regardless of whether it was a
  reported input (Cases A1 / B) or the `revenue ÷ price` backsolve (Case A2)
  historically. Under Cases A1 / B this is the row's **inversion point**.
- **`YoY %` — `<Product n>`** — the **driver** (red/dashed; the default seed, then
  flat; when `N` is the 53-week year the seed follows the rule above and the
  comment says so).
- **`Total Units`** — the **same `SUM` formula** as the historical columns; drag it
  across. Never a driver.
- **`YoY %` — `Total Units`** — unchanged derived-display formula
  (`= this col ÷ prior col − 1`). With the per-product drivers seeded flat, it shows
  the mix-weighted blend of them, which will generally **not** equal any single
  product's driver — that is correct, not an error.

### Part 2 — Selling Price (§3)

- **`<Product n>`** — now the **formula** `= <prior col> × (1 + <its YoY %, this col>)` in every projection column, regardless of whether it was the
  Case-A1 backsolve or a reported input historically. Under Case A1 this is the row's
  **inversion point**.
- **`YoY %` — `<Product n>`** — the **driver** (red/dashed;
  the default seed, then flat).
- **`Average Selling Price`** — the **same formula** as the historical columns,
  `= <§4 Total Unit Revenue> ÷ <§2 Total Units>`; drag it across. Never a driver, and
  never re-expressed as an average of the projected price rows.
- **`Memo: Reported selling price — <Product n>`**, if present — a historical-only
  input; leave its projection cells **blank (dash)**.

### Part 3 — Unit Revenue (§4)

- **`<Product n>`** — the **formula** `= <§2 Units Sold — Product n, this col> ×
  <§3 Selling Price — Product n, this col>` in every projection column, in **all**
  cases. Under Cases A1 / A2 this is the row's inversion point (reported input
  historically, formula in projection); under Case B the formula is unchanged from
  the historical columns.
- **`Total Unit Revenue`** — the **same `SUM` formula**; drag it across. Never a
  driver.

**This is the mechanism the whole build turns on:** a volume assumption raises
`Units Sold`, a price assumption raises `Selling Price`, and their product raises
`Unit Revenue` — separately, visibly, and with the mix effect falling out of
`Average Selling Price` automatically.

### Part 4 — Other revenue streams (§5)

- **`Revenue from <Stream n>`** value row — **historical unchanged** (reported input, or the
  derived-from-percentage formula). For **projection**: `= <prior col> × (1 + <its
  YoY %, this col>)` — the same input → compounding inversion as
  Parts 1 and 2.
- **The residual is the exception to its own historical formula.** Historically the
  `Other Revenue` block is a plug against reported total revenue. There is no
  reported total in the projection columns, so it **cannot** stay a plug — that would
  be circular against §6's `Total Revenue`. It is projected as a **share of modeled
  revenue**: `= <Other Revenue — % of modeled revenue, this col> × (<Total Unit Revenue, this
  col> + SUM(<named stream rows>, this col))`, the driver row beneath it seeded
  default seed, then flat like every other driver. The denominator excludes the residual
  itself, so there is no circularity. **State this inversion in one Notes line:**
  *"Revenue: in the forecast Other Revenue is a share of modeled revenue, held at
  the latest ratio, rather than a plug."*
- **`YoY %`** — the **driver** for each named stream (red/dashed;
  the default seed, then flat).

### Part 5 — Consolidated Revenue (§6)

- **`Unit Revenue`** and each **`Revenue from <Stream>`** restatement row — the
  **same live references** as the historical columns; drag them across (they now
  point at the projected §4 / §5 values).
- **`Net Sales`** (when laid) and **`Total Revenue`** — the **same `SUM`
  formulas** as the historical columns; drag them across. Neither is **ever** a
  driver in either half. The only thing that changes across the boundary is *what
  anchors them*: historically the components are constructed to reproduce
  reported net sales and total revenue; in projection they are simply assembled.
- **`Net Sales (reported)`**, **`Total Revenue (reported)`** and
  **`Memo: Total − Reported (must = 0)`** — **blank (dash)** in every projection
  column. Do not extend a reported anchor into years that have not been reported.

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=` formula
  (no hardcoded numbers). The **only** seeded cells are the three driver types
  enumerated above — one per product for volume, one per product for price, one per
  stream.
- **Driver seeding.** Rate drivers: `N+1` = the default seed (the guided value where the guidance table names it, else the latest clean historical year), `N+2 … N+5 = N+1`. Stream drivers and the residual's ratio driver: the same rule.
- **No total or blended row is a driver.** `Total Units`, `Average Selling Price`,
  every `Unit Revenue` row, `Total Unit Revenue`, and `Total Revenue` carry **no**
  red/dashed cells anywhere in the projection block.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors**, and **no circular references** (confirm §3 ↔ §4 is a one-directional
  reference within each column, and that the §5 residual is a share of modeled revenue rather
  than a subtraction in projection).
- **Continuity at the boundary.** `N+1` units compound off `N`'s units; `N+1` price
  compounds off `N`'s price; `N+1` product revenue is the product of those two; each
  stream's `N+1` compounds off its `N` value. Eyeball the `N` → `N+1` step on every
  driven line — a visible discontinuity means a reference is off by one column.
- **Identity coherence.** In every projection column,
  `Unit Revenue — Product n = Units Sold — Product n × Selling Price — Product n`
  exactly, `Total Unit Revenue = Σ` the product rows, and
  `Average Selling Price = Total Unit Revenue ÷ Total Units` exactly.
- **No sign or magnitude absurdities.** No projected revenue, unit count, or price
  goes negative or to zero; no price or volume compounds to an implausible level by
  `N+5`. Check the **cumulative** effect of each driver, not just the annual rate — a
  +8% price driver held flat for five years is **+47%**, and combined with a +5%
  volume driver it is **+87%** on that product's revenue.
- **Mix sanity.** Compare `Average Selling Price` at `N+5` to `N`. If the blended ASP
  moves sharply while every product's price driver is modest, the volume drivers are
  shifting mix hard — confirm that is intended and note it.

---

## Section 8 — Downstream handoff

After the build is laid down, recalculated and footed:

- Confirm **zero formula errors** and **no circular references** (LibreOffice /
  `recalc.py`).
- Confirm the **foot**: `Memo: Total − Reported (must = 0)` equals **0** in every
  historical column, and `Total Revenue` is the assembled sum in every projection
  column.
- Confirm the **cross-checks** were run and recorded: any reported ASP / AUR against
  the derived price (§3), any overlapping reported revenue against a Case-B product's
  construction (§1.2), and — where a store roll-forward exists — revenue per store as
  a sanity read recorded only in `BUILD_LOG.md` (§0.3).
- Hand back to the retail router (`../retail.md`), reporting: the **products carried
  and their order**, **each product's case (A1 / A2 / B)**, whether the build is
  **covers-all or mixed** and which **streams** were carried, the **residual line and
  its typical size as a percentage of revenue**, the **historical window** used, and
  the **row addresses** of `Total Revenue`, `Total Unit Revenue`, each product's
  `Unit Revenue` row, and each stream — so downstream sections can reference them
  without re-deriving anything. The router reports the build method onward to the
  parent revenue router (its Step 5).
- The downstream **costs / margins** builds reference the revenue lines laid down
  here (e.g. gross profit per unit = unit revenue − product cost of sales, both over
  the same `Units Sold` row), so keep the row labels stable, the product order fixed,
  and the units basis explicit.

### Notes to record in the workbook

One line per fact, each written as `Revenue: <fact>` in an analyst's words: no
section numbers, no case names, no skill vocabulary.

- The isolation decision from §1.1: *"Revenue: units × price covers <product
  revenue>; products: <list>; <stream> is carried separately (FY<n> 10-K)."*
- The units basis and the universe for every product: *"Revenue: <product> units
  are gross of returns while revenue is net, so the derived price sits below list
  price by the return rate; units are <retail / wholesale>, <company-operated / all
  channels>."*
- Any 53-week year in the window: *"Revenue: FY<n> had 53 weeks; unit growth is
  seeded from FY<a>, which is unaffected."*
- Each stream's materiality decision, including any channel deliberately left
  inside the residual: *"Revenue: <channel>, about <x>% of sales, is not carried
  separately; it stays inside Other Revenue."*
- Each stream's presentation: *"Revenue: <stream> is presented <inside net sales /
  as its own line on the income statement> and sits <above / below> Net Sales."*
- The residual's size and stability: *"Revenue: Other Revenue, the residual, is
  <x>% of revenue in FY<n> (<range>); it holds unmodeled streams and the
  units-times-price difference."*
- For a product built as units × price, its gap to any overlapping reported figure:
  *"Revenue: <product> revenue is built as units × price and runs <x>% <above /
  below> the reported <caption>, a <gross-versus-net / channel> difference; the gap
  sits in Other Revenue."*
- The reported ASP / AUR cross-check: *"Revenue: the issuer's reported <ASP /
  units> differs from the derived figure by <x>%; the issuer's is <net of returns /
  on a different channel mix>."*
- Any driver seeded from a year other than the latest, and why: *"Revenue:
  <stream> growth is seeded from FY<a>; the FY<b> figure is on a different
  basis."*
- The residual in the forecast: *"Revenue: in the forecast Other Revenue is a share
  of modeled revenue, held at the latest ratio, rather than a plug."*

### Record in `BUILD_LOG.md`, not the Notes

The stage's hand-back report carries the same.

- Each product's pairing case (A1 / A2 / B) and whether the build is covers-all or
  mixed; the omit decision for §5 when it is covers-all.
- The segment map (`../../../SKILL.md`, "The segment map"): each brand this build laid
  a revenue row for, named as the inventory's segment series spell it, and that row's
  key — the brand rows of the `Unit Revenue` block, not the consolidated table's
  one-line restatement of their total.
- The delivered base of every units and revenue series and the conversion applied
  to bring it to base units, so the ingest step is auditable.
- Where a store roll-forward exists, the revenue-per-store cross-check result:
  never a row, never a Notes line.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's unit-economics lines; the store roll-forward and all non-revenue
sections are owned by their respective skills.*
