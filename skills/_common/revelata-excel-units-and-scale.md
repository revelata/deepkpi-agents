# Units, scale, and number format (model-wide contract)

Every number in this model has **two independent properties**: the value **stored**
in the cell, and the scale it is **displayed** at. Confusing the two is the most
common defect in a delivered model — it produces either an unreadable figure
(`$25,499,000,000` where an analyst expects `25,499`) or a formula that silently
depends on the scale deepKPI happened to deliver a series in.

Every sub-skill inherits this contract. A sub-skill **may** override a display
scale or a tag for a named row or family — see **Precedence** at the end — but
Rule 1 binds every build without exception.

Column references below are the **four-column label system** defined in
`revelata-excel-styling-rules.md`: **Col A** hidden deepKPI string, **Col B**
hidden index, **Col C** display label, **Col D** units tag, **Col E onward** data.

## Rule 1 — Store base units, at full source precision

- Every numeric cell stores its value in the **base unit** of its dimension: money
  in **currency units** (dollars, not thousands or millions), counts in **ones**,
  area in **square feet**, time in **days**.
- deepKPI delivers some series pre-scaled — the KPI name, description, or `unit`
  field will say *in thousands* / *in millions*. **Convert on ingest**, multiply
  back up to the base unit, and store the converted number. Multiplying by 1,000 is
  exact, so no source precision is lost.
- **Never round a converted value to "tidy" it.** Exact integers are what make the
  model's tie-out rows (`Memo: Total − Reported (must = 0)`) come out at exactly
  zero. A rounded ingest makes those checks fail on noise — or, worse, get quietly
  fudged to hide the noise. Rounding at ingest is destructive and is never done.
- **Never re-key a value to make the display look right.** Do not write `3,555`
  because the row should read in millions. Store `3,554,985,000` and let the number
  format do the work (Rule 3). **Worked examples in the sub-skills — tables and numeric
  walkthroughs alike — show the displayed figure, never the stored value.** Read
  `3,200` under `(USD in millions)` as a cell storing `3,200,000,000` with the
  two-comma format applied. Displayed-scale arithmetic is exact because sums,
  differences, `% × money` and ratios are scale-invariant; the one exception is a
  declared coherence departure (Rule 2), whose walkthrough must write the scale step
  out so the equation still computes.
- **Consequence — this is the point of the rule.** Because every row sits on the
  same base, **cross-row formulas are plain arithmetic**: `= Revenue / Stores` is
  dollars per store, `= Revenue / SqFt` is dollars per square foot. No correction
  factor is ever required. **A formula that needs `*1000` or `/1000` to come out
  right is proof that Rule 1 was broken upstream** — fix the stored value; never
  paper over it with a constant in the formula.
- **This deliberately departs from the sell-side storage convention.** Analyst-built
  models normally store the *displayed* figure — `2,659` in a millions-denominated
  sheet — so the formula bar matches the display. Here the cell holds
  `2,659,125,000` and millions is a display format. That convention exists because
  such models are keyed by hand; these values arrive from deepKPI and are never
  typed, and the cells an analyst does edit (percentages, days, per-unit prices) are
  stored at their display scale either way. What the convention cannot do is carry
  money, unit counts, square footage and store counts on one sheet and divide them
  by each other without a bridging constant in every mixed ratio — the defect this
  rule exists to prevent. This is a deliberate choice, not an oversight: do not
  revert it to display-scale storage without also revisiting Rules 3 and 5.
- **Provenance comments name the source's own scale.** A filing usually reports in
  thousands while the sheet displays millions, so an analyst following a provenance
  hyperlink meets a third magnitude. Where a value carries a provenance link, the
  comment states the source's scale — e.g. `filing reports in thousands` — so the
  difference is explained rather than discovered.

## Rule 2 — Choose one display scale per row family

A **row family** is the set of rows measuring the same dimension that a reader adds
up or compares down a column: all the money rows in a section, all the store-count
rows in a roll-forward, all the square-footage rows in a block.

- **Every row in a family displays at the same scale.** If two rows are summed, or
  one is a subtotal of the others, they **must** share a scale. A total that does
  not visually match its components is a failed build.
- Scale is **never** chosen per individual row, and **never** chosen once for the
  whole sheet. Per-row choice is what produces revenue columns that don't add up; a
  single sheet-wide scale would render 20,594 stores as `0.02`.

**Class A — fixed by convention.** These never vary with company size:

| Family | Display scale |
|---|---|
| Per-share amounts | ones, 2 decimals |
| Per-unit money (per store, per sq ft, per order) | ones, decimals at natural precision |
| Percentages and margins | percent, 1 decimal |
| Days, years, multiples | ones, 1 decimal |
| Basis points | ones |

**Class B — chosen by the digit test, then declared in the tag.** Apply the
**digit test**: pick the scale that makes the **largest value in the family read
with three to six digits**.

| Family | Usual landing point | Varies when |
|---|---|---|
| Money magnitude | **millions** | a company small enough that millions reads in 1–2 digits takes thousands |
| Store / location / customer counts | ones | a count in the hundreds of millions (users, members) takes millions |
| Square footage | thousands or millions of sq ft | a large fleet reads better in millions; a small-format retailer in thousands |
| Units / volume sold | thousands or millions | same reasoning as square footage |

