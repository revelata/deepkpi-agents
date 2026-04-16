# Benchmarking HTML Report Template

Revelata dark-theme benchmark report. The design is **data-forward**: the primary element is a
fingerprint × coverage grid (KPIs as rows, companies as columns), not a prose fingerprint box.
Benchmark cards below the grid provide narrative context per company.

**Logo**: Inlined as SVG. Links to `https://www.revelata.com`.
**Fonts**: Inter (body), Figtree (tickers/brand), JetBrains Mono (data values).

---

## Design principles for benchmarking reports

- Fingerprint × coverage grid as hero
- Plain category dividers (lighter font, no tier numbers)
- **Tickers only** in column headers
- **White** = target column (amber/yellow means partial match)
- Corrected values shown silently
- `.bmark-row` compact row layout

**Ticker color coding (both column headers and card headings):**
- White `#fff` — target company
- Green `var(--green)` `#22c55e` — strong structural match
- Yellow `var(--yellow)` `#eab308` — partial match
- Purple `var(--purple)` `#a855f7` — segment sub-benchmark
- No "red" tickers — companies with no match simply aren't included

**Cell color coding in the grid:**
- `td.cell.target-col` — `background: rgba(255,255,255,0.04); color: #fff` (subtle white)
- `td.cell.match-strong` — `background: var(--green-mid); color: #86efac`
- `td.cell.match-partial` — `background: var(--yellow-mid); color: #fde68a`
- `td.cell.match-none` — transparent, `color: var(--text-dim)`, shows `—` or brief note
- `td.cell.seg-cell` — `background: var(--purple-dim); color: #d8b4fe`

---

## CSS variables (do not change)

```css
:root {
  --bg: #0a0d13; --surface: #111318; --surface2: #181c24;
  --border: #252b36; --border-light: #2e3647;
  --text: #dce4f0; --text-muted: #7a8799; --text-dim: #4e5a6a;
  --cyan: #4FEAFF; --cyan-dim: rgba(79,234,255,0.1); --cyan-glow: rgba(79,234,255,0.06);
  --amber: #f59e0b; --amber-dim: rgba(245,158,11,0.1); --amber-text: #fbbf24;
  --green: #22c55e; --green-dim: rgba(34,197,94,0.12); --green-mid: rgba(34,197,94,0.2);
  --yellow: #eab308; --yellow-dim: rgba(234,179,8,0.12); --yellow-mid: rgba(234,179,8,0.18);
  --red: #ef4444; --red-dim: rgba(239,68,68,0.1);
  --purple: #a855f7; --purple-dim: rgba(168,85,247,0.12);
  --blue: #3b82f6; --blue-dim: rgba(59,130,246,0.1);
}
```

---

## Document structure

```
HEADER
  Revelata logo (SVG inline) + "deepKPI · Benchmark Analysis"
  h1: [TICKER] — [Company Name]
  header-meta: sector · FY date · CIK · "N benchmarks · N segments"
  legend (top-right): color swatches

FINGERPRINT × COVERAGE GRID   ← hero element
  (no section-label above the grid — it opens the page directly after the header)
  fp-grid table:
    group-header row: "Target" | "Group A label" | "Group B label (seg, purple)"
    col-header row: ticker pills (target=white, strong=green, partial=yellow, seg=purple)
    KPI rows:
      row-header: kpi-name + kpi-sub
      cells: target-col | match-strong | match-partial | match-none | seg-cell
    group-header separator rows for new KPI groups (e.g. segment-specific KPIs)

BENCHMARK DETAIL
  section-label: "Benchmark Detail"
  cat-divider: "[Group name]"    ← plain text, font-weight:500, color:var(--text-dim)
  bmark-list:
    bmark-row: (bmark-id with ticker+name) + (bmark-data with kpi-comp blocks + bmark-note)
  cat-divider (segment, purple): "[Segment] — segment sub-benchmarks"
  bmark-list: (segment benchmarks)

KPI CHARTS
  section-label: "KPI Charts"
  chart-tabs: tabbed interface — one tab per fingerprint KPI
    Tab nav: .tab-btn elements, active tab highlighted in var(--cyan)
    Tab panels: one canvas per tab, Chart.js bar chart
    Chart colors match ticker colors: target=rgba(255,255,255,0.15), strong=rgba(34,197,94,0.55),
      partial=rgba(234,179,8,0.45), seg=rgba(168,85,247,0.4)
    DRI target segments shown as separate bars within the target color range (rgba(255,255,255,0.08-0.15))
    Log scale for metrics with extreme range differences (e.g. energy GWh)

DIFF INSIGHT
  section-label: "Diff Insight"
  synthesis box (cyan left border): 2 paragraphs
    P1: what whole-company benchmarks reveal about the target
    P2: what the diff surfaced — segment gap or structural insight

NOTES
  section-label: "Notes"
  notes-list: ≤5 items (material caveats only — no scaling artifact explanations)

SOURCES
  section-label: "Sources"
  sources-table: Ticker | CIK | Coverage | FY end | Notes

FOOTER
  "Benchmark data from SEC filings via Revelata deepKPI. All values link to source filing passages."
  Right: "FY[YEAR] · [Month YEAR]"

CLOSING CTA ("try it yourself")
  Same block as Analysis Pressure Test HTML: linked headline "Run this on any report with your agent:",
  two columns (Claude vs OpenClaw) with MCP URL, install.sh curl, and a final bullet (use the
  benchmark-specific prompts in the HTML skeleton below, not "Pressure test this report").

DISCLOSURES
  Same legal paragraphs as Analysis Pressure Test reports: Compensation, Third-Party Content,
  General, and the follow-on unlabeled paragraph (verbatim from pressure-test template).
```

