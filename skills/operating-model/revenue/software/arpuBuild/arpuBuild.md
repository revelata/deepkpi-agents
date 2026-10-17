---
name: revenue-software-arpu
description: >
  ARPU revenue build for software / technology companies in the operating-model
  workbook. Invoked by the software router (`revenue/software/software.md`) after
  its Step 4 routing when the company reports a user count and revenue but does
  NOT qualify for the richer ARR or take-rate builds — enough to drive the model
  off ARPU (revenue ÷ users). By the time this build runs, the shared KPI
  inventory is known and the customer (user) roll-forward has already been laid
  down by `customerRollForward/customerRollForward.md`. Receives the resolved
  `company_id`, official company name, workbook path, the shared KPI inventory,
  the KPIs that satisfied the ARPU criteria, and the row addresses of the
  customer roll-forward's consolidated `EOP` (and any bucket `EOP`s). First
  isolates which revenue the ARPU × Users identity covers and decides Case A
  (one ARPU for total revenue) vs Case B (multiple ARPU buckets that sum to total
  revenue), carving out any non-ARPU stream (e.g. services) that must be projected
  on a YoY % basis. Then builds a Unit Economics block (ARPU,
  historical = revenue ÷ EOP users, projection = prior year × (1 + its YoY % driver)) and a Revenue block
  (ARPU × Users → Total Revenue), plus any non-ARPU streams, all collected into a
  consolidated revenue table that foots to reported total revenue. Pulls series
  via `search_kpis` from the shared inventory; format per
  ../../../../_common/revelata-excel-styling-rules.md (one row per series, derived
  cells as live formulas) EXCEPT for time scope (last 4 fiscal years), which this
  build overrides. Sections: §1 isolate the ARPU-driven revenue + Case A/B, §2
  Unit Economics (ARPU), §3 Revenue (ARPU × Users), §4 non-ARPU revenue streams,
  §5 consolidated revenue + foot, §6 worked example, Projections, §7 downstream
  handoff.
---

# revenue — software — ARPU build

This is the **ARPU (average revenue per user)** software revenue build. It is
invoked by the software router (`../software.md`) at its Step 4 hand-off when the
company **did not** qualify for the ARR build (no NRR) or the take-rate build
(not a booking-based business), but **does** report a **user count** and
**revenue** — enough to drive the model off **ARPU** (revenue ÷ users).

At its core an ARPU build is simple. The customer / user roll-forward already
gives the **count of users** in every period; the only thing this build adds is a
way to **convert users into revenue** — an average revenue per user. Multiply the
two and you have revenue: `Revenue = ARPU × Users`. Everything below is the
disciplined way to source or derive that ARPU, wire the identity so it foots to
reported revenue, and carve out any revenue stream the ARPU does **not** cover.

By the time control reaches this build, three things are already established and
must **not** be re-litigated:

1. the company **is in the software / technology industry** (decided by the parent
   revenue router, `../../revenue.md`);
2. the company **qualifies for the ARPU build** (decided by the software router's
   Step 2 criteria C — user count + revenue present, and neither ARR nor take-rate
   criteria met); and
3. the **customer / user roll-forward has already been laid down** in the workbook
   by `../customerRollForward/customerRollForward.md` (the router runs it as a
   conditional pre-build before routing here; its Step 3 gate fires on the
   user-count family and designates the ARPU anchor as the series the roll-forward
   tracks, so whenever this build is reached the roll-forward exists and its `EOP`
   is the ARPU population). This build is therefore responsible
   only for the **revenue** lines of the ARPU model and **references the user
   counts already present** — it does not re-derive them.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook (with the customer / user roll-forward already
laid down), the **shared KPI inventory** from the orchestrator, the router's note
of which KPIs satisfied the ARPU criteria (the user-count series and the
revenue series), and the **row addresses** of the customer roll-forward's
consolidated `EOP` (and each bucket `EOP`, if the roll-forward was built with a
breakdown) so this build can reference them without re-deriving anything.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and build
with the **xlsx** skill. All conventions there apply here — the four-column label
system (Col A hidden deepKPI string, Col B hidden index, Col C display label, Col D
units tag, Col E onward data), one row per distinct series, deepKPI-sourced values
as pale-green hyperlinked input cells, and **every** total / derived cell as a live
`=` formula (never a hardcoded number) — **except** for the **time scope**, which
this build overrides per the "Time scope" section below.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped. Use
  the **same four annual period columns** the customer roll-forward used, so every
  ARPU / revenue cell sits directly under the matching user-count cell.
- **The ARPU build is ANNUAL.** ARPU, the user counts, and revenue are modeled as
  an annual build, so this build uses **annual columns only** (one per fiscal year,
  oldest → newest, left → right), matching the customer roll-forward above it. Do
  **not** add quarterly columns.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 6), then **extends the entire ARPU build into the projection window** following
  the **Projections (forecast years)** section near the end of this file. Do not
  fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §1 the
> ARPU-driven-revenue isolation and §2 – §7 the revenue build (Unit Economics,
> Revenue, non-ARPU revenue streams, the consolidated revenue foot, a worked
> example, and the downstream handoff), plus the **Projections (forecast years)**
> section near the end that extends the build into `N+1 … N+5` — are the
> implemented scope. Do not build or add any new information outside the sections
> present here.

---

## Section 1 — Isolate the ARPU-driven revenue and decide Case A vs Case B

This is the **first section** of the ARPU build and its analytical foundation.
Before any Unit Economics or Revenue row is written, you **must** decide, from the
filing and the KPI inventory, exactly **which revenue the ARPU × Users identity
covers**, **how many ARPU buckets** there are, and **which revenue (if any) the
ARPU does not cover** and must be modeled separately.

**Why this matters (STRICT).** `ARPU × Users` only reconstructs the revenue that
those users actually generate. If a company reports a user-driven stream **and**
another stream the user count does not monetize (professional services, hardware,
licensing, transaction fees, etc.), multiplying ARPU by users and calling the
result *total* revenue silently double-counts or under-counts. The goal of this
section is that **the revenue fed through the ARPU identity is genuinely the
revenue those users generate**, everything else is carved out (Section 4), and the
whole build foots to reported total revenue (Section 5).

### 1.1 — Read the filing and inventory to fix the ARPU numerator

Two things must be extracted before any row is written:

1. **The numerator of ARPU**, fixed by the first of two rungs:
   - **The issuer's reported per-user revenue metric.** Where the filing defines a
     revenue-per-user figure (`ARPU`, `ARPP`, `Average Revenue Per Member`, revenue
     per active user, by any name), its numerator **is** the ARPU numerator, in the
     issuer's words: the revenue the definition names, on the axis the definition
     uses (a segment's revenue, a stream's revenue, total revenue). The build does
     not re-derive what the users "really" generate; the issuer has said. The
     metric's **denominator** is not adopted (§1.3: it is usually an average, and
     the build uses period-end users), which is a separate matter from the
     numerator. An issuer whose metric is total revenue over its user count is
     covers-all; one whose metric is a segment's or a stream's revenue is mixed,
     the rest carried in §4.
   - **The population test**, only where no such metric is reported. The numerator
     is every revenue line earned from the population the roll-forward's count
     measures. For each line of the revenue disaggregation, answer two questions
     and record the table in `BUILD_LOG.md` as a judgment item:

     | Revenue line | Who pays, or who is it served to | Inside the counted population? | In the numerator? |
     |---|---|---|---|

     A line is **carved out** to §4 only when the party that pays it is one the
     count does not measure, or when it is served to a population the count
     excludes. A line the counted population pays into is **retained** even where
     others pay into it too; sharing is not a carve-out. The numerator is the sum of
     the retained lines.
2. **Whether the user count (and revenue) is reported as one population or split
   into buckets** — e.g. a single global MAU vs. `US & Canada`, `Europe`, `Rest of
   World` user counts each with their own ARPU / revenue. This decides Case A vs
   Case B (below).

**Workflow:**

1. Pull the latest 10-K markdown via the **filing** skill
   (`list_sec_filing_markdowns` → `get_sec_filing_markdown`).
