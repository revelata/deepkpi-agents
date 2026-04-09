---
name: analyst-report-stress-test
description: >
  Stress-test any analyst report on a US public company. Upload a PDF of a sell-side
  report and say "Stress test this" — the skill extracts the analyst's key arguments,
  pulls granular SEC filing data via deepKPI to build supporting and counter-evidence
  for each claim, then produces an interactive HTML report with Revelata dark branding,
  Chart.js visualizations (blue palette), source attribution (amber = analyst, cyan = SEC),
  and clickable provenance hyperlinks to the exact filing passages. Use whenever the user
  mentions "stress test", "stress-test", "critically analyze", "triangulate", "fact-check",
  or "challenge" in the context of an analyst report, research note, or investment thesis.
  Also triggers when the user uploads a PDF that looks like a sell-side report and asks
  for analysis, counterpoints, or a second opinion on it.
---

# Analyst report stress test

Take an analyst report and rigorously test every argument against SEC filing data.
The output is an interactive HTML report that a portfolio manager can open in a browser
and use to form an independent view — every number is clickable back to its source.

## When this skill triggers

- User says "stress test this" (or similar) with an uploaded analyst report
- User uploads a sell-side PDF and asks for critical analysis, counterpoints, or fact-checking
- User asks to "triangulate" or "challenge" an investment thesis

## Chat pacing and verbosity

Keep the **conversation** thin; put the depth in the **HTML report**.

- After reading the PDF, state the **4–6 main arguments** you will stress-test
  (short titles or one line each — this is the roadmap for the user).
- Also state you'll pull **market reaction context** (price on report date vs today),
  then move straight into data pulls.
- Do **not** narrate every tool call, intermediate table, or reasoning step in chat.
  Avoid dumping raw deepKPI responses into the thread.
- While pulling data, use a **brief progress line per argument**, e.g.
  `Pulling SEC data for 2/5: [short argument title]…` then continue silently until
  the next argument or until the HTML is ready.
- **Automatically build and save the HTML report** when pulls and drafting are
  complete. Do **not** ask whether to generate the file unless the user explicitly
  asked for a non-HTML deliverable only.
- After the file exists: **present** it (`present_files` or equivalent) and add
  **1–2 sentences** on the sharpest takeaway — no full recap.

## High-level workflow

1. **Read the report** — extract the analyst's 4-6 key arguments/claims
2. **Identify the company** — resolve the ticker/name to a CIK via deepKPI
3. **Pull SEC data** — for each argument, search deepKPI for the most granular
   metrics that can confirm or complicate the claim
4. **Build evidence pairs** — for each argument, write a "supports the thesis"
   card and a "complicates the thesis" card, grounded in specific numbers
5. **Write the synthesis** — 2 paragraphs that weave the evidence into a nuanced
   take the analyst didn't give you
6. **Generate the HTML** — an interactive, dark-themed report with Chart.js charts,
   source attribution, and provenance links (**default deliverable — produce it without asking**)
7. **Deliver** — save to the workspace and present to the user (**short wrap-up only**)

Each of these steps is detailed below. Follow **Chat pacing and verbosity** for what to say in-thread vs. what belongs only in the HTML.

## Dependencies

This skill relies on **`retrieve-kpi-data`** for all data retrieval. Before starting,
read `retrieve-kpi-data/retrieve-kpi-data.md` for the full
retrieval workflow, provenance rules, and gap-handling logic. That skill handles
the mechanics of talking to deepKPI — this skill handles the analytical framework
and HTML output.

## Scope

This skill works for **US public companies** with SEC filings indexed in deepKPI.
If the report covers a non-US company or a private company, tell the user that
deepKPI doesn't have coverage and offer to do a qualitative analysis instead
(without the data-backed evidence cards and provenance links).

---

## Step 1: Read the analyst report

Read the uploaded PDF. Extract:

- **Company name and ticker**
- **Report metadata**: author/firm, date, rating action (upgrade/downgrade/initiation),
  price target if applicable. Store the firm name internally for source pills and claim
  banners, but **do not surface the firm name in the footer or synthesis**.
- **4-6 key arguments** the analyst makes. These are the claims you'll stress-test.
  Look for: revenue/growth commentary, margin trends, segment performance, balance
  sheet / leverage, competitive positioning, specific catalysts or risks.

Write each argument as a 1-2 sentence summary. You'll use these as the section
headers in the final report. **In chat**, share this list once as the identified
main arguments; do not pre-write full evidence cards in the thread.

## Step 1.5: Market reaction context (price move since publication)

Get the stock **close price** on:

- **Report date** (use the report's publication date; if only a date is given, use that day's close)
- **Current date** (most recent close)

Compute percent move: \(\Delta\% = (P_\text{now}/P_\text{report} - 1)\times 100\).

