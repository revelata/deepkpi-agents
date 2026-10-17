---
name: costs
description: >
  ROUTER — builds the COSTS section of an operating-model workbook for a US
  public company, but does not build it directly. Invoked by the `operating-model`
  orchestrator AFTER the revenue build and the depreciation schedule are fully
  done, which passes the resolved
  `company_id`, official company name, workbook path, the shared KPI inventory,
  and the INDUSTRY already classified by `industry-classification/` (orchestrator
  Step 1.2). This skill's job is to route the cost build to the industry-specific
  sub-skill for that industry: `restaurants/` for restaurant companies, `retail/`
  for retailers and consumer-merchandise companies (apparel, footwear, grocery,
  mass / club / dollar stores, specialty and beauty retail), `software/` for
  software / technology companies. No other industry reaches this router.
  The industry sub-skill performs the
  actual deepKPI pulls and lays out line items beneath the `COSTS` ALL-CAPS
  header, formatting per ../../_common/revelata-excel-styling-rules.md.
---

# costs (industry router)

This sub-skill is part of the `operating-model` system and owns the **COSTS**
section. It does **not** build the cost model itself. Instead it **routes** to the
matching industry-specific sub-skill, which performs the actual build.

The motivation mirrors the revenue router: cost structures are industry-specific.
A restaurant company is modeled on food & beverage cost, restaurant labor,
occupancy, and other restaurant operating expenses (often as a % of restaurant
sales); a retailer on cost of sales — which typically carries buying,
distribution and occupancy inside it — walked down to gross profit, plus SG&A and
any impairment / store-closure charges (as a % of net sales, and per
company-operated location where a store roll-forward exists); a software /
technology company on cost of revenue by stream (walked down to gross profit),
R&D, sales & marketing, and G&A (as a % of revenue). Rather than one generic
cost builder, each industry gets a dedicated pipeline.
This router picks the right one.

## Prerequisite — revenue build and depreciation schedule must be complete