---

## Key CSS classes

### Fingerprint grid

```css
.grid-wrap { overflow-x: auto; }
.fp-grid { border-collapse: collapse; width: 100%; font-size: 0.74rem; }

/* Sticky row label */
.fp-grid th.row-header, .fp-grid td.row-header {
  position: sticky; left: 0; z-index: 2;
  background: var(--surface2); min-width: 140px; max-width: 160px;
}

/* Group separator rows */
.fp-grid .group-header th {
  background: var(--bg); font-size: 0.56rem; font-weight: 600;
  text-transform: uppercase; letter-spacing: 0.08em; color: var(--text-dim);
  padding: 0.5rem 0.6rem 0.2rem; border-top: 1px solid var(--border);
}

/* Col header ticker pills */
.col-ticker { font-family: 'Figtree', monospace; font-weight: 700; font-size: 0.85rem; }
.col-ticker.target  { color: #fff; }
.col-ticker.match-strong { color: var(--green); }
.col-ticker.match-partial { color: var(--yellow); }
.col-ticker.seg { color: var(--purple); }

/* Data cells — tighter padding */
.fp-grid td.cell {
  padding: 0.35rem 0.55rem; border-bottom: 1px solid var(--border);
  text-align: center; vertical-align: middle; white-space: nowrap; min-width: 92px;
  font-family: 'JetBrains Mono', monospace; font-size: 0.71rem;
}

/* Cell states */
td.cell.target-col  { background: rgba(255,255,255,0.04); color: #fff; font-weight: 600; }
td.cell.match-strong { background: var(--green-mid); color: #86efac; }
td.cell.match-partial { background: var(--yellow-mid); color: #fde68a; }
td.cell.match-none   { background: transparent; color: var(--text-dim); }
td.cell.seg-cell     { background: var(--purple-dim); color: #d8b4fe; }

/* Delta sub-value */
.delta { display: block; font-size: 0.58rem; color: inherit; opacity: 0.65; margin-top: 0.08rem; }
```

### Benchmark cards

```css
.bmark-row {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 7px; display: grid; grid-template-columns: 100px 1fr; overflow: hidden;
}
.bmark-id {
  padding: 0.55rem 0.7rem; border-right: 1px solid var(--border);
  display: flex; flex-direction: column; justify-content: center;
  background: var(--surface2);
}
.bm-ticker { font-family: 'Figtree', monospace; font-weight: 700; font-size: 1rem; }
.bm-ticker.strong { color: var(--green); }
.bm-ticker.partial { color: var(--yellow); }
.bm-ticker.seg    { color: var(--purple); }

/* Category dividers — lighter than old tier labels */
.cat-divider {
  font-size: 0.6rem; font-weight: 500; text-transform: uppercase; letter-spacing: 0.07em;
  color: var(--text-dim); margin: 1rem 0 0.4rem; padding-bottom: 0.25rem;
  border-bottom: 1px solid var(--border);
}
/* Segment sub-benchmark group */
.cat-divider.seg { color: var(--purple); border-color: rgba(168,85,247,0.2); }
```

