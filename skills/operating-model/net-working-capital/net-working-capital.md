---
name: net-working-capital
description: >
  Builds the NET WORKING CAPITAL section of an operating-model workbook for a US public
  company. Invoked by the `operating-model` orchestrator LAST — AFTER the REVENUE,
  DEPRECIATION SCHEDULE, COSTS, and CONSOLIDATED FINANCIALS sections are fully built;
  receives the resolved `company_id`, official company name, workbook path (with those
  four sections already laid down), the shared KPI inventory, and the INDUSTRY the
  orchestrator classified once at its Step 1.2. Like `consolidated-financials` and
  `depreciation-schedule`, this skill performs the build itself — it does NOT route to
  a sub-skill. Its mechanics are the same for every industry; its one industry-aware
  step is reading that industry's DRIVER MAP (`restaurants/restaurantsNWC.md`,
  `retail/retailNWC.md`, `software/softwareNWC.md`) for which current operating lines
  to expect, which driver each line takes and which upstream row — by exact label —
  that driver divides by. Net working capital = current
  operating assets − current operating liabilities, where "current" = resolvable within
  one year and "operating" = core to the business model (cash, short-term investments,
  loans / debt, and finance leases are NOT operating and are excluded). It lays down,
  beneath the `NET WORKING CAPITAL` ALL-CAPS header, four blocks: (1) a Current
  Operating Assets walkdown (Accounts Receivables, Inventory, Prepaid Expenses, Income
  Tax Receivables, plus the map's industry lines → Total Current Operating Assets) with
  a parallel Drivers table (days of a flow, share of a flow, or held flat — base rows
  per the map); (2) a Current Operating Liabilities walkdown (Accounts Payable,
  Operating Lease Liabilities, Accrued Expenses, Deferred Revenue, Income Tax Payable,
  Wages Payable, Customer Deposit, plus the map's lines → Total Current Operating
  Liabilities) with a parallel Drivers table (days of a flow, share of a flow, per
  company-operated location, or held flat — base rows per the map); and (3) a Net
  Working Capital table (NWC = Total Current Operating Assets
  − Total Current Operating Liabilities; Change in NWC = current-year NWC − prior-year
  NWC, first historical year blank). The listed line items are NON-EXHAUSTIVE — the
  build figures out which the issuer actually reports and adds any others that are
  current AND operating. Balance-sheet line items are deepKPI inputs; driver bases
  reference rows the REVENUE, COSTS and location builds already laid, by the labels the
  map names; every total, ratio, and driver is a live `=` formula. Pulls specific series via `search_kpis` against the shared
  inventory (never re-runs `list_kpis`). Format per
  ../../_common/revelata-excel-styling-rules.md.
---

# net-working-capital (working-capital builder)

This sub-skill is part of the `operating-model` system and owns the **NET WORKING
CAPITAL** section. **It is a builder, not a router** — like
`consolidated-financials` and `depreciation-schedule`, it writes the workbook
itself. **There is no industry routing here**, and the mechanics below are the same
for every industry. What differs by industry is **which lines an issuer carries and
which upstream row each driver divides by** — a restaurant's payables are days of
food cost, a retailer's days of merchandise cost, a software company's days of total
operating spend — and that is held in one **driver map per industry**
(`restaurants/restaurantsNWC.md`, `retail/retailNWC.md`, `software/softwareNWC.md`),
read at §1.5 for the industry the orchestrator classified once at its Step 1.2. Do
**not** read `get_company_summary` and do **not** re-classify; take the industry as
given and build the schedule.

This is the **last** section of the operating model (orchestrator Step 4, item 5).
When it is done, the model is complete.

## What net working capital is (the definitions that drive every decision)

Net working capital (NWC) measures the capital tied up in the day-to-day operating
cycle. The whole build hinges on three definitions — apply them to **every**
candidate line before including it:

- **Net Working Capital = Current Operating Assets − Current Operating Liabilities.**
- **Current** = expected to be **realized or settled within one year**. In practice,
  this is the issuer's **"current"** balance-sheet section (current assets / current
  liabilities). The **non-current / long-term** portion of any item (e.g. the
  long-term portion of operating lease liabilities, long-term deferred revenue) is
  **excluded**.
- **Operating** = **core to the business model**. **Cash and cash equivalents,
  short-term / marketable investments, restricted cash, loans / notes / the current
  portion of long-term debt, dividends payable, interest payable on debt, and
  finance- (capital-) lease liabilities are NOT operating** and are **excluded**,
  even though they are current. Include only items that arise from selling the
  product or running operations.

> **The two filters are ANDed.** A line enters NWC only if it is **both current AND
> operating**. Cash is current but not operating → out. The long-term portion of
> operating lease liabilities is operating but not current → out. The current
> portion of finance-lease liabilities is current but **financing**, not operating
> → out. **Operating lease liabilities (current portion) ARE operating and current
> → in.** State the include/exclude decision for any non-obvious line in one Notes
> line, in the analyst's words, so the classification is auditable: "Net Working
> Capital: <line> is <included as operating / excluded as financing>; <reason in the
> issuer's caption>."

The four blocks this build lays down — Current Operating Assets (+ Drivers),
Current Operating Liabilities (+ Drivers), and Net Working Capital — flow directly
from these definitions.

## Prerequisite — REVENUE, DEPRECIATION SCHEDULE, COSTS, and CONSOLIDATED FINANCIALS must be built first

This build runs **only after the REVENUE, DEPRECIATION SCHEDULE, COSTS, and
CONSOLIDATED FINANCIALS sections are fully laid down** (orchestrator Step 4, items
1–4). It depends on the upstream sections for the **driver denominators** (none of
which it re-derives):

1. **REVENUE is finished** — its `Total Revenue` row exists. The DSO driver and the
   `% of Revenue` drivers (Deferred Revenue, Customer Deposit) reference it.
2. **DEPRECIATION SCHEDULE is finished** — not referenced by this section, but it
   precedes this one in the build order (it is built second, right after REVENUE,
   although it sits fourth on the sheet). Do not touch it.
3. **COSTS is finished** — its cost block exists, carrying the **`Total Costs and
   Expenses`** contract row and, under the issuer's own captions, the cost-of-sales
   line and (restaurants) the labor line that the industry driver map names as bases
   (§1.5).
4. **CONSOLIDATED FINANCIALS is finished** — not referenced by this section, but it
   is built immediately **before** this one. This build is handed control right
   after the consolidated financials complete. Do not touch it.

Additionally, **if the revenue build laid down a location roll-forward**, that build
laid the contract row **`Company-Operated EOP Balance`** (the consolidated
company-operated unit count — `../SKILL.md`, "Contract rows"), and the
`Operating Lease Liabilities — per Company-Operated Location` driver references it.
If no row with that label exists on the sheet, that one driver falls back to a
percentage basis (§3.2). The test is the presence of the row, never the industry.

If the orchestrator routed here before the four sections completed, **stop** and
return control — do not build net working capital out of order.

**Inputs expected from the orchestrator:** resolved `company_id`, official company
name, the path to the workbook (with REVENUE, DEPRECIATION SCHEDULE, COSTS, and
CONSOLIDATED FINANCIALS already built), the **shared KPI inventory**, and the
**industry determination** (restaurant / retail / software) from the orchestrator's
Step 1.2, which selects the driver map read at §1.5. If no industry was passed,
**stop** and return control; do not classify here.

