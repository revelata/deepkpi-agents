---
name: tearsheet
description: >
    Generate a one-pager company summary, including a snapshot of key financials and 
    operational KPIs, useful for meeting or earnings prep.  Triggers only when the user 
    explicitly asks for a "tearsheet".  Do not trigger on broad questions such as
    "What does company X do?" because that is handled by the `company-summary` skill.
---

# tearsheet

Generate a short, concise company tearsheet that an analyst would typically look up before an earnings call. 

Since this tearsheet is used for the quarterly earnings call, you should only output quarterly KPIs, not annual. 

## Data source

See `../_common/data-source-rules.md`. Deep KPI data flows through the standard
`query_company_id` / `list_kpis` / `search_kpis` workflow used by the `kpi` skill.

## Hard stop if deepKPI access fails

See `../_common/connection-failure.md`. STOP and ask before falling back.

## Workflow

Follow these steps:

### 1. Company Summary 

Use the output from `company-summary` skill to generate a concise summary of the company.  It should be 3-5 bullets. 

### 2. Key Financials 

Use the `kpi` skill to pull the following key financial KPIs.  Pull the last 8 quarters to enable YoY calculations. Do NOT pull in annual numbers, except to use to calculate Q4 numbers where necessary.
- Revenue
- Gross Profit
- Operating Income
- EBITDA (if not reported, compute as Operating Income + D&A using the `implied-metric` skill and call it "EBITDA (derived)")
- Net Income
- Diluted EPS
- Operating Cash Flow
- CapEx (PPE purchases)
- Free Cash Flow (compute as Operating Cash Flow - CapEx using the `implied-metric` skill. Call it "FCF (derived)")

### 3. Operational KPIs 

Find the top 3-5 KPIs that are consequential **revenue drivers**, i.e., operational numbers that move revenue and earnings. NEVER include financial statement items (D&A, share count, buybacks, dividends) in this section. 
Pull the last 8 quarters to enable YoY calculations.  Do NOT pull in annual numbers, except to use to calculate Q4 numbers where necessary.

First, think about what the most important KPIs are for THIS specific company based on its business model and segments, and what drives its valuation. For example:
- **SaaS/cloud**: ARR, net revenue retention, RPO/cRPO, major customers, cloud gross margin
- **Consumer tech**: DAU/MAU, ARPU, engagement metrics, installed base, paid subscribers
- **E-commerce/marketplace**: GMV, take rate, active buyers/sellers, order frequency
- **Retail**: same-store sales, store count, average ticket, transactions
- **Telecom/media**: subscribers, churn, ARPU, content spend
- **Hardware**: units shipped, ASP, attach rate, installed base, products vs services gross margin split
- **Financial services**: AUM, NIM, loan growth, credit quality metrics
- **Pharma/biotech**: pipeline stage, patient starts, scripts, market share
- **Industrials/energy**: backlog, book-to-bill, utilization, production volumes

Then, search for those specific KPIs using the `kpi` skill. Also search for:
- Segment/product revenue breakdown
- Geographic revenue breakdown

If there are very few operational KPIs found, say that the company does not report granular operational KPIs. 

### 3b. Capital Return
Pull share count, share repurchases, and dividends paid for the same periods. This is a separate section from operating KPIs — it shows how the company is returning cash to shareholders.

<!-- ## 4. Compute Key Ratios

Using the `implied-metric` skill where appropriate, show trend over the last 4 quarters with YoY change for EACH quarter (not just the earliest):
- Gross Margin %
- Operating Margin %
- EBITDA Margin %
- Net Margin %
- Revenue Growth (YoY)
- EPS Growth (YoY)

If the company has strong seasonality (e.g., retail Q4, back-to-school, etc.), add a brief note flagging it so YoY comparisons are read in context rather than sequential QoQ.

Only attempt to calculate a ratio if the inputs are available from **deepKPI**.  If ANY input is unavailable for a particular ratio calculation, DO NOT calculate and instead return "incalculable". -->

