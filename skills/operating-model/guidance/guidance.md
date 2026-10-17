---
name: guidance
description: >
  Reads the issuer's own outlook for the first projection year, once, for the
  operating-model skill. Invoked by the `operating-model` orchestrator at its Step
  3.5, after the KPI inventory and before any section is built. Lists the company's
  8-K filings, pulls the latest earnings-release exhibit, extracts a fixed list of
  guided items for fiscal year `N+1` and hands back a guidance table that every
  section sub-skill receives beside the inventory: the first rung of the default
  driver seed, and the source of the guidance check in CONSOLIDATED FINANCIALS. A
  component, not a route or a stage; it lays no rows itself.
---

# guidance

## Why this exists

An analyst's first source for the first forecast year is what the company itself
said it expects. Most issuers publish an outlook with their annual results and update
it each quarter: sales or comparable-sales growth, unit openings, capital spending, an
adjusted profit measure. The model's drivers should start from those figures where
they exist, and the model's totals should be checked against them where they do not
map to a driver. This sub-skill reads that outlook once so that no section has to.

## Data access

Two deepKPI operations, both against the resolved `company_id`:

- `list_sec_filing_markdowns` with `form_type` `8-K`, free. Earnings releases are filed
  as an 8-K with the release attached as an exhibit (`doc_type` `EX-99.1` or similar).
- `get_sec_filing_markdown` for one exhibit, ten credits. Read one exhibit per build;
  a second only when the first turns out not to be a results release or is silent on
  outlook (step 4 below); never a third.

If either call fails, `../../_common/connection-failure.md` applies: transient errors
are retried as it says, and only a call that fails after the retries is a stop.

## Which exhibit

1. List the 8-K filings from the start of fiscal year `N` onward.
2. Candidates are the exhibits attached to those filings. A results release is one
   whose first lines report quarterly or annual results; a dividend declaration, a
   governance filing or a conference announcement is not.
3. Take the **most recent** results release. Guidance is updated every quarter and the
   latest statement supersedes earlier ones.
