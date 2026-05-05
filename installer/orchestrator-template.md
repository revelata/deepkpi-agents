---
name: revelata-deepkpi
description: >
  Financial and operational KPI research for US public companies using Revelata
  deepKPI. Pulls SEC metrics (10-K/10-Q/8-K): segments, unit KPIs (stores, comps,
  ARPU, users), income statement, balance sheet, cash flow; full SEC filing
  markdown and verbatim quotes; implied Q4 and per-unit derivations, seasonality
  splits, .xlsx export. Pressure-tests sell-side analyst PDFs against SEC filing
  data with interactive HTML output. Operational peer / comp benchmarking. Idea
  generation for "what should I invest in?" when the user has no specific company
  in mind. Company summaries and segment / geography discovery. Triggers: "pull
  data", historicals, "find the KPI", seasonality, .xlsx, filing excerpts, "what
  did they say", pressure-test, peers, comps, benchmark, similar companies, new
  ideas, what does X do, who operates in. OpenClaw: see `_common/deepkpi-api.md`.
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

# Revelata deepKPI

Query structured KPIs, SEC filing text, and company summaries for US public
companies, powered by [Revelata](https://www.revelata.com).

This skill is a controller for a bundle of focused workflows (KPI pulls, filing
markdown, segment discovery, seasonality, derived metrics, peer benchmarking,
analyst-report pressure-testing, idea generation). Each workflow lives in its
own reference doc; load the relevant doc(s) before doing any work.

## Data access

See `_common/data-source-rules.md` — single source of truth for how to call
deepKPI from MCP-capable runtimes (Claude, ChatGPT) vs non-MCP runtimes
(OpenClaw). Every workflow below depends on this.

## Hard stop on connection failures

See `_common/connection-failure.md`. If deepKPI access fails, STOP and ask the
user before falling back to other sources. This rule applies to **every**
workflow in the bundle.

## Workflow routing

**Read the relevant reference doc(s) before doing any work.** Multiple docs may
apply to a single request — load all that fit.

| User need | File to read |
|-----------|--------------|
| No specific company or thesis — "what should I invest in?", "what stock should I buy?", **new ideas**, **interesting companies**, boredom / open exploration | `ideas/ideas.md` — interactive funnel + `company_summary_search` screen; then `kpi/kpi.md` for deep pulls |
| Pull historical KPIs / financials from deepKPI | `kpi/kpi.md` |
| **What a company does**, **segments / geographies**, or **thematic** "who does X?" lists | `company-summary/company-summary.md` — named company: `get_company_summary` / `get_company_segments`; discovery: `company_summary_search` then hydrate as needed |
| Pull **full filing markdown** into chat, **verbatim SEC text**, quotes, MD&A / risk-factor language, or "what did they say" | `filing/filing.md` — **before any web/SEC.gov**: `list_sec_filing_markdowns` (free) → `get_sec_filing_markdown` (10 credits). Return full markdown when they want the document; blockquoted excerpts for quote-style asks; no paraphrase as quotes |
| Derive missing Q4 numbers, a segment remainder, or per-unit economics (ASP, ARPU, AUV, take rate) | `implied-metric/implied-metric.md` |
| Split annual forecasts into quarterly estimates / seasonality patterns | `seasonality/seasonality.md` |
| Produce an Excel workbook (.xlsx) from deepKPI data | Whichever data doc applies (`kpi/kpi.md`, `seasonality/seasonality.md`, etc.); then follow `_common/revelata-excel-styling-rules.md` |
| Pressure-test a sell-side / analyst report against SEC filing data (HTML report, Chart.js, provenance links) | `pressure-test/pressure-test.md` |
| **Peers / comps**, **benchmark** a company, **most similar** public companies, or operational comp sets | `benchmark/benchmark.md` — always read `kpi/kpi.md` first for KPI mechanics |

**Default entry points by intent:**

- For **metrics and modeling feeds**, start with `kpi/kpi.md` (it references
  `implied-metric/implied-metric.md`, `seasonality/seasonality.md`, and
  `_common/revelata-excel-styling-rules.md` as needed).
- For **business description, segment structure, or thematic company lists**, start
  with `company-summary/company-summary.md`.
- For **filing markdown (full or excerpts) and verbatim quotes**, start with
  `filing/filing.md`.

If a request mixes these, read **every** doc that applies.

## Workflow summary

**`kpi/kpi.md`** — Primary workflow for **structured KPIs** (company ID,
`list_kpis` / `search_kpis`, gap handling including Q4 derivation), provenance
rules, in-chat tables, and the mandatory post-pull Excel offer.

**`company-summary/company-summary.md`** — `get_company_summary` (what they do)
and `get_company_segments` (how they break out segments / geos);
`company_summary_search` for **thematic** "who does X?" discovery. Not for KPI
time series.

**`filing/filing.md`** — **SEC filing markdown** in chat: full filing or
excerpts, verbatim quotes, MD&A / risk language. Tools:
`list_sec_filing_markdowns` → `get_sec_filing_markdown`, source hierarchy
(tool-first, not web), blockquote discipline for quote-style asks. Distinct
purpose from KPI time series.

**`implied-metric/implied-metric.md`** — Compute metrics that deepKPI doesn't
report directly from data that IS reported: `Q4 = FY − (Q1+Q2+Q3)`, missing
segment = total − known segments, per-unit economics (revenue per store, ARPU,
ASP), take rates, penetration rates, geographic mix percentages.

**`seasonality/seasonality.md`** — Compute each quarter's typical share of the
full fiscal year from 2–3 years of actuals, then apply those ratios to split an
annual projection into quarterly estimates.

**`pressure-test/pressure-test.md`** — End-to-end workflow for uploaded analyst
PDFs: extract 4–6 claims, pull granular deepKPI metrics per claim, build paired
"supports" / "complicates" evidence with mandatory provenance hyperlinks, and
emit a Revelata-branded interactive HTML report
(`pressure-test/references/html-template.md`,
`pressure-test/references/chart-patterns.md`). After the draft HTML exists, run
the mandatory internal **draft HTML QA** rubric in
`pressure-test/references/double-check.md`, then revise and re-check as needed
before presenting the file. **Always** read `kpi/kpi.md` for KPI mechanics; use
`filing/filing.md` when the test needs verbatim filing passages; use
`company-summary/company-summary.md` for business description / segment
structure / thematic lists when useful; use `implied-metric/implied-metric.md`
when filling Q4 or segment gaps.

**`benchmark/benchmark.md`** — Curated **operational** benchmark sets (not
trading multiples): `company_summary_search` for candidates, KPI fingerprint +
alignment, diff-driven segment sub-benchmarks, chat 1-pager, optional HTML
(`benchmark/references/html-template.md`), Excel via
`_common/revelata-excel-styling-rules.md`. **Always** read `kpi/kpi.md` first.

**`ideas/ideas.md`** — Onramp when the user has **no ticker and no thesis**:
rapid interview (multiple-choice by default), `company_summary_search` for a
10–15 name screen with thesis-matched KPIs, then deep pulls on 1–2 chosen names
per `kpi/kpi.md`. `ideas/references/sector-kpi-map.md` for diagnostic KPI
concepts. **No** default Excel offer. Not for users who already named a company
or a specific metric — use `kpi/kpi.md` instead.