### 4. Recent Developments
Use the `filing` skill to look up the most recent 2 quarters of filings. Try multiple keyword searches to get coverage:
- First search: company name + "results" or "record" for earnings highlights
- Second search: "outlook" or "guidance" or "expect" for forward-looking commentary
- Third search: strategy-specific terms relevant to the company (e.g., "AI", "cloud", "subscribers", "margin")
- If a search returns empty, try broader single-keyword searches before giving up

Extract:
- Key recent developments or announcements
- Management's top priorities or strategic focus areas
- Any notable management quotes, quoted verbatim with document citations
Keep this brief — 3-5 bullet points max.

### 5. Five Key Tensions
Identify the 5 most critical bull/bear debates for this stock. Each tension is a single line that frames both sides. Alternate between bullish-leaning and bearish-leaning tensions. Every tension must reference a specific data point from the analysis above.

Format as a numbered list:
1. "[Bullish factor] vs [Bearish factor]" — cite the specific metric
2. "[Bearish factor] vs [Bullish factor]" — cite the specific metric
...etc.

This goes at the top of the report, right after the Company Overview — it gives the reader the bull/bear framing before they dive into the data.

### 6. News Snapshot
Run 2 WebSearch queries to gather recent context:
1. `"{TICKER} {company_name} news {current_year}"` — recent headlines
2. `"{TICKER} catalysts risks {current_year}"` — forward-looking events

Distill into **3-5 key events** from the last 6 months, reverse chronological. Each event: date, one-line headline, sentiment tag (Positive / Negative / Mixed / Upcoming). Keep it tight — this is a tearsheet, not a research note.

### 7. What to Watch
Build a **Quantitative Monitors** list — 5 metrics with explicit thresholds:
- Format: "Metric: current value → bull threshold / bear threshold"
- Example: "Gross Margin: 45.2% → above 46% confirms pricing power / below 43% signals cost pressure"

Choose the 5 metrics that matter most for THIS company's thesis based on the data you pulled above. These should be actionable — an analyst should be able to check these next quarter and know whether the thesis is intact.

### 8. Save Report
Save to `reports/{TICKER}_tearsheet.html` using the template below.  Write the full analysis as styled HTML with the design system CSS inlined. This is the final deliverable — no intermediate markdown step needed.

Structure the report with these sections:

```
<h1>{Company Name} ({TICKER}) — Tearsheet</h1>
<p>Generated: {date}</p>

<h2>Company Overview</h2>
{2-3 sentence description from filings}

<h2>Five Key Tensions</h2>
{numbered list of 5 bull/bear debates with data citations}

<h2>Key Financials (Last 4 Quarters)</h2>
<table>
| Metric | Q(oldest) | Q | Q | Q(latest) |
{table with Daloopa citations; derived metrics marked (calc.)}
</table>

<h2>Segment / Geographic Breakdown</h2>
{segment revenue table or geographic revenue table, whichever is more relevant}

<h2>Key Operating KPIs</h2>
<table>
| KPI | Q(oldest) | Q | Q | Q(latest) |
{table with Daloopa citations — ONLY business-driver metrics, NOT financial items}
{if few KPIs available, note the disclosure gap}
</table>

<h2>Capital Return</h2>
<table>
| Metric | Q(oldest) | Q | Q | Q(latest) |
{share count, buybacks, dividends — separate from operating KPIs}
</table>

<h2>Margins & Growth</h2>
<table>
| Metric | Q(oldest) | Q | Q | Q(latest) |
| Gross Margin % | X% | X% | X% | X% |
| ... | ... | ... | ... | ... |
| Rev Growth YoY | X% | X% | X% | X% |
| EPS Growth YoY | X% | X% | X% | X% |
{each cell shows the YoY change for THAT quarter}
{note on seasonality if applicable}
</table>

<h2>Recent Developments</h2>
<ul>{bullet points from filings with document citations}</ul>

<h2>News Snapshot</h2>
{3-5 recent events with date, headline, sentiment tag}

<h2>What to Watch</h2>
{5 quantitative monitors with current value and bull/bear thresholds}
```

Tell the user where the HTML report was saved.

Give a 2-3 sentence summary of the company's current state, including an honest assessment: What is the single biggest risk or concern? Does the current valuation (price, implied multiples) seem warranted given the growth trajectory? What would make you cautious about owning this stock?
