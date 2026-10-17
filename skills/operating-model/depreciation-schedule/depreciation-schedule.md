---
name: depreciation-schedule
description: >
  Builds the DEPRECIATION SCHEDULE section of an operating-model workbook for a US
  public company. Invoked by the `operating-model` orchestrator AFTER the REVENUE
  section is built and BEFORE COSTS (the build order; on the sheet it sits fourth);
  receives the resolved `company_id`, official company name, workbook path (with
  REVENUE already laid down), and the shared KPI inventory. Like `consolidated-financials`,
  this skill performs the build itself — it does NOT route to a sub-skill, and it
  does NO industry routing (the depreciation schedule is identical for every
  industry). It lays down, beneath the `DEPRECIATION SCHEDULE` ALL-CAPS header, a
  `Depreciation Schedule` PP&E roll-forward (Net PP&E BOP → + Capital Expenditures →
  − Depreciation & Amortization → + Other → Net PP&E EOP) on top, then the three
  builds the roll-forward refers down to: a `Depreciation` build (the issuer's PP&E
  component table — land, buildings, furniture, equipment, construction in progress,
  … → Gross PP&E → Accumulated Depreciation → Net PP&E, plus Implied Useful Life =
  Net PP&E ÷ D&A, and Depreciation & Amortization pulled from the statement of cash
  flows), a `Capital Expenditures` build (capex from the cash-flow statement + as %
  of revenue), and an `Other` build (the roll-forward plug = Net PP&E EOP − Net PP&E
  BOP − Capex + D&A, + as % of revenue). PP&E components / accumulated depreciation /
  net PP&E are deepKPI balance-sheet inputs; D&A and capex are deepKPI cash-flow
  inputs; every roll-forward link, ratio, and total is a live `=` formula. Its
  `Depreciation & Amortization` row is the model's single D&A source — the contract
  row CONSOLIDATED FINANCIALS and the cost build's total-D&A line reference; this
  skill writes into no other section. Pulls specific series via `search_kpis`
  against the shared inventory (never re-runs `list_kpis`). Format per
  ../../_common/revelata-excel-styling-rules.md.
---

# depreciation-schedule (PP&E roll-forward builder)

This sub-skill is part of the `operating-model` system and owns the **DEPRECIATION
SCHEDULE** section. **It is a builder, not a router** — like
`consolidated-financials`, it writes the workbook itself. **There is no industry
routing here.** The depreciation schedule is **standard for every industry**
(restaurant, retail, software, industrial — all the same), so this file performs
the same build regardless of how the company was classified upstream. Do **not**
read `get_company_summary`, do **not** branch on industry, and do **not** create
industry sub-folders; just build the schedule.

The section has **four blocks**, laid top-to-bottom beneath the
`DEPRECIATION SCHEDULE` ALL-CAPS header:

1. a **`Depreciation Schedule`** roll-forward table (the consolidated walkdown), on
   top, whose lines **refer down** to the three builds below it;
2. a **`Depreciation`** build (the issuer's PP&E component table + Implied Useful
   Life + cash-flow D&A);
3. a **`Capital Expenditures`** build; and
4. an **`Other`** build (the roll-forward plug).

The Depreciation build's `Depreciation & Amortization` row is the model's single
D&A source (§6): CONSOLIDATED FINANCIALS and the cost build's total-D&A line, both
built after this section, reference it. This section writes into no other section.

## Prerequisite — REVENUE must be built first; this section is built before COSTS

This build runs **after the REVENUE section is fully laid down and before COSTS**
(orchestrator Step 4, item 2). It depends on one upstream section and is depended
on by two downstream ones:

1. **REVENUE is finished** — its `Total Revenue` row exists. The capex and Other
   builds express figures **as a % of revenue** and reference that row.
2. **COSTS and CONSOLIDATED FINANCIALS are built after this section and reference
   it.** The cost build's total-D&A line references this schedule's forward D&A, and
   the consolidated section's `Total Depreciation & Amortization` references this
   schedule's `Depreciation & Amortization` in every column (§6). Neither exists
   yet when this build runs, and this build writes nothing into them.

The build order differs from the sheet order on purpose: on the sheet this section
still sits fourth, beneath CONSOLIDATED FINANCIALS. The renderer places it there
whenever it is built (`../SKILL.md`, "Build mechanics").

If the orchestrator routed here before REVENUE completed, **stop** and return
control — do not build the depreciation schedule out of order.

**Inputs expected from the orchestrator:** resolved `company_id`, official company
name, the path to the workbook (with REVENUE already built), and the **shared KPI
inventory**.

**Data source:** deepKPI only — see `../../_common/data-source-rules.md`. On failure,
follow `../../_common/connection-failure.md`. Do **not** re-run `list_kpis`; pull the
specific PP&E, capex, and D&A series with `search_kpis` against the shared
inventory. The **only** filing read permitted is the optional 10-K fallback in §1.3
(used solely when deepKPI lacks the granular PP&E component breakdown).

**Formatting:** follow `../../_common/revelata-excel-styling-rules.md` and build with
the **xlsx** skill. All conventions there apply — one row per distinct series,
deepKPI-sourced values as pale-green hyperlinked input cells, and
**every** total / ratio / roll-forward / plug cell as a live `=` formula (never a
hardcoded number) — **except** the time scope and column layout, which this build
**matches to the upstream sections** (next section).

**Number format and units:** storage, the number-format strings, and the tag grammar
come from `../../_common/revelata-excel-units-and-scale.md`, and every row's family
follows from that file's Rule 4 — an input row's from its deepKPI `unit` field, a
derived row's from the dimensions of its formula. **The Col D tag for every row this
build writes is shown in the row map of its own section** — §2, §3, §4 and §5 — and in
the `Units (Col D)` column of that section's formula table; the index under "The target
layout" explains how to read the row-map annotations. Every money row — the PP&E
components and totals, D&A, capex, the plug and the roll-forward — shows the placeholder
`(USD in <scale>)`: the contract's Rule 2 supplies the scale, millions by default,
thousands where the digit test puts a small filer. This build has no per-unit rows and
makes no scale decision of its own; three classifications need stating:

- **`Implied Useful Life` → `(years)`, not a percent.** It divides a balance-sheet
  **stock** (`Plant, Property, and Equipment Net`) by an **annual flow** (`Depreciation
  & Amortization`), and a stock over a per-period flow is a span of time in that
  period's unit — years, in this annual model. Display it as a plain number with one
  decimal (`5.5`), never as a percentage and never as currency.
- Both `as % of revenue` rows (§3 and §5) are tagged `(% of total revenue)` — identical
  labels in two blocks, told apart by their block; both are italic label + italic data.
- The two tie-out memos (`Memo: Net PP&E − reported (must = 0)` in §2 and `Memo: BOP +
  Capex − D&A + Other − EOP (must = 0)` in §4) are differences of money rows and take
  the money family's tag.

## Time scope and columns (match the upstream build — overrides the common styling rules)

This rule **overrides** the corresponding conventions in
`../../_common/revelata-excel-styling-rules.md`:

- **Use the exact period columns the REVENUE section already used.** Every line here must sit in the **same columns** as the
  rows it references, so each reference lines up. In practice the restaurant builds
  use the **four most recent fiscal years**, annual columns only; mirror exactly
  whatever timeline is already on the sheet. Do **not** introduce a different
  timeline and do **not** add periods the upstream builds did not lay down. If the
  upstream sections carried a quarterly block, mirror it (annual block, blank
  separator, quarterly block). (The full intended horizon is the canonical **Model
  timeline** in the orchestrator `../SKILL.md` — the four historical fiscal years
  plus the five projection years, `N+1 … N+5`, after the last historical year; this
  section mirrors whatever portion of that timeline the upstream builds have laid
  down.)