**Data source:** deepKPI only — see `../../_common/data-source-rules.md`. On failure,
follow `../../_common/connection-failure.md`. Do **not** re-run `list_kpis`; pull the
specific balance-sheet series with `search_kpis` against the shared inventory. The
**only** filing read permitted is the optional 10-K fallback in §1.4 (used solely
when deepKPI lacks a current-asset / current-liability line that the balance sheet
clearly reports).

**Formatting:** follow `../../_common/revelata-excel-styling-rules.md` and build with
the **xlsx** skill. All conventions there apply — one row per distinct series,
deepKPI-sourced values as pale-green hyperlinked input cells, and
**every** total / ratio / driver cell as a live `=` formula (never a hardcoded
number) — **except** the time scope and column layout, which this build
**matches to the upstream sections** (next section).

**Number format and units:** storage, the number-format strings, and the tag grammar
come from `../../_common/revelata-excel-units-and-scale.md`, and every row's family
follows from that file's Rule 4 — an input row's from its deepKPI `unit` field, a
derived row's from the dimensions of its formula. **The Col D tag for every row this
build writes is shown in the row map of its own section** — §2.1, §2.2, §3.1, §3.2 and
§4 — and in the `Units (Col D)` column of that section's formula table; the index under
"The target layout" explains how to read the row-map annotations.
Balance-sheet rows and their totals show the placeholder `(USD in <scale>)`: the
contract's Rule 2 supplies the scale — millions by default, thousands where the digit
test puts a small filer. This block mixes two percent bases — `total costs` and `total
revenue` — so the denominator in each percent tag is what distinguishes rows whose
labels differ by a single word. This build makes one scale decision of its own:

- **`Operating Lease Liabilities — per Company-Operated Location` → `(USD thousands per
  location)`, a declared coherence departure.** The liability displays in millions and
  the location count in ones, so the division comes out in millions per location — a
  figure like `0.0595` that no analyst would write. Lease liability per location is
  quoted in thousands, so display it so and record in the row's Col C comment:
  *"Displayed in USD thousands per location by convention; the operands are in millions
  and ones, so this row does not reconcile on the page. The formula divides base-unit
  values and is exact."* Rescaling the location count instead is not an option: the
  location build displays it in ones everywhere else.
- `DSO` / `DIO` / `DPO` rows keep a plain number format (~1 decimal); percent drivers
  are **italic label + italic data**.

## Time scope and columns (match the upstream build — overrides the common styling rules)

This rule **overrides** the corresponding conventions in
`../../_common/revelata-excel-styling-rules.md`:

- **Use the exact period columns the REVENUE / COSTS / CONSOLIDATED FINANCIALS /
  DEPRECIATION SCHEDULE sections already used.** Every line here must sit in the
  **same columns** as the rows it references, so each driver denominator lines up. In
  practice the restaurant builds use the **four most recent fiscal years**, annual
  columns only; mirror exactly whatever timeline is already on the sheet. Do **not**
  introduce a different timeline and do **not** add periods the upstream builds did
  not lay down. If the upstream sections carried a quarterly block, mirror it
  (annual block, blank separator, quarterly block). (The full intended horizon is
  the canonical **Model timeline** in the orchestrator `../SKILL.md` — the four
  historical fiscal years plus the five projection years, `N+1 … N+5`, after the
  last historical year; this section mirrors whatever portion of that timeline the
  upstream builds have laid down.)
- **Flow vs. stock (only matters if a quarterly block exists).** **Balance-sheet
  balances** (every current operating asset and liability line) are **STOCKS** — use
  the **period-end** value
  directly in each column (never impute Q4 by subtraction). The **driver
  denominators** — the revenue and cost rows the industry map names — are **FLOWS**; reference
  the upstream rows in the matching column (the upstream builds already imputed any
  missing quarter in their own rows). With the default annual-only timeline this
  distinction is moot, but state it if you build quarterlies. **Important: when a
  flow denominator is quarterly, DSO / DIO / DPO must use the matching period-day
  count (≈ 91/92 for a quarter), NOT 365** — see §2.2 / §3.2. With annual columns,
  use **365**.

> This build is authored section by section. The sections present here — §1 the
> data identification / classification, §2 the Current Operating Assets build
> (values + drivers), §3 the Current Operating Liabilities build (values +
> drivers), §4 the Net Working Capital table, §5 quality checks, §6 a worked
> example, §7 the projection layer (forward fiscal years `N+1 … N+5`), and §8 the
> downstream handoff — are the implemented scope. Do **not** build or add anything
> outside these sections (no cash-flow bridge, no full cash-conversion-cycle block
> beyond the per-line DSO/DIO/DPO drivers, and no projection columns beyond those the
> upstream sections actually laid down).

---

## Sign conventions (state once, apply everywhere)

Fix these signs before writing a single cell, and state them in one Notes line so
the build is auditable: "Net Working Capital: liabilities are carried as positive
balances; NWC is assets less liabilities; a positive change in NWC is a cash use."

| Quantity | Sign carried in the sheet | Note |
|---|---|---|
| Each **current operating asset** (AR, Inventory, Prepaids, …) | **positive** | reported balance-sheet stock |
| `Total Current Operating Assets` | **positive** | `= SUM(` the asset lines `)` |
| Each **current operating liability** (AP, Operating Lease Liabilities, Accrued, …) | **positive** | carried as a **positive magnitude** (a liability balance), even though it is a credit |
| `Total Current Operating Liabilities` | **positive** | `= SUM(` the liability lines `)` |
| `Net Working Capital (NWC)` | **signed** | `= Total Current Operating Assets − Total Current Operating Liabilities`. **Frequently NEGATIVE for restaurants and other cash-business operators** (they collect cash immediately and pay suppliers later), which is normal — do not "fix" a negative NWC. |
| `Change in NWC` | **signed** | `= NWC(t) − NWC(t−1)`; blank in the first historical year. |

Carry **all** liability lines as **positive** values and **subtract** the
liabilities total from the assets total in the NWC line. Be consistent sheet-wide.

---

## The target layout

The sheet shape beneath the `NET WORKING CAPITAL` ALL-CAPS header the scaffold already
placed. Blank lines are the one-row spacers between blocks. Each block's rows, Col D
tags, formatting and formulas are specified **once, in its own section** — build from
there; the bracketed placeholders say which.

```
NET WORKING CAPITAL                           ← ALL-CAPS section header, already in the scaffold

  Current Operating Assets                    ← block sub-header · rows in §2.1
    [value walkdown rows — §2.1]

  Current Operating Assets — Drivers          ← block sub-header · rows in §2.2
    [driver rows — §2.2]

  Current Operating Liabilities               ← block sub-header · rows in §3.1
    [value walkdown rows — §3.1]

  Current Operating Liabilities — Drivers     ← block sub-header · rows in §3.2
    [driver rows — §3.2]

  Net Working Capital                         ← block sub-header · rows in §4
    [NWC and Change in NWC — §4]
```

