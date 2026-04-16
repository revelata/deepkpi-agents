---
name: peer-benchmark
description: >
  Find benchmark companies for any US public company using deepKPI's semantic search across
  the company universe. Produces three outputs: a tight in-chat 1-pager, an Excel KPI workbook,
  and a Revelata-branded HTML report. The core workflow is: (1) build a KPI-enriched fingerprint
  of the target from SEC data, (2) find and KPI-align whole-company benchmark candidates,
  (3) diff the aligned fingerprints to identify segments or operational quirks that no whole-company
  benchmark covers, then iterate to find segment-specific sub-benchmarks for those gaps,
  (4) produce outputs. Use whenever the user asks to compare a company to peers, find comps,
  benchmark a company or division, find the most similar companies, build a comp set,
  find peers for valuation, identify similar businesses, triangulate segment economics, or asks
  "what companies are like X?" or "what's the best comp for Y?" The word "benchmarking" is used
  instead of financial "comps" (price multiples) where that ambiguity matters. Also use when the
  user wants to understand a specific segment of a large company by finding standalone public
  companies that resemble that segment.
---

# peer-benchmark

Find comparable public companies ("benchmarks") for a target company or segment using deepKPI.
The output is not a mechanical list of industry peers — it's a curated set where every benchmark
adds a specific analytical lens, and where the gaps in coverage are as informative as the matches.

The workflow is explicitly iterative. Segment sub-benchmarks are not pre-assumed based on what
segments exist; they are discovered by diffing the target's KPI fingerprint against what the
whole-company benchmarks can actually explain. If something in the target's operations has no
counterpart in the whole-company set, that's the signal to go deeper.

## Dependencies

Before starting, read:
- `retrieve-kpi-data/retrieve-kpi-data.md` — retrieval workflow, provenance
  rules, scaling artifact handling, KPI search strategy. Required for all data pulls.
- `format-deepkpi-for-excel/format-deepkpi-for-excel.md` — only if user
  requests Excel output.

Every number displayed must have a `[value](provenance-url)` link. No exceptions.

## Output mode — ask first

**Before pulling any data**, ask the user which output format they want:

> "Would you like an **interactive HTML report** (opens in browser, clickable provenance links, Chart.js charts) or **in-chat markdown** output? Or both?"

- If **HTML**: generate the full HTML report (dark Revelata branding, Chart.js, fingerprint grid). Also produce the chat 1-pager as a compact summary.
- If **in-chat**: produce only the chat 1-pager with full markdown provenance links (see rules below). Offer the HTML at the end.
- If **both**: produce chat 1-pager first, then generate the HTML.

Offer Excel at the end regardless of which mode is chosen, unless the user already requested it.

## Outputs

| Format | When | Description |
|--------|------|-------------|
| Chat 1-pager | Always | Fingerprint pill rows + master table + KPI alignment + ≤5 notes — **all values hyperlinked** |
| HTML report | If user chose HTML or both | Dark Revelata-branded report with fingerprint grid, benchmark cards, and Chart.js KPI charts |
| Excel workbook | User requests .xlsx | KPI alignment table, periods as columns per format spec |

### In-chat provenance link rules (non-negotiable)

Every numeric value shown in chat **must** be a markdown hyperlink to its source filing passage. No bare numbers.

Format: `[+4.9%](https://www.revelata.com/docviewer?pvid=11240)` — the pvid comes from the deepKPI response.

This applies everywhere in the chat output: fingerprint bullets, the KPI alignment table, notes, and the diff insight. If a value has no pvid (e.g. an estimate or derived metric), label it explicitly as `~$X est.` or `implied` with no link. Never omit the link for a directly sourced value.

Example of correct in-chat KPI alignment table row:
```
| TXRH | [+4.9%](https://www.revelata.com/docviewer?pvid=11240) | [$8.7M](https://www.revelata.com/docviewer?pvid=10061) | [714](https://www.revelata.com/docviewer?pvid=11537) |
```

---

## Workflow

The four steps below run in sequence. Steps 1–3 are analytical; Step 4 is output generation.
Run all deepKPI calls in parallel wherever possible to save time.

---

### Step 1: Build the target's KPI-enriched fingerprint

This is the foundation everything else builds on. Pull it from deepKPI — do not use general
knowledge for specific metrics.

