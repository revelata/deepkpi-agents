# deepkpi-agents

Example agent skills for automating finance workflows. These skills provide basic support for working with deepKPI data, as well as foundational examples for automating steps in a workflow. Every deepKPI datapoint comes with a link back to its original source and those hyperlinks are carried through any subsequent tool calls that use these skills.

These skills source data from deepKPI by [Revelata](https://www.revelata.com), e.g. for public US companies. Data access requires a [free account](https://www.revelata.com/signup) and authentication via OAuth or API Key to load data into your agent's context. We support MCP access with OAuth authentication (preferred for Claude and Claude Cowork) and API access with an API key (preferred for OpenClaw). 

Integration instructions for Claude Cowork, OpenClaw, or generic API access and API keys are available [here](https://www.revelata.com/ai-credits).

## Skills

| Skill | Role |
|-------------------------|-----------------------------------------|
| `retrieve-kpi-data` | Pulls KPI data from public filings into agent and chat workflows, while also providing options to export into Excel financial models |
| `derive-implied-metric` | Computes derived metrics based on reported data with transparent formulas and source-data links. Example uses include Q4 imputation, segment remainders, per-unit metrics, AUV, Rule of 40, etc. |
| `analyze-seasonality` | Computes and analyzes seasonal ratios, quarterly splits from annual forecasts, and builds an Excel workbook with the results |
| `format-deepkpi-for-excel` | Canonical `.xlsx` layout, styling, formulas, hyperlinks. Edit or override this skill to implement your own formatting conventions. |

Each skill folder contains a **`SKILL.md`** (YAML frontmatter + body).

## Installation

The `package-skills.sh` script will guide you through skill installation for **Claude Desktop**, **Claude.ai (web)**, or **OpenClaw**. For manual installation, please refer to the documentation for skill installation in your environment. 

```bash
chmod +x package-skills.sh
./package-skills.sh
```

- **Claude Desktop / Claude.ai** — builds one ZIP per skill (folder-at-root layout) into `~/Desktop/deepkpi-skills` or `~/Downloads/deepkpi-skills`, then prints upload steps.

- **OpenClaw** — copies each skill directory into **`~/.openclaw/workspace/skills/`**. Override with `OPENCLAW_SKILLS_ROOT` if needed.


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
