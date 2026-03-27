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

## Authentication issues

| Symptom | What to try |
|---------|-------------|
| Redirect loop or “access denied” | Confirm you’re signed into the expected Revelata account. |
| Connector works but **search** fails | You may be out of **credits**. **`list_kpis`** and **`query_company_id`** are free; **`search_kpis`** uses credits. Check your balance at [AI credits](https://www.revelata.com/ai-credits). Note that all accounts receive 100 free credits each month. |

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
| **Claude + MCP** | Connector URL **`…/mcp`**, OAuth — tools **`query_company_id`**, **`list_kpis`**, **`search_kpis`**. |
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