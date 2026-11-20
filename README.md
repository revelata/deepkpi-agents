# deepkpi-agents: Revelata Agentic Skills Library

**Open-source agentic skills for equity research and analysis, powered by [Revelata deepKPI](https://www.revelata.com), our Stable Context Service for fundamental equity research.** Pull structured, hard-to-find KPI time series; SEC filing markdown (10-K, 10-Q, 8-K); comprehensive company summaries; and more — directly into Claude or ChatGPT.  Our deepKPI Stable Context Service pre-structures, pre-interprets, pre-verifies, and cites every fact it returns, enabling your AI to operate on a stable, authoritative substrate. 

The skills cover a growing set of fundamental workflows for equity research: KPI lookup, filing-text retrieval, Excel operating model generation, earnings call preparation, derived metric calculation, peer benchmarking, seasonality analysis, and analyst report pressure testing.

Data access requires a [free Revelata account](https://www.revelata.com/signup?product_id=0). Every data point returned by our deepKPI service has a clickable hyperlink back to its source sentence in the original filing. Provenance is preserved through every downstream tool call, so analyses are **1-click auditable** — no opaque numbers, no hand-waved citations.

Authentication is via **OAuth** with your Revelata account. For manual MCP server setup, endpoint URL, and the underlying tool reference, see **[MCP.md](./MCP.md)**.

## Skills

| Skill | What it does |
|---|---|
| `kpi` | Pulls structured KPI time series for US public companies from SEC filings; supports Excel export. |
| `company-summary` | Describes a company's business and segment / geography structure; supports thematic "who does X?" discovery. |
| `filing` | Pulls clean SEC filing markdown into chat; extracts verbatim quotes from MD&A, risk factors, footnotes. |
| `seasonality` | Computes seasonal quarterly ratios from historical actuals; splits annual forecasts into quarterly estimates; outputs an Excel workbook. |
| `implied-metric` | Derives metrics that aren't directly reported — Q4 from FY−(Q1+Q2+Q3), segment remainders, per-unit economics (ARPU, ASP, AUV), take rates. |
| `pressure-test` | Pressure-tests analyst reports against SEC filing data; outputs an interactive HTML report with claim-by-claim evidence and provenance hyperlinks. |
| `benchmark` | Performs operational peer / comp discovery via deepKPI semantic search; aligns KPI fingerprints, generates segment sub-benchmarks, supports HTML and Excel output. |
| `tearsheet` | Outputs a one-page pre-earnings tearsheet — quarterly financials, revenue-driver KPIs, and bull / bear tensions; outputs an HTML report. |
| `operating-model` | Builds a full operating model in Excel from deepKPI: scaffold plus revenue, costs, consolidated financials, depreciation, and net working capital sections. |
| `ideas` | Guides users without a specific company or thesis through idea generation — interactive interview, screen, and deep-dive. |
| `revelata` | Orchestrates complex multi-step research that crosses multiple workflows. |

## Installation

We integrate into the following agentic frameworks:

### Claude Desktop & Claude.ai

Install the plugin via our third-party marketplace:

1. In Claude Desktop, open **Customize → Plugins → Add Marketplace**
2. **Add from a repository**, and enter **`revelata/deepkpi-agents`**
3. **Turn off** "automatic syncing" and then click **Sync**
4. Then **Add** the **`Revelata`** plugin

**Connect the deepKPI connector.** Claude installs a plugin's connector separately from the plugin, so connect it once to finish setup:

5. Open the **[Revelata deepKPI connector](https://claude.ai/customize/connectors/id/revelata-deepkpi)** and click **Connect to Claude**
6. Sign in with your Revelata account, or [create a free one](https://www.revelata.com/signup?product_id=0)

If you skip this step, the skills send you to sign in the first time you use them.

### Claude Code CLI

From a terminal:

```bash
claude plugin marketplace add revelata/deepkpi-agents
claude plugin install revelata@revelata-marketplace
```

The MCP OAuth flow runs in your browser on first use.

### ChatGPT / Codex (desktop Plugins)

Install as a plugin from the Revelata marketplace (skills + deepKPI MCP together):

1. In **ChatGPT desktop**, open **Plugins**.
2. **Add a marketplace** and use the GitHub source: **`revelata/deepkpi-agents`**.
3. Install the **Revelata deepKPI** (`revelata`) plugin from that marketplace.
4. Complete **OAuth** when prompted (sign in with your Revelata account).

Requires a [free Revelata account](https://www.revelata.com/signup?product_id=0). The MCP endpoint is `https://deepkpi-mcp.revelata.com/mcp`.

## Examples

Once installed, ask your agent to do your work:

```
Pull membership data for Planet Fitness and create an Excel workbook
```

```
Analyze quarterly sales for Darden restaurants. Impute Q4 sales if necessary.
```

```
Model seasonality in Monster Energy's sales by brand
```

```
Pull the store count rolls for Planet Fitness into Excel
```

```
Pressure test this analyst report on Clorox [attach PDF] — use SEC data and give me the HTML report
```

In Claude Cowork or Claude Code, you can also invoke a specific skill directly with a slash command:

```
/revelata:kpi PLNT number of members
```

```
/revelata:pressure-test [attach PDF]
```