### Synthesis (Diff Insight)

```css
.synthesis {
  background: linear-gradient(135deg, rgba(79,234,255,0.04) 0%, transparent 60%);
  border: 1px solid rgba(79,234,255,0.15); border-left: 3px solid var(--cyan);
  border-radius: 7px; padding: 0.9rem 1.1rem; margin: 0.4rem 0 1.2rem;
}
.synthesis-title {
  font-size: 0.58rem; font-weight: 700; text-transform: uppercase;
  letter-spacing: 0.09em; color: var(--cyan); margin-bottom: 0.7rem;
}
```

### Page footer, closing CTA, and disclosures

Use the same rules as `analyst-report-pressure-test/references/html-template.md`: data
footer, then **closing CTA** (self-serve install), then **disclosures**. Copy the CSS below
into the report’s `<style>` block (merge with existing rules).

```css
/* Footer */
.footer {
  margin-top: 2.5rem; padding-top: 1.4rem;
  border-top: 1px solid var(--border);
  font-size: 0.75rem; color: var(--text-dim); text-align: center;
}
.footer a { color: var(--cyan); text-decoration: none; }
.footer a:hover { text-decoration: underline; text-decoration-style: dotted; text-underline-offset: 3px; }

/* Disclosures */
.disclosures {
  margin-top: 1.5rem; padding-top: 1.2rem;
  border-top: 1px solid var(--border);
  font-size: 0.68rem; color: var(--text-dim);
  line-height: 1.6;
}
.disclosures p { margin-top: 0.7rem; }
.disclosures p:first-child { margin-top: 0; }
.disclosures strong { color: var(--text-muted); font-weight: 700; }

/* Closing CTA — plain on page background, between footer and disclosures */
.closing-cta {
  margin-top: 2rem;
  font-size: 0.82rem; color: var(--text-muted);
  line-height: 1.65;
}
.closing-cta .cta-setup-label {
  font-family: 'Figtree', 'Inter', system-ui, sans-serif;
  font-size: 1.15rem; font-weight: 700;
  margin-bottom: 1rem;
}
.closing-cta .cta-setup-label a {
  color: var(--cyan);
  text-decoration: none;
  border-bottom: 1px solid transparent;
  transition: border-color 0.15s ease;
}
.closing-cta .cta-setup-label a:hover {
  border-bottom-color: var(--cyan);
  text-decoration: none;
}
.closing-cta .cta-paths {
  display: grid; grid-template-columns: 1fr 1fr; gap: 1.6rem;
  margin-top: 0.3rem;
}
.closing-cta .cta-path-label {
  font-size: 0.7rem; font-weight: 700;
  text-transform: uppercase; letter-spacing: 0.07em;
  color: var(--text); margin-bottom: 0.5rem;
  padding-bottom: 0.4rem; border-bottom: 1px solid var(--border);
}
.closing-cta strong { color: var(--text-muted); font-weight: 700; }
.closing-cta a:not(.cta-setup-label *) {
  color: var(--cyan); text-decoration: underline;
  text-decoration-style: dotted; text-underline-offset: 2px;
}
.closing-cta a:not(.cta-setup-label *):hover { text-decoration-style: solid; }
.closing-cta ol { padding-left: 1.3rem; margin-top: 0.3rem; }
.closing-cta ol li { margin: 0.35rem 0; }
.closing-cta code {
  font-family: ui-monospace, 'SF Mono', Menlo, monospace;
  font-size: 0.75rem; color: var(--text);
  background: var(--surface); padding: 1px 6px; border-radius: 3px;
  border: 1px solid var(--border);
}

@media (max-width: 700px) {
  .closing-cta .cta-paths { grid-template-columns: 1fr; gap: 1.2rem; }
}
```

---

## Footer, “try it yourself” CTA, and disclosures (HTML)

Place **after** the main benchmark content (e.g. after Sources). The **closing CTA** is the same
self-serve (“try it yourself”) install block as in `analyst-report-pressure-test/references/html-template.md`
(same headline link text, same steps 1–2). Step 3 must reference **benchmarking / peers / comps**
(see below), not pressure-testing an analyst report. The **disclosure** `<div class="disclosures">`
block matches the pressure-test template **word for word**.

