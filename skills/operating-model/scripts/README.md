# operating-model/scripts — the renderer

`framework.py` is the single implementation of the compose-then-render mechanic that
`../SKILL.md` ("Build mechanics") requires; `style.py` is the single implementation of
the styling and units contracts in `../../_common/`; `audit.py` runs the Rule 6 unit
audit of Step 5. The skill text is the specification; these files make it executable.
When a rule in the text changes, change the matching constant here in the same commit.

A build directory (e.g. `.model_build_<ticker>/`) contains:

```
model.py                 configure(...) — title, output path, timeline, fiscal year-ends
sec_revenue.py           REVENUE rows      (ROWS, NOTES)
sec_dep.py               DEPRECIATION SCHEDULE rows
sec_costs.py             COSTS rows
sec_consol.py            CONSOLIDATED FINANCIALS rows
sec_nwc.py               NET WORKING CAPITAL rows
build_all.py             assemble + render
```

`model.py`:

```python
import sys, datetime
sys.path.insert(0, "<path to skills/operating-model/scripts>")
from framework import *
configure(
    title="<Registrant name> — operating model (deepKPI)",
    out="<workspace>/<Company>_operating_model.xlsx",
    hist=[2022, 2023, 2024, 2025], proj=[2026, 2027, 2028, 2029, 2030],
    fye={2022: datetime.date(2022, 12, 31), ...},
    fye_note="FYE Dec-31",
)
```

Every section module starts with `from model import *` and ends by exposing `ROWS`
(a list of `Row` objects, without the section header) and `NOTES` (a list of strings).

`build_all.py`:

```python
from model import *
import sec_revenue, sec_dep, sec_costs, sec_consol, sec_nwc
parts = {
    "REVENUE": sec_revenue.ROWS, "COSTS": sec_costs.ROWS,
    "CONSOLIDATED FINANCIALS": sec_consol.ROWS,
    "DEPRECIATION SCHEDULE": sec_dep.ROWS, "NET WORKING CAPITAL": sec_nwc.ROWS,
}
notes = sec_revenue.NOTES + sec_dep.NOTES + sec_costs.NOTES + sec_consol.NOTES + sec_nwc.NOTES
render(assemble(parts), notes)
```

While a build is in progress, leave out the sections not yet written: `assemble`
lays their headers with spacer rows, and `render` refuses (naming the key and the
referencing row) if a formula points at a row no assembled section lays down. The
scaffold of Step 2 is `scaffold()`, i.e. `assemble({})` rendered.

After every render: `python3 <xlsx skill>/scripts/recalc.py <out>` (LibreOffice recalculation —
`recalc.py` needs LibreOffice's `soffice` on `PATH`; on macOS it lives at
`/Applications/LibreOffice.app/Contents/MacOS`, so prepend that directory for the run —
zero formula errors), then `python3 audit.py <out> --last-hist-col <column letter of N>`.

## The build log and re-running a stage

`BUILD_LOG.md` in the build directory is the build's own history: every `DEFECT UPSTREAM`
record a stage returned, the ledger of (owner, row, scope) pairs the orchestrator has
already acted on, and each re-run's outcome (`../SKILL.md`, Step 4.2). It is never copied
into the workbook; the Notes block carries only the resulting modeling facts.

Re-running a stage means re-executing that stage's file against the rows that now exist
and rewriting its section module (`sec_<name>.py` here); the renderer is not edited.
After the owner is re-run, every later section module is re-run in build order and
`build_all.py` renders the whole workbook again — there is no partial re-render.
