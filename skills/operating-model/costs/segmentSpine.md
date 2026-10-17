---
name: costs-segment-spine
description: >
  Projection rule for a COSTS section built on a segment path: which level, the
  segment blocks or the consolidated lines, carries the forward drivers, and how
  the other level is derived from it so that the segment subtotals and the
  consolidated total tie in every projection column. Read inline by each industry
  cost build (`restaurants/restaurantsCosts.md`, `retail/retailCosts.md`,
  `software/softwareCosts.md`) at its segment-detail projection step when its
  segmentation gate chose a segment path. A component, not a route or a stage;
  it lays no rows itself.
---

# Segment spine — one set of forward assumptions

## Why this file exists

A cost build on a segment path lays two decompositions of the same costs: a block per
segment, each with its own `% of segment revenue` ratios, and a consolidated table
whose lines sum the segments in history and foot to the reported figures. In history
both are facts and they agree by construction. Forward, each cost build's projection
section gives both levels their own red drivers, and two independent driver sets
never add up: the segment subtotals drift from the consolidated total, the
consolidated section's segment operating-income lines no longer sum to its total, and
no row on the sheet says so. An analyst keeps **one** set of assumptions and derives
the other level by identity. This file says which level that is and how the identity
is written.

## Which level is the spine

Decide once, from the shape of the disclosure the build already read at its
segmentation gate, and record the decision in the hand-back.

- **Case A: the segment lines are the face lines.** Each segment discloses the same
  captions the consolidated income statement carries (cost of sales and selling,
  general and administrative per brand; cost of revenue and operating expenses per
  product segment), possibly plus a corporate-only line at the consolidated level.
  The **segments are the spine.** Each segment block keeps its forward `% of segment
  revenue` drivers. Each consolidated line that maps to the segments keeps, in every
  projection column, the same `= SUM(segment lines)` formula it has in history; a
  corporate-only line keeps its own forward driver on total revenue; the consolidated
  subtotals and `Total Costs and Expenses` sum as before. The consolidated `% of
  revenue` block is then a set of derived reads forward, not drivers.

- **Case B: the segments decompose costs differently from the face lines.** The
  segments disclose, say, employee compensation and other costs, while the income
  statement carries cost of revenue, research and development, marketing and general
  and administrative; or the segments disclose only segment revenue and segment
  operating income. The **consolidated face lines are the spine**: they are the income
  statement the analyst reads, the level the issuer guides, and the row every
  downstream section references as `Total Costs and Expenses`. Every segment but one
  keeps its own forward drivers. The remaining segment, the **residual**, is derived:
  its `Total Costs and Expenses — <Segment>` in each projection column is
  `= <consolidated Total Costs and Expenses> − SUM(<the other segments' totals>)
  − SUM(<corporate-only lines>)`, its segment operating income is its revenue less
  that, and its individual cost lines forward are dashes, because a total cannot be
  split into lines without an allocation the issuer never gave. Its `% of segment
  revenue` block forward shows the total ratio and the operating margin as derived
  reads and dashes for the lines.

**The residual is the largest segment by revenue in year `N`.** The small segments are
where an analyst's assumptions live, a loss-making segment above all, and the large
one absorbs the identity. A segment-only disclosure, revenue and operating income
with no cost lines, is Case B with one cost line per segment, `segment revenue −
segment operating income`, and the same residual rule.

Guidance does not move the spine. A guided item for a non-residual segment seeds that
segment's drivers; a guided consolidated line or ratio seeds the consolidated driver
under Case B and becomes a check memo under Case A, where the consolidated line is a
sum; a guided total of costs is always a check memo (`consolidated-financials.md`).

## The proof on the sheet

The memo the build lays in history, `Memo: Total Costs and Expenses − Σ segment totals
(must = 0)`, with the corporate-only lines in the sum where they exist, is carried into
**every projection column** and must read 0 there too. Under Case A it is 0 because the
consolidated lines are sums; under Case B because the residual is defined by it. A
non-zero forward value is a build error, not a judgment.

## The two styling exceptions

Each cost build's projection section says that every forward `%` cell is a red driver
and every forward dollar line is `% × base`. On a segment path the **derived level** is
the exception to both, and this is the only exception:

- its forward `%` cells are **black formulas**, derived reads, written as formula cells
  so the renderer colors them as reads, not as drivers;
- its forward dollar lines are the **identity formulas** above, `SUM` of segments or
  the residual difference, not `% × base`.

The non-derived level keeps the ordinary rule unchanged. The dashes left in a
residual segment's line items are dashes, not zeros.

## Cell comments and Notes

The consolidated total's comment, or the residual segment's subtotal comment, says
which level is the spine in the analyst's words: `"Forward: the sum of the brand
blocks plus the corporate line; brand ratios are the assumptions."` or `"Forward:
derived as consolidated costs less the other segments; dial the consolidated lines or
the other segments' ratios."` The Notes block carries one line, in the analyst's
words: `"Costs: forward costs are the sum of the segment blocks plus the corporate
line; <name> is the residual segment."` or `"Costs: forward costs are consolidated
costs less the other segments; <name> is the residual segment."`

## Hand-back

The cost build's hand-back report states the case, the spine, the residual segment
where there is one, the segment names as the revenue hand-back's segment map spells
them, and that the Σ-segments memo is 0 in every column. The consolidated section
needs nothing else: its segment revenue lines come from the same map, its segment
cost rows reference the segment subtotals and its totals reference the consolidated
rows, so once the cost build ties,
its segment operating-income lines sum to its total in every projection column.

## What this rule does not do

- It does not touch a historical cell, the segmentation gate, or the choice of path.
- It does not apply where the segment detail is historical-only; that case keeps the
  build's existing rule of leaving the segment block's forward cells blank.
- It does not allocate a residual total down to lines, and it does not let the
  consolidated ratios be dialed under Case A; the analyst dials the segments.
