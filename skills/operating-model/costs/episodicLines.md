---
name: costs-episodic-lines
description: >
  Projection rule for the episodic cost lines of an operating-model COSTS section:
  impairments and other write-downs, restructuring and closing programs, settlements,
  and gains or losses on assets presented inside the operating block. Read inline by
  each industry cost build (`restaurants/restaurantsCosts.md`, `retail/retailCosts.md`,
  `software/softwareCosts.md`) at its driver-methodology step, for the lines that
  build names as in scope. Decides only the first projection year's driver seed for
  those lines; every other mechanic of the cost build is unchanged. A component, not
  a route or a stage; it lays no rows itself.
---

# Episodic cost lines — the projection seed

## Why this file exists

The cost builds seed every forward `% of revenue` driver at the issuer's guided value
or, more often, at the latest historical year. That is the right default for a cost
that scales with the business. It is the wrong default for a line whose history is one
large charge or credit among small or zero years: a latest-year seed carries the whole
event into every forward year when the event is the latest year, an average carries a
fraction of it whichever year it was, and either way the modeled operating margin is
wrong by that amount for the whole horizon. An analyst never does this. A one-off
charge is shown in history and carried at zero forward; a program the company runs
every year is carried at a normal level with the spike taken out.

This file is the rule the cost build applies to those lines instead of the default seed. It
is read once, at the point in the build's projection section that names it, and only for
the lines the build itself lists as in scope. Nothing here touches a historical cell.

## What is in scope

Each cost build keeps its own list of the captions this rule covers, in the issuer's
vocabulary, next to the pointer that sends it here. The lists share one definition: a
line whose amount is set by discrete events rather than by the level of activity.
Typical captions are impairment of goodwill, intangibles, trademarks or long-lived
assets; restructuring, reorganization, realignment, exit, severance, store-closing or
restaurant-closing costs; litigation or regulatory settlements; and gains or losses on
the sale, termination or modification of assets, leases or businesses when the issuer
presents them inside the operating block.

Lines that recur because the business recurs stay on the default seed and are never
in scope, whatever their caption: pre-opening costs, advertising-fund expense, provision
for doubtful accounts, amortization of acquired intangibles (which the software build
holds flat by its own rule), and an "other operating income or expense" line that the
issuer reports every year.

## Storage precondition

A year in which the issuer did not incur an in-scope line is stored as a numeric **0**
in that line's historical dollar cell, never as the text dash. The number format
displays a zero as a dash, so the sheet reads the same either way, but the seed
functions below use `COUNT`, `AVERAGE` and `MEDIAN`, which all ignore text. If two of
the three seed years were text dashes, every one of those functions would return the
single remaining year, which is exactly the spike this rule exists to exclude. The
historical `%` cell for such a year is then a live `0 ÷ base`, which is 0.

## The rule

Apply the steps in order to each in-scope line and stop at the first that decides it.
Every outcome is a red driver in `N+1`, with each later year referencing the `N+1`
cell, exactly as the default drivers are laid; only the `N+1` value differs.

1. **The issuer's own adjusted measure.** If the 10-K's non-GAAP reconciliation
   (adjusted operating income, adjusted EBITDA or adjusted net income) excludes the
   line, seed **0**. The issuer has said the line is not part of its run-rate; the
   analyst's convention is to agree.

2. **The nature of the charge.** Decided from the caption, without reading further.
   - A **non-cash write-down** (goodwill, intangible, trademark, long-lived asset or
     store-asset impairment) seeds **0**. Nobody forecasts a write-down, and the asset
     just written down is smaller than it was.
   - An **event-driven gain or loss** (sale of assets, real estate or a business; lease
     termination or modification; legal or regulatory settlement; insurance recovery)
     seeds **0**, whichever sign it carried in history.