**Calls:** `query_company_id` → `get_company_summary` → `get_company_segments` → `list_kpis`
→ `search_kpis` (for each segment's signature metrics)

**What to extract:**

**A. Narrative** — 2-3 sentences: business model, revenue drivers, customer type, go-to-market,
geography. Ground it in numbers where possible (unit count, revenue scale, market share if stated).

**B. Segment map** — For each reportable segment:
- Name and revenue share %
- One-sentence description of the economic model (how it makes money, who pays)
- 3-5 signature KPIs with actual values from deepKPI, each with provenance link

The segment KPIs are what make this fingerprint useful for diffing. For an airline: ASMs, load
factor, CASM, TRASM. For a refinery: capacity bpd, utilization %, gross margin per barrel.
For a restaurant segment: unit count, comp sales %, AUV. Pull the real numbers.

**C. KPI signature** — The 3-5 metrics that matter most for the consolidated company. These
become the columns in the KPI alignment table in the output.

**Output of Step 1:** An internal working document (not shown to user) with:
```
Target: [TICKER] — [Company] (CIK: NNNNNN, FY: DATE)
Narrative: ...
Segments:
  [Segment A] (XX% rev): [description] | KPIs: metric1=[val](url), metric2=[val](url), ...
  [Segment B] (XX% rev): [description] | KPIs: metric1=[val](url), ...
KPI signature: metric1, metric2, metric3 [, metric4, metric5]
```

---

### Step 2: Find candidates and align their fingerprints

**A. Search**

Run `company_summary_search` with 3-5 queries. Each query should describe a *business model*,
not just a sector name. The goal is semantic richness — describe what the company does, for whom,
how it earns money, and what drives its unit economics.

Examples of the contrast:
- Weak: `"airline"` → Strong: `"hub-and-spoke network carrier international domestic routes premium cabin loyalty co-brand revenue per ASM"`
- Weak: `"restaurant chain"` → Strong: `"multi-brand casual full-service dining operator franchised same-store sales average unit volume"`
- Weak: `"software company"` → Strong: `"B2B SaaS subscription recurring revenue net revenue retention enterprise mid-market"`

Use `top_k_companies: 10-12` per query. Deduplicate across queries. Target 6-12 candidates.

**B. KPI alignment**

For each candidate: call `list_kpis` (free), then `search_kpis` for the target's KPI signature
metrics (from Step 1C). This produces aligned rows — the target's metrics sitting next to each
candidate's equivalent metrics.

The alignment reveals two things:
1. How close each candidate is on the dimensions that matter (similar range = structurally comparable)
2. Where candidates have no data or wildly different values (poor fit on that dimension)

Coverage coding:
- **Green**: metric present and plausible
- **Yellow**: metric present but value seems off (scaling artifact, possible cross-contamination)
- **Red**: no data

**C. Tier the candidates**

Based on the aligned KPI fingerprints (not just the description similarity):
- **Tier 1**: Closest structural match — same business model, similar values on 3+ signature KPIs
- **Tier 2**: Useful comparators — good match on some KPIs, different on others; adds a specific lens
- **Tier 3**: Scale context — structurally different or much different scale, but useful as reference

---

### Step 3: Diff — find what the whole-company benchmarks don't explain

This is the step that surfaces the most analytically valuable insights.

**The question:** After aligning KPI fingerprints in Step 2, which parts of the target's
operations have *no good coverage* in the whole-company benchmark set?

A "coverage gap" exists when:
1. The target has a reportable segment whose signature KPIs appear nowhere in the Tier 1/2 benchmark set, OR
2. The target reports KPIs that are structurally foreign to all benchmark candidates
   (e.g., `refinery throughput bpd` when all candidates are airlines), OR
3. A major segment has a fundamentally different economic model than what any whole-company
   benchmark represents

**For each gap identified:**

a. Build a **segment-specific fingerprint** using the segment's own KPIs from Step 1B
   ("this segment, if it were a standalone public company, would look like:")

b. Run a fresh `company_summary_search` describing that segment as a standalone business.
   Use the segment's KPIs as the anchor — e.g., for a refinery segment:
   `"independent petroleum refiner crude oil throughput barrels per day capacity utilization refining margin per barrel crack spread"`.
   Not: `"refinery"`.

c. Pull KPI alignment for sub-benchmark candidates using the *segment's* KPI signature
   (not the parent company's consolidated metrics)

d. Tag all matches as `Maps to: Segment: [name]` in the master table

**Important framing:** The sub-benchmark tells you what that segment *would* look like as a
standalone profit-maximizing business. When the segment operates under a different economic logic
inside its parent (cost-center, captive supplier, hedge), say so explicitly — the gap between
the sub-benchmark's economics and the segment's implied economics *is the analytical insight*.

**Example of the diff in action:**
- Target: Delta (airline + refinery)
- Step 2 finds: UAL, AAL, LUV, ALK — all cover the airline KPIs (load factor, CASM, ASMs)
- Diff: `refinery throughput bpd`, `utilization %`, `gross margin/bbl` appear in Delta's segment
  map but in *none* of the airline benchmarks
- Step 3 triggers: build refinery segment fingerprint → search → find PBF, CVI, DINO as
  sub-benchmarks → align on throughput/utilization/margin
- Insight that emerges: Monroe's 200K bpd capacity is closest to CVI (207K bpd combined);
  PBF shares East Coast PADD 1 geography; but Monroe runs as a hedge, not a profit center —
  the merchant refiner margins ($8–16/bbl) represent the *opportunity cost* Delta pays to own it

The segment sub-benchmark logic is not limited to named segments. If the target has any
operational dimension that reads as structurally foreign to the whole-company comps —
a financial arm, a logistics network, a retail footprint embedded in a manufacturer —
ask whether a standalone pure-play exists in the S&P 1500 that illuminates it.

---

### Step 4: Build outputs

#### Chat 1-pager

Tight. No prose sidebars. Everything fits on one screen.

```
# Benchmarks for [Company] ([TICKER])

[TARGET FINGERPRINT — 2-3 sentences. Every sourced metric hyperlinked:
e.g. [+2.0% blended comps](https://www.revelata.com/docviewer?pvid=578),
[$12.1B revenue](https://www.revelata.com/docviewer?pvid=11442)]
Segments: [Segment A] XX% rev | [Segment B] XX% rev

## Benchmark table

| Ticker | Maps to | Similar on | Different on | Scale vs [TARGET] |
|--------|---------|------------|--------------|-------------------|

## KPI alignment — FY[YEAR]

| Company | [metric1] | [metric2] | [metric3] | [segment metric] | Period |
|---------|-----------|-----------|-----------|-----------------|--------|
| [TARGET] | [val](pvid-url) | [val](pvid-url) | [val](pvid-url) | [val](pvid-url) | FY... |
| BENCH1   | [val](pvid-url) | [val](pvid-url) | — | — | FY... |

Column headers are plain text. Only the value cells carry hyperlinks.
Estimates/derived values: `~$X est.` with no link.

## Notes
- [≤5 bullets — only material caveats: scaling flags, cross-contamination, structural differences,
  coverage gaps, economic logic mismatches (cost-center vs. profit-maximizer)]

## Sources
[Ticker (CIK) — Green/Yellow/Red — FY end — any corrections]
```

If a section would be empty, omit it. If the KPI alignment table would exceed 10 rows, drop Tier 3
from it (keep Tier 3 in the benchmark table only).

#### HTML report

Read `references/html-template.md`. Key structure:

- **Fingerprint box** (amber border): target company profile with KPI pills, each linking to provenance
- **Benchmark cards** (one per company): tier-colored top border, similar/different columns,
  key KPI values hyperlinked. Segment sub-benchmarks use purple border + "Segment:" badge.
- **KPI alignment section**: Chart.js grouped bar charts for the 2-3 most important metrics,
  showing target vs. all benchmarks. Table below the charts with full alignment.
- **Diff insight box** (cyan glow, same as synthesis in pressure test): 2 paragraphs on what
  the benchmark set reveals that whole-company analysis would miss.
- **Notes** and **Sources** footer.

#### Excel workbook

Follow `format-deepkpi-for-excel/format-deepkpi-for-excel.md`.
One sheet for whole-company benchmarks, one sheet per segment sub-benchmark group.
Annual periods as columns; green cells for target values; clickable provenance links.

---

## Failure modes

- **Assuming segment sub-benchmarks without doing the diff**: Don't pre-decide "this company
  has a real estate arm so I'll find REITs." Let the KPI gap analysis surface it. The diff step
  earns its keep precisely because the gaps are often surprising.
- **Narrative-only fingerprint**: If Step 1 doesn't pull actual KPI values, the diff in Step 3
  has nothing to work with. The fingerprint must have numbers.
- **Skipping KPI alignment for candidates**: Checking description similarity is not enough.
  Pull the actual metrics — two companies can describe themselves similarly but operate very
  differently when you look at unit economics.
- **Treating all segments equally**: Not every segment warrants a sub-benchmark search.
  Focus on segments where: (a) the parent discloses separate KPIs, and (b) the KPIs are foreign
  to the whole-company benchmark set.
- **Too much prose in chat**: The 1-pager is a reference artifact. Cut until it hurts.
- **Skipping list_kpis**: Free call that prevents wasted credits on metrics that don't exist.
