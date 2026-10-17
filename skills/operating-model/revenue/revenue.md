---
name: revenue
description: >
  ROUTER — builds the REVENUE section of an operating-model workbook for a US
  public company, but does not build it directly. Invoked by the `operating-model`
  orchestrator, which passes the resolved `company_id`, official company name,
  workbook path, the shared KPI inventory, and the INDUSTRY already classified by
  `industry-classification/` (orchestrator Step 1.2). This skill's job is to route
  the build to the industry-specific sub-skill for that industry: `restaurants/`
  for restaurant companies, `retail/` for retailers and consumer-merchandise
  companies (apparel, footwear, grocery, mass / club / dollar stores, specialty
  and beauty retail), `software/` for software / technology companies. No other
  industry reaches this router. The industry sub-skill performs the actual deepKPI
  pulls and lays out line items beneath the `REVENUE` ALL-CAPS header, formatting
  per ../../_common/revelata-excel-styling-rules.md.
---

# revenue (industry router)

This sub-skill is part of the `operating-model` system and owns the **REVENUE**
section. It does **not** build the revenue model itself, and it does **not**
classify the company. It **routes** on the industry the orchestrator hands it
(classified once by `../industry-classification/industry-classification.md`) to
the matching industry-specific sub-skill, which performs the actual build.

The motivation is that revenue builds are industry-specific: a restaurant company
is modeled on units × AUV × same-store sales, a SaaS company on ARR/seats, an
upstream E&P on production volumes × realized price, a refiner on throughput ×
crack spread, a retailer on store count × sales-per-square-foot, and so on.
Rather than one generic revenue builder, each industry gets a dedicated pipeline.
This router picks the right one.

**Inputs expected from the orchestrator:** resolved `company_id`, official company
name, the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator's `list_kpis` call, and the **industry determination** (restaurant /
retail / software) from the orchestrator's Step 1.2 — with, for software, the
**revenue model** (platform / subscription / advertising / mixed) the same step
returned.

**Data source:** deepKPI only — see `../../_common/data-source-rules.md`. On failure,
follow `../../_common/connection-failure.md`.

**Formatting:** the downstream industry sub-skill follows
`../../_common/revelata-excel-styling-rules.md` and builds with the **xlsx** skill.

## Step 1 — Take the industry as given (do NOT re-classify)

The company's industry is **already known**: the orchestrator ran
`../industry-classification/industry-classification.md` at its Step 1.2 and
passed the result here. **Use it as-is.** Do **not** call `get_company_summary`
and do **not** re-derive the industry — the classification is made exactly once,
so revenue and costs never disagree about what the company is.

If no industry determination was passed, the orchestrator skipped its Step 1.2:
**stop** and return control. Do not classify here.

## Step 2 — Route to the industry sub-skill

Based on the classification, hand the build to exactly one sub-skill, passing it
**all of the inputs this router received** — resolved `company_id`, official
company name, workbook path, and the shared KPI inventory — plus the industry
determination and, for software, the revenue model, exactly as the orchestrator
passed them:

- **Restaurant** → invoke **`restaurants/restaurants.md`** (the restaurant revenue
  pipeline).
- **Retail** → invoke **`retail/retail.md`** (the retail revenue pipeline).
  `retail/retail.md` is itself a **sub-router**: it picks the build method that
  the company's disclosure actually supports and hands off to
  `retail/comparableStoresBuild/comparableStoresBuild.md`,
  `retail/locationBuild/locationBuild.md`, `retail/sqftBuild/sqftBuild.md`,
  `retail/unitsBuild/unitsBuild.md`, or `retail/other/other.md`. Do **not** call
  those build files directly from this router; always go through
  `retail/retail.md`, and let it own the build-method decision.
- **Software / technology** → invoke **`software/software.md`** (the software
  revenue pipeline).

Every company that reaches this router resolves to exactly one of these three
routes — there is no "no build" outcome here, because a company outside the
three supported industries was turned away by the orchestrator at Step 1.2 and
never arrives.

State which route you picked and why (one line, citing the industry determination
and its basis) before handing off, so the routing decision is auditable.

## Step 3 — Hand off

The industry sub-skill is responsible for its own deepKPI pulls (using
`search_kpis` against the shared inventory for the specific series it needs),
period columns, formulas, provenance hyperlinks, and styling. This router does
**not** write to the workbook itself; once it has routed, the industry sub-skill
takes over the REVENUE section build. The same applies to
retail: `retail/retail.md` is a router, so the build begins one level deeper in
the selected build sub-skill.

## Step 4 — Report the build method back

Return, along with the completed REVENUE section:

- the **segment map** from the sub-build's hand-back report (`../SKILL.md`, "The
  segment map"): each issuer segment the build laid revenue rows for, named as the
  inventory's segment series spell it, with the keys of its rows; an empty map when
  the build laid no segment, brand or banner rows — the orchestrator passes it to the
  costs router and to the consolidated section;
- for retail, the **build method** `retail/retail.md` selected (comparable
  stores / units / square footage / other) — the orchestrator passes it to the
  costs router, which hands it to the retail cost build; and
- the one-line routing justification you stated in Step 2.


## Step 5 — Findings from a stage

A `DEFECT UPSTREAM` record returned by any stage beneath this router is **returned
unchanged as this router's own outcome** — this router never acts on it, names a level, or
re-runs anything on its own. When the orchestrator (`../SKILL.md`, Step 4.2) asks this router
to **re-run from a named stage forward**, re-run that stage with the finding it carries and
then every stage after it in this router's order, running the route selection again as
part of that; return the re-issued hand-back reports.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed by the
  orchestrator. This router makes **no** new deepKPI calls.
- Adding a new industry pipeline later means a criterion in
  `../industry-classification/`, a new sibling folder under `revenue/` with one
  routing branch in Step 2, and the matching cost build under `../costs/`. 