4. Confirm the outlook it states is for the model's fiscal year `N+1`. Whatever the
   latest release's outlook section says is the issuer's current statement, and three
   statements mean **no guidance**: an outlook for a later year only (deepKPI's annual
   data lags the issuer's reporting), a withdrawal of the outlook, and a note that the
   outlook is given on the earnings call or the investor site. For any of these, hand
   back an empty table with that reason and read no earlier release: an earlier
   release's figures are superseded, never still in effect, and `N+1` is never seeded
   from guidance for a different year. Only a release that is **silent** on outlook,
   with no outlook section at all, sends the reading to the next most recent results
   release of the same fiscal year; the annual results release nearly always carries
   one.

## The fixed list of items

Extract only these, in the issuer's words. Anything the release guides that is not on
the list is recorded in the hand-back as text and never seeded.

| Item | Typical phrasing | Used by |
|---|---|---|
| Total revenue or net sales, level or growth | "net sales of 21.4 to 21.65 billion", "revenue growth of 3 to 5 percent" | check memo in CONSOLIDATED FINANCIALS; a revenue build whose driver is total growth |
| Total costs and expenses, level or growth, with the basis the issuer states | "total expenses of 114 to 119 billion" | check memo in CONSOLIDATED FINANCIALS; never a driver |
| Comparable sales growth, company, franchise or system, by nameplate where given | "comparable sales minus 0.5 to plus 0.5 percent" | the comparable-sales builds' comp drivers; on any other revenue build, the check block in CONSOLIDATED FINANCIALS |
| Systemwide sales growth | "global systemwide sales approximately flat" | the check block in CONSOLIDATED FINANCIALS, with the memo where the model lays systemwide sales |
| Unit development: gross openings, net new units, closures, by company or franchise where given | "250 to 300 net new restaurants", "open approximately 40 stores" | the location builds' openings and closures drivers; on a build without that driver, the check block in CONSOLIDATED FINANCIALS |
| Capital expenditures, on the basis the issuer defines | "capital expenditures of 120 to 130 million" | the depreciation schedule's `Guidance: Capital Expenditures` input and its capex driver |
| Depreciation and amortization | "D&A of approximately 150 million" | the check block in CONSOLIDATED FINANCIALS against `Total Depreciation & Amortization`; never a driver, the schedule keeps its own D&A |
| Adjusted EBITDA, level or margin, with the definition the release gives | "adjusted EBITDA margin 7.7 to 7.9 percent" | check memo in CONSOLIDATED FINANCIALS |
| Operating income or operating margin, reported or adjusted, with the basis the release gives | "adjusted operating margin of at least 22.3 percent" | check memo in CONSOLIDATED FINANCIALS against the model's `Operating margin` row; never a driver |
| Gross margin rate, SG&A rate | "gross margin rate down 40 basis points" | the cost build's ratio driver for that line where it lays one (cost of sales as 1 − the gross margin rate; the SG&A ratio); a gross margin guide also gets the check memo in CONSOLIDATED FINANCIALS against `Gross margin` |
| Effective tax rate, adjusted EPS, free cash flow, share count | | recorded only; the model stops at EBITDA |

Every item above the last row is within the model's scope. One that no section's
driver takes is laid in CONSOLIDATED FINANCIALS (§7.1 of `consolidated-financials.md`)
as a `Guidance:` input, with a check memo where the model has a row on the same scope
and basis, so the issuer's stated figure is on the sheet; the hand-back's text is
never the only place a listed guide appears. A segment or nameplate guide is laid at
that scope against the consolidated section's segment row.

## Reading the numbers

- A **range** gives low and high; the seed is the **midpoint**. Record all three.
- "**Approximately X**" and "**about X**" give X as low, high and midpoint.
- "**At least X**" or "**X or better**" gives X as the midpoint and says so in the
  basis column; "**up to X**" likewise.
- **Qualitative phrases** map to a number only from this list, and the phrase is kept
  verbatim beside it: "flat" or "approximately flat" is 0%; "low single digits" is 2%;
  "mid single digits" is 5%; "high single digits" is 8%; "low double digits" is 11%;
  "in line with the prior year" is 0% change. Any other wording ("modest growth",
  "improvement") is recorded as text with no midpoint and is not seeded.
- A **basis** the issuer attaches travels with the item: the fiscal-year length
  (52 or 53 weeks), the inclusion of closed-store sales, constant currency, the
  non-GAAP definition and its exclusions, "excluding the impact of" anything. The
  consolidated section's check memo and the cost builds read that basis.
- Guidance stated for a **quarter** only is recorded and not seeded; the model is
  annual.
- Guidance for a **segment or nameplate** is kept at that level; a build seeds the
  segment driver when it has one and never allocates a consolidated figure down. A
  build without that driver leaves the item to the consolidated section's check block.

## The guidance table

Hand back one row per item found:

| Item | Scope | Fiscal year | Low | High | Midpoint | Unit | Basis | Verbatim | Citation |
|---|---|---|---|---|---|---|---|---|---|

Scope is `consolidated`, a segment or nameplate, or `company-operated` / `franchised`.
Unit is the issuer's (USD millions, percent, units). Citation is the accession number,
the exhibit sequence and the SEC URL from the listing, which is what a seeded driver's
hyperlink points at. An empty table is a valid result; say in one line why it is empty
(no results release in the window, no outlook section in any results release of the
year, outlook withdrawn, outlook given on the call or the investor site only, outlook
for a different year).

Record separately in `BUILD_LOG.md`, as text, every guided item not on the list and
every item whose wording did not map to a number; this is what the reading found and
set aside, not a workbook note.

## How the sections use it

Each sub-skill receives the table with the inventory. At its driver-methodology step it
checks, for each driver it lays, whether a row of the table names that driver at that
scope for fiscal year `N+1`; if so the `N+1` cell is the midpoint, written with
`drivers_fixed()` and hyperlinked to the citation, and the cell comment reads
`"Issuer guidance for FY<N+1>: <verbatim>. Midpoint of <low> to <high>. <basis>."`
The Notes block carries one line naming every driver seeded from guidance, in the
analyst's words: `"Guidance: <driver>, <driver> and <driver> for FY<N+1> follow the
issuer's outlook of <date>; later years hold them flat."` This is a default the
analyst may override. A driver
the table does not name takes the next rung of the default seed. The consolidated
section lays a `Guidance:` input for every listed item for `N+1` that no driver took,
with a check memo where the model has a row on the same scope and basis
(`consolidated-financials.md` §7.1).

## What this sub-skill does not do

- It does not read the 10-K's outlook or MD&A; that text is the sections' own reading
  for ratio bases and one-off disclosures.
- It does not reconcile a guided adjusted measure to GAAP; it records the definition
  and the exclusions the issuer lists.
- It does not judge whether guidance is credible. The analyst does that by override.

## Hand-back report

`COMPLETE` with: the exhibit read (filing date, accession, sequence), the fiscal year
guided, the guidance table, the recorded-only items, and the one-line reason when the
table is empty.
