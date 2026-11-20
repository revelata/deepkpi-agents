# Data source rules — deepKPI access

**deepKPI** is Revelata's data service for US public companies, sourcing data from SEC filings (10-K / 10-Q / 8-K). 
The operations available are listed below. Every numeric figure or filing excerpt produced 
by skills in this bundle must trace back to a deepKPI call.

deepKPI is reached through the **Revelata MCP server** (`https://deepkpi-mcp.revelata.com/mcp`),
which the plugin declares and the user signs in to once. Call its tools directly; no API
key is involved. If the tools are missing or a call fails, follow `connection-failure.md`
(sibling file in this folder) rather than any other source.

## Canonical inventory of deepKPI operations

- `query_company_id` — resolve official registrant name → SEC CIK
- `list_kpis` — enumerate every KPI deepKPI has for a company
- `search_kpis` — retrieve specific KPI time series
- `company_summary_search` — thematic / activity-based discovery across summaries
- `get_company_summary` — narrative business description from latest 10-K
- `get_company_segments` — segment / geography structure from latest 10-K
- `list_sec_filing_markdowns` — list available filings for a company
- `get_sec_filing_markdown` — retrieve full filing markdown
