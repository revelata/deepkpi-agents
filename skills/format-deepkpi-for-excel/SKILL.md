---
name: format-deepkpi-for-excel
description: >
  Canonical Excel (.xlsx) layout and styling for deepKPI financial exports: 
  wide layout, annual then quarterly columns, Calibri, green input cells, hyperlinks,
  numeric date headers, freeze panes, column grouping, no redundant Source rows;
  derived cells must be live formulas, never hardcoded computed values.
  Use whenever building a spreadsheet from deepKPI data — after any tool such as
  retrieve-kpi-data, analyze-seasonality, derive-implied-metric that sources data
  from deepKPI. Pair with the xlsx skill for implementation. 
---
# format-deepkpi-for-excel

**In-chat** KPI tables stay **tall** (periods as rows). **Excel** workbooks are
**wide** (periods across columns) for modeling. This skill is the **single source of
truth** for deepKPI `.xlsx` structure and visuals.

Always invoke the **xlsx skill** for spreadsheet output — it governs formula
discipline, tooling, and general conventions. The sections below add **financial /
deepKPI-specific** requirements on top.

## DeepKPI Excel export spec

Use whenever the user wants a **file** (or accepted a post-pull `.xlsx` or `.csv` 
offer).

### Sheet defaults (apply to the whole workbook)

- **Font:** **Calibri** for the sheet. **Provenance hyperlinks** use the same
  **green** as input text (`#00B050` / `FF00B050`), **not** default blue — see
  **Hyperlinks** below.
- **Gridlines:** **Off** — the worksheet should present with **no visible cell
  grid** (Excel: gridlines hidden for the sheet).
- **Empty data cells** (no value for that period): show a **dash** (`-` or
  accounting-style em dash), not a blank cell — consistent for the data region
  (period columns from Col E onward, and any comparable body area).

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
  date columns** when multiple deepKPI series are the **same KPI** (same metric,
  unit, aggregation); **split into separate rows** when they differ. Do not
  fragment one series into "Revenue - Q1" / "Revenue - Q2" rows. **Each value
  lands in the column that matches its reporting period;** Col A may list multiple
  deepKPI source strings if you merged series (or keep one canonical label in C).
- **Derived blocks:** **operand** (input) series as **separate rows** above;
  **derived** row **last** in that block. Derived cells use **black** font and no
  green input styling — and **must** hold **live `=` formulas**, never typed
  results (see **Derived values — formulas only** below).
- **Time periods flow left to right** within each block. Row labels in column A.
- **Three-column label system**:
  - Col A (hidden): deepKPI metric name string — serves as audit trail
  - Col B: Display label (what users see)
  - Col C: Units tag, italic (e.g., `(in thousands)`)
  - Col D onward: time-period data values
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
- **Annual and quarterly column blocks:** **Annual columns first** (FY2017,
  FY2018 … or 4-digit year labels), left → right, oldest first. Then **one blank
  column**. Then **quarterly columns** (Mar-22, Jun-22, Sep-22, Dec-22 …), left →
  right, oldest first. Do **not** put quarterlies before annuals.
- **Column outline / grouping (expand–collapse):** Create **two** separate Excel
  **column groups** (outline) so the user can **collapse or expand** the **annual**
  block vs the **quarterly** block: (1) group **only** the contiguous **annual**
  period columns (including the date header row for those columns); (2) group
  **only** the contiguous **quarterly** period columns. Leave the **blank separator
  column ungrouped** (between the two groups). Columns **A–D** are **not** grouped.
  Match Excel **Data → Group** behavior (or your library’s equivalent), e.g.
  openpyxl: set `outlineLevel = 1` on each `column_dimensions` entry spanning the
  annual columns, then again for the quarterly span (**sibling** groups, not one
  nested group). Leave groups **expanded** by default so numbers are visible unless
  the xlsx skill says otherwise.
- **Date header row** (Col E onward): **numeric Excel dates** with display formats
  above (**Mar-22** style for quarterlies); **Bold** and **underlined** font.
  (Calibri.)
- **ALL CAPS section header rows** (e.g. `REVENUE BUILD`): **Bold** and **font
  underlined** (underline the text in Col C for that row; background unchanged
  unless the xlsx skill says otherwise).
- **Color conventions** (Revelata KPI inputs — overriding generic xlsx fill rules
  for this file type):
  - **deepKPI-sourced input values** (“hardcoded” from API): **Font color**
    **`#00B050`** (Excel ARGB `FF00B050`); **fill / background**
    **`#E2EFDA`** (Excel ARGB `FFE2EFDA`). Not the old solid bright-green cell fill.
  - **Derived / calculated formula cells**: **Black** font (default or explicit); no
    green tint unless the xlsx skill differs.
  - **Col A source-label text**: **Blue** `#0070C0` (`FF0070C0`) where still specified below.
  - **Red** `#FF0000` (`FFFF0000`): estimated or external values (use sparingly)
- **% change rows**: italic label + italic data, formatted as accounting-style %:
  `_(* #,##0.0%_);_(* \(#,##0.0%\);_(* "-"?_);_(@_)`
- **Number format** for all data values (accounting with dash for zero):
  `_(* #,##0_);_(* \(#,##0\);_(* "-"_);_(@_)`