**Reading the layout above, the row maps in §2.1–§4 and the §6 example.** Each row's
annotation has two columns, left to right: the **Col D units tag in parentheses** —
`(USD in <scale>)` means the contract's Rule 2 sets the money scale; every other tag is
written as it goes in the cell — and the note in **square brackets**: `[deepKPI INPUT
…]` for a pulled balance, `[FORMULA = …]` for a computed row, plus any styling
(`SUM-BAR`, `italic`). Block sub-headers carry no tag.

**The line items are PLACEHOLDERS and NON-EXHAUSTIVE.** The asset and liability lines
drawn in §2.1 and §3.1 (`Accounts Receivables`, `Inventory`, …, `Customer Deposit`) are
the **common** ones — **not all companies report all of them, and some report others.**
It is the build's job to read the issuer's balance sheet (§1), include **only** the
lines that are **current AND operating**, drop any the issuer does not report (e.g.
`Restaurant Supplies` is restaurant-specific; many issuers have no `Customer Deposit` or
no `Income Tax Receivables`), and **add** any further current operating line the issuer
does report (e.g. `Other current assets`, `Gift card liability` as its own line,
`Accrued occupancy`, etc.). **The names drawn in the sketches and listed in the
industry maps are classes, not labels.** A class (`Accounts Receivables`, `Prepaid
Expenses`, `Operating Lease Liabilities`) is how the map assigns a line its driver and
its base; the Col C label of every value row is the **issuer's balance-sheet caption**
(`Accounts receivable, net`, `Prepaid expenses and other current assets`, `Operating
lease liabilities, current`), and each driver row is `<that caption> — <metric>`. A
class name appears on the sheet only when it happens to be the issuer's caption.

**Header hierarchy (per the styling contract).** Only the ALL-CAPS `NET WORKING
CAPITAL` header keeps the big-header look (**bold, underlined, size 16**). The five
block sub-headers — `Current Operating Assets`, `Current Operating Assets —
Drivers`, `Current Operating Liabilities`, `Current Operating Liabilities —
Drivers`, `Net Working Capital` — are **bold, size 12, underlined, and indented
once** — the sub-header treatment the styling contract gives every section. Do **not** set them to size
16 (keep them size 12, not the big ALL-CAPS-header look).

**Two tables per side.** Each side has **one table for the
walkdown to its total** (the value rows → the sum-bar total) and, **below it, a
second table with each of the drivers** for the respective line items. The value
**and** the driver are populated for **all historical years** already on the sheet.

---

## Section 1 — Identify, classify, and pull the deepKPI series (no workbook writing yet)

This first section writes nothing. It (a) reads the issuer's balance sheet, (b)
applies the **current AND operating** filters to decide which lines belong, and (c)
maps each surviving line to a deepKPI series pulled with `search_kpis` against the
**shared inventory** (never `list_kpis`). Pull **annual** (`- Annual`) series across
the build window; add the matching `- 3 Month` quarterly series only if the upstream
timeline carried a quarterly block.

### 1.1 — Where the balance-sheet lines live in the shared inventory

