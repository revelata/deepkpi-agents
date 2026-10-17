---
name: operating-model
description: >
  Builds the scaffold for a full operating model of a US public company from
  Revelata deepKPI data, then orchestrates section sub-skills to fill it in.
  Takes a ticker or company name as input, resolves it to a deepKPI
  `company_id` via `query_company_id`, classifies the company's industry once
  (restaurant, retail or software — any other industry stops here with an
  unsupported-industry message and no workbook), and produces a single-sheet Excel
  (.xlsx) workbook with styled-but-empty ALL-CAPS section headers — Revenue,
  Costs, Consolidated Financials, Depreciation Schedule, Net Working Capital —
  following ../_common/revelata-excel-styling-rules.md. After the scaffold is
  laid down, it discovers the company's full KPI inventory once via `list_kpis`
  and shares it, then hands each section to its dedicated sub-skill, built in
  dependency order (revenue, depreciation-schedule, costs, consolidated-financials,
  net-working-capital) and rendered in the fixed sheet order by the renderer in
  scripts/ (compose the sections as keyed rows, regenerate the whole workbook).
  Triggers:
  "build an operating model", "build a model for", "operating model for a ticker
  or company", "model out this company", "set up the model", "scaffold a model".
  For a single section, a one-off KPI pull, or filing text, use the kpi / filing
  skills directly instead.
---

# operating-model

This skill is the **orchestrator** for building an operating model. Its own job
is narrow: **resolve the company**, **have its industry classified once** (and
stop if it is not one the skill models), **lay down a styled, empty workbook
skeleton** with the five canonical section headers, and **discover the company's
full KPI inventory once** so it can be shared. It does **not** populate any
section itself — each section is built by a dedicated sub-skill that this skill
invokes in turn, drawing on the shared KPI inventory.

**The sole data source for all figures is deepKPI.** Do not use training
knowledge, analyst reports, or any other source for financial figures. Every
number that eventually lands in the workbook must trace back to a deepKPI call
(enforced by the sub-skills).

## GOLDEN RULES (non-negotiable — read before every build)

These rules override convenience, speed, and your own judgment. Violating any of
them is a failed build, even if the output looks correct.

1. **Follow the workflow exactly, in order. Never look ahead.** Execute this
   skill's steps (and each sub-skill's steps) strictly in sequence. Do **not**
   open, read, or reason about a downstream sub-skill before the workflow has
   actually routed you there. You may only read a sub-skill's file at the moment
   the workflow hands control to it. Peeking ahead to "see what's coming" or to
   pre-plan biases your decisions and is prohibited.

2. **Never skip `list_kpis`, and always wait for it to fully resolve.** The full
   KPI inventory discovery (Step 3) is mandatory and must complete before **any**
   routing or sub-skill work begins. It may be large and slow — that is expected.
   Wait for it. If the result is too large to read inline, page through it / parse
   it from the saved file, but **do not** substitute a handful of `search_kpis`
   guesses for the full inventory. Every routing decision depends on the complete
   inventory being in hand, and the sub-skills rely on it to know exactly what to
   call.

3. **Route only on the available KPIs — never on your own knowledge.** Routing
   decisions (e.g. which revenue sub-build to use) must be made **solely** from
   what the KPI inventory contains, exactly as each router's criteria specify. Do
   **not** factor in anything else — not the company's real-world characteristics,
   and not which sub-skill is more complete. Facts about the **nature of the
   business** are not the routers' to decide: the company's **industry** and, for
   software, its **revenue model** (platform / subscription / advertising / mixed)
   are determined exactly once, by the `industry-classification` sub-skill in
   Step 1.2, from the 10-K business description, and handed to the routers as
   inputs. A router may use those determinations and the inventory, and nothing
   else. A company outside the three supported industries (restaurant, retail,
   software) stops at Step 1.2. Nothing is ever routed to a placeholder.

4. **Do not go off on tangents. Build only what the active skill specifies —
   nothing more.** If a sub-skill says it is authored section by section and that
   only the sections present are implemented, build **exactly** those sections and
   **stop**. Do **not** invent, add, "improve," or extrapolate extra sections,
   line items, or analysis beyond what the current skill explicitly defines, even
   if you think it would be helpful. When a skill is incomplete, stop and say so —
   do not fill the gap with your own construction.

If a rule here conflicts with something you want to do, the rule wins. When in
doubt, stop and ask the user rather than improvising.

## Model timeline — historical and projection years

This section is the **single source of truth** for the model's fiscal-year
columns. **Every sub-skill inherits this timeline; none defines its own.**

Let **`N`** = the **last historical fiscal year** — the most recent fiscal year
for which deepKPI has complete reported actuals.

- **Historical years (actuals).** The **four most recent fiscal years** with
  deepKPI actuals: **`N−3`, `N−2`, `N−1`, `N`**. This is the established window the
  revenue build lays down and every downstream section mirrors; older years are
  dropped.
- **Projection years (forecast).** The **five fiscal years immediately after the
  last historical year**: **`N+1`, `N+2`, `N+3`, `N+4`, `N+5`**. The projection
  window is therefore **always five years long**, beginning the year after the last
  historical year.
  - *Example:* if the last historical year is **FY2025**, the projection years are
    **FY2026, FY2027, FY2028, FY2029, FY2030**.
- **Full model horizon** = the four historical years followed by the five
  projection years, oldest → newest, left → right: **`N−3 … N`** (historical) then
  **`N+1 … N+5`** (projection) — **nine fiscal-year columns** in total.

Notes on this definition:

- **"Fiscal year" means the company's fiscal year-end**, not the calendar year —
  many issuers are non-December. `N` is the latest fiscal year fully reported in
  deepKPI.
- The historical/projection boundary is also where cell behavior changes:
  historical columns carry reported deepKPI inputs and live historical formulas;
  projection columns carry the forward drivers/assumptions.
- **Scope of this section:** it fixes *which* fiscal years are historical and
  which are projection, and nothing else. How each section lays its projection
  columns — its drivers, their seeds and the formulas that invert them — is
  defined in that section's own file (every build carries a Projections section);
  build the projection columns exactly as the active sub-skill instructs, never
  from this definition alone.