- **Subtotals**: bold; last item before total gets a thin bottom border.
- **Grand totals**: bold, double top border.
- **Sub-items**: indent label in Col C with two leading spaces.

```
Col A (hidden)            | Col B | Col C                  | Col D          | FY2022       | FY2023       |   | Mar-22       | Jun-22       | Sep-22       | Dec-22       | … |
--------------------------|-------|------------------------|----------------|--------------|--------------|---|--------------|--------------|--------------|--------------|---|
                          |       | REVENUE BUILD          |                |              |              |   |              |              |              |              |   |  ← ALL CAPS bold + underlined
revenue; quarterly ($)    |  33   | Revenue                | (in thousands) | -            | -            |   | [248,017] inp| [300,941] inp| [292,246] inp| -            | … | ← inp = green #00B050 text, fill #E2EFDA
revenue; annual ($)       |  34   | Revenue (annual)       | (in thousands) | [1,196,826] inp| [1,383,600] inp|   | -            | -            | -            | -            | … |
                          |  35   |   % YoY                |                |   +15.6%     |   +12.5%     |   |     n/a      |   +21.1%     |   +15.2%     |              | … | ← italic
                          |       | Q4 Revenue             | (in thousands) | -            | -            |   | -            | -            | -            | [355,622] drv|   | ← drv = derived, black font
```

*(Legend: **row 2 blank** between **C1** title and headers; date header row —
**numeric** dates, bold + underlined; empty inputs — `-`; **C1** = bold 12pt title
with full company name; **A1:B1** empty.)*

### Derived values — formulas only

**Every derived value** (anything computed from other cells: Q4 as FY − Q1 − Q2 − Q3,
YoY or other growth rates, subtotals, seasonal ratios, projected quarters, segment
remainders, per-unit metrics, etc.) **must** be implemented as an Excel **`=`
formula** that references the relevant input cells.

**Never** type, paste, or “hardcode” the computed number into a derived cell — even if
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
  “10-K FY2024” unless that is the value shown.
- **Style:** **Font color** **`#00B050`**
  (`FF00B050`) to match prescribed green — **not** default hyperlink blue.
  **Underline:** **none** (e.g. `underline=None` in openpyxl `Font`) — avoids
  Excel’s default underlined link look and layout quirks when **right-aligned** in
  the cell.
- **Calibri** for link text unless the xlsx library requires a Font pass on the cell.

```python
# Example: openpyxl — provenance link; green text, no underline (e.g. when right-aligned)
cell.value = "248,017"  # or numeric + accounting format; link attaches to this cell
cell.hyperlink = "https://exact-url-from-deepkpi"
cell.font = Font(name="Calibri", color="FF00B050", underline=None)
```

Alternatively `=HYPERLINK("url","display")` — still apply **green** font and **no
underline** on that cell to match the spec (may require cell style after formula).

Never store a provenance URL as **plain text only** in the data grid.

**CSV:** Cannot store hyperlinks. Add a `provenance_url` column with raw URL
strings, and warn the user that links are not clickable — recommend .xlsx.

### Pre-delivery checklist (Excel output)

Before presenting the file link, verify every item. Do not deliver the file until all boxes pass.

- [ ] No spurious row fragmentation (no "metric - Q1" rows); merged same-KPI
      series = one row; distinct KPIs = separate rows; operands before derived
- [ ] **Annual columns are the left block**, blank separator, **quarterly columns
      on the right** — not the reverse
- [ ] **Column groups** defined: **annual** block and **quarterly** block each
      collapsible via outline (separator + cols A–D **outside** groups)
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
- [ ] **Hyperlinks**: **green** `FF00B050`, **no underline**, not blue
- [ ] **Empty** data cells show a **dash** (not blank) in the data region
- [ ] **deepKPI input** cells: font **`#00B050`**, fill **`#E2EFDA`**
- [ ] **Derived** cells: **black** font (no green input styling); formulas live
- [ ] Every derived value is a live `=` formula referencing input cells — no hardcoded numbers
- [ ] Number format `_(* #,##0_);_(* \(#,##0\);_(* "-"_);_(@_)` applied to data cells as applicable
- [ ] Every deepKPI-sourced cell has an actual Excel hyperlink (not a plain-text URL string)
- [ ] **ALL CAPS** section headers: **bold** and **underlined**
- [ ] **Col C** display labels: **one** naming pattern sheet-wide; **prefer** em dash
      or hyphen over **parentheses** for qualifiers; abbreviations only when
      **industry-standard** (e.g. ARPU), not opaque codes (e.g. BOC)
- [ ] Col A (deepKPI metric name) and Col B (index) are hidden

## Common failure modes (Excel)

- **Extra Source rows**: filing identity lives in the **cell hyperlink** only.
- **Default blue underlined links** on deepKPI values — use **green**, **no underline**.
- **Text-only date headers** — use **numeric** Excel dates + `mmm-yy` / year format.
- **Quarterly columns before annual** — **annuals left**, blank, **quarterlies right**.
- **Hardcoded derived numbers** — if a cell is computed from other cells, it must
  be a **formula**, not a pasted constant (even if “correct”).
- **Parenthetical KPI labels** (`Name (modifier)`) or **opaque abbreviations** in
  Col C when **dash-separated** names or **spelled-out** words would be clearer.
