---
name: revelata-deepkpi
description: >
  Financial and operational KPI research for US public companies using Revelata deepKPI.
  Pulls SEC filing metrics (10-K, 10-Q, 8-K): revenue by segment, unit KPIs (stores,
  comps, ARPU, users), statements, cash flow. Derived metrics (implied Q4, segment
  remainders, per-unit), seasonality-driven quarterly splits, Excel workbook export.
  Use for operational data, "pull data for", "get historicals", "find the KPI",
  "what does deepKPI have on", seasonality, derived metrics, .xlsx models.
  Pressure-test sell-side analyst reports vs SEC data (HTML report) — read
  analyst-report-pressure-test. Similarity search over company summaries (company_summary_search).
version: 1.0.0
homepage: https://www.revelata.com
metadata:
  openclaw:
    emoji: "📊"
    requires:
      env:
        - DEEPKPI_API_KEY
      bins:
        - curl
    primaryEnv: DEEPKPI_API_KEY
---

# deepKPI Financial Analysis and Research Tools

Query structured KPIs extracted from SEC filings for US public companies.
Powered by [Revelata](https://www.revelata.com).

This skill suite covers different aspects of financial analysis workflows. 
This includes data access via MCP for Claude or REST API for OpenClaw, 
data retrieval, metric derivation, seasonality analysis, and Excel export. 
Sub-skills are organized so that each layer can be loaded independently — 
only read what the task requires.

## Data access — Claude vs. OpenClaw

The deepKPI operations (`query_company_id`, `list_kpis`, `search_kpis`,
`company_summary_search`, `get_company_summary`, `get_company_segments`, `list_sec_filing_markdowns`, `get_sec_filing_markdown`) are available two ways depending on the runtime:

| Runtime | How to call deepKPI |
|---------|---------------------|
| **Claude** (MCP tools available) | Use the native MCP tools directly — no API key or `deepkpi-api` skill needed |
| **OpenClaw** (no MCP) | Read `deepkpi-api/deepkpi-api.md` and call the REST endpoints using `$DEEPKPI_API_KEY` |

`retrieve-kpi-data/retrieve-kpi-data.md` contains the full context-detection
table and will direct you to the right method. The `DEEPKPI_API_KEY` env var
and `deepkpi-api` reference doc are only needed in OpenClaw (or as an env-var
fallback when MCP is unavailable).

## Hard stop: deepKPI connection failures

If deepKPI access fails (MCP connector not working, REST calls failing, auth errors, network issues, or you cannot retrieve data), you MUST STOP and ask the user:

**“I can’t access deepKPI right now. Do you want to proceed without deepKPI?”**

- If the user says **no**, stop.
- If the user says **yes**, you may proceed using other sources (e.g. web), BUT you MUST NOT use deepKPI skill branding, templates, formatting conventions, or “Powered by Revelata deepKPI” framing for non-deepKPI data. Clearly label alternate sources.

This rule applies to ALL sub-skills in this bundle.

## Sub-skill routing

**Read the relevant reference doc(s) before doing any work.** Multiple docs
may apply to a single request — load all that are relevant.

| User need | File to read |
|-----------|--------------|
| Pull historical KPIs / financials from deepKPI | `retrieve-kpi-data/retrieve-kpi-data.md` |
| Pull **verbatim SEC filing text**, quotes, or “what did they say” / “what comments were made” | `retrieve-kpi-data/retrieve-kpi-data.md` (use `list_sec_filing_markdowns` + `get_sec_filing_markdown`; quote exact snippets, do not paraphrase by default) |
| Derive missing Q4 numbers, a segment remainder, or per-unit economics (ASP, ARPU, AUV, take rate) | `derive-implied-metric/derive-implied-metric.md` |
| Split annual forecasts into quarterly estimates / seasonality patterns | `analyze-seasonality/analyze-seasonality.md` |
| Produce an Excel workbook (.xlsx) from deepKPI data | `format-deepkpi-for-excel/format-deepkpi-for-excel.md` |
| REST API calls (OpenClaw / env-var fallback only) | `deepkpi-api/deepkpi-api.md` |
| Pressure-test a sell-side / analyst report against SEC filing data (HTML report, Chart.js, provenance links) | `analyst-report-pressure-test/analyst-report-pressure-test.md` |

**Default entry point:** Start with `retrieve-kpi-data/retrieve-kpi-data.md`
for almost every request. It orchestrates the full retrieval workflow and
references the other docs as needed (e.g. it will direct you to
`derive-implied-metric` for Q4 gaps and to `format-deepkpi-for-excel` for
Excel output).

## Sub-skill summary

**`deepkpi-api`** — Raw REST access to deepKPI endpoints:
`query_company_id`, `list_kpis`, `search_kpis`, `company_summary_search`,
`get_company_summary`, `get_company_segments`, `list_sec_filing_markdowns`, `get_sec_filing_markdown`. **OpenClaw / env-var fallback only** — in Claude, use
the native MCP tools instead.

**`retrieve-kpi-data`** — The primary data-pull workflow. Covers company ID
resolution, KPI discovery, search strategy, gap handling (including Q4
derivation), provenance rules, in-chat table layout, and the mandatory
post-pull Excel offer.

**`derive-implied-metric`** — Compute metrics that deepKPI doesn't report
directly from data that IS reported: Q4 = FY − (Q1+Q2+Q3), missing segment = total − known segments,
per-unit economics (revenue per store, ARPU, ASP), take rates, penetration
rates, and geographic mix percentages.

**`analyze-seasonality`** — Compute each quarter's typical share of the full
fiscal year from 2–3 years of actuals, then apply those ratios to split an
annual projection into quarterly estimates.

**`format-deepkpi-for-excel`** — Canonical layout and styling spec for any
.xlsx export built from deepKPI data: wide layout with periods as columns
(annual block → blank column → quarterly block), Calibri font, green input
cells, clickable hyperlinks in cells, numeric date headers, freeze panes,
column grouping, and no redundant Source rows.

**`analyst-report-pressure-test`** — End-to-end workflow for uploaded analyst PDFs:
extract 4–6 claims, pull granular deepKPI metrics per claim, build paired
"supports" / "complicates" evidence with mandatory provenance hyperlinks, and
emit a Revelata-branded interactive HTML report (`references/html-template.md`,
`references/chart-patterns.md`). **Always** read `retrieve-kpi-data` first for
MCP/REST mechanics; use `derive-implied-metric` when filling Q4 or segment gaps.