```html
<!-- ===== FOOTER ===== -->
<div class="footer">
  Benchmark data sourced from SEC filings via
  <a href="https://www.revelata.com" target="_blank" rel="noopener noreferrer">Revelata deepKPI</a>.
  All values link to source filing passages.
</div>

<!-- ===== CLOSING CTA (try it yourself) ===== -->
<div class="closing-cta">
  <p class="cta-setup-label"><a href="https://github.com/revelata/deepkpi-agents" target="_blank" rel="noopener noreferrer">Run this on any report with your agent:</a></p>

  <div class="cta-paths">
    <div class="cta-path">
      <div class="cta-path-label">For Claude</div>
      <ol>
        <li>Claude Settings → Connectors → Add Custom Connector: <code>https://deepkpi-mcp.revelata.com/mcp</code></li>
        <li>Install Revelata deepKPI agents: <code>curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash</code></li>
        <li>Ask Claude to benchmark a company, find peers or comps, or identify the most similar public companies.</li>
      </ol>
    </div>

    <div class="cta-path">
      <div class="cta-path-label">For OpenClaw</div>
      <ol>
        <li><a href="https://www.revelata.com/for-ai-builders" target="_blank" rel="noopener noreferrer">Get a DEEPKPI_API_KEY</a></li>
        <li>Install Revelata deepKPI agents: <code>curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash -s openclaw</code></li>
        <li>Ask your agent to benchmark a company, find peers or comps, or identify the most similar public companies.</li>
      </ol>
    </div>
  </div>
</div>

<!-- ===== DISCLOSURES (same as Analysis Pressure Test template) ===== -->
<div class="disclosures">
  <p><strong>Compensation Disclosure:</strong> No part of the compensation of any Revelata personnel was, is, or will be directly or indirectly related to the specific views, conclusions, or recommendations expressed in this report, or to the coverage of any particular security or issuer herein.</p>

  <p><strong>Third-Party Content Disclosure:</strong> This report references and comments on research produced by a third-party analyst and their affiliated institution. Any such references are made for purposes of analysis and commentary only. The referenced analyst and their institution have not reviewed, approved, sponsored, or endorsed this report, Revelata, or any of Revelata's products, services, views, or conclusions, and no such endorsement or affiliation should be inferred. All commentary, opinions, and conclusions added by Revelata are solely those of Revelata and do not represent the views of the referenced analyst or their institution.</p>

  <p><strong>General Disclosure:</strong> The information contained in this equity research report is provided for informational purposes only and is not intended to constitute financial advice or a recommendation to buy, sell, or hold any securities. The opinions expressed herein are as of the date of publication and are subject to change without notice. This report does not take into account the investment objectives, financial situation, or specific needs of any individual investor.</p>

  <p>We are not a licensed financial advisor, broker, or dealer, and this report is not intended to provide investment, legal, accounting, or tax advice. Any reliance on the information contained in this report is at the sole discretion and risk of the user.</p>
</div>
```

---

## Grid skeleton

```html
<div class="grid-wrap">
<table class="fp-grid">
  <thead>
    <tr class="group-header">
      <th class="row-header"></th>
      <th colspan="1" style="color:rgba(255,255,255,0.35);">Target</th>
      <th colspan="N" style="color:var(--text-dim);">[Whole-company group label]</th>
      <!-- If segment sub-benchmarks exist: -->
      <th colspan="N" style="color:var(--purple);opacity:0.7;">[Segment] — sub-benchmarks</th>
    </tr>
    <tr class="col-header">
      <th class="row-header">KPI</th>
      <th style="text-align:center;"><div class="col-ticker target">[TARGET]</div></th>
      <th style="text-align:center;"><div class="col-ticker match-strong">[TICKER1]</div></th>
      <th style="text-align:center;"><div class="col-ticker match-partial">[TICKER2]</div></th>
      <th style="text-align:center;"><div class="col-ticker seg">[TICKER3]</div></th>
    </tr>
  </thead>
  <tbody>
    <!-- Optional group separator within body -->
    <tr class="group-header">
      <th class="row-header">[Group name e.g. "Whole-company"]</th>
      <th></th><th></th><th></th><th></th>
    </tr>
    <tr>
      <td class="row-header">
        <span class="kpi-name">[KPI label]</span>
        <span class="kpi-sub">[unit / period]</span>
      </td>
      <td class="cell target-col"><a href="provenance-url">[value]</a></td>
      <td class="cell match-strong"><a href="provenance-url">[value]</a><span class="delta">[±delta]</span></td>
      <td class="cell match-partial"><a href="provenance-url">[value]</a><span class="delta">[±delta]</span></td>
      <td class="cell match-none">—</td>
    </tr>
    <!-- For segment-specific KPI rows where all whole-company cols are blank: -->
    <tr class="group-header">
      <th class="row-header" style="color:var(--purple);opacity:0.7;">[Segment name]</th>
      <th></th><th></th><th></th><th></th>
    </tr>
    <tr>
      <td class="row-header"><span class="kpi-name">[Segment KPI]</span></td>
      <td class="cell target-col"><a href="provenance-url">[value]</a></td>
      <td class="cell match-none">—</td> <!-- all whole-company cols blank = gap visualization -->
      <td class="cell match-none">—</td>
      <td class="cell seg-cell"><a href="provenance-url">[value]</a></td>
    </tr>
  </tbody>
</table>
</div>
```

