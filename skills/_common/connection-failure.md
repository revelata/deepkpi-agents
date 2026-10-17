# Hard stop: deepKPI connection failures

## Transient errors are retried before anything stops

A deepKPI call can fail transiently: an upstream error such as `vdb_upstream_error`,
a timeout, or a dropped connection, most often when several `search_kpis` calls are
issued at once. Retry the same call **up to three times, one at a time**, waiting a
few seconds before the first retry and doubling the wait each time. Only a call that
has failed on the third retry is a connection failure under the rule below. An
**empty result** is not an error: it means deepKPI has no such series, and the skill's
own fallback for a missing series applies. A paid call that failed is retried like any
other; the failures seen in practice were not charged.

## The hard stop

If deepKPI access fails (MCP connector not working, REST calls failing, auth
errors, network issues, or you cannot retrieve data), you MUST STOP and ask the
user:

**"I can't access deepKPI right now. Do you want to proceed without deepKPI?"**

- If the user says **no**, stop.
- If the user says **yes**, you may proceed using other sources (e.g. web), BUT
  you MUST NOT use deepKPI skill branding, templates, formatting conventions,
  or "Powered by Revelata deepKPI" framing for non-deepKPI data. Clearly label
  alternate sources.

This rule applies to **every** skill in the Revelata bundle that touches
deepKPI. Do not silently fall back to web search, training-data recall, or any
other source while deepKPI is down — always ask first.