## Units, scale, and number format

`../_common/revelata-excel-units-and-scale.md` is the **single source of truth** for how
every number in this model is stored, scaled, and labeled. **Read it before
writing any cell, and follow it in every section.** Like the **Model timeline**
above, it is a sheet-wide contract that the sub-skills inherit.

A sub-skill may override a **display scale** or a **tag** for a named row or family
where its own file says so explicitly; nothing may override base-unit storage or
reintroduce a scale constant. Money **precision** is not a stage's choice either: the
renderer derives one format per money family from the stored historical inputs (one
decimal when the issuer reports below the display unit, whole units otherwise, the
contract's Rule 3) and the audit verifies it. The contract's **Rule 6** defines the audit that
**Step 5** runs before delivery.

## Contract rows — the labels sections may reference across section boundaries

The CONSOLIDATED FINANCIALS and DEPRECIATION SCHEDULE builders are identical for every
industry and carry no industry knowledge; they reach into the REVENUE and COSTS sections
**only through the rows below, by these exact labels**. The NET WORKING CAPITAL
builder's mechanics are industry-free too, and its industry knowledge is confined to
one **driver map** per industry (`net-working-capital/<industry>/`) that names which
upstream rows its drivers divide by — the contract rows below plus, under the
issuer's own captions, the cost-of-sales and labor lines the map describes. Every revenue
and cost build must lay the rows that apply to it under these labels, whatever the
issuer's own caption is (the issuer's wording goes in the Col C comment). A downstream
builder never resolves a label by industry, by example, or by fallback between two
spellings. Each contract row also has a **fixed key**, the `{key}` a formula writes to
reference it (Build mechanics), so a cross-section reference is exact whatever anyone's
spelling of the label; and an **existence condition**, evaluable from the shared
inventory or a hand-back report, which is how a downstream stage tells a row that is
missing from one that never exists for this company (Step 4.2).

| Contract row | Key | Laid by | Exists when | Meaning | Status |
|---|---|---|---|---|---|
| `Total Revenue` | `rev_total` | every revenue build (the grand-total row of its consolidated revenue table) | always | reported total revenue in history; the assembled total in projection | in force 2026-10-12 |
| `Revenue from <Stream>` | `rev_<stream>` (slug of the issuer's caption), one per stream | the software revenue builds and the retail units and square-footage builds, one row per named revenue stream each lays; a build whose single metric covers all revenue lays none — its one row is `Total Revenue` (the ARPU build's covers-all case) — (the stream's own block value row and the row that restates it in the consolidated revenue table carry this same label; `<Stream>` is the issuer's caption with the issuer's own revenue noun removed and every other word kept, including a qualifier such as ", net": `Subscription` → `Revenue from Subscription`; `Credit card revenues, net` → `Revenue from Credit Card, net`; `Macy's Media Network revenue, net` → `Revenue from Macy's Media Network, net`; `Net revenue from licensing` → `Revenue from Licensing, net`. The noun removed is one of revenue, revenues, sales, net sales; nothing else is shortened, reordered or renamed, and the issuer's full caption goes in the Col C comment. A caption that is only a revenue noun (`Revenues`, `Net sales`) is a total, never a stream; the residual plug is always `Other Revenue` and never carries a stream name) | for each named stream the revenue build lays; never for the residual, which is `Other Revenue` (`rev_other`) | that stream's revenue — the denominator a cost-of-revenue line divides by; the software cost build matches a cost line to its stream by this label and falls back to `Total Revenue` when no row matches | in force 2026-10-12 |
| `Net Sales` | `net_sales` | every retail revenue build, only when the issuer's income statement shows a merchandise net sales line **and** at least one separate revenue line (membership fees, other revenue); omitted for a single-revenue-line issuer | the shared inventory's `Consolidated Income Statement` shows a merchandise net sales line **and** at least one separate revenue line | the reported merchandise net sales line — the base the retail cost build strikes cost of sales against; it falls back to `Total Revenue` when the row is absent (a row-presence test). Retail-internal, like `Revenue from <Stream>` for software | in force 2026-10-13 |
| `Total Costs and Expenses` | `tce` | every cost build | always | the all-in total of every additive cost line between revenue and `Operating Income (modeled)`, including cost of sales / cost of revenue; `Operating Income (modeled) = Total Revenue − Total Costs and Expenses` | in force 2026-10-12 |
| `Total Costs and Expenses — <Segment>` | `tce_<segment>` | cost builds on a segment path (C1 / C2) | the cost build ran a segment path (its hand-back report says which) | that segment's all-in subtotal; forward, the segment subtotals and the consolidated total tie by the spine rule in `costs/segmentSpine.md` | in force 2026-10-12 |
| `Operating Income (modeled)` / `Operating Income (reported)` | `oi_modeled` / `oi_reported` | every cost build | always / when the inventory lists a reported operating-income line | modeled operating income and the reported cross-check | in force 2026-10-12 |
| `Depreciation & Amortization` | `dna` | the depreciation schedule (its `Depreciation` build) | always | the model's single D&A source: cash-flow D&A in history, `prior-year Net PP&E ÷ Implied Useful Life` forward. CONSOLIDATED FINANCIALS' `Total Depreciation & Amortization` references it in every column; a cost build's total-D&A line references it in the projection columns. A cost build that carries no D&A line (D&A embedded in its cost lines) references nothing — the consolidated section still has its source | in force 2026-10-12 |
| `Company-Operated EOP Balance` | `coeop_total` (consolidated); `coeop_<brand>` per brand / banner block | every location build (its consolidated Total block) | a location build ran (the revenue hand-back report says so) | the consolidated company-operated unit count — the per-location denominator for the cost builds' per-location rows and NWC's lease driver; a downstream builder keys its fallback on the row's absence, never on the industry | in force 2026-10-12 |
The cost-of-sales line is **not** a contract row: its only downstream reader, the NET
WORKING CAPITAL build, resolves it through its industry driver map, under the issuer's
own caption.

