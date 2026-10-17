# Revelata Excel styling rules

Canonical Excel (.xlsx) layout and styling for deepKPI financial exports: wide
layout, annual then quarterly columns, Calibri, pale-green fill on deepKPI input
cells, dark-blue hyperlinked numbers, numeric date headers, time series values
as Excel numbers (not text), real cell indents (never leading spaces), freeze
panes, column grouping, no redundant Source
rows; same metric at quarterly and annual frequency (same definition/unit) on
one row across period columns, not two rows; derived cells must be live
formulas, never hardcoded computed values.

Apply whenever building a spreadsheet from deepKPI data. Pair with the **xlsx**
skill for implementation.

**In-chat** KPI tables stay **tall** (periods as rows). **Excel** workbooks are
**wide** (periods across columns) for modeling. This file is the **single source
of truth** for deepKPI `.xlsx` structure and visuals.

Always invoke the **xlsx skill** for spreadsheet output — it governs formula
discipline, tooling, and general conventions. The sections below add **financial /
deepKPI-specific** requirements on top.

## DeepKPI Excel export spec

Use whenever the user wants a **file** (or accepted a post-pull `.xlsx` or `.csv` 
offer).

### Sheet defaults (apply to the whole workbook)

- **Font:** **Calibri** for the sheet. **font size 12** **Hyperlinked value cells** (provenance links)
  use **dark blue** font (`#0563C1` / `FF0563C1`) and keep the **row's own number
  format** (a link never changes a cell's format — see **Hyperlinks**) so they read
  like real links. Other body (non-linked) styling follows **Color conventions**.
- **Gridlines:** **Off** — the worksheet should present with **no visible cell
  grid** (Excel: gridlines hidden for the sheet).
- **Empty data cells** (no value for that period): show a **dash** (`-` or
  accounting-style em dash), not a blank cell — consistent for the data region
  (period columns from Col E onward, and any comparable body area).

### Time series values — store as numbers (not text)

- Any **numeric** value written from deepKPI **time series** (reported actuals,
  imputed amounts, ratios, rates, and other quantitative points) must be stored as
  **Excel number values** (numeric cell type), **not** as text — so sorting, charts,
  `SUM`, and arithmetic work without coercion.
- **Do not** write series values as strings that only *look* like numbers (e.g.
  quote-prefixed cells, padded text, or literals like `"1,234.5"` as the stored
  value). Use a **real numeric** `cell.value` (or equivalent) and apply **number
  format** (currency, percent, thousands, decimals) for display.
- **Percent / basis points:** store the **numeric** magnitude the sheet should use
  (per your convention, e.g. decimal fraction for percent format), still as a
  number — not a text label such as `"15%"` unless the underlying source is
  genuinely non-numeric.
- **Hyperlinked value cells:** the **cell value** remains numeric when the metric is
  numeric; the provenance hyperlink is layered on the cell — do not replace the
  number with a text-only representation. Display them with **dark blue** font and
  the **row's own number format** — the one `revelata-excel-units-and-scale.md`
  Rule 3 dictates for the row's dimension and scale, identical on linked and
  non-linked cells (see **Hyperlinks**).

### Title cell **C1** (not A1)

Columns **A** and **B** are **hidden** (audit trail). A title in **A1** would not
**show** — put the workbook title in **C1** (first visible column). Leave **A1:B1**
empty.

- **C1** is a short **title / description** of the workbook: **bold**, **font
  size 12**, **Calibri**, **normal sentence case** (not ALL CAPS). Include the
  **full official company name** as registered (e.g. from `query_company_id` /
  SEC registrant), plus what the sheet contains (e.g. historical KPIs / deepKPI
  extract). Example shape: `Chipotle Mexican Grill, Inc. — quarterly and annual
  KPI historicals (deepKPI)`. For long titles, merge **C1** rightward across the
  label area (e.g. **C1:D1**) or as needed; do not place the title in hidden
  columns.
- **Row 2 must be empty** — leave the **entire row blank** (no titles, no merged
  filler). This separates the **C1** title from the data block.
- **Row 3** is the first row used for **period headers** (dates in Col E onward) and
  any ALL CAPS section labels that sit on the same row as those headers if your
  layout uses that pattern; **row 4** is the **first** KPI **data** row unless your
  template needs an extra header row (if so, keep **one** blank row still **only**
  between the title row and where dates begin).

### Period column headers (store dates as numbers)

- **Which fiscal years go in Col E onward** is set by the parent or orchestrator skill (e.g., in a canonical **Model
  timeline** section) invoking this set of formatting rules. This section solely governs *how* those period headers are formatted, not
  *which* years they are.
- Do **not** type period labels as plain text in header cells. **Store real Excel
  date serials** in the **date header row** (**row 3** in the default layout: **C1**
  title → blank row 2 → **headers row 3**), in Col E onward, then apply **number format**:
  - **Quarterly columns:** `mmm-yy` (displays **Mar-22**, **Dec-23**, etc.).
  - **Annual columns:** use a consistent year-end (or fiscal year-end) **date
    value** in the cell and format as **`yyyy`** (or equivalent) so it reads clearly;
    do not use text like `FY2022` unless it is still a formatted date number.
- That same header row remains **bold** and **underlined** (font), per layout rules.

### Freeze panes

- Set **freeze panes** so when the user scrolls:
  - The **period header row** (date labels in Col E onward) **stays visible** below
    the title and blank spacer; and
  - **Columns A through D** **stay visible** horizontally.
- **Default row layout:** Row **1** = **C1** title (leave **A1:B1** empty) · Row **2** =
  empty · Row **3** = period headers · Row **4** = first data row → set freeze to
  **`E4`** (top-left of the scrollable grid: first data cell under the date headers,
  right of Col D).
- If you add rows above the date header for extra titles only, still keep **exactly
  one fully blank row** between the last title row and the date header row, then
  freeze at the cell **under** the header row and **right of** column D.

### Layout — revenue build model convention

Format all output spreadsheets as a **revenue build model**:

- **One row per KPI or distinct time series** — use **one row with many
  date columns** when multiple deepKPI series are the **same KPI** (same metric
  definition and **same unit**). **Quarterly and annual variants of the same
  metric** (e.g. `Sales - Olive Garden - 3 Month` and `Sales - Olive Garden -
  Annual`) belong on the **same row**: put **annual** values under the **annual
  column block** and **quarterly** values under the **quarterly** block — **do
  not** put them on two separate rows. Only **split into separate rows** when the
  series truly differ (different definition, unit, segment, or a different metric
  — not merely a different aggregation period). Do not fragment one series into
  "Revenue - Q1" / "Revenue - Q2" rows. **Each value lands in the column that
  matches its reporting period;** Col A may list multiple deepKPI source strings
  if you merged quarterly + annual into one row (or keep one canonical display
  label in Col C).
- **Imputation / gap-fill (same series row):** When you **impute** a missing point
  in an existing stream (e.g. **Q4 = FY − Q1 − Q2 − Q3** because there is no Q4
  10-Q), put the value **only** in **that series' row**, in the **missing period
  column(s)**—as a **live `=` formula** (black font, no green input styling). **Do
  not** add a separate line item such as "Q4 (derived)", "Q4 Revenue", or "Imputed
  Q4" beneath the quarterly row. **Especially in Excel**, the quarterly KPI stays
  **one row**; Q4 cells reference FY and Q1–Q3. **Annual figures for that same
  metric** (same definition and unit, only FY vs quarterly frequency) sit on **this
  same row** in the annual columns — not on a second row. Document imputation in
  **Notes** or an agreed footnote row, not as an extra KPI row.
- **Distinct derived KPIs** (YoY %, margins, segment remainder **as its own metric**,
  build subtotals): **operand** rows above where needed; the **derived KPI** gets
  its **own** row—because it is a **different** line item, not a hole in one stream.
  Those cells are still **live formulas** (see **Derived values — formulas only**).
- **Time periods flow left to right** within each block. Row labels in Col C.
- **Four-column label system**:
  - Col A (hidden): deepKPI metric name string — serves as audit trail
  - Col B (hidden): row index
  - Col C: Display label (what users see)
  - Col D: Units tag, italic (e.g., `(USD in millions)`)
  - Col E onward: time-period data values
- **KPI names (Col C — display labels) — one pattern for the whole sheet:** Before
  filling rows, choose a **single** convention for how **metric + qualifier /
  segment** reads. **Prefer** separating the qualifier with an **em dash or hyphen**
  (`Revenue — Americas`, `Dues - Black Card`) — **avoid** parenthetical modifiers
  (`Metric (segment)`) when a dash-separated label reads naturally. Apply the
  pattern **everywhere** — do not mix styles for parallel constructs (e.g. not
  *Black Card Penetration* on one row and *Dues — Black Card* on another).
- **Abbreviations in Col C:** Prefer **full words**; use abbreviations **sparingly**
  and only when they are **standard in the industry** (e.g. **ARPU**, **ASP**,
  **EPS**). **Do not** use opaque or company-specific codes (e.g. **BOC**, internal
  segment codes) unless the user explicitly asked for that exact label. If a KPI 
  has a specific abbreviation already baked in that you don't recognize, e.g. CCHBC
  then use it as it appears.
- Col A may still hold the raw deepKPI string; Col C should read as a **consistent
  series of human-readable labels**.
- **Annual and quarterly column blocks — only when the invoking skill lays
  quarterly columns.** Where it does: **Annual columns first** (FY2017, FY2018 … or
  4-digit year labels), left → right, oldest first. Then **one blank column**. Then
  **quarterly columns** (Mar-22, Jun-22, Sep-22, Dec-22 …), left → right, oldest
  first. Do **not** put quarterlies before annuals. The **operating-model** skill
  lays **annual columns only** (its Model timeline: four historical and five
  projection fiscal years), so there the annual block is the whole data region —
  no separator column, no quarterly block, and no quarterly column group.
- **Rows are never hidden or collapsed.** A supporting row (a quarterly row summed to an
  annual value) may be placed in a row outline group, left **expanded**; memo and check
  rows are ordinary visible rows. The reader sees every row the model carries.
- **Column outline / grouping (expand–collapse):** Create **two** separate Excel
  **column groups** (outline) so the user can **collapse or expand** the **annual**
  block vs the **quarterly** block: (1) group **only** the contiguous **annual**
  period columns (including the date header row for those columns); (2) group
  **only** the contiguous **quarterly** period columns. Leave the **blank separator
  column ungrouped** (between the two groups). Columns **A–D** are **not** grouped.
  Match Excel **Data → Group** behavior (or your library's equivalent), e.g.
  openpyxl: set `outlineLevel = 1` on each `column_dimensions` entry spanning the
  annual columns, then again for the quarterly span (**sibling** groups, not one
  nested group). Leave groups **expanded** by default so numbers are visible unless
  the xlsx skill says otherwise.
- **Date header row** (Col E onward): **numeric Excel dates** with display formats
  above (**Mar-22** style for quarterlies); **Bold** and **underlined** font.
  (Calibri.)
- **ALL CAPS section header rows** (e.g. `REVENUE BUILD`): **Bold**, **font
  underlined**, and **font size 16**  (underline the text in Col C for that row; background unchanged
  unless the xlsx skill says otherwise).
- **Every header below the five section headers** — a build's section sub-header
  (`Consolidated Revenue`, `Comparable Cohort Revenue`, `Notes`), a brand / banner /
  concept / segment / geography header, an ownership header, a block header — is
  **bold, underlined, size 12, title case**, one level shallower than the line
  items it frames (the block-header rule below). Nothing below the five section headers is size 16 or
  ALL CAPS, and no header is left un-underlined: the hierarchy inside a section is
  carried by indent, not by size and not by withholding the underline. The
  renderer's `subheader()` produces exactly this row. A header row has **no data
  region**: its period cells are empty, never dashes, and it carries no Col D tag. A
  dash marks a data row's empty period, never a header's; the renderer treats any
  row with no cells and no tag as a header and renders it so.
- **Color conventions** (Revelata KPI inputs — overriding generic xlsx fill rules
  for this file type):
  - **deepKPI-sourced input values** ("hardcoded" from API): **fill / background**
    **`#E2EFDA`** (Excel ARGB `FFE2EFDA`). **Font color:** use **`#0563C1`**
    (`FF0563C1`) — **dark blue** — on cells that have an **Excel hyperlink** to
    provenance (so links look like links). Use **`#00B050`** (`FF00B050`) only for
    **non-hyperlinked** sourced numerics if any (rare); default is **dark blue** on
    all linked value cells.
  - **Derived / calculated formula cells**: **Black** font (default or explicit); no
    green tint unless the xlsx skill differs.
  - **Col A source-label text**: **Blue** `#0070C0` (`FF0070C0`) where still specified below.
  - **Red** `#FF0000` (`FFFF0000`): estimated or external values (use sparingly)
- **% change rows**: italic label + italic data, formatted as accounting-style %:
  `_(* #,##0.0%_);_(* \(#,##0.0%\);_(* "-"?_);_(@_)`
- **Number format** is **derived, never chosen**: it follows from the row's
  dimension and display scale per `revelata-excel-units-and-scale.md` **Rule 3**
  (money in millions `_(* #,##0,,_);…`, money in thousands `#,##0,`, per-unit money
  `#,##0.00`, percent as above). The one-comma accounting format with a dash for zero,
  `_(* #,##0_);_(* \(#,##0\);_(* "-"_);_(@_)`, is the **counts / ones** case of that
  table, not a default for all data values.
- **Totals and subtotals — the "sum bar"**: bold, with a **single thin top border**
  across the data columns only (Col E onward). Never a double line, never a bottom
  border on the row above, never a border on the label columns. One visual for every
  total, from a block subtotal to the grand total.
- **Sub-items**: indent the Col C label with the cell's **real indent property**
  (see **Indentation — real cell indent, never leading spaces** below). Never pad
  the label string with spaces.
- **Comments.** An input cell carries **no** comment: its hyperlink and the Col A
  series name are its provenance. A comment sits on an input only when the value is an
  override or on a basis the link does not show. The operand recipe of a formula row
  and the basis of a driver go on the **Col C label cell**, one comment per row.

### Indentation — real cell indent, never leading spaces

**Indentation is applied with the cell's actual indent property** — openpyxl
`Alignment(indent=n)` (`indent=1`, `2`, `3`), the equivalent of Excel's
**Home → Increase Indent** (`Alt, H, 6`) — and **never with leading spaces** in the
label string. This is a hard rule for **every** Col C label on **every** sheet.
Where a build file says "indent once", "indent twice", or "indent level *n*", it
means `Alignment(indent=1)`, `Alignment(indent=2)`, `Alignment(indent=n)` — not two
or four spaces.

Leading spaces are prohibited because:

- The block-header underline (`Font(underline="single")`) draws under the padding
  characters and produces a **ragged rule running left of the text**; a real indent
  shifts the label without adding any underline-able characters.
- Padded labels break `MATCH` / `VLOOKUP` / `XLOOKUP` and any other lookup against
  the label text, and they defeat exact-match comparisons that do not `TRIM`.
- The padding is **invisible in the Excel UI** — a user cannot see, verify, or
  correct a mis-padded row, and Increase/Decrease Indent will not clear it.
- Changing a cell's horizontal alignment leaves the phantom spaces stranded inside
  the string, so the label no longer lines up with anything.

When setting a cell's `Alignment`, **keep the existing `horizontal` / `vertical`
settings and add `indent=n`** — do not construct a bare `Alignment(indent=n)` that
discards the rest, and do not prepend spaces to the string:

```python
# correct
c = ws["C12"]
c.value = "Total Square Footage"          # no padding in the string
a = c.alignment
c.alignment = Alignment(horizontal=a.horizontal, vertical=a.vertical, indent=1)

# wrong
c.value = "  Total Square Footage"        # leading spaces — prohibited
```

**The indent hierarchy is set by row kind, and the renderer applies it.** A block
header sits at level *n*; the line items it frames sit at *n + 1*; the total they
roll up into returns to *n*, bold with the sum bar; a memo or check row sits at the
items' level, *n + 1*; a trend or ratio row that belongs to one line (`YoY %`,
`% of revenue`, days) sits one level deeper than that line. Nested blocks repeat the
pattern: a sub-block header at *n + 1*, its items at *n + 2*, its total at *n + 1*.
A stage gives an indent only to its **headers** — the renderer derives every other
row's indent from these rules — so a build file states hierarchy by nesting headers,
never by indenting data rows.

Any ASCII row map in these skill files uses spaces only to **draw** the hierarchy on
the page, two spaces per level. Those spaces are diagram, not data: the renderer sets
the indents.

```
Col A (hidden)            | Col B | Col C                  | Col D          | FY2022       | FY2023       |   | Mar-22       | Jun-22       | Sep-22       | Dec-22       | … |
--------------------------|-------|------------------------|----------------|--------------|--------------|---|--------------|--------------|--------------|--------------|---|
                          |       | REVENUE BUILD          |                |              |              |   |              |              |              |              |   |  ← ALL CAPS bold + underlined
revenue; qtr+FY ($)       |  33   | Revenue                | (in thousands) | [1,196,826] inp| [1,383,600] inp|   | [248,017] inp| [300,941] inp| [292,246] inp| [355,622] drv| … | ← one row: FY block + quarterly block; Q4 imputed = FY−Q1−Q2−Q3 in Dec column, black—not a separate "Q4" row; not a second "annual only" row
                          |  34   |   YoY %                |                |   +15.6%     |   +12.5%     |   |     n/a      |   +21.1%     |   +15.2%     |              | … | ← italic; distinct KPI → own row OK; label indent = Alignment(indent=1), cell value is "YoY %" with no padding
```

*(Legend: **row 2 blank** between **C1** title and headers; date header row —
**numeric** dates, bold + underlined; empty inputs — `-`; **C1** = bold 12pt title
with full company name; **A1:B1** empty. The spaces before `YoY %` above are the
diagram's way of showing one indent level — the stored cell value carries **no**
leading spaces.)*

### Derived values — formulas only

**Every derived cell** must be a live Excel **`=`
formula** referencing inputs. **Imputed quarters** (e.g. Q4 = FY − Q1 − Q2 − Q3) live
in the **same row** as that quarterly series, in the gap column—**not** on a
separate "Q4 derived" row. **Annual and quarterly pulls of the same metric** stay on
that **same row** (annual columns vs quarterly columns), not a second row for "Annual"
only. **Distinct** derived KPIs (YoY %, ratios, remainder
lines, projections) use **their own** rows because they are different series.

**Never** type, paste, or "hardcode" the computed number into a derived cell — even if
it matches what you calculated in chat or in your head. The workbook must
**recalculate** when inputs change; a static numeric literal in a derived cell is a
failure. Only **deepKPI-sourced inputs** (values taken straight from the API) may be
literal values in cells (still with hyperlinks per this skill).

### Hyperlinks — provenance only (no extra Source rows)

Every deepKPI value must carry an **actual Excel hyperlink** on the **value cell** —
that is the filing reference. **Do not** add separate **Source** rows, **Source**
columns, or other redundant blocks that only restate the filing name; the link is
sufficient.

- **Display:** Use the **metric value** (or short label) as the link text, not
  "10-K FY2024" unless that is the value shown.
- **Style (linked value cells):** **Font color** **dark blue** **`#0563C1`**
  (Excel ARGB `FF0563C1`). **Do not** rely on underline to signal links — Excel's
  per-character underline on hyperlinked numbers is unreliable across clients and
  libraries.
- **Number format** on **hyperlinked** numeric cells is the **row's own format** —
  the Rule 3 format the row's dimension and scale dictate, exactly as on the
  non-linked cells beside it (a percent input stored as a decimal fraction, `0.105`
  → 10.5%, takes the same `_(* #,##0.0%_);…` as a derived percent row). A link
  never changes a cell's number format; the **dark blue** font (`FF0563C1`) is the
  link signal, so linked and derived cells in one column render identically.
- **Calibri** on link cells.

Use `cell.hyperlink` + numeric `cell.value`, or `=HYPERLINK("url", …)` with a numeric
cell — apply **font color** and **number format** on the cell as above (not default
hyperlink styling).

Never store a provenance URL as **plain text only** in the data grid.

**CSV:** Cannot store hyperlinks. Add a `provenance_url` column with raw URL
strings, and warn the user that links are not clickable — recommend .xlsx.

### Pre-delivery checklist (Excel output)

Before presenting the file link, verify every item. Do not deliver the file until all boxes pass.

- [ ] No spurious row fragmentation (no "metric - Q1" rows); merged same-KPI
      series = one row; **quarterly + annual for the same metric (same definition /
      unit)** = **one row** (annual block + quarterly block), not two rows; **imputed
      Q4 (etc.) in that row's column**, not a separate "Q4 derived" line item;
      distinct KPIs = separate rows
- [ ] *(skills that lay quarterlies only)* **Annual columns are the left block**,
      blank separator, **quarterly columns on the right** — not the reverse; an
      annual-only skill (the operating model) has one contiguous annual block
- [ ] *(skills that lay quarterlies only)* **Column groups** defined: **annual**
      block and **quarterly** block each collapsible via outline (separator + cols
      A–D **outside** groups)
- [ ] **Calibri** as the workbook body font
- [ ] **Gridlines hidden** (no visible cell grid on the sheet)
- [ ] **C1** (not A1): **bold**, **12pt**, sentence case, **full official company name** +
      data description; **A1:B1** empty (hidden columns)
- [ ] **Row 2** entirely **blank** between title and date headers
- [ ] **Date headers**: **Excel date serials** in cells, formatted **`mmm-yy`**
      (etc.), **not** typed text — **bold** + **underlined** (default: **row 3**)
- [ ] **Freeze panes** at **`E4`** by default (or equivalent: below header row,
      right of **D**)
- [ ] **No** extra **Source** rows/columns for filings — only **hyperlinks** on value
      cells
- [ ] **Hyperlinks** on value cells: **dark blue** font `FF0563C1`; the cell keeps
      the **row's own number format** (Rule 3 of the units contract — a linked
      percent renders exactly like a derived one); **do not** depend on underline