3. **A program with a disclosed remaining cost.** For a restructuring, reorganization,
   exit or closing program the issuer must disclose the total expected cost and the
   cost incurred to date in the exit-cost note of the 10-K. Where that note exists, the
   remaining cost (expected less incurred) is the forward charge: seed `N+1` as a live
   formula, the remaining cost divided by the build's own projected revenue base for
   `N+1` (the same row its other drivers divide by, already declared in the build's
   Dependencies table), and seed `N+2` onward at **0** unless the note gives timing, in
   which case spread the remaining cost over the years it names. The remaining cost and
   the note are cited in the cell comment.

4. **Frequency.** For anything not decided above, count the historical years (all four
   on the sheet) in which the line was non-zero.
   - **Three or four**: the line recurs. Seed `N+1` at the **run-rate**, the median of
     the three most recent historical `%` cells, written as a live formula with the
     same `COUNT` guard the default seed uses: `= IF(COUNT(N−2:N) = 0, 0, MEDIAN(N−2:N))`.
     With one distorted year among three, the median always lands on a normal year, so
     the builder never decides which year is the outlier, and it holds when the spike is
     the latest year.
   - **Two or fewer**: the line is a one-off. Seed **0**.

## How the cell reads

The red driver cell carries a comment that states the outcome in the words an analyst
would use, never the name of the step or of a function:

- Zero, step 1: `"Projection driver. Excluded from the issuer's adjusted operating
  income; carried at 0. Override with a run-rate if a charge is expected."`
- Zero, step 2: `"Projection driver. Non-cash write-down, not forecast; carried at 0."`
  or `"Projection driver. Event-driven gain or loss, not forecast; carried at 0."`
- Zero, step 4: `"Projection driver. Incurred in <k> of 4 years; treated as a one-off
  and carried at 0."`
- Remaining cost, step 3: `"Projection driver. Expected remaining cost of the <program>
  per the 10-K exit-cost note, <amount> in FY<N+1>, 0 thereafter."`
- Run-rate, step 4: `"Projection driver. Recurring program line, incurred in <k> of 4
  years; run-rate of the three most recent years with the spike year excluded
  (FY<year>, <value>). Held flat."`

The forward dollar cell stays the build's ordinary `= % × base` formula, so a zero
driver shows a zero dollar line, displayed as a dash by the number format, and the row
keeps its place in the `SUM`.

## Notes and hand-back

The build's Notes block carries one line naming each in-scope line and its treatment,
stated as a modeling fact: `"Costs: <line> carried at 0 forward (excluded from adjusted
operating income); <line> at a run-rate of <value> (recurring program, FY<year>
excluded)."` The hand-back report lists the same, and separately lists two sets of
row keys: the **lines seeded at zero forward** (steps 1, 2 and 4), which NET WORKING
CAPITAL subtracts from `Total Costs and Expenses` to lay its recurring cost base
(`../net-working-capital/net-working-capital.md` §1.5); and **every line the issuer
excludes from its adjusted measure** (step 1, whether or not the line was in scope
here), which CONSOLIDATED FINANCIALS reads to lay `Adjusted EBITDA (issuer basis)`
for the guidance check.

## Where the driver lives

Under a segment path the in-scope line's driver sits on the segment row, exactly where
the build's own methodology puts every segment driver, and the consolidated row is the
sum the build already lays. The rule is applied at whichever level carries the driver,
never at both.

## What this rule does not do

- It does not change a historical cell, a memo, a reconciliation or a subtotal.
- It does not decide a line whose history is two spikes in three years; the median then
  returns a spike and the cell comment says so. Guidance in the issuer's earnings
  release may give a better seed, and the analyst may type it over the driver.
- It does not reclassify a line the issuer reports inside the operating block to below
  the line, or the reverse; the line set is decided by the build's own sections.

In the renderer, a zero or formula seed is written with `drivers_fixed()` and the
run-rate with `drivers_runrate()` (`scripts/framework.py`); the default seed stays
`drivers()`.