- **Flow vs. stock (only matters if a quarterly block exists).** PP&E **component
  balances, accumulated depreciation, and net PP&E are STOCKS** — use the
  period-end value directly in
  each column (never impute Q4 by subtraction). **Capital expenditures and
  Depreciation & Amortization are FLOWS** — if a quarterly block exists, impute a
  missing quarter as `Q4 = FY − Q1 − Q2 − Q3` **in that series' row**, as a live
  formula. With the default annual-only timeline this distinction is moot, but state
  it if you build quarterlies.

> This build is authored section by section. The sections present here — §1 the
> data identification / pull, §2 the Depreciation build, §3 the Capital
> Expenditures build, §4 the Depreciation Schedule roll-forward table, §5 the Other
> build, §6 the D&A contract row downstream sections reference, §7 quality checks, §8 a worked example,
> §9 the projection layer (forward fiscal years `N+1 … N+5`), and §10 the downstream
> handoff — are the implemented scope. Do **not** build or add
> anything outside these sections (no impairment schedules, no asset-by-asset
> depreciation lives, no separate amortization-of-intangibles block unless it is
> already a line in the issuer's PP&E / cash-flow disclosure).

---

## Sign conventions (state once, apply everywhere)

Fix these signs before writing a single cell, and state them in one Notes line, in
the analyst's words: "Depreciation Schedule: accumulated depreciation is carried
<positive and subtracted / negative and added>; D&A and capex are carried as positive
amounts." Getting them consistent is what makes the roll-forward foot and
the EBITDA add-back (§6) correct.

| Quantity | Sign carried in the sheet | Note |
|---|---|---|
| `Net PP&E BOP` | **positive** | opening balance |
| `Capital Expenditures` | **positive** | additions **increase** PP&E. The cash-flow statement reports each counted line ("Purchases of property and equipment", "Capitalized software", …) as a **negative** outflow; carry each **magnitude as positive** here. |
| `Depreciation & Amortization` | **positive** | the cash-flow add-back magnitude. It **reduces** PP&E, so the roll-forward **subtracts** it. |
| `Other` | **signed** (plug; usually small, either sign) | the residual that makes the walk foot — see §5. |
| `Net PP&E EOP` | **positive** | closing balance |
| `Accumulated Depreciation` | per the issuer's presentation | if pulled as a **positive** magnitude, Net PP&E = Gross **−** Accum Dep; if pulled **negative**, Net PP&E = Gross **+** Accum Dep. Pick one and be consistent. |

**The roll-forward identity (the foot):**

```
  Net PP&E EOP = Net PP&E BOP + Capital Expenditures − Depreciation & Amortization + Other
```

`Net PP&E EOP` is a **direct reference** to the Depreciation build's `Net PP&E`
(the reported balance-sheet stock), **not** a column sum — so there is **no
circular reference** with the `Other` plug. `Other` is defined as the residual that
balances the identity (§5), so the walk foots **by construction**; §7 verifies it
with a memo that must be 0.

---

## The target layout

The sheet shape beneath the `DEPRECIATION SCHEDULE` ALL-CAPS header the scaffold already
placed. Blank lines are the one-row spacers between blocks. The roll-forward table sits
on top but is built **after** the two builds it refers down to — §2 and §3 first, then
§4, then §5 (which wires the roll-forward's `Other` row). Each block's rows, Col D tags,
formatting and formulas are specified **once, in its own section** — build from there.

```
DEPRECIATION SCHEDULE                         ← ALL-CAPS section header, already in the scaffold

  Depreciation Schedule                       ← block sub-header · rows in §4 — built AFTER §2 and §3
    [roll-forward rows — §4]

  Depreciation                                ← block sub-header · rows in §2
    [PP&E component table — §2]

  Capital Expenditures                        ← block sub-header · rows in §3
    [capex and its % of revenue — §3]

  Other                                       ← block sub-header · rows in §5
    [the roll-forward plug and its % of revenue — §5]
```

**Reading the layout above, the row maps in §2–§5 and the §8 example.** Each row's
annotation has two columns, left to right: the **Col D units tag in parentheses** —
`(USD in <scale>)` means the contract's Rule 2 sets the money scale; every other tag is
written as it goes in the cell — and the note in **square brackets**: `[deepKPI INPUT
…]` for a pulled value, `[FORMULA = …]` for a computed row, plus any styling (`SUM-BAR`,
`italic`). Block sub-headers carry no tag.

The PP&E component rows in §2 (`<each PP&E component — issuer's lines>`) are
**placeholders** — use the **issuer's exact PP&E line items**, in the issuer's order
and wording (§1.2); the `Land`, `Buildings`, … rows in the §8 example are one
issuer's. A company may report three components or a dozen.

**Header hierarchy (match the upstream sections).** Only the ALL-CAPS
`DEPRECIATION SCHEDULE` header keeps the big-header look (**bold, underlined, size
16**). The four block sub-headers — `Depreciation Schedule`, `Depreciation`,
`Capital Expenditures`, `Other` — are **bold, size 12, underlined, and indented
once** — the sub-header treatment the styling contract gives every section. Do **not** set them to size
16 (keep them size 12, not the big ALL-CAPS-header look).

**Build order vs. layout order.** The roll-forward table is on **top**, but its
cells **reference the builds below it**, and the `Other` build in turn references
the roll-forward table. So lay the labels top-to-bottom, but **wire the references
in dependency order**: build §2 (Depreciation) and §3 (Capital Expenditures) first,
then fill the roll-forward table's BOP / Capex / D&A / EOP cells (§4), then build
§5 (Other) and finally wire the roll-forward `Other` row to it. This ordering keeps
the dependency graph **acyclic** (see §5.3).

---

## Section 1 — Identify and pull the deepKPI series (no workbook writing yet)

This first section writes nothing. It maps each line of the four blocks to a
deepKPI series and pulls it with `search_kpis` against the **shared inventory**
(never `list_kpis`). Pull **annual** (`- Annual`) series across the build window;
add the matching `- 3 Month` quarterly series only if the upstream timeline carried
a quarterly block.

### 1.1 — Where each series lives in the shared inventory

| Block line(s) | Category in the shared inventory | Typical KPI wording | Type |
|---|---|---|---|
| PP&E components (Land, Buildings, Leasehold improvements, Furniture & fixtures, Equipment, Construction in progress, …) | `Consolidated Balance Sheet` (PP&E footnote / supplemental); some issuers under `Miscellaneous` | `Land`, `Buildings`, `Leasehold improvements`, `Furniture, fixtures and equipment`, `Construction in progress` | **stock** |
| Accumulated Depreciation | `Consolidated Balance Sheet` | `Accumulated depreciation`, `Less: accumulated depreciation and amortization` | **stock** |
| Net PP&E | `Consolidated Balance Sheet` | `Property and equipment, net`, `Net property and equipment` | **stock** |
| Depreciation & Amortization | `Consolidated Cash Flow` | `Depreciation and amortization` (the cash-flow add-back) | **flow** |
| Capital Expenditures | `Consolidated Cash Flow` | the cash-flow lines the issuer counts in its capital expenditures (the definition rule below), for example `Purchases of property and equipment`, `Capitalized software`, `Principal payments on finance leases`, `Capital expenditures`, `Additions to property and equipment` | **flow** |

- **Capital expenditures are what the issuer's 10-K calls capital expenditures.**
  Read the definition from the filing already pulled, in two places: the MD&A
  liquidity paragraph that states the year's capital expenditures (*"capital
  expenditures were $740 million"*) and the outlook sentence that states the basis
  guidance is on (*"approximately $800 million"*, *"including principal payments on
  finance leases"*). Then take the component lines from the statement of cash flows:
  every line the issuer counts, wherever it sits (an investing line such as
  `Purchases of property and equipment` or `Capitalized software`; a financing line
  such as `Principal payments on finance leases` when the issuer's definition
  includes it), each gross, with an offset the issuer nets against them (landlord
  allowances, proceeds) as its own signed line. **The components summed must equal
  the figure the MD&A states for year `N`**; record the lines counted and the
  tie-out in `BUILD_LOG.md`. Only when the filing states no capital-expenditures
  figure is the row `Purchases of property and equipment` alone, and the Notes say
  so. The inventory's own capital-expenditures series, where one exists, is a
  cross-check on the sum, never the source of the definition. A non-cash addition
  the issuer does not count (finance-lease right-of-use assets recognized without
  cash) stays in the `Other` plug and is named in its Notes line (§5.1).
- **Keyword to anchor on for the component table:** *"property and equipment"* /
  *"net property and equipment"*. The issuer discloses a table — components, then
  `Less: accumulated depreciation`, then `Property and equipment, net` — in the PP&E
  footnote or on the face of the balance sheet. **Copy that table** into the
  `Depreciation` block, line for line.
- **D&A source (important):** pull D&A from the **statement of cash flows**, not the
  income statement. This cash-flow D&A **may differ from the D&A carried in the
  COSTS build** — that is expected and fine. This cash-flow figure is what drives
  Implied Useful Life **and** is the row CONSOLIDATED FINANCIALS and the cost build's
  total-D&A line reference (§6).
- **Capex sign:** if the cash-flow series comes back negative (an outflow), carry
  its **magnitude as positive** per the sign conventions.

### 1.2 — Use the issuer's exact component lines

The component set is **issuer-specific** — do not assume a generic list. Read the
issuer's PP&E table and reproduce **its** lines, labels, and order (e.g. a
restaurant may report `Land`, `Buildings and leasehold improvements`,
`Furniture, fixtures and equipment`, `Construction in progress`; an industrial
issuer may split `Machinery and equipment`, `Land and improvements`, `Buildings`,
etc.). Whatever the issuer lists between the top of the PP&E table and
`Less: accumulated depreciation` are the component rows.

### 1.3 — Fallback if deepKPI lacks the granular component breakdown

If `search_kpis` returns `Net property and equipment` and the cash-flow D&A / capex
but **not** the per-component breakdown (Land / Buildings / …), then — and only then
— read the 10-K PP&E footnote: call `list_sec_filing_markdowns` (free) then
`get_sec_filing_markdown` for the latest 10-K, take the component table, enter those
component cells as **gold-fill** override inputs (hyperlinked to that filing, with a
cell comment noting the source), and record it in the Notes block: "Depreciation
Schedule: the PP&E components are taken from the 10-K property note; the database
carries no component split." This mirrors the cost build's data-quality fallback.
If even the footnote does not split PP&E, build the `Depreciation` block with just
`Net property and equipment` (reported input), `Accumulated Depreciation` if
available, and the cash-flow `Depreciation & Amortization`, and record the missing
detail in the Notes block: "Depreciation Schedule: the filing gives no PP&E component
split; the block carries net PP&E, accumulated depreciation and D&A only." Never
invent component values.

Record in `BUILD_LOG.md`, in one line each, the KPI series you matched for
components, accumulated depreciation, net PP&E, D&A, and capex (citing the inventory
category), before writing — so the sourcing is auditable.

---

## Section 2 — The Depreciation build

Lay this block second on the sheet (beneath the roll-forward table's labels). It is
the **source of truth** for Net PP&E EOP and D&A that the roll-forward refers down
to.

```
  Depreciation                                                                   [bold sub-header, size 12, underlined]
    <each PP&E component — issuer's lines>            (USD in <scale>)           [deepKPI INPUT — balance-sheet stock]
    Plant, Property, and Equipment Gross              (USD in <scale>)           [FORMULA = SUM(components above); bold, SUM-BAR]
    Accumulated Depreciation                          (USD in <scale>)           [deepKPI INPUT — balance-sheet stock]
    Plant, Property, and Equipment Net                (USD in <scale>)           [FORMULA = Gross − Accumulated Depreciation; bold, SUM-BAR]
    Plant, Property, and Equipment Net (reported)     (USD in <scale>)           [deepKPI INPUT — the reported net line; only when deepKPI reports Net PP&E directly — §2.2]
    Memo: Net PP&E − reported (must = 0)              (USD in <scale>)           [FORMULA = Net − Plant, Property, and Equipment Net (reported); italic; laid with the input row above — §2.2]
    Implied Useful Life                               (years)                    [FORMULA = Net PP&E ÷ D&A]
    Depreciation & Amortization                       (USD in <scale>)           [deepKPI INPUT — statement of cash flows]
```

### 2.1 — The formulas (cell-by-cell) for the Depreciation build

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `<each PP&E component>` | | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked balance-sheet value) | *(no comment on input rows — provenance is the hyperlink)* |
| `Plant, Property, and Equipment Gross` | | `(USD in <scale>)` | `= SUM(` the component rows above `)` | `"Σ of the reported PP&E components (gross, before accumulated depreciation)."` |
| `Accumulated Depreciation` | | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked) | `"Reported accumulated depreciation. Sign convention: <positive→subtracted / negative→added> (state which)."` |
| `Plant, Property, and Equipment Net` | | `(USD in <scale>)` | `= <Gross, this col> − <Accumulated Depreciation, this col>` (flip the operator if Accum Dep is carried negative) | `"Gross PP&E less accumulated depreciation. Ties to the reported Net PP&E (memo check)."` |
| `Plant, Property, and Equipment Net (reported)` *(only when deepKPI reports Net PP&E directly — §2.2)* | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked): the reported net line, a visible row because the memo below reads it | *(no comment on input rows — provenance is the hyperlink)* |
| `Memo: Net PP&E − reported (must = 0)` *(italic; only when deepKPI reports Net PP&E directly — §2.2)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <Plant, Property, and Equipment Net, this col> − <Plant, Property, and Equipment Net (reported), this col>` | `"Tie-out: modeled Net PP&E less reported; must be 0 every period."` |
| `Implied Useful Life` | | `(years)` | `= <Plant, Property, and Equipment Net, this col> ÷ <Depreciation & Amortization, this col>` | `"Implied useful life (years) = Net PP&E ÷ cash-flow D&A. The depreciation driver."` |
| `Depreciation & Amortization` | | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked **cash-flow** D&A) | `"D&A from the statement of cash flows. May differ from the D&A line inside the COSTS block — expected. Drives Implied Useful Life; referenced by the roll-forward, by CONSOLIDATED FINANCIALS (Total Depreciation & Amortization, every column) and by the cost build's total-D&A line (projection columns)."` |

- **`Plant, Property, and Equipment Gross`** and **`Plant, Property, and Equipment
  Net`** each carry the **SUM-BAR** styling (bold, a single thin top
  border across the data columns). `Gross` is a live `SUM`; `Net` is a live subtraction
  — never hardcoded.
- **`Implied Useful Life`** is the **depreciation driver**: in any **projected** period
  the model sets `D&A = prior-year Net PP&E ÷ Implied Useful Life`, with the forward
  life seeded and held exactly as §9.1 defines (the same driver methodology every
  section uses). Build it as the live ratio for **every historical period**; do not
  fabricate projected columns the upstream sections did not lay down. Format it as a
  plain number (years), not a currency.
- **`Depreciation & Amortization`** is the **cash-flow** D&A input — the single most
  important cell in this section, since CONSOLIDATED FINANCIALS and the cost build
  reference it (§6).

### 2.2 — Net PP&E cross-check

If deepKPI reports `Property and equipment, net` directly (it usually does), lay it as
a visible input row `Plant, Property, and Equipment Net (reported)` directly beneath
the modeled `Net`, and beneath that an italic memo row `Memo: Net PP&E − reported
(must = 0)` = `<Plant, Property, and Equipment Net> − <Plant, Property, and Equipment
Net (reported)>`; it must be **0** every period. The input is a row, never a hidden
cell or a memo: a formula reads it, and its provenance hyperlink is the audit trail. A non-zero
value means a missing component, an accumulated-depreciation sign error, or a series
that was not converted to base units on ingest (Rule 1 of the units contract) — fix it,
do not plug it. (When the component breakdown came from the 10-K fallback (§1.3), this
check is the proof the copied table foots to the reported net.)

---

## Section 3 — The Capital Expenditures build

Lay this block third. It is short — the capex input and its ratio to revenue.

```
  Capital Expenditures                                                           [bold sub-header, size 12, underlined]
    <Component line 1>                                (USD in <scale>)           [deepKPI INPUT; ONLY when the issuer's capital expenditures span more than one cash-flow line — one row per counted line, the issuer's caption, positive magnitude; history only]
    <Component line 2>                                (USD in <scale>)           [deepKPI INPUT; same condition]
    Capital Expenditures                              (USD in <scale>)           [deepKPI INPUT where the issuer's figure is one cash-flow line; FORMULA = SUM(component rows) where it spans more than one; positive magnitude]
    as % of revenue                                   (% of total revenue)       [FORMULA = Capital Expenditures ÷ Total Revenue; italic]
    Guidance: Capital Expenditures                    (USD in <scale>)           [ONLY when the guidance table carries capital expenditures for N+1: red hyperlinked INPUT in the N+1 column, dash elsewhere — §9.2]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Guidance: Capital Expenditures` | DATA_DEPENDENT | `(USD in <scale>)` | laid only when the orchestrator's guidance table gives capital expenditures for `N+1`: the midpoint as a red constant in the `N+1` column, hyperlinked to the exhibit, written per cell with `drv(value, note, url)`; a dash in every other column | `"Issuer guidance for FY<N+1>: <verbatim>. Midpoint of <low> to <high>. <basis>."` |
| `<Component line>` *(the issuer's cash-flow caption, one row per counted line)* | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked; carried **positive**) in the historical columns; a **dash** in every projection column — the forward figure is carried only at the total | `"<Caption> from the statement of cash flows; one of the lines the issuer counts in its capital expenditures (§1.1). Outflow carried positive."` |
| `Capital Expenditures` | | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked; carried **positive**) where the issuer's capital expenditures are one cash-flow line; `= SUM(<component rows>, this col)` where they span more than one | `"Capital expenditures as the issuer defines them (<the lines counted>), from the statement of cash flows; ties to the MD&A figure. Outflow carried positive — capex increases PP&E."` |
| `as % of revenue` | | `(% of total revenue)` | `= <Capital Expenditures, this col> ÷ <Total Revenue, this col>` | `"Capex ÷ total revenue. References the REVENUE build's Total Revenue, not re-entered."` |

- The component rows exist only when the issuer's figure spans more than one
  cash-flow line (§1.1): Macy's purchases of property and equipment plus capitalized
  software; Meta's purchases plus principal payments on finance leases. They are
  history only; the forward `Capital Expenditures` is one driver-derived total (§9.2)
  and the component rows are dashes there.

- `as % of revenue` is a **live formula** referencing the **REVENUE build's
  `Total Revenue`** row (black formula; the % uses the accounting percent format,
  italic, per the styling rules). Never re-enter a revenue figure here.
- This `Capital Expenditures` input is what the roll-forward's `Capital
  Expenditures` line **refers down to** (§4).

---

## Section 4 — The Depreciation Schedule roll-forward table

This is the **table on top** (the user's *"consolidated table titled 'Depreciation
Schedule'"*), laid directly beneath the `DEPRECIATION SCHEDULE` ALL-CAPS header. Its
cells **refer down** to the builds (§2, §3, §5). Wire BOP / Capex / D&A / EOP now;
wire `Other` after §5 is built.

```
  Depreciation Schedule                                                          [bold sub-header, size 12, underlined]
    Net Property and Equipment, BOP                   (USD in <scale>)           [FORMULA = prior period's EOP; first historical year is blank]
    Capital Expenditures                              (USD in <scale>)           [FORMULA = ref to the Capital Expenditures build]
    Depreciation & Amortization                       (USD in <scale>)           [FORMULA = ref to the Depreciation build's D&A]
    Other                                             (USD in <scale>)           [FORMULA = ref to the Other build; wired in §5]
    Net Property and Equipment, EOP                   (USD in <scale>)           [FORMULA = ref to the Depreciation build's Net PP&E; SUM-BAR]
    Memo: BOP + Capex − D&A + Other − EOP (must = 0)  (USD in <scale>)           [FORMULA; italic; 0 by construction since Other is the plug — §7]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Net Property and Equipment, BOP` | | `(USD in <scale>)` | **first** period column: **blank / dash** (no prior year). Every **later** column: `= <Net Property and Equipment, EOP, the immediately prior period column>` | `"Opening net PP&E = prior period's closing net PP&E. Blank in the first historical year (no prior period)."` |
| `Capital Expenditures` | | `(USD in <scale>)` | `= <Capital Expenditures build → Capital Expenditures, this col>` | `"Refers down to the Capital Expenditures build."` |
| `Depreciation & Amortization` | | `(USD in <scale>)` | `= <Depreciation build → Depreciation & Amortization, this col>` | `"Refers down to the cash-flow D&A in the Depreciation build. Subtracted in the roll-forward."` |
| `Other` | | `(USD in <scale>)` | `= <Other build → Other, this col>` (wire after §5) | `"Refers down to the Other build (the roll-forward plug)."` |
| `Net Property and Equipment, EOP` | | `(USD in <scale>)` | `= <Depreciation build → Plant, Property, and Equipment Net, this col>` | `"Closing net PP&E = reported Net PP&E from the Depreciation build. Closes the walk; foots by construction because Other is the plug."` |
| `Memo: BOP + Capex − D&A + Other − EOP (must = 0)` *(italic)* | | `(USD in <scale>)` | `= <BOP> + <Capital Expenditures> − <Depreciation & Amortization> + <Other> − <EOP>`, all this col  — a dash in the first historical column, where BOP and Other are dashes| `"Foot check: 0 by construction because Other is the plug; a non-zero value reveals a broken reference or a sign slip."` |

- **`Net Property and Equipment, BOP`** is **blank** in the first historical column
  (dash) and a **reference to the prior column's EOP** in every later column — a
  live formula, never re-keyed.
- **`Net Property and Equipment, EOP`** is a **direct reference** to the Depreciation
  build's `Plant, Property, and Equipment Net` (the balance-sheet stock), styled as
  a **SUM-BAR** (bold, top border). It is **not** a column sum
  — keeping it a reference (with `Other` as the plug) is what prevents a circular
  reference.
- The roll-forward reads `EOP = BOP + Capex − D&A + Other`. Carry D&A as positive
  and **subtract** it (sign conventions). Because `Other` (§5) is the residual that
  balances this identity, the implied walk equals the referenced EOP exactly — §7
  proves it with a memo = 0.

---

## Section 5 — The Other build (the roll-forward plug)

Lay this block last on the sheet. `Other` is the **plug** that makes the
roll-forward foot for the historical years; it captures everything that moved Net
PP&E other than capex and D&A (e.g. disposals, impairments, FX on PP&E,
acquisitions / divestitures, reclassifications).

```
  Other                                                                          [bold sub-header, size 12, underlined]
    Other                                             (USD in <scale>)           [FORMULA = EOP − BOP − Capex + D&A, from the roll-forward table; a dash in the first historical column — the base year has no walk]
    as % of revenue                                   (% of total revenue)       [FORMULA = Other ÷ Total Revenue; italic]
```

### 5.1 — The formulas (cell-by-cell) for the Other build

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Other` | | `(USD in <scale>)` | `= <Net Property and Equipment, EOP> − <Net Property and Equipment, BOP> − <Capital Expenditures> + <Depreciation & Amortization>`; in the **first** historical column a **dash** — the base year has no opening balance and no walk — **all four referencing the roll-forward table's rows, this column** | `"Roll-forward plug = EOP − BOP − Capex + D&A. Balances the PP&E walk for historical years (disposals, impairments, FX, M&A, reclasses)."` |
| `as % of revenue` | | `(% of total revenue)` | `= <Other, this col> ÷ <Total Revenue, this col>`; a dash in the first historical column, like `Other` | `"Other ÷ total revenue. References the REVENUE build's Total Revenue."` |

Whenever the forward driver carries the plug (every build does, as a % of revenue),
the Notes block states **what the historical plug contains**, read from the filing
and the inventory: any capital-expenditure component the issuer counts that the
balance sheet carries outside PP&E (capitalized software in other assets) or that is
not an addition to PP&E (principal payments on finance leases), which the plug nets
against its amortization or its lease accounting; finance-lease or other non-cash
additions the issuer does not count; amortization of intangibles inside cash-flow
D&A; disposals, impairments, FX, acquisitions. A plug of a few percent of revenue is
a modeling fact a reader needs before deriving free cash flow from the schedule. If
the cause cannot be named from the filing and the inventory, the Notes line says so.

### 5.2 — Then wire the roll-forward's `Other` row

Once the `Other` build's `Other` row exists, set the **roll-forward table's `Other`
line** to `= <Other build → Other, this col>` (the row §4 left blank). The
roll-forward now reads top to bottom and foots.

### 5.3 — Why there is no circular reference

The dependency chain is **acyclic**:

```
  Depreciation build (Net PP&E, D&A) ─┐
  Capital Expenditures build (Capex) ─┤
                                      ▼
  roll-forward:  BOP (= prior EOP) · Capex · D&A · EOP   ── none depend on Other
                                      ▼
  Other build:   Other = EOP − BOP − Capex + D&A         ── depends only on the four above
                                      ▼
  roll-forward:  Other (= ref to Other build)            ── the ONLY roll-forward cell that depends on Other
```

`Net PP&E EOP` is a reference to the balance-sheet stock (not a sum of the column),
so it does **not** depend on `Other`; `Other` depends on EOP / BOP / Capex / D&A;
and the roll-forward's `Other` row is the single cell closing the loop — but it only
**reads** the Other build, nothing reads back. No cycle. If a tool flags a circular
reference, you made `Net PP&E EOP` a column `SUM` instead of a reference — fix that.

---

## Section 6 — The D&A contract row (what downstream sections reference)

This schedule's `Depreciation & Amortization` row (the Depreciation build, §2) is the
model's **single D&A source** — a contract row (`../SKILL.md`, "Contract rows").
Two downstream sections reference it; this section writes into neither.

### 6.1 — Who references the row

- **CONSOLIDATED FINANCIALS** — its `Total Depreciation & Amortization` row is
  `= <this row, same column>` in **every** column, historical and projected
  (`consolidated-financials` §6), plus the component amortization lines the cost
  build carries outside this figure. Its `Total EBITDA` is `Total Operating Income +
  Total Depreciation & Amortization`, so EBITDA adds back the cash-flow D&A and
  every amortization caption the issuer expenses beside it.
- **COSTS** — the cost build's **total-D&A line**, where it has one, keeps its reported
  deepKPI input in the historical columns and references this row's forward D&A in
  the projection columns (`costs` §9.3; §8.3 for software).

Because rows are referenced by key and the workbook is rendered whole
(`../SKILL.md`, "Build mechanics"), nothing depends on this row's address, and there
is no re-pointing step: each reference is written by the section that owns it, when
that section is built.

### 6.2 — Which cost lines point here (the partial-D&A-line rule)

Only a cost line that is the issuer's **total** D&A references this schedule. The
test is historical: the face line equals this schedule's cash-flow `Depreciation &
Amortization` in every historical column, within rounding. A line that fails the
test is a **component** of D&A, or reports something the cash-flow figure excludes —
`Amortization of acquired intangibles`, `Amortization of cloud computing
arrangements`, a `Depreciation` line beside a separate amortization line — and the
cost build projects it on its own basis (held flat at its year-`N` value as a red
driver, per the cost build's rule), never as a reference to this schedule, whose
forward D&A rolls off the PP&E base and is not a forecast of such a line. Lines that
**together** equal this schedule's figure in every historical column (a `Depreciation`
line beside an `Amortization` line that sum to cash-flow D&A) are its parts, not
components outside it; the cost build lists only the lines outside the figure, and the
consolidated section adds those to its total D&A (`consolidated-financials.md` §6).

Two consequences:

- When the cost block carries **no** D&A line at all (D&A embedded in cost of sales
  and SG&A, as many retailers present it), nothing in COSTS references this row and
  nothing needs to; CONSOLIDATED FINANCIALS still has its D&A source. Do **not**
  create a D&A line inside the cost block for the schedule's sake — it would
  double-count against the lines that already carry the expense.
- When the cost block carries only component lines, the forward sum of those lines
  and this schedule's forward D&A differ. That is the cash-flow-D&A versus
  income-statement-D&A gap the historical columns already show; it is expected, and
  it is noted, not reconciled.

### 6.3 — Sign

This row is a **positive** magnitude (the roll-forward subtracts it in §4).
CONSOLIDATED FINANCIALS adds it back, so **EBITDA ≥ EBIT** every period; if a
recalculated workbook shows EBITDA below EBIT, the sign of this row or of the EBITDA
formula is wrong — fix the formula, never the stored input.

---

## Section 7 — Quality checks and the foot

Verify with **live formulas in the workbook** (not by eye) before declaring done:

- **PP&E gross foots.** `Plant, Property, and Equipment Gross = SUM(components)`,
  every period (live `SUM`, not hardcoded).
- **Net PP&E ties to reported.** `Memo: Net PP&E − reported = 0` every period (§2.2),
  when a reported Net PP&E series exists.
- **Roll-forward foots.** Add `Memo: BOP + Capex − D&A + Other − EOP (must = 0)` in
  the roll-forward block; it must be **0** every period (proves the BOP / Capex / D&A
  / Other references and signs are wired correctly; it is 0 by construction because
  `Other` is the plug — a non-zero value reveals a broken reference or a sign slip).
  In the **first** historical year there is no walk: BOP, `Other`, its `as % of
  revenue` and this memo are all dashes. A guard that treats the missing BOP as zero
  would print an `Other` equal to the whole closing balance, which reads as a plug and
  means nothing; the dash is the honest cell.
- **Implied Useful Life is sane.** `Net PP&E ÷ D&A` lands in a plausible range
  (single-digit to low-double-digit years for most operators); cross-check it against
  the depreciation-policy useful lives disclosed in the 10-K's property-and-equipment
  note. A wildly off value flags a series that was not
  converted to base units on ingest (Rule 1 of
  `../../_common/revelata-excel-units-and-scale.md` — fix the stored value, never the
  formula) or a wrong D&A series.
- **Capex / Other % rows reference revenue.** Both `as % of revenue` rows divide by the
  **REVENUE build's `Total Revenue`** (live reference), not a re-keyed number.
- **The D&A contract row is stable and positive.** `Depreciation & Amortization` in the
  Depreciation build keeps that exact label, carries positive values, and is the only
  D&A row downstream sections reference (§6); this build wrote into no other section.
- **No hardcodes; recalc clean.** Every total / ratio / roll-forward / plug cell is a
  live formula; only deepKPI-sourced inputs (components, accumulated depreciation, net
  PP&E, cash-flow D&A, cash-flow capex) are literal values, each green and hyperlinked.
  Recalculate the workbook (LibreOffice / the xlsx skill's `recalc.py`) and confirm
  **zero formula errors** and that every memo above is 0.

---

## Section 8 — Worked example (illustrative)

A single fiscal year, USD in millions; figures illustrative — the real build references
the cells and pulls every input from deepKPI.

```
  Depreciation
  Land                                           420  (USD in millions)     [input]
  Buildings and leasehold improvements         2,650  (USD in millions)     [input]
  Furniture, fixtures and equipment            1,900  (USD in millions)     [input]
  Construction in progress                       180  (USD in millions)     [input]
  Plant, Property, and Equipment Gross         5,150  (USD in millions)     [= SUM(components) ← sum bar]
  Accumulated Depreciation                   (2,950)  (USD in millions)     [input; carried negative]
  Plant, Property, and Equipment Net           2,200  (USD in millions)     [= Gross + Accum Dep ← sum bar]
  Implied Useful Life                            5.5  (years)               [= 2,200 ÷ 400]
  Depreciation & Amortization                    400  (USD in millions)     [input — statement of cash flows]

  Capital Expenditures
  Capital Expenditures                           480  (USD in millions)     [input — cash flows, magnitude]
  as % of revenue                               4.4%  (% of total revenue)  [= 480 ÷ 11,000 (Total Revenue)]

  Other
  Other                                         (30)  (USD in millions)     [= EOP − BOP − Capex + D&A = 2,200 − 2,150 − 480 + 400 = (30)]
  as % of revenue                             (0.3%)  (% of total revenue)  [= (30) ÷ 11,000]

  Depreciation Schedule  [the roll-forward, on top]
  Net Property and Equipment, BOP              2,150  (USD in millions)     [= prior year EOP]
  Capital Expenditures                           480  (USD in millions)     [= ref Capex build]
  Depreciation & Amortization                    400  (USD in millions)     [= ref Depreciation build D&A]
  Other                                         (30)  (USD in millions)     [= ref Other build]
  Net Property and Equipment, EOP              2,200  (USD in millions)     [= ref Net PP&E in Depreciation build ← sum bar]
  Memo: BOP + Capex − D&A + Other − EOP            0  (USD in millions)     [= 2,150 + 480 − 400 + (30) − 2,200 = 0 ✓]
```

Downstream (§6): when CONSOLIDATED FINANCIALS is built, its `Total Depreciation &
Amortization` references this **400** (cash-flow D&A) and `Total EBITDA = EBIT +
400`; when COSTS is built, its total-D&A line references this row in the projection
columns. ✓

---

## Section 9 — Projecting the schedule forward (the projection layer)

Sections §1–§8 build and quality-check the **historical** schedule (the four FYs
`N−3 … N`). This section populates the **projection columns** — the forward fiscal
years `N+1 … N+5`, or whatever forward portion the upstream **REVENUE** build
actually laid down. It adds **no new rows and no new line items**: every projection
lives in the **forward period columns of the rows already built** in §2–§5.

**Three ground rules that hold for the whole projection layer:**

1. **Never touch a historical cell or a historical formula.** Every value and
   formula in the four historical columns (`N−3 … N`) stays exactly as §1–§8 laid it
   down — the reported PP&E components, accumulated depreciation, reported Net PP&E,
   cash-flow D&A and capex inputs, the `Implied Useful Life` ratio, the historical
   `Other` plug, and the historical roll-forward all remain as built. This section
   writes **only** into the forward columns.
2. **Project only the columns the upstream build projected.** Every forward dollar
   here is ultimately struck against forward **revenue** (capex and Other) or rolls
   off prior Net PP&E (D&A). A column can only be filled where the **REVENUE** build
   already laid down that forward period and its `Total Revenue`. If a forward column
   was not projected upstream, leave the matching cells here blank (dash) — never
   invent a revenue base.
3. **One structural change vs. the historical schedule — the `Net PP&E ↔ EOP`
   direction flips, and `Other` stops being a plug.** In the **historical** columns,
   the roll-forward's `Net Property and Equipment, EOP` is a *reference down* to the
   reported `Plant, Property, and Equipment Net`, and `Other` is the *plug* that
   makes the walk foot. In the **forward** columns those two roles **reverse**: the
   roll-forward computes `EOP` from the walk (`BOP + Capex − D&A + Other`), the
   Depreciation build's `Net PP&E` *references up* to that `EOP`, and `Other` becomes
   a **driver-based** value (% of revenue), not a residual. This flip is what keeps
   the forward columns acyclic (§9.6) — there is no reported Net PP&E to anchor to in
   the future, so the walk itself produces the closing balance.

The whole forward schedule rests on **three drivers**: `Implied Useful Life` (the
Depreciation build, §9.3), `Capital Expenditures — as % of revenue` (§9.2), and
`Other — as % of revenue` (§9.4). Set the drivers first; every forward dollar then
flows from them. Set the forward `Total Revenue` reference cells exactly as the
upstream sections already reference them — never re-key a revenue figure.

### 9.1 — The driver methodology (how every forward assumption is set)

This is the **same driver methodology the COSTS build uses** (`costs` §9.1 for
restaurants and retail, §8.1 for software); apply it identically here so the whole
workbook's assumption layer is consistent.

**What is a driver.** The three forward rows named above — `Implied Useful Life`,
the Capex `as % of revenue`, and the Other `as % of revenue` — are the model's
**true assumptions**. They are the only cells in this section an analyst is meant to
dial; every projected **dollar** (forward D&A, forward capex, forward Other, and
therefore forward Net PP&E) is computed from them.

**Driver styling — RED font.** Mark **every forward driver cell red**, the styling rules' color for **estimated / assumption values**. This
makes the assumption set visible at a glance and separates the drivers an analyst
may change from the black formula cells they should not. (§2.1 names
`Implied Useful Life` the driver and defers here for the forward mechanic.)
**Historical** `Implied Useful Life` and **historical** `as % of revenue` cells stay
**black live formulas** — they are *derived* (`Net PP&E ÷ D&A`, `cost ÷ revenue`),
not drivers. Placeholders are **not** red: forward D&A, forward capex, forward
Other, and the forward roll-forward / Net PP&E cells are all **black formula** cells.

**Driver value methodology (apply to every driver row, identically).**

- **First projection year (`N+1`) = the default seed** (`../../SKILL.md`, Build
  mechanics), in this order: the **guided** value when the shared guidance table
  names this driver for `N+1` (the midpoint, hyperlinked to the exhibit, the comment
  quoting the issuer); else the latest year on the **issuer's normalized basis** when
  the filing discloses one (a red constant, the disclosure cited); else the **latest
  historical year as reported**, which the renderer writes as a live formula over the
  three most recent historical cells:

  ```
  N+1 driver  =  IF(ISNUMBER(<N>), <N>, IF(ISNUMBER(<N−1>), <N−1>, IF(ISNUMBER(<N−2>), <N−2>, 0)))
  ```

  and only when `N` is itself a disclosed distortion with no normalized figure, a
  reference to the latest clean year among `N−1` and `N−2`, the comment naming the
  distortion. No year is averaged and no CAGR is seeded; the first forward year
  continues the last actual, so there is no mechanical step at `N+1`.

- **Every later projection year (`N+2`, `N+3`, `N+4`, `N+5`) = the first projection
  year.** Each forward column references the `N+1` driver cell, so the assumption is
  **held flat** across the horizon:

  ```
  N+2 driver = <N+1 driver cell>
  N+3 driver = <N+1 driver cell>
  …and so on for every remaining projection year.
  ```

  (Referencing `N+1` directly — rather than the immediately prior column — means that
  if the analyst overrides `N+1`, the whole flat line moves with it.)

- **This pattern holds forward for every one of the three drivers.** All forward
  driver cells are **red**, because the whole forward row is the assumption set. An
  analyst may **override any driver cell** by typing a value over the formula; the
  cell stays red to signal it is an assumption.

- **Number formats are unchanged.** A red driver keeps the format its historical row
  already used: `Implied Useful Life` stays a plain number (years); the two `as % of
  revenue` rows stay accounting-percent. Only the **font color** turns red.

### 9.2 — The Capital Expenditures build (forward)

Project this block first among the dollar builds — it has no dependency on the walk.

- **`as % of revenue`** (the driver). Leave the **historical** `%` cells exactly as
  §3 laid them (`= Capital Expenditures ÷ Total Revenue`, black). Fill the
  **forward** `%` cells with the §9.1 driver methodology — `N+1` = the default seed (guided capex, else the latest year), each later year `= the N+1 cell` — and color every forward cell **red**.
  When the guidance table gives capital expenditures for `N+1`, lay the
  `Guidance: Capital Expenditures` row (§3) and make the `N+1` driver the live
  formula `= <Guidance: Capital Expenditures, N+1> ÷ <Total Revenue, N+1>` — a red
  formula over two visible cells, the comment naming the guide — so the forward
  dollar row equals the guided figure and later years hold that ratio. The guided
  figure is never typed inside the driver formula; the visible row is where a reader
  finds it. No memo is laid: the `N+1` dollar row equals the guide by construction.
- **`Capital Expenditures`** ($). Leave the **historical** capex cells exactly as §3
  laid them (the issuer's figure as a green hyperlinked input, or the SUM of its
  component rows; the component rows are dashes forward). For each **forward**
  column, set:

  ```
  Capital Expenditures (forward)  =  <as % of revenue driver, this col>  ×  <Total Revenue, this col>
  ```

  a **black live formula** (a placeholder derived from the driver, not a red cell),
  referencing the **REVENUE build's** forward `Total Revenue`. Never re-enter a
  revenue number.
- The roll-forward's `Capital Expenditures` line (§9.5) keeps its **same reference
  down** to this row in the forward columns — only the value underneath it changed.

### 9.3 — The Depreciation build (forward) — the forward D&A source

This block produces **forward D&A**, the row the COSTS build references in its own
forward columns (`costs` §9.3; §8.3 for software) and the row the roll-forward refers
down to. Keep the `Depreciation & Amortization`, `Plant, Property, and Equipment Net`,
and `Implied Useful Life` row labels and locations **stable** so downstream skills can
find them.

- **PP&E components, `Plant, Property, and Equipment Gross`, and `Accumulated
  Depreciation`** — **leave every forward cell blank (dash).** Per the build rule, do
  not project the walkdown up to Net PP&E; there is no forward component detail to
  show. Historical cells in these rows are untouched. (Do not carry the `= SUM(...)`
  Gross formula forward into the blank columns either — leave them empty.)
- **`Plant, Property, and Equipment Net`** — historical cells stay `= Gross −
  Accumulated Depreciation` (black, sum-bar). For each **forward** column, set it to
  a **reference up to the roll-forward's closing balance**:

  ```
  Plant, Property, and Equipment Net (forward)  =  <Depreciation Schedule → Net Property and Equipment, EOP, this col>
  ```

  This is the **direction flip** (§9, rule 3): forward Net PP&E mirrors the walk's
  `EOP` rather than the (now blank) Gross-less-accumulated build. Keep the sum-bar
  styling.
- **`Implied Useful Life`** (the depreciation driver). Historical cells stay the
  black live ratio `= Net PP&E ÷ D&A`. Fill the **forward** cells with the §9.1
  driver methodology — `N+1` = the default seed (the latest year; no guidance item
  maps to a useful life), each later year `= the N+1 cell` — and color every
  forward cell **red**. Format stays a number of years.
- **`Depreciation & Amortization`** — historical cells stay the green cash-flow
  deepKPI input. For each **forward** column, D&A is the value this build *solves
  for*, rolling depreciation off the opening asset base over the assumed life:

  ```
  Depreciation & Amortization (forward)  =  <Plant, Property, and Equipment Net, the immediately PRIOR column>  ÷  <Implied Useful Life, this column>
  ```

  a **black live formula**. The numerator is the **prior** period's Net PP&E: for
  `N+1` that is the **last historical reported Net PP&E** (`N`), a real anchor; for
  `N+2 … N+5` it is the prior projection column's `Plant, Property, and Equipment
  Net` (which equals that column's roll-forward `EOP`). This forward D&A is what the
  roll-forward's `Depreciation & Amortization` line refers down to (§9.5), unchanged.

### 9.4 — The Other build (forward)

- **`as % of revenue`** (the driver). Leave the **historical** `%` cells exactly as
  §5 laid them (`= Other ÷ Total Revenue`, black). Fill the **forward** `%` cells with
  the §9.1 driver methodology — `N+1` = the default seed (the latest year; no guidance
  item maps to the plug), each later year `= the N+1 cell` — and color every forward
  cell **red**. (Historical `Other` is often
  small and either sign; the latest-year seed simply carries that run-rate forward.)
- **`Other`** ($). Leave the **historical** `Other` cells exactly as §5 laid them
  (the black roll-forward **plug**, `= EOP − BOP − Capex + D&A`). For each **forward**
  column, `Other` stops being a plug and becomes a **driver-based** dollar:

  ```
  Other (forward)  =  <as % of revenue driver, this col>  ×  <Total Revenue, this col>
  ```

  a **black live formula** referencing the REVENUE build's forward `Total Revenue`.
  This is the second half of the structural flip (§9, rule 3): because forward
  `Other` is now an independent driver-based value (not a residual of `EOP`), the
  roll-forward can **compute** `EOP` forward without a circular reference (§9.6).
- The roll-forward's `Other` line (§9.5) keeps its **same reference down** to this
  row in the forward columns — only the value underneath it changed.

### 9.5 — The Depreciation Schedule roll-forward (forward)

Four of the five lines keep the **exact same formulas/references** they carry in the
historical columns — do not re-wire them. **Only `Net Property and Equipment, EOP`
changes** for the forward columns.

- **`Net Property and Equipment, BOP`** — unchanged: `= <Net Property and Equipment,
  EOP, the immediately prior column>`, every forward column. For `N+1` the prior
  column is the last historical year, so forward BOP automatically picks up the
  reported closing Net PP&E of year `N`.
- **`Capital Expenditures`** — unchanged: `= <Capital Expenditures build → Capital
  Expenditures, this col>` (which is now the §9.2 forward dollar).
- **`Depreciation & Amortization`** — unchanged: `= <Depreciation build →
  Depreciation & Amortization, this col>` (which is now the §9.3 forward dollar).
- **`Other`** — unchanged: `= <Other build → Other, this col>` (which is now the §9.4
  forward dollar).
- **`Net Property and Equipment, EOP`** — **this is the one changed line.** Historical
  cells stay `= <Depreciation build → Plant, Property, and Equipment Net>`. For each
  **forward** column, replace that reference with the roll-forward identity computed
  **forward**:

  ```
  Net Property and Equipment, EOP (forward)  =  <BOP, this col>  +  <Capital Expenditures, this col>  −  <Depreciation & Amortization, this col>  +  <Other, this col>
  ```

  D&A is carried positive and **subtracted**; capex and Other are **added** (Other
  signed). Keep the **SUM-BAR** styling. Carry this formula across **all** forward
  columns; do **not** alter any historical `EOP` cell.

### 9.6 — Why the forward columns don't go circular (and the forward checks)

The direction flip (§9, rule 3) keeps the forward dependency graph **acyclic** —
each forward column depends only on the **prior** column's closing balance plus the
**current** column's drivers and revenue, so the schedule resolves left-to-right:

```
  drivers (Useful Life, Capex %, Other %)  ── red; depend on history only, not on the walk
  Capex $(t)  = Capex %(t) × Revenue(t)
  Other $(t)  = Other %(t) × Revenue(t)
  D&A(t)      = Net PP&E(t−1) ÷ Useful Life(t)          ← PRIOR column's Net PP&E only
  BOP(t)      = EOP(t−1)                                 ← PRIOR column's EOP only
  EOP(t)      = BOP(t) + Capex(t) − D&A(t) + Other(t)
  Net PP&E(t) = EOP(t)                                   ← mirrors EOP; nothing reads back into the walk
```

`Net PP&E(t)` references `EOP(t)`, but nothing references `Net PP&E(t)` back into the
column's own `EOP` (D&A uses `Net PP&E(t−1)`, the prior column). No cycle. Contrast
the **historical** regime, where `EOP = ref(Net PP&E)` and `Other = plug` — the
opposite directions, also acyclic. If a tool flags a forward circular reference, you
either left forward `Other` as the plug formula (it must be `% × revenue`, §9.4) or
pointed forward D&A at the **current** column's Net PP&E instead of the **prior**
column's (§9.3) — fix that.

Forward quality checks (verify with live formulas, not by eye):

- **Roll-forward foot memo stays 0.** `Memo: BOP + Capex − D&A + Other − EOP` (§7) is
  **0** every forward period too — now 0 *by definition*, because forward `EOP` is
  the walk itself. Carry the memo across the forward columns.
- **Net PP&E tie memo is historical-only.** `Memo: Net PP&E − reported = 0` (§2.2)
  has no meaning forward (no reported Net PP&E exists for a future period) — leave its
  forward cells **blank (dash)**. Do not fabricate a reported projection.
- **Forward `Implied Useful Life` is sane.** Being the latest historical year, it
  should sit in the same plausible band as history; if it doesn't,
  a historical ratio is off (a series not converted to base units on ingest, or a wrong
  D&A series).
- **Styling is correct.** The three driver rows are **red** in every forward column;
  every other forward cell (forward D&A, capex, Other, BOP, EOP, Net PP&E) is a **black
  live formula**; the PP&E components, Gross, and Accumulated Depreciation are
  **blank**. Recalculate the workbook and confirm **zero formula errors**.

### 9.7 — Worked illustration (projection mechanics)

Continue the §8 company (USD in millions; figures illustrative). Suppose the three most
recent historical years read: `Implied Useful Life` **5.7 / 5.6 / 5.5**, `Capex as %
of revenue` **4.0% / 4.2% / 4.4%**, `Other as % of revenue` **(0.2%) / (0.3%) /
(0.3%)**, with reported `Net PP&E (N) = 2,200`, and no guided capex for `N+1`, so
every driver takes the latest year. The REVENUE build carries forward
`Total Revenue` of `11,600 (N+1)` and `12,100 (N+2)`.

```
                                        N+1                                   N+2
  DRIVERS (red)
  Implied Useful Life          5.5   = latest year (5.5)              5.5   = <N+1 cell>      (held flat)
  Capex as % of revenue        4.4%  = latest year (4.4%)             4.4%  = <N+1 cell>
  Other as % of revenue       (0.3%) = latest year ((0.3%))           (0.3%) = <N+1 cell>

  DOLLARS (black formulas)
  Capital Expenditures       510.400 = 4.4% × 11,600           532.400 = 4.4% × 12,100
  Other                      (34.800)= (0.3%) × 11,600         (36.300)= (0.3%) × 12,100
  Depreciation & Amortization 400.000= 2,200 ÷ 5.5             413.745 = 2,275.600 ÷ 5.5   (prior Net PP&E ÷ life)

  ROLL-FORWARD
  Net PP&E, BOP            2,200 = EOP(N)                     2,275.600 = EOP(N+1)
  + Capital Expenditures    510.400                                532.400
  − Depreciation & Amort.   400.000                                413.745
  + Other                   (34.800)                               (36.300)
  Net PP&E, EOP           2,275.600 = BOP+Capex−D&A+Other        2,357.955 = BOP+Capex−D&A+Other   ← sum bar
  Memo: foot (must = 0)           0                                      0   ✓

  Depreciation build → Plant, Property, and Equipment Net
                          2,263.410 = ref EOP(N+1)               2,335.163 = ref EOP(N+2)
```

Note the recursion: `N+1` D&A rolls off the **reported** `Net PP&E (N)`; the walk
produces `EOP (N+1) = 2,263.410`; the Depreciation build's Net PP&E mirrors it; and
`N+2` D&A then rolls off **that** `2,263.410`. Every forward column needs only the prior
column plus this column's three red drivers and forward revenue — no circular reference.
Downstream, the COSTS build's total-D&A line references this build's forward D&A
(`costs` §9.3; §8.3 for software), and CONSOLIDATED FINANCIALS references this row in
every column (§6).

---

## Section 10 — Downstream handoff

After the schedule is laid down, recalculated, and the foot checks pass:

- Confirm **zero formula errors**; the Net PP&E tie memo (§2.2) and the roll-forward
  foot memo (§7) are **0** every period; and Implied Useful Life is sane.
- Keep the row labels `Net Property and Equipment, EOP`, `Depreciation &
  Amortization`, `Implied Useful Life`, and `Capital Expenditures` **stable** — they
  are this section's public surface (`Depreciation & Amortization` is the contract
  row CONSOLIDATED FINANCIALS and the cost build reference, §6).
- The `COSTS`, `CONSOLIDATED FINANCIALS`, and `NET WORKING CAPITAL` sections
  (orchestrator Step 4, items 3–5) are built **after** this one. Hand control back to
  the orchestrator to continue.

---

*This build is part of the Revelata operating-model skill set. It writes only the
DEPRECIATION SCHEDULE section (the PP&E roll-forward, the Depreciation / Capital
Expenditures / Other builds); it does no industry routing, pulls only the PP&E /
capex / D&A series it needs, and never writes into another section. Revenue, costs,
consolidated financials, net working capital, and all other sections are owned by
their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Total Revenue` (`rev_total`) for the capex and Other drivers | revenue build | always | none — stop |
