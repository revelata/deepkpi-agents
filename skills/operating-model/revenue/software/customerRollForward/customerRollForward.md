---
name: revenue-software-customer-roll-forward
description: >
  Customer roll-forward build for software / technology companies in the
  operating-model workbook. Invoked by the software router
  (`revenue/software/software.md`) BEFORE it routes to a revenue sub-build,
  whenever the shared KPI inventory contains **customer-count or user-count** KPI
  data for the company. Receives the resolved `company_id`, official company name,
  workbook path, the shared KPI inventory, the exact series the router designated
  for it to track (the total customer count for an ARR build; the ARPU anchor —
  MAU, DAU, subscribers — for an ARPU build; the best available total otherwise),
  any series that are breakdowns of it, and the build type the router already
  selected. Lays out a customer
  roll-forward (BOP, Net New Additions, EOP) beneath the `REVENUE` ALL-CAPS
  header — a single consolidated block when only a total customer count is
  reported, or a consolidated block with a `Change from:` bucket bridge plus one
  roll-forward block per customer bucket when the company also discloses a
  breakdown. Pulls series via `search_kpis` against the shared inventory; format
  per ../../../../_common/revelata-excel-styling-rules.md (one row per series,
  derived cells as live formulas) EXCEPT for time scope and column ordering,
  which this build overrides (see §1, "Time scope and column ordering"). Produces the
  customer / user counts that any downstream revenue sub-build (`arrBuild/`,
  `trBuild/`, `arpuBuild/`, `other/`) can reference.
---

# revenue — software — customer roll forward

This is the **customer roll-forward** build for software / technology companies.
It is invoked by the software router (`../software.md`) **before** the router
dispatches to a revenue sub-build, whenever the shared KPI inventory contains
**customer-count or user-count** KPI data for the company. Its job is to lay down
the count roll-forward (BOP, Net New Additions, EOP) on the series the router
designated — the population the following build's metric is defined on — so that
whichever revenue
sub-build runs next — `arrBuild/`, `trBuild/`, `arpuBuild/`, or `other/` — can
reference these customer counts.

By the time control reaches this file, two things are already established and
must **not** be re-litigated:

1. the company **is in the software / technology industry** (decided by the
   parent revenue router, `../../revenue.md`), and
2. **customer-count or user-count KPI data is present** in the shared inventory
   and the router has **designated the series to track** (its Step 3 gate and
   table) — so a roll-forward **is** buildable. Do not re-run the gate, do not
   substitute a different series, and do not conclude mid-build that the data is
   missing;
   if a specific series looks absent, that is a **sourcing** problem to solve
   (see §2.6), not a reason to abandon the build.

**Inputs expected from the router:** resolved `company_id`, official company
name, the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, the **exact series this build is to track** (designated by the
router's Step 3 table: the total customer count for an ARR build, the ARPU anchor
for an ARPU build, the best available total for take-rate / other), the **exact
series that are breakdowns of it**, and the **build type the router already
selected** (`arrBuild/`, `trBuild/`, `arpuBuild/`, or `other/`) so this block can
be laid out directly above the revenue lines that follow it. The designated series
is the consolidated total of this roll-forward; this build never substitutes a
different total (§2.4, step 2).

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and
build with the **xlsx** skill. All conventions there apply here — the
four-column label system (Col A hidden deepKPI string, Col B hidden index,
Col C display label, Col D units tag, Col E onward data), one row per distinct
series, deepKPI-sourced values as pale-green hyperlinked input cells, and
**every** total / derived cell as a live `=` formula (never a hardcoded number)
— **except** for the **time scope** and **column ordering**, which this build
overrides per §1 below.

## Section 1 — Time scope and column ordering (overrides the common styling rules)

These rules **override** the corresponding conventions in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (per the
  mechanics below), then **extends every roll-forward into the projection window**
  following §3 (Projections) near the end of this file.
  Do not fabricate projection values outside that procedure.
- **The customer-count build is ANNUAL.** It is built as a roll-forward across
  **fiscal years**, so this build uses **annual columns only** (one per fiscal
  year, oldest → newest, left → right). Do **not** add quarterly columns to the
  customer roll-forward, **even though software issuers very commonly report
  customer counts every quarter.** The whole model horizon is annual (four
  historical + five projection fiscal years), and the roll-forward must line up
  column-for-column with the revenue build that follows it. (If a later section
  of the workbook is genuinely quarterly, the standard column-ordering rule
  applies there: put annual columns first, then a blank separator, then quarterly
  columns.)