---

## Benchmark card skeleton

```html
<div class="cat-divider">[Group label]</div>
<div class="bmark-list">
  <div class="bmark-row">
    <div class="bmark-id">
      <div class="bm-ticker strong">[TICKER]</div>  <!-- strong | partial | seg -->
      <div class="bm-name">[Full company name]</div>
    </div>
    <div class="bmark-data">
      <div class="kpi-comp">
        <div class="kc-label">[KPI name]</div>
        <div class="kc-val green"><a href="provenance-url">[value]</a></div>  <!-- green | yellow | dim -->
        <div class="kc-delta pos">vs [target value] ([±delta])</div>  <!-- pos | neg -->
      </div>
      <!-- More kpi-comp blocks -->
      <div class="bmark-note">[1-2 sentence analytical note]</div>
    </div>
  </div>
</div>

<!-- Segment sub-benchmark group -->
<div class="cat-divider" style="color:var(--purple);border-color:rgba(168,85,247,0.2);">
  [Segment name] — segment sub-benchmarks
</div>
```

---

## Chart color conventions

```js
// Chart.js backgroundColor / borderColor
// Target: rgba(255,255,255,0.15) / rgba(255,255,255,0.4)
// Strong match: rgba(34,197,94,0.55) / rgba(34,197,94,0.9)
// Partial match: rgba(234,179,8,0.45) / rgba(234,179,8,0.8)
// Segment sub-benchmark: rgba(168,85,247,0.4) / rgba(168,85,247,0.8)
// Target segment breakdown: rgba(255,255,255,0.08) / rgba(255,255,255,0.25)
// Negative values: rgba(239,68,68,0.35) / rgba(239,68,68,0.8)
```

---

## Rules

1. **Every number must be a hyperlink** to its `https://www.revelata.com/docviewer?pvid=NNNNN` URL.
2. **No tier badges** — color-coded tickers convey match quality; labels are plain category dividers.
3. **Target column = white**, not amber/yellow. Amber/yellow is reserved for partial benchmark match.
4. **Do not add scaling artifact footnotes** — silently correct values if confident they are wrong.
5. **Category dividers are plain text** (`font-weight: 500`, `color: var(--text-dim)`) not bold headers.
6. **Coverage gaps are visualized as blank rows** — rows where all benchmark columns show `—` make
   the gap immediately visible without prose explanation.
7. **Segment sub-benchmark headers and tickers use purple** — `var(--purple)` #a855f7.
8. **Chart colors match ticker colors** — visual consistency between grid and charts.
9. **All segments or none** — if the target company has multiple reportable brand/business segments,
   include a grid row group for every segment (comps + AUV, or equivalent KPIs), not just the one
   with the best coverage. The benchmark columns for sparse segments will naturally show `—`, which
   is informative. Never arbitrarily cap the fingerprint at N dimensions or expose only the segments
   with the best benchmark matches.
10. **Body padding**: `1.25rem 1.75rem`. Section label margins: `1.5rem 0 0.4rem`. Tab panel
    padding: `0.7rem 0.9rem`. Benchmark card data padding: `0.45rem 0.7rem`. These are the
    post-compaction values — use them to keep the layout dense and non-bloated.
11. **Footer + closing CTA + disclosures**: Always append the `.footer`, `.closing-cta`, and
    `.disclosures` blocks from the skeleton above — same legal copy as Analysis Pressure Test;
    same CTA headline and install steps 1–2; step 3 prompts benchmarking / peers / comps.