This router runs **only after the REVENUE section and the DEPRECIATION SCHEDULE
have been fully built** (orchestrator Step 4, items 1 and 2). The schedule's
`Depreciation & Amortization` row is what a cost build's total-D&A line references
in the projection columns, so it must exist before any cost build runs; the schedule
sits below COSTS on the sheet, which does not matter (`../SKILL.md`, "Build
mechanics"). Two things must already be true before this file does anything:

1. The **revenue build is finished** — its line items are laid down in the
   workbook beneath the `REVENUE` header. The cost build references revenue
   (e.g. restaurant-level margin, cost ratios as a % of sales), so the revenue
   lines must exist first.
2. The company's **industry has already been classified** by
   `../industry-classification/industry-classification.md` (orchestrator Step
   1.2), and that determination has been carried forward to this router by the
   orchestrator — the same one the revenue router routed on.

If the orchestrator routed here before the revenue build completed, **stop** and
return control — do not build costs out of order.

**Inputs expected from the orchestrator:** resolved `company_id`, official company
name, the path to the scaffold workbook (with the REVENUE section already built),
the **shared KPI inventory** from the orchestrator's `list_kpis` call, and the
**industry determination** (restaurant / retail / software) from the
orchestrator's Step 1.2.

**Also carried forward for every company**: the revenue hand-back's **segment map**
(`../SKILL.md`, "The segment map"), which a cost build on a segment path uses to find
each segment's revenue rows. Pass it through unchanged.

**Also carried forward for retail companies**, and required by the retail cost
build: the **revenue build method** the retail sub-router selected
(`comparableStoresBuild` / `unitsBuild` / `sqftBuild` / `other`). Pass it through —
`retail/retailCosts.md` uses it to pick its revenue denominators. No location-gate
flag is carried: whether the per-company-operated-location cost block is built is
decided by the presence of the `Company-Operated EOP Balance` contract row in the
REVENUE section (`../SKILL.md`, "Contract rows"), which the cost build tests itself.

**Data source:** deepKPI only — see `../../_common/data-source-rules.md`. On failure,
follow `../../_common/connection-failure.md`.

**Formatting:** the downstream industry sub-skill follows
`../../_common/revelata-excel-styling-rules.md` and builds with the **xlsx** skill.

## Step 1 — Reuse the industry classification (do NOT re-classify)

The company's industry is **already known**: the orchestrator ran
`../industry-classification/industry-classification.md` once at its Step 1.2 and
passed the result to the revenue router and to this router. **Use it as-is.** Do
**not** call `get_company_summary` and do **not** re-derive the industry — the
classification is made exactly once, so revenue and costs never disagree about
what the company is.

If no industry determination was passed, the orchestrator skipped its Step 1.2:
**stop** and return control. Do not classify here.

## Step 2 — Route to the industry sub-skill

Based on the (already-known) industry, hand the build to exactly one sub-skill,
passing it **all of the inputs this router received** — resolved `company_id`,
official company name, workbook path, the shared KPI inventory, and the industry
determination:

- **Restaurant** → invoke **`restaurants/restaurantsCosts.md`** (the restaurant
  cost pipeline).
- **Retail** → invoke **`retail/retailCosts.md`** (the retail cost pipeline). Pass
  it, in addition to the standard inputs, the **revenue build method** the retail
  sub-router selected — see the inputs section above. Unlike the revenue side, retail costs are **not** sub-routed by build
  method: `retail/retailCosts.md` is a single pipeline that reads the build method
  to pick its revenue denominators, so there is exactly one retail cost file to
  invoke regardless of which revenue sub-build ran.
- **Software / technology** → invoke **`software/softwareCosts.md`** (the software
  cost pipeline).

Every company that reaches this router resolves to exactly one of these three
routes — there is no "no build" outcome here, because a company outside the three
supported industries was turned away by the orchestrator at Step 1.2. The route
here must match the industry the **revenue** build used, so revenue and costs are always
built for the same company profile (e.g. a company whose revenue was built by
`software/software.md` has its costs built by `software/softwareCosts.md`, and one
whose revenue was built through `retail/retail.md` has its costs built by
`retail/retailCosts.md`).

State which route you picked and why (one line, citing the orchestrator's
industry determination), before handing off, so the routing decision
is auditable. For **retail**, state the revenue build method in the same line, so
the retail cost build's choice of revenue denominators is auditable from the routing
line alone (whether it builds per-location costs is decided by the
`Company-Operated EOP Balance` row, which it verifies itself).

## Step 3 — Hand off

The industry sub-skill is responsible for its own deepKPI pulls (using
`search_kpis` against the shared inventory for the specific cost series it needs),
period columns, formulas, provenance hyperlinks, and styling. This router does
**not** write to the workbook itself; once it has routed, the industry sub-skill
takes over the COSTS section build.

## Step 4 — Findings from a stage

A `DEFECT UPSTREAM` record returned by any stage beneath this router is **returned
unchanged as this router's own outcome** — this router never acts on it, names a level, or
re-runs anything on its own. When the orchestrator (`../SKILL.md`, Step 4.2) asks this router
to **re-run from a named stage forward**, re-run that stage with the finding it carries and
then every stage after it in this router's order, running the route selection again as
part of that; return the re-issued hand-back reports.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed by the
  orchestrator. This router makes **no** new deepKPI calls; it only reuses the
  orchestrator's industry determination to route.
- The industry classification must match the one the revenue build used — same
  company, same industry, same route family. Both routers consuming the one
  determination from Step 1.2 (rather than re-classifying) is what guarantees this.
- **The revenue side sub-routes by build method; the cost side does not.** Retail
  revenue is split across four sub-builds behind `revenue/retail/retail.md`, but
  retail costs are one file. Route to `retail/retailCosts.md` and pass the build
  method along as an input — never try to pick a cost file by build method.
- Adding a new industry pipeline later means a criterion in
  `../industry-classification/`, a new sibling folder under `costs/` with one
  routing branch in Step 2, and the matching revenue build under `../revenue/`.
