---
name: consolidated-financials
description: >
  Builds the CONSOLIDATED FINANCIALS summary section of an operating-model
  workbook for a US public company. Invoked by the `operating-model` orchestrator
  AFTER the REVENUE, DEPRECIATION SCHEDULE, and COSTS sections are fully built;
  receives the resolved `company_id`, official company name, workbook path (with
  those three sections already laid down), the shared KPI inventory, and the
  industry determination.
  Unlike the revenue/costs routers, this skill performs the build itself — it does
  NOT route to a sub-skill. It assembles a single summary table beneath the
  `CONSOLIDATED FINANCIALS` ALL-CAPS header: Revenue (by segment → Total Revenue),
  Cost (by segment → Total Costs), Operating Income (by segment → Total Operating Income),
  Depreciation & Amortization (Total, referencing the depreciation schedule's D&A),
  and EBITDA (Total). Every figure is a live `=` formula REFERENCING cells already
  built in the REVENUE, COSTS, and DEPRECIATION SCHEDULE sections —
  it pulls NO new KPI series (no `search_kpis`, no `list_kpis`). Segments are
  discovered by reading the consolidated revenue table (Revenue) and the cost
  subtotal rows (Costs) already in the workbook; an Operating Income segment is
  shown only when that segment exists in BOTH Revenue and Costs. It makes no
  deepKPI calls at all; the §4 check that nothing sits between the built costs and
  Operating Income / EBIT reads the shared inventory already in hand. Format
  per ../../_common/revelata-excel-styling-rules.md.
---

# consolidated-financials (summary-table builder)

This sub-skill is part of the `operating-model` system and owns the
**CONSOLIDATED FINANCIALS** section. **It is a builder, not a router.** Where
`revenue/revenue.md` and `costs/costs.md` only classify and hand off, this file
**writes the workbook itself** — it lays down a compact summary income statement
beneath the `CONSOLIDATED FINANCIALS` ALL-CAPS header.

The section is a **summary roll-up of work that already exists in the workbook.**
By the time control reaches this file, the **REVENUE** and **COSTS** sections are
already built, so every number this section needs is already a cell somewhere
above it. This build therefore **pulls no new KPI time series** — it does not call
`search_kpis` or `list_kpis`. Every value it writes is a **live `=` formula that
references the revenue and cost cells already laid down.** It makes **no** deepKPI
calls at all; the §4 check that nothing sits between the built costs and Operating
Income reads the shared inventory already in hand.

## Prerequisite — REVENUE, DEPRECIATION SCHEDULE, and COSTS must be built first

This build runs **only after the REVENUE, DEPRECIATION SCHEDULE, and COSTS sections
are fully laid down** (orchestrator Step 4, items 1–3), because it references their
cells:

1. The **REVENUE section is finished** — its consolidated revenue table (the
   bottom of the revenue build) lists the revenue components that sum to
   `Total Revenue`. This build reads that table to discover the **revenue
   segments** (§1) and references its rows.
2. The **COSTS section is finished** — its cost subtotal row(s) and the
   `Operating Income (modeled)` line exist. This build reads them to discover the
   **cost segments** (§1) and references its rows.
3. The **DEPRECIATION SCHEDULE is finished** — its `Depreciation & Amortization`
   row (the Depreciation build) exists. It is the model's single D&A source and the
   only row this section's D&A block references (§6).

If the orchestrator routed here before all three completed, **stop** and return
control — do not build the consolidated financials out of order.

> **Note on build order versus sheet order.** The depreciation schedule sits
> **below** this section on the sheet but is built **before** it (orchestrator Step
> 4, item 2); the renderer places each section under its scaffold header whenever it
> is built (`../SKILL.md`, "Build mechanics"). Only NET WORKING CAPITAL (item 5) is
> built after this section.

**Inputs expected from the orchestrator:** resolved `company_id`, official company
name, the path to the workbook (with the REVENUE, DEPRECIATION SCHEDULE, and COSTS sections already
built), the **shared KPI inventory**, and the **industry determination**.

**Data source:** deepKPI only — see `../../_common/data-source-rules.md`. On failure,
follow `../../_common/connection-failure.md`. This build makes **no** deepKPI calls
of any kind — not `search_kpis`, not `list_kpis`, and no filing read; the §4 check
uses the shared inventory already in hand.

**Formatting:** follow `../../_common/revelata-excel-styling-rules.md` and build with
the **xlsx** skill. All conventions there apply, **except** the time scope and
column layout, which this section **matches to the REVENUE / COSTS build** (next
section).

**Number format and units:** storage, the number-format strings, and the tag grammar
come from `../../_common/revelata-excel-units-and-scale.md`, and every row's family
follows from that file's Rule 4. **The Col D tag for every row this section writes is
shown in the row map of its own section** — §2 through §7 — and in the `Units (Col D)`
column of that section's formula table; the index under "The target layout" explains how
to read the row-map annotations. Every row in this section is a **money** row — the
segment lines, every total, and the three foot-check memos (§2, §3, §5), which are
differences of money rows — so every tag is the placeholder `(USD in <scale>)`: the
contract's Rule 2 supplies the scale, millions by default, thousands where the digit
test puts a small filer. This section has no percent, per-unit or count rows and makes
no scale decision of its own.

## Time scope and columns (match the REVENUE / COSTS build)

This rule **overrides** the corresponding conventions in
`../../_common/revelata-excel-styling-rules.md`:

- **Use the exact period columns the REVENUE and COSTS sections already used.**
  Every consolidated line must sit in the **same columns** as the source rows it
  references, so each reference lines up. In practice the restaurant builds use
  the **four most recent fiscal years**, annual columns only; if the upstream
  builds carried a quarterly block, mirror it exactly (annual block, blank
  separator, quarterly block). Do **not** introduce a different timeline and do
  **not** add periods the upstream builds did not lay down. (The full intended
  horizon is the canonical **Model timeline** in the orchestrator `../SKILL.md` —
  the four historical fiscal years plus the five projection years, `N+1 … N+5`,
  after the last historical year; this section mirrors whatever portion of that
  timeline the upstream builds have laid down.)
- **Never re-enter a number that already exists above.** Because every figure here
  is a reference, there are **no green deepKPI input cells in this section** — the
  green, hyperlinked provenance cells live in the REVENUE and COSTS sections. Every
  cell this build writes is a **black live `=` formula** (see §8 styling).

> This build is authored section by section. The sections present here — §1
> segment discovery, §2 the Revenue subtable, §3 the Cost subtable, §4 the
> nothing-in-between check, §5 the Operating Income subtable, §6
> Depreciation & Amortization, §7 EBITDA, §8 layout / styling, §9 quality checks,
> §10 a worked example, §11 the projection layer (carry the formulas forward), and
> §12 the downstream handoff — are the implemented scope. Do **not** build or add any
> information outside the sections present here (e.g. do not extend the table down to
> interest, taxes, or net income).

---

## The target layout

The sheet shape beneath the `CONSOLIDATED FINANCIALS` ALL-CAPS header the scaffold
already placed. Blank lines are the one-row spacers between blocks. Each block's rows,
Col D tags, formatting and formulas are specified **once, in its own section** — build
from there.

```
CONSOLIDATED FINANCIALS                       ← ALL-CAPS section header, already in the scaffold

  Revenue                                     ← block sub-header · rows in §2
    [segment lines, Total Revenue, foot memo — §2]

  Cost                                        ← block sub-header · rows in §3
    [segment lines, Total Costs, foot memo — §3]

  Operating Income                            ← block sub-header · rows in §5
    [one line per cost segment with revenue, Total Operating Income, foot memo — §5]

  Depreciation & Amortization                 ← block sub-header · rows in §6
    [Total Depreciation & Amortization — §6]

  EBITDA                                      ← block sub-header · rows in §7
    [Total EBITDA — §7]
```

**Reading the layout above, the row maps in §2–§7 and the §10 example.** Each row's
annotation has two columns, left to right: the **Col D units tag in parentheses** —
`(USD in <scale>)` means the contract's Rule 2 sets the money scale — and the note in
**square brackets**: `[FORMULA = …]` for the cell formula, plus any styling (`SUM-BAR`,
`italic`). Block sub-headers carry no tag.

The `<each revenue segment>` / `<each cost segment>` rows in §2 and §3 are
**placeholders**: the real segment names, and how many there are, are discovered in §1
from the revenue and cost tables already in the workbook. A block may have **zero**
segment lines (consolidated-only), exactly **one**, or **several**.

**Formatting beyond the Col D units tag is not specified here — follow the workbook's
existing conventions.** Style every row exactly the way the **REVENUE and COSTS
sections** style their own sub-headers, sub-items, and subtotals, per
`../../_common/revelata-excel-styling-rules.md`, so the summary reads as a continuation
of the same workbook. Concretely: the block sub-headers (`Revenue`, `Cost`, `Operating
Income`, `Depreciation & Amortization`, `EBITDA`) are **bold, underlined, size 12,
indented once** — the one sub-header treatment the styling contract gives every
section; segment lines are **sub-items** indented like the
cost lines beneath those sub-headers; and each **total** is styled like `Total operating
expenses` in the cost build (bold, a single thin top border across the data columns —
the sum bar). Every total is a **live `= SUM(...)`** (or the equivalent live formula in
§5.3 / §7), never a hardcoded number. Beyond that added underline on the block
sub-headers, do not invent a bespoke indent / bold / underline scheme for this section —
otherwise mirror what is already on the sheet. The full styling spec is in §8.

---

## Section 1 — Discover the segments (read the workbook, do not pull KPIs)

This first section writes nothing. It reads the **REVENUE** and **COSTS** sections
already in the workbook, the cost build's hand-back report (which path it ran) and the
revenue build's hand-back report (its **segment map**, `../SKILL.md` "The segment
map") to determine the segment lines for each subtable. **Do not call `search_kpis` /
`list_kpis`** — the answer is already on the sheet and in the hand-backs.

### 1.1 — Revenue segments

Which rows are the revenue segments depends on the path the cost build ran (its
hand-back report says; on the sheet, a segment path is the presence of
`Total Costs and Expenses — <Segment>` rows).

**Cost build on a segment path (C1 / C2).** The revenue segments are the **cost
build's segments**, and each one's revenue is the row or rows the revenue build's
hand-back report names for that segment in its **segment map**: one row where the
revenue build laid the segment's revenue as one line (a brand's row inside a units
build's `Unit Revenue` block, a cohort build's `Total Revenue — <Brand> (modeled)`),
several where it laid the segment as several streams or product rows (an ARPU stream
plus that segment's other-revenue stream). Never resolve a segment by comparing
labels: the cost build struck its `% of segment revenue` ratios on exactly these rows,
so on a finished sheet every cost segment with revenue has a map entry (a missing one
is the cost build's finding, raised before this section runs). Revenue the map assigns
to no segment — a stream with no cost segment, the residual `Other Revenue` — is one
further line, `Other Revenue (unallocated)` (§2).

**Cost build consolidated-only (Path C0).** Read the **consolidated revenue table at
the bottom of the REVENUE build** — the small table where the revenue components are
summed to `Total Revenue`. The **revenue segments are the component rows that sum to
Total Revenue there**, taken exactly as the revenue build laid them (same labels, same
order), e.g. `Revenue from the Comparable Cohort`, `Revenue from the Non-Comparable
Cohort`, `Revenue from Franchises`, `Other Revenue` (comparable-stores build); or
`Revenue from Restaurants — Total`, `Revenue from Franchises`, `Other Revenue`
(revenue-per-restaurant build). The Revenue subtable's `Total Revenue` is the sum of
these lines and foots to the revenue build's reported `Total Revenue` by construction
(§9).

> If the revenue build is a **single, undecomposed** total (no component rows),
> the Revenue subtable has **no segment lines** — just reference `Total Revenue`
> directly. **The test is the Col D tag, not the position:** a row counts as a segment
> only if it is a **money** row (`(USD in <scale>)`) that the build sums into
> `Total Revenue`. Rows that sit above the total but carry a per-unit tag (`(USD per
> …)`) or a count tag are the total's **drivers**, not its components, and are never
> segment lines.

### 1.2 — Cost segments (from the cost subtotal rows)

Read the **COSTS section**. The **cost segments are the per-segment cost subtotal
rows** the cost build laid down. **Important:** the cost build's segmentation is
**not** always the same as revenue's:

- **Path C0 — consolidated only.** The cost build laid a single
  `Total Costs and Expenses` (one row, no per-segment breakout). Then the Cost
  subtable has **no segment lines**. It carries instead the cost build's **own
  subtotal rows, where it laid them**: `Total cost of revenue` and `Total operating
  expenses` for a software issuer, the cost-of-sales line and the operating-expense
  lines below gross profit for a retailer on the gross-profit presentation. `Total
  Costs` sums them and still foots to `Total Costs and Expenses`. Where the cost
  build lays one sum only, the subtable has that one line. A summary P&L with one
  cost line gives the reader no gross-margin read, which is why the subtotals are
  carried.
- **Path C1 / C2 — segmented.** The cost build laid a `Total Costs and Expenses —
  <Segment>` subtotal for each brand/geography, **plus** the consolidated
  `Total Costs and Expenses`. Examples: `Total Chili's Costs`,
  `Total Maggiano's Costs`, `Total Corporate Costs`, summing to
  `Total Operating Costs`. Then those per-segment subtotal rows are `Segment A`,
  `Segment B`, … in the Cost subtable (§3), and `Total Costs` sums them.

Note that a **corporate-only** cost segment (e.g. `Total Corporate Costs` /
consolidated G&A) can appear in the cost build with **no matching revenue
segment** — that is expected and handled in §3 / §5.

### 1.3 — State the segment sets before writing

Before laying any rows, record in `BUILD_LOG.md` — one line each — the **revenue
segment set** and the **cost segment set** you read off the workbook, citing the
source rows. The segment rows themselves show the result on the sheet; the log
keeps what was read and from where, and drives the Operating Income lines (§5).
Example:

> *Cost segments: Chili's, Maggiano's, Corporate (from the cost subtotal rows).
> Revenue segments: Chili's = `rev_chilis`, Maggiano's = `rev_maggianos` (from the
> revenue hand-back's segment map); no unallocated revenue.*

or, on Path C0:

> *Cost build: Path C0. Revenue segments: Revenue from Restaurants — Total, Revenue
> from Franchises, Other Revenue (from the consolidated revenue table).*

---

## Section 2 — Revenue subtable

Lay the Revenue block directly beneath the `CONSOLIDATED FINANCIALS` ALL-CAPS
header:

```
  Revenue                                                      [sub-header — bold, size 12, indent once, underlined; §8]
    <Revenue Segment A>                     (USD in <scale>)   [FORMULA = ref to that segment's revenue row, or SUM of its rows per the segment map]
    <Revenue Segment B>                     (USD in <scale>)   [FORMULA = same]
    …                                       (USD in <scale>)   [one row per revenue segment from §1.1]
    Other Revenue (unallocated)             (USD in <scale>)   [segment path only, when the map leaves revenue unassigned: FORMULA = SUM of the unassigned rows]
    Total Revenue                           (USD in <scale>)   [FORMULA = SUM(segments above); SUM-BAR]
    Memo: Total Revenue − revenue build (must = 0)  (USD in <scale>)  [FORMULA = Total Revenue − revenue build's Total Revenue; italic; must be 0 — §9]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Revenue` (sub-header) | | — | *(label only — no data)* | *(none)* |
| `<each revenue segment>` | | `(USD in <scale>)` | segment path: `= <the segment's revenue row, this column>`, or `= <row 1> + <row 2> …` over the rows the segment map names for it; Path C0: `= <that segment's row in the consolidated revenue table, this column>` | `"References the REVENUE section — <segment row label(s)>. Not re-entered."` |
| `Other Revenue (unallocated)` | DATA_DEPENDENT | `(USD in <scale>)` | `= SUM(` the revenue rows the segment map assigns to no segment `)`; laid only on a segment path, and only when non-zero in some year | `"Revenue outside the cost segments: <the streams>. Carried so Total Revenue foots."` |
| `Total Revenue` | | `(USD in <scale>)` | `= SUM(` the segment rows in this block `)` | `"Σ of the revenue segments above. Ties to the revenue build's Total Revenue."` |
| `Memo: Total Revenue − revenue build (must = 0)` *(italic)* | | `(USD in <scale>)` | `= <Total Revenue, this col> − <revenue build's Total Revenue, this col>` | `"Foot check: this section's Total Revenue less the revenue build's; must be 0 every period."` |

- Each segment cell is a **live reference** to the revenue build's row in the same
  column — a black formula, **not** a green input (the green provenance cell lives
  in the REVENUE section). Where the map names several rows for a segment, the
  cell is their sum, still a black formula over the REVENUE rows.
- `Total Revenue` is a **live `= SUM(...)`** over the segment rows in this block.
  If the Revenue subtable has **no** segment lines (§1.1), set `Total Revenue =
  <revenue build's Total Revenue row, this column>` instead, and say so in the
  row's cell comment: "References the revenue build's Total Revenue; no segment
  split."
- Same period columns as the revenue build; one row per segment (never fragment a
  segment into per-period rows).

---

## Section 3 — Cost subtable

Lay the Cost block beneath the Revenue block (one blank spacer row between):

```
  Cost                                                         [sub-header — bold, size 12, indent once, underlined; §8]
    <Cost Segment A>                        (USD in <scale>)   [FORMULA = ref to that segment's cost subtotal]
    <Cost Segment B>                        (USD in <scale>)   [FORMULA = ref to that segment's cost subtotal]
    …                                       (USD in <scale>)   [one row per cost segment from §1.2]
    Total Costs                             (USD in <scale>)   [FORMULA = SUM(segments above); SUM-BAR]
    Memo: Total Costs − cost build (must = 0)  (USD in <scale>)  [FORMULA = Total Costs − cost build's Total Costs and Expenses; italic; must be 0 — §9]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Cost` (sub-header) | | — | *(label only — no data)* | *(none)* |
| `<each cost segment>` | | `(USD in <scale>)` | `= <that segment's "Total Costs and Expenses — <Segment>" row in the COSTS section, this column>` | `"References the COSTS section — <segment subtotal label>. Not re-entered."` |
| `Total cost of revenue` / `Total operating expenses` / the cost-of-sales line *(Path C0, where the cost build laid them)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <that subtotal row in the COSTS section, this column>` | `"References the COSTS section — <subtotal label>. Not a segment: a subtotal of the one consolidated cost block."` |
| `Total Costs` | | `(USD in <scale>)` | `= SUM(` the cost segment rows, or the Path C0 subtotal rows, in this block `)` | `"Σ of the cost segments above. Ties to the cost build's consolidated Total Costs and Expenses."` |
| `Memo: Total Costs − cost build (must = 0)` *(italic)* | | `(USD in <scale>)` | `= <Total Costs, this col> − <cost build's Total Costs and Expenses, this col>` | `"Foot check: this section's Total Costs less the cost build's consolidated total; must be 0 every period."` |

- Each segment cell is a **live reference** to the cost build's per-segment
  subtotal in the same column (black formula, not green input).
- `Total Costs` is a **live `= SUM(...)`** over the cost segment rows. If the cost
  build is **consolidated-only** (§1.2, Path C0 — no per-segment subtotals), the
  Cost subtable has **no** segment lines; its lines are the cost build's subtotal
  rows where laid (§1.2), each a live reference, and `Total Costs` sums them. Where
  the cost build lays one sum only, set `Total Costs = <cost build's consolidated
  Total Costs and Expenses row, this column>` and say so in the row's cell
  comment: "References the cost build's Total Costs and Expenses; no segment
  split."
- Carry costs as **positive** values here (matching the cost build's sign
  convention) and subtract them when computing Operating Income (§5). Be consistent
  sheet-wide and state the convention in the Notes block: "Consolidated
  Financials: costs are shown as positive amounts and subtracted to reach
  operating income."

---

## Section 4 — Nothing sits between Total Costs and Operating Income (a check, not a block)

The framework this section was written from carries a placeholder,
`[Insert Additional Costs here]`, between the Cost subtable and Operating Income.
It existed for the case where the consolidated `Total Costs` referenced an
operating-expense subtotal that left out a line the issuer shows above operating
income — a separately presented impairment or restructuring line, `Other (gains)
and charges`, equity income shown above the operating line. That case cannot
arise under the contract this build now references: `Total Costs` is the cost
build's **`Total Costs and Expenses`**, defined (`../SKILL.md`, "Contract rows") as
the all-in total of **every** additive line between revenue and `Operating Income
(modeled)`; every cost build mirrors the issuer's expense block line for line and
must pass its own `modeled − reported (must ≈ 0)` operating-income check before it
hands back. The placeholder is therefore satisfied upstream, and **this build lays
no Additional Costs block** — one would make `Total Operating Income` disagree with
the cost build's `Operating Income (modeled)` by exactly the items in it, failing
the §5.3 memo.

### 4.1 — The check (no deepKPI call)

Read the shared KPI inventory's **`Consolidated Income Statement`** category,
already in hand. It lists the issuer's reported income-statement lines in order.
Confirm that no line sits **between** the last line the COSTS build carried /
`Total Costs and Expenses` and `Operating Income (modeled)`.

Record the outcome in one line in `BUILD_LOG.md` — *"No line between Total Costs
and Expenses and Operating Income; §4 check passed"* — so the decision is
auditable. A check and its result are build history; nothing goes to the
workbook Notes.

### 4.2 — If the check finds a line

A line between the cost build's total and operating income that the cost build
did not carry is a **cost-build defect**, not a consolidated-financials item: that
build's own operating-income memo should have flagged it. Stop at this check and
return the record **`DEFECT UPSTREAM — costs: no <inventory line name> for
consolidated, <historical columns>; Consolidated Income Statement category, between
Total Costs and Expenses and Operating Income (modeled)`** (the Dependencies table at the end
of this file declares the row; `../SKILL.md` Step 4.2 defines what happens next —
the cost build is re-run from its own file and this section is re-run after it). Do
not lay the line here, do not add a row to the COSTS section from here, and do not
plug the gap — the all-in total lives in the cost build and is corrected there. If
the cost build answers `RE-ENTRY FAILURE` (no series exists for the line), this
section has no fallback: the build stops naming the line.

### 4.3 — Operating Income vs. EBIT (clarification)

In this summary, **Operating Income is the EBIT line** of the model — the table
stops at EBITDA and never descends to interest, taxes, or net income. The §4 check
is therefore exactly: *is there anything between the costs we already built and
the Operating Income / EBIT line?* By contract there is not, and
Operating Income = Total Revenue − Total Costs.

---

## Section 5 — Operating Income subtable

Lay the Operating Income block beneath the Cost subtable (or beneath the Additional
Costs block, if §4 built one):

```
  Operating Income                                             [sub-header — bold, size 12, indent once, underlined; §8]
    <Cost segment>                          (USD in <scale>)   [FORMULA = that segment's revenue line (§2) − that segment's cost line (§3)]
    …                                       (USD in <scale>)   [one row per cost segment that has revenue — see rule]
    Total Operating Income                  (USD in <scale>)   [FORMULA — see §5.3; SUM-BAR]
    Memo: Total Operating Income − cost build (must = 0)  (USD in <scale>)  [FORMULA = Total Operating Income − cost build's Operating Income (modeled); italic; must be 0 — §5.3]
```

### 5.1 — Segment rule

On a **segment path** (§1.1), lay an Operating Income line for **every cost segment
whose revenue the segment map names**: `= <its revenue line in §2> − <its cost line in
§3>`. Both lines exist by construction (§1.1), so no label comparison is made here.
Two kinds of line get **no** Operating Income row:

- a **cost-only** segment (`Corporate` / consolidated G&A — a cost block with no
  revenue of its own, which the map therefore does not name) — its cost still flows
  into `Total Operating Income` via the totals;
- `Other Revenue (unallocated)` — revenue with no cost segment; it too flows into
  `Total Operating Income` via the totals.

On **Path C0** there are no cost segments, so build **no** segment lines; show only
`Total Operating Income`. The Path C0 subtotal lines in the Cost subtable (`Total cost
of revenue`, `Total operating expenses`, the cost-of-sales line) are not segments and
get no Operating Income line.

### 5.2 — The formulas (cell-by-cell)

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Operating Income` (sub-header) | | — | *(label only — no data)* | *(none)* |
| `<each cost segment with revenue>` | | `(USD in <scale>)` | `= <segment's Revenue row, this col> − <segment's Cost row, this col>` | `"Segment operating income = <segment> revenue − <segment> cost. Ties to the cost build's Operating income — <segment> row."` |
| `Total Operating Income` | | `(USD in <scale>)` | see §5.3 | `"Total revenue − total costs. Ties to the cost build's Operating Income (modeled)."` |
| `Memo: Total Operating Income − cost build (must = 0)` *(italic)* | | `(USD in <scale>)` | `= <Total Operating Income, this col> − <cost build's Operating Income (modeled), this col>` | `"Foot check: must be 0 every period. A non-zero gap that equals cost of revenue / cost of sales means Total Costs references an opex-only subtotal instead of Total Costs and Expenses — fix the reference, never add cost of revenue here; otherwise a sign error, a wrong Operating Income (modeled) reference, or a cost line the cost build failed to carry; fix it in the cost block, not here."` |

- Each segment Operating Income cell nets that segment's revenue reference against
  its cost reference — a black live formula.
- Mind the **sign convention** chosen in §3 (costs positive → subtract).

### 5.3 — `Total Operating Income` (the sum line)

`Total Operating Income` is a **live formula**, never hardcoded. Build it so it
both **foots to the components** and **ties to the cost build**:

- **Preferred (ties to the upstream foot):**
  `= <Total Revenue> − <Total Costs>`. This equals the cost build's
  `Operating Income (modeled)` and is robust whether or not segment lines exist.
- It will also equal `SUM(` the segment Operating Income rows `)` **plus** the
  unallocated revenue less the cost-only segments, which have no segment
  line — which is exactly why the totals-based formula above is preferred (it
  captures everything, including unmatched segments, automatically).

Add a hidden/italic memo check `= <Total Operating Income> − <cost build's
Operating Income (modeled), this col>` that must be **0** every period (§9).

---

## Section 6 — Depreciation & Amortization subtable

Lay the D&A block beneath Operating Income. The framework has **no segment lines**
here. `Total Depreciation & Amortization` is **all** depreciation and amortization the
issuer expenses: the depreciation schedule's `Depreciation & Amortization` row plus
every **component amortization line** the cost build carries outside that figure
(`Amortization of cloud computing arrangements`, `Amortization of acquired
intangibles` — the lines the cost hand-back report lists as held flat, schedule §6.2).
In the common case there are none and the block is one row:

```
  Depreciation & Amortization                                  [sub-header — bold, size 12, indent once, underlined; §8]
    Total Depreciation & Amortization       (USD in <scale>)   [FORMULA = the schedule's row; SUM-BAR]
```

When component lines exist, lay the schedule's figure and each component as visible
rows under the issuer's captions, and the total as their `SUM`, so the summation is
followable:

```
  Depreciation & Amortization                                  [sub-header]
    <issuer's D&A caption>                  (USD in <scale>)   [FORMULA = the schedule's row, every column]
    <component line caption>                (USD in <scale>)   [FORMULA = the cost build's line, every column; one row per listed line]
    Total Depreciation & Amortization       (USD in <scale>)   [FORMULA = SUM(rows above); SUM-BAR]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Depreciation & Amortization` (sub-header) | | — | *(label only — no data)* | *(none)* |
| `<issuer's D&A caption>` (the schedule's figure as a visible row) | DATA_DEPENDENT | `(USD in <scale>)` | laid only when a component line is laid: `= <DEPRECIATION SCHEDULE → Depreciation & Amortization, this column>` | `"References the depreciation schedule's Depreciation & Amortization (cash-flow D&A in history, the roll-forward in projection)."` |
| `<component line caption>` | DATA_DEPENDENT | `(USD in <scale>)` | one row per line the cost hand-back lists: `= <that cost line, this column>` | `"References the cost block's <caption>: amortization the issuer expenses outside the depreciation line; added back in EBITDA."` |
| `Total Depreciation & Amortization` | | `(USD in <scale>)` | no component lines: `= <DEPRECIATION SCHEDULE → Depreciation build → Depreciation & Amortization, this column>`; otherwise `= SUM(` the rows above `)` | `"References the depreciation schedule's Depreciation & Amortization (cash-flow D&A in history, the roll-forward in projection), plus any amortization the issuer expenses beside it. EBITDA adds this back."` |

- **Source of D&A:** the depreciation schedule's `Depreciation & Amortization` row —
  the contract row (`../SKILL.md`, "Contract rows"): cash-flow D&A in the historical
  columns, `prior-year Net PP&E ÷ Implied Useful Life` in the projection columns.
  The schedule is built before this section (Prerequisite), so the row exists.
- **The cost block's total-D&A line is never referenced.** Whatever total D&A the cost
  build carries — a total-D&A line, a non-additive memo, or nothing at all when D&A
  is embedded in cost of sales and SG&A — stays inside `Total Costs and Expenses`.
  Only the **component** lines the hand-back lists are referenced, because the
  schedule's figure does not contain them; a build with none is unchanged.
- The label is a bold sum line per the framework.

---

## Section 7 — EBITDA subtable

Lay the EBITDA block last. Again, no segment lines — a block sub-header and a
single total:

```
  EBITDA                                                       [sub-header — bold, size 12, indent once, underlined; §8]
    Total EBITDA                            (USD in <scale>)   [FORMULA; SUM-BAR]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `EBITDA` (sub-header) | | — | *(label only — no data)* | *(none)* |
| `Total EBITDA` | | `(USD in <scale>)` | `= <Total Operating Income, this col> + <Total Depreciation & Amortization, this col>` | `"EBITDA = Operating Income (EBIT) + D&A. D&A was inside Total Costs and Expenses, so it is added back here; the add-back is the depreciation schedule's cash-flow D&A."` |

- EBITDA = **Operating Income + D&A**. Because the cost build kept D&A inside Total
  Costs and Expenses, `Total Operating Income` is already net of D&A; adding the
  schedule's D&A back yields EBITDA. This is a live formula referencing the two total
  rows above — never a hardcode. The add-back is the schedule's cash-flow D&A plus
  the component amortization lines §6 added, so EBITDA is before **all** depreciation
  and amortization the issuer expenses, which is also what the issuer's own
  reconciliation adds back.

### 7.1 — Guidance check (laid only when the guidance table has an item for `N+1` that no driver took)

The orchestrator's guidance table (Step 3.5) carries items no driver takes: the
aggregates no section seeds (a revenue or net-sales level, a total-expense level, an
operating margin, reported or adjusted, an adjusted EBITDA level or margin, a gross
margin rate, a D&A level) and any listed item the revenue build in use has no driver
for (a comparable-sales guide on a square-foot or units build, a brand or segment
revenue guide on a units build, a unit-development guide on a build without that
driver). A guidance block lists what the issuer guided so the reader sees the
issuer's view beside the model's; the analyst's convention is to set the drivers and
then check the model against the guide, never to back-solve the drivers to hit it.
Lay this block beneath `Total EBITDA` when the table has at least one item for fiscal
year `N+1` that no driver took; omit it entirely otherwise. The one exclusion is the
list's last row (effective tax rate, adjusted EPS, free cash flow, share count), which
is outside the model's scope.

**One rule for every item.** For each such item, lay `Guidance: <item>`: the guided
figure for `N+1` as a **visible input** in the guided item's own units — a level in
`(USD in <scale>)`, a margin, rate or growth in `(%)`, a count in `(units)` — a red
constant in the `N+1` cell, hyperlinked to the exhibit, written per cell with
`drv(value, note, url)` (not `drivers_fixed()`, which would carry the figure into
every later year), a dash in every other column. Where the model has a row on the
**same scope and basis**, lay `Memo: modeled − guided <item>` beneath it: `= <the
model's row, N+1> − <Guidance: <item>, N+1>` in the same units, a dash elsewhere; for
a guide stated as growth, the model side is the row's YoY change, `= <row, N+1> ÷
<row, N> − 1 − <Guidance: <item>, N+1>`. The model's row is one that already exists:
`Total Revenue` or `Net Sales` (the revenue build), a segment or brand row of this
section's Revenue subtable, `Total Costs and Expenses` (the cost build), `Operating
margin` and `Gross margin` (the cost build's % walkdown), `Total Depreciation &
Amortization` (this section), `Adjusted EBITDA (issuer basis)` (this block, below).
Where no row on the guided basis exists (a comparable-sales guide when the model lays
no comparable-sales row), the `Guidance:` input stands alone and its comment says so.
A guided figure is **never typed inside a formula**: a margin guide is a `(%)` input
compared with the model's margin row, not a dollar figure computed from it.

```
  Guidance check                                               [sub-header — bold, size 12, indent once, underlined; §8]
    Adjusted EBITDA (issuer basis)          (USD in <scale>)   [only when the issuer guides adjusted EBITDA; FORMULA every column]
    Guidance: <item>                        (the item's units) [one per guided item no driver took: visible input in the N+1 column only, hyperlinked to the exhibit; dash elsewhere]
    Memo: modeled − guided <item>           (the item's units) [only where the model has a row on the same scope and basis; FORMULA in the N+1 column only; italic; visible]
    …                                                          [repeat for each such item: Total Revenue / Net Sales, a segment or brand revenue row, Operating margin, Gross margin, Adjusted EBITDA, Total Costs and Expenses, Total Depreciation & Amortization, a comparable-sales or unit-development guide the build has no driver for]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell | Comment on the Col C label cell |
|---|---|---|---|---|
| `Adjusted EBITDA (issuer basis)` | DATA_DEPENDENT | `(USD in <scale>)` | laid **only when the guidance table carries an adjusted EBITDA level or margin**; `= <Total EBITDA, this col> + SUM(<each cost line the cost build's hand-back lists as excluded from the issuer's adjusted measure>, this col)`, the lines with the sign the cost block carries (a charge positive, a gain negative); `= <Total EBITDA, this col>` when the list is empty | `"EBITDA on the issuer's adjusted definition: Total EBITDA plus the lines the issuer excludes (<list>). Historical columns tie to the reported adjusted EBITDA where the issuer publishes one; forward, the excluded lines are carried at zero, so this equals Total EBITDA."` |
| `Guidance: <item>` — one per guided item for `N+1` that no driver took, named as the model row where one exists (`Total Revenue`, or `Net Sales` when the issuer guides net sales; `<Segment>` or `<Brand>`; `Operating margin`; `Gross margin`; `Adjusted EBITDA`; `Total Costs and Expenses`; `Total Depreciation & Amortization`) and otherwise in the issuer's words (`Comparable sales growth`, `Net new restaurants`) | DATA_DEPENDENT | the guided item's units: `(USD in <scale>)` for a level, `(%)` for a margin, rate or growth, `(units)` for a count | `N+1` only: the guide's midpoint (the stated figure for "at least" / "approximately", per `guidance.md`), a red constant written per cell with `drv(value, note, url)` hyperlinked to the exhibit; a margin or growth guide is the rate itself, never multiplied into dollars; dash in every other column | `"Issuer guidance for FY<N+1>: <verbatim>. Midpoint of <low> to <high>. <basis>."` For an adjusted operating margin add: `"Compared with the modeled operating margin: forward, the lines the issuer excludes are carried at zero, so the two coincide."` Where no memo follows add: `"No modeled row on this basis; shown for reference."` |
| `Memo: modeled − guided <item>` *(italic, visible)* | DATA_DEPENDENT | same units as its `Guidance:` row | laid only beneath a `Guidance:` row whose item the model has a row for on the same scope and basis; `N+1` only: `= <the model's row, N+1> − <Guidance: <item>, N+1>` for a level, margin or rate; `= <the model's row, N+1> ÷ <the model's row, N> − 1 − <Guidance: <item>, N+1>` for a growth guide — `Total Revenue` or the revenue build's `Net Sales`; a segment or brand row of this section's Revenue subtable; the cost build's `Operating margin` or `Gross margin`; `Total Depreciation & Amortization`; `Adjusted EBITDA (issuer basis)`, or for a margin guide `= <Adjusted EBITDA (issuer basis), N+1> ÷ <Total Revenue, N+1> − <Guidance: Adjusted EBITDA, N+1>`; the cost build's `Total Costs and Expenses`, or where the guided basis excludes lines the issuer adjusts for, that total less those lines, said in the comment; dash elsewhere | `"Modeled less guided, first projection year. Not a foot: a gap is information for the analyst, who overrides drivers to close it or leaves it as a view."` |

- The memo rows stay **visible**: they are checks against an external figure, like
  the reported-figure memos, not wiring.
- A guided item outside the model's scope (the fixed list's last row: effective tax
  rate, adjusted EPS, free cash flow, share count) is not laid; the orchestrator's
  hand-back carries it as text. A listed item within scope that has no model row on
  its basis is laid as the `Guidance:` input alone, no memo, its comment saying so.
- A guided item a driver already took (the capex guide in the depreciation schedule,
  a comp guide in a comparable-sales build) is not repeated here; its check is the
  seeded driver itself.
- These rows carry values in `N+1` only; §11 does not carry them across.

---

## Section 8 — Layout and styling (follow the REVENUE / COSTS conventions)

This section introduces **no formatting scheme of its own.** Style every row the
way the REVENUE and COSTS sections already style theirs, per
`../../_common/revelata-excel-styling-rules.md`, so the consolidated summary reads as a
continuation of the same workbook rather than a differently-formatted block. Match
the upstream sections; aside from underlining the block sub-headers (below), do not
invent a bespoke indent / bold / underline scheme.

- **`CONSOLIDATED FINANCIALS` ALL-CAPS header** — already in the scaffold (bold,
  underlined, size 16, like the other section headers). Leave it as is.
- **Block sub-headers** (`Revenue`, `Cost`, `Operating Income`, `Depreciation &
  Amortization`, `EBITDA`) — **bold, size 12, indented once, and underlined**: the
  sub-header treatment the styling contract gives every section. Do not apply the
  big ALL-CAPS-header look (size 16).
- **Segment lines** — **sub-items** under their sub-header, indented exactly the way
  the cost lines sit under `Consolidated Costs` in the cost build (the styling
  rules' sub-item indent). Plain font; the segment's display label exactly as it
  reads in the source section.
- **Total rows** (`Total Revenue`, `Total Costs`, `Total Operating Income`, `Total
  Depreciation & Amortization`, `Total EBITDA`) — style them
  the way the cost build styles `Total Costs and Expenses`: bold, with a **single thin
  top border** across the data columns (the sum bar) — never a double line, never a
  bottom border on the row above.
- **Every total is a live `= SUM(...)`** (or the equivalent live formula in §5.3 /
  §7) — never a typed constant, and every total carries its sum line.
- **All data cells are black live `=` formulas.** There are **no green deepKPI
  input cells** in this section (it references; it does not source).
- **Spacing, number format, font, dashes, and period columns** — match the upstream
  sections exactly (one blank spacer row between blocks; same columns per the "Time
  scope and columns" rule above). Col D units tags follow the **Number format and
  units** paragraph under "Prerequisite — REVENUE, DEPRECIATION SCHEDULE, and COSTS must be built first".

---

## Section 9 — Quality checks and the foot

Verify with **live formulas in the workbook** (not by eye) before declaring done:

- **Revenue foot.** `Total Revenue` (this section) = the revenue build's reported
  `Total Revenue`, every period. (By construction when segments are the revenue
  build's components.) Memo `= this section's Total Revenue − revenue build's Total
  Revenue` must be **0**.
- **Cost foot.** `Total Costs` (this section) = the cost build's consolidated
  `Total Costs and Expenses`, every period. Memo must be **0**.
- **Operating Income foot.** `Total Operating Income` = the cost build's
  `Operating Income (modeled)`, every period (§5.3 memo = **0**). A non-zero gap
  means, in order of likelihood, a wrong `Total Costs` reference (an opex-only
  subtotal referenced instead of the all-in `Total Costs and Expenses` row — the gap
  then equals cost of revenue or cost of sales), a sign error, a wrong `Operating
  Income (modeled)` reference, or a cost line the cost build failed to carry (§4 —
  corrected in the cost build) — resolve it; do **not** plug it.
- **Segment lines complete.** On a segment path every cost segment the map names has
  an operating-income line, and each equals the cost build's `Operating income —
  <segment>` row (§5.1); cost-only segments and unallocated revenue have none, yet
  `Total Operating Income` still captures them via the totals-based formula.
- **EBITDA identity.** `Total EBITDA = Total Operating Income + Total D&A`, every
  period.
- **No hardcodes.** Every cell in the section is a live formula referencing the
  REVENUE / COSTS rows (or, for §4, a referenced input). Recalculate the workbook
  (LibreOffice / the xlsx skill's `recalc.py`) and confirm **zero formula errors**
  and that all foot-check memos are 0.

---

## Section 10 — Worked example (illustrative): a two-brand parent

Brinker-style: revenue segments `Chili's`, `Maggiano's`; cost segments `Chili's`,
`Maggiano's`, `Corporate` (G&A only at the parent). Figures illustrative, USD in
millions — the real build references the cells.

```
  Revenue
  Chili's                                   3,600  (USD in millions)  [= ref Chili's revenue]
  Maggiano's                                  430  (USD in millions)  [= ref Maggiano's revenue]
  Total Revenue                             4,030  (USD in millions)  [= SUM(above)]

  Cost
  Chili's                                   3,050  (USD in millions)  [= ref Total Chili's Costs]
  Maggiano's                                  400  (USD in millions)  [= ref Total Maggiano's Costs]
  Corporate                                   160  (USD in millions)  [= ref Total Corporate Costs]
  Total Costs                               3,610  (USD in millions)  [= SUM(above)]

  Operating Income                                 [one line per cost segment with revenue; Corporate is cost-only]
  Chili's                                     550  (USD in millions)  [= 3,600 − 3,050]
  Maggiano's                                   30  (USD in millions)  [= 430 − 400]
  Total Operating Income                      420  (USD in millions)  [= Total Revenue − Total Costs; also = 550 + 30 − 160 (Corporate)]

  Depreciation & Amortization
  Total Depreciation & Amortization           210  (USD in millions)  [= ref Depreciation & Amortization in the DEPRECIATION SCHEDULE]

  EBITDA
  Total EBITDA                                630  (USD in millions)  [= Op Income + D&A]
```

Note how `Corporate` is a **cost-only** segment: it gets **no** Operating Income
segment line, but its 160 still pulls `Total Operating Income` down via the
`Total Revenue − Total Costs` formula (550 + 30 − 160 = 420). A
**consolidated-only** company (Chipotle-style) would instead have **no** segment
lines anywhere — just `Total Revenue`, `Total Costs`, `Total Operating Income`,
`Total D&A`, `Total EBITDA`.

---

## Section 11 — Projecting the build forward (carry the formulas across)

Sections §1–§10 build and quality-check the **historical** columns. This section
explains how to populate the **projection columns** — the forward fiscal years
(`N+1 … N+5`, or whatever forward portion the upstream builds laid down).

**This section is unique: it has no drivers and no assumptions of its own.** Every
cell it writes is already a **live `=` reference** to a cell in the REVENUE or COSTS
section, and those upstream sections have **already been projected** (the revenue
build projected forward revenue; the cost build projected forward costs from its red
`% of revenue` drivers; the depreciation schedule projected forward D&A). So there
is **nothing to assume here** — projecting the consolidated
financials is purely mechanical: **carry each row's historical formula across into
the projection columns** ("drag and drop"). The relative references shift one column
to the right and automatically pick up the upstream projected values.

**Three ground rules:**

1. **No drivers, no inputs — projection cells stay black formulas.** Do **not** add
   any red driver cells and do **not** add any green deepKPI input cells in the
   forward columns. This section references; it never sources. Every projected cell
   is a **black live `=` formula**, exactly like its historical counterpart.
2. **Never touch a historical cell or the framework.** The historical columns and
   every row label / layout in §1–§10 stay exactly as built. This section writes
   **only** into the forward columns.
3. **Project only the columns the upstream builds projected.** Because every cell is
   a reference, a projection column can only be filled where REVENUE, COSTS, **and** the
   DEPRECIATION SCHEDULE already laid down that forward period. Where an upstream cell is blank (a column
   the upstream build did not project, or a segment the cost build left
   historical-only), the carried-forward reference resolves to blank — leave it
   blank; do not substitute a number.

### 11.1 — The mechanical rule (drag-and-drop)

For **every data row** in §2–§7, take the formula in the **last historical column**
and copy it into **each projection column**, letting the column reference shift to
that projection column. The formula **structure does not change** — only the column
it points at. Because each formula is a relative reference to the same row in the
upstream section, the copy for `N+1` references the upstream `N+1` cell, the copy for
`N+2` references upstream `N+2`, and so on. No formula is rewritten, no constant is
typed.

### 11.2 — Row-by-row (every formula carries forward unchanged)

Each row's projected cells are the same formula it already uses, one column over:

| Row | Carried-forward formula (each projection column) | Resolves to |
|---|---|---|
| `<Revenue segment>` (§2) | `= <that segment's revenue row, this proj col>`, or the sum of its rows per the segment map | the revenue build's **projected** segment revenue |
| `Other Revenue (unallocated)` (§2) | `= SUM(` the unassigned revenue rows, this proj col `)` | the revenue build's projected streams outside the cost segments |
| `Total Revenue` (§2) | `= SUM(segments)` (or `= <revenue build Total Revenue>` if no segments) | projected total revenue |
| Path C0 subtotal lines (§3) | `= <that subtotal row in the COSTS section, this proj col>` | the cost build's projected subtotals |
| `<Cost segment>` (§3) | `= <that segment's "Total Costs and Expenses — <Segment>" row, this proj col>` | the cost build's **projected** segment cost (blank if that segment was left historical-only); the segment subtotals and the consolidated total tie forward by the cost build's spine rule (`../costs/segmentSpine.md`), so the segment operating-income lines sum to `Total Operating Income` in every projection column |
| `Total Costs` (§3) | `= SUM(segments)` (or `= <cost build Total Costs and Expenses>` if consolidated-only) | projected total costs |
| `<Operating Income segment>` (§5) | `= <segment revenue, this proj col> − <segment cost, this proj col>` | projected segment operating income |
| `Total Operating Income` (§5.3) | `= <Total Revenue> − <Total Costs>` | projected operating income = the cost build's **`Operating Income (modeled)`** |
| `Total Depreciation & Amortization` (§6) | `= <depreciation schedule's Depreciation & Amortization, this proj col>` | projected D&A (the schedule's forward roll-off) — see §11.3 |
| `Total EBITDA` (§7) | `= <Total Operating Income, this proj col> + <Total D&A, this proj col>` | projected EBITDA |

The §9 foot-check memos are formulas too, so **carry them forward as well** — they
stay **0** in every projected column where the upstream references are consistent
(§11.4).

### 11.3 — Depreciation & Amortization in the projection columns (the one thing to confirm)

The D&A line references the depreciation schedule's `Depreciation & Amortization`
row in every column (§6), so the carry-forward picks up the schedule's forward D&A
(`prior-year Net PP&E ÷ Implied Useful Life`) with no special handling. The one
thing to confirm is that the reference is to the **schedule's** row and not to a D&A
line inside the COSTS block. A cost-block D&A line, where one exists, is a reported
input historically and references the same schedule row forward, so pointing here
at the cost line would appear to work in some builds and have no source in others
(D&A embedded in cost of sales and SG&A). The schedule's row is the source in every
build.

### 11.4 — Pre-delivery checklist (projections)

- [ ] **No driver, assumption, or input cell added** anywhere in the projection
      columns — every projected cell is a **black live `=` formula** reference.
- [ ] **No historical cell or row/label changed** — projections live only in the
      forward columns the **REVENUE and COSTS** builds projected.
- [ ] **Every §2–§7 row carried forward unchanged** (same formula, column shifted)
      into each projection column; blank where the upstream reference is blank.
- [ ] **`Total Operating Income`** carries `= Total Revenue − Total Costs` forward
      and equals the cost build's **`Operating Income (modeled)`** in every
      projected period.
- [ ] **D&A line references the depreciation schedule's `Depreciation &
      Amortization` row** in all columns, never a D&A line inside the COSTS block.
- [ ] **`Total EBITDA = Total Operating Income + Total D&A`** holds in projected
      columns.
- [ ] **Foot-check memos (§9) carried forward** and evaluate to **0** in every
      projected period where the upstream is consistent.
- [ ] After recalculation, **zero formula errors**; the historical columns and §9
      checks are unchanged.

---

## Section 12 — Downstream handoff

After the consolidated financials are laid down, recalculated, and the foot checks
pass:

- Confirm **zero formula errors** and that the Revenue, Cost, and Operating Income
  foot-check memos are **0** every period, and `Total EBITDA = Total Operating Income +
  Total D&A`.
- Keep the row labels `Total Revenue`, `Total Costs`, `Total Operating Income`,
  `Total Depreciation & Amortization`, and `Total EBITDA` **stable** — the user's
  analysis references this summary.
- Only the **Net Working Capital** section (orchestrator Step 4, item 5) is built
  **after** this one. Hand control back to the orchestrator to continue.

---

*This build is part of the Revelata operating-model skill set. It writes only the
CONSOLIDATED FINANCIALS summary section (Revenue, Cost, Operating Income, D&A,
EBITDA) as live references to the REVENUE, COSTS, and
DEPRECIATION SCHEDULE sections;
it pulls no new KPI series and never descends below the operating line. The
depreciation schedule, net working capital, and all other sections are owned by
their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Total Revenue` (`rev_total`) | revenue build | always | none — stop |
| the revenue rows the revenue hand-back's segment map names for each cost segment (`<the segment's revenue row>`, or `<row 1> + <row 2> …`) | revenue build | the cost hand-back report shows a segment path — the cost build struck its segment ratios on these rows, so the map names every cost segment with revenue | none — a cost segment with no map entry is the cost build's finding, raised before this section runs |
| each segment's revenue row in the consolidated revenue table | revenue build | Path C0 and the revenue build laid component rows | `Total Revenue` referenced directly (no segment lines) |
| `Total Costs and Expenses` (`tce`), `Operating Income (modeled)` (`oi_modeled`) | cost build | always | none — stop |
| `Total Costs and Expenses — <Segment>` (`tce_<segment>`) | cost build | the cost hand-back report shows a segment path | segment operating income omitted |
| `subtotal row in the COSTS section` — the Path C0 subtotal rows `Total cost of revenue`, `Total operating expenses` or the cost-of-sales line | cost build | the cost build laid them (its presentation carries a gross-profit or opex subtotal) | one `Total Costs` line referencing `Total Costs and Expenses` |
| every reported income-statement line above operating income, as a cost row | cost build | the inventory's `Consolidated Income Statement` lists the line | none — the §4.2 finding; on `RE-ENTRY FAILURE` the build stops |
| `Depreciation & Amortization` (`dna`) | depreciation schedule | always | none — stop |
| the cost build's component amortization lines (`<component line caption>`, keys as the cost hand-back lists them) for §6 | cost build | the cost hand-back lists such lines | none laid; `Total Depreciation & Amortization` references the schedule alone |
| `Operating margin`, `Gross margin` (the cost build's % walkdown), the revenue build's `Net Sales` and its segment or brand rows, as the model side of a guidance memo (§7.1) | cost build / revenue build | the guidance table carries that item; `Operating margin` always exists, `Gross margin` when `HAS_GROSS_PROFIT_ROW`, `Net Sales` and segment rows when the revenue build laid them | the `Guidance:` input is laid alone; no memo row |
| `cost line excluded from the issuer's adjusted measure` (each one, keys as the cost hand-back lists them) | cost build | the cost hand-back lists excluded lines | `Adjusted EBITDA (issuer basis)` = `Total EBITDA` |
