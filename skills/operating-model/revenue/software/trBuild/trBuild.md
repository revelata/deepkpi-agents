---
name: revenue-software-take-rate
description: >
  Take-rate revenue build for booking-based software / technology companies in the
  operating-model workbook. Invoked by the software router
  (`revenue/software/software.md`) after its Step 4 routing when the company is a
  platform that intermediates orders / transactions and recognizes revenue as a
  slice of that volume — it reports a total-bookings series (Gross Bookings / GMV /
  GOV / TPV / GTV) and a revenue line that maps to that volume. Uber, DoorDash, and
  Stripe are canonical examples. By the time this build runs, the shared KPI
  inventory is known and, if customer data was present, the customer roll-forward
  has already been laid down by `customerRollForward/customerRollForward.md`.
  Receives the resolved `company_id`, official company name, workbook path, the
  shared KPI inventory, the KPIs that satisfied the take-rate criteria, and (if it
  ran) the row addresses of the customer roll-forward. The build reconstructs
  revenue from the identity `Revenue = Bookings × Take Rate`, decided per booking
  stream, and supports two approaches to arrive at Bookings: Approach 1
  (Driver → Bookings → Take Rate → Revenue), where an operational driver — trips,
  orders, active accounts — is grown forward and a backsolved Bookings-per-Driver
  rebuilds bookings; and Approach 2 (Bookings → Take Rate → Revenue), where bookings
  is projected directly off its own period-over-period change. It builds a Unit
  Economics block (bookings and its driver decomposition, with YoY %
  trend rows), a Take Rate block (reported or backsolved = revenue ÷ bookings, with
  a YoY % driver), and a Consolidated Revenue table that sums each
  stream's revenue (Take Rate × Bookings) plus any non-booking streams
  (each on its own YoY % driver) and foots to reported total revenue. Pulls series via
  `search_kpis` from the shared inventory; format per
  ../../../../_common/revelata-excel-styling-rules.md and this file's own conventions
  block (one row per series, derived cells as live formulas) EXCEPT for time scope
  (last 4 fiscal years), which this build overrides. Sections:
  §1 isolate booking-driven revenue + pick the approach + enumerate streams, §2 Unit
  Economics (Bookings), §3 Take Rate, §4 Consolidated Revenue + foot, §5 worked
  example, Projections, §6 downstream handoff.
---

# revenue — software — take-rate build

This is the **take-rate** software revenue build. It is invoked by the software
router (`../software.md`) at its Step 4 hand-off when the company is a
**booking-based platform** — a business that intermediates orders / transactions
between parties and recognizes revenue as a **slice of that volume**. It satisfied
the router's take-rate criteria: it reports **Total Bookings** (Gross Bookings /
GMV / GOV / TPV / GTV) and a **revenue line that maps to that booked volume** —
and because the orchestrator's industry classification designated the company's
revenue model as `platform` from its business description. The router's implied
take-rate sanity check (`revenue ÷ bookings` well below one every year) has run;
if it flagged the mapping, confirm the bookings series against the 10-K before §2.

At its core a take-rate build is one identity:

```
  Revenue = Bookings × Take Rate
```

Everything below is the disciplined way to (a) arrive at **Bookings**, (b) source or
backsolve the **Take Rate**, and (c) wire the identity so the build foots to
reported total revenue and projects cleanly. There are **two approaches** to arrive
at bookings, and Section 1 decides which one applies:

```
  Approach 1:   Driver → Bookings → Take Rate → Revenue
  Approach 2:            Bookings → Take Rate → Revenue
```

- **Approach 1 (Driver → Bookings).** There is an operational **driver** that
  generates the booked volume — for a rideshare platform, **trips**; for a food
  platform, **orders**; for a payments platform, **transactions**. Bookings does not
  stand on its own; it is reconstructed as `Bookings Driver × Bookings per Bookings
  Driver`. The driver (e.g. trips) is projected on a period-over-period change, a
  **Bookings-per-Driver** unit (e.g. bookings per trip = the average booked value per
  trip) is **backsolved** for every historical period and projected on its own
  period-over-period change, and Bookings is rebuilt as their product. Use this
  approach when a clean operational driver of the booked volume is reported and
  modeling the driver forward is more defensible than growing bookings blindly.
- **Approach 2 (Bookings direct).** Bookings is taken as the reported series and
  **projected directly** off its own period-over-period change — no driver
  decomposition. Use this approach when no clean operational driver is reported, or
  when the driver adds no forecasting power over simply trending bookings.

By the time control reaches this build, three things are already established and
must **not** be re-litigated:

1. the company **is in the software / technology industry** (decided by the parent
   revenue router, `../../revenue.md`);
2. the company **qualifies for the take-rate build** (decided by the software
   router's Step 2 criteria B — it **is** a booking-based business **and** reports
   total bookings + corresponding revenue); and
3. **if customer data was present**, the **customer roll-forward has already been
   laid down** in the workbook by `../customerRollForward/customerRollForward.md`
   (the router runs it as a conditional pre-build before routing here). This build
   references those counts **only if** its bookings driver is a customer / account
   count already on the sheet; otherwise it sources its driver directly. It never
   re-derives the roll-forward.

**Inputs expected from the router:** resolved `company_id`, official company name,
the path to the scaffold workbook, the **shared KPI inventory** from the
orchestrator, the router's note of which KPIs satisfied the take-rate criteria (the
total-bookings series, the corresponding revenue series, and a reported take rate if
one exists), and — **if the customer roll-forward ran** — the **row addresses** of
its consolidated `EOP` / `Net New Additions` so this build can reference them if its
driver is a customer count.

**Data source:** deepKPI only — see `../../../../_common/data-source-rules.md`. On
failure, follow `../../../../_common/connection-failure.md`.

**Formatting:** follow `../../../../_common/revelata-excel-styling-rules.md` and the
**Conventions** block in this file's framework overview, and build with the **xlsx**
skill. All conventions there apply here — the four-column label system (Col A hidden deepKPI string, Col B
hidden index, Col C display label, Col D units tag, Col E onward data), one row per
distinct series, deepKPI-sourced values as pale-green hyperlinked input cells, and
**every** total / derived cell as a live `=` formula (never a hardcoded number) —
**except** for the **time scope**, which this build overrides per the "Time scope"
section below.

## Time scope (overrides the common styling rules)

This rule **overrides** the corresponding convention in
`../../../../_common/revelata-excel-styling-rules.md` for this build:

- **Time scope — historical window = last 4 fiscal years.** Limit the historical
  columns to the **four most recent fiscal years** for which deepKPI has data
  (`N−3 … N`, where `N` is the last historical year). Older years are dropped. If a
  customer roll-forward was laid down, use the **same four annual period columns** it
  used, so every bookings / take-rate / revenue cell sits directly under the matching
  count cell.
- **The take-rate build is ANNUAL.** Bookings, the take rate, and revenue are modeled
  as an annual build, so this build uses **annual columns only** (one per fiscal
  year, oldest → newest, left → right). Do **not** add quarterly columns.
- **No quarterly supporting data (unless an annual value must be summed from quarters).**
  Do **not** add quarterly figures as supporting rows to the sheet — unless a section of
  this build explicitly states otherwise, every KPI is sourced at its **reported annual
  value**. The lone exception: if deepKPI has **no reported annual value** for a needed
  KPI and the annual figure must be built by **summing that KPI's four quarters**, bring
  the four quarterly rows in as supporting rows and sum them to the annual figure,
  placed in an outline group left expanded (no row is hidden; styling rules). Absent
  that summing need, no quarterly rows appear.
- **Projection years.** Per the canonical **Model timeline** in the orchestrator
  `../../../SKILL.md`, the projection window is the **five fiscal years after the
  last historical year** (`N+1 … N+5`; e.g. last historical FY2025 → projections
  FY2026–FY2030). This build lays down the **historical** columns first (Sections 1
  – 5), then **extends the entire take-rate build into the projection window**
  following the **Projections (forecast years)** section near the end of this file.
  Do not fabricate projection values outside that procedure.

> This build is authored section by section. The sections present here — §1 the
> booking-driven-revenue isolation and §2 – §6 the revenue build (Unit Economics,
> Take Rate, the consolidated revenue foot, a worked example, and the downstream
> handoff), plus the **Projections (forecast years)** section near the end that
> extends the build into `N+1 … N+5` — are the implemented scope. Do not build or add
> any new information outside the sections present here.

---

## Section 1 — Isolate the booking-driven revenue, pick the approach, and enumerate the streams

This is the **first section** of the take-rate build and its analytical foundation.
Before any Unit Economics, Take Rate, or Revenue row is written, you **must** decide,
from the filing and the KPI inventory: **which revenue the `Bookings × Take Rate`
identity covers**, **which approach** (1 or 2) reconstructs bookings, **how many
booking streams** there are, and **which revenue (if any) is not booking-driven** and
must be modeled separately as a non-booking stream.

**Why this matters (STRICT).** `Bookings × Take Rate` only reconstructs the revenue
that the booked volume actually generates. If a company reports a booking-driven
stream **and** another stream the bookings do not produce (subscription /
membership fees, advertising, interest income, one-time fees, hardware, etc.),
running the take-rate identity on blended total revenue silently corrupts the take
rate and double-counts once the other stream is added back. The goal of this section
is that **the revenue fed through the take-rate identity is genuinely the
booking-driven revenue**, everything else is carved out as a **non-booking stream**
(Section 4), and the whole build foots to reported total revenue.