- [ ] **Empty** data cells show a **dash** (not blank) in the data region
- [ ] **deepKPI input** cells: fill **`#E2EFDA`**; **hyperlinked** inputs **dark blue**
      `FF0563C1` per **Hyperlinks**
- [ ] **Derived** cells: **black** font (no green input styling); formulas live
- [ ] Every derived value is a live `=` formula referencing input cells — no hardcoded numbers
- [ ] **Time series numerics** stored as **Excel numbers**, not text strings
- [ ] Number format on every data cell is the row's **Rule 3** format (two-comma
      money in millions, one-comma counts, per-unit `0.00`, percent) — derived from
      the row's dimension and display scale, never chosen by hand; no data cell on
      `General`
- [ ] Every deepKPI-sourced cell has an actual Excel hyperlink (not a plain-text URL string)
- [ ] **ALL CAPS** section headers: **bold** and **underlined**
- [ ] **Indentation** on every Col C label uses the cell's **real indent property**
      (`Alignment(indent=n)` / `Alt, H, 6`) — **no** label string anywhere in the
      workbook begins with a space. Verify programmatically before delivering:
      every Col C `cell.value` satisfies `value == value.lstrip()`
- [ ] Setting indent **preserved** each cell's existing `horizontal` / `vertical`
      alignment rather than replacing the whole `Alignment` object