**The segment map.** A segment's revenue is not a contract row either, because a revenue
build may lay it as one row or as several (a brand's row; an advertising stream plus that
segment's other-revenue stream). The revenue stage's hand-back report therefore carries a
**segment map**: for each issuer segment the build laid revenue rows for, the segment's
name as the inventory's segment series spell it and the keys of those rows; an empty map
when the build laid no segment, brand or banner rows. The orchestrator passes it with
the revenue hand-back to the costs router and to the consolidated section (Step 4). A
cost build on a segment path takes each segment's revenue from the map and from nothing
else; the consolidated section lays its segment revenue lines from the same map. No
downstream stage resolves a segment by comparing labels.

### Lays when — the row-condition vocabulary

Every stage file specifies its rows in tables that carry a **`Lays when`** column. That
column says under what condition the row must be on the sheet, and `scripts/audit.py`
reads it at Step 5 to check that every specified row was laid. The values below are
the only ones the column may hold; they are defined here once, mirrored as constants
in `scripts/audit.py`, and `make lint` rejects any other value.

| Value | Meaning |
|---|---|
| *(blank)* | the row is always laid, and its historical cells are never all dashes. This is the default; `ALWAYS_COMPLETE` is its explicit spelling. |
| `ALWAYS_COMPLETE` | as blank, written out |
| `ALWAYS_DASHES_OK` | the row is always laid; its historical cells may all be dashes where the issuer reported nothing (an intermittent impairment line, a stream disclosed in one year) |
| `DATA_DEPENDENT` | the row is laid only when the issuer reports the line, which the sheet cannot prove either way; the audit does not check it. Prefer `ALWAYS_DASHES_OK` wherever the text can lay the row empty instead — except for a reported anchor (`<row> (reported)`) and its `Memo: … − reported` check: when the issuer does not report the figure, both are omitted, never laid as dashes, because a check row with nothing to check reads as a failed check; completeness is still tested by the required `Operating Income (reported)` foot |
| a flag expression | the row is laid, complete, exactly when the expression is true; `NOT` and `AND` over the flags below, e.g. `NOT HAS_DNA_EMBEDDED`, `HAS_LOCATION_BLOCK AND HAS_SEGMENT_ROWS` |

Each flag is the presence of one fixed-label row on the finished sheet, so the audit
reads it from the workbook and never from a hand-back:

| Flag | True when the sheet has |
|---|---|
| `HAS_GROSS_PROFIT_ROW` | a `Gross profit` row in COSTS (the issuer presents a gross-profit subtotal) |
| `HAS_DNA_EMBEDDED` | a `Memo: depreciation and amortization (embedded in the lines above)` row in COSTS — the retail cost build's memo row for an issuer whose D&A sits inside cost of sales and SG&A with no face line; the software build records the same fact in Notes and lays no row, so the flag is false on a software sheet and no software row keys on it |
| `HAS_SEGMENT_ROWS` | any `Total Costs and Expenses — <Segment>` row in COSTS (a segment cost path ran) |
| `HAS_LOCATION_BLOCK` | a `Company-Operated EOP Balance` row in REVENUE (a location build ran) |
| `HAS_NET_SALES_ROW` | a `Net Sales` row in REVENUE (the issuer reports merchandise net sales separately) |

A row whose label is a template (`Revenue from <Stream>`, `<Banner> — Costs`) is not
checked by label; the memo rows that foot those families to reported totals are what
guard them, and the audit checks every memo's content.

## Build mechanics — compose the sections, then render the workbook

The workbook is never edited in place. Every section is composed as a list of keyed
rows, and the whole workbook is regenerated from those lists on every render, in the
scaffold order of Step 2. `scripts/framework.py` is the single implementation of this
mechanic, `scripts/style.py` the single implementation of the styling and units
contracts, and `scripts/README.md` shows the build-directory layout. Four rules
follow:

- **One module per section, returning rows.** A section module returns its rows
  (`Row` objects) and its notes, nothing else. It never opens the workbook, never
  writes a cell, never computes a sheet address.
- **Formulas reference rows by key, never by address.** A formula writes `{key}`
  where it needs another row's row number (`=F{rev_total}-F{cost_total}`), and the
  renderer resolves every key at render time. A section may therefore reference a row
  that another section lays down, whichever is written first and wherever it sits on
  the sheet.
- **Build order and sheet order are independent.** Step 4 builds the sections in
  dependency order (revenue → depreciation schedule → costs → consolidated financials
  → net working capital); `assemble()` always places them in the Step 2 scaffold
  order. Nothing about the sheet layout changes when the build order changes.
- **Rendering is whole-workbook, from scratch.** `render()` assigns row numbers,
  resolves keys, applies the styling in `style.py`, sets every row's indent from its
  kind (the styling rules' indent hierarchy: a stage indents only its headers), writes
  the Notes block, and saves.
  Re-running the build after any change re-resolves every reference: there is no
  insertion into a saved workbook and no address that can go stale. A key that no
  assembled section lays down is a render error naming the key and the referencing
  row, not a `#REF!` discovered later.

- **A stage owns its rows; the renderer is never the fix.** Every row has one owner,
  the section or sub-build whose file defines it, and no stage adds, removes or edits a
  row in another stage's module. A stage that needs a row it does not lay references it
  by key and, if the row is missing, reports it (Step 4.2) rather than laying it. What
  gets edited in a correction is always the owner's **section module**, the file the
  agent wrote for that stage; `framework.py`, `style.py` and `audit.py` are fixed plugin
  code. Build-process history — findings, re-runs, their outcomes — goes to
  `BUILD_LOG.md` in the build directory, never into the workbook's Notes block, which
  carries only modeling facts. A **modeling fact** is what a reader needs to interpret
  a number on the sheet: what a line contains, why a plug or a ratio has the size it
  has, which convention or basis was applied. **Build history** is what was tried,
  changed or re-run. The explanation of a plug is a fact and stays on the sheet; the
  story of how the builder found it is history and goes to the log.
- **Three places for what a build records, and the test for each.** Everything a
  stage would write down goes to exactly one of these:
  - **Notes block** — a modeling fact an analyst needs to read the model: what a line
    contains, which basis or convention a ratio uses, a judgment the build made where
    the filing allowed more than one reading, a default the analyst may want to
    override. One line per fact, written as `<Section>: <fact>` in the analyst's
    words, for a reader who has not read this skill: no section numbers, no route,
    tier, path, mode, case or layout names, no driver colors, no words such as
    contract row, spine, hand-back or stage.
  - **`BUILD_LOG.md`** — build history: which route, tier, path or mode ran and why,
    which series was chosen over a sibling, which checks were run and what they
    returned, every re-run and its outcome, every data trap met.
  - **Cell comment** — provenance and basis for one row, on its Col C label cell: the
    series or filing a value came from, the denominator a ratio divides by, which rung
    set a seed. An input cell itself carries no comment — its hyperlink and Col A series
    name are the provenance — unless the value is an override or on a basis the link
    does not show.
  A stage file that says "record" or "note" something names the place; where it
  does not, apply the test above.

After every render, recalculate with the xlsx skill's `recalc.py` (zero formula
errors); at Step 5, run `scripts/audit.py`.

The styling rules and the units contract in `../_common/` remain the specification;
`style.py` carries their values (colors, number formats, borders) once. Skill text
names a convention — "pale-green input fill", "red driver", "SUM-BAR" — and never
restates a color code or a format string. A change to a rule is made in the rule
text and in `style.py` in the same commit.

- **A rate names its base, and a count identity holds only counts.** A rate
  driver's Col D tag names the row its formula multiplies or divides by, and that
  row is on the sheet; a formula never applies a rate to a different row than its
  tag names. A row inside an identity of counts (a unit roll, a store roll) is a
  count, so a percentage never enters a sum of counts. A quantity the issuer states
  as a share of a base is converted on the sheet from a visible share input against
  the row that carries that base, never typed into a formula as a constant; where
  the issuer's base is not one row, the share applies pro rata to each row that
  carries part of it, the comment saying so.
- **The default driver seed is the analyst's: guidance, else the latest year.**
  Every forward driver the builds lay takes its `N+1` value from the first of
  these rungs that applies, and every later year references the `N+1` cell, so
  the assumption is held flat and an override of `N+1` moves the whole line:
  1. **Guided.** The shared guidance table from Step 3.5 names the driver for
     fiscal year `N+1`: the midpoint of the range, written with `drivers_fixed()`
     as a red driver hyperlinked to the earnings-release exhibit, the comment
     quoting the issuer's words.
  2. **Latest year, on the issuer's normalized basis.** The issuer discloses the
     latest year's figure with a distortion removed (organic or constant-currency
     growth, a 52-week comparable, a go-forward sales change, a balance net of a
     named one-off item): that figure, as a red constant with the disclosure cited
     in the comment. The reported historical cell is never changed.
  3. **Latest year as reported.** `drivers()` in `scripts/framework.py` writes
     `= IF(ISNUMBER(N), N, IF(ISNUMBER(N−1), N−1, IF(ISNUMBER(N−2), N−2, 0)))`:
     the most recent numeric value among the three seed years, and **0** when
     there is none (a decomposition disclosed only in the base year). The guard is
     `ISNUMBER`, never `IFERROR`, so a genuine error still surfaces.
  4. **Latest undistorted year.** Only when `N` itself is a disclosed distortion
     and no normalized figure exists — a program year in a unit roll, a 53-week
     `N` under a growth driver, the first comparison after an acquisition — the
     seed references the latest clean year among `N−1` and `N−2`, and the comment
     names the distortion.
  No build averages years into an `N+1` seed, drops a year on its own judgment, or
  seeds a CAGR. The one stated exception is the comparable-sales builds' `N+2`
  rate, which reverts to the historical average comp as the long-run rate after a
  guided or recency-seeded first year; elsewhere a multi-year average appears only
  where a file lays it as a memo. The latest year
  is the convention because it carries no mechanical step at `N+1`: the first
  forward year continues the last actual, and the analyst's view goes on top as an
  override. The driver's cell comment states which rung set it; the build does not
  stop or ask.