### 1.1 — Read the filing and inventory to fix the bookings, the revenue, and the driver

Three things must be extracted before any row is written:

1. **The total-bookings series** — the `$ amount of orders / transactions booked on
   the platform`. Confirm its name and `unit` (dollars) in the inventory: `Gross
   Bookings`, `Gross Merchandise Value (GMV)`, `Gross Order Volume (GOV)`, `Total
   Payment Volume (TPV)`, `Gross Transaction Value (GTV)`, `Bookings`, `Merchandise
   volume`. If the company reports bookings **per segment / product** (e.g. Mobility
   Gross Bookings vs Delivery Gross Bookings), note each — these become the **booking
   streams** (below).
2. **The revenue that maps to those bookings** — the numerator of the take rate. For
   a pure marketplace this is usually **total revenue**; for a mixed company it is the
   **booking-driven revenue only** (e.g. `Marketplace revenue`, `Transaction
   revenue`, or the segment revenue that maps to each booking stream). Read the
   revenue-disaggregation footnote and MD&A to confirm which line each booking stream
   produces.
3. **Whether a clean operational driver of the booked volume is reported** — the
   Approach-1 / Approach-2 decision. Look for a volume **count** that generates
   bookings: `Trips`, `Orders`, `Transactions`, `Deliveries`, `Rides`, `Active
   accounts`, or similar. If a sensible driver exists and modeling it forward is
   defensible, this is **Approach 1**; if none exists or it adds nothing, **Approach
   2**.

**Workflow:**

1. Pull the latest 10-K markdown via the **filing** skill
   (`list_sec_filing_markdowns` → `get_sec_filing_markdown`).
2. Search the markdown for the key-metrics / operating-metrics table and the
   disaggregated revenue table (tokens: `Gross Bookings`, `GMV`, `GOV`, `TPV`, `Take
   rate`, `Trips`, `Orders`, `Transactions`, `Disaggregation of revenue`, `Revenue by
   segment`, `Revenue by type`). Read the surrounding paragraphs to confirm which
   revenue each booking stream produces and whether a driver of the booked volume is
   disclosed.
3. Confirm each series you intend to use (each bookings series, each corresponding
   revenue series, any driver series, any reported take rate, any non-booking stream)
   is present in the shared KPI inventory (via `search_kpis`), reading the `unit`
   field to confirm dollars vs. counts vs. percentages. Record **which revenue the
   take rate covers**, **how bookings is obtained** (reported, or built from a driver),
   and **which streams (if any) are carved out to non-booking streams** as one line
   per booking stream in the workbook's Notes block, in the analyst's words:
   `Revenue: the take rate is <stream revenue> divided by <bookings caption>;
   bookings are <reported / built as <driver> times bookings per <driver>>;
   <streams> are carried separately.` No note row is laid inside the block. Which
   approach (1 or 2) applies to each stream goes to `BUILD_LOG.md` (the stage's
   hand-back report carries the same), not to the sheet.

### 1.2 — Approach 1 vs Approach 2 (how bookings is reconstructed)

Exactly one approach applies per build (and, if streams differ, per stream — see
§1.3), and the Unit Economics shape (§2) follows from which one it is:

- **Approach 1 — Driver → Bookings.** A reported operational **driver** generates the
  booked volume. Bookings is reconstructed as `Bookings Driver × Bookings per
  Bookings Driver`:
  - **Bookings Driver** (e.g. Trips) — reported deepKPI **input** historically;
    projected off its own **YoY %** driver.
  - **Bookings per Bookings Driver** (e.g. Bookings per Trip = average booked value
    per trip) — **backsolved** historically (`= Bookings ÷ Bookings Driver`);
    projected off its own **YoY %** driver.
  - **Bookings** — reported deepKPI **input** historically (the listed value);
    projected as `Bookings Driver × Bookings per Bookings Driver`.

- **Approach 2 — Bookings direct.** No driver decomposition. **Bookings** is the
  reported deepKPI **input** historically and is projected directly off its own
  **YoY %** driver (`= prior × (1 + YoY %)`). The Unit
  Economics block collapses to the single `Bookings` line plus its `YoY %` trend.

Record which approach applies (and the driver, for Approach 1) in `BUILD_LOG.md`;
the Notes line from §1.1 says how bookings is obtained without the approach name.
Do **not** default to Approach 2 because it is simpler when a clean driver of
the booked volume is reported — but do **not** invent a driver that has no economic
link to bookings just to use Approach 1. The driver must be a series whose product
with a backsolved per-driver value **reproduces reported bookings exactly** every
historical year (it does, by construction, because the per-driver is the backsolve).

### 1.3 — One booking stream or several

A platform may report **one** consolidated booking stream or **several** (e.g. a
rideshare parent with Mobility and Delivery). The build is laid out **one block per
booking stream**:

- **Single stream.** One Unit Economics block, one Take Rate line, one Revenue line;
  the consolidated table is trivial (one component + any non-booking streams).
- **Multiple streams.** One Unit Economics block **per stream** (each with its own
  approach, driver if any, bookings, and YoY % trend), one Take Rate
  line **per stream**, and one Revenue line **per stream**, all summed in the
  consolidated table (§4). Streams appear in a **fixed order** and that same order is
  used in the Take Rate block and the Consolidated Revenue table.

Each stream may independently be Approach 1 or Approach 2 (e.g. one segment has a
clean driver and another does not) — decide per stream and record each choice in
`BUILD_LOG.md`.

### 1.4 — The take rate: reported or backsolved

The **take rate** is `Revenue ÷ Bookings`. It **may** be reported by the company (in
the key-metrics table, possibly named `Take rate`, `Net revenue margin`, or `Revenue
as a % of Gross Bookings`), **but it likely is not**. This build's **default and
preferred** historical treatment is to **backsolve** the take rate as `booking-driven
revenue ÷ bookings`, because that guarantees `Bookings × Take Rate` foots to the
reported revenue exactly. If the company **also** reports a take rate directly, carry
it as an optional **memo cross-check** row (§3) and, where the two differ, add one
Notes line: `Revenue: the issuer's reported take rate is <definition>; the model's
is stream revenue divided by bookings, so the two differ.` Do **not** substitute
the reported take rate for the backsolved one that anchors the identity (a reported
take rate may use a different bookings or revenue definition and will not tie the
identity exactly).

### 1.5 — Carve out non-booking (Other) revenue

Independently of the approach and stream count, the booking-driven revenue may be
**only part of reported total revenue**:

- **Bookings cover all revenue** — the booking-driven revenue **is** reported total
  revenue. There is no separate non-booking stream; the Consolidated Revenue table
  (§4) simply sums the stream revenues to Total Revenue.
- **Bookings cover only part (mixed)** — the company also has revenue the bookings do
  **not** generate (subscription / membership fees, advertising, interest, one-time
  fees, etc.). Each such stream is a **non-booking stream** (§4), **projected on its own
  growth driver** (not the take-rate identity); §4 sums the booking-driven stream revenues and
  the non-booking stream(s) and foots to reported total revenue.

Record whether the build is **covers-all** or **mixed** in `BUILD_LOG.md`, and the
**segment map** with it (`../../../SKILL.md`, "The segment map"): the keys of the
stream rows that make up each issuer segment's revenue, or an empty map when the
streams do not follow the segment disclosure; the Notes line from §1.1 names the
streams carried separately. Do **not** bury a
genuine, material non-booking stream inside the take rate — carve it out and
project it as a non-booking stream.

### 1.6 — Pre-delivery checklist (isolation)

- [ ] One Notes line per booking stream states **which revenue the take rate
      covers**, **how bookings is obtained** (reported, or built from the named
      driver), and which streams are carried separately, in the analyst's words
      (§1.1); no note row sits inside the block. The approach (1 or 2) per stream and
      covers-all vs mixed are in `BUILD_LOG.md`.
- [ ] The take-rate numerator is confirmed to be the **booking-driven revenue** those
      bookings actually generate — not a blended total when a distinct non-booking
      stream exists.
- [ ] Each series to be used (each bookings series, each corresponding revenue, any
      driver, any reported take rate, any non-booking stream) is present as its own
      deepKPI series (confirmed via `search_kpis`, correct `unit`), or a sourcing gap
      is documented.
- [ ] Approach 1 is chosen **only** when a driver with a genuine economic link to the
      booked volume is reported; otherwise Approach 2, with the reason in
      `BUILD_LOG.md`.
- [ ] No non-booking revenue leaked into the take-rate identity.

---

## Revenue build — framework overview (Sections 2 – 4)

Section 1 fixed the take-rate numerator, the approach, the streams, and the
carve-out. Sections 2 – 4 turn bookings into revenue via the take rate, model any
non-booking streams alongside, and foot the whole build to the company's
**reported total revenue**. The build follows one fixed framework so that **every**
take-rate company is modeled the same way and the workbook always foots.

**The master identity.** Revenue is reconstructed per booking stream from bookings
and the take rate, and consolidated revenue is the sum of the stream revenues plus
any non-booking streams:

```
  Approach 1:   Bookings_stream = Bookings Driver_stream × Bookings per Bookings Driver_stream   (§2)
  Approach 2:   Bookings_stream = reported / trended directly                                    (§2)

  Revenue_stream = Bookings_stream × Take Rate_stream                                            (§3 / §4)

  Total Revenue  = Σ ( Bookings_stream × Take Rate_stream ) + Σ non-booking streams [+ Other Revenue residual]   (§4 foot)
```