- [ ] **Block headers** sit at the **same** indent level as their own line items
      (bold + underline distinguishes them, not a deeper indent)
- [ ] **Col C** display labels: **one** naming pattern sheet-wide; **prefer** em dash
      or hyphen over **parentheses** for qualifiers; abbreviations only when
      **industry-standard** (e.g. ARPU), not opaque codes (e.g. BOC)
- [ ] Col A (deepKPI metric name) and Col B (index) are hidden

## Common failure modes (Excel)

- **Faking indentation with leading spaces** — `"  Total Square Footage"` instead of
  `Alignment(indent=1)`. The underline on header rows then runs ragged under the
  padding, lookups on the label fail, and the user cannot see or fix the padding in
  Excel. Use the **real cell indent** (`Alt, H, 6`) every time.
- **Clobbering alignment while indenting** — assigning a fresh `Alignment(indent=n)`
  drops the cell's `horizontal` / `vertical` settings. Read the existing alignment
  and carry those values through.
- **Indenting a data row by hand** — the renderer sets every non-header row's indent
  from its kind; a stage gives an indent only to a header, and only when it nests
  one block inside another.
- **Extra Source rows**: filing identity lives in the **cell hyperlink** only.
- **Green font on hyperlinked values** — use **dark blue** `FF0563C1` and the **percent
  format** (or accounting + blue for non-percent) so links look like links **without**
  relying on underline.
- **Text-only date headers** — use **numeric** Excel dates + `mmm-yy` / year format.
- **Text-stored time series values** — numeric KPI points must be **Excel numbers**,
  not strings; use number format for display, not text that mimics a number.
- **Quarterly columns before annual** — **annuals left**, blank, **quarterlies right**.
- **Hardcoded derived numbers** — if a cell is computed from other cells, it must
  be a **formula**, not a pasted constant (even if "correct").
- **Parenthetical KPI labels** (`Name (modifier)`) or **opaque abbreviations** in
  Col C when **dash-separated** names or **spelled-out** words would be clearer.
- **Extra row for imputed Q4** — imputation belongs **in the quarterly series row**,
  not a second row for the same stream.
- **Two rows for quarterly vs annual of the same metric** — if definition and unit
  match and only aggregation differs (e.g. `… - 3 Month` vs `… - Annual`), use **one
  row** with FY values in the annual columns and quarterlies in the quarterly columns.