2. Search the markdown for the disaggregated revenue table and the key-metrics
   table (tokens: `ARPU`, `Average Revenue Per User`, `Average Revenue Per Member`,
   `MAU`, `DAU`, `Active users`, `Disaggregation of revenue`, `Revenue by
   geography`, `Revenue by type`). Where a per-user revenue metric is defined,
   quote its definition and take its numerator (rung one above); otherwise run the
   population test (rung two). Read the same passages for whether the company
   reports ARPU / users **per region / segment / product** or as a **single
   blended** figure.
3. Confirm each series you intend to use (the user-count series, the revenue
   series, and any reported ARPU) is present in the shared KPI inventory (via
   `search_kpis`), reading the `unit` field to confirm counts vs. dollars vs.
   per-user dollars. Record **which revenue the ARPU covers** and **which streams
   (if any) are carved out to §4** as one line in the workbook's Notes block, in the
   analyst's words: `Revenue: ARPU is <covered revenue> divided by period-end
   <population>; <stream> is carried separately.` No note row is laid inside the
   block. Which case (A or B) applies, and whether the build is covers-all or
   mixed, goes to `BUILD_LOG.md` (the stage's hand-back report carries the same),
   not to the sheet.

### 1.2 — Case A vs Case B (and the non-ARPU carve-out)

Exactly one of two cases applies to the ARPU identity, and the build shape follows
from which one it is:

- **Case A — one ARPU for the covered revenue.** A single ARPU (blended, one
  bucket) monetizes a single user population. The covered revenue is then
  `Total covered revenue = ARPU × Users`. Historically ARPU is `covered revenue ÷
  EOP users`; in projection ARPU is a **driver**. Build **§2 Unit Economics** and
  **§3 Revenue** with a single ARPU / single user line.

- **Case B — multiple ARPU buckets that sum to the covered revenue.** The company
  reports several user buckets (e.g. by geography or plan tier), each with its own
  ARPU, and the **sum of every `ARPU_bucket × Users_bucket` gives the covered
  revenue**. This case is only buildable if the **customer roll-forward carries the
  matching user buckets** (see the STRICT note below) **and** the revenue (or ARPU)
  is disclosed per bucket so each bucket ARPU can be sourced or backsolved. Build
  **§2 Unit Economics** with one ARPU line per bucket and **§3 Revenue** with one
  revenue line per bucket summed to Total Revenue.

Independently of A vs B, the covered revenue may be **only part of reported total
revenue**:

- **ARPU covers all revenue** — the covered revenue **is** reported total revenue.
  No §4 streams; §5 consolidated table simply restates §3's Total Revenue.
- **ARPU covers only part** (mixed) — e.g. ARPU × Users is only **subscription**
  revenue and the company also has **services** revenue. The uncovered stream(s)
  are **non-ARPU streams** (§4), each projected on a **YoY %** basis;
  §5 sums the ARPU-driven revenue and the non-ARPU streams and foots to reported
  total revenue.

Record which case (A or B) applies and whether the build is **covers-all** or
**mixed** in `BUILD_LOG.md`; the Notes line from §1.1 carries the fact itself (what
ARPU covers and what is carried separately) without the case name. Record there too
the **segment map** (`../../../SKILL.md`, "The segment map"): for each issuer segment,
the keys of the rows that make up its revenue — the ARPU-covered stream and any §4
stream the segment disclosure attributes to the same segment both map to it (an
advertising stream and that segment's other-revenue stream are one segment's revenue);
a stream the segment disclosure does not attribute maps to no segment. Do **not**
default to Case A / covers-all because it is
simpler — if a breakdown or a distinct non-user stream is reported, model it.

**Label of the §3 total (STRICT).** The §3 block's total row is the revenue that
ARPU × Users explains. In a **mixed** build label it **`Revenue from <Stream>`**, where
`<Stream>` is the issuer's own name for the ARPU-driven business (`Revenue from
Subscriptions`, `Revenue from Advertising`, `Revenue from Family of Apps`); if the
issuer names no such business, fall back to **`Revenue from <users noun>`** using the
roll-forward's noun (`Revenue from Subscribers`, `Revenue from Paying Users`). Only a
**covers-all** build labels that row **`Total Revenue`**, because there it *is* the
reported total and the contract row (`../../../SKILL.md`, "Contract rows"). Never lay
two rows labeled `Total Revenue`; never use a modeling word such as "covered" in a
Col C label — a cold reader of the sheet must recognize the issuer's business.

> **STRICT — Case B needs the user breakdown in the roll-forward.** To use bucket
> ARPUs you need the **user count per bucket** and the **revenue (or ARPU) per
> bucket**. The user counts come from the customer roll-forward, so Case B is only
> viable when that roll-forward was built with the **matching buckets** (its
> Layout B bucket `EOP` rows). If the roll-forward carries only a consolidated
> user count, you cannot build Case B on top of it — fall back to **Case A** on the
> blended ARPU, and add one Notes line: `Revenue: ARPU is blended across all users;
> the user breakdown is not reported.` Never invent a bucket user count this build does not
> reference from the roll-forward.

### 1.3 — Sourcing ARPU: reported or derived

ARPU may be **reported** by the company (often in the key-metrics table, possibly
under a different name — `ARPU`, `Average Revenue Per Member`, `ARPPU`, `Revenue
per active user`) **or derived** by this build. This build's **default and
preferred** historical treatment is to **derive** ARPU as `covered revenue ÷ EOP
users`, because that guarantees `ARPU × Users` foots to the reported covered
revenue exactly. If the company **also** reports an ARPU directly, carry it as an
optional **memo cross-check** row (§2), with the basis difference on the §2.1 Notes
line — do **not** substitute the reported ARPU for the derived one that anchors the
identity, since a reported ARPU
is typically built on an **average** user base (and sometimes annualized from a
quarterly figure) and will not tie the annual identity exactly. That exemption is
the denominator's alone: the reported metric's **numerator** is the build's numerator
(§1.1, rung one), which is what makes the memo row a cross-check of one revenue on
two user bases rather than two revenues on two bases.

> Use the **EOP** user count as the ARPU denominator (the roll-forward exposes EOP),
> and use the **same EOP basis** in both the historical backsolve and the projection
> rebuild so the average-vs-EOP distortion cancels. See the rigor note in §2.1.

### 1.4 — Pre-delivery checklist (isolation)

- [ ] One Notes line states **which revenue the ARPU covers** and which streams
      are carried separately, in the analyst's words (§1.1); no note row sits
      inside the block. The case (A or B) and covers-all vs mixed are in
      `BUILD_LOG.md`.
- [ ] The ARPU numerator is the issuer's reported per-user metric's numerator where
      one is defined, quoted in `BUILD_LOG.md`; otherwise the population test's
      table is in `BUILD_LOG.md` as a judgment item and the numerator is the sum of
      its retained lines (§1.1).
- [ ] **Case B is chosen only if** the customer roll-forward carries the matching
      user buckets **and** per-bucket revenue / ARPU is disclosed; otherwise the
      build falls back to Case A with the blended-ARPU Notes line from §1.2.
- [ ] Each series to be used (user count, covered revenue, any reported ARPU, any
      non-ARPU stream) is present as its own deepKPI series (confirmed via
      `search_kpis`, correct `unit`), or a sourcing gap is documented.
- [ ] No line earned from a party outside the counted population sits in the ARPU
      numerator, and no line the counted population pays into was carved out on the
      ground that others pay into it too.

---

## Revenue build — framework overview (Sections 2 – 5)

Section 1 fixed the ARPU numerator, the case (A / B), and the carve-out. Sections
2 – 5 turn the user counts into revenue via ARPU, model any non-ARPU streams
alongside, and foot the whole build to the company's **reported total revenue**.
The build follows one fixed framework so that **every** ARPU-build company is
modeled the same way and the workbook always foots.

**The master identity.** Revenue is reconstructed from ARPU and users, and
consolidated revenue is the sum of the ARPU-driven revenue and the non-ARPU
streams:

```
  Case A:   Total covered revenue = ARPU × Users                                   (§2 / §3)
  Case B:   Total covered revenue = Σ ( ARPU_bucket × Users_bucket )               (§2 / §3)

  Total Revenue = Total covered revenue + Non-ARPU Stream 1 + Non-ARPU Stream 2 + … [+ Other]   (§5 foot)
