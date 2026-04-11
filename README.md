# deepkpi-agents

Example agent skills for automating finance workflows. These skills provide basic support for working with deepKPI data, as well as foundational examples for automating common analysis tasks. Every deepKPI datapoint comes with a link back to its original source. These hyperlinks are carried through any subsequent tool call to provide 1-click auditability. 

The skills in this repo source data from deepKPI by [Revelata](https://www.revelata.com). The underlying datasets capture comprehensive KPI data about public companies extracted from narrative text and tables in their filings; these are refreshed nightly to capture fresh disclosures. Data access requires a [free account](https://www.revelata.com/signup?product_id=0). Authentication is provided via OAuth for our MCP server (preferred for Claude and Cowork) or API Key (preferred for OpenClaw); once authenticated, these skills allow you to pull KPI data into your agent's context automatically.

Integration instructions for Claude Cowork, OpenClaw, or generic API access and API keys are available [here](https://www.revelata.com/ai-credits).

**MCP (Claude connector):** See **[MCP.md](./MCP.md)** for setup, endpoint URL, and troubleshooting. OpenClaw uses the REST API — see **`deepkpi-api/`** in this repo.

## Layout

- **Root `SKILL.md`** — Agent-facing skill package (**`revelata-deepkpi`**): YAML frontmatter + router doc.
- **Subfolders** — Reference markdown used by that skill (e.g. `retrieve-kpi-data/retrieve-kpi-data.md`, `deepkpi-api/deepkpi-api.md`). 

The installer builds one directory, **`revelata-deepkpi/`** (root `SKILL.md` + those folders), and either copies it for **OpenClaw** or zips it for **Claude** as a **single** deliverable.

## Modules (inside the bundle)

| Folder | Role |
|---|---|
| `retrieve-kpi-data` | Pulls KPI data from public filings into agent and chat workflows, while also providing options to export into Excel financial models. Uses MCP (Claude) or `deepkpi-api` (OpenClaw) for data access. |
| `derive-implied-metric` | Computes derived metrics based on reported data with transparent formulas and source-data links. Example uses include Q4 imputation, segment remainders, per-unit metrics, AUV, Rule of 40, etc. |
| `analyze-seasonality` | Computes and analyzes seasonal ratios, quarterly splits from annual forecasts, and builds an Excel workbook with the results |
| `analyst-report-stress-test` | Stress-tests sell-side analyst reports by mapping their claims to supporting and countervailing evidence from SEC filings.|
| `format-deepkpi-for-excel` | Canonical `.xlsx` layout, styling, formulas, hyperlinks. Edit or override this skill to implement your own formatting conventions. |
| `deepkpi-api` | REST API access to deepKPI endpoints (company lookup, KPI discovery, KPI search). Required for OpenClaw; env-var fallback for Claude when MCP is unavailable. |
| `custom-deepkpi-skill` | **Stub / template** — summarizes shared rules, links to the skills above, and a minimal "hello world" response. Fork and customize for your org. |

## Installation

### Quick install (any platform)

```bash
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash
```

The installer prompts you to choose **Claude Desktop**, **Claude.ai**, or
**OpenClaw**, then stages **`revelata-deepkpi/`** from this repo (or downloads it)
and walks you through setup.

- **Claude (Desktop or web):** creates **`revelata-deepkpi.zip`** — upload that as a custom skill to access all of the functionality.
- **OpenClaw:** installs to **`~/.openclaw/skills/revelata-deepkpi/`** and configures **`skills.entries.revelata-deepkpi`** with `DEEPKPI_API_KEY` (skill **`name:`** in root `SKILL.md` matches that key).

To skip the prompt and go straight to a specific platform:

**OpenClaw**
```bash
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash -s openclaw
```

**Claude Desktop**
```bash
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash -s claude-desktop
```

**Claude.ai (web)**
```bash
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash -s claude-web
```

### From a local clone

```bash
git clone https://github.com/revelata/deepkpi-agents.git
cd deepkpi-agents
./install.sh
```

Same interactive flow, but uses local files instead of downloading from GitHub.

### Notes

- **`custom-deepkpi-skill`** is not bundled by the installer — clone the repo to copy it into your bundle if you want it.
- Override the OpenClaw skills directory with `OPENCLAW_SKILLS_ROOT` if needed (the skill still installs as `revelata-deepkpi` inside that root).


## Examples

Once installed, ask your agent to do your work for you: 

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
Stress test this analyst report on Clorox [attach PDF] — use SEC data and give me the HTML report
```
