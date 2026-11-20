# deepKPI connection failures: sign in first, retry second, stop and ask last

Work through the three cases below in order. The first case that matches decides
what you do.

## 1. Not signed in: send the user to sign in

A new user often has the Revelata plugin installed but has not yet signed in to the
deepKPI connector. That is a setup step, not an error. Never answer it with an error
message or with the "proceed without deepKPI?" question in section 3.

The user is **not signed in** when any one of these holds:

- The deepKPI tools (`query_company_id`, `list_kpis`, `search_kpis`,
  `company_summary_search`, `get_company_summary`, `get_company_segments`,
  `list_sec_filing_markdowns`, `get_sec_filing_markdown`) are missing from your tool
  list, including from any deferred-tool or tool-search listing.
- The only tools for the Revelata or deepKPI server are sign-in tools: a tool whose
  name ends in `authenticate` (for example `mcp__plugin_revelata_revelata__authenticate`),
  or whose description says the server "requires authentication".
- A deepKPI call fails with HTTP 401 or 403, or with a message such as
  "unauthorized", "authentication required", "invalid token", "token expired",
  "not connected" or "please sign in".

When the user is not signed in, do this before anything else in the skill, and do
not call any other data source:

1. **If a sign-in tool for the Revelata or deepKPI server is available, call it now.**
   It returns a sign-in link. Do not ask permission first, because the user asked
   for data that needs sign-in. If several servers offer a sign-in tool, use the one
   whose name or description mentions Revelata, deepKPI or
   `deepkpi-mcp.revelata.com`.
2. **Send the user one short message** that gives the link and says what happens
   next. Use the link the sign-in tool returned. If no sign-in tool is available,
   replace the link with the steps for the user's app from the list after these
   steps. Keep this wording or something close to it:

   > To pull this from deepKPI, sign in to your Revelata account first:
   > **[Sign in to Revelata](<link>)**
   >
   > No account yet? The same page lets you create one for free, and every account
   > gets 100 free credits a month. When you've signed in, reply **done** and I'll
   > pick up your request where it left off.

   Do not add a list of possible causes, do not describe it as an error, and do not
   offer to use other sources.
3. **End your turn and wait.** Do not answer the request from the web, from training
   data or from another tool while the user signs in.
4. **When the user replies, resume the original request.** Check for the deepKPI
   tools again (search the deferred-tool listing if there is one) and start the skill
   from its first deepKPI call. Do not make the user repeat the request.
   - If the browser showed a failed page at a `http://localhost:<port>/callback?...`
     address and a `complete_authentication` tool for the server is available, ask
     the user to paste that full address, then pass it to that tool.
   - If the tools are still missing or still fail with a sign-in error, give the
     steps for the user's app (list below) once more. If sign-in still fails after
     that, go to section 3.

Steps to connect when no sign-in tool is available. Give only the steps for the
user's app; if you cannot tell which app it is, give the first two.

- **Claude desktop app or claude.ai:** first explain in one sentence that Claude
  installs the deepKPI connector separately from the Revelata plugin, so it needs
  connecting once. Then give these steps, with the first one as a clickable link:
  1. Open the [Revelata deepKPI connector](https://claude.ai/customize/connectors/id/revelata-deepkpi)
     and click **Connect to Claude**.
  2. Sign in with a Revelata account, then reply **done**.
- **Claude Code:** run `/mcp`, select the **revelata** server and choose
  **Authenticate**.
- **ChatGPT:** open **Plugins**, find **Revelata deepKPI**, and click **Connect**.

To create an account: https://www.revelata.com/signup?product_id=0

## 2. Transient errors: retry before anything stops

A deepKPI call can fail transiently: an upstream error such as `vdb_upstream_error`,
a timeout, or a dropped connection, most often when several `search_kpis` calls are
issued at once. Retry the same call **up to three times, one at a time**, waiting a
few seconds before the first retry and doubling the wait each time. Only a call that
has failed on the third retry is a connection failure under section 3. An
**empty result** is not an error: it means deepKPI has no such series, and the skill's
own fallback for a missing series applies. A paid call that failed is retried like any
other; the failures seen in practice were not charged.

## 3. The hard stop

If the user is signed in (section 1 does not apply) and deepKPI access still fails
after the retries in section 2 (the MCP connector is not working, the network is
down, or you cannot retrieve data), you MUST STOP and ask the user:

**"I can't access deepKPI right now. Do you want to proceed without deepKPI?"**

- If the user says **no**, stop.
- If the user says **yes**, you may proceed using other sources (e.g. web), BUT
  you MUST NOT use deepKPI skill branding, templates, formatting conventions,
  or "Powered by Revelata deepKPI" framing for non-deepKPI data. Clearly label
  alternate sources.

These rules apply to **every** skill in the Revelata bundle that touches deepKPI.
Do not silently fall back to web search, training-data recall, or any other source
while deepKPI is unavailable. Send the user to sign in or ask them first.