```

In the **historical** columns the covered revenue (Case A) or each bucket revenue
(Case B) is the **reported** deepKPI input (the anchor), and ARPU is **backsolved**
from it — so `ARPU × Users` reproduces the reported revenue **by construction**.
The consolidated table foots to reported total revenue because the non-ARPU
streams (plus a residual `Other Revenue` line, if the identified streams do not
exhaust the remainder) form an **exhaustive partition** of `Total Revenue − covered
revenue` (see §4 / §5).

**Build the revenue lines in this order**, each beneath the customer roll-forward
that the router laid down:

1. **Section 2 — Unit Economics (ARPU).** One ARPU line (Case A) or one ARPU line
   per bucket (Case B), each with a `YoY %` row. Historical ARPU is
   the backsolve `covered revenue ÷ EOP users`; projected ARPU is a **driver**.
2. **Section 3 — Revenue (ARPU × Users).** Restates ARPU (linked from §2), pulls
   the EOP user count (linked from the customer roll-forward), and builds Total
   Revenue = `ARPU × Users` (Case A) or `Σ bucket revenue` (Case B), with a
   `YoY %` row.
3. **Section 4 — Non-ARPU Revenue Streams.** Each carved-out stream with a
   YoY % memo — omitted entirely for a covers-all company.
4. **Section 5 — Consolidated Revenue.** Sums the ARPU-driven revenue + the non-ARPU
   streams (+ residual `Other Revenue` if needed) and foots to reported `Total
   Revenue`. Present **only** when §4 streams exist (a covers-all company's §3 Total
   Revenue already is the consolidated total).

**Conventions that apply to all of Sections 2 – 5 (read once):**

- **Annual columns only**, the same four the customer roll-forward uses.
- **Reference the customer roll-forward — do not re-derive counts.** The user
  counts this build needs already exist in the workbook (the router laid them down):
  the consolidated `EOP` (Case A) or each bucket `EOP` (Case B). Reference those
  cells with live `=` formulas; never hardcode a count. **Population consistency
  (STRICT):** the user count you reference must be the **same population** the ARPU
  denominator is defined on (e.g. paying subscribers, not registered accounts). If
  the roll-forward tracked a different population than the ARPU metric, the
  router's Step 3 designation was not followed. The router checks the roll-forward's
  hand-back population against its designation **before dispatching this build**
  (`../software.md`, Step 4) and re-runs the roll forward on a mismatch, so by the
  time this build runs the populations agree; if they do not, stop and return
  `OUT OF ORDER — customer roll-forward population` to the router rather than
  papering over the mismatch.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (reported covered revenue / reported bucket revenue, any
  reported ARPU carried as a memo, the reported non-ARPU streams, and reported total
  revenue) are **input cells** (pale-green fill, dark-blue
  hyperlinked value linked to the filing). **Every other cell is a live `=`
  formula** (black font, no fill) — the ARPU backsolve, the `ARPU × Users` product,
  every bucket revenue, the sums, every `YoY %` row, and the foot
  check. Never hardcode a computed number.
- **Label / comment / spacing discipline.** Col C labels are **plain descriptive
  text**; the operand recipe for each formula row goes in a **cell comment on the
  Col C label cell** (author `ARPU Build`), not in the visible label. **Indent with
  the cell's own indentation, never with leading spaces.** Set the indent through the
  cell alignment (openpyxl `Alignment(indent=1)` for one level, `Alignment(indent=2)`
  for two) and keep the Col C label string itself flush-left with **no leading
  spaces** — leading spaces get caught under the block-header underline (and any cell
  underline), rendering as an underlined blank run at the start of the cell, which is
  exactly the artifact a real indent avoids. **Block headers are bold + underlined and
  indented once** (`indent=1`); **main line items sit one level deeper** (`indent=2`),
  and a block's total (`Revenue from <Stream>`, `Total Revenue`) returns to `indent=1`,
  bold; **memos sit at the items' level and a trend row one level deeper than the line
  it belongs to** — the renderer sets every data row's indent from its kind (styling
  rules). Blocks are separated
  by **one blank spacer row**.
- **Border discipline (whole sheet).** **Never use a double-lined border anywhere.**
  Every subtotal / total row (e.g. `Total Revenue`, each bucket revenue total row)
  is marked with a **single-lined "sum bar"** — a thin top border applied **only
  across the data columns (Col E onward)**, never a double line and never a bottom
  border on the row above. Total rules never run through the label columns (Col A–D).
  Reserve the **font underline** (`Font(underline="single")`) for **block / section
  headers**; total rows are **bold only** (no label underline) — their total is
  conveyed by the single-lined sum bar across the data columns. The customer / user
  roll-forward's **`EOP` (total-payer end-of-period) row** that this build sits
  beneath and references is treated the same way: it carries a **single-lined sum bar**
  (thin top border) applied **only across the data columns (Col E onward)** — never
  through the label / row-header columns (Col A–D), and never a double line.
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.2 and §3.2 (both
  cases), §4.2 and §5.2 — and in the `Units (Col D)` column of that section's formula
  table. Dollar rows show the placeholder `(USD in <scale>)`: the contract's Rule 2
  supplies the scale, millions by default, thousands where the digit test puts a small
  filer. Three classifications are specific to this build:
  - **The user count's scale is set by ARPU, not inherited from the roll-forward.**
    `ARPU` divides a money row by the `Users` row, so money scale ÷ count scale = ARPU
    scale. With money in millions, a user base in the millions displays in **millions**
    — the `Users` tag `(users, in <scale>)` becomes `(users, in millions)` — and ARPU
    lands in plain dollars, `(USD per user)`, so the three rows reconcile on the page
    (the §6.1 example: `1,800 ÷ 150 = 12.00`). Do **not** carry the roll-forward's
    display scale across unexamined: a count left in ones under money in millions makes
    ARPU unverifiable against the two rows it comes from, which is the most common
    defect in this build. Where the base is genuinely small (tens of thousands of
    enterprise customers), display it in thousands — `(users, in thousands)` — and ARPU
    then reads in thousands, `(USD thousands per user)`, the unit an analyst quotes for
    such a company; both tags change together. `Reported ARPU (memo)` takes the same tag
    as the ARPU row it checks. Where the issuer also publishes a monthly ARPU, write the
    tag as `(USD per user per year)` so the two are never confused.
  - **Percent rows.** Every `YoY %` row is the bare `(%)` the contract's
    Rule 5 reserves for a period change, whether the cell is a historical formula or a
    projection driver; `Memo: ARPU-revenue mix` names its denominator, `(% of total
    revenue)`.
  - **Everything else is money at one scale, memos included.** Bucket revenue, `Total
    Revenue`, `Revenue from <Stream>`, each non-ARPU stream, the `Other Revenue`
    residual and `Memo: components − Total` all take the one Rule 2 scale — the memo too, because a
    scale mismatch is exactly what it exists to expose. `Total Revenue` in §3 and §5
    carries the SUM-BAR named in its note.
- **Reading the layout blocks (§2.2, §3.2, §4.2, §5.2).** Each row's annotation has two
  columns, left to right: the **Col D units tag in parentheses** — `(USD in <scale>)`
  and `(users, in <scale>)` mean the scale is set as described above; every other tag is
  written as it goes in the cell — and the note in **square brackets**: the row's real
  cell indent, then `deepKPI INPUT …` for a pulled value, `FORMULA …` for a computed
  row, the projection treatment, and styling (`bold`, `SUM-BAR`, `italic`). Block
  headers, stream header rows and the `YoY %` label-only rows carry no
  tag.
- **Memo rows stay visible.** Every **memo** line item (e.g. `Reported ARPU (memo)` in
  §2, `Memo: components − Total (must = 0)` / `Memo: ARPU-revenue mix` in §5) is an
  ordinary visible italic row; no row on the sheet is hidden or collapsed (styling
  rules).
- **Blank row above a full `YoY %` section.** When a `YoY %` block is a **full section** — a `YoY %` header followed by its
  own line items (and, where present, a total) that mirror the block above it — leave
  **one blank spacer row immediately above** the `YoY %` header, so it
  reads as its own section (e.g. `… / Total Revenue / [blank] / YoY % /
  Revenue 1 / Revenue 2 / Total Revenue`). Do **not** add that blank row when
  `YoY %` is a **single one-line trend** sitting directly under its line
  item (e.g. a one-row KPI `Users / Total Users / YoY %`, or the single
  `YoY %` row beneath a `Total Revenue` in §3/§4) — those stay flush
  with no blank row above. This rule governs only the blank spacer row; all other
  indentation, bold, underline, and sum-bar conventions are unchanged.

The sub-sections below specify each component cell-by-cell. Build them in order; do
not add revenue lines outside this framework.

---

## Section 2 — Unit Economics (ARPU)

This section builds the **ARPU** line(s) — the conversion factor from users to
revenue. It sits **directly beneath** the customer roll-forward. It reads as a
small `Unit Economics` block: the ARPU line(s), then a `YoY %`
sub-block showing each ARPU's year-over-year trend. In the historical columns ARPU
is **backsolved** from reported revenue and the EOP user count; in the projection
columns each ARPU becomes a **driver** (see the Projections section).

### 2.1 — The logic and the ARPU numerator

```
  Case A:   ARPU        = Total covered revenue ÷ Total EOP Users               [historicals]
            ARPU        = <driver>                                              [projection]

  Case B:   ARPU_bucket = Bucket covered revenue ÷ Bucket EOP Users            [historicals]
            ARPU_bucket = <driver>                                             [projection]

  YoY % (any ARPU row) = this col ÷ prior col − 1               [both halves, derived]
