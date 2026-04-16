---
name: custom-deepkpi-skill
description: >
  Starter template for automating a financial workflow with data sourced from 
  deepKPI. Use as a copy-paste base for specific steps in your agentic workflow.
  and your agent will inherit the data retrieval, metric derivation, and formatting
  capabilities of our other skills. Trigger when the user asks for a "custom deepKPI 
  skill", template workflow, or hello-world deepKPI example. Does not replace those 
  skills, and instead compose with them.
---

# custom-deepkpi-skill

This is a **stub skill**: minimal behavior on its own, but it **collects** the
guiding principles the other deepKPI skills share and **points** to them. Fork this
folder, rename it, and edit **`SKILL.md`** for your team—keep the cross-links below
accurate.

## Relationship to other skills

| Skill | When to use |
|-------|-------------|
| **`deepkpi-api`** | REST API access layer. Required for OpenClaw; env-var fallback for Claude when MCP is unavailable. Other skills call through this for data access. |
| **`retrieve-kpi-data`** | Every number from SEC-sourced KPIs; `list_kpis` / `search_kpis`; provenance `[value](url)`; in-chat tables; mandatory Excel offer after data pulls. |
| **`company-summary-segments`** | `get_company_summary` / `get_company_segments` for named companies; `company_summary_search` for “who does X?”; not target-based benchmarking. |
| **`retrieve-sec-filing`** | SEC filing markdown (full document or excerpts): `list_sec_filing_markdowns` / `get_sec_filing_markdown`; blockquotes for quotes; not for structured KPI series. |
| **`derive-implied-metric`** | Implied metrics (Q4, segment remainders, per-unit, etc.); **imputed values in the same row** as the series, not a spare line item; flow vs stock. |
| **`format-deepkpi-for-excel`** | `.xlsx` / CSV layout: PLNT-style wide grid, **C1** title, formulas not hardcoded, hyperlinks on value cells, **`format-deepkpi-for-excel`** checklist. |
| **`analyze-seasonality`** | Seasonal ratios, quarterly splits from annuals; same provenance and Excel rules. |
| **`analyst-report-pressure-test`** | Pressure-test analyst PDFs vs. SEC KPIs; HTML + Chart.js output; see `analyst-report-pressure-test/analyst-report-pressure-test.md`. |

**Compose:** **`deepkpi-api`** provides data access (OpenClaw) or use MCP (Claude).
Run **`retrieve-kpi-data`** before anything that needs figures; use
**`company-summary-segments`** for what companies do, segment/geo breakdowns, thematic lists; use
**`retrieve-sec-filing`** for full filing markdown / “what did they say” / quotes. Add
**`derive-implied-metric`** when something is computed, **`analyze-seasonality`** for
seasonal work, and **`format-deepkpi-for-excel`** whenever you build a spreadsheet file.

## Shared rules (do not drop when customizing)

- **deepKPI is the source of truth** for reported numbers—no training-data guesses.
- **Provenance:** `[value](exact-url)`; copy URLs exactly as the API returns; never invent links.
- **Imputation / Q4:** fill **gaps in the same row** as the quarterly series; Excel formula in the period column—**not** a separate “Q4 (derived)” row for the same stream.
- **Excel:** derived cells are **live `=` formulas**; deepKPI inputs green styling per **`format-deepkpi-for-excel`**; no redundant Source rows—hyperlinks on values.
- **Revelata / deepKPI access:** account and credentials per your environment ([revelata.com](https://www.revelata.com)).

## Hello world (stub behavior)

When this skill is invoked **without** a heavier task, respond briefly to confirm the
pipeline:

1. Say that you will use **deepKPI** (via MCP or API) for any real figures.
2. List which of the four skills above would apply to a typical “pull → derive → export” request.
3. Print a one-line **hello** acknowledging **`custom-deepkpi-skill`** is loaded—e.g.
   `deepKPI custom skill: ready (stub).`

**Example assistant reply shape:**

> **deepKPI custom skill: ready (stub).**  
> For real work I’ll follow **`retrieve-kpi-data`** for pulls, add **`derive-implied-metric`** / **`analyze-seasonality`** when needed, and **`format-deepkpi-for-excel`** for files. What company and metrics should we pull?

That is the full “hello world”; expand this file with your own SOPs, glossaries, or
review checklists as needed.