Money is expected to land on millions for essentially every filer in scope — that
is a **default**, not a constant. Square footage and units sold are **not** pinned
to a scale: a 151mm sq ft fleet reads well as `151,095` in thousands or `151` in
millions, while a 2mm sq ft specialty retailer reads `2,000` in thousands, which is
clearly better than `2`.

**Coherence — scales are not chosen independently where one row divides another.**
When a ratio
row exists, `numerator scale ÷ denominator scale = ratio scale`. Choose the
denominator's scale so the **displayed** operands divide to the **displayed** result —
otherwise the reader cannot verify the row against the two rows it comes from, even
though the formula is correct. Work backwards from the ratio: money in millions over a
count in millions gives a plain per-unit figure; money in millions over a count in
thousands gives a per-unit figure in thousands.

Depart from this **only** where the ratio's conventional unit is the one an analyst
quotes — a used-vehicle ASP is `$26,000`, not `26.0` — and **record it in the row's Col
C comment as a declared coherence departure**. The test for a legitimate departure is
whether rescaling the *denominator* would make the denominator itself unreadable or
unconventional. A 701.7 million sq ft fleet reads perfectly well, so square footage has
no claim to an exception; a vehicle price of `26.0` does not, so it has one.

### Rule 2b — Families not listed here

The tables above are **illustrative, not exhaustive**. The model will meet
dimensions they do not name — AUV, comparable-sales growth, ARR, RPO, bookings,
take rate, headcount, retail weeks, attach rates, inventory turns. For any such
dimension:

1. Store base units (Rule 1).
2. Pick the display scale by the digit test (Rule 2, Class B), unless the dimension
   is inherently unscaled — ratios, rates, and per-unit figures are Class A.
3. Generate the tag as `(<unit>)` when the scale is ones, or `(<unit>, in <scale>)`
   when scaled.

**Never leave a row untagged**, and **never apply the money format to a non-money
row**. An unlisted family is exactly where a free-formed tag creeps in.

## Rule 3 — The number format is derived, not chosen

The format follows mechanically from the stored base (Rule 1) and the display scale
(Rule 2). Because Rule 1 guarantees money is stored in currency units, the money
format is **always two commas**.

| Display scale | Accounting format |
|---|---|
| Money in millions | `_(* #,##0,,_);_(* \(#,##0,,\);_(* "-"_);_(@_)` |
| Money in thousands | `_(* #,##0,_);_(* \(#,##0,\);_(* "-"_);_(@_)` |
| Counts / ones | `_(* #,##0_);_(* \(#,##0\);_(* "-"_);_(@_)` |
| Per-unit money | `_(* #,##0.00_);_(* \(#,##0.00\);_(* "-"_);_(@_)` |
| Percent | `_(* #,##0.0%_);_(* \(#,##0.0%\);_(* "-"?_);_(@_)` |

- **Decimals are derived from the inputs, once per family.** A money family shows one
  decimal (`#,##0.0,,`) when any historical input in it is not a whole number of the
  display unit — an issuer that reports in thousands, or to a tenth of a million, in
  a millions column — and whole units otherwise. The issuer's own reporting precision
  therefore sets the display, which is the convention. The renderer derives this
  from the stored inputs and overrides any format a stage passed; the audit's family
  check verifies it.
- **The format is a property of the row, applied across the entire data region** —
  including dash / empty cells and cells a projection will fill later. **No data
  cell may be left on `General`**: a formula that later lands in one renders
  unscaled and silently breaks the family.

## Rule 4 — Every data row carries a units tag in Col D

- **No data row ships without a tag.** A blank Col D on a row that has values is a
  failed build.
- **"Data row" means any row carrying values — not just the primary reported
  series.** Three kinds are routinely missed and are explicitly in scope:
  - **Percent rows** — margins, `% of revenue` / `% of opex` drivers, and every
    `YoY %` row. A block title such as `Consolidated Costs — % of
    revenue` does **not** tag the rows beneath it: a title row declares a property
    for a whole block, which fails as soon as the block mixes denominators, exactly
    as a units banner does. Each row declares its own.
  - **Reported-comparator memo rows** (`Memo: Reported Total Revenue`,
    `Reported ARPU (memo)`) — these hold real deepKPI values and are tagged like any
    other row of their family. A scale mismatch between a modeled row and its
    comparator is precisely what the memo exists to catch, so the comparator must
    declare its scale.
  - **Tie-out memo rows** (`Memo: components − Total (must = 0)`) — tagged with the
    family of the difference they compute, normally money. The value is zero when
    the check passes, so the tag looks redundant; it is not, because the tag is what
    makes a **non**-zero residual readable, and that is the only case anyone opens
    the collapsed memo group to look at.
- The tag is **generated** from the dimension and the display scale chosen in
  Rule 2. It is not free text, and it is not a place for provenance notes or
  commentary (`(reported NRM)` is not a unit).