### Reporting rules (keep concise)

- Add a small **\"Price since report\"** box near the top of the HTML with the two closes and the \(\Delta\%\).
- If the report is **> 3 weeks old**, add 2–4 sentences in the HTML (not the chat thread) on:
  what the price did since publication and which **SEC KPIs** would have hinted at (or failed to hint at) that move.
- If the report is **> 3 months old**, add a short contrast in the HTML between:
  **data available at the time of the report** vs **new filings/KPIs since then**, and whether the new data supports or undermines the original claims.

If price data cannot be retrieved reliably in the current environment, state that in the HTML box and continue with the SEC stress test.

## Step 2: Resolve the company in deepKPI

Use the **`retrieve-kpi-data`** workflow:

1. Call `query_company_id` with the company's official registrant name (not brand)
2. Call `list_kpis` (free) to see every available metric
3. Scan the KPI list to plan your searches — map each analyst argument to the
   most granular KPIs available

**Fiscal year awareness**: Note the company's fiscal year-end. Map calendar
quarters to fiscal quarters correctly. For example, Clorox's FY ends June 30,
so Sep 30 = FQ1, Dec 31 = FQ2, etc.

## Step 3: Pull SEC data for each argument

For each argument, run targeted `search_kpis` calls. Follow the deepKPI
retrieval skill's granularity principle: unit-level and segment data first,
consolidated metrics as context. In chat, one short **progress line per argument**
is enough (see **Chat pacing and verbosity**); do the heavy lifting quietly.

Typical queries per argument:

- **Volume/growth claims**: organic volume by segment, price/mix by segment,
  total organic sales growth
- **Margin claims**: gross profit, COGS, segment EBIT, segment margins
  (compute from EBIT / revenue)
- **Segment performance**: segment revenue, segment EBIT, segment-level
  organic volume and price/mix
- **Leverage/balance sheet**: total debt, EBITDA, interest expense, cash flow
  from operations
- **Competitive/market claims**: ad spend, customer concentration, international
  growth, R&D

**Derive what's missing**: If Q4 is absent, compute Q4 = FY - (Q1+Q2+Q3).
If a segment is missing, compute it as residual. See `derive-implied-metric/derive-implied-metric.md`.

**Save every provenance URL** returned by deepKPI. You'll need them for the
hyperlinks in the HTML.

**Credit management**: `search_kpis` costs 1 credit per result. Use `list_kpis`
(free) first to find exact KPI names, then use those names as targeted queries
with `num_of_res=3`. Run searches in parallel where possible to save round-trips.
If the user runs out of credits, display the required purchase message and pause.

## Step 4: Build evidence pairs

For each argument, write two evidence cards:

### "Supports the thesis" card
Data that confirms or strengthens the analyst's point. Often this means:
- Filing data that matches or exceeds the concern the analyst raised
- Trend data showing the problem is worsening or more structural than stated
- Additional metrics the analyst didn't cite that reinforce the argument

### "Complicates the thesis" card
This isn't cheerleading for the company — it's intellectual honesty. The best
analysts miss things because they're writing for a specific audience with a
specific deadline. Your job is to find the data they didn't show. Often this means:
- Context the analyst omitted (base effects, one-time items, comp distortions)
- Offsetting positives in other segments or metrics
- Trend improvements the analyst underplayed
- Management guidance or forward-looking data points
- The analyst's own caveats buried in the fine print

**Writing style**: Be analytical and specific. Every number must have a source —
either `[SEC]` with a provenance hyperlink, or a source pill referencing the
analyst report. Don't hedge excessively; take a clear analytical position
in each card. Use the firm abbreviation only in source pills and claim banners —
never in the footer or synthesis prose (refer to "the report" or "the analyst"
instead).

## Step 5: Write the synthesis

Two paragraphs at the bottom of the report. Refer to "the report" or "the
analyst" — **never name the firm** in the synthesis.

- **Paragraph 1**: What the analyst gets right. Acknowledge the strongest evidence
  supporting the thesis, citing specific numbers.
- **Paragraph 2**: What the analyst misses or overstates. The nuances, context,
  and counterfactuals that complicate the picture. End with the key risk or
  decision point — what would have to go wrong (or right) for the thesis to
  play out differently.

Every number in the synthesis must also be hyperlinked to its source.

## Step 6: Generate the HTML report

Read `references/html-template.md` in this folder for the complete HTML/CSS/JS template.

The report structure:

```
Header
  - Revelata brand mark + "Analysis Stress Test"
  - Title: "[Company] ([Ticker]): Stress-Testing the [Firm] [Action]"
  - Subtitle: firm, report title, date, rating action
  - Legend: amber = "analyst report" data, cyan = "SEC filings (deepKPI)"
    (use generic labels in the legend — the firm name only appears in the
     title, subtitle, source pills, and claim banners)

For each argument (numbered 01, 02, ...):
  - Section heading
  - Analyst claim banner (amber left-border, quoting the analyst)
  - 1-2 Chart.js charts (if the data tells a better story visually)
  - Evidence grid: support card (red top) | counter card (green top)

Synthesis section (cyan glow background)
Footer (data sourcing disclaimer)
Chart.js scripts
```

### Chart guidelines

- Use Chart.js 4.x loaded from cdnjs
- **Blue-family palette only** for SEC data: `#4FEAFF` (cyan), `#90caf9` (light blue),
  `#5b8def` (mid blue), `#a78bfa` (periwinkle)
- Differentiate series via: dash patterns (`[]`, `[6,3]`, `[2,3]`, `[8,4,2,4]`),
  point shapes (`circle`, `rect`, `triangle`, `rectRounded`), and shade
- Positive/negative bars: use opacity (e.g., `B1+'99'` vs `B1+'33'`)
- Dark background means white-ish grid lines at very low opacity (`rgba(255,255,255,0.05)`)
- Max height: 280px per chart
- Charts get a cyan left-border highlight: `border-left: 3px solid var(--cyan)`

### Source attribution

- **Amber** (`--amber: #f59e0b`) for data from the analyst report
  - Source pills: `<span class="src-pill src-r">JPM</span>` (use the firm's abbreviation)
  - Claim banners: amber left-border
- **Cyan** (`--cyan: #4FEAFF`) for SEC filing data from deepKPI
  - Source pills: `<span class="src-pill src-s">SEC</span>`
  - Every SEC number must be a hyperlink: `<a href="provenance-url" target="_blank">value</a>`
  - Links use dotted underline style

### Provenance hyperlinks — non-negotiable

Every number sourced from deepKPI must be wrapped in an `<a>` tag linking to
its exact provenance URL. This is the audit trail that makes the report credible.
Copy URLs exactly as returned from the API. Never fabricate a URL.

Format: `<a href="https://www.revelata.com/docviewer?pvid=XXXX" target="_blank">$248M</a>`

This applies to numbers in:
- Evidence card text
- Synthesis paragraphs
- Anywhere else a deepKPI number appears in prose

## Step 7: Deliver

1. **Generate the HTML** (steps 4–6) and save to the workspace as
   `[TICKER]_Critical_Analysis.html` (e.g., `CLX_Critical_Analysis.html`) **without
   asking for confirmation** — this is the expected output of the skill.
2. Present it to the user with `present_files` (or your client's equivalent).
3. **Closing message**: 1–2 sentences on the most interesting tension or finding.
   Do not paste large excerpts from the HTML or rehash every argument in chat.

---

## Reference files

| File | When to read |
|------|-------------|
| `references/html-template.md` | Always — contains the full HTML/CSS/JS template |
| `references/chart-patterns.md` | When building charts — palette, dash patterns, examples |

---

## Common failure modes

- **Over-narrating in chat**: long play-by-play of tools, data pulls, or draft prose
  before the HTML exists — keep thread updates to argument list + per-argument
  progress lines + final short summary
- **Leading with consolidated metrics**: always go granular first (segment, unit-level)
- **Missing provenance links**: every deepKPI number needs its `<a href>` tag
- **Wrong fiscal quarter mapping**: check the company's FY-end before labeling quarters
- **Timid counter-evidence**: the "complicates" card should genuinely challenge the thesis,
  not just say "but maybe it'll get better"
- **Too many arguments**: 4-6 is the sweet spot. More than 6 makes the report unwieldy
- **Charts without clear purpose**: only add a chart when visual trend/comparison tells
  the story better than a sentence. Not every argument needs a chart.
- **Forgetting the source legend**: always include the amber/cyan legend at the top
- **Bare numbers in synthesis**: the synthesis is where people read closest — hyperlink everything
- **Naming the firm in the footer or synthesis**: the footer says "supplemental data from
  deepKPI" — never mention the analyst firm there. In the synthesis, say "the report" or
  "the analyst", not the firm name. This avoids an awkward dynamic when the analysis is
  critical.
- **Assuming standard segment structure**: some companies have non-obvious segment
  breakdowns (e.g., EL reports Mainland China as a separate segment from Asia/Pacific).
  Always scan the KPI list carefully before querying.
- **Ignoring derived metrics**: the deepKPI skill can compute implied Q4, segment
  remainders, per-unit economics, etc. These derived numbers often reveal the most
  interesting counter-evidence (e.g., operating leverage hiding behind a revenue decline).
- **deepKPI credits**: `search_kpis` costs 1 credit per result. Start with `num_of_res=3`
  and use exact KPI names from `list_kpis` (free) to keep costs down. If credits run out,
  display the purchase link and wait for the user.
