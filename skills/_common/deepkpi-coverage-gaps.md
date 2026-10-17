# deepKPI coverage gaps — known patterns and the search-exhaustion check

deepKPI's structured KPI catalog is comprehensive but not exhaustive. Several
recurring gaps trip up a first pass. This file documents the patterns to
anticipate before pulling, and the check to run before declaring that a metric
is not there. **It does not say what to do once a gap is confirmed** — that is
each skill's own rule (see the last section).

Read this file in any of the following situations:

- The company is a retailer that reports on a 4-4-5 / 13-week calendar
  (Costco, TJX, Ross, Burlington), or any non-calendar fiscal cadence where
  10-Q and 10-K use 12/24/52-week periods.
- The company files monthly sales 8-Ks (Costco, some grocers, some auto
  dealers, some apparel).
- The company has filed a material 8-K (guidance pre-announce, M&A) in the
  last few days.
- A number you expected isn't returning from `search_kpis` after a first pass.

## Gap pattern 1 — Quarter-specific values when only the half-year exists

**Pattern:** the 10-Q narrative reports a 12-week (quarter) value; deepKPI's
structured KPI catalog only carries the 24-week (1H) or 52-week (annual)
version of that same metric.

Worked example (Costco Q2 FY26):
- Narrative text: "core merchandise gross margin expanded 22 bps in Q2."
- deepKPI structured KPI: only the 24-week (1H) value, +26 bps.
- These are different numbers measuring related but different periods. Never
  attach the 1H pvid to a sentence or cell that names the quarter value; the
  numbers don't match.

## Gap pattern 2 — Monthly sales 8-Ks

**Pattern:** some companies (Costco, certain grocers, certain auto retailers,
certain apparel companies) issue monthly or 4-week / 5-week sales press
releases as 8-Ks. These press releases carry comp-sales detail by channel
and geography that does not exist in 10-Q form. deepKPI's structured KPI
catalog is built from 10-K and 10-Q periods, so the monthly figures are
NOT in the KPI database, and the sales 8-Ks themselves may not appear in
`list_sec_filing_markdowns` until a delayed ingest run.

Worked example (Costco): the March 2026 sales 8-K (5-week period ending
March 30) and the April 2026 sales 8-K (4-week period ending May 4) were
not in deepKPI's filing list at the time they were needed. Check whether the
source 8-K appears in `list_sec_filing_markdowns` before treating any monthly
figure as deepKPI-sourced; if it does not, no deepKPI pvid exists for it.

## Gap pattern 3 — Late-filed material 8-Ks

**Pattern:** an 8-K filed in the last few days (guidance preannounce,
executive change, M&A, dividend) may not have flowed into deepKPI's
structured KPI catalog yet. Its figures have no pvid until the ingest run
catches up.

## Gap pattern 4 — Segment redefinitions and one-time KPI breakouts

**Pattern:** management discloses a segment-margin or product-line figure
in the MD&A or earnings call transcript that isn't a recurring structured
KPI (a one-time disclosure of incremental margins, a region-specific comp
mentioned only in the CFO commentary). It may exist in the filing text
(`get_sec_filing_markdown`) without existing as a structured series.

## The search-exhaustion check before declaring a gap

Before declaring "this KPI is not in deepKPI", run at least FOUR distinct
`search_kpis` queries:

1. The exact metric name as it would be phrased by the user or the filing.
2. A synonym (e.g., "comparable sales" / "same-store sales" / "comps").
3. The parent metric (e.g., for "core merchandise gross margin",
   search "gross margin" alone).
4. The segment-level or geography-level variant (e.g., for a US-only
   figure, search the segment name explicitly).

If `list_kpis` returns a candidate that looks close to what you need,
test it with a `search_kpis` call before concluding it's not the right
match. Many gaps disappear with one more query.

Record what was searched when a gap is declared. "Tried <4 variants, none
returned X" is a defect; "tried [variant1, variant2, variant3, variant4],
deepKPI gap" is acceptable.

## What happens after a confirmed gap is each skill's own rule

This file stops at the confirmed gap: the search was exhausted per the section above and
the search log is recorded. What a skill does next — cite another source, derive the
figure, stop and ask — depends on what it produces, and is stated in that skill's own
file, never here. The shared layer does not describe individual skills.