- **Episodic cost lines are the one exception to the default seed.** Impairments,
  restructuring and closing charges, settlements and asset gains or losses are seeded
  by the rule in `costs/episodicLines.md`, which every cost build reads at its driver
  methodology step: zero for a one-off, a run-rate for a recurring program line, the
  disclosed remaining cost where the filing states one. The renderer writes those
  seeds with `drivers_fixed()` and `drivers_runrate()`; the default seed is never
  applied to a line in that class.
- **One seed for every driver; the residual is a ratio driver.** No build seeds a
  driver on a CAGR: a named revenue stream's `YoY %` takes the
  default seed above, and a historical CAGR appears only as an informational memo
  where a build lays one. A revenue build's residual plug (`Other Revenue`, the
  reported total less the named components) cannot stay a plug in projection,
  because there is no reported total to plug against, and it is never seeded to zero
  dollars, which would step projected revenue down at `N+1`. It is projected as a
  **share of modeled revenue**: a driver row `Other Revenue — % of modeled revenue`,
  tagged `(% of modeled revenue)`, holds the historical ratio of the residual to
  the named components the build projects (never to a total that contains the
  residual, which would be circular) and takes the default seed in projection; the
  residual is then that driver times those components. The row's historical cells
  are the build's fit diagnostic (low single digits expected) and are visible, not a
  memo.

## Data source

See `../_common/data-source-rules.md` for the MCP-vs-REST routing table and the
canonical inventory of deepKPI operations. This skill uses `query_company_id`
(to resolve the company) and `list_kpis` (to discover the full, shared KPI
inventory once); the `industry-classification` sub-skill it invokes at Step 1.2
uses `get_company_summary` once; the `guidance` sub-skill it invokes at Step 3.5
uses `list_sec_filing_markdowns` and one `get_sec_filing_markdown` to read the
latest earnings-release exhibit once; the section sub-skills then use
`search_kpis` and the statement operations against that shared inventory.