```

- **Derive (historicals):** for each historical period, ARPU = covered revenue ÷
  the **EOP** user count from the roll-forward. In Case B, do this **per bucket**
  using that bucket's revenue and that bucket's EOP users.
- **Trend:** the `YoY %` row beneath each ARPU shows its
  year-over-year growth — the trend that anchors the forward driver.
- **Project:** each ARPU becomes a forward **driver** (§Projections); the rebuild
  `ARPU × Users` happens in §3.

**Rigor note — EOP vs. average users.** ARPU here uses the **EOP** user count (per
the framework and the roll-forward). Revenue is earned across the period, so EOP
slightly understates per-user revenue in fast-growing years; this is acceptable
because the **same EOP basis** is used in the historical backsolve and the §3
rebuild, so the distortion largely cancels. If the company reports an ARPU built on
**average** users, it will not tie this build's EOP-based ARPU exactly — carry it
only as the optional memo cross-check (below) and add one Notes line: `Revenue: the
issuer's reported ARPU is on average users; the model's ARPU is on period-end
users, so the two differ.` Do not overwrite the EOP-based line with it.

**Rigor note — isolate the covered revenue.** The ARPU numerator is the **covered
revenue** fixed in §1, not blended total revenue, whenever a distinct non-ARPU
stream exists. Dividing *total* revenue by users contaminates ARPU and double-counts
once the non-ARPU streams are added back in §5. The `ARPU` row's Col C comment
names the numerator; the Notes line from §1.1 states what ARPU covers.

**Base-year note.** Unlike an ACV backsolve, ARPU can be computed in **every**
historical year including the base year, because the roll-forward's base-year `EOP`
user count is a reported input (only its `BOP` / `Net New Additions` are blank).
Do **not** leave the base-year ARPU blank.

### 2.2 — Layout

**Case A (single ARPU):**

```
  Unit Economics                                                              [indent once; bold + underlined block header]
  ARPU                                                (USD per user)          [indent once; historical: FORMULA = §3 Total Revenue ÷ Total EOP Users; projection: FORMULA = prior col × (1 + YoY %)]
    Reported ARPU (memo)                              (USD per user)          [indent twice; deepKPI INPUT — optional; only if a company-reported ARPU exists; label uses the issuer's term (ARPP, ARPPU) where it has one; italic memo cross-check]
  [blank spacer row]                                   (one blank row above the full YoY % section)
  YoY %                                                        [indent once; bold + underlined label-only row — no data]
    ARPU                                              (%)                     [indent twice; FORMULA = this col ÷ prior col − 1 in history; projection DRIVER; italic; base col dash]
```

**Case B (multiple ARPU buckets):**

```
  Unit Economics                                                              [indent once; bold + underlined block header]
  ARPU — <Bucket 1>                                   (USD per user)          [indent once; historical: FORMULA = Bucket 1 revenue ÷ Bucket 1 EOP Users; projection: FORMULA = prior col × (1 + YoY %)]
  ARPU — <Bucket 2>                                   (USD per user)          [indent once; historical: FORMULA = Bucket 2 revenue ÷ Bucket 2 EOP Users; projection: FORMULA = prior col × (1 + YoY %)]
  [blank spacer row]                                   (one blank row above the full YoY % section)
  YoY %                                                        [indent once; bold + underlined label-only row — no data]
    ARPU — <Bucket 1>                                 (%)                     [indent twice; FORMULA = this col ÷ prior col − 1 in history; projection DRIVER; italic; base col dash]
    ARPU — <Bucket 2>                                 (%)                     [indent twice; FORMULA = this col ÷ prior col − 1 in history; projection DRIVER; italic; base col dash]
```

One blank spacer row sits **above** the `YoY %` sub-section (it is a
full `YoY %` section — a header with its own per-ARPU trend lines — so
it takes the blank-row-above rule from the shared conventions); there are no other
blank rows within the block, and one blank spacer row follows it. `YoY %` is a **bold, underlined label-only** row (no data in any period column); its per-ARPU trend
lines are indented twice beneath it. Number formats follow each row's Col D tag. In
Case B, the ARPU bucket
order **matches** the customer roll-forward's bucket order (and §3's revenue-bucket
order).

### 2.3 — The formulas (cell-by-cell)

"§3 Total Revenue (col X)" = the Section 3 Revenue block's `Total Revenue` cell in
column X; "roll-forward EOP (col X)" = the customer roll-forward's consolidated (or
bucket) `EOP` cell in column X.

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `ARPU` *(Case A)* | DATA_DEPENDENT | `(USD per user)` | historical: `= <§3 total (Revenue from <Stream> / Total Revenue), this col> ÷ <Total EOP Users, this col>`; **projection:** `= <prior col ARPU> × (1 + <ARPU YoY %, this col>)` | `"Historical backsolve: covered revenue ÷ EOP users. Projection: prior year × (1 + the YoY % driver). EOP basis; covered revenue only."` |
| `ARPU — <Bucket n>` *(Case B)* | | `(USD per user)` | historical: `= <§3 Revenue — Bucket n, this col> ÷ <Bucket n EOP Users, this col>`; **projection:** `= <prior col> × (1 + <this bucket's YoY %, this col>)` | `"Historical backsolve: bucket revenue ÷ bucket EOP users. Projection: prior year × (1 + the bucket's YoY % driver)."` |
| `Reported ARPU (memo)` *(optional; `ARPU` replaced by the issuer's own term where it has one, e.g. `Reported ARPP (memo)`)* | DATA_DEPENDENT | `(USD per user)` | deepKPI **input** — company-reported ARPU, if disclosed | *(no comment — input memo; cross-check vs derived ARPU; the average-vs-EOP / annualization basis gap is the §2.1 Notes line)* |
| `YoY %` (label row) | | — | dash (no value) | `"Label row; heads the per-ARPU YoY trend lines. No values."` |
| `ARPU` / `ARPU — <Bucket n>` (under YoY %) | | `(%)` | base col: dash; historical: `= <this col ARPU> ÷ <prior col ARPU> − 1`; **projection: DRIVER** (red/dashed), seeded per **Projections** | `"ARPU growth, YoY. Historical: derived. Projection: the driver — ARPU compounds off it."` |

- The `ARPU` line references **§3's Total Revenue** (Case A) or **§3's bucket
  revenue** (Case B) as its historical numerator, and the **roll-forward EOP** as
  its denominator — both live references, so a change upstream flows through.
- The only deepKPI **input** in this section is the optional `Reported ARPU (memo)`;
  every ARPU and every `YoY %` cell is a **black live formula**
  (until ARPU inverts to a driver in projection).

**Sourcing.** Pull the user-count series (already referenced from the roll-forward)
and, if the company reports ARPU, the reported-ARPU series via `search_kpis` against
the shared inventory. Read the `unit` to confirm the reported ARPU is a per-user
dollar figure and note whether it is annual or a monthly / quarterly run-rate before
using it even as a memo.

### 2.4 — Pre-delivery checklist (Unit Economics)

- [ ] ARPU is the **backsolve** `covered revenue ÷ EOP users` in **every** historical
      column (including the base year), a live formula — not a hardcode.
- [ ] The numerator is the **covered revenue** (Case A total, or Case B bucket
      revenue), not a blended total when a non-ARPU stream exists.
- [ ] The denominator is the **roll-forward EOP** for the matching population (Case A
      consolidated, Case B bucket), referenced not re-derived.
- [ ] Each ARPU has a `YoY %` trend line (dash in the base column).
- [ ] Any company-reported ARPU is carried **only** as `Reported ARPU (memo)` with
      the basis gap (average vs EOP / annualization) on its Notes line (§2.1) — it
      does not replace the derived line.
- [ ] In Case B, the ARPU bucket set and order match the roll-forward buckets and
      §3's revenue buckets.
- [ ] After recalculation, **zero formula errors**.

---

## Section 3 — Revenue (ARPU × Users)

This section rebuilds revenue from the ARPU line(s) and the user counts, and
produces the ARPU-driven total — labeled `Revenue from <Stream>` in a mixed build,
`Total Revenue` in a covers-all build (§1.2) — that §5 (or, covers-all, the rest of the
workbook) foots to. It sits directly beneath the Unit Economics block. In the historical
columns that total (Case A)
or each bucket revenue (Case B) is the **reported** deepKPI input (the anchor); in
the projection columns it becomes the computed `ARPU × Users`.

### 3.1 — The identity and the link direction

For each period N:

- **Case A:** `Total Revenue = ARPU × Users`. Historically `Total Revenue` is the
  reported covered-revenue input and §2's ARPU is backsolved from it; in projection
  ARPU is the driver and `Total Revenue = ARPU × Users` is computed.
- **Case B:** `Revenue — Bucket n = ARPU_bucket n × Users_bucket n` per bucket, and
  `Total Revenue = Σ Revenue — Bucket n`. Historically each bucket revenue is the
  reported bucket input and §2's bucket ARPU is backsolved from it; in projection
  each bucket revenue = `bucket ARPU × bucket users` and Total Revenue sums them.

**The link direction inverts at the boundary** (exactly as the §2 ARPU backsolve
implies), and there is **no circularity** — in each half exactly one side is the
source and the other references it:

- **Historical:** covered / bucket revenue is the reported input (source); §2 ARPU
  = revenue ÷ users (references it).
- **Projection:** §2 ARPU is the driver (source); revenue = ARPU × users
  (references it).

### 3.2 — Layout

**Case A:**

```
  Revenue                                                                     [indent 1; bold + underlined block header]
    ARPU                                                (USD per user)          [indent 2; FORMULA = §2 Unit Economics ARPU, this col]
    Users                                               (users, in <scale>)     [indent 2; FORMULA = customer roll-forward consolidated EOP, this col]
  Revenue from <Stream>                               (USD in <scale>)        [indent 1, bold; SUM-BAR; label per §1.2 (`Total Revenue` only when covers-all); historical: deepKPI INPUT — the reported revenue of the ARPU-driven business; projection: FORMULA = ARPU × Users]
    YoY %                              (%)                     [indent 2; FORMULA = this col ÷ prior col − 1; italic; base col dash]
```

**Case B:**

```
  Revenue                                                                     [indent 1; bold + underlined block header]
    Revenue — <Bucket 1>                                (USD in <scale>)        [indent 2; historical: deepKPI INPUT — reported bucket revenue; projection: FORMULA = §2 ARPU — Bucket 1 × Bucket 1 EOP Users]
    Revenue — <Bucket 2>                                (USD in <scale>)        [indent 2; historical: deepKPI INPUT — reported bucket revenue; projection: FORMULA = §2 ARPU — Bucket 2 × Bucket 2 EOP Users]
  Revenue from <Stream>                               (USD in <scale>)        [indent 1, bold; SUM-BAR; label per §1.2 (`Total Revenue` only when covers-all); FORMULA = SUM(bucket revenue rows) in both halves]
    YoY %                              (%)                     [indent 2; FORMULA = this col ÷ prior col − 1; italic; base col dash]
```

Zero blank rows within the block; one blank spacer row after it. The §3 total
(`Revenue from <Stream>`, or `Total Revenue` when covers-all — §1.2) carries a
**single-lined sum bar** (thin top border) across the data columns and is
**bold**; there is **no** double border and **no** label underline. Revenue rows are the
**money** family; the `Users` row (Case A) is a **count** whose display scale follows
the coherence requirement in the **Number format and units** bullet above — not the
roll-forward's unit by default; the `ARPU` row (Case A) is **per-unit money**.

### 3.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `ARPU` *(Case A)* | DATA_DEPENDENT | `(USD per user)` | `= <§2 Unit Economics 'ARPU', base col>` | `= <§2 Unit Economics 'ARPU', this col>` | `"= ARPU from the Unit Economics block (this col). Linked, not re-entered."` |
| `Users` *(Case A; the Col C label is the issuer's own noun for the population — `Daily Active People`, `Paying users`, `Subscribers` — and `Users` only when the issuer names none)* | DATA_DEPENDENT | `(users, in <scale>)` | `= <roll-forward consolidated 'EOP', base col>` | `= <roll-forward consolidated 'EOP', this col>` | `"= customer roll-forward EOP users (this col). Same population ARPU is defined on."` |
| `Revenue from <Stream>` *(Case A; `Total Revenue` when covers-all — §1.2)* | | `(USD in <scale>)` | historical: deepKPI **input** — the reported revenue of the ARPU-driven business | historical: same input; **projection:** `= <ARPU> × <Users>` | `"Historical: reported covered revenue (input, the anchor). Projection: = ARPU × Users."` |
| `Revenue — <Bucket n>` *(Case B)* | | `(USD in <scale>)` | historical: deepKPI **input** — reported bucket revenue | historical: same input; **projection:** `= <§2 'ARPU — Bucket n', this col> × <Bucket n EOP Users, this col>` | `"Historical: reported bucket revenue (input). Projection: = bucket ARPU × bucket EOP users."` |
| `Revenue from <Stream>` *(Case B; `Total Revenue` when covers-all — §1.2)* | | `(USD in <scale>)` | `= SUM(<Revenue — Bucket rows>, this col)` | same | `"= Σ bucket revenue. Foots to the reported revenue of this business."` |
| `YoY %` | | `(%)` | base col: dash; else `= <this col Total Revenue> ÷ <prior col Total Revenue> − 1` | same | `"Total revenue growth, YoY."` |

- In Case A, `ARPU` and `Users` are **linked restatements** (of §2 and the
  roll-forward) so the `Total Revenue = ARPU × Users` identity reads cleanly in one
  block; they are live references, not new inputs.
- In Case B, the `ARPU × Users` product is done **inline per bucket** (referencing
  §2's bucket ARPU and the roll-forward's bucket EOP), and `Total Revenue` sums the
  buckets.

**Case B foot to reported total covered revenue.** In every historical year, the
sum of the reported bucket revenues **must** tie to the reported covered revenue. If
the reported buckets do not exhaust it (an "all other regions" line is omitted), add
a residual bucket `Revenue — other` whose historical value is `covered revenue −
SUM(reported buckets)` (a formula) with its own §2 ARPU backsolve against a residual
user bucket **only if** the roll-forward carries one; if it does not, keep `Revenue
— other` as a stream projected on YoY % (treat it like a §4 stream)
rather than forcing an ARPU it has no user count for. Add one Notes line: `Revenue:
<other> revenue is projected on its own growth rate; it has no user count to divide
by.`

### 3.4 — Pre-delivery checklist (Revenue)

- [ ] **Case A:** `Total Revenue` is the reported covered-revenue deepKPI input in
      the historical columns (bold, single-lined sum bar); `ARPU` and `Users` are
      live links to §2 and the roll-forward.
- [ ] **Case B:** each `Revenue — Bucket n` is the reported bucket input historically;
      `Total Revenue = SUM(buckets)` and ties to reported total covered revenue every
      historical year (residual handled if buckets don't exhaust).
- [ ] The `Total Revenue = ARPU × Users` (A) / `Σ bucket ARPU × bucket users` (B)
      identity holds by construction — historically because ARPU was backsolved from
      the same reported revenue and users.
- [ ] No circular reference (one side sources, the other references, in each half).
- [ ] `YoY %` is a live formula (dash in the base column).
- [ ] After recalculation, **zero formula errors**, and ARPU values look
      economically sane (positive, same order of magnitude across years — a wild ARPU
      flags a user-count or revenue-numerator problem upstream).

---

## Section 4 — Non-ARPU Revenue Streams (conditional)

**Include this section only for a mixed company** (§1.2) — one whose ARPU covers
only part of reported total revenue, leaving one or more streams the user count does
not monetize (professional services, hardware, license, transaction fees, etc.). A
**covers-all** company has no non-ARPU streams, so this section is **omitted
entirely**; record the omit decision in one line in `BUILD_LOG.md`, citing §1 (the
hand-back report carries the same). It is not a Notes line.

### 4.1 — What the streams are, and making the partition exhaustive

Each non-ARPU stream is a reported revenue line that is **not** the ARPU-covered
revenue. These are **not** put through the ARPU identity — the user count does not
generate them and they carry no per-user ARPU. Each is carried as a **reported
input** with a **YoY %** memo, and projected on that
YoY % basis (Section 5 / Projections) — this is the "project the
other revenue stream as a period-over-period change and use that as the driver"
step.

**Make the streams an exhaustive partition of the non-ARPU remainder.** The
ARPU-covered revenue plus the non-ARPU streams must sum to **reported total
revenue** in every historical year. After laying down the explicitly reported
non-ARPU streams, check each year: if `covered revenue + Σ (non-ARPU streams) <
reported Total Revenue`, the reported streams do not exhaust revenue — add a final
**`Other Revenue`** stream whose historical value is the residual `Total Revenue −
covered revenue − Σ (identified non-ARPU streams)` (a formula), carried historically
as that formula and projected as a **share of modeled revenue** (covered revenue plus
the named streams) off the driver row `Other Revenue — % of modeled revenue` laid beneath
it — see Projections, Part 3. After this the partition is exhaustive **by
construction**.

### 4.2 — Layout

**There is NO oversized `Non-ARPU Revenue` section header.** Each non-ARPU stream is
its own small block, laid out exactly like the §2 / §3 blocks: a bold + underlined
header row bearing the stream name (label only — no data), then the
stream's value row, then its `YoY %` row. Blocks are separated by
**one blank spacer row**.

```
  <Stream 1 name>                                                             [indent 1; bold + underlined block header — label only — no data]
    Revenue from <Stream 1 name>                        (USD in <scale>)        [indent 2; deepKPI INPUT historical; projection: = prior col × (1 + YoY %)]
      YoY %                              (%)                     [indent 3; FORMULA historical = this col ÷ prior col − 1; driver in projection; italic]

  <Stream 2 name>                                                             [indent 1; bold + underlined block header — label only]
    Revenue from <Stream 2 name>                        (USD in <scale>)        [indent 2; deepKPI INPUT historical; projection: = prior col × (1 + YoY %)]
      YoY %                              (%)                     [indent 3; FORMULA historical; driver in projection]

  Other                                                                       [indent 1; bold + underlined block header — label only; only if streams don't exhaust]
    Other Revenue                                       (USD in <scale>)        [indent 2; FORMULA residual historical = Total − covered revenue − Σ streams; projection: = the driver row beneath × (covered revenue + Σ named streams), this col]
      Other Revenue — % of modeled revenue                (% of modeled revenue)  [indent 3; FORMULA historical = Other Revenue ÷ (covered revenue + Σ named streams); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]
```

Each stream's header row is **bold + underlined, indent once** (no data values) and
carries the stream's name as the issuer captions it; the value row beneath it is a
plain **indent-once** row labeled `Revenue from <Stream>` — the same label the §5
consolidated table uses when it restates the row — (no bold, no sum bar — a stream
is a single reported figure, not a sum); the `YoY %` row is
**indent twice**, italic, immediately beneath (no blank row above). The residual
block, when needed, is headed `Other` with the value row `Other Revenue`. One blank
spacer row separates one stream's block from the next.

### 4.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Stream n>` *(value row; the block header above it is the bare stream name)* | | `(USD in <scale>)` | deepKPI **input** — reported non-ARPU stream revenue (historical) | *(no comment — input row; provenance via hyperlink)* |
| `YoY %` | | `(%)` | base col: dash; else `= <this col> ÷ <prior col> − 1` | `"YoY % in <stream>. Historical: derived. Projection: driver."` |
| `Other Revenue` *(residual, only if needed)* | DATA_DEPENDENT | `(USD in <scale>)` | historical: `= <Total Revenue, this col> − <covered revenue, this col> − SUM(<identified non-ARPU streams, this col>)`; projection: `= <Other Revenue — % of modeled revenue, this col> × (<covered revenue, this col> + SUM(<identified non-ARPU streams, this col>))` | `"Residual non-ARPU revenue = reported total − covered revenue − identified streams. Makes the partition exhaustive. Projection: a share of modeled revenue, off the driver row beneath."` |
| `Other Revenue — % of modeled revenue` *(driver row under the residual, in place of a `YoY %`; visible)* | DATA_DEPENDENT | `(% of modeled revenue)` | historical: `= <Other Revenue, this col> ÷ (<covered revenue, this col> + SUM(<identified non-ARPU streams, this col>))`; projection: **DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The residual's share of the revenue the build models (covered revenue + named streams). Historical: a fit diagnostic — low single digits expected. Projection: driver, guided or else the latest year, then flat."` |

Pull each non-ARPU stream series via `search_kpis` against the shared inventory. If a
stream is bundled with others in a single reported line, use that reported line and
name the bundled components in that row's Col C comment; the `Other Revenue`
residual (§4.1) still makes the build foot.

### 4.4 — Pre-delivery checklist (Non-ARPU streams)

- [ ] Section is **present iff** the company is **mixed** (§1.2); omitted for
      covers-all, with the decision in `BUILD_LOG.md`.
- [ ] Each stream is its own mini-block — a **bold + underlined header** row, a
      reported deepKPI **input** value row (historical), and a `YoY %`
      row beneath it (dash in the base column) — with **no** oversized `Non-ARPU
      Revenue` section header above them.
- [ ] The streams (plus the `Other Revenue` residual, if added) form an **exhaustive
      partition** of `Total Revenue − covered revenue` in every historical year
      (verified in §5's foot check).
- [ ] No non-ARPU dollars leaked into the ARPU identity (§2 – §3).
- [ ] After recalculation, **zero formula errors**.

---

## Section 5 — Consolidated Revenue (the foot; conditional)

This section collects the ARPU-covered revenue and the non-ARPU streams into a single
table and foots to the company's **reported total revenue**. **Build it only when §4
streams exist** (a mixed company). For a **covers-all** company, §3's `Total Revenue`
already is the consolidated total that foots to reported revenue — **skip this
section** and record in `BUILD_LOG.md` that §3 Total Revenue is the foot.

### 5.1 — The partition and the foot

Consolidated revenue is the sum of the ARPU-covered revenue and the non-ARPU streams:

> **Total Revenue = Revenue from <Stream> (ARPU × Users) + Non-ARPU Stream 1 + Non-ARPU
> Stream 2 + … [+ Other Revenue residual]**

Because §4 made the streams an **exhaustive partition** of `Total Revenue − covered
revenue`, this sum equals reported total revenue exactly. In the **historical**
columns, `Total Revenue` here is the **reported** deepKPI input (the anchor), and a
foot-check memo confirms the components tie to it. In the **projection** columns the
inversion applies: `Total Revenue` is written **directly as the sum** of its
components (§ see Projections).

### 5.2 — Layout

```
  Consolidated Revenue                                                        [indent 1; bold + underlined header — NOT all caps, NOT enlarged; it is still under REVENUE]
    Revenue from <Stream>                               (USD in <scale>)        [indent 2; FORMULA = the §3 total, this col — same label as that row]
    Revenue from <Non-ARPU Stream 1>                    (USD in <scale>)        [indent 2; FORMULA = §4 stream row, this col — same label as that row]
    Revenue from <Non-ARPU Stream 2>                    (USD in <scale>)        [indent 2; FORMULA = §4 stream row, this col — same label as that row]
    Other Revenue                                       (USD in <scale>)        [indent 2; FORMULA = §4 'Other Revenue' residual, this col; only if §4 has it]
  Total Revenue                                       (USD in <scale>)        [indent 1, bold; SUM-BAR; historical: deepKPI INPUT — reported total revenue; projection: FORMULA = sum of components]
    Memo: components − Total (must = 0)               (USD in <scale>)        [indent 2; FORMULA check; 0 every period]
    Memo: ARPU-revenue mix                            (% of total revenue)    [indent 2; FORMULA, optional = Revenue from <Stream> ÷ Total Revenue]
```

The `Consolidated Revenue` header is **bold + underlined, indent once**, and is
**not** all caps or enlarged (it is a sub-section under the `REVENUE` header, not a
top-level section header). `Total Revenue` is **bold** with a **single-lined sum bar**
(thin top border) across the data columns — **no** double border and **no** label
underline; the component rows read top-to-bottom into it; the foot-check memo sits
immediately beneath it. The first component row carries **exactly the label the §3
total carries** (`Revenue from <Stream>` per §1.2) and references it; never introduce a
second name for the same figure.

### 5.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Cell formula | Comment on Col C label cell |
|---|---|---|---|---|
| `Revenue from <Stream>` | | `(USD in <scale>)` | `= <the §3 total, this col>` | `"= the revenue the ARPU block explains (ARPU × Users / Σ buckets); same label as that row."` |
| `Revenue from <Non-ARPU Stream n>` | | `(USD in <scale>)` | `= <§4 stream row, this col>` — same label as that row | `"= the <stream n> line above, which ARPU does not cover."` |
| `Other Revenue` *(if §4 has it)* | DATA_DEPENDENT | `(USD in <scale>)` | `= <§4 'Other Revenue' residual, this col>` | `"= the Other Revenue residual above: revenue not covered by ARPU or a named stream."` |
| `Total Revenue` | | `(USD in <scale>)` | historical: deepKPI **input** — reported total revenue; **projection:** `= <Revenue from <Stream>> + SUM(<non-ARPU stream rows>)` | `"Historical: reported total revenue (input, the anchor). Projection: = covered + Σ non-ARPU streams."` |
| `Memo: components − Total (must = 0)` *(laid with this section — a mixed build)* | DATA_DEPENDENT | `(USD in <scale>)` | `= (<Revenue from <Stream>> + SUM(<non-ARPU stream rows>)) − <Total Revenue>` | `"Foot check: must equal 0 every period."` |
| `Memo: ARPU-revenue mix` *(optional)* | DATA_DEPENDENT | `(% of total revenue)` | `= <Revenue from <Stream>> ÷ <Total Revenue>` (percent) | `"ARPU-covered revenue as a share of total."` |

### 5.4 — Pre-delivery checklist (Consolidated Revenue)

- [ ] The table sums `Revenue from <Stream>` + every non-ARPU stream (+ `Other Revenue`
      residual if §4 has it).
- [ ] `Total Revenue` is the **reported** deepKPI input in the historical columns
      (bold, single-lined sum bar; the `Consolidated Revenue` header is bold +
      underlined but not all caps or enlarged).
- [ ] The `components − Total (must = 0)` memo evaluates to **0** in every historical
      period after recalculation.
- [ ] For a **covers-all** company, this section is skipped and §3 `Total Revenue` is
      the foot (recorded in `BUILD_LOG.md`).
- [ ] After recalculation, **zero formula errors**, and the master identity `Total
      Revenue = Revenue from <Stream> + Σ non-ARPU streams` holds exactly every period.

---

## Section 6 — Worked example (illustrative)

This walks two illustrative companies through the build to show how the rows chain.
**The figures are illustrative** (round numbers for transparency, not any real
issuer's reported data) — the point is the mechanics. Universe = consolidated;
**revenue figures in $ millions**; ARPU in **$ per user per year**; user counts in
**millions of users**. Build window FY2022 (base) → FY2025.

### 6.1 — Case A, covers-all (single blended ARPU)

Reported: a single `Revenue` line (all user-driven) and a single MAU count. The
customer roll-forward's consolidated `EOP` (millions of users): FY2022 100, FY2023
120, FY2024 135, FY2025 150. Reported revenue (USD in millions): FY2022 1,000,
FY2023 1,320, FY2024 1,566, FY2025 1,800.

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Users — roll-forward EOP | | `(users, in millions)` | 100 | 120 | 135 | 150 |
| Total Revenue *(reported input)* | | `(USD in millions)` | 1,000 | 1,320 | 1,566 | 1,800 |
| ARPU *(§2 backsolve = Rev ÷ Users)* | | `(USD per user per year)` | 10.00 | 11.00 | 11.60 | 12.00 |
| ARPU YoY % | | `(%)` | — | +10.0% | +5.5% | +3.4% |

`Total Revenue = ARPU × Users` foots every year (e.g. FY2025: 12.00 × 150m =
$1,800M). Only `Total Revenue` is a deepKPI input; ARPU and the trend are formulas.
Because ARPU covers all revenue, §4 and §5 are omitted and this §3 `Total Revenue`
**is** the consolidated total.

### 6.2 — Case B / mixed (regional ARPU buckets + a services stream)

Reported: `Subscription revenue` split into `US & Canada` and `International`, each
with its own user count (the roll-forward was built Layout B with these two user
buckets), plus a non-user `Services` revenue line. Illustrative FY2025: US&Canada
users 60m at ARPU $20 ⇒ $1,200M; International users 240m at ARPU $2.50 ⇒ $600M.

- **§2 Unit Economics:** `ARPU — US & Canada` = $1,200M ÷ 60m = **$20.00**;
  `ARPU — International` = $600M ÷ 240m = **$2.50** (both backsolved historically).
- **§3 Revenue:** `Revenue — US & Canada` $1,200M + `Revenue — International` $600M ⇒
  `Revenue from Subscriptions` = **$1,800M** (ties to reported subscription revenue).
- **§4 Non-ARPU stream:** `Revenue from Services` reported $150M with a `YoY %`
  memo.
- **§5 Consolidated:** `Revenue from Subscriptions 1,800 + Revenue from Services 150 = Total
  Revenue 1,945`
  (reported total); if reported total were instead $1,975M, a §4 `Other Revenue`
  residual of $30M would be added to make the partition exhaustive, and the
  `components − Total` foot-check = 0. ARPU-revenue mix = 1,800 ÷ 1,945 = **92.5%**.

---

## Projections (forecast years)

After the **historical** build above (Sections 1 – 6) is laid down, recalculated,
and footed (the §5 `components − Total (must = 0)` check passes for a mixed company,
or §3 `Total Revenue` reconciles for covers-all), **extend the entire ARPU build into
the projection window** before the downstream handoff (§7). The projection window is
the **five fiscal years after the last historical year** (`N+1 … N+5`) per the
**Model timeline** in `../../../SKILL.md` — do not redefine it here. Add five more
**annual** columns immediately to the right of the historical block, continuing the
same left → right, oldest → newest order; the build stays **annual**. Most of the
build **drags across as formulas**; only a small set of **drivers** are entered as
forward assumptions.

### Driver styling (applies to every projection driver below)

Mark **every** projection driver cell so it reads as a forward assumption — visually
distinct from both the formula cells and the historical deepKPI input cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **A dashed box on all four sides of each individual driver cell** (openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom` — one complete
  box **per cell**, applied **after** any shared row-border pass so a later border
  write cannot overwrite the box). Do **not** reduce it to a single bottom border.
- **No pale-green fill and no hyperlink** — projection drivers are assumptions, not
  deepKPI-sourced actuals.
- Every **non-driver** projection cell stays standard formula styling (black font, no
  fill, no dashed box) — identical to its historical styling, dragged one column
  right.

### Driver value methodology (the default seed for every driver)

Unless a driver is called out as an exception below, seed each driver cell as:

- **First projection year (`N+1`)** — the **default seed** (`SKILL.md`, Build
  mechanics): the guided value where the orchestrator's guidance table names this
  driver for `N+1`; else the latest year on the issuer's normalized basis where the
  filing discloses one; else the **latest historical year** (`N`), which the renderer
  writes as a live `ISNUMBER`-guarded formula over `N`, `N−1`, `N−2` (0 when none is
  numeric). No year is averaged into the seed.
- **Each later projection year (`N+2 … N+5`)** — **equal to the `N+1` cell** (flat):
  `= <driver N+1 cell>`.
- The modeler may type a specific assumption over any driver cell; the red/dashed
  styling flags exactly which cells are meant to be overwritten.

The projection **drivers** in this build are exactly:

1. **Each ARPU's `YoY %`** (§2) — the trend row under the single
   blended ARPU (Case A) or under each bucket ARPU (Case B). The driver is the
   **growth rate, not the ARPU level**: the level is projected as `prior year × (1 +
   change)`, the way every other per-unit figure in the operating model (revenue per
   restaurant, revenue per store, selling price) is projected. Seeding the level itself would freeze it at the last actual — no growth — and seeding it from an average of past levels would step it down first.
2. **Each non-ARPU stream's `YoY %`** (§4), and the `Other
   Revenue` residual's `Other Revenue — % of modeled revenue` if present.

`Users` is **not** a new driver here — each `Users` reference (Case A consolidated,
Case B bucket) points at the customer roll-forward's **projected** `EOP`, which
`../customerRollForward/customerRollForward.md` already turned into a driven roll (its
`Net New Additions` is the driver) in its own Projections section. Reference the
projected EOP; do not re-seed it.

### Part 1 — Unit Economics (§2): ARPU inverts from backsolve to driver

In the projection columns each ARPU stops being the backsolve and becomes the driver:

- **`YoY %`** (the trend line under each ARPU) — the **driver**
  (red/dashed; `N+1` = the default seed: the guided value, else that ARPU's latest historical change (`N`); `N+2 … N+5` = `N+1`). Historically it was the derived `= this col ÷ prior col − 1`;
  in projection it is the assumption the ARPU row compounds off.
- **`ARPU`** (Case A) / **`ARPU — <Bucket n>`** (Case B) — a **black formula** in
  projection: `= <prior col ARPU> × (1 + <YoY %, this col>)`.
  Historically it was the backsolve `covered / bucket revenue ÷ users`; forward it
  continues the actuals from the year-`N` level at the seeded rate, with no step at
  the boundary. The modeler dials the rate, never types a level.
- **`Reported ARPU (memo)`**, if present — a historical-only input; leave its
  projection cells blank (dash).

### Part 2 — Revenue (§3): the identity computes forward

- **Case A.** `ARPU` — references §2's now-driven ARPU (`= §2 ARPU, this col`).
  `Users` — references the roll-forward's **projected** consolidated `EOP` (this col).
  `Total Revenue` — now the **formula** `= ARPU × Users` (no longer a reported input).
- **Case B.** Each `Revenue — Bucket n` — now the **formula** `= <§2 'ARPU — Bucket
  n', this col> × <Bucket n projected EOP Users, this col>`. `Total Revenue` —
  **unchanged formula** `= SUM(bucket revenue rows)` in both halves; drag it across.
- **`YoY %`** — unchanged formula (`= this col ÷ prior col − 1`).

No new driver appears in §3; its drivers live in §2 (ARPU) and, indirectly, in the
customer roll-forward (projected users).

### Part 3 — Non-ARPU Revenue Streams (§4): driver = each stream's YoY %

For each non-ARPU stream:

- **`YoY %`** — the **driver** (red/dashed; `N+1` = the default seed: the guided value, else the latest historical `YoY %` value; `N+2 … N+5` = `N+1`).
- **`Revenue from <Stream n>`** — unchanged **for historical** (reported deepKPI input). For
  **projection**: `= <prior column stream value> × (1 + <YoY %, this
  column>)` — the input → compounding inversion (the stream compounds off its own
  prior value by the driver).
- The `Other Revenue` residual, if it exists, is **no longer a subtraction** in
  projection (that would be circular against `Total Revenue`). It is projected as a
  **share of modeled revenue**: `= <Other Revenue — % of modeled revenue, this col> ×
  (<covered revenue, this col> + SUM(<named stream rows>, this col))`, the driver row
  beneath it seeded by the default seed like every other driver. The denominator
  excludes the residual itself, so there is no circularity. Add one Notes line:
  `Revenue: in the forecast Other Revenue is a share of modeled revenue, held at the
  latest ratio, rather than a plug.`

### Part 4 — Consolidated Revenue (§5): Total becomes the sum

- **`Revenue from <Stream>`** and each **`Revenue from <Non-ARPU Stream n>`** / **`Other Revenue`**
  component row — the **same reference formulas** as the historical columns; drag them
  across (they now point at the projected §3 / §4 values).
- **`Total Revenue`** — the **foot**. The identity `Total Revenue = Revenue from <Stream> +
  Σ non-ARPU streams` holds in both halves, so `Total Revenue` is **never a driver**.
  Historically it is the **reported deepKPI input**; in projection it is written
  **directly as the sum** of its component rows: `= <Revenue from <Stream>> + SUM(<non-ARPU
  stream rows>)`. The `components − Total (must = 0)` foot-check then evaluates to
  **0** in every projection year (trivially). For a **covers-all** company there is no
  §5; §3 `Total Revenue = ARPU × Users` (Case A) / `= SUM(buckets)` (Case B) is the
  projected total.

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=` formula
  (no hardcoded numbers). The **only** seeded/typed cells are the drivers: each
  ARPU's `YoY %` (§2) and each non-ARPU stream's `YoY %` (§4). No ARPU level is typed.
- **Driver seeding.** Each driver's `N+1` = the default seed (the guided value where the guidance table names it, else the latest historical year) and `N+2 … N+5` = `N+1`.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors** and **no circular references** (confirm §3 revenue ↔ §2 ARPU is a
  one-directional reference in each half, and the §4 residual is a share of modeled revenue rather
  than a subtraction in projection).
- **Foot.** For a mixed company, the §5 `components − Total (must = 0)` memo equals
  **0** in every projection year; for a covers-all company, §3 `Total Revenue` equals
  `ARPU × Users` (A) / `Σ buckets` (B) every projection year.
- **Continuity at the boundary.** `N+1` `Users` equals the roll-forward's `N+1`
  projected EOP; `N+1` ARPU equals `N` ARPU × (1 + the seeded change), so the level
  continues the actuals rather than resetting to an average; `N+1` for each non-ARPU
  stream compounds off its `N` value — the projection joins the actuals with no gap
  or jump.

---

## Section 7 — What the ARPU build produces for downstream sections

After Sections 1 – 5 are built, the workbook contains, for every period in the
window, a fully-footed ARPU revenue build beneath the customer / user roll-forward: a
`Unit Economics` block (ARPU per covered stream or bucket, with its trend), a
`Revenue` block reconstructing `Total Revenue = ARPU × Users` (Case A) or `Σ bucket
ARPU × bucket users` (Case B), any non-ARPU streams projected on a YoY % basis, and — for a mixed company — a `Consolidated Revenue` table whose `Total
Revenue` foots to reported revenue. Every component is a live formula flowing from the
user counts, the ARPU / stream inputs, and the reported-revenue anchor. Downstream
operating-model sections (costs, consolidated financials) reference `Total Revenue`
and the component lines (the covered revenue, each non-ARPU stream) directly; any
later change to the customer roll-forward, an ARPU driver, or a stream input
propagates automatically through the entire ARPU build and keeps the foot intact.

Report back to the router, in one line each: whether the company was **Case A or
Case B** and **covers-all or mixed** (and which stream the ARPU covered), the
historical window used, and the row addresses of `Total Revenue`, the covered-revenue
line, and each non-ARPU stream so downstream sections can reference them without
re-deriving anything.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's ARPU lines; the customer / user roll-forward and all non-revenue
sections are owned by their respective skills.*
