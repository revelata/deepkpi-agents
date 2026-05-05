---
name: custom-deepkpi-skill
description: >
  Starter template for automating a financial workflow with data sourced from
  deepKPI. Use as a copy-paste base for specific steps in your agentic workflow,
  and your agent will inherit the data retrieval, metric derivation, and formatting
  capabilities of our other skills. Trigger when the user asks for a "custom deepKPI
  skill", template workflow, or hello-world deepKPI example. Does not replace those
  skills, and instead composes with them.
---

# custom-deepkpi-skill

This is a **stub skill**: minimal behavior on its own, but it **collects** the
guiding principles the other deepKPI skills share and **points** to them. Fork this
folder into `skills/<your-skill>/`, rename this file to SKILL.md, and edit it for your team —
keeping the cross-links below accurate.

## Relationship to other skills

| Skill | When to use |
|-------|-------------|
| **`kpi`** | Every number from SEC-sourced KPIs; `list_kpis` / `search_kpis`; provenance `[value](url)`; in-chat tables; mandatory Excel offer after data pulls. |
| **`company-summary`** | `get_company_summary` / `get_company_segments` for named companies; `company_summary_search` for "who does X?"; not target-based benchmarking. |
| **`filing`** | SEC filing markdown (full document or excerpts): `list_sec_filing_markdowns` / `get_sec_filing_markdown`; blockquotes for quotes; not for structured KPI series. |
| **`implied-metric`** | Implied metrics (Q4, segment remainders, per-unit, etc.); **imputed values in the same row** as the series, not a spare line item; flow vs stock. |
| **`seasonality`** | Seasonal ratios, quarterly splits from annuals; same provenance and Excel rules. |
| **`pressure-test`** | Pressure-test analyst PDFs vs. SEC KPIs; HTML + Chart.js output; mandatory draft HTML QA (`references/double-check.md`) before delivery. |
| **`benchmark`** | Operational peer / comp discovery via deepKPI semantic search; KPI fingerprint alignment; segment sub-benchmarks; HTML + Excel output. |
| **`ideas`** | Idea-generation onramp — interactive interview, screen, and deep-dive when the user has no specific company or thesis. |

Shared content under `../_common/` is referenced by every skill above:

| Reference | Purpose |
|-----------|---------|
| **`../_common/data-source-rules.md`** | What deepKPI is; runtime routing (MCP-capable vs non-MCP); canonical inventory of deepKPI operations. |
| **`../_common/connection-failure.md`** | Hard-stop rule when deepKPI access fails — STOP and ask before falling back. |
| **`../_common/revelata-excel-styling-rules.md`** | Canonical `.xlsx` layout, styling, formulas, hyperlinks — apply whenever building a spreadsheet from deepKPI data. |
| **`../_common/deepkpi-api.md`** | REST API reference for OpenClaw / non-MCP runtimes. |

**Compose:** Use `kpi` for any task that needs figures; `company-summary` for what
companies do, segment/geo breakdowns, thematic lists; `filing` for full filing
markdown / "what did they say" / quotes. Add `implied-metric` when something is
computed, `seasonality` for seasonal work, and follow
`../_common/revelata-excel-styling-rules.md` whenever you build a spreadsheet.

## Shared rules (do not drop when customizing)

- **deepKPI is the source of truth** for reported numbers — no training-data guesses.
- **Provenance:** `[value](exact-url)`; copy URLs exactly as the API returns; never invent links.
- **Connection failures:** follow `../_common/connection-failure.md` — STOP and ask before falling back to other sources.
- **Imputation / Q4:** fill **gaps in the same row** as the quarterly series; Excel formula in the period column — **not** a separate "Q4 (derived)" row for the same stream.
- **Excel:** derived cells are **live `=` formulas**; deepKPI inputs green styling per `../_common/revelata-excel-styling-rules.md`; no redundant Source rows — hyperlinks on values.
- **Revelata / deepKPI access:** account and credentials per your environment ([revelata.com](https://www.revelata.com)).

## Hello world (stub behavior)

When this skill is invoked **without** a heavier task, respond briefly to confirm the
pipeline:

1. Say that you will use **deepKPI** (via MCP or REST) for any real figures.
2. List which of the skills above would apply to a typical "pull → derive → export" request.
3. Print a one-line **hello** acknowledging **`custom-deepkpi-skill`** is loaded — e.g.
   `deepKPI custom skill: ready (stub).`

**Example assistant reply shape:**

> **deepKPI custom skill: ready (stub).**
> For real work I'll follow `kpi` for pulls, add `implied-metric` / `seasonality` when needed, and apply `../_common/revelata-excel-styling-rules.md` for files. What company and metrics should we pull?

That is the full "hello world"; expand this file with your own SOPs, glossaries, or
review checklists as needed.