## Hard stop if deepKPI access fails

See `../_common/connection-failure.md`. If deepKPI is unreachable, STOP and ask
the user before falling back to any other source.

## Opening line

Before doing anything else, say:

**"Let me resolve the company in deepKPI and set up the operating model
scaffold."**

## Step 1 — Resolve the company and classify its industry

### 1.1 — Resolve the company

The user provides **either a ticker or a company name**. Detect which:

- **Looks like a ticker** — 1–5 characters, all uppercase, no spaces (e.g.
  `DRI`, `CMG`, `AAPL`): map it to the **official registrant name** first. Use
  your knowledge of the common ticker → issuer mapping, and if there is any
  ambiguity, ask the user to confirm the company before proceeding. `query_company_id`
  resolves by **name**, not ticker.
- **Looks like a company / brand name** (e.g. `Darden`, `Olive Garden`,
  `Chipotle`): use it directly. If the user named a **brand or subsidiary**, map
  it to the **parent registrant** first (e.g. "Olive Garden" → "Darden
  Restaurants").

Then call **`query_company_id`** with the official `company_name` (set
`num_of_res` to 3 so you can disambiguate). Take the `company_id` (SEC CIK for US
companies) from the response. If multiple plausible matches come back, show them
and ask the user to pick. **The `company_id` is required by every sub-skill**, so
carry it forward.

### 1.2 — Classify the industry (supported: restaurant, retail, software)

Invoke **`industry-classification/industry-classification.md`**, passing the
resolved `company_id` and the official company name. It makes one
`get_company_summary` call, applies its criteria in fixed precedence, and hands
back either **`industry: restaurant | retail | software`** with a one-line basis,
or **`UNSUPPORTED — <basis>`**.

- **Supported** → carry the industry and its basis forward — and, for software,
  the **revenue model** the skill also returns. The `revenue` router, the `costs`
  router and the `net-working-capital` build receive the industry in Step 4 and
  act on it; the software revenue router also receives the revenue model. None of
  them re-classifies.
- **`UNSUPPORTED`** → **stop here.** Tell the user, in one short paragraph, that
  this skill currently models **restaurant, retail and software** issuers, what
  the company was classified as and why (the basis), and that no workbook was
  created. Do not scaffold, do not run `list_kpis`, do not route anywhere, and do
  not improvise a generic build. The classification runs before Step 2 precisely
  so that an unsupported company costs nothing and leaves nothing behind.

## Step 2 — Build the empty, styled workbook scaffold

Produce **one** `.xlsx` workbook with a **single worksheet** containing the five
sections **stacked vertically in this exact order**:

1. `REVENUE`
2. `COSTS`
3. `CONSOLIDATED FINANCIALS`
4. `DEPRECIATION SCHEDULE`
5. `NET WORKING CAPITAL`

**Fix the model timeline first.** The renderer cannot render anything, the scaffold
included, without a configured timeline, and it writes every fiscal year-end into the
period header row on every render. So before the scaffold, set a **provisional `N`**:
the fiscal year of the latest annual filing in the free `list_sec_filing_markdowns`
listing (one call, no credits), with the issuer's fiscal year-end convention read from
the same listing. Pass `hist = N−3 … N`, `proj = N+1 … N+5` and the year-end dates to
`configure(...)`. `N` is provisional because the listing can run a year ahead of the
annual series deepKPI holds; the revenue build confirms it (Step 4, item 1).

Produce it with the renderer — `scaffold()` in `scripts/framework.py` after
`configure(...)` (see **Build mechanics**) — which applies
**`../_common/revelata-excel-styling-rules.md`** for all layout and visual
conventions. The scaffold is what the renderer produces when no section has been
assembled yet. Concretely:

- **Columns A and B are hidden** (audit-trail columns); leave **A1:B1 empty**.
- **C1** = the workbook title: **bold, Calibri, 12pt, sentence case**, containing
  the **full official registrant name** (from `query_company_id`) plus what the
  sheet is, e.g. `Darden Restaurants, Inc. — operating model (deepKPI)`. Merge
  rightward (C1:D1) if long.
- **Row 2 is fully blank** (spacer between the title and the body).
- **Gridlines off** for the sheet; font **Calibri** throughout.
- Lay down the five **ALL-CAPS section header rows** in the label column (Col C),
  each **bold and underlined and font size 16**, separated by at least one blank
  spacer row. The renderer places each section's rows beneath its header on every
  render; nothing is inserted into this file later.
- **The period header row carries the timeline's year-end dates**, written by the
  renderer from `configure(...)`: the four historical fiscal years followed by the
  five projection years, per the **Model timeline** above. Nothing else is filled in:
  no data, line items or values. The sub-skills lay the rows beneath the headers.
- Apply **freeze panes** consistent with the styling rules (Cols A–D and the
  title region stay visible).

Save the scaffold to the user's workspace folder and report the saved path, as a link
where the runtime offers one, so the user can see the skeleton before sections are
filled.

## Step 3 — Discover the full KPI inventory (once, shared)

**After** the scaffold is laid down and **before** routing to any sub-skill,
discover **every KPI deepKPI has for this company** in a single call, so all the
sub-skills draw from **one shared inventory** instead of each re-discovering KPIs
on their own.

Call **`list_kpis`** with the resolved `company_id`. See
`../_common/deepkpi-api.md` (the `/v1.0/list_kpis` entry and "Step 2 — Discover
available KPIs") for the exact call. Key points:

- **This call is free** — no credits — so always run it here rather than letting
  each sub-skill spend `search_kpis` credits to find the same names.
- Omit the `source` filter so the inventory spans **all filing types** (both
  annual 10-K and quarterly 10-Q metrics).
- The response is a JSON object keyed by **category** — `Company KPIs`, `Segment
  Financials`, `Consolidated Income Statement`, `Consolidated Balance Sheet`,
  `Consolidated Cash Flow`, `Capital Structure`, `Taxes`, `Miscellaneous`,
  `Off-Balance Sheet Items` — with each value an array of exact KPI name strings.

Read through the full inventory and **understand what is available** before
proceeding: note which categories are populated, which segments/brands appear,
and which KPI names map to each of the five sections. **Retain this inventory in
context as the shared KPI map** and pass it to every sub-skill in Step 4.

If `list_kpis` returns nothing or fails, follow `../_common/connection-failure.md`
(STOP and ask) — do not silently fall back to per-section discovery or other
sources.

**Which filing a historical value comes from.** A series' points are each taken from
some filing, and an issuer may present the same year differently in a later one: a
line reclassified, a figure restated, a line absorbed into another. Every stage applies
one rule: **a historical value is carried on the latest filing's presentation.**

- Before a stage takes a series for any line, it **lists every inventory series whose
  caption names that line** (the face caption, a `Total …` prefix, the note total, a
  segment or geography variant), across **every category** of the inventory and not
  only the category the line was found in; the inventory is in hand and the scan
  costs nothing.
  When that scan finds **two or more series for one caption**, compare their
  overlapping years with the latest 10-K and take the series that matches it; where
  the latest 10-K does not present the year, the provenance-id test below decides.
  Never take the first series found, and never skip the scan because the first
  series looked complete.
- When a later filing **restates** an earlier year, the restated figure is the value and
  the as-filed figure goes in the cell comment ("as filed in the FY<year> 10-K: <value>").
  Which filing a point comes from is read from its provenance id, not from the filing
  text: a deepKPI point carries a date and a docviewer id, and every point sharing one
  id was taken from one filing, so **the latest-dated point under an id is that
  filing's own year**. For year `Y`, the point whose id also carries a later year came
  from the later filing and is the restated value. Where the competing ids both end at
  `Y`, the FY`N` 10-K read in Step 3 settles it; where `Y` is outside that 10-K's
  window and the ids still tie, carry the point whose id ends at `Y`, the other in the
  comment, and log the choice.
- When a line reported in earlier years is later **absorbed into another line**, the
  receiving line is on a consistent basis only if the absorbed line is carried as its own
  row in the years it was separate, dashes after, so the totals agree across the window;
  where the inventory has no series for it, carry the latest presentation and state the
  break in a Notes line ("<Section>: FY<a>–FY<b> <line> excludes <absorbed line>, which
  the issuer folded into it from FY<c>"). A line reported in some years only is never
  omitted on that ground alone.
- Every such choice is one line in `BUILD_LOG.md`; a historical cell that differs from
  the as-filed figure gets the Notes line above.

## Step 3.5 — Pull the issuer's guidance (once, shared)

After the inventory and before any section is built, invoke
**`guidance/guidance.md`**, passing the `company_id`, the company name and the
model timeline. It lists the company's 8-K filings, pulls the **latest
earnings-release exhibit** once, and hands back a **guidance table** for fiscal
year `N+1`: each guided item from its fixed list with the low, high and midpoint,
the basis the issuer states, the verbatim phrase and the citation. An issuer that
guides nothing hands back an empty table, which is a normal outcome, not a stop.
**Retain the table in context and pass it to every sub-skill in Step 4** beside
the inventory: it is the first rung of the default driver seed (Build mechanics)
and the source of the guidance check in CONSOLIDATED FINANCIALS. No sub-skill
pulls a filing to look for guidance on its own.

## Step 4 — Hand off each section to its sub-skill

After the scaffold exists **and the shared KPI inventory and guidance table are in
hand**, build the sections **in order** by invoking the sibling sub-skills, passing
each the resolved `company_id`, the official company name, the workbook path, **the
shared KPI inventory from Step 3 and the guidance table from Step 3.5** so they can
go straight to the relevant KPI names (using `search_kpis` only for the specific
series they need, not to re-discover the catalog) and seed guided drivers without
re-reading any filing. Every sub-skill inherits the **Model timeline** defined
above — the four historical fiscal years (`N−3 … N`) plus the five projection
years (`N+1 … N+5`) — and must not define its own:

1. **`revenue`** — routes by industry and builds the revenue model beneath the
   `REVENUE` header. Pass it the **industry determination from Step 1.2** — and,
   for software, the **revenue model** — in addition to the standard inputs; it
   routes on those and does not classify.
   **Capture, when the revenue build returns, the segment map** from its hand-back
   report ("The segment map", above) and, **for retail, the revenue build method**
   (which revenue sub-build ran) — the costs router and the consolidated section need
   them.
   **Confirm `N`** when the revenue build returns: its first annual series shows the
   last fiscal year with complete actuals. If that differs from the provisional `N`
   of Step 2, re-run `configure(...)` with the corrected timeline, re-run Step 3.5
   (its table is keyed on `N+1`), re-run the revenue stage against the corrected
   years, and render again; rendering is whole-workbook, so nothing provisional
   survives. No later stage has run at that point.
2. **`depreciation-schedule`** — builds the PP&E roll-forward beneath the
   `DEPRECIATION SCHEDULE` header, including the model's single D&A source (the
   contract row `Depreciation & Amortization`). **Runs after `revenue`** (its capex
   and Other rows are a % of `Total Revenue`) **and before `costs`**, because the
   cost build's forward D&A and the consolidated financials' D&A reference it. On
   the sheet it still sits fourth; see **Build mechanics**.
3. **`costs`** — builds the cost structure beneath the `COSTS` header. **Runs only
   after the `revenue` build is fully done** (it depends on the revenue lines and
   on the industry classification established during the revenue build) **and
   after the depreciation schedule** (its total-D&A line's projected cells reference
   the schedule). Pass it the **industry determination from Step 1.2, the segment map and, for
   retail, the build method captured from Step 4, item 1** in addition to the
   `company_id`, company name, workbook path, and shared KPI inventory, so the
   costs router can route by industry **without re-classifying**.
4. **`consolidated-financials`** — builds the consolidated statements beneath the
   `CONSOLIDATED FINANCIALS` header, as references to the REVENUE and COSTS rows and
   to the depreciation schedule's `Depreciation & Amortization` row. Pass it the
   **segment map** captured at item 1 and the cost build's hand-back report (which
   path it ran).
5. **`net-working-capital`** — builds the net working capital schedule. Pass it the
   **industry determination from Step 1.2** as well: it reads that industry's driver
   map (`net-working-capital/restaurants/`, `retail/` or `software/`) for which
   current operating lines to expect and which upstream rows its drivers divide by;
   its mechanics are the same for every industry.

**Order dependency (non-negotiable):** `revenue` first; the `depreciation-schedule`
before `costs`; `costs` before `consolidated-financials`; `net-working-capital`
last. The industry classified once in Step 1.2 is handed to both the revenue
router and the costs router, so the two sections are always built for the same
company profile; neither router re-derives it.
The build order deliberately differs from the sheet order: the renderer places every
section under its scaffold header regardless of when it was built, so a section's
position on the sheet never changes.

Each sub-skill is responsible for its own deepKPI pulls, period columns,
formulas, and styling (all of them also follow
`../_common/revelata-excel-styling-rules.md` and
`../_common/revelata-excel-units-and-scale.md`). Build the whole model **end to
end** by default; pause after the scaffold and confirm between sections only when
the user asks to review the build section by section.

### 4.1 — Vocabulary for the two loops below

A **stage** is one unit of the build that lays rows: the location build, a revenue
sub-build, the franchise block, the depreciation schedule, a cost build, the
consolidated section, net working capital. A build is the ordered list of stages actually
run, in the Step 4 order. A **router** (`revenue/revenue.md`, `costs/costs.md`, the
industry routers beneath `revenue/`) picks which stage file runs in a slot and runs its
section's stages in order; it lays nothing. This orchestrator runs the sections in order,
keeps the build's one log, and is the only thing that ever re-runs a stage. A stage or
router returns an **outcome** by finishing its own hand-back section — `COMPLETE` with its
hand-back report, or one of the fixed strings below.

### 4.2 — A row missing upstream: the correction loop

The routers' `ABORTED` loop (their Step 4.1) handles a stage that cannot be built. This
step handles the other case: a stage finds that **a row it is entitled to expect from an
earlier stage does not exist**. No stage ever lays, edits or plugs another stage's row;
it reports, and the owner is re-run.

**What a stage may report, and how it knows.** A stage may report only a row its own file
declares in its **Dependencies** table: the row as that file names it, the stage that owns
it, the **existence condition** under which the owner lays it, and the **fallback** when
the condition is false (the net-working-capital driver maps are the model). Contract rows
are declared once in the table above with a fixed key and condition. Diagnosis is three
mechanical steps: the row is in the stage's Dependencies table; its existence condition
evaluates **true** on evidence the stage may read (the shared inventory, a hand-back
report, or the filing where the stage's own text already reads it); and no row in the
owner's module matches it — the renderer reports the key unresolved, or the stage's own
check finds none. Condition **false** is not a finding: the stage takes its declared
fallback. A reference that is in no Dependencies table and does not resolve is not a
finding either: the build stops with `RE-ENTRY FAILURE — undeclared dependency: <stage>,
<row>` and the pair is a skill defect to report, not something to work around.

**Outcomes.**

| Outcome | Returned by | Meaning |
|---|---|---|
| `DEFECT UPSTREAM — <owner>: no <row> for <scope>, <columns>; <evidence>` | any stage; returned **unchanged** by every router it passes through | a declared row whose condition is true does not exist. `owner` = the section and, where relevant, the stage within it, as the Dependencies table names it; `scope` = a brand / banner / segment as the owner's hand-back report spells it, or `consolidated`; `evidence` = the series or filing citation, informational only |
| `RE-ENTRY FAILURE — <reason>` | the re-run owner, or this orchestrator | the row could not be laid; or the finding repeats one already acted on; or the dependency is undeclared |
| `OUT OF ORDER — <section>` | a stage's prerequisite guard | this orchestrator's own error: build that section, then resume |

**The loop.**

1. **Report.** The stage stops at the check that found the row missing and returns the
   record to the file that invoked it, keeping its module as laid so far. A router
   returns the record unchanged as its own outcome, so every finding reaches this
   orchestrator by one or two hops; no file decides a level.
2. **Repeat check.** Keep one **ledger** in `BUILD_LOG.md`, keyed by (owner, row,
   scope). A record whose key is already there is **not** re-run — the owner would
   produce the same module from the same text — and the stage that reported it receives
   `RE-ENTRY FAILURE — unresolvable` (step 5). This is the only termination guard and it
   is sufficient: findings travel backward in build order, re-runs forward, the possible
   keys are finite, and a re-run is deterministic. Log the record.
3. **Re-run the owner.** Tell the owner's section router to re-run its section **from the
   owner stage forward** (re-run a cross-section builder directly). The owner reopens its
   own file — permitted under Golden Rule 1, the workflow now routes there — applies its
   own text to the finding, trying its own paths in its own order and testing after each
   whether a row matching the record now exists in its module, and commits the first path
   that satisfies it. **Satisfy or leave untouched:** if none does, it changes nothing and
   returns `RE-ENTRY FAILURE — <reason>` in its own terms ("gross split disclosed at the
   consolidated level only"). It re-pulls at most the series the finding needs; the
   inventory is never re-listed. It re-issues its hand-back report.
4. **Re-run everything after the owner, in build order.** The router finishes its section
   from the owner forward — its route selection runs again as part of that, so routing
   re-evaluates itself — and this orchestrator then re-runs every later section. Each
   stage runs again from its own file against the rows that now exist, so every
   row-presence test is re-evaluated. Stages between the owner and the one that reported
   never see the finding; they are simply run again. There is no partial re-render: a
   forward re-run is always correct and is one to a few stages.
5. **On `RE-ENTRY FAILURE`**, re-run the stage that reported with the reason. It does one
   of three things, in this order and nothing else: its declared fallback for that
   situation; its own `ABORTED` to its router, if it is a revenue sub-build that cannot
   build without the row; otherwise the build stops naming the row and the reason.
6. **New information is a new finding.** A stage may report against the same owner again
   only with a different row or scope; the identical record is what step 2 refuses.
7. **Log, not Notes.** Every event goes to `BUILD_LOG.md`. The workbook's Notes block
   carries only the **resulting modeling facts**, stated exactly as they would be had no
   loop occurred ("Company Openings for <banner> are 10-K overrides, store activity table
   FY<n>"). A resolved loop leaves no trace in the workbook. The loop never asks the user.

**Two cases this loop does not cover.** A *wrong value* upstream is the owner's own
pre-delivery checklist's job — a downstream stage has no independent evidence about an
upstream cell — and is never a finding. A customer roll-forward built on the *wrong
population* is caught by the software router before it dispatches the ARPU build
(`revenue/software/software.md`, Step 4), not downstream.

## Step 5 — Final QC and correction pass

After all five sections are built, run the **unit audit** defined in **Rule 6** of
`../_common/revelata-excel-units-and-scale.md` across the finished workbook. Run it **in
code**, not by reading the sheet: all of checks 1–5 are mechanically computable, and
a by-eye pass is how unit defects reach delivery in the first place.

This step runs **once, at the end**, because the checks that matter most are
cross-section: a sub-skill cannot see what display scale a sibling section chose.

### 5.1 — Run the audit

Run `scripts/audit.py` against the recalculated workbook, naming every stage file the
build ran (the files `BUILD_LOG.md` records, in build order):

```
python3 scripts/audit.py <workbook> --last-hist-col <letter of N> --stages <stage file> <stage file> …
```

It evaluates Rule 6 checks 1–5 over every row of the data region (Col E onward), for
every section, and prints the stored and displayed `Total Revenue` for check 6, which
needs one lookup against the cited filing. With `--stages` it also runs three checks
against the stage files' own row tables:

- **7 row presence** — every row a stage specifies with a `Lays when` that holds on this
  sheet (the vocabulary above) exists in that stage's section, and a required row whose
  historical cells are all dashes counts as missing unless its value is
  `ALWAYS_DASHES_OK`. The audit prints the stage list and the required set it derived,
  so an omitted stage file is visible in the output.
- **8 memo content** — every row whose label ends `(must = 0)` reads zero within
  rounding in every historical column, and every `(must ≈ 0)` row within half a
  percent of that column's `Total Revenue`.
- **9 margin reads** — `Gross margin` equals gross profit over revenue and
  `Operating margin` equals operating income over revenue in the last historical column.
- **10 vocabulary** — no Notes row and no cell comment contains a section number, a
  route, case, mode, tier, layout or approach name, a driver color, or skill vocabulary
  such as contract row, spine or hand-back (Build mechanics, "Three places"). Runs with
  or without `--stages`.
- **11 header rows** — a row with a label, no Col D tag and no value or formula in any
  period cell is a header: its period cells must be empty, never dashes, and its label
  bold and underlined (styling contract). A data row that is empty in a period shows a
  dash and carries a tag. Runs with or without `--stages`.

### 5.2 — Report findings before changing anything

Emit a findings table:

| Row | Col C label | Check | Observed | Expected |
|---|---|---|---|---|

If the audit is clean, say so explicitly — do not pass over it in silence.

### 5.3 — Correct, within scope

**Fix only:** missing or malformed Col D tags; wrong or missing number formats;
`General`-format cells in the data region; display scales inconsistent within a
family; and scale constants in formulas — fixed by correcting the **stored value**
per Rule 1 and then deleting the constant, never by adjusting the constant.

**Do not:** restructure rows, add or remove line items, change modeling drivers, or
revisit any routing or classification decision. If a finding cannot be corrected
without making a modeling judgment, leave it in place and surface it in 5.4.

A **row-presence** or **memo-content** finding (checks 7 and 8) is never corrected
here: it means a stage did not lay a row its own text specifies, or laid one that does
not foot. Re-run the owning stage from its file against the rows that now exist, as
Step 4.2 re-runs an owner, then re-run every later stage in build order and render
again. A stage that cannot lay the row returns `RE-ENTRY FAILURE` naming it and its
reason. The build does **not** stop: record the finding and the reason in
`BUILD_LOG.md`, carry both into the report (5.4) as an unresolved finding, and finish.
A reason of the form "my own text omits this row for this case" is a `Lays when`
defect in that file's row table — report it as a skill-text issue, not as a model
defect.

**Never edit a stored value to make a check pass.** A stored number that disagrees
with the filing is a data problem, not a formatting one — report it.

### 5.4 — Re-run, then report

Re-run the audit until checks 1–11 return zero findings, or only the findings recorded
as unresolved under 5.3. Then report to the user: what was corrected, any unresolved
finding with the owner's reason, and any judgment items needing their call — for example a bare
`(%)` whose denominator is not clear from its row label, or a family whose
conventional display scale is genuinely debatable.

## Notes

- **Derived cells must be live `=` formulas** wherever sub-skills compute values
  (margins, totals, imputed quarters) — never hardcoded results. This is enforced
  per section but the orchestrator should remind the user the model is built to
  recalc.
- If the user only wants **one** section (e.g. just a revenue build), you may
  skip the **workbook scaffolding** (Step 2) — but **still do Step 1 (resolve the
  company and classify its industry) and Step 3 (discover the full KPI inventory
  via `list_kpis`)** before routing. The KPI discovery always runs first so the single sub-skill receives
  the same shared KPI inventory; only the scaffold is skipped. Then route straight
  to that section's sub-skill, passing it the `company_id`, company name, and the
  shared inventory (or use the `kpi` skill for a raw pull).
- **Supported industries are restaurant, retail and software; there is no generic
  build.** Adding an industry means four things, all of them: a criterion in
  `industry-classification/`, a revenue build under `revenue/`, a cost build under
  `costs/`, and a net-working-capital driver map under `net-working-capital/`.
