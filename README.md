# deepkpi-agents

Example agent skills for automating finance workflows. These skills provide basic support for working with deepKPI data, as well as foundational examples for automating common analysis tasks. Every deepKPI datapoint comes with a link back to its original source. These hyperlinks are carried through any subsequent tool call to provide 1-click auditability. 

The skills in this repo source data from deepKPI by [Revelata](https://www.revelata.com). The underlying datasets capture comprehensive KPI data about public companies extracted from narrative and tabular text in their filings; these are refreshed nightly to capture fresh disclosures. Data access requires a [free account](https://www.revelata.com/signup). Authentication is provided via OAuth for our MCP server (preferred for Claude and Cowork) or API Key (preferred for OpenClaw); once authenticated, these skills allow you to pull KPI data into your agent's context automatically. . 

Integration instructions for Claude Cowork, OpenClaw, or generic API access and API keys are available [here](https://www.revelata.com/ai-credits).

## Skills

| Skill | Role |
|-------------------------|-----------------------------------------|
| `retrieve-kpi-data` | Pulls KPI data from public filings into agent and chat workflows, while also providing options to export into Excel|
| `derive-implied-metric` | Computes derived metrics from reported data. All calculations are implemented with transparent formulas and provenance links for operands. Example uses include Q4 imputation, segment remainders, per-unit metrics, AUV, Rule of 40, etc. |
| `analyze-seasonality` | Computes and analyzes quarterly splits from annual forecasts and builds an Excel workbook with the results |
| `format-deepkpi-for-excel` | Canonical `.xlsx` layout, styling, formulas, hyperlinks. Edit or override this skill to implement your own formatting conventions. |
| `custom-deepkpi-skill` | **Stub / template**—summarizes shared rules, links to the four skills above, and a minimal “hello world” response. Use this as a stub to implement your own skills that work with deepKPI data |

Each skill folder contains a **`SKILL.md`** (YAML frontmatter + body).

## Installation

The `package-skills.sh` script will guide you through skill installation for **Claude Desktop**, **Claude.ai (web)**, or **OpenClaw**. Note that installation does not by default install the 
stubbed custom agent skill. For manual installation, please refer to the documentation for skill installation in your environment. 

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