- **Customers are a STOCK, not a flow — never sum quarters.** When only a
  quarterly customer series exists, the **annual EOP is the fiscal-year-end
  (Q4 / FYE) value of that series** — the count as of the last day of the fiscal
  year. **Never** add Q1 + Q2 + Q3 + Q4 customer counts to produce an annual
  figure, and never average them. Summing a stock is the single most damaging
  error available in this build: it inflates every EOP roughly fourfold and
  silently corrupts every downstream ARPU / ARR / revenue-per-customer line.
  When an annual EOP is taken from a quarterly series' fiscal-year-end point, say so
  in that cell's comment: `Year-end point of the quarterly series <caption>; not a
  sum of quarters.` It is not a Notes line.
- **Never silently substitute data.** If a deepKPI series for a specific cell is
  a clear data-quality artifact (order-of-magnitude scaling or tagging error), do
  not transcribe it. Prefer a clean alternate deepKPI series; if none exists,
  take the value from the company's 10-K key-metrics disclosure, mark that cell
  distinctly (see §2.8), and add one Notes line: `Revenue: customer counts are taken
  from the 10-K key business metrics; the database series was <scaled / mis-tagged /
  missing>.`

## Section 2 — Customers: the roll-forward

The customer-count build is laid out as a **roll-forward**, not a flat list of
period-end counts. The source of truth is the company's **key business metrics**
disclosure (in MD&A, and often repeated in Item 1), which reports the customer
count **as of the end of each period** — and, for many issuers, one or more
**breakdowns** of that count (spend / ARR cohorts, customer type, product, or
geography).

Which of the two layouts you build depends entirely on **whether a usable
breakdown exists**:

- **No breakdown available** — only a total customer count is reported →
  **Layout A**, a single consolidated block.
- **A breakdown is available** — the total plus one or more cohort / segment
  customer counts that can be resolved into an exhaustive set of buckets →
  **Layout B**, the consolidated block with a `Change from:` bridge, followed by
  one roll-forward block per bucket.

Determine which case applies by working through §2.4
**before** writing any rows. Do not default to Layout A because it is simpler; if
a breakdown exists, Layout B is required.

### 2.1 — Layout A — total customers only

```
  <Population> Roll Forward                                                  [indent 1; bold + underlined block header — the issuer's noun for the counted population: `Paying Users Roll Forward`, `Daily Active People Roll Forward`; `Customer Roll Forward` only when the issuer names none]
    BOP                                         (<customer unit>, in <scale>)  [indent 2; FORMULA = prior FY EOP; blank in the base year]
    Net New Additions                           (<customer unit>, in <scale>)  [indent 2; FORMULA plug = EOP − BOP; blank in the base year]
  EOP                                         (<customer unit>, in <scale>)  [indent 1, bold; SUM-BAR; deepKPI INPUT — reported period-end count]
```

**Row table** (the rows above, as the Step 5 audit reads them; `Lays when` per
`../../../SKILL.md`; bucket rows are templates and are guarded by §4's foot):

| Row (Col C label) | Lays when | Units (Col D) | Cell |
|---|---|---|---|
| `BOP` | | `(<customer unit>, in <scale>)` | `= prior FY EOP`; dash in the base year |
| `Net New Additions` | | `(<customer unit>, in <scale>)` | plug `= EOP − BOP` in history; the driver forward (Layout A), or the bucket blocks' sum (Layout B) |
| `EOP` | | `(<customer unit>, in <scale>)` | deepKPI input, reported period-end count |
| `Change from:` | DATA_DEPENDENT | — | label-only row heading the bucket bridge; Layout B only |

The row order makes the identity **`BOP + Net New Additions = EOP`** read
top-to-bottom. `Net New Additions` is the closing plug; `EOP` is the reported
period-end count.

### 2.2 — Layout B — total customers plus a breakdown

```
  <Population> Roll Forward                                                  [indent 1; bold + underlined block header — the issuer's noun for the counted population: `Paying Users Roll Forward`, `Daily Active People Roll Forward`; `Customer Roll Forward` only when the issuer names none]
    BOP                                         (<customer unit>, in <scale>)  [indent 2; FORMULA = prior FY EOP; blank in the base year]
    Change from:                                                               [indent 2; label row — no values in any period column]
      <Bucket 1>                                (<customer unit>, in <scale>)  [indent 3; FORMULA = Bucket 1 block's Net New Additions]
      <Bucket 2>                                (<customer unit>, in <scale>)  [indent 3; FORMULA = Bucket 2 block's Net New Additions]
  EOP                                         (<customer unit>, in <scale>)  [indent 1, bold; NO sum bar; deepKPI INPUT — reported total period-end count]
    Net New Additions                         (<customer unit>, in <scale>)  [indent 2; FORMULA memo = EOP − BOP; blank in the base year]

  <Bucket 1>                                                                 [indent 1; bold + underlined block header]
    BOP                                         (<customer unit>, in <scale>)  [indent 2; FORMULA = prior FY EOP; blank in the base year]
    Net New Additions                           (<customer unit>, in <scale>)  [indent 2; FORMULA plug = EOP − BOP; blank in the base year]
  EOP                                         (<customer unit>, in <scale>)  [indent 1, bold; SUM-BAR; deepKPI INPUT, or derived — see §2.4]

  <Bucket 2>                                                                 [indent 1; bold + underlined block header]
    BOP                                         (<customer unit>, in <scale>)  [indent 2; FORMULA = prior FY EOP; blank in the base year]
    Net New Additions                           (<customer unit>, in <scale>)  [indent 2; FORMULA plug = EOP − BOP; blank in the base year]
  EOP                                         (<customer unit>, in <scale>)  [indent 1, bold; SUM-BAR; deepKPI INPUT, or derived — see §2.4]
```

Notes on Layout B that are **not** optional:

- **`Change from:` is a label-only row.** It carries no values in any period
  column — the cells are empty, as on every header, and the label is bold and
  underlined. It exists to head the bucket bridge, exactly as written.
- **Each `Change from: <Bucket n>` row references that bucket block's
  `Net New Additions` cell directly** (`=<col><bucket n NNA row>`), so the
  bridge has one definition and cannot drift from the bucket blocks.
- **`Net New Additions` sits BELOW `EOP` in the consolidated block**, indented one
  further level, as a **memo** line. It is `= EOP − BOP`. It is deliberately
  redundant with the `Change from:` rows — that redundancy **is** the footing
  check (see §4; §3.6 for the projection columns).
- **One bucket block per bucket**, laid out **after** the consolidated block, in
  the **same order** as the `Change from:` rows above. Separate each block from
  the next with **one blank spacer row**.
- The **consolidated block never carries its own Net New Additions driver** — the
  drivers live in the bucket blocks. See §3.4.

### 2.3 — Roll-forward mechanics

Every block — consolidated and bucket alike — obeys the identity
**`EOP = BOP + Net New Additions`**. Build the rows so this holds as live
formulas:

- **BOP** of a year is a **live formula** equal to the **prior year's EOP** for
  that same block (chain columns left → right; e.g. `=<prevCol><EOProw>`). The
  earliest / base year has no prior column, so its **BOP is blank (dash)**. Do
  **not** widen the historical window to `N−4` just to seed the base-year BOP —
  the window is fixed at four years and a blank base-year BOP is correct.
- **Net New Additions** is the **closing plug** in the historical columns, a
  **live formula** computed every non-base year as **`Net New Additions = EOP −
  BOP`**. It **can be negative** (net customer churn), and negatives are expected
  and must **not** be floored at zero or "corrected". It is **blank (dash) in the
  base year** (no BOP to difference against). It represents everything that moved
  the balance: gross new logos, less churned logos, plus any acquisition-related
  additions or definition-change reclassifications.
- **EOP** is the **reported period-end count** — a deepKPI input — except for
  **derived buckets**, where it is a formula (see §2.4).
  Because `Net New Additions` absorbs the residual, every block **foots exactly**
  by construction.
- In **Layout B**, the consolidated block's **`Change from: <Bucket n>`** rows are
  formulas pointing at each bucket block's `Net New Additions`, and the
  consolidated **`Net New Additions` memo** is `= EOP − BOP`.
- Every non-input cell (BOP, the Net New Additions plug, the `Change from:` rows,
  the memo, and every derived-bucket EOP) is a live `=` formula — never a
  hardcoded number. After building, **recalculate** (LibreOffice / the xlsx
  skill's `recalc.py`) and confirm **zero formula errors**, then confirm the
  consolidated **EOP** ties to the filing.

### 2.4 — Constructing the buckets — reported, derived, and residual

This is the analytical core of the build, and the step most likely to be done
badly. A "bucket" is a **disjoint** slice of the total customer count. The bucket
set must be **mutually exclusive and collectively exhaustive**: in every
historical year, **the buckets' EOPs must sum exactly to the consolidated EOP**.
Work through these steps in order.

**1. Collect every candidate customer series.** From the shared KPI inventory
(never re-run `list_kpis`), gather every series that counts customers, then
confirm each with `search_kpis`. Read the `unit` field to confirm it is a
**count**, not dollars or a percentage. Candidate families include:

- **Total:** `Customers`, `Total customers`, `Customer count`, `Paying
  customers`, `Active customers`, `Total paying customers`; for a user-count
  population, `Monthly Active Users`, `Daily Active Users`, `Daily Active
  People`, `Active users`, `Paying users`, `Subscribers`, `Members`.
- **Spend / ARR cohorts:** `Customers with ARR > $100K`, `Customers with ARR ≥
  $1M`, `Customers with annualized revenue over $X`, `Customers contributing more
  than $X`, `$100K+ customers`, `Large customers`.
- **Customer type:** `Enterprise customers`, `Commercial customers`, `SMB
  customers`, `Self-serve customers`, `Channel / partner customers`.
- **Product or segment:** `Customers — <Product>`, `<Segment> customers`,
  `Platform customers`.
- **Geography:** `Customers — Americas / EMEA / APAC`, `Domestic customers`,
  `International customers`.
- **Flows (useful for cross-checks, not as buckets):** `Customer additions`,
  `Net new customers`, `Customers added`, `Customer churn`, `Logo retention`,
  `Gross retention`.

**2. Identify the total.** Exactly **one** series is the consolidated total — the
count the breakdown must sum to — and it is the **series the router designated**
(Inputs). Do not substitute a different total because it has a richer breakdown:
for an ARPU build the designated series is the ARPU anchor, and the `EOP` the
ARPU build divides revenue by must be that population. Only where the router
designated no specific series (take-rate / other) and two plausible totals exist
(e.g. `Customers` and `Paying customers`), pick the one the **breakdown is
actually a breakdown of**, confirm by checking that the cohorts are strictly
smaller than it in every year, and record the choice in `BUILD_LOG.md` (the
hand-back report carries the same); the row label carries the issuer's noun.

**3. Discard series that are not partitions.** Drop from bucket consideration:

- **Duplicates** of the total under a different name.
- **Different-definition counts** (e.g. registered accounts vs. paying
  customers) that do not slice the chosen total.
- **Flow series** (additions, churn) — these are cross-checks, not buckets.
- Any cohort that **exceeds** the total in a year — that is a definition
  mismatch, not a bucket; investigate before using it at all.

**4. Resolve nested thresholds into disjoint bands.** This is the most common
trap. Threshold cohorts are **cumulative and nested**, not siblings: `Customers
with ARR > $1M` is a **subset** of `Customers with ARR > $100K`. Stacking them as
two buckets double-counts the largest customers and the buckets will not foot.
Convert them into **disjoint bands** by differencing adjacent thresholds,
highest threshold first:

- Highest band = the highest reported threshold cohort, used as reported.
- Each intermediate band = **(next-lower threshold cohort) − (next-higher
  threshold cohort)**.
- Lowest band = **Total − (lowest reported threshold cohort)**.

**5. Derive the complement — do not skip a bucket just because it isn't
reported.** When the company reports the total and only *some* of the slices, the
unreported slice is **derivable and must be built**. If the filing reports
`Total customers` and `Customers with ARR > $100K` and nothing else, the second
bucket is **`Customers — ARR under $100K`**, whose EOP in every year is the live
formula **`Total EOP − (ARR > $100K) EOP`**. Name it for what it actually is
(the complement of the reported cohort), style its EOP as a **formula** cell
(black font, no fill, no hyperlink — it is derived, not sourced), and give it a
cell comment stating the derivation. **A two-bucket build where one bucket is
derived is the expected outcome for most software issuers** — treat it as the
normal case, not an edge case.

**6. Add a residual bucket if the parts still don't reach the whole.** If the
reported plus derived buckets leave a gap in any year (common with product or
geography breakdowns that omit an "all other" line), add a final bucket labeled
**`Customers — other`** whose EOP is the live formula **`Total EOP − SUM(all
other bucket EOPs)`**. After this step the buckets are exhaustive **by
construction**, in every year.

**7. Fall back to Layout A when there is genuinely no breakdown.** If, after
steps 1–6, the only usable series is the total, build **Layout A** — a single
consolidated block, no `Change from:` bridge, no bucket blocks. Do **not**
manufacture a breakdown out of a flow series, a percentage, or your own
knowledge of the company's customer mix.

**8. Order the buckets deterministically.** Reported cohorts first, in descending
size / threshold order (largest cohort first); then derived complements; then the
residual `Customers — other`, always last. The `Change from:` rows in the
consolidated block must appear in **exactly** this same order as the bucket
blocks beneath.

**9. Verify the partition before building anything else.** For **every**
historical year, confirm `SUM(bucket EOPs) = consolidated EOP`. If it does not
hold, the bucket set is wrong — go back to step 3 or 4 (almost always a nested
cohort treated as a sibling, or a cohort that slices a different total). Do not
proceed to the projection columns with a partition that does not foot.

### 2.5 — Worked example — resolving nested ARR cohorts (illustrative)

*The figures below are illustrative placeholders chosen to show the mechanics —
they are not any real issuer's reported data. Always use the company's actual
deepKPI / filing values.*

Suppose the inventory yields three series: `Total customers`, `Customers with ARR
≥ $100K`, and `Customers with ARR ≥ $1M`, with FY(N) values of **10,000**,
**1,200**, and **200**.

Naively using the two cohorts as buckets gives 1,200 + 200 = 1,400 ≠ 10,000, and
double-counts the 200 largest customers inside the 1,200. Applying step 4 and
step 5 instead yields **three disjoint buckets**:

- **`Customers — ARR $1M and above`** — reported, EOP = **200** (deepKPI input).
- **`Customers — ARR $100K to $1M`** — derived, EOP = `(ARR ≥ $100K) − (ARR ≥
  $1M)` = **1,000** (formula).
- **`Customers — ARR under $100K`** — derived, EOP = `Total − (ARR ≥ $100K)` =
  **8,800** (formula).

These sum to 200 + 1,000 + 8,800 = **10,000**, matching the consolidated EOP, so
the partition foots. The consolidated block then carries three `Change from:`
rows — one per bucket — each pointing at that bucket block's `Net New Additions`.

### 2.6 — Sourcing customer counts — deepKPI series first, then the 10-K key-metrics disclosure

Period-end customer counts are a **required input** for the roll-forward (and for
whichever revenue sub-build runs next). **Never leave an EOP cell blank in a
historical year if the company discloses the count anywhere.** A missing
historical EOP breaks the chain: it blanks that year's Net New Additions, blanks
the next year's BOP, and silently truncates the build.

**Step A — deepKPI structured series (try first, but never stop here).** Search
the shared inventory with `search_kpis` for the patterns in "Constructing the
buckets" step 1. Treat these series as *often partial*: an issuer may have a
customer series populated for only two of the four historical fiscal years, or
carry it only at quarterly frequency, while the annual counts are fully disclosed
in the filing. **A sparse or missing deepKPI customer series does NOT mean the
count is unavailable.** Prefer annual (`- Annual`) series; where only a quarterly
series exists, take the **fiscal-year-end point** as the annual EOP (per "Customers
are a STOCK" above), never a sum.

**Step B — the 10-K key business metrics disclosure (authoritative; always check
the latest 10-K, which carries years `N` and `N−1`; pull earlier filings only where
Step A leaves a gap).** US software registrants disclose customer counts in
**MD&A** under a **"Key Business Metrics"**, **"Key Metrics"**, or **"Key
Operating Metrics"** heading, usually alongside net dollar retention and ARR, and
often repeated in **Item 1 (Business)**. Use the **filing** skill
(`list_sec_filing_markdowns` → `get_sec_filing_markdown`) to pull each relevant
fiscal year's 10-K; do **not** web-search to avoid the call.

Rely on these properties:

- **Each fiscal year's 10-K reports that year's period-end count**, and typically
  the prior year's alongside it — so the latest 10-K checks `N` and `N−1`, and the
  one before it covers `N−2` and `N−3`. Pull a prior-year filing only where Step A
  left that year blank or a §2.7 trap puts its value in doubt.
- **Cohort thresholds are stated in the label itself** ("customers with ARR of
  $100,000 or more") — capture the exact threshold so the derived bands in step 4
  are labeled correctly.
- A **"—"** entry means **zero** — record **0** (display as a dash), not blank,
  so downstream formulas don't return `#VALUE!`.

**Finding the disclosure in the markdown (extraction technique).** Key-metrics
tables render as **space-separated cells on a single very long line**, so a linear
read or `offset`/`limit` paging will not surface them, and a vague search will
miss them. Search the saved markdown with **targeted tokens plus a trailing
capture window** (the numbers follow the header on the same line), e.g. the regex
`Key Business Metrics.{0,600}` (case-insensitive, match-only). If that token does
not hit (filings vary the wording), try, in order: `Key Metrics`,
`Key Operating Metrics`, `customers with ARR`, `customers with annual`,
`Total customers`, `customers as of`, `Dollar-Based Net Retention`. **Do not**
rely on generic phrases like `"our customers"` or `"customer growth"` — they
routinely miss the table and will lead you to the wrong conclusion that the count
isn't disclosed. If `get_sec_filing_markdown` returns output too large to read
inline, search the **saved file** directly with these tokens rather than
abandoning the pull.

**Cross-check before trusting the numbers.** Where the company also discloses a
customer **flow** (net new customers added, or gross adds and churn), confirm the
roll-forward's computed `Net New Additions` matches it for the same year — this
is a direct, independent validation of both the BOP chain and the EOP inputs. If
they disagree, the usual causes are a restated customer definition or an
acquisition; resolve and document it rather than overwriting the plug.

**Provenance & styling for 10-K-sourced counts.** When an EOP value comes from
the 10-K key-metrics disclosure rather than a deepKPI series, style the cell as a
**10-K-sourced input** (gold fill, dark-blue hyperlinked value linked to **that
fiscal year's** 10-K filing URL) and attach a cell comment like *"Source: FY20XX
10-K, MD&A, Key Business Metrics."* Add one Notes line: `Revenue: customer counts
are taken from the 10-K key business metrics; the database series was <scaled /
mis-tagged / missing>.`

### 2.7 — Data-quality traps (check every cell against these)

- **Stock summed as a flow.** The `×4` error described above. If an EOP jumps
  roughly fourfold in one year with no acquisition, suspect a summed quarterly
  series.
- **Nested cohorts treated as siblings.** See step 4 — the buckets will not foot.
- **Restated / redefined customer counts.** Software issuers change the customer
  definition (e.g. counting a parent organization instead of each billing
  account) and restate prior years. Use the **restated** series that spans the
  whole window consistently. If no single consistent series covers the four
  years, **do not silently splice** two definitions into one row — mark the
  affected cells (their comment names the definition each count is on) and add one
  Notes line: `Revenue: the customer definition changed in FY<n> (<old> to <new>);
  counts before and after are not comparable.`
- **Order-of-magnitude scaling artifacts** (a 1,200 tagged as 1,200,000).
  Sanity-check each cell against the series trend and the filing.
- **A cohort exceeding the total** in any year — always a definition mismatch,
  never a real result.
- **Approximate counts.** Some issuers report "approximately 10,000 customers".
  Enter the stated number and say so in that cell's comment: `Issuer reports
  'approximately 10,000'.` Do not invent precision. It is not a Notes line.

### 2.8 — Indentation & styling

- **Global border rule (whole sheet):** **never use a double-lined border
  anywhere.** Every subtotal / total is marked with a **single-lined "sum bar"** — a
  thin top border applied **only across the data columns (Col E onward)** — never a
  double line, and never a bottom border on the row above the total.
- **Block headers** (`<Population> Roll Forward`, and each `<Bucket>` header): **indent
  once** in Col C (`Alignment(indent=1)` — the cell's real indent, never leading
  spaces), **bold and underlined**.
  Blocks are separated by **one blank spacer row**.
- **Main line items** (`BOP`, `Change from:`, `Net New Additions`): **indent twice**
  in Col C — one level deeper than the block header; `EOP`, the block's total, back at
  **indent once**, bold. The renderer sets these from the row's kind (styling rules).
- **Sub-lines** (the `<Bucket n>` rows beneath `Change from:`): **indent three** in
  Col C; the `Net New Additions` memo beneath the consolidated `EOP` in Layout B sits at
  the items' level, **indent twice**.
- **Col D units tag:** every count row carries one — see "Number format and units" below
  for the noun and the scale.
- **Col C label pattern:** one convention sheet-wide — bucket names use an **em
  dash** to separate the metric from the qualifier (`Customers — ARR $1M and
  above`), never parentheses. Spell out cohort thresholds; `ARR` is
  industry-standard and may be abbreviated.
- **`EOP` rows are bold**, and their sum bar is a **single-lined top border on the
  data columns only**: in **Layout A** the single block's `EOP` gets a single-lined
  sum bar; in **Layout B** each **bucket block's `EOP`** gets a single-lined sum
  bar, while the **consolidated block's `EOP`** is **bold with no sum bar** (it is
  the reported total, bridged by the `Change from:` rows, not a column-sum of the
  rows directly above it). **No double-lined borders anywhere**, and **no bottom
  border on the row above a total** — the single-lined sum bar on the total row is
  the only total rule.
- **Horizontal rules never run through the row-header columns.** Every sum bar is
  applied **only across the data columns (Col E onward)**. The **row-header / label
  columns (Col A, B, C, and the Col D units tag) must carry no top or bottom
  border** on any row. Do **not** let a sum bar bleed into the label block: set the
  border on `E`…(last data column) only, and leave `A:D` borderless.
- **Underline is for block headers, not total rows.** Block / bucket headers carry a
  **font underline on the Col C label** (`Font(underline="single")`) in addition to
  bold. **`EOP` total rows are bold only** (no label underline) — their total is
  conveyed by the single-lined sum bar across the data columns. Never draw a cell
  border in the label columns to signal a total; labels never carry borders.
- **deepKPI input** cells (reported EOPs): pale-green fill, dark-blue
  hyperlinked value. **10-K-sourced** cells: distinct fill (e.g. light
  gold) + a cell comment citing the key-metrics disclosure, and the §2.6 Notes
  line. **Formula cells** (BOP, the Net New Additions plug, `Change from:`
  rows, the memo, derived-bucket EOPs, residual EOPs): black font, no fill, no
  hyperlink.
- The `Change from:` label row carries **no values** — every period cell shows a
  dash.
- The `Net New Additions` **memo** line in Layout B is **italic** (label and
  values) to mark it as a memo/tie-out rather than a build line, and carries a
  cell comment stating `= EOP − BOP` and that it must equal the sum of the
  `Change from:` rows.
- The `Net New Additions` **plug** in each block carries a cell comment stating
  its definition (`= EOP − BOP`) and what it captures (gross new logos less
  churned logos, plus acquisition additions and definition reclassifications).
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the two layout blocks of §2.1 and §2.2.** Two points are
  specific to this build:
  - **One family — a count of the issuer's customer metric.** Every data row — `BOP`,
    `Net New Additions`, each `Change from:` line, every `EOP` and the `Net New
    Additions` memo — is a count, so the tag `(<customer unit>, in <scale>)` is filled
    with the noun the issuer's metric uses — `customers`, `users`, `subscribers`,
    `members` — the one noun the issuer settles, because the roll-forward counts
    whatever its key-metrics disclosure counts. Use an accounting **count** format so a
    negative `Net New Additions` displays in parentheses.
  - **The scale is set by the per-unit row that divides by this count, not defaulted to
    ones.** Where a revenue build divides a money row by one of these rows — ARPU by
    `Users`, Average ACV by `Total New Customers` — money scale ÷ count scale = per-unit
    scale, so the count's display scale is chosen to make that division read on the page
    (the contract's Rule 2, coherence): a base in the millions displays `(users, in
    millions)` so ARPU lands in plain dollars; a base in the tens of thousands displays
    `(customers, in thousands)`. Only a count nothing divides by stays in ones,
    `(customers)`. Projection drivers are counts too and keep the same tag.
- **Reading the layout blocks (§2.1, §2.2).** Each row's annotation has two columns,
  left to right: the **Col D units tag in parentheses** — `(<customer unit>, in
  <scale>)` is filled as described above — and the note in **square brackets**: the
  row's real cell indent, then `deepKPI INPUT …` for a pulled value, `FORMULA …` for a
  computed row, plus styling (`bold`, `SUM-BAR`, `NO sum bar`) and where the cell is
  blank. Block headers and the `Change from:` label row carry no tag.

### 2.9 — Pre-delivery checklist (historical roll-forward)

Run this before touching a projection column. Every item is a rule stated above;
verify with **live formulas in the workbook** (not by eye).

- [ ] The layout matches the data: Layout B wherever the inventory or the 10-K gives a
      customer breakdown that partitions the total, Layout A only when §2.4 step 7's
      fallback genuinely applies — and the choice is recorded in `BUILD_LOG.md`, not
      in the Notes (the rows show it).
- [ ] The bucket set is a true **partition** (§2.4 steps 4–6, 9): nested thresholds
      resolved into disjoint bands, the complement derived rather than skipped, a
      `Customers — other` residual block present only if the parts still fall short,
      and `SUM(bucket EOPs) = consolidated EOP` in **every** historical column.
- [ ] Layout B structure per §2.2: `Change from:` is a label-only row (no data in any period cell); each `Change from: <Bucket n>` cell references that bucket block's
      `Net New Additions` directly; the consolidated `Net New Additions` memo sits
      beneath `EOP` and equals the sum of the `Change from:` rows; one bucket block per
      bucket, after the consolidated block, in the same order, one spacer row between.
- [ ] Every `BOP` is a **live formula** equal to the prior column's `EOP` on the same
      line, and the base-year `BOP` and `Net New Additions` cells are **blank (dash)**,
      not zero (§2.3).
- [ ] Every `Net New Additions` plug is the live formula `= EOP − BOP`, so each block
      foots `BOP + Net New Additions = EOP` exactly in every non-base column (§2.3).
- [ ] Every `EOP` is the **reported** period-end count (deepKPI input, or a 10-K
      key-metrics value), except derived and residual buckets, whose `EOP` is the
      formula §2.4 prescribes; no EOP is typed in or back-solved (§2.3).
- [ ] **Customers were treated as a stock**: every annual `EOP` taken from a quarterly
      series is that series' fiscal-year-end point, never a sum or average of quarters,
      and each such cell's comment says so (§2 conventions).
- [ ] Every count came from deepKPI first and was checked against the 10-K key-metrics
      disclosure (§2.6); any cell taken from the 10-K carries the gold override fill, a
      cell comment citing the disclosure, and a matching Notes line.
- [ ] No §2.7 trap survived: no cohort exceeds the total in any year, no ×1,000 scaling
      or cross-tagged series, no restated definition without its Notes line and
      marked cells, no approximate ("approximately 10,000") figure entered without a
      cell comment saying so.
- [ ] Every data row — `BOP`, `Net New Additions`, each `Change from:` line, every
      `EOP`, the memo — carries `(<customer unit>, in <scale>)` in Col D with **one**
      noun and **one** display scale throughout the build (§2.8); block headers and the
      `Change from:` label row carry no tag.
- [ ] Styling per §2.8: block and bucket headers bold + underlined at indent once; line
      items at indent once and sub-lines at indent twice, all by the cell's real indent
      property; `EOP` rows bold with a single-lined sum bar across the data columns only
      in Layout A and in every bucket block, and **no** sum bar on the Layout B
      consolidated `EOP`; never a double line, never a border on Col A–D; deepKPI inputs
      pale-green and hyperlinked; formula cells black with no fill; bucket labels use
      the em-dash pattern; the plug and memo rows carry their comments.
- [ ] After recalculation (LibreOffice / the xlsx skill's `recalc.py`), **zero formula
      errors** and **no circular references**.

## Section 3 — Projections (forecast years)

After the **historical** roll-forward above is laid down, recalculated, and
reconciled to the filing's reported customer count, **extend every roll-forward
into the projection window** before handing back to the router. The projection
window is the **five fiscal years after the last historical year** (`N+1 … N+5`)
per the **Model timeline** in `../../../SKILL.md` — do not redefine it here. Add
these as five more **annual** columns immediately to the right of the historical
annual block, continuing the same left → right, oldest → newest order. The
customer roll-forward stays **annual** in the projection window too; do **not**
add quarterly projection columns.

### 3.1 — The driver inversion (historical vs. projection)

This is the one structural difference between the two halves of each
roll-forward — it **flips which cells are inputs and which are formulas**:

- In the **historical** columns, the **EOP is the reported input** (deepKPI /
  10-K) and **Net New Additions is the closing plug formula**
  (`Net New Additions = EOP − BOP`).
- In the **projection** columns this **inverts**: **Net New Additions becomes the
  forward driver** (an assumption input the modeler sets), and **EOP becomes the
  formula** (`EOP = BOP + Net New Additions`).
- **BOP stays a formula in both halves** — always equal to the prior period's EOP.

So in each projection column, for **every block that carries a driver** (see §3.2 and §3.3 for which blocks those are):

- **BOP** — **formula**, `= prior period EOP` for that same block (chain left →
  right, `=<prevCol><EOProw>`). For the first projection year (`N+1`), BOP equals
  the **last historical year `N` EOP**, so projections pick up exactly where the
  actuals end with no gap.
- **Net New Additions** — **driver** (assumption input), one cell per projection
  year. In the projection columns it is **no longer a plug**: it is set directly
  as the modeler's forward net-adds assumption (still can be negative). Seed it by
  the default seed (`../../../SKILL.md`, Build mechanics): the **guided** figure
  where the guidance table carries net additions or an ending count for this block's
  population for `N+1`, written with `drivers_fixed()` and hyperlinked to the
  exhibit; else the **latest historical year's** Net New Additions, written with
  `drivers()`. Later years reference `N+1`. A negative latest year carries forward
  negative; the comment says which rung set the seed.
- **EOP** — **formula**, `= BOP + Net New Additions`.

### 3.2 — Derived and residual buckets stop being subtractions in the projection columns

A **derived** bucket (`Total − cohort`) or a **residual** bucket
(`Total − SUM(other buckets)`) has a formula EOP in the **historical** columns.
In the **projection** columns that formula would be **circular** — the projected
consolidated EOP is itself built up *from* the buckets — so it must not be
carried across.

In the projection columns, **every bucket becomes a normal driven roll**:
its **Net New Additions is a driver** and its **EOP is `BOP + Net New
Additions`**, exactly like a reported bucket. Derivation applies to the
historical half only. Add one Notes line so the inversion is visible to whoever
picks up the model: `Revenue: in the forecast each customer bucket has its own
net-additions assumption; in history the <bucket> count is the remainder of the
total.` Confirm after recalculation that the workbook reports **no circular
reference**.

### 3.3 — Drivers are the only projection inputs; everything else drags across

The **only** cells you type values into in the projection columns are each
driven block's **Net New Additions** row. Every other projection cell is a
**formula dragged across** from the roll-forward identity:

- **BOP** from the prior column's EOP;
- **EOP** from the current column's `BOP + Net New Additions`;
- in **Layout B**, the consolidated block's projection columns are **formula-only
  in both halves**: each `Change from: <Bucket n>` row continues to reference that
  bucket block's `Net New Additions`; the consolidated **`EOP`** becomes
  `= BOP + SUM(Change from rows)` (use `SUM(...)` over the contiguous
  `Change from:` bucket rows, not bare addition, so a dash cell does not throw
  `#VALUE!`); and the **`Net New Additions` memo** stays `= EOP − BOP`. **No new
  drivers appear in the consolidated block.**

Note the second half of the inversion in Layout B: in the historical columns the
consolidated `EOP` is a **reported input** and the `Change from:` rows explain it;
in the projection columns the consolidated `EOP` is **built from** the
`Change from:` rows. That is the only cell in the consolidated block whose nature
changes across the boundary.

### 3.4 — One independent set of drivers per roll-forward

Every distinct roll-forward block that carries a driver carries **its own** Net
New Additions driver — drivers are **never shared** across blocks:

- **Layout A (no breakdown).** There is exactly **one** roll-forward, so exactly
  **one** driver set: the single block's `Net New Additions` row.
- **Layout B (breakdown).** Each **bucket block** is its own roll-forward and gets
  its **own** `Net New Additions` driver, set independently. The **consolidated
  block gets none** — its projected EOP is the sum of the bucket changes on top of
  its BOP. Putting a driver in the consolidated block as well would double-count
  the projected adds and break the partition.
- Therefore the **number of projection driver sets = the number of bucket blocks**
  (Layout B), or **one** (Layout A). For the illustrative three-cohort example
  above that is three driver sets — ARR $1M and above, ARR $100K to $1M, and ARR
  under $100K — each set independently.

### 3.5 — Driver (assumption) cell styling

Mark **every** projection driver cell so it reads as a forward assumption —
visually distinct from both the formula cells and the historical deepKPI input
cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`. Only the
  **driver** cells go red; formula-derived projection cells stay black (see the
  last bullet). Red font is what marks a value as a projected assumption.
- **A dashed box on all four sides of each individual driver cell.** Build a
  `Side(border_style="dashed")` and apply it to **`left`, `right`, `top`, and
  `bottom`** of **every** driver cell, one complete box **per cell** — e.g.
  `Border(left=dashed, right=dashed, top=dashed, bottom=dashed)`. This is a
  hard requirement, and the most common way to get it wrong:
    - **Do not** reduce the box to a single bottom border (or any one/two sides).
      A lone `bottom="thin"` — the subtotal-rule styling from the historical
      columns — is **not** a driver box; if a driver cell shows only a bottom
      border, the styling was not applied and must be fixed.
    - Each driver cell gets its **own** four-sided box; do not draw one rectangle
      around a range and leave interior cell edges open. Adjacent driver cells
      each carry a full dashed box so every individual assumption cell is boxed.
    - Apply the dashed box **after** any shared row-border pass, so a later
      `bottom`-border write cannot overwrite the box's bottom side.
- **No pale-green fill and no hyperlink** — projection drivers are assumptions,
  not deepKPI-sourced actuals, so they do **not** receive the pale-green input fill
  or the provenance hyperlink reserved for historical input cells.
- **Formula** cells in the projection columns (BOP, EOP, the `Change from:` rows,
  the memo) keep the standard formula styling — **black** font, no fill, no dashed
  box — identical to their historical-column formula styling. The red font and the
  dashed box are reserved for the driver (assumption-input) cells alone.

### 3.6 — Checks (projection)

- By construction each projected block **foots** (`EOP = BOP + Net New
  Additions`); recalculate (LibreOffice / the xlsx skill's `recalc.py`) and
  confirm **zero formula errors** and **no circular references**.
- Confirm **`N+1` BOP equals `N` EOP** for every block — the projection joins the
  actuals with no gap or discontinuity.
- In Layout B, confirm the consolidated projected **EOP** still equals
  **`SUM(bucket EOPs)`** in every projection year, and that the consolidated
  `Net New Additions` memo still equals the sum of the `Change from:` rows.

## Section 4 — Final check — buckets reconcile to the total

Before handing back, run one last reconciliation specifically on the customer
counts sourced from **deepKPI and SEC Filing Markdowns**:

- **Verify every bucket count is completely accurate.** For each bucket block,
  re-read the counts taken from deepKPI or the filing markdown and confirm each
  one matches that fiscal year's reported key-metrics figure exactly — no
  transcription, scaling, quarterly-vs-annual, or threshold-band errors per
  bucket.
- **Confirm the parts sum to the whole.** The total of all the individual bucket
  EOPs **must equal** the company's reported total customer count for that year,
  in **every** historical column, and the same must hold for the change bridge:
  `SUM(Change from: rows) = Net New Additions memo = EOP − BOP`. If the bucket
  counts do not add up to the reported total, the build is wrong — fix the
  offending bucket cell(s) before proceeding; do not hand back a build whose parts
  don't foot to the whole.
- **Confirm the consolidated EOP ties to the filing** for every historical year,
  and that the base-year BOP and Net New Additions are blank (dash) rather than
  zero.
- **Confirm the stock/flow rule held**: no annual EOP anywhere in the build was
  produced by summing quarterly counts.

## Section 5 — Hand back to the router

Once the customer roll-forward is laid down, recalculated, and reconciled to the
filing's reported customer count, hand control back to the software router
(`../software.md`) — specifically to its **Step 4**. The router already selected
the build type before invoking this skill; it will now dispatch to that sub-build
(`arrBuild/`, `trBuild/`, `arpuBuild/`, or `other/`), which will reference these
customer counts as needed. This skill does **not** route to a revenue sub-build
itself and is **not** a substitute for one.

Report back to the router, in one line each: which layout was built (A or B), the
bucket set and how each bucket was obtained (reported / derived / residual), the
historical window used, and the row addresses of the consolidated `EOP` and each
bucket `EOP` so the downstream revenue build can reference them without
re-deriving anything.

## Notes

- Do **not** re-run `list_kpis` — use the shared KPI inventory passed down the
  chain. Pull specific series via `search_kpis` against that inventory.
- This build writes **only** the customer roll-forward block(s); the revenue lines
  themselves are the downstream sub-build's responsibility.
- Layout B is the expected outcome whenever any usable breakdown exists — including
  the very common case of a total plus a single reported cohort, which yields one
  reported bucket and one derived complement. Layout A is only for companies that
  report nothing but a total.
- The customer roll-forward is laid down as the **first block beneath the `REVENUE`
  ALL-CAPS header**, with a blank spacer row after the last bucket block so the
  revenue sub-build has room to build beneath it.