In the **historical** columns each stream's booking-driven revenue is the **reported**
deepKPI input (the anchor), and the take rate is **backsolved** from it — so
`Bookings × Take Rate` reproduces the reported revenue **by construction**. The
consolidated table foots to reported total revenue because the non-booking
stream(s) — plus a residual `Other Revenue` line if the identified streams do not
exhaust the remainder — form an **exhaustive partition** of `Total Revenue −
Σ stream revenue` (see §4).

**Build the revenue lines in this order**, each beneath the customer roll-forward (if
one was laid down) or beneath the `REVENUE` header:

1. **Section 2 — Unit Economics (Bookings).** One `Bookings — <Stream>` line per
   booking stream (and, for Approach 1, its `Bookings Driver` / `Bookings per Bookings
   Driver` decomposition), each with a `YoY %` trend sub-block; when
   two or more streams exist, a `Total Bookings` roll-up row (bold, sum bar) sums them.
   Historical bookings is the reported input; Approach-1 `Bookings per Bookings
   Driver` is the backsolve.
2. **Section 3 — Take Rate.** One take-rate line per booking stream (backsolved =
   revenue ÷ bookings historically; a reported take rate carried as a memo), with a
   `YoY %` sub-block whose rows are the **projection drivers**.
3. **Section 4 — Consolidated Revenue.** Each stream's revenue (`Take Rate ×
   Bookings`), plus any non-booking stream(s) projected on their own
   `YoY %` drivers,
   summed to `Total Revenue` and footed to the reported figure.

**Conventions that apply to all of Sections 2 – 4 (read once):**

- **Annual columns only**, the same four the customer roll-forward used (if one
  exists), oldest → newest, left → right.
- **Reference the roll-forward only when the driver is a count it carries.** If the
  Approach-1 `Bookings Driver` is a customer / account count the roll-forward already
  laid down, reference that cell with a live `=` formula rather than re-entering it.
  If the driver is a non-customer volume (trips, orders, transactions), source it
  directly via `search_kpis` — the roll-forward does not carry it. Never hardcode a
  count.
- **Inputs vs. formulas (unchanged from the styling rules).** Only values taken
  straight from deepKPI (each stream's reported bookings, each stream's reported
  booking-driven revenue, each reported Approach-1 driver, any reported take rate
  carried as a memo, each reported non-booking stream, and reported total revenue) are
  **input cells** (pale-green fill,
  dark-blue hyperlinked value
  linked to the filing). **Every other cell is a live `=` formula** (black font, no
  fill) — the Bookings-per-Driver backsolve, the reconstructed bookings product, the
  take-rate backsolve, the `Take Rate × Bookings` revenue, every `YoY %` row, the sums, and the foot check. Never hardcode a computed number.
- **Label / comment / spacing discipline.** Col C labels are **plain descriptive
  text**; the operand recipe for each formula row goes in a **cell comment on the Col
  C label cell** (author `Take-Rate Build`), not in the visible label. Indentation is
  applied with the cell's **actual indent property** — openpyxl
  `Alignment(indent=n)` (`indent=1` for one level, `indent=2` for two) — and **never
  with leading spaces**. Leading spaces are prohibited because the block-header
  underline (`Font(underline="single")`) draws under the padding characters and
  produces a ragged rule that runs left of the text; an actual indent shifts the label
  without adding any underline-able characters, so the underline sits cleanly under the
  label only. When setting a cell's `Alignment`, keep the existing
  `horizontal`/`vertical` settings and add `indent=n` — do not prepend spaces to the
  string. **Block / section headers are bold + underlined at `indent=1`**; **main line
  items sit one level deeper, at `indent=2`**, and a block's total (`Bookings`, `Total
  Revenue`) returns to `indent=1`, bold; **memos sit at the items' level and a trend
  row one level deeper than the line it belongs to** — the renderer sets every data
  row's indent from its kind (styling rules). Blocks are separated by **one blank spacer row**.
  Additionally, **skip one blank row directly above a full `YoY %`
  sub-block** — a `YoY %` **label-only row that heads two or more
  indented per-line trend rows** (it mirrors several line items beneath it, e.g. one
  trend row per stream). Do **not** skip when the `YoY %` heads a
  **single** trend row, or is a **lone derived-display growth line under one total / KPI**
  (e.g. the `YoY %` nested directly beneath `Total Revenue`, or a one-KPI
  `Bookings → Total Bookings → YoY %`) — that row sits directly beneath its
  parent with no blank row above it. The exact
  per-row indent / bold / underline / sum-bar recipe is codified in the **Canonical
  formatting template** immediately below — follow it for every take-rate build,
  extending the stream count to whatever the company reports.
- **Border discipline (whole sheet).** **Never use a double-lined border anywhere.**
  Every subtotal / total row (each stream's `Bookings`, the multi-stream
  `Total Bookings`, each reconstructed total, and `Total Revenue`) is marked with a
  **single-lined "sum bar"** — a thin top border
  applied **only across the data columns (Col E onward)**, never a double line and
  never a bottom border on the row above. Total rules never run through the label
  columns (Col A–D). Reserve the **font underline** (`Font(underline="single")`) for
  **block / section headers**; total rows are **bold only** (no label underline) —
  their total is conveyed by the single-lined sum bar across the data columns.
- **Memo rows stay visible.** Every **memo** line item (e.g. `Reported Take Rate (memo)
  — <Stream n>` in §3, `Memo: components − Total (must = 0)` in §4) is an ordinary
  visible italic row; no row on the sheet is hidden or collapsed (styling rules).
- **Number format and units.** Storage, the number-format strings, and the tag grammar
  come from `../../../../_common/revelata-excel-units-and-scale.md`, and every row's
  family follows from that file's Rule 4 — an input row's from its deepKPI `unit` field,
  a derived row's from the dimensions of its formula. **The Col D tag for every row this
  build writes is shown in the layout block of its own section** — §2.2 (both
  approaches), §3.2 and §4.2 — and in the `Units (Col D)` column of that section's
  formula table. Dollar rows show the placeholder `(USD in <scale>)`: the contract's
  Rule 2 supplies the scale, millions by default, thousands where the digit test puts a
  small filer. Four classifications are specific to this build:
  - **The driver row is a count in the issuer's own unit, at the scale the digit test
    and coherence give.** The `<Driver>` row is tagged `(<driver>, in <scale>)` with the
    noun the issuer reports — `(trips, in millions)`, `(orders, in millions)`, `(nights,
    in millions)`; this is the one row whose noun comes from the issuer, because the
    driver *is* whatever the issuer counts. Its scale is chosen so that `Bookings per
    <Driver>` reconciles on the page: bookings in millions ÷ driver in millions = plain
    dollars per unit, so a reader can divide the two rows above and land on the per-unit
    row. For every platform this route reaches the driver is in the hundreds of millions
    or more and lands on millions; a smaller count takes the scale the digit test gives,
    and the per-unit row's tag follows (money in millions ÷ a count in thousands is
    thousands of dollars per unit). Do **not** leave the driver in ones while bookings
    are in millions — the per-unit row would then not reconcile against the two rows it
    is derived from.
  - **`Bookings per <Driver>` is `(USD per <driver>)`** — per-unit money in natural
    dollars (`13.33`), never scaled to millions, with the driver noun in the tag so the
    unit is named (`(USD per trip)`).
  - **Take rates name their denominator.** `Take Rate — <Stream n>` divides revenue by
    bookings and is tagged `(% of bookings)`; where the issuer's term for booked volume
    is different — gross order value, gross merchandise value — use that term, `(% of
    GOV)`, `(% of GMV)`. The optional `Reported Take Rate (memo)` row takes the same tag
    as the row it checks.
  - **Every `YoY %` row is bare `(%)`** — the period-over-period change
    the contract's Rule 5 reserves the bare tag for; the tag is the same whether the
    cell is a historical formula or a projection driver. The `YoY %`
    label-only rows that head each trend sub-block carry no tag.
- **Reading the layout blocks (§2.2, §3.2, §4.2).** Each row's annotation has two
  columns, left to right: the **Col D units tag in parentheses** — `(USD in <scale>)`
  means the contract's Rule 2 sets the money scale; `<driver>` is replaced by the
  issuer's driver noun; every other tag is written as it goes in the cell — and the note
  in **square brackets**: the row's real cell indent, then `deepKPI INPUT …` for a
  pulled value, `FORMULA …` for a computed row, the projection treatment, and styling
  (`bold`, `SUM-BAR`, `italic`). Block headers and `YoY %` label-only
  rows carry no tag.

The sub-sections below specify each component cell-by-cell. Build them in order; do
not add revenue lines outside this framework.

### Canonical formatting template (indent / bold / underline / sum-bar map)

Every take-rate build lays its three revenue blocks out in the row order and cell
formatting below. **Indent** is the **actual cell indent** (`Alignment(indent=n)`),
never leading spaces (see the spacing discipline above). Extend the stream list
(`Stream 1 … Stream k`) to whatever the company reports; a **single-stream** build
drops the ` — <Stream>` suffix, and its `Total Bookings` / `Total Revenue` collapses
onto the single stream line (the lone `Bookings` / `Revenue` row already carries the
bold + sum bar, so no separate total row is added).

**This template governs *format* only — it removes no existing functionality.** The
multiple-bucket classification from §1.3 is retained: when bookings report in several
buckets (e.g. Mobility, Delivery), each stays its **own** `Bookings — Stream n` line
in its respective bucket, and the per-stream **Approach-1 driver decomposition**
(`Bookings Driver`, `Bookings per Bookings Driver`) is still built inside that
stream. The template simply fixes the indent / weight / rule of every row and adds
the `Total Bookings` roll-up across buckets.

**Unit Economics (§2)**

```
  Unit Economics                    indent 1  · bold + underline            (block header)
    [ per Approach-1 stream, above that stream's Bookings line: ]
  <Driver> — Stream n               indent 1                                (label = driver's actual name, e.g. Trips; reported input / driven fwd)
  Bookings per <Driver> — Stream n  indent 1                                (e.g. Bookings per Trip; backsolve / driven fwd)
  Bookings — Stream 1               indent 1                                (reported input; its own bucket)
  Bookings — Stream 2               indent 1
  Bookings — Stream 3               indent 1
  Total Bookings                    indent 1  · bold · single-lined sum bar (= Σ Bookings — Stream n)
  [ skip one blank row above the full YoY % block ]
  YoY %              indent 1  · bold + underline            (label-only row)
    Bookings — Stream 1             indent 2                                (YoY; DRIVER in projection)
    Bookings — Stream 2             indent 2
    Bookings — Stream 3             indent 2
```

**Take Rate (§3)**

```
  Take Rate                         indent 1  · bold + underline            (block header)
  Take Rate — Stream 1              indent 1                                (backsolve / driven fwd)
  Take Rate — Stream 2              indent 1
  Take Rate — Stream 3              indent 1
  [ skip one blank row above the full YoY % block ]
  YoY %              indent 1  · bold + underline            (label-only row)
    Take Rate — Stream 1            indent 2                                (YoY; DRIVER in projection)
    Take Rate — Stream 2            indent 2
    Take Rate — Stream 3            indent 2
```

**Consolidated Revenue (§4)**

```
  Consolidated Revenue              indent 1  · bold + underline            (sub-section header; NOT all caps, NOT enlarged)
  Revenue from Stream 1                indent 1                                (reported input / Take Rate × Bookings)
  Revenue from Stream 2                indent 1
  Revenue from Stream 3                indent 1
  [ Revenue from <Non-booking Stream n>   indent 1   one row per non-booking stream ]
  [ Other Revenue                   indent 1   the residual, only if needed ]
  Total Revenue                     indent 1  · bold · single-lined sum bar (= Σ Revenue from Stream n + Σ non-booking streams [+ Other Revenue])
  [ skip one blank row above the full YoY % block ]
  YoY %              indent 1  · bold + underline            (label-only row)
    Revenue from Stream 1              indent 2                                (YoY)
    Revenue from Stream 2              indent 2
    Revenue from Stream 3              indent 2
```

**Rules baked into the map above:**

- **Bold rows** are exactly: the three block/section headers (also underlined), each
  `YoY %` label row (also underlined), and the two roll-up totals
  `Total Bookings` / `Total Revenue` (bold + sum bar, **no** underline). Every other
  row is plain.
- **Never underline a total row.** `Total Bookings` and `Total Revenue` convey their
  total with the single-lined sum bar across the data columns (Col E onward) — not a
  font underline and never a double border (per the border discipline above).
- **`Total Bookings` is a roll-up across buckets**, added **only when there are two or
  more booking streams**; it is `= SUM(<Bookings — Stream n>)` and carries its own
  `YoY %` derived-display row like the other lines. A single-stream
  build has no separate `Total Bookings` row.
- The `YoY %` block that heads the per-stream trend rows sits at
  **`indent=1`** in all three blocks (its trend rows at `indent=2`). The separate
  `YoY %` and `Memo: components − Total` rows nested directly beneath
  `Total Revenue` remain at `indent=2` (they belong to the total, not to the stream
  list) — see §4.2.
- **One blank row precedes each full `YoY %` block.** Because the
  `YoY %` label row in §2, §3, and §4 heads two or more trend rows, leave
  **one blank spacer row directly above it** (shown as `[ skip one blank row … ]` in the
  maps above). The single derived-display `YoY %` nested beneath
  `Total Revenue` (§4.2) heads one growth row, so it gets **no** blank row above it — see
  the spacing discipline above.
- **Memo rows stay visible.** Any memo line item (e.g. `Reported Take Rate (memo)` in
  §3, `Memo: components − Total` in §4) is an ordinary visible italic row — see the memo
  convention above.

---

## Section 2 — Unit Economics (Bookings)

This section builds **Bookings** — the volume the take rate is applied to — one block
per booking stream, directly beneath the customer roll-forward (if any) or the
`REVENUE` header. It reads as a `Unit Economics` block: for **Approach 1**, the
`Bookings Driver` and `Bookings per Bookings Driver` lines followed by the
reconstructed `Bookings`; for **Approach 2**, just `Bookings`. A `YoY %` sub-block beneath shows each line's year-over-year trend. In the projection
columns those trend rows become **drivers** (see the Projections section).

### 2.1 — The logic

```
  Approach 1 (Driver → Bookings):
    Bookings Driver                 = reported input                              [historicals]
    Bookings per Bookings Driver    = Bookings ÷ Bookings Driver                  [historicals, backsolve]
    Bookings                        = reported input                              [historicals, the listed anchor]
    Bookings                        = Bookings Driver × Bookings per Bookings Driver   [projection]

  Approach 2 (Bookings direct):
    Bookings                        = reported input                              [historicals]
    Bookings                        = <prior col Bookings> × (1 + YoY %)   [projection]

  YoY % (any row)    = this col ÷ prior col − 1                    [both halves, derived]
```

- **Derive (historicals):** every historical value comes from deepKPI —
  `Bookings Driver` and `Bookings` are reported inputs; the only computed historical
  line is the Approach-1 `Bookings per Bookings Driver` backsolve (`= Bookings ÷
  Bookings Driver`). This is the average booked value per unit of driver (e.g. booked
  dollars per trip).
- **Trend:** the `YoY %` sub-block beneath the bookings lines shows
  each line's year-over-year growth — the trend that anchors the forward drivers.
- **Project:** in Approach 1 the `Bookings Driver` and `Bookings per Bookings Driver`
  each compound off their own `YoY %` driver, and `Bookings` is rebuilt
  as their product; in Approach 2 `Bookings` compounds directly off its `YoY %` driver (§Projections).

**Rigor note — the backsolve foots by construction.** Because `Bookings per Bookings
Driver = Bookings ÷ Bookings Driver` historically, the product `Bookings Driver ×
Bookings per Bookings Driver` reproduces reported bookings exactly every historical
year — so the Approach-1 decomposition never distorts the historical anchor. The
decomposition only changes the **projection**, where the two pieces are grown
separately.

**Rigor note — driver units.** The driver is a **count**, never the money family;
the per-driver is **per-unit money** and is never scaled to millions. Their display
scales are not free choices: the **Number format and units** bullet above sets the
driver's scale from the bookings scale, so that the product lands in the bookings'
dollar unit and the per-driver row reconciles against the two rows it comes from.
Tag the driver from that chosen scale — never from the scale deepKPI delivered.

**Naming rule — never write the words "Bookings Driver" in the sheet.** `Bookings
Driver` and `Bookings per Bookings Driver` are **placeholders used in this document
only**. In the delivered workbook the Col C label is the driver's **actual reported
name** — `Trips`, `Orders`, `Transactions`, `Rides`, `Room Nights`, etc. — and the
per-driver line reads `Bookings per <Driver>` in the singular: `Bookings per Trip`,
`Bookings per Order`. A mobility stream therefore lays down `Trips` / `Bookings per
Trip` / `Bookings`, **not** `Bookings Driver` / `Bookings per Bookings Driver`. This
applies everywhere the driver is labeled — the Unit Economics lines, their
`YoY %` trend rows, the Col D unit tags, and any stream-prefixed
variant (`Trips — Mobility`, `Bookings per Trip — Mobility`). Wherever the maps and
formula tables below print `Bookings Driver` / `<Driver>`, substitute that company's
driver name.

### 2.2 — Layout

**Approach 1 (single stream):**

```
  Unit Economics                                                                [indent 1; bold + underlined block header]
    <Driver>                                            (<driver>, in <scale>)    [label = the driver's actual name, e.g. Trips / Orders; indent 2; deepKPI INPUT historical; projection: = prior col × (1 + its YoY %)]
    Bookings per <Driver>                               (USD per <driver>)        [e.g. Bookings per Trip; indent 2; historical: FORMULA = Bookings ÷ <Driver>; projection: = prior col × (1 + its YoY %)]
  Bookings                                            (USD in <scale>)          [indent 1, bold; SUM-BAR; historical: deepKPI INPUT; projection: FORMULA = <Driver> × Bookings per <Driver>]
  [ skip one blank row above the full YoY % block ]
    YoY %                                                          [indent 2; bold + underlined label-only row — no data]
      <Driver>                                          (%)                       [indent 3; FORMULA = this col ÷ prior col − 1; italic; base col dash; projection: DRIVER]
      Bookings per <Driver>                             (%)                       [indent 3; FORMULA = this col ÷ prior col − 1; italic; base col dash; projection: DRIVER]
      Bookings                                          (%)                       [indent 3; FORMULA = this col ÷ prior col − 1; italic; base col dash; derived display]
```

**Approach 2 (single stream):**

```
  Unit Economics                                                                [indent once; bold + underlined block header]
  Bookings                                            (USD in <scale>)          [indent once, bold; SUM-BAR; historical: deepKPI INPUT; projection: FORMULA = prior col × (1 + YoY %)]
  YoY %                                                          [indent once; bold + underlined label-only row — no data]
    Bookings                                          (%)                       [indent twice; FORMULA = this col ÷ prior col − 1; italic; base col dash; projection: DRIVER]
```

**Multiple streams.** Retain every booking bucket as its own stream — do **not**
collapse buckets together. Under the single `Unit Economics` block header, lay down
each stream in the fixed stream order: its Approach-1 decomposition (if any) followed
by its `Bookings — <Stream>` line, all at `indent=1`. Prefix each line label with the
stream name (`Trips — Mobility`, `Bookings — Mobility`, `Orders — Delivery`,
`Bookings — Delivery`, etc. — the driver line carries its **own name**, never the
words "Bookings Driver") so downstream references and buckets stay unambiguous. After
the last stream's `Bookings` line, add a **`Total Bookings`** roll-up row — `indent=1`, bold,
single-lined sum bar, `= SUM(<Bookings — Stream n>)` — so the block foots to total
booked volume across buckets. Then the block's `YoY %` sub-block
(`indent=1` label row) carries an `indent=2` trend row for each stream's `Bookings`
(and, for Approach-1 streams, for its `Bookings Driver` and `Bookings per Bookings
Driver`), plus one for `Total Bookings` as a derived display. `Total Bookings` is
added **only** when two or more streams exist; a single-stream build has no separate
`Total Bookings` row (its lone `Bookings` line is already the bold sum-bar headline).

Zero blank rows within a block, except the single spacer above a full `YoY %` sub-block (see the spacing discipline); one blank spacer row after the block.
When two or more streams (or the Approach-1 decomposition) give the `YoY %` label row two or more trend rows, leave one blank row directly above it; a
single-stream Approach-2 block, whose `YoY %` heads just the lone
`Bookings` trend row, gets no blank row above it. `YoY %`
is a **bold, underlined label-only** row (no data in any period column); its per-line trend rows are
indented twice beneath it. `Bookings` carries the single-lined sum bar and is bold
(it is the reconstructed total of the block in Approach 1; in Approach 2 it is the
single line but still marked bold + sum bar as the block's headline figure).

### 2.3 — The formulas (cell-by-cell)

"§3 Revenue (col X)" is not referenced here (bookings is upstream of revenue).
"prior col" = the period column immediately to the left.

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Bookings Driver` *(Approach 1)* | DATA_DEPENDENT | `(<driver>, in <scale>)` | deepKPI **input** — reported driver (trips / orders / …) | historical: same input; **projection:** `= <prior col Bookings Driver> × (1 + <YoY %: Bookings Driver, this col>)` | `"Reported operational driver of the booked volume. Projection: compounds off its YoY % driver."` |
| `Bookings per Bookings Driver` *(Approach 1)* | DATA_DEPENDENT | `(USD per <driver>)` | historical: `= <Bookings, this col> ÷ <Bookings Driver, this col>` | historical: same backsolve; **projection:** `= <prior col Bookings per Bookings Driver> × (1 + <YoY %: Bookings per Bookings Driver, this col>)` | `"Backsolve: Bookings ÷ Bookings Driver (avg booked value per driver unit). Projection: compounds off its YoY % driver."` |
| `Bookings` *(Approach 1)* | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** — reported bookings (the listed anchor) | historical: same input; **projection:** `= <Bookings Driver, this col> × <Bookings per Bookings Driver, this col>` | `"Historical: reported bookings (input). Projection: = Bookings Driver × Bookings per Bookings Driver."` |
| `Bookings` *(Approach 2)* | DATA_DEPENDENT | `(USD in <scale>)` | deepKPI **input** — reported bookings | historical: same input; **projection:** `= <prior col Bookings> × (1 + <YoY %: Bookings, this col>)` | `"Historical: reported bookings (input). Projection: compounds off its YoY % driver."` |
| `YoY %` (label row) | | — | dash (no value) | dash (no value) | `"Label row; heads the per-line YoY trend rows. No values."` |
| `Bookings Driver` / `Bookings per Bookings Driver` / `Bookings` (under YoY %) | DATA_DEPENDENT | `(%)` | base col: dash | `= <this col value> ÷ <prior col value> − 1` | `"Year-over-year change. Historical: derived. Projection: driver for the Bookings Driver / Bookings-per-Driver rows, or for Bookings where it is taken directly; derived display for the reconstructed Bookings."` |

- **Labels.** `Bookings Driver` / `Bookings per Bookings Driver` in the table above are
  placeholders: the Col C label written to the sheet is the driver's actual name and
  `Bookings per <Driver>` (e.g. `Trips` / `Bookings per Trip`) — see the naming rule in
  §2.1.
- The only deepKPI **inputs** in this section are the reported `Bookings Driver`
  (Approach 1) and reported `Bookings` (both approaches). The `Bookings per Bookings
  Driver` and every `YoY %` cell are **black live formulas** (until
  they invert to drivers in projection).
- In Approach 1, note in a Col C comment that the reconstructed `Bookings` in
  projection (`Driver × per-Driver`) is **not** the same cell as the historical
  reported input — the row switches from input to formula at the boundary (standard
  input → formula inversion, same as the other builds).

**Sourcing.** Pull each bookings series and each Approach-1 driver via `search_kpis`
against the shared inventory, reading the `unit` to confirm dollars (bookings) vs.
counts (driver). If the driver is a customer / account count the roll-forward already
carries, reference the roll-forward cell instead of re-pulling it.

### 2.4 — Pre-delivery checklist (Unit Economics)

- [ ] Approach recorded per stream (1 or 2). Approach 1 blocks carry `Bookings
      Driver`, `Bookings per Bookings Driver`, and `Bookings`; Approach 2 blocks carry
      only `Bookings`.
- [ ] The literal strings "Bookings Driver" and "Bookings per Bookings Driver" appear
      **nowhere** in Col C: the driver line is labeled with the driver's actual name
      (`Trips`, `Orders`, …) and the per-driver line as `Bookings per <Driver>`, in the
      Unit Economics lines and their `YoY %` trend rows alike.
- [ ] `Bookings` is the **reported** deepKPI input in every historical column (bold,
      single-lined sum bar).
- [ ] Approach 1: `Bookings per Bookings Driver` is the **backsolve** `Bookings ÷
      Bookings Driver` (a live formula) in every historical column; `Bookings Driver`
      is the reported input.
- [ ] Approach 1: the product `Bookings Driver × Bookings per Bookings Driver` equals
      reported `Bookings` every historical year (foots by construction).
- [ ] Each bookings line has a `YoY %` trend row (dash in the base
      column).
- [ ] If the driver is a count the customer roll-forward carries, it is **referenced**
      from the roll-forward, not re-entered.
- [ ] Multiple streams: each bucket kept as its own stream in a fixed order, labels
      stream-prefixed, and a `Total Bookings` roll-up row (bold, single-lined sum bar,
      `= SUM(<Bookings — Stream n>)`) added beneath the last stream. Single stream: no
      separate `Total Bookings` row.
- [ ] Indentation uses the actual cell indent (`Alignment(indent=n)`), not leading
      spaces: headers / main lines at `indent=1`, trend / memo sub-rows at `indent=2`.
- [ ] One blank spacer row sits directly above the full `YoY %` block
      (the one heading two or more trend rows); a single-stream Approach-2 block's
      one-trend `YoY %` has no blank row above it.
- [ ] Any quarterly rows summed to build a missing annual value sit in an outline
      group left expanded (no row on the sheet is hidden).
- [ ] After recalculation, **zero formula errors**, and bookings / per-driver values
      look economically sane across years.

---

## Section 3 — Take Rate

This section builds the **take rate** — the fraction of bookings the company keeps as
booking-driven revenue — one line per booking stream. It sits directly beneath the
Unit Economics block. In the historical columns the take rate is **backsolved** from
the reported booking-driven revenue and bookings; in the projection columns each take
rate is grown off its own **YoY %** driver (see the Projections
section). Its result feeds the §4 Consolidated Revenue table.

### 3.1 — The logic

```
  Take Rate_stream               = Booking-driven Revenue_stream ÷ Bookings_stream   [historicals, backsolve]
  Take Rate_stream               = <prior col Take Rate> × (1 + YoY %)  [projection]

  YoY % (Take Rate) = this col ÷ prior col − 1                        [both halves]
```

- **Derive (historicals):** for each historical period and each stream, `Take Rate =
  booking-driven revenue ÷ bookings` — where the revenue numerator is the reported
  stream revenue fixed in §1 and the bookings denominator is §2's `Bookings` line.
  This guarantees `Bookings × Take Rate` reproduces the reported revenue exactly.
- **Trend:** the `YoY %` sub-block beneath the take-rate lines shows
  each take rate's year-over-year change — the trend that anchors the forward driver.
- **Project:** each take rate compounds off its own `YoY %` driver
  (§Projections); the revenue rebuild `Take Rate × Bookings` happens in §4.

**Rigor note — the driver is the YoY %, not the take-rate level.** In
this build the projection **driver** is the take rate's `YoY %` row
(seeded by the default seed), and the take rate compounds off its prior value: `Take
Rate_N+1 = Take Rate_N × (1 + YoY %_N+1)`. This is consistent with the
Bookings-Driver and Other-Revenue treatments in this build (every driver here is a
`YoY %` row). A flat 0% change simply holds the take rate constant,
which is a reasonable neutral default for a mature marketplace.

**Rigor note — reported take rate is a memo only.** If the company reports a take
rate, carry it as `Reported Take Rate (memo)` and cross-check it against the
backsolve; a material gap (definitional differences in bookings or revenue) is the
§1.4 Notes line. Do **not** replace the backsolved line with it — the backsolve is
what makes the identity foot.

### 3.2 — Layout

```
  Take Rate                                                                     [indent once; bold + underlined block header]
  Take Rate — <Stream 1>                              (% of bookings)           [indent once; historical: FORMULA = §4 Revenue from Stream 1 ÷ §2 Bookings — Stream 1; projection: = prior col × (1 + its YoY %)]
  Take Rate — <Stream 2>                              (% of bookings)           [indent once; historical: FORMULA = §4 Revenue from Stream 2 ÷ §2 Bookings — Stream 2; projection: = prior col × (1 + its YoY %)]
    Reported Take Rate (memo) — <Stream n>            (% of bookings)           [indent twice; deepKPI INPUT — optional; only if a take rate is reported; italic memo cross-check; visible]
  [ skip one blank row above the full YoY % block ]
  YoY %                                                          [indent once; bold + underlined label-only row — no data]
    Take Rate — <Stream 1>                            (%)                       [indent twice; FORMULA = this col ÷ prior col − 1; italic; base col dash; projection: DRIVER]
    Take Rate — <Stream 2>                            (%)                       [indent twice; FORMULA = this col ÷ prior col − 1; italic; base col dash; projection: DRIVER]
```

For a **single stream**, drop the ` — <Stream>` suffix (just `Take Rate`). Zero blank
rows within the block, except the single spacer above the full `YoY %`
sub-block (see the spacing discipline); one blank spacer row after the block.
`YoY %` is a
**bold, underlined label-only** row (no data in any period column); its per-take-rate trend rows are
indented twice beneath it. Any `Reported Take Rate (memo)` row is a visible
italic memo row. Every take-rate and YoY % row uses the
percent format. The take-rate line order **matches** §2's bookings-stream order and
§4's revenue-stream order.

### 3.3 — The formulas (cell-by-cell)

"§4 Revenue from Stream n (col X)" = the Section 4 table's `Revenue from Stream n` cell in
column X; "§2 Bookings — Stream n (col X)" = the Section 2 block's `Bookings` line for
that stream in column X.

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Take Rate — <Stream n>` | | `(% of bookings)` | historical: `= <§4 Revenue from Stream n, this col> ÷ <§2 Bookings — Stream n, this col>` | historical: same backsolve; **projection:** `= <prior col Take Rate — Stream n> × (1 + <YoY %: Take Rate — Stream n, this col>)` | `"Historical backsolve: booking-driven revenue ÷ bookings. Projection: compounds off its YoY % driver."` |
| `Reported Take Rate (memo) — <Stream n>` *(optional)* | | `(% of bookings)` | deepKPI **input** — reported take rate, if disclosed | same | *(no comment — input memo; cross-check vs backsolve; a material definitional gap is the §1.4 Notes line)* |
| `YoY %` (label row) | | — | dash (no value) | dash (no value) | `"Label row; heads the per-take-rate YoY trend rows. No values."` |
| `Take Rate — <Stream n>` (under YoY %) | | `(%)` | base col: dash | `= <this col Take Rate — Stream n> ÷ <prior col Take Rate — Stream n> − 1` | `"Take-rate change, YoY. Historical: derived. Projection: DRIVER (seeded by the default seed)."` |

- Each take-rate line references **§4's stream revenue** as its historical numerator
  and **§2's stream bookings** as its denominator — both live references, so a change
  upstream flows through.
- The only deepKPI **input** in this section is the optional `Reported Take Rate
  (memo)`; every backsolved take rate and every `YoY %` cell is a
  **black live formula** (until the YoY % inverts to a driver in
  projection).

### 3.4 — Pre-delivery checklist (Take Rate)

- [ ] Each take rate is the **backsolve** `booking-driven revenue ÷ bookings` (a live
      formula) in every historical column — not a hardcode and not the reported take
      rate.
- [ ] The numerator is the **booking-driven stream revenue** (§4 / §1), not blended
      total; the denominator is **§2's Bookings** for the matching stream.
- [ ] Each take rate has a `YoY %` trend row (dash in the base column),
      which is the **projection driver**.
- [ ] Any company-reported take rate is carried **only** as `Reported Take Rate
      (memo)` with a material gap on its Notes line (§1.4) — it does not replace the
      backsolved line, and the memo
      row is a visible italic memo row.
- [ ] One blank spacer row sits directly above the full `YoY %` block.
- [ ] Take-rate line order matches §2's bookings streams and §4's revenue streams.
- [ ] Take-rate values are economically sane (positive, typically a small % of
      bookings; a wild take rate flags a bookings / revenue numerator problem
      upstream).
- [ ] After recalculation, **zero formula errors**.

---

## Section 4 — Consolidated Revenue (the foot)

This final section collects each stream's booking-driven revenue and any non-booking
non-booking streams into a single table and foots to the company's **reported total
revenue**. It sits directly beneath the Take Rate block.

### 4.1 — The partition and the foot

Consolidated revenue is the sum of each stream's revenue (`Take Rate × Bookings`) and
any non-booking streams:

> **Total Revenue = Σ ( Bookings_stream × Take Rate_stream ) + Σ non-booking streams
> [+ Other Revenue residual]**

In the **historical** columns each `Revenue from Stream n` is the **reported** deepKPI
input (the anchor from which §3's take rate was backsolved), and `Total Revenue` is
the reported total (a foot-check memo confirms the components tie to it). In the
**projection** columns the inversion applies: each `Revenue from Stream n` becomes `Take
Rate × Bookings`, each non-booking stream compounds on its growth driver, the residual
is a share of modeled revenue, and `Total Revenue`
is written **directly as the sum** of the components (§ see Projections).

**Non-booking streams — projected on their own growth driver.** Each non-booking
stream (a reported revenue line the bookings do not generate — subscription /
membership fees, advertising, interest, one-time fees, etc.) is carried as a reported
**input** historically and projected off its own `YoY %` driver,
seeded like every other driver in the build (the default seed, then flat — see Projections). List each
non-booking stream as its **own small block** (header + value + `YoY %`) and **insert its value row into the Consolidated Revenue table** so it sums
into `Total Revenue`.

**Make the partition exhaustive.** The stream revenues plus the non-booking
stream(s) must sum to **reported total revenue** every historical year. After laying
down the explicitly reported non-booking streams, check each year: if `Σ Revenue —
Stream n + Σ non-booking streams < reported Total Revenue`, the reported streams do not
exhaust revenue — add a final **`Other Revenue`** residual whose historical value is
`Total Revenue − Σ Revenue from Stream n − Σ (identified non-booking streams)` (a formula),
carried historically as that formula and projected as a **share of modeled revenue**
off the driver row `Other Revenue — % of modeled revenue` laid beneath it in the
consolidated table (see Projections). After this the partition is exhaustive **by
construction**.

### 4.2 — Layout

Each non-booking stream first appears as its **own small block** (laid
out like a §2 / §3 block — a bold + underlined header, a value row, a `YoY %` row), then its value row is **referenced into** the Consolidated Revenue
table below:

```
  <Non-booking Stream 1 name>                                                   [indent 1; bold + underlined block header = the stream's name; label only — no data]
    Revenue from <Non-booking Stream 1>                 (USD in <scale>)          [indent 2; value row — same label as its consolidated restatement; deepKPI INPUT historical; projection: = prior col × (1 + YoY %)]
      YoY %                              (%)                       [indent 3; FORMULA historical = this col ÷ prior col − 1; driver in projection (the default seed: guided, else the latest change, then flat); italic]

  Consolidated Revenue                                                          [indent 1; bold + underlined header — NOT all caps, NOT enlarged; it is still under REVENUE]
    Revenue from <Stream 1>                                (USD in <scale>)          [indent 2; historical: deepKPI INPUT — reported stream revenue; projection: FORMULA = §3 Take Rate — Stream 1 × §2 Bookings — Stream 1]
    Revenue from <Stream 2>                                (USD in <scale>)          [indent 2; historical: deepKPI INPUT — reported stream revenue; projection: FORMULA = §3 Take Rate — Stream 2 × §2 Bookings — Stream 2]
    Revenue from <Non-booking Stream 1>                 (USD in <scale>)          [indent 2; FORMULA = that stream's block value row, this col — same label; one row per non-booking stream]
    Other Revenue                                       (USD in <scale>)          [indent 2; the residual — only if the named streams do not exhaust reported total; FORMULA per §4.3]
      Other Revenue — % of modeled revenue                (% of modeled revenue)    [indent 3; only with the residual; FORMULA historical = Other Revenue ÷ (Σ stream revenue + Σ non-booking streams); DRIVER in projection (the default seed: guided, else the latest year, then flat); visible]
  Total Revenue                                       (USD in <scale>)          [indent 1, bold; SUM-BAR; historical: deepKPI INPUT — reported total revenue; projection: FORMULA = sum of components]
    Memo: components − Total (must = 0)               (USD in <scale>)          [indent 2; FORMULA check; 0 every period; visible]
    YoY %                              (%)                       [indent 2; FORMULA = this col ÷ prior col − 1; italic; base col dash; single derived-display row — no blank row above it]

    YoY %                                                          [indent 2; bold + underlined label-only row — no data]
      Revenue from <Stream 1>                              (%)                       [indent 3; FORMULA = this col ÷ prior col − 1; italic; base col dash]
      Revenue from <Stream 2>                              (%)                       [indent 3; FORMULA = this col ÷ prior col − 1; italic; base col dash]
```

The `Consolidated Revenue` header is **bold + underlined, indent once**, and is
**not** all caps or enlarged (it is a sub-section under the `REVENUE` header, not a
top-level section header). `Total Revenue` is **bold** with a **single-lined sum bar**
(thin top border) across the data columns — **no** double border and **no** label
underline; the component rows read top-to-bottom into it; the foot-check memo sits
immediately beneath it. For a **covers-all** company (no non-booking revenue) there
are no non-booking stream blocks and no `Other Revenue` row — the table sums the stream
revenues straight to `Total Revenue`. Revenue rows are the **money** family;
take-rate and YoY % rows are **percent**.

### 4.3 — The formulas (cell-by-cell)

| Row (plain Col C label) | Lays when | Units (Col D) | Base (leftmost) column | Chained column (N > base) | Comment on Col C label cell |
|---|---|---|---|---|---|
| `Revenue from <Stream n>` | | `(USD in <scale>)` | historical: deepKPI **input** — reported stream revenue | historical: same input; **projection:** `= <§3 Take Rate — Stream n, this col> × <§2 Bookings — Stream n, this col>` | `"Historical: reported booking-driven stream revenue (input; the take rate is backsolved from it). Projection: = Take Rate × Bookings."` |
| `Revenue from <Non-booking Stream n>` *(one per non-booking stream)* | | `(USD in <scale>)` | `= <that stream's block value row, this col>` — same label as that row | same | `"= the non-booking stream's value (reported input historical / driver-compounded projection). Non-booking revenue; not run through the take-rate identity."` |
| `Other Revenue` *(residual, only if needed)* | DATA_DEPENDENT | `(USD in <scale>)` | historical: `= <Total Revenue, this col> − SUM(<Revenue from Stream rows, this col>) − SUM(<non-booking stream rows, this col>)` | projection: `= <Other Revenue — % of modeled revenue, this col> × (SUM(<Revenue from Stream rows, this col>) + SUM(<non-booking stream rows, this col>))` (see Projections) | `"Residual non-booking revenue = reported total − Σ stream revenue − identified non-booking streams. Makes the partition exhaustive. Projection: a share of modeled revenue, off the driver row beneath."` |
| `Other Revenue — % of modeled revenue` *(driver row under the residual; only with it; visible)* | DATA_DEPENDENT | `(% of modeled revenue)` | historical: `= <Other Revenue, this col> ÷ (SUM(<Revenue from Stream rows, this col>) + SUM(<non-booking stream rows, this col>))` | projection: **DRIVER** — red font + dashed border, default seed (guided, else the latest year, then flat) | `"The residual's share of the revenue the build models (stream revenue + non-booking streams). Historical: a fit diagnostic — low single digits expected. Projection: driver, guided or else the latest year, then flat."` |
| `Total Revenue` | | `(USD in <scale>)` | historical: deepKPI **input** — reported total revenue | historical: same input; **projection:** `= SUM(<Revenue from Stream rows>) + SUM(<non-booking stream rows>) [+ <Other Revenue residual>]` | `"Historical: reported total revenue (input, the anchor). Projection: = Σ stream revenue + Σ non-booking streams + residual."` |
| `Memo: components − Total (must = 0)` | | `(USD in <scale>)` | `= (SUM(<Revenue from Stream rows>) + SUM(<non-booking stream rows>) [+ <Other Revenue residual>]) − <Total Revenue>` | same | `"Foot check: must equal 0 every period."` |
| `YoY %` (Total Revenue memo) | | `(%)` | base col: dash; else `= <this col Total Revenue> ÷ <prior col Total Revenue> − 1` | same | `"Total revenue growth, YoY."` |
| `Revenue from <Stream n>` (under the block YoY %) | | `(%)` | base col: dash | `= <this col Revenue from Stream n> ÷ <prior col Revenue from Stream n> − 1` | `"Stream revenue growth, YoY (derived display)."` |

- Each `Revenue from Stream n` is the **reported input** historically (the same figure
  §3 backsolves its take rate from) and the **`Take Rate × Bookings` product** in
  projection — the standard input → formula inversion, with no circularity (in each
  half exactly one of {stream revenue, take rate} is the source and the other
  references it).
- The `Revenue from <Non-booking Stream n>` rows in the consolidated table are **references** to the non-booking
  Revenue blocks above; those blocks hold the reported input (historical) and the
  driver-compounded value (projection).

### 4.4 — Pre-delivery checklist (Consolidated Revenue)

- [ ] The table sums every `Revenue from Stream n` + every `Revenue from <Non-booking
      Stream n>` (+ the `Other Revenue` residual if added) into `Total Revenue`.
- [ ] Each `Revenue from Stream n` is the **reported** deepKPI input in the historical
      columns (the anchor §3's take rate is backsolved from).
- [ ] `Total Revenue` is the **reported** deepKPI input in the historical columns
      (bold, single-lined sum bar; the `Consolidated Revenue` header is bold +
      underlined but not all caps or enlarged).
- [ ] Every non-booking stream is carried as its **own block** (header +
      value + `YoY %`) and **referenced into** the consolidated table.
- [ ] The `components − Total (must = 0)` memo evaluates to **0** in every historical
      period after recalculation (streams + non-booking streams [+ residual] form an exhaustive
      partition), and that memo row is visible.
- [ ] One blank spacer row sits directly above the full `YoY %` block;
      the single `YoY %` nested beneath `Total Revenue` has no blank row
      above it.
- [ ] For a **covers-all** company, there are no non-booking stream rows and `Total Revenue
      = Σ stream revenue`.
- [ ] After recalculation, **zero formula errors**, and the master identity `Total
      Revenue = Σ (Bookings × Take Rate) + Σ non-booking streams [+ residual]` holds exactly every
      period.

---

## Section 5 — Worked example (illustrative)

This walks an illustrative two-segment marketplace through the full build to show how
the rows chain. **The figures are illustrative** (round numbers for transparency, not
any real issuer's reported data) — the point is the mechanics. Universe =
consolidated; **bookings and revenue in $ millions**; the driver in **millions of
trips**; bookings-per-trip in **$ per trip**; take rate in **%**. Build window FY2022
(base) → FY2025. Segments: **Mobility** (Approach 1 — driver = Trips) and **Delivery**
(Approach 2 — bookings direct), plus a non-booking **Advertising** stream.

**§2 Unit Economics — Mobility (Approach 1):**

| Row | Lays when | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|---|
| Trips — Mobility | | `(trips, in millions)` | 1,900 | 2,300 | 2,700 | 3,000 |
| Bookings per Trip — Mobility *(backsolve)* | | `(USD per trip)` | 12.63 | 12.83 | 13.00 | 13.33 |
| **Bookings — Mobility** *(reported input)* | | `(USD in millions)` | **24,000** | **29,500** | **35,100** | **40,000** |

`Bookings per Trip = Bookings ÷ Trips` every year (e.g. FY2025: $40,000M ÷ 3,000m =
**$13.33/trip**), and `Trips × Bookings per Trip` reproduces reported bookings by
construction. FY2025 take rate below.

**§2 Unit Economics — Delivery (Approach 2):** reported `Bookings — Delivery`
(USD in millions):
FY2022 45,000, FY2023 55,000, FY2024 62,000, FY2025 68,000, each with a
`YoY %` trend row; no driver decomposition.

**§3 Take Rate (backsolved = §4 stream revenue ÷ §2 bookings):**

| Take Rate | Units (Col D) | FY2022 | FY2023 | FY2024 | FY2025 |
|---|---|---|---|---|---|
| Take Rate — Mobility | `(% of bookings)` | 25.0% | 26.0% | 27.0% | 28.0% |
| Take Rate — Delivery | `(% of bookings)` | 14.0% | 15.0% | 16.0% | 17.0% |

(e.g. FY2025 Mobility revenue $11,200M ÷ bookings $40,000M = **28.0%**.)

**§4 Consolidated Revenue (FY2025, USD in millions):**

- `Revenue from Mobility` = reported **$11,200M** (28.0% × $40,000M).
- `Revenue from Delivery` = reported **$11,560M** (17.0% × $68,000M).
- `Revenue from Advertising` (a non-booking stream) = reported **$1,200M**, projected on its own
  `YoY %` driver.
- `Total Revenue` = reported **$23,960M**, and `11,200 + 11,560 + 1,200 = 23,960` —
  the `components − Total` foot-check = 0.

Only the reported inputs (Trips, each `Bookings` line, each stream revenue,
Advertising, Total Revenue) are deepKPI inputs; Bookings-per-Trip, every take rate,
every YoY %, and the foot check are formulas.

---

## Projections (forecast years)

After the **historical** build above (Sections 1 – 5) is laid down, recalculated, and
footed (the §4 `components − Total (must = 0)` check passes), **extend the entire
take-rate build into the projection window** before the downstream handoff (§6). The
projection window is the **five fiscal years after the last historical year** (`N+1 …
N+5`) per the **Model timeline** in `../../../SKILL.md` — do not redefine it here. Add
five more **annual** columns immediately to the right of the historical block,
continuing the same left → right, oldest → newest order; the build stays **annual**.
Most of the build **drags across as formulas**; only a small set of **drivers** are
entered as forward assumptions.

### Driver styling (applies to every projection driver below)

Mark **every** projection driver cell so it reads as a forward assumption — visually
distinct from both the formula cells and the historical deepKPI input cells:

- **Font color red** — the "estimated / external values"
  convention in `../../../../_common/revelata-excel-styling-rules.md`.
- **A dashed box on all four sides of each individual driver cell** (openpyxl
  `Side(border_style="dashed")` on `left`, `right`, `top`, `bottom` — one complete box
  **per cell**, applied **after** any shared row-border pass so a later border write
  cannot overwrite the box). Do **not** reduce it to a single bottom border.
- **No pale-green fill and no hyperlink** — projection drivers are assumptions, not
  deepKPI-sourced actuals.
- Every **non-driver** projection cell stays standard formula styling (black font, no
  fill, no dashed box) — identical to its historical styling, dragged one column right.

### Driver value methodology (the default seed for every driver)

Unless a driver is called out as an exception below, seed each driver cell as:

- **First projection year (`N+1`)** — the **default seed** (`../../../SKILL.md`, Build mechanics): the guided value where the guidance table names the driver for `N+1`; else the latest year on the issuer's normalized basis where disclosed; else the **latest historical year** (`N`), written by the renderer as a live formula with an `ISNUMBER` fallback to `N−1` and `N−2`.
- **Each later projection year (`N+2 … N+5`)** — **equal to the `N+1` cell** (flat):
  `= <driver N+1 cell>`.
- The modeler may type a specific assumption over any driver cell; the red/dashed
  styling flags exactly which cells are meant to be overwritten.

The projection **drivers** in this build are exactly:

1. **Approach 1** — each stream's `Bookings Driver` `YoY %` **and** its
   `Bookings per Bookings Driver` `YoY %` (§2).
2. **Approach 2** — each stream's `Bookings` `YoY %` (§2).
3. **Each stream's `Take Rate` `YoY %`** (§3).
4. **Each non-booking stream's `YoY %`** (§4).
5. **The residual's `Other Revenue — % of modeled revenue`** (§4, only when a residual
   exists) — a ratio driver, not a growth driver.

All five take the same default seed: `N+1` = the guided value where the guidance table names the driver, else the latest historical value; `N+2 … N+5` flat. No driver in this build is seeded on a CAGR.

Note: the `YoY %` rows for the **reconstructed `Bookings`** (Approach 1),
each **`Revenue from Stream n`**, and **`Total Revenue`** are **derived displays**, not
drivers — they stay black formulas and simply show the resulting growth.

### Part 1 — Unit Economics (§2): bookings reconstructs forward

**Approach 1 (per stream):**

- **`Bookings Driver`** — now the **formula** `= <prior col Bookings Driver> × (1 +
  <its YoY %, this col>)`, where its `YoY %` is a
  **driver** (red/dashed; `N+1` = the default seed: the guided value, else the latest historical change; `N+2 … N+5` = `N+1`).
- **`Bookings per Bookings Driver`** — now the **formula** `= <prior col Bookings per
  Bookings Driver> × (1 + <its YoY %, this col>)`, where its
  `YoY %` is a **driver** (same seeding).
- **`Bookings`** — now the **formula** `= <Bookings Driver, this col> × <Bookings per
  Bookings Driver, this col>` (no longer a reported input). Its `YoY %`
  stays a derived display.

**Approach 2 (per stream):**

- **`Bookings`** — now the **formula** `= <prior col Bookings> × (1 + <its
  YoY %, this col>)`, where its `YoY %` is a **driver**
  (same seeding). No driver decomposition.

For `N+1`, every "prior col" resolves to the last historical year `N`, so projections
pick up exactly where the actuals end.

### Part 2 — Take Rate (§3): driver = each take rate's YoY %

Per stream:

- **`Take Rate — <Stream n>`** — now the **formula** `= <prior col Take Rate — Stream
  n> × (1 + <its YoY %, this col>)` (no longer the revenue ÷ bookings
  backsolve).
- **`YoY %`** (under the take rate) — the **driver** (red/dashed; `N+1` = the default seed: the guided value, else the latest historical take-rate change; `N+2 … N+5` = `N+1`). A flat 0% seed simply holds the take rate at its `N` level; the modeler may
  type an expansion / compression assumption.
- **`Reported Take Rate (memo)`**, if present — a historical-only input; leave its
  projection cells blank (dash).

### Part 3 — Consolidated Revenue (§4): the identity computes forward

- **`Revenue from <Stream n>`** — now the **formula** `= <§3 Take Rate — Stream n, this
  col> × <§2 Bookings — Stream n, this col>` (no longer a reported input). This is the
  value §3 references as its take-rate numerator historically, now flowing the other
  way; there is **no circularity** because in projection §3's take rate is the driven
  source and this revenue is the computed reference.
- **Each `Revenue from <Non-booking Stream n>` row** — unchanged **for historical** (reported deepKPI
  input). For **projection**: `= <prior col stream value> × (1 + <its YoY %, this col>)`. The `Other Revenue` residual, if it exists, is **no longer a
  subtraction** in projection (that would be circular against `Total Revenue`) — it
  is projected as a **share of modeled revenue**: `= <Other Revenue — % of modeled revenue,
  this col> × (SUM(<Revenue from Stream rows>) + SUM(<non-booking stream rows>))`, the
  driver row beneath it seeded by the default seed. The denominator excludes the
  residual itself, so there is no circularity. Add one Notes line: `Revenue: in the
  forecast Other Revenue is a share of modeled revenue, held at the latest ratio,
  rather than a plug.`
- **`Total Revenue`** — the **foot**. The identity `Total Revenue = Σ stream revenue +
  Σ non-booking streams [+ residual]` holds in both halves, so `Total Revenue` is **never a driver**.
  Historically it is the **reported deepKPI input**; in projection it is written
  **directly as the sum** of its component rows: `= SUM(<Revenue from Stream rows>) +
  SUM(<non-booking stream rows>) [+ <Other Revenue residual>]`. The `components − Total (must = 0)` foot-check then
  evaluates to **0** in every projection year (trivially).

### Checks (projection)

- **Drag-and-drop integrity.** Every non-driver projection cell is a live `=` formula
  (no hardcoded numbers). The **only** seeded/typed cells are the drivers: each
  Approach-1 `Bookings Driver` / `Bookings per Bookings Driver` `YoY %`
  or Approach-2 `Bookings` `YoY %` (§2), each `Take Rate`
  `YoY %` (§3), each non-booking stream's `YoY %`, and
  the residual's `Other Revenue — % of modeled revenue` (§4).
- **Driver seeding.** Every driver's `N+1` = the default seed (the guided value where the guidance table names it, else the latest historical year) and `N+2 … N+5` = `N+1`.
- **Recalculate** (LibreOffice / the xlsx skill's `recalc.py`) → **zero formula
  errors** and **no circular references** (confirm §4 `Revenue from Stream n` ↔ §3 Take
  Rate is a one-directional reference in each half, and the §4 `Other Revenue` residual
  is a share of modeled revenue rather than a subtraction in projection).
- **Foot.** The §4 `components − Total (must = 0)` memo equals **0** in every
  projection year.
- **Continuity at the boundary.** `N+1` bookings reconstructs off `N`'s driver /
  per-driver (Approach 1) or `N`'s bookings (Approach 2); `N+1` take rate compounds off
  `N`'s take rate; `N+1` each non-booking stream compounds off its `N` value — the
  projection joins the actuals with no gap or jump.

---

## Section 6 — What the take-rate build produces for downstream sections

After Sections 1 – 5 are built, the workbook contains, for every period in the window,
a fully-footed take-rate revenue build beneath the customer roll-forward (if any) or
the `REVENUE` header: a `Unit Economics` block per booking stream (bookings, its
driver decomposition where Approach 1 applies, and the YoY % trends), a
`Take Rate` block per stream (backsolved historically, driven forward on its
YoY %), any non-booking streams projected on their own growth drivers, and
a `Consolidated Revenue` table whose `Total Revenue` foots to reported revenue. Every
component is a live formula flowing from the reported bookings / drivers, the reported
stream revenues, the take-rate and growth drivers, and the reported-total anchor.
Downstream operating-model sections (costs, consolidated financials) reference `Total
Revenue` and the component lines (each `Revenue from Stream n`, each `Revenue from <Non-booking Stream n>`, the `Other Revenue` residual if any)
directly; any later change to a bookings input, a take-rate driver, or an Other
Revenue driver propagates automatically through the entire build and keeps the foot
intact.

Report back to the router, in one line each: whether each booking stream was
**Approach 1 or Approach 2** (and the driver, for Approach 1), whether the build was
**covers-all or mixed** (and which streams were carved to non-booking streams), the
historical window used, and the row addresses of `Total Revenue`, each `Revenue —
Stream n`, and each `Revenue from <Non-booking Stream n>` so downstream sections can reference them
without re-deriving anything.

---

*This build is part of the Revelata operating-model skill set. It writes only the
REVENUE section's take-rate lines; the customer roll-forward and all non-revenue
sections are owned by their respective skills.*
