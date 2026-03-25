# deepkpi-agents

Example agent skills for automating finance workflows. These skills provide basic support for working with deepKPI data, as well as foundational examples for automating steps in a workflow. Every deepKPI datapoint comes with a link back to its original source and those hyperlinks are carried through any subsequent tool calls that use these skills.

These skills source data from deepKPI by [Revelata](https://www.revelata.com), e.g. for public US companies. Data access requires a [free account](https://www.revelata.com/signup) and authentication via OAuth or API Key to load data into your agent's context. We support MCP access with OAuth authentication (preferred for Claude and Claude Cowork) and API access with an API key (preferred for OpenClaw). 

Integration instructions for Claude Cowork, OpenClaw, or generic API access and API keys are available [here](https://www.revelata.com/ai-credits).

## Skills

| Skill | Role |
|---|---|
| `deepkpi-api` | REST API access to deepKPI endpoints (company lookup, KPI discovery, KPI search). Required for OpenClaw; env-var fallback for Claude when MCP is unavailable. |
| `retrieve-kpi-data` | Pulls KPI data from public filings into agent and chat workflows, while also providing options to export into Excel financial models. Uses MCP (Claude) or `deepkpi-api` (OpenClaw) for data access. |
| `derive-implied-metric` | Computes derived metrics based on reported data with transparent formulas and source-data links. Example uses include Q4 imputation, segment remainders, per-unit metrics, AUV, Rule of 40, etc. |
| `analyze-seasonality` | Computes and analyzes seasonal ratios, quarterly splits from annual forecasts, and builds an Excel workbook with the results |
| `format-deepkpi-for-excel` | Canonical `.xlsx` layout, styling, formulas, hyperlinks. Edit or override this skill to implement your own formatting conventions. |
| `custom-deepkpi-skill` | **Stub / template** — summarizes shared rules, links to the skills above, and a minimal "hello world" response. Fork and customize for your org. |

Each skill folder contains a **`SKILL.md`** (YAML frontmatter + body).

## Installation

### Quick install (any platform)

```bash
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash
```

The installer prompts you to choose **Claude Desktop**, **Claude.ai**, or
**OpenClaw**, then downloads the skills and walks you through setup.

To skip the prompt and go straight to a specific platform:

```bash
# OpenClaw
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash -s openclaw

# Claude Desktop
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash -s claude-desktop

# Claude.ai (web)
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

- The stub template (`custom-deepkpi-skill`) is not installed by default — clone
  the repo to access it.
- Override the OpenClaw skills directory with `OPENCLAW_SKILLS_ROOT` if needed.


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
