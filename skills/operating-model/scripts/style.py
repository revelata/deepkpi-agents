"""Styling and number-format constants for the operating-model renderer.

This file is the single IMPLEMENTATION of two specifications:
  - ../../_common/revelata-excel-styling-rules.md   (colors, fonts, borders, layout)
  - ../../_common/revelata-excel-units-and-scale.md (number formats, Rule 3)
Those files remain the specification a human reads. When a rule there changes,
change the matching constant here in the same commit. Nothing in the skill text
restates a color code or a format string; it names the convention, and this
file carries the value.
"""

# ---- Fonts and layout (styling rules: "Sheet defaults", "Title cell C1",
#      "Period column headers", "Freeze panes", "Layout") --------------------
FONT_NAME = "Calibri"            # body font for the whole sheet
FONT_SIZE = 12                   # body, title, period headers, sub-headers
SECTION_HEADER_SIZE = 16         # the five ALL-CAPS section headers: bold + underline + size 16
TITLE_CELL = "C1"                # bold 12pt sentence-case title, merged C1:D1
PERIOD_HEADER_ROW = 3            # numeric fiscal-year-end dates, bold + underline
FIRST_DATA_ROW = 4               # first row beneath the period headers
FIRST_DATA_COL = 5               # column E; A and B hidden (audit trail), C labels, D units tags
FREEZE_PANES = "E4"              # below the header row, right of column D
COL_WIDTH_LABEL = 52             # column C
COL_WIDTH_UNITS = 24             # column D
COL_WIDTH_PERIOD = 15            # each period column
HIDE_COLUMNS = ("A", "B")        # Col A = deepKPI metric name (audit trail), Col B = row index
SHOW_GRIDLINES = False

# ---- Colors (styling rules: "Sheet defaults" > "Color conventions") -------
# ARGB strings as openpyxl expects them.
INPUT_FILL = "FFE2EFDA"          # pale green: deepKPI-sourced input values
LINK_FONT = "FF0563C1"           # dark blue: every hyperlinked (provenance) value cell
SOURCE_LABEL_FONT = "FF0070C0"   # blue: Col A source-label text
DRIVER_FONT = "FFFF0000"         # red: estimated / assumption values (forward drivers)
TENK_FILL = "FFFFF2CC"           # pale gold: a value taken from the 10-K text, overriding deepKPI (cell comment states why)
DERIVED_FONT = None              # black (default): every formula cell

# ---- Borders (styling rules: "Totals and subtotals — the sum bar") ---------
SUM_BAR_SIDE = "thin"            # one thin TOP border across the data columns of a total row; never on Col C/D
DRIVER_BORDER_SIDE = "dashed"    # dashed box around a forward driver cell (override here)

# ---- Comment authors (styling rules: label comments carry the recipe) ------
AUTHOR_MODEL = "deepKPI model"   # Col C label comments (the operand recipe / methodology)
AUTHOR_INPUT = "deepKPI"         # notes on green input cells
AUTHOR_TENK = "10-K"             # notes on gold 10-K override cells
AUTHOR_DRIVER = "assumption"     # notes on red driver cells

# ---- Number formats (units-and-scale Rule 3; accounting style, dash for zero)
FMT_COUNT  = '_(* #,##0_);_(* \\(#,##0\\);_(* "-"_);_(@_)'            # counts / ones
FMT_MM     = '_(* #,##0,,_);_(* \\(#,##0,,\\);_(* "-"_);_(@_)'        # money stored in dollars, shown in millions
FMT_MM1    = '_(* #,##0.0,,_);_(* \\(#,##0.0,,\\);_(* "-"_);_(@_)'    # millions with one decimal (Rule 3: where whole millions lose precision)
FMT_K      = '_(* #,##0,_);_(* \\(#,##0,\\);_(* "-"_);_(@_)'          # money shown in thousands
FMT_K1     = '_(* #,##0.0,_);_(* \\(#,##0.0,\\);_(* "-"_);_(@_)'      # thousands with one decimal
FMT_PCT    = '_(* #,##0.0%_);_(* \\(#,##0.0%\\);_(* "-"?_);_(@_)'     # percent, stored as a fraction
FMT_PER    = '_(* #,##0.00_);_(* \\(#,##0.00\\);_(* "-"_);_(@_)'      # per-unit money in natural dollars
FMT_PER_MM = '_(* #,##0.00,,_);_(* \\(#,##0.00,,\\);_(* "-"_);_(@_)'  # per-unit money shown in millions (e.g. USD millions per location)
FMT_X1     = '_(* #,##0.0_);_(* \\(#,##0.0\\);_(* "-"_);_(@_)'        # plain number, one decimal (years, days, multiples)
FMT_UNITS  = FMT_PER_MM                                                  # unit counts stored in ones, shown in millions with two decimals
FMT_PERIOD_HEADER = '"FY{year} ("mmm-yy")"'                              # period header: numeric date shown as FY2025 (Dec-25)

# Col D tag prefix -> number format. Used by audit.py (Rule 6 check 3) and by
# builders that want the format implied by a tag. Longest prefix wins.
TAG_FORMATS = [
    ("(USD in millions",            (FMT_MM, FMT_MM1)),
    ("(USD in thousands",           (FMT_K, FMT_K1)),
    ("(USD per ",                   FMT_PER),
    ("(USD millions per ",          FMT_PER_MM),
    ("(USD thousands per ",         FMT_K1),
    ("(people, in millions",        FMT_MM),
    ("(sq ft in millions",          FMT_MM1),
    ("(sq ft per ",                 FMT_COUNT),
    ("(pairs, in millions",         FMT_UNITS),
    ("(units, in millions",         FMT_UNITS),
    ("(users, in millions",         FMT_UNITS),
    ("(%",                          FMT_PCT),
    ("(days)",                      FMT_X1),
    ("(years)",                     FMT_X1),
    ("(x)",                         FMT_X1),
    ("(locations)",                 FMT_COUNT),
    ("(stores)",                    FMT_COUNT),
    ("(restaurants)",               FMT_COUNT),
]

MONEY_FAMILIES = {"(USD in millions": (1_000_000, FMT_MM, FMT_MM1),
                  "(USD in thousands": (1_000, FMT_K, FMT_K1)}


def money_family(tag):
    """The money family a Col D tag belongs to ('(USD in millions' / '(USD in thousands'), or None."""
    if not tag:
        return None
    for prefix in MONEY_FAMILIES:
        if tag.startswith(prefix):
            return prefix
    return None


def money_format(prefix, input_values):
    """Units contract, Rule 3: a money family's decimals are derived from its historical
    inputs, never chosen. One decimal when any stored input is not a whole number of the
    display unit (an issuer reporting in thousands, or to a tenth of a million, in a
    millions column); whole units otherwise."""
    unit, whole, one_dec = MONEY_FAMILIES[prefix]
    for v in input_values:
        if isinstance(v, (int, float)) and not isinstance(v, bool) and round(v) % unit != 0:
            return one_dec
    return whole


def formats_for_tag(tag):
    """Return the tuple of acceptable number formats for a Col D tag, or None if the tag is unknown."""
    if not tag:
        return None
    best = None
    for prefix, fmt in TAG_FORMATS:
        if tag.startswith(prefix) and (best is None or len(prefix) > len(best[0])):
            best = (prefix, fmt)
    if best is None:
        return None
    fmt = best[1]
    return fmt if isinstance(fmt, tuple) else (fmt,)
