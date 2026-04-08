# HTML Template Reference

This is the canonical HTML structure for every Analysis Stress Test report.
Copy this skeleton and fill in the dynamic content. Do not deviate from the
CSS custom properties, class names, or layout structure — they are the Revelata
brand identity for this product.

## Full HTML skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>[TICKER] Analysis Stress Test | Revelata</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
  :root {
    --bg: #0e1117; --surface: #161b22; --surface2: #1c2129;
    --border: #2a313a; --border-light: #353d47;
    --text: #e6edf3; --text-muted: #8b949e; --text-dim: #6e7681;
    --cyan: #4FEAFF; --cyan-dim: rgba(79,234,255,0.15); --cyan-glow: rgba(79,234,255,0.08);
    --blue: #90caf9; --blue-dim: rgba(144,202,249,0.12);
    --amber: #f59e0b; --amber-dim: rgba(245,158,11,0.12); --amber-text: #fbbf24;
    --red: #f87171; --red-dim: rgba(248,113,113,0.10);
    --green: #4ade80; --green-dim: rgba(74,222,128,0.10);
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Inter', system-ui, sans-serif;
    background: var(--bg); color: var(--text);
    line-height: 1.7; padding: 2.5rem;
    max-width: 900px; margin: 0 auto;
    font-size: 14.5px; -webkit-font-smoothing: antialiased;
  }

  /* Header */
  .header { margin-bottom: 2.5rem; }
  .header-brand { display: flex; align-items: center; gap: 0.6rem; margin-bottom: 0.8rem; }
  .header-brand svg { width: 20px; height: 20px; }
  .header-brand span {
    font-size: 0.75rem; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.08em; color: var(--cyan);
  }
  h1 {
    font-size: 1.6rem; font-weight: 700;
    letter-spacing: -0.03em; color: #fff; margin-bottom: 0.3rem;
  }
  .subtitle { color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1.5rem; }
  .subtitle strong { color: var(--red); font-weight: 600; }

  /* Legend */
  .legend {
    display: flex; gap: 2rem; padding: 0.9rem 1.2rem;
    background: var(--surface); border: 1px solid var(--border);
    border-radius: 8px; font-size: 0.8rem; color: var(--text-muted);
  }
  .legend-item { display: flex; align-items: center; gap: 0.5rem; }
  .legend-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }

  /* Section headings */
  h2 {
    font-size: 1.1rem; font-weight: 700; color: #fff;
    margin: 3rem 0 0.4rem; padding-bottom: 0.5rem;
    border-bottom: 1px solid var(--border);
  }
  h2 .num { color: var(--cyan); margin-right: 0.4rem; }

  /* Analyst claim banner */
  .claim {
    background: var(--surface); border: 1px solid var(--border);
    border-left: 3px solid var(--amber); border-radius: 6px;
    padding: 0.9rem 1.1rem; margin: 1rem 0 1.2rem;
    font-size: 0.88rem; color: var(--text-muted);
  }
  .claim strong { color: var(--amber-text); font-weight: 600; }
  .claim .src {
    font-size: 0.7rem; font-weight: 600; color: var(--amber);
    text-transform: uppercase; letter-spacing: 0.06em; margin-right: 0.3rem;
  }

  /* Evidence cards */
  .evidence { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin: 1rem 0 1.5rem; }
  .ev-card {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: 8px; padding: 1.1rem 1.2rem;
    font-size: 0.85rem; line-height: 1.65; color: var(--text-muted);
  }
  .ev-card p { margin-bottom: 0.6rem; }
  .ev-card p:last-child { margin-bottom: 0; }
  .ev-support { border-top: 3px solid var(--red); }
  .ev-counter { border-top: 3px solid var(--green); }
  .ev-label {
    font-size: 0.7rem; font-weight: 700; text-transform: uppercase;
    letter-spacing: 0.07em; margin-bottom: 0.7rem;
    display: flex; align-items: center; gap: 0.4rem;
  }
  .ev-support .ev-label { color: var(--red); }
  .ev-counter .ev-label { color: var(--green); }
  .ev-label svg { width: 13px; height: 13px; }

  /* Inline data highlights */
  .d { font-weight: 600; }
  .d-r { color: var(--amber-text); }
  .d-s { color: var(--cyan); }
  .d-s a, .ev-card a, .synthesis a:not(.footer a) {
    color: var(--cyan); text-decoration: underline;
    text-decoration-style: dotted; text-underline-offset: 2px;
  }
  .d-s a:hover, .ev-card a:hover, .synthesis a:hover {
    text-decoration-style: solid;
  }

  /* Source pills */
  .src-pill {
    display: inline-block; font-size: 0.6rem; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.05em;
    padding: 1px 5px; border-radius: 3px;
    vertical-align: middle; margin-right: 2px;
  }
  .src-r { background: var(--amber-dim); color: var(--amber); }
  .src-s { background: var(--cyan-dim); color: var(--cyan); }

  /* Charts */
  .chart-card {
    background: var(--surface); border: 1px solid var(--border);
    border-left: 3px solid var(--cyan); border-radius: 10px;
    padding: 1.3rem 1.4rem; margin: 1.2rem 0;
  }
  .chart-header {
    display: flex; justify-content: space-between;
    align-items: baseline; margin-bottom: 0.8rem;
  }
  .chart-title { font-size: 0.8rem; font-weight: 600; color: var(--text); letter-spacing: 0.01em; }
  .chart-src { font-size: 0.65rem; color: var(--text-dim); }
  canvas { max-height: 280px; }

  /* Synthesis */
  .synthesis {
    background: var(--cyan-glow);
    border: 1px solid rgba(79,234,255,0.25);
    border-radius: 10px; padding: 1.6rem 1.8rem; margin: 3rem 0 1rem;
  }
  .synthesis h2 { border: none; margin-top: 0; color: var(--cyan); }
  .synthesis p { color: var(--text); margin-bottom: 0.9rem; }
  .synthesis p:last-child { margin-bottom: 0; }

  /* Footer */
  .footer {
    text-align: center; padding: 2rem 0 1rem;
    font-size: 0.7rem; color: var(--text-dim);
  }
  .footer a { color: var(--cyan); text-decoration: none; }

  /* Responsive */
  @media (max-width: 700px) {
    body { padding: 1.2rem; }
    .evidence { grid-template-columns: 1fr; }
    .legend { flex-direction: column; gap: 0.5rem; }
  }
