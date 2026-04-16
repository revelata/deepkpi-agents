# deepKPI MCP — documentation

Support and troubleshooting for **Claude Desktop**, **Claude.ai**, and similar clients that use Revelata’s **remote MCP server** (Streamable HTTP).

**OpenClaw** does not use this MCP URL for deepKPI — it uses the **REST API** and **`DEEPKPI_API_KEY`**. See [`deepkpi-api/deepkpi-api.md`](./deepkpi-api/deepkpi-api.md). Hosted API docs: [deepkpi-api.revelata.com/docs](https://deepkpi-api.revelata.com/docs).

---

## Basic setup (Claude)

1. **Create a free Revelata account** — [Sign up](https://www.revelata.com/signup?product_id=0). 

3. **Copy the following MCP server URL** 
```https://deepkpi-mcp.revelata.com/mcp```

4. **Allow required capabilities** — In Claude, enable **Code execution and file creation** by navigating to **Settings → Capabilities** on Claude.ai. For other clients, consult your documentation for connecting to MCP servers. 

5. **Add a custom connector** —  
   **Claude Desktop:** **Settings → Connectors → Add custom connector**.  
   **Claude.ai (web):** Use **Settings → Customize**.

6. **Configure the connector** — Enter **Revelata deepKPI** under name and paste the **server URL** from step 3 exactly as copied. Click connect. 

7. **Complete OAuth** — Begin a chat or task. When prompted to authenticate, sign in with your Revelata account in the browser. 

8. **Begin using deepKPI data in your analyses!**

---

## MCP tools

The server exposes eight tools:

### `query_company_id`

Looks up a company’s numeric identifier from a **free-text name**. Returns matches you can use as **`company_id`** in the other tools. For US companies this identifier is the **SEC CIK**.

**Parameters:** `company_name` (string), `num_of_res` (optional, default `5`) — max number of matches to return.

**Credits:** None — free.

---

### `list_kpis`

Lists **all KPIs** available for a given company, **organized by category**. Use this as the **first step** before searching: the returned KPI names help you write **precise** queries for **`search_kpis`**, which saves credits.

**Parameters:** `company_id` (string), `source` (optional) — omit to include all filing types, or set to `10-K`, `10-Q`, or `8-K` to filter.

**Credits:** None — free.

---

### `search_kpis`

**Semantic search** over KPIs for one company — finds items most relevant to your **natural-language `query`**. Each result costs **one credit** (cap **15** results per call; default **3** — increase only when needed). Best practice: run **`list_kpis`** first, then search using **exact KPI names** from that list when possible instead of requesting many broad results.

**Parameters:** `company_id` (string), `query` (string), `num_of_res` (optional, default `3`), `source` (optional) — same filing-type filter as **`list_kpis`**; omit to search across all filing types.

**Credits:** Charged per result — check your balance or add credits at [AI credits](https://www.revelata.com/ai-credits).

---

### `company_summary_search`

**Semantic search** over **all companies’ 10-K-derived summaries** — returns the best-matching tickers/CIKs for a natural-language `query` (**thematic** discovery: “companies that …”, “who operates in …”). **Not** the tool for “most similar to **Target Co.**” benchmarking (separate skill). **1 credit per company** returned (cap **15** via `top_k_companies`); empty results cost nothing.

**Parameters:** `query` (string), `top_k_companies` (optional, default `10`, max `15`).

**Credits:** **1** per company in the response — check your balance at [AI credits](https://www.revelata.com/ai-credits).

**Agent workflow:** **`company-summary-segments/company-summary-segments.md`** — use for **thematic lists**; for a **named** company’s profile use **`get_company_summary`** / **`get_company_segments`** first (Workflow A in that doc).

---

### `get_company_summary`

Returns a **narrative company summary** (derived from the company’s latest 10-K). Primary source for **“what does this company do?”** — not for pulling numeric KPI time series (use **`search_kpis`** for that). May follow **`company_summary_search`** when a thematic hit needs full prose.

**Parameters:** `company_id` (string) — for US companies, the **SEC CIK** (same as for **`list_kpis`** / **`search_kpis`**). If you only have a name, call **`query_company_id`** first.

**Credits:** **3** per successful call.

**Agent workflow:** **`company-summary-segments/company-summary-segments.md`**.

---

### `get_company_segments`

Returns a **structured segment breakdown** (derived from the company’s latest 10-K). Use for high-level segment mix and narrative structure; for detailed segment **metrics** over time, prefer **`list_kpis`** + **`search_kpis`**.

**Parameters:** `company_id` (string) — SEC CIK for US companies; resolve with **`query_company_id`** if needed.

**Credits:** **3** per successful call.

**Agent workflow:** **`company-summary-segments/company-summary-segments.md`**.

---

### `list_sec_filing_markdowns`

Lists SEC filings available as markdown for a given **CIK**. Use this to discover valid `acc_no` and `seq_no` values before fetching content. **Agent workflow:** `retrieve-sec-filing/retrieve-sec-filing.md` (tool-first, before web/SEC.gov).

**Parameters:** `cik` (int), `form_type` (optional string, e.g. `10-K`), `start_date` (optional `YYYY-MM-DD`), `end_date` (optional `YYYY-MM-DD`).

**Credits:** None — free.

---

### `get_sec_filing_markdown`

Fetches the markdown content for a specific SEC filing.

**Parameters:** `cik` (int), `acc_no` (string), `seq_no` (optional int, default `1`).

**Credits:** **10** per successful call.

**Critical quoting rule:** When the user asks “what did they say”, “what comments were made”, “exact language”, or similar, you MUST return **verbatim quotes/snippets** from the markdown (with clear snippet boundaries). Do not paraphrase by default. Full rules: **`retrieve-sec-filing/retrieve-sec-filing.md`**.

---

## Authentication issues

| Symptom | What to try |
|---------|-------------|
| Redirect loop or “access denied” | Confirm you’re signed into the expected Revelata account. |
| Connector works but **search** / **summary** / **filing markdown** calls fail | You may be out of **credits**. **`list_kpis`**, **`query_company_id`**, and **`list_sec_filing_markdowns`** are free. **`search_kpis`** uses **1 credit per result**; **`company_summary_search`** uses **1 credit per company** returned; **`get_company_summary`** and **`get_company_segments`** each use **3 credits** on success; **`get_sec_filing_markdown`** uses **10 credits** on success. Check your balance at [AI credits](https://www.revelata.com/ai-credits). Note that all accounts receive 100 free credits each month. |

---

## Network and TLS

- Use **HTTPS** only for the MCP endpoint.
- Allow outbound **HTTPS** to your MCP host; some corporate networks interfere with long-lived streaming — try another network to test.
- If auth hangs, try toggling **VPN**.

---

## Tools don’t appear

1. **Restart** Claude after changing the connector.
2. **Re-add** the connector and complete OAuth again.
3. Confirm your client supports **remote MCP** with **Streamable HTTP** (not only legacy SSE docs).

---

## OpenClaw vs MCP

| Runtime | How you use deepKPI |
|--------|----------------------|
| **Claude + MCP** | Connector URL **`…/mcp`**, OAuth — tools **`query_company_id`**, **`list_kpis`**, **`search_kpis`**, **`company_summary_search`**, **`get_company_summary`**, **`get_company_segments`**, **`list_sec_filing_markdowns`**, **`get_sec_filing_markdown`**. |
| **OpenClaw** | Install **`revelata-deepkpi`**, set **`DEEPKPI_API_KEY`**, call REST per [`deepkpi-api/deepkpi-api.md`](./deepkpi-api/deepkpi-api.md). |

Do not paste the MCP URL into OpenClaw as a substitute for the REST skill flow.

---

## Skill bundle (this repo)

Agent instructions and OpenClaw install:

```bash
curl -fsSL https://raw.githubusercontent.com/revelata/deepkpi-agents/main/install.sh | bash
```

Details: [README.md](./README.md).

---

## Still stuck?

- Please reach out right away to support@revelata.com!