All current operating asset and liability lines live under the **`Consolidated
Balance Sheet`** category of the shared inventory (a few issuers tuck supplemental
detail under `Miscellaneous`). Read that category first to see exactly which
current-asset and current-liability lines the issuer reports — **do not assume the
placeholder set.** That category is where the lines are found, not where the search
for each line's series ends. For each line taken, list every series in the **whole
inventory**, every category, whose caption names it — the face caption, a `Total …`
prefix, the note total, a `… - Consolidated` or `… - as of period end` variant —
before choosing one (`../SKILL.md` Step 3, "Which filing a historical value comes
from"). The note total that carries a later filing's restated figure for a year the
face series shows as filed is usually filed under a note category, not under the
balance sheet, which is why the scan cannot stop at the category read first.

| Block line (placeholder) | Side | Typical KPI / balance-sheet wording | Include? |
|---|---|---|---|
| Accounts Receivables | asset | `Accounts receivable, net`, `Receivables, net` | current + operating → **in** |
| Inventory | asset | `Inventory`, `Inventories`, `Merchandise inventory` | current + operating → **in** |
| Prepaid Expenses | asset | `Prepaid expenses`, `Prepaid expenses and other current assets` | current + operating → **in** |
| Income Tax Receivables | asset | `Income tax receivable`, `Income taxes receivable` | current + operating → **in** |
| Accounts Payable | liability | `Accounts payable` | current + operating → **in** |
| Operating Lease Liabilities | liability | `Operating lease liabilities, current`, `Current operating lease liabilities` | current + operating → **in** (CURRENT portion only) |
| Accrued Expenses | liability | `Accrued liabilities`, `Accrued payroll and benefits`, `Accrued expenses` | current + operating → **in** |
| Deferred Revenue | liability | `Deferred revenue`, `Unearned revenue`, `Gift card liability` | current + operating → **in** |
| Income Tax Payable | liability | `Income taxes payable`, `Accrued income taxes` | current + operating → **in** |
| Wages Payable | liability | `Wages payable`, `Salaries and wages payable`, `Accrued payroll` | current + operating → **in** (avoid double-counting with Accrued Expenses — §1.3) |
| Customer Deposit | liability | `Customer deposits`, `Deposits` | current + operating → **in** |

The **industry driver map** (§1.5) lists the further lines that industry typically
carries — restaurant supplies and deferred franchise fees, a retailer's combined
payables-and-accruals line, a software issuer's accrued compensation and deferred
contract costs — with their captions. Treat them exactly as the rows above: current
AND operating, included only if reported.

**Explicitly EXCLUDE (current but NOT operating, or NOT current):**

- `Cash and cash equivalents`, `Restricted cash`, `Short-term investments`,
  `Marketable securities` — current but **financing/investing**, not operating.
- `Current portion of long-term debt`, `Notes payable`, `Loans`, `Revolving credit
  facility`, `Dividends payable`, `Interest payable` — **financing**.
- `Current portion of finance-lease (capital-lease) liabilities` — current but a
  **financing** lease, excluded (a finance lease is financing, not operating).
  **Operating** lease liabilities (current portion) are **kept**.
- The **non-current / long-term** portion of any line (long-term operating lease
  liabilities, long-term deferred revenue, deferred tax assets/liabilities shown as
  non-current) — **not current**.

### 1.2 — Decide the included set (the placeholder lists are non-exhaustive)

Apply §1.1 to the issuer's actual balance sheet. The result is **issuer-specific**:

- **Drop** placeholders the issuer does not report (a software company has no
  `Restaurant Supplies`; many issuers have no `Customer Deposit` or no `Income Tax
  Receivable` in a given year).
- **Add** any further current operating line the issuer **does** report that is not
  in the placeholder list (e.g. `Other current assets` of an operating nature,
  `Accrued occupancy`, `Accrued advertising`, `Gift card liability` carried
  separately from deferred revenue). Use the issuer's exact label.
- A line that is **immaterial or a financing/investing item** is excluded per §1.1.

### 1.3 — Avoid double-counting overlapping accruals

`Accrued Expenses` and `Wages Payable` can overlap: some issuers fold accrued
payroll **inside** a single `Accrued liabilities` line, while others break out
`Salaries and wages payable` **separately** from `Accrued liabilities`. **Use the
issuer's actual presentation and never count the same dollars twice.** If the issuer
reports a single combined accrued-liabilities line, carry **one** `Accrued Expenses`
row (do not also add a `Wages Payable` row). If the issuer reports both separately,
carry both. State which presentation the issuer uses in one Notes line: "Net Working
Capital: the issuer reports <one combined accrued-liabilities line / accrued expenses
and wages payable separately>; carried as reported."

### 1.4 — Fallback if deepKPI lacks a line the balance sheet clearly reports

If `search_kpis` does not return a current operating line that the issuer plainly
reports on the face of the balance sheet, then — and only then — read the latest
10-K balance sheet: call `list_sec_filing_markdowns` (free) then
`get_sec_filing_markdown`, take the line's period-end values, enter those cells as
**gold-fill** override inputs (hyperlinked to that filing, with a cell comment noting
the source), and record it in the Notes block: "Net Working Capital: <line> balances
are taken from the 10-K balance sheet; the database carries no series for it." This
mirrors the cost build's data-quality fallback. Never invent a balance value. If a line genuinely is not reported, **omit
the row** (do not zero-fill); a line reported in some years and later absorbed into
another line is not "not reported" — carry it per the orchestrator's rule on which
filing a historical value comes from (`../SKILL.md`, Step 3).

State, in one line each, the KPI series you matched for every included asset and
liability line (citing the `Consolidated Balance Sheet` category), and the
include/exclude calls for any non-obvious line, **before** writing — so the sourcing
and classification are auditable.

### 1.5 — Read the industry driver map and confirm its base rows exist upstream

The drivers (§2.2 / §3.2) divide by rows the **upstream sections already built**;
**which** row each driver divides by is set by the **industry driver map**, read
**now** — a sibling import the orchestrator's GOLDEN RULE 1 permits at this point:

| Industry (the orchestrator's Step 1.2 determination) | Driver map |
|---|---|
| restaurant | `restaurants/restaurantsNWC.md` |
| retail | `retail/retailNWC.md` |
| software | `software/softwareNWC.md` |

The map lists the industry's typical lines (its §1) and, for every line, the driver
kind, the base row **by the exact label the cost, revenue or location build laid**,
the fallback when that row is absent, and the convention behind the choice (its §2).
The mechanics in §2–§7 do not change by industry; only the bases do. The industry is
the one the orchestrator classified once; this build never re-classifies.

Confirm each base row the map names exists on the sheet before wiring a driver.
Where it does not, apply the map's stated fallback — a **row-presence test with a
default**, never a question to the user — and say so in the driver's cell comment.
Two bases every map uses are contract rows and are always present: `Total Revenue`
(REVENUE build) and `Total Costs and Expenses` (COSTS build).

**The recurring cost base.** A ratio struck on a cost total must stand on the footing
the model carries forward. Where the cost hand-back lists any line it seeds at **zero**
forward (`../costs/episodicLines.md`: an impairment, a write-down, a one-off charge)
and that line is non-zero in at least one historical column, this build lays one row,
`Total Costs and Expenses (recurring)` `= <Total Costs and Expenses, this col> −
SUM(<each such line, this col>)` in every column (§2.2), and **every driver this file
or the map bases on `Total Costs and Expenses` is based on that row instead**, on
both sides: the historical ratio divides by it and the forward value multiplies by it
(§7.2, §7.3). Forward the two rows are equal, since the zero-seeded lines are zero;
in history the recurring row strips the charge, so the ratio is stable across years
instead of dipping in the year of the charge. A line the episodic rule seeds at a
run-rate stays inside the base. Where the hand-back lists no such line the row is not
laid and the plain contract row is the base. This is the analyst's convention: an
accrual or a prepayment scales with the spending that generates it, and a non-cash
write-down generates none. The location count,
`Company-Operated EOP Balance`, is present only where a location build ran (see the
Prerequisite). The cost-of-sales and labor lines are laid under the issuer's own
captions; the map describes them by family and by their place in the cost walkdown.

---

## Section 2 — The Current Operating Assets build (values + drivers)

Lay this block first beneath the `NET WORKING CAPITAL` header. It is **two tables**:
the **value walkdown** to `Total Current Operating Assets`, then the **Drivers**
table beneath it.

### 2.1 — The value walkdown for Assets

```
  Current Operating Assets                                                       [bold sub-header, size 12, underlined]
    Accounts Receivables                              (USD in <scale>)           [deepKPI INPUT — balance-sheet stock; label = the issuer's caption, this name is the class — §1.1]
    Inventory                                         (USD in <scale>)           [deepKPI INPUT]
    Prepaid Expenses                                  (USD in <scale>)           [deepKPI INPUT]
    Income Tax Receivables                            (USD in <scale>)           [deepKPI INPUT]
    …                                                 (USD in <scale>)           [one row per included current operating asset — §1.2]
    Total Current Operating Assets                    (USD in <scale>)           [FORMULA = SUM(asset lines above); bold, SUM-BAR]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `<each current operating asset>` | | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked period-end balance) | *(no comment on input rows — provenance is the hyperlink)* |
| `Memo: <item> inside <balance>` *(italic, beneath the balance it sits in)* | DATA_DEPENDENT | `(USD in <scale>)` | laid only when the filing discloses a one-off non-trade item inside that balance (§7.1): the item's amount, hyperlinked to the disclosure, in the year(s) given; dashes elsewhere; not summed into the total | `"<item> included in <balance> at FY<N>, per <note>. Shown so the year's days read as reported; the forward driver is seeded net of it."` |
| `Total Current Operating Assets` | | `(USD in <scale>)` | `= SUM(` the asset rows above `)` | `"Σ of the current operating assets. Current AND operating only — excludes cash, short-term investments, and any non-operating current asset."` |

- Each asset line is **one row** across the period columns (annual block, then the
  quarterly block if the upstream sections carried one), per the one-row-per-series
  rule. Do **not** fragment a line into per-period rows.
- `Total Current Operating Assets` carries the **SUM-BAR** styling (bold; a single thin
  top border across the data columns — never a double line, never a bottom border on the
  row above) and is a **live `= SUM(...)`** — never an input, never hardcoded.

### 2.2 — The Drivers table for Assets

Lay the Drivers table directly beneath the value walkdown (one blank spacer row),
**one driver row per asset line that has a driver, in the same order**. Each driver
row's Col C label is the line name **plus its metric** (`— DSO`, `— DIO`, `— % of
<Base>`), because the basis differs from row to row (unlike the cost build's uniform
`% of revenue` block, the metric belongs in the visible label here). The metric and
the base for each line come from the **industry map's §2**; put the full formula
recipe in the Col C cell comment.

```
  Current Operating Assets — Drivers                                             [bold sub-header, size 12, underlined]
    Total Costs and Expenses (recurring)              (USD in <scale>)           [FORMULA = Total Costs and Expenses − SUM(lines the cost build seeds at zero); ONLY where the cost hand-back lists such a line (§1.5); the base of every % of Total Costs driver and every fallback on that total]
    Accounts Receivables — DSO                        (days)                     [FORMULA; label = <the value row's caption> — DSO]
    Inventory — DIO                                   (days)                     [FORMULA]
    Prepaid Expenses — % of Total Costs               (% of total costs)         [FORMULA; italic; `(% of recurring total costs)` where the recurring row is laid]
    <line> — <metric per the map>                     (<tag per the map>)        [FORMULA; one row per further asset line that has a driver]
```

The driver kinds, with the base row supplied by the map:

| Driver kind | Col C label | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| the recurring cost base | `Total Costs and Expenses (recurring)` *(first row of the block; not a driver; black)* | `(USD in <scale>)` | **DATA_DEPENDENT** — laid only where the cost hand-back lists a line seeded at zero forward that is non-zero in some historical column (§1.5): `= <Total Costs and Expenses, this col> − SUM(<each such line, this col>)` in **every** column, the lines referenced by key in the COSTS section | `"Total Costs and Expenses less the lines carried at zero forward (<line>, <line>). The base of every cost-based driver below, so the ratio stands on the costs the model carries forward; equals Total Costs and Expenses in every projection year."` |
| days of a flow | `<line> — DSO` / `<line> — DIO` | `(days)` | `= <line, this col> ÷ <base row, this col> × 365` | `"DSO (or DIO) = <line> ÷ <base row> × 365. Days of <base> tied up in <line>."` — name the base row as laid. 365 for annual columns; the period-day count (~91) for quarterly columns. |
| share of a flow | `<line> — % of <Base>` | `(% of <base>)` — the tag names the row divided by: `(% of recurring total costs)` where the base is the recurring row | `= <line, this col> ÷ <base row, this col>` | `"% of <base> = <line> ÷ <base row>."` Where the base is `Total Costs and Expenses` or its recurring row, add the map's caveat that the row includes D&A. |
| held flat | *(no driver row)* | — | — | The balance's own `N+1` cell is the driver (§7.2). Used for `Income Tax Receivables`: no tax line exists in the model (the income statement stops at EBITDA), so the balance is held at its year-`N` value — the standard fallback; say so in the value row's comment. |

- In every map `Accounts Receivables — DSO` divides by `Total Revenue` and
  `Prepaid Expenses — % of Total Costs` by `Total Costs and Expenses`, or by `Total
  Costs and Expenses (recurring)` where that row is laid (§1.5); `Inventory — DIO`
  divides by the cost-of-sales line the map names. Every further asset line takes the
  driver and base its map row gives.
- **DSO / DIO** rows are **days** — a plain number (format to ~1 decimal), **not** a
  percent. **`% of …`** rows use the accounting **percent** format and are **italic**
  per the styling rules.
- Every denominator is a **live reference** to the upstream row, in the **same
  column** — never re-keyed. The numerator is the value row directly above in this
  section.
- **Period-day count.** With the default **annual** columns, use **365**. If a
  quarterly block exists, DSO/DIO in the quarterly columns must use the quarter's
  day count (≈ 91/92), not 365 — state the choice in the comment.
- These drivers are the **projection drivers**: in any projected period the model
  inverts them (`line = driver ÷ 365 × base` for a days driver; `line = driver × base`
  for a share — §7.2). Build them as the live ratio for **every historical period**;
  §7 lays their projection cells.
- Only build a driver row for an asset line that is actually present (§1.2). For any
  **added** current operating asset, use the map's "any added line" row — the
  analogous kind against the analogous base — and note the choice in the comment.

---

## Section 3 — The Current Operating Liabilities build (values + drivers)

Lay this block beneath the assets block (one blank spacer row). Same two-table
shape: the **value walkdown** to `Total Current Operating Liabilities`, then the
**Drivers** table.

### 3.1 — The value walkdown for Liabilities

```
  Current Operating Liabilities                                                  [bold sub-header, size 12, underlined]
    Accounts Payable                                  (USD in <scale>)           [deepKPI INPUT; label = the issuer's caption, this name is the class — §1.1]
    Operating Lease Liabilities                       (USD in <scale>)           [deepKPI INPUT — CURRENT portion only]
    Accrued Expenses                                  (USD in <scale>)           [deepKPI INPUT — e.g. accrued payroll]
    Deferred Revenue                                  (USD in <scale>)           [deepKPI INPUT — e.g. gift card liability]
    Income Tax Payable                                (USD in <scale>)           [deepKPI INPUT]
    Wages Payable                                     (USD in <scale>)           [deepKPI INPUT — omit if folded into Accrued Expenses, §1.3]
    Customer Deposit                                  (USD in <scale>)           [deepKPI INPUT]
    …                                                 (USD in <scale>)           [one row per included current operating liability — §1.2]
    Total Current Operating Liabilities               (USD in <scale>)           [FORMULA = SUM(liability lines above); bold, SUM-BAR]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Operating Lease Liabilities` | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked) | `"CURRENT portion of operating lease liabilities only. Operating leases are operating + current. Finance- (capital-) lease liabilities are financing → excluded. Long-term lease portion is non-current → excluded."` |
| `Deferred Revenue` | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked) | `"Current deferred / unearned revenue (e.g. gift card liability, loyalty deferral). Long-term deferred revenue is excluded."` |
| `<each other current operating liability>` | | `(USD in <scale>)` | deepKPI **input** (green, hyperlinked period-end balance, carried positive) | *(no comment on plain input rows — provenance is the hyperlink)* |
| `Memo: <item> inside <balance>` *(italic, beneath the balance it sits in)* | DATA_DEPENDENT | `(USD in <scale>)` | as in §2.1: a disclosed one-off non-trade item inside that liability (§7.1), hyperlinked, in the year(s) given; dashes elsewhere; not summed into the total | as in §2.1 |
| `Total Current Operating Liabilities` | | `(USD in <scale>)` | `= SUM(` the liability rows above `)` | `"Σ of the current operating liabilities. Current AND operating only — excludes debt, the current portion of finance leases, dividends/interest payable."` |

- Carry every liability as a **positive magnitude** (a balance), per the sign
  conventions. `Total Current Operating Liabilities` is a live `= SUM(...)` with the
  SUM-BAR styling (a single thin top border across the data columns — never a double
  line, never a bottom border on the row above).

### 3.2 — The Drivers table for Liabilities

Lay the Drivers table directly beneath the value walkdown (one blank spacer row),
**one driver row per liability line that has a driver, in the same order**, label =
line name + metric, recipe in the cell comment. The metric and the base for each
line come from the **industry map's §2**.

```
  Current Operating Liabilities — Drivers                                        [bold sub-header, size 12, underlined]
    Accounts Payable — DPO                            (days)                     [FORMULA — base per the map: the cost-of-sales line, or Total Costs and Expenses]
    Operating Lease Liabilities — per Company-Operated Location (USD thousands per location)  [FORMULA — or `— % of Total Costs` where no location count exists]
    Accrued Expenses — % of Total Costs               (% of total costs)         [FORMULA; italic]
    Deferred Revenue — % of Revenue                   (% of total revenue)       [FORMULA; italic — `— % of Net Sales` where the map names that row]
    <line> — <metric per the map>                     (<tag per the map>)        [FORMULA; one row per further liability line that has a driver]
```

The driver kinds, with the base row supplied by the map:

| Driver kind | Col C label | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| days of a flow | `<line> — DPO` | `(days)` | `= <line, this col> ÷ <base row, this col> × 365` | `"DPO = <line> ÷ <base row> × 365. Days of <base> owed."` — name the base row as laid. 365 annual; ~91 quarterly. |
| share of a flow | `<line> — % of <Base>` | `(% of <base>)` — the tag names the row divided by: `(% of recurring total costs)` where the base is the recurring row | `= <line, this col> ÷ <base row, this col>` | `"% of <base> = <line> ÷ <base row>."` D&A caveat where the base is `Total Costs and Expenses` or its recurring row. |
| per location | `Operating Lease Liabilities — per Company-Operated Location` | `(USD thousands per location)` | `= <Operating Lease Liabilities, this col> ÷ <Company-Operated EOP Balance (Total), this col>` | `"Current operating lease liability per company-operated location = liability ÷ the location build's consolidated company-operated EOP count. Same company-operated universe."` |
| held flat | *(no driver row)* | — | — | `Income Tax Payable`: the `N+1` cell is the driver, seeded to the year-`N` value (§7.3) — no tax line in the model; say so in the value row's comment. |

- **DPO** rows are **days** (plain number, ~1 decimal). **`% of …`** rows use the
  accounting **percent** format, **italic**.
- Every denominator is a **live reference** to the upstream row in the same column —
  never re-keyed. Wherever this section or the map names `Total Costs and Expenses`
  as a base, the base is `Total Costs and Expenses (recurring)` when that row is laid
  (§1.5), for days drivers and share drivers alike.
- **Operating Lease Liabilities per location — fallback.** This driver needs a
  **company-operated location count** — the contract row `Company-Operated EOP
  Balance`, laid by every location build. If **no row with that label exists on the
  sheet** (no location build ran — every software build, for instance), **fall back**
  to `Operating Lease Liabilities — % of Total Costs` (`= Operating Lease Liabilities ÷
  Total Costs and Expenses`, or ÷ `Total Costs and Expenses (recurring)` where that row
  is laid, §1.5) and note the fallback in the cell comment. Do **not**
  invent a location count.
- These drivers are the **projection drivers** (inverted in projected periods — §7.3).
  Build them live for **every historical period**; §7 lays their projection cells.
- Build a driver row only for a liability line that is present (§1.2). For any
  **added** current operating liability, use the map's "any added line" row and note
  it. Where the issuer reports one combined payables-and-accruals line, follow the
  map (the retail map's §1) and never carry the same dollars twice (§1.3).

---

## Section 4 — The Net Working Capital table

Lay this block last, beneath the liabilities drivers (one blank spacer row). It is
**three lines** — the sub-header and **two** data rows:

```
  Net Working Capital                                                            [bold sub-header, size 12, underlined]
    Net Working Capital (NWC)                         (USD in <scale>)           [FORMULA = Total Current Operating Assets − Total Current Operating Liabilities; SUM-BAR]
    Change in NWC                                     (USD in <scale>)           [FORMULA = this period's NWC − prior period's NWC; blank in the first historical year]
```

| Row (Col C label) | Lays when | Units (Col D) | Cell, every period column | Comment on the Col C label cell |
|---|---|---|---|---|
| `Net Working Capital (NWC)` | | `(USD in <scale>)` | `= <Total Current Operating Assets, this col> − <Total Current Operating Liabilities, this col>` | `"NWC = Total Current Operating Assets − Total Current Operating Liabilities. Often NEGATIVE for cash-business operators (restaurants) — normal, not an error."` |
| `Change in NWC` | | `(USD in <scale>)` | **first** period column: **blank / dash** (no prior year). Every **later** column: `= <Net Working Capital (NWC), this col> − <Net Working Capital (NWC), the immediately prior period column>` | `"Change in NWC = current-period NWC − prior-period NWC. Blank in the first historical year (no prior period). A positive change = cash USE; a negative change = cash SOURCE."` |

- `Net Working Capital (NWC)` is a **live subtraction** of the two totals above
  (style it as a SUM-BAR / bold subtotal). It is **signed** — do not force it
  positive.
- `Change in NWC` is **blank (dash)** in the **first historical column** (no prior
  period) and a **live difference** of this and the prior column's NWC in every later
  column — a formula, never re-keyed; the first historical year has no prior
  period and stays blank.

---

## Section 5 — Quality checks and the foot

Verify with **live formulas in the workbook** (not by eye) before declaring done:

- **Classification is clean.** Every value row is **current AND operating** (§1.1).
  No cash, short-term investments, debt / notes / loans, current portion of finance
  leases, dividends payable, or interest payable appears on either side; no
  long-term / non-current portion appears. The operating lease line is the **current
  portion** only. (This is a read-through check, recorded with its result in
  `BUILD_LOG.md` — it has no memo cell, but it is the most important check. The
  include or exclude decisions themselves are already Notes lines, per §1.1.)
- **No double-counting.** `Accrued Expenses` and `Wages Payable` do not both capture
  the same accrued payroll (§1.3); the issuer's actual presentation is followed.
- **Totals foot.** `Total Current Operating Assets = SUM(asset lines)` and
  `Total Current Operating Liabilities = SUM(liability lines)` — both live `SUM`s,
  every period.
- **NWC identity.** `Net Working Capital (NWC) = Total Current Operating Assets −
  Total Current Operating Liabilities`, every period (live formula).
- **Change in NWC chains correctly.** Blank in the first historical column; in every
  later column `= NWC(t) − NWC(t−1)` (references the immediately prior period column,
  not a re-keyed number).
- **Every driver references the base row the industry map names, in the right
  column.** DSO ÷ `Total Revenue`; DIO and DPO ÷ the map's base; `% of <base>` ÷ that
  base; per-location ÷ the location build's consolidated company-operated EOP count.
  DSO/DIO/DPO multiply by the correct **period-day count** (365 annual; ~91 quarterly).
  All are live references — no re-keyed denominators.
- **Drivers are sane, by the map's §4 ranges.** Each map states the days and
  percentages its industry typically shows and the sign of NWC it expects (negative
  for a restaurant operator or a prepaid-subscription software issuer, positive for a
  merchandise retailer); the `%` drivers are stable across years. A wild value flags a
  series that was not converted to base units on ingest (Rule 1 of
  `../../_common/revelata-excel-units-and-scale.md` — fix the stored value, never the
  formula) or a wrong base row.
- **No hardcodes; recalc clean.** Every total / ratio / driver / NWC / change cell is a
  live formula; only deepKPI-sourced balance-sheet inputs are literal values, each green
  and hyperlinked (or gold-fill for a §1.4 filing override). Recalculate the workbook
  (LibreOffice / the xlsx skill's `recalc.py`) and confirm **zero formula errors** and
  that the totals and NWC identity hold every period.

---

## Section 6 — Worked example

The worked example lives in the industry driver map (its §3): a restaurant operator
in `restaurants/restaurantsNWC.md`, a discount retailer in `retail/retailNWC.md`, a
subscription software issuer in `software/softwareNWC.md`. Each shows one historical
year of both walkdowns and both driver tables on that industry's bases, the NWC
lines with the sign the industry normally produces, the projection mechanics, and —
where a location build exists — the one declared coherence departure (the
per-location lease driver displayed in USD thousands per location although
liabilities are in millions and counts in ones; the row's Col C comment records it,
per the units contract's Rule 2 coherence test).

---

## Section 7 — Projecting the build forward (the projection layer)

Sections §1–§6 build and quality-check the **historical** net-working-capital block
(the four FYs `N−3 … N`). This section populates the **projection columns** — the
forward fiscal years `N+1 … N+5`, or whatever forward portion the upstream sections
actually laid down. It adds **no new rows and no new line items**: every projection
lives in the **forward period columns of the rows already built** in §2–§4.

**Three ground rules that hold for the whole projection layer:**

1. **Never touch a historical cell or a historical formula.** Every value and
   formula in the four historical columns (`N−3 … N`) stays exactly as §1–§6 laid it
   down — the green deepKPI balance-sheet inputs in the value rows, the black driver
   ratios, both `SUM` totals, and the NWC / Change-in-NWC lines all remain as built.
   This section writes **only** into the forward columns.
2. **Project only the columns the upstream sections projected.** Every forward value
   here is struck against a forward **upstream base** — the rows the industry map
   names: `Total Revenue` (REVENUE build), `Total Costs and Expenses` and the
   cost-of-sales or labor line (COSTS build), and, for the operating-lease driver,
   the **company-operated EOP count** (location build). A
   column can only be filled where those bases were already projected upstream, in
   that same column. If a base column was not projected, leave the matching NWC cells
   blank (dash) — never re-key or invent a base.
3. **The structural flip — driver and value swap roles (the user's key point).** In the
   **historical** columns each driver is *derived from* its value (`DSO = AR ÷ Revenue ×
   365`, `% of Total Costs = balance ÷ Total Costs and Expenses`, …); the **value** is
   the green deepKPI input and the **driver** is the black formula. In the **forward**
   columns those roles **reverse**: the **driver becomes the red assumption** (set per
   §7.1), and the **value is computed by inverting the driver** against its forward base
   (§7.2 / §7.3). The two `SUM` totals, the NWC line, and `Change in NWC` keep their
   historical formulas and simply **carry forward** (§7.4).

Build order in each forward column: **set the drivers first** (red), **then invert
them** into the value rows (black), **then** let the totals, NWC, and Change-in-NWC
formulas (already built) recompute.

### 7.1 — The driver methodology (how every forward assumption is set)

This is the **same driver methodology the COSTS and DEPRECIATION-SCHEDULE builds use**
(`costs` §9.1 for restaurants and retail, §8.1 for software; `depreciation-schedule`
§9.1); apply it identically so the whole workbook's assumption layer is consistent.

**What is a driver.** Every row in the two **Drivers** tables — `… — DSO`, `… — DIO`,
`… — DPO`, `… — % of Total Costs`, `… — % of Revenue`, and `Operating Lease Liabilities —
per Company-Operated Location` — is a model **assumption**. They are the only cells in
this section an analyst is meant to dial; every projected balance-sheet **value** (and
therefore both totals and NWC) is computed from them.

**Driver styling — RED font.** Mark **every forward driver cell red**, the styling rules' color for **estimated / assumption values**. This
makes the assumption set visible at a glance and separates the drivers an analyst may
change from the black formula cells they should not.
**Historical** driver cells stay **black live formulas** — they are *derived*
(`value ÷ base`), not assumptions. Placeholders are **not** red: every forward
**value** row, both `SUM` totals, the NWC line, and `Change in NWC` are **black
formula** cells.

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

- **A disclosed one-off inside a balance is shown beneath it and netted out of the
  seed.** When the filing discloses a non-trade item sitting inside receivables,
  payables or an accrual at year `N` (a settlement receivable, an acquisition-related
  payable), the reported balance and its historical days stay exactly as laid, and the
  item is laid as a **memo input row** directly beneath that balance, `Memo: <item>
  inside <balance>`, hyperlinked to the disclosure, its amount in the year(s) the filing
  gives it and dashes elsewhere (§2.1 / §3.1). The `N+1` driver is then a **red
  formula** on the balance net of the item: `= (<balance, N> − <memo, N>) ÷ <base, N>
  × 365` for a days driver, the same net balance over its base for a ratio driver.
  The reader sees the one-off explain the year-`N` spike in place, and the seed
  derives from cells on the sheet; the driver comment names the item (`"DSO on
  receivables net of the <item> disclosed in <note>; later years hold it flat"`). No
  year is skipped; year `N` is still the base.

- **This pattern holds forward for every driver row, on both sides.** All forward
  driver cells are **red**, because the whole forward row is the assumption set. An
  analyst may **override any driver cell** by typing a value over the formula; the
  cell stays red to signal it is an assumption.

- **Number formats are unchanged.** A red driver keeps the format its historical row
  already used: `DSO` / `DIO` / `DPO` stay a plain number of days (~1 decimal); the
  `% of Total Costs` / `% of Revenue` rows stay accounting-percent; the per-location driver
  stays USD thousands per location. Only the **font color** turns red.

### 7.2 — Current Operating Assets (forward) — invert each driver into its value

Set the forward **drivers** first (red, §7.1), then compute each forward **value** by
**reversing the historical ratio** — the same algebra used to derive the driver, run
backward. The value rows, which are green deepKPI inputs in the historical columns,
become **black formulas** in the forward columns (no hyperlink — they are computed, not
pulled). Use the **same base each historical driver used as its denominator**, in the
**same column**, referencing the upstream forward row (never re-keyed). Where the
historical driver divided by `Total Costs and Expenses (recurring)` (§1.5), the
forward value multiplies by that row's forward cell, which equals `Total Costs and
Expenses` there; the two sides of every ratio always name the same row:

```
  Accounts Receivables (fwd)    =  <Accounts Receivables — DSO, this col>  ÷ 365  ×  <Total Revenue, this col>
  Inventory (fwd)               =  <Inventory — DIO, this col>             ÷ 365  ×  <the map's cost-of-sales base, this col>
  Prepaid Expenses (fwd)        =  <Prepaid Expenses — % of Total Costs, this col>        ×  <Total Costs and Expenses, this col>   (the recurring row where laid)
  Income Tax Receivables (fwd)  =  held flat: N+1 = <Income Tax Receivables, year N> (red driver); N+2 … N+5 = <the N+1 cell>
  <any further asset line>      =  its driver inverted against the base the map names: ÷ 365 × base for a days driver; × base for a share
```

- **Day count.** With the default **annual** columns, divide DSO/DIO by **365**. If a
  quarterly block was projected, use that quarter's day count (~91/92) — the same rule
  §2.2 applies to the historical ratio.
- **`Total Current Operating Assets`** — **do not change its formula.** It stays the
  same `= SUM(asset lines above)` carried into each forward column (black, sum-bar).
  It simply sums the now-computed forward values.
- **Added / issuer-specific asset lines.** For any current operating asset beyond the
  placeholders (§1.2), invert **its** driver against **its** base exactly as the map's
  row gives them. Only project a line that exists historically; a line the issuer
  does not report has no forward cell.

### 7.3 — Current Operating Liabilities (forward) — same inversion

Identical mechanic on the liability side: set the forward **drivers** red (§7.1), then
invert each into its **value** (black formula, positive magnitude), against the same
upstream forward base the historical driver used:

```
  Accounts Payable (fwd)            =  <Accounts Payable — DPO, this col>       ÷ 365  ×  <the map's payables base, this col>
  Operating Lease Liabilities (fwd) =  <… — per Company-Operated Location, this col>   ×  <Company-Operated EOP Balance (Total), this col>
  Accrued Expenses (fwd)            =  <Accrued Expenses — % of Total Costs, this col>        ×  <Total Costs and Expenses, this col>   (the recurring row where laid)
  Deferred Revenue (fwd)            =  <Deferred Revenue — % of <sales row>, this col>  ×  <that sales row, this col>   (Total Revenue, or Net Sales where the map names it)
  Income Tax Payable (fwd)          =  held flat: N+1 = <Income Tax Payable, year N> (red driver); N+2 … N+5 = <the N+1 cell>
  Wages Payable (fwd)               =  <Wages Payable — % of <base>, this col>  ×  <that base, this col>   (the labor line, or Total Costs and Expenses, per the map)
  Customer Deposit (fwd)            =  <Customer Deposit — % of Revenue, this col>     ×  <Total Revenue, this col>
```

- **Operating Lease Liabilities — the per-location dependency.** The forward value needs
  a **forward** company-owned EOP count, which exists only where the location build
  **projected** unit counts. Where it did, multiply the per-location driver by that
  forward count. Where **no location build exists** (or it did not project counts), use
  the **§3.2 fallback**: the driver is `% of Total Costs`, so the forward value is `% of
  Total Costs × Total Costs and Expenses`. Do **not** invent a forward location count.
- **`Total Current Operating Liabilities`** — unchanged formula: the same `= SUM(...)`
  carried into each forward column (black, sum-bar), summing the computed forward
  values.
- **Added / issuer-specific liability lines.** Invert the driver against the base the
  map's row gives: a days driver `÷ 365 ×` its base, a share driver `×` its base.

### 7.4 — Net Working Capital (forward) — carry the formulas forward

Both NWC lines need **no new logic** — carry their historical formulas straight into
every forward column:

- **`Net Working Capital (NWC)`** = `<Total Current Operating Assets, this col> −
  <Total Current Operating Liabilities, this col>` (black, sum-bar, **signed** — leave
  it negative if that is what the cash-business math gives, exactly as in history).
- **`Change in NWC`** = `<NWC, this col> − <NWC, the immediately prior column>`. There
  is **no blank in the forward columns**: only the **first historical** year is blank.
  For `N+1` the prior column is the last historical year, so the chain continues
  seamlessly across the historical/projection boundary (`Change(N+1) = NWC(N+1) −
  NWC(N)`).

### 7.5 — Forward checks

Verify with live formulas (not by eye) before declaring the projection done:

- **Styling.** Every forward **driver** cell is **red**; every forward **value**,
  both totals, the NWC line, and `Change in NWC` are **black live formulas**. No green
  inputs and **no hyperlinks** appear in the forward value rows (they are computed, not
  pulled from deepKPI).
- **Inversion is internally consistent.** Each forward value uses the **same base** its
  historical driver used as a denominator, in the **same column** — the base the
  industry map names: a days driver `÷ 365 ×` its base; a share driver `×` its base;
  the per-location driver `×` the company-operated count. (A quick
  proof: re-deriving the driver from the projected value — value ÷ base × day-count —
  returns the red driver exactly.)
- **Totals foot forward.** `Total Current Operating Assets = SUM(asset lines)` and
  `Total Current Operating Liabilities = SUM(liability lines)`, every forward column.
- **NWC chains across the boundary.** `Change in NWC` references the immediately prior
  column in every forward period, with `N+1` reaching back to the last historical NWC;
  no forward cell is blank.
- **Project only where upstream did.** Every forward column references a forward base
  the upstream sections actually laid down; the per-location line is filled only where
  the location build projected counts (else the `% of Total Costs` fallback). No invented
  bases or counts.
- **Drivers stay sane.** Each forward driver is year `N`'s ratio (or the guided or
  normalized figure the seed ladder put there), so it sits in the same band as the
  latest actuals (low DSO/DIO, higher DPO for a cash operator), and forward NWC stays
  the same sign and scale as recent actuals (often still **negative** for restaurants
  — normal). Recalculate and confirm **zero formula
  errors**.

### 7.6 — Worked illustration (projection mechanics)

Each industry driver map closes its §3 worked example with the projection
mechanics on that industry's bases: the red drivers as the latest year (or the guided
value) held flat, each forward balance as the driver inverted against its forward
base in the same column, the held-flat tax balances, and the role flip between the
halves (historically `DSO = AR ÷ Revenue × 365`, the driver derived from the reported
balance; forward, the red `DSO` is the assumption and `AR = DSO ÷ 365 × Revenue`).
Totals, NWC and Change in NWC carry their historical formulas forward unchanged.

---

## Section 8 — Downstream handoff

This is the **final** section of the operating model. After it is laid down,
recalculated, and the checks pass:

- Confirm **zero formula errors**; both totals foot (`= SUM`), the NWC identity holds
  (`= Total Current Operating Assets − Total Current Operating Liabilities`) every
  period, and `Change in NWC` chains off the prior column (blank in the first
  historical year).
- Confirm the **classification** read-through: every line is current AND operating;
  cash, investments, debt, and finance leases are excluded; the operating lease line
  is the current portion; no double-counted accrual.
- Keep the row labels `Total Current Operating Assets`, `Total Current Operating
  Liabilities`, `Net Working Capital (NWC)`, and `Change in NWC` **stable** — they
  are this section's public surface (any later cash-flow bridge or projection
  references them).
- Hand control back to the orchestrator. With Revenue, Costs, Consolidated
  Financials, the Depreciation Schedule, and Net Working Capital all built, the
  operating model is **complete** — report completion to the user.

---

*This build is part of the Revelata operating-model skill set. It writes only the
NET WORKING CAPITAL section (the Current Operating Assets and Current Operating
Liabilities walkdowns, their per-line DSO / DIO / DPO / % / per-location drivers, and
the NWC and Change-in-NWC lines); it does no industry routing — it reads one industry
driver map for its driver bases — pulls only the current-operating balance-sheet
series it needs, references the upstream rows the map names, and never edits another
section. Revenue, costs, consolidated financials, the
depreciation schedule, and all other sections are owned by their respective skills.*

## Dependencies — rows this build references but does not lay

Per `../SKILL.md` Step 4.2: this build may report a row as missing upstream only if it is
listed here, its condition evaluates true, and no row in the owner's module matches it.
Condition false means the fallback, not a finding.

| Row (as referenced here) | Owner | Exists when | Fallback when the condition is false |
|---|---|---|---|
| `Total Revenue` (`rev_total`) | revenue build | always | none — stop |
| `Total Costs and Expenses` (`tce`) | cost build | always | none — stop |
| each cost line the cost build seeds at zero forward (keys as the cost hand-back's zero-seeded list names them), for `Total Costs and Expenses (recurring)` | cost build | the cost hand-back lists at least one such line that is non-zero in a historical column | the recurring row is not laid; every cost-based driver uses `Total Costs and Expenses` |
| `Company-Operated EOP Balance` (`coeop_total`) for the lease driver | location build | the revenue hand-back report shows a location build ran | the industry map's stated fallback |
| the cost-of-sales line and the labor line, under the issuer's captions | cost build | per the industry driver map (`restaurants/`, `retail/`, `software/`) | the map's stated fallback (`Total Costs and Expenses`), noted as one |