</style>
</head>
<body>

<!-- ===== HEADER ===== -->
<div class="header">
  <div class="header-brand">
    <svg viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" stroke="#4FEAFF" stroke-width="2"/>
      <path d="M8 12h8M12 8v8" stroke="#4FEAFF" stroke-width="2" stroke-linecap="round"/>
    </svg>
    <span>Revelata &mdash; Analysis Stress Test</span>
  </div>
  <h1>[Company] ([TICKER]): Stress-Testing the [Firm] [Action]</h1>
  <p class="subtitle">
    [Firm] [Division] &mdash; "[Report Title]" &mdash; [Date] &mdash;
    Rating: [Old] &rarr; <strong>[New]</strong>
  </p>

  <div class="legend">
    <div class="legend-item">
      <div class="legend-dot" style="background:var(--amber)"></div>
      Analyst report data
    </div>
    <div class="legend-item">
      <div class="legend-dot" style="background:var(--cyan)"></div>
      Supplemental data from SEC filings (deepKPI)
    </div>
  </div>
</div>

<!-- ===== ARGUMENT N ===== -->
<!-- Repeat this block for each argument (4-6 total) -->

<h2><span class="num">01</span> [Argument Title]</h2>

<div class="claim">
  <span class="src">[FIRM] says:</span>
  [1-2 sentence summary of the analyst's claim. Bold the key numbers.]
</div>

<!-- Optional: 1-2 chart cards if visual comparison helps -->
<div class="chart-card">
  <div class="chart-header">
    <span class="chart-title">[Chart Title]</span>
    <span class="chart-src">
      <span class="src-pill src-s">SEC</span> [Filing type]
    </span>
  </div>
  <canvas id="c[N]"></canvas>
</div>

<div class="evidence">
  <div class="ev-card ev-support">
    <div class="ev-label">
      <svg viewBox="0 0 16 16" fill="currentColor">
        <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm1 10H7V7h2v4zm0-5H7V4h2v2z"/>
      </svg>
      Supports the thesis
    </div>
    <p>
      <span class="src-pill src-s">SEC</span>
      [Analysis with hyperlinked numbers:
       <span class="d d-s"><a href="provenance-url" target="_blank">$XXM</a></span>]
    </p>
  </div>
  <div class="ev-card ev-counter">
    <div class="ev-label">
      <svg viewBox="0 0 16 16" fill="currentColor">
        <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm1 10H7V7h2v4zm0-5H7V4h2v2z"/>
      </svg>
      Complicates the thesis
    </div>
    <p>
      <span class="src-pill src-s">SEC</span>
      [Counter-analysis with hyperlinked numbers]
    </p>
    <p>
      <span class="src-pill src-r">[FIRM]</span>
      [Relevant point from the report itself that complicates the thesis]
    </p>
  </div>
</div>

<!-- ===== END OF ARGUMENT BLOCKS ===== -->

<!-- ===== SYNTHESIS ===== -->
<div class="synthesis">
  <h2>The Deeper Picture</h2>
  <p>[Paragraph 1: what the analyst gets right, with hyperlinked numbers]</p>
  <p>[Paragraph 2: what the analyst misses, the key risk/decision point]</p>
</div>

<div class="footer">
  Supplemental data sourced from SEC filings via
  <a href="https://www.revelata.com" target="_blank">Revelata deepKPI</a>.<br>
  This analysis is for informational purposes only and does not constitute
  investment advice.
</div>

<!-- ===== CHARTS ===== -->
<script>
// Chart.js global defaults for dark theme
Chart.defaults.color = '#8b949e';
Chart.defaults.borderColor = '#2a313a';
Chart.defaults.font.family = "'Inter', system-ui, sans-serif";
Chart.defaults.font.size = 11;

// Blue/cyan palette — ALL SEC data charts use only these colors
const B1 = '#4FEAFF';  // cyan — primary
const B2 = '#90caf9';  // light blue — secondary
const B3 = '#5b8def';  // mid blue — tertiary
const B4 = '#a78bfa';  // periwinkle — quaternary
const grid = { color: 'rgba(255,255,255,0.05)' };

// [Insert chart constructors here — see chart-patterns.md for examples]
</script>
</body>
</html>
```

## Key rules

1. **Never change the CSS custom properties** — they are the brand identity
2. **Source pills are mandatory** on every data point in evidence cards
3. **Every SEC number must be an `<a href>` hyperlink** to its provenance URL
4. **Amber = analyst report, Cyan = SEC filing** — no exceptions
5. **Charts use blue-family palette only** — differentiate with dashes and point shapes
6. **The subtitle must include the rating action** (upgrade/downgrade/etc.) with the
   new rating in `<strong>` (which renders in red via CSS)
7. **Evidence cards are always in a 2-column grid**: support (red top) on the left,
   counter (green top) on the right
8. **The synthesis section** uses the cyan-glow background to visually separate it
9. **Footer** must include the Revelata link and the disclaimer — do **not** name the analyst firm in the footer