- **A row's dimension is not a choice.** For a deepKPI input row it is the series'
  `unit` field. For a derived row it is the dimensional result of the formula:
  - money ÷ count → per-unit money;
  - money ÷ money → percent;
  - money ± money → money, and count ± count → count;
  - a balance-sheet **stock** ÷ a per-period **flow** → a span of time in the flow's
    period: years in an annual model (e.g. Net PP&E ÷ D&A), or days where the formula
    multiplies by 365 (e.g. DSO).

  A sub-skill therefore never decides which rows are money or percent; it shows the
  resulting tag beside each row in its layout blocks and states only the display-scale
  decisions the contract cannot derive — which per-unit rows take a scaled unit, and
  which rows are declared coherence departures.
- **Money family — the template is `(<ISO> in millions)`:**
  - Use the **ISO 4217 code**, never the currency symbol. `$` is shared by USD,
    CAD, AUD, HKD, SGD and MXN; a symbol cannot distinguish them.
  - **Default to `USD`.** Override when the deepKPI KPI name, description, or
    `unit` field explicitly names another currency, and then use that code for
    every money tag sourced from it.
  - The code carries through the whole money family: `(USD in millions)`,
    `(USD per share)`, `(USD per store)`, `(USD per sq ft)`.

| Row kind | Tag |
|---|---|
| Money, millions | `(USD in millions)` |
| Money, thousands | `(USD in thousands)` |
| Per share | `(USD per share)` |
| Per unit | `(USD per store)`, `(USD per sq ft)`, `(USD per order)` |
| Scaled per unit | `(USD thousands per store)` |
| Counts | `(stores)`, `(customers)`, `(users)` |
| Scaled counts | `(units, in millions)`, `(sq ft in thousands)` |
| Percent | `(% of total revenue)`, `(% of GOV)` |
| Other | `(days)`, `(years)`, `(bps)`, `(x)` |

## Rule 5 — Ratio, per-unit, and percent rows

- A ratio row divides its operands **directly**: `= <numerator> / <denominator>`.
  Under Rule 1 no scale constant is ever needed, and none may be written.
- The ratio's **own** display scale follows Rule 2 — natural dollars with decimals
  in almost every case.
- The tag declares **both** sides: `(USD per store)`, `(USD per sq ft)`.
- **Percent rows** store the **decimal fraction** (`0.0671`, not `6.71`) and use the
  percent format. **The tag names the denominator** — `(% of total revenue)`,
  `(% of GOV)`, `(% of total opex)` — taken from the row's own formula denominator.
  A bare `(%)` is reserved for rows whose denominator is **intrinsic to the row
  itself**, which in practice means `YoY %` (the same row, prior
  period). It is not a shortcut for "the denominator is obvious from context".
- Where the row's **label** already names the denominator (`Accounts payable —
  % of OpEx`), keep the label as it is and tag the row anyway. The label is the
  row's name, the tag is its unit; the overlap is deliberate, and stripping the
  label would collide with the money row of the same name.
- **Never scaled to millions:** per-share amounts, per-unit prices, percentages,
  days, years, and multiples.

## Rule 6 — The unit audit (executed in the final QC pass)

These are the checks the final QC pass runs. They are defined here and executed by
the calling skill's final QC step — for the operating model, **Step 5 — Final QC
and correction pass** — after every section has been built, because the most
valuable checks are cross-section and invisible from inside a single sub-skill.

1. **Tag completeness** — every row with values has a Col D tag, using Rule 4's
   definition of a data row: percent rows, reported-comparator memos and tie-out
   memos all count, and a block title row does not tag the rows beneath it. The
   **period header row** is not a data row — its cells hold dates, which are stored
   as numbers and will otherwise register as an untagged row.
2. **No `General`** — no cell in the data region is left on the `General` format.
3. **Family consistency** — within each family every row shares one display scale,
   and every subtotal visually matches the components above it.
4. **No scale constants** — no formula contains a bare `*1000`, `/1000`, or
   `*1000000`. Distinguish the two kinds of constant: a **dimensional** constant is
   part of the metric's definition and is expected (`×365` converting a ratio into
   days, `×12`, `×4`); a **scale** constant only bridges a mismatch between how two
   rows were stored, and means a stored value is wrong (see Rule 1).
5. **Dimensional check on every ratio row** — (numerator tag) ÷ (denominator tag) =
   (ratio tag), e.g. `(USD in millions) ÷ (sq ft in millions) = (USD per sq ft)`.
   Where the units do **not** cancel, the row's Col C comment must state that the
   conventional display was chosen over reconcilability, per Rule 2. A non-canceling
   row with no such comment is a **failed build** — fix the denominator's scale.
6. **Magnitude spot-check** — for the largest money row, confirm that
   `displayed value × scale = stored value`, and that the stored value matches the
   figure as filed.

## Precedence

This contract is the **default for every section of the model**. A sub-skill
overrides it **only** where that sub-skill's own file states an explicit,
contradicting rule for a **named** row or row family; absent such a statement, the
rules above govern.

An override may change a **display scale** or a **tag**. **No override may break
Rule 1** (base-unit storage, no rounding at ingest) or introduce a scale constant
into a formula.
