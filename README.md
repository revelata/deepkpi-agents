# deepkpi-agents: Revelata Agentic Skills Library

**Open-source agentic skills for equity research and analysis, powered by [Revelata deepKPI](https://www.revelata.com).** Pull structured KPI time series, full SEC filing markdown (10-K, 10-Q, 8-K), 10-K-derived company summaries, and more — directly into Claude, ChatGPT, or OpenClaw.

The skills cover a growing set of fundamental workflows for equity research: KPI lookup, filing-text retrieval, derived metric calculation, peer benchmarking, seasonality analysis, and analyst-report pressure-testing.

Data access requires a [free Revelata account](https://www.revelata.com/signup?product_id=0). Every data point returned by our deepKPI service has a clickable hyperlink back to its source sentence in the original filing. Provenance is preserved through every downstream tool call, so analyses are **1-click auditable** — no opaque numbers, no hand-waved citations.

Authentication is via **OAuth** (Claude, ChatGPT) or **API key** (OpenClaw). For manual MCP server setup, endpoint URL, and the underlying tool reference, see **[MCP.md](./MCP.md)**.

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
| `ideas` | Guides users without a specific company or thesis through idea generation — interactive interview, screen, and deep-dive. |
| `revelata` | Orchestrates complex multi-step research that crosses multiple workflows. |

## Installation

We integrate into the following agentic frameworks:

### Claude Desktop Cowork & Code

Install the plugin via our third-party marketplace:

1. In Cowork, open **Customize → + → Create Plugin**
2. Add marketplace: **`revelata/deepkpi-agents`**
3. Install the **`revelata`** plugin

**Known Cowork issue — manual MCP authentication required.** A Cowork issue prevents authentication within Cowork chat. To finish setup:

4. Open **Customize → Revelata → Connectors**
5. Choose the **Revelata** connector and click **Install** (or **Connect**, depending on your version of Cowork).
6. Complete the OAuth flow when prompted

> **Important:** A Cowork plugin install propagates to **Claude Code** automatically. The reverse is **not** true. If you want both supported, install via Cowork.

### Claude.ai (web) or Claude Desktop Chat

1. Download the latest [ZIP package](https://github.com/revelata/deepkpi-agents/releases/latest/download/deepkpi-skills.zip).
2. Enable **Code execution and file creation** in Claude.ai → Settings → Capabilities
3. Upload the ZIP via **Customize → Skills**
4. Adding the deepKPI MCP connector (see **[MCP.md](./MCP.md)**)

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

**Alternative (skills ZIP + MCP App):** Download the latest [ZIP package](https://github.com/revelata/deepkpi-agents/releases/latest/download/deepkpi-skills.zip), enable **Developer Mode**, upload the ZIP as a custom skill, and add the deepKPI MCP server as an App at the URL above.

### OpenClaw

OpenClaw uses the deepKPI REST API (no MCP). Get an API key at [revelata.com/ai-credits](https://www.revelata.com/ai-credits), then:

```bash
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash -s openclaw
```

The installer prompts for `DEEPKPI_API_KEY` and configures `~/.openclaw/openclaw.json`.

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
