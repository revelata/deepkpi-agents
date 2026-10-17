#!/usr/bin/env python3
"""Dev-time dependency audit for the operating-model skill tree.

For every stage file (a build or cross-section builder), list each reference it makes to a
row laid by ANOTHER stage and check that the reference is covered by the file's own
`## Dependencies` table (columns: Row | Owner | Condition | Fallback). A reference not
covered is an undeclared dependency: the stage could not diagnose that row as missing
(SKILL.md, Step 4.2). Dev-time only — lives in tools/, outside the shipped skills/ tree.
Run before every commit (`make lint`):

    python3 tools/dependency_audit.py            # report
    python3 tools/dependency_audit.py --strict   # exit 1 on any undeclared reference

Heuristic by design: references are the `<...>` placeholders in formula tables and layout
annotations. A placeholder is cross-stage when it names another section or build, or a
contract row this file does not itself lay. Exact row matching is the renderer's job at
build time; this script only checks that each cross-stage edge is declared.
"""
import re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1] / "skills" / "operating-model"
sys.argv = sys.argv[:1] + ["--parse-only"]  # keep audit.py from running its workbook pass on import
sys.path.insert(0, str(ROOT / "scripts"))
import importlib.util as _ilu
_spec = _ilu.spec_from_file_location("om_audit", ROOT / "scripts" / "audit.py")
STAGE_DIRS = ["revenue", "costs", "consolidated-financials", "depreciation-schedule",
              "net-working-capital"]
ROUTERS = {"revenue/revenue.md", "costs/costs.md", "revenue/restaurants/restaurants.md",
           "revenue/retail/retail.md", "revenue/software/software.md"}
CONTRACT = ["Total Revenue", "Revenue from <Stream>", "Net Sales", "Total Costs and Expenses",
            "Operating Income (modeled)", "Operating Income (reported)",
            "Depreciation & Amortization", "Company-Operated EOP Balance"]
MARKERS_CI = re.compile(r"location build|location section|store roll-forward|roll-forward'?s|"
                        r"customer roll-forward|revenue build|cost build|costs? section|"
                        r"depreciation schedule|depreciation build|franchise block|shared block|"
                        r"consolidated revenue table|laid by|the (?:revenue|cost|location) build", re.I)
MARKERS_CS = re.compile(r"\b(COSTS|REVENUE|DEPRECIATION SCHEDULE|CONSOLIDATED FINANCIALS|NET WORKING CAPITAL)\b")
class _M:
    @staticmethod
    def search(t): return MARKERS_CI.search(t) or MARKERS_CS.search(t)
MARKERS = _M
PLACEHOLDER = re.compile(r"<([^<>\n]{3,160})>")
NOISE = re.compile(r"^(this col|prior col|same col|scale|n|k|x|R|T|brand|banner|segment|stream|"
                   r"issuer|caption|name|quote|unit|driver|path to .*|Registrant name|Company|"
                   r"workspace|ISO|number of year-steps|Product \d|Stream \d.*|Bucket \d.*)$", re.I)

def _load_audit_helpers():
    src = (ROOT / "scripts" / "audit.py").read_text()
    block = src[src.index("# ---- Lays when"):src.index('if __name__ == "__main__":')]
    ns = {"re": re}
    exec(block, ns)
    return ns["layout_rows"], ns["lays_valid"]

om_layout_rows, om_lays_valid = _load_audit_helpers()


def stage_files():
    for d in STAGE_DIRS:
        for p in sorted((ROOT / d).rglob("*.md")):
            rel = p.relative_to(ROOT).as_posix()
            if rel in ROUTERS: continue
            if "/net-working-capital/" in "/" + rel and rel.count("/") == 2 and rel.endswith("NWC.md"):
                continue  # the driver maps are dependency lists themselves
            yield rel, p

def laid_labels(text):
    """Row labels this file lays: layout lines `  <label>   (<tag>)   [...]` and table rows."""
    labels = set()
    for ln in text.splitlines():
        m = re.match(r"^\s{0,8}([A-Z][^\[\]|]*?)\s{2,}\(", ln)
        if m: labels.add(m.group(1).strip().rstrip("`"))
        m = re.match(r"^\|\s*`([^`]+)`", ln)
        if m: labels.add(m.group(1).strip())
    return labels

def dependencies(text):
    """Rows declared in a `## Dependencies` (or `### Dependencies`) table."""
    m = re.search(r"^#{2,3} Dependencies.*?$(.*?)(?=^#{2,3} |\Z)", text, re.S | re.M)
    rows = []
    if not m: return rows
    for ln in m.group(1).splitlines():
        if ln.startswith("|") and not ln.startswith("|---") and "Row" not in ln.split("|")[1]:
            rows.append(ln.split("|")[1].replace("*", "").strip())
    return rows

OWN = {"depreciation-schedule": ["depreciation build", "depreciation schedule", "DEPRECIATION SCHEDULE"],
       "consolidated-financials": ["CONSOLIDATED FINANCIALS", "consolidated revenue table"],
       "net-working-capital": ["NET WORKING CAPITAL"], "costs": ["COSTS", "cost build", "costs section"],
       "revenue": ["REVENUE"]}

def _own(rel, t):
    top = rel.split("/")[0]
    low = t.lower()
    return any(o.lower() in low for o in OWN.get(top, [])) and not MARKERS_CI.search(
        re.sub("|".join(re.escape(o) for o in OWN.get(top, [])), "", t, flags=re.I))

def cross_refs(text, laid, rel=""):
    refs = {}
    for ph in PLACEHOLDER.findall(text):
        if rel and _own(rel, ph) and not MARKERS_CS.search(re.sub("|".join(re.escape(o) for o in OWN.get(rel.split("/")[0], [])), "", ph)):
            continue
        t = re.sub(r",? ?(this|prior|same|base|proj(?:ection)?) (col(?:umn)?|year)[a-z ()]*", "", ph).strip()
        if NOISE.match(t): continue
        cross = bool(MARKERS.search(t))
        if not cross:
            for c in CONTRACT:
                if c.lower() in t.lower() and c not in laid and c != "Revenue from <Stream>":
                    cross = True
        if cross:
            refs[t] = refs.get(t, 0) + 1
    return refs

def covered(ref, deps):
    """A reference is covered when every word of some declared row's label appears in it.
    Candidates per declared row: each backticked label, each parenthesised alias, and the
    plain text with 'for the brand/banner' and similar filler removed."""
    words_r = set(re.findall(r"[a-z0-9&%-]+", ref.lower()))
    stop = {"for", "the", "brand", "banner", "segment", "a", "as", "row", "rows", "line", "lines",
            "under", "issuer", "issuer's", "captions", "caption", "each", "every", "reported", "in",
            "table", "and", "or", "of", "to", "this", "that", "its", "an"}
    for d in deps:
        groups = [g for grp in re.findall(r"\(([^()]+)\)", d) for g in grp.split(";")]
        cands = re.findall(r"`([^`]+)`", d) + groups + [re.sub(r"`[^`]*`|\([^()]*\)", " ", d)]
        for c in cands:
            ws = set(re.findall(r"[a-z0-9&%-]+", c.lower())) - stop
            if ws and ws <= words_r:
                return True
    return False

def main():
    strict = "--strict" in sys.argv
    total_undeclared = 0
    lays_problems = 0
    sketch_only = []
    for rel, p in stage_files():
        text = p.read_text()
        # Lays when: vocabulary, sketch ⊆ tables, own <row> references laid or declared
        rows = om_layout_rows(text)
        table_labels = {l for labs, *_ in rows for l in labs}
        for labs, lays, ln, *_ in rows:
            if not om_lays_valid(lays):
                print(f"{rel}:{ln}  LAYS-WHEN  unknown value {lays!r}"); lays_problems += 1
        if rows:
            # sketch data rows: `  <label>   (<tag>)   [...]` with a real units tag; label-only
            # header lines, series captions and example lines are not rows
            TAG = r"\((USD|%|days|years|x\)|sq ft|people|users|pairs|units|locations|stores|restaurants|units in)"
            sketch = set()
            for ln in text.splitlines():
                m = re.match(r"^\s{0,8}([A-Z][^\[\]|←]*?)\s{2,}" + TAG, ln)
                if m:
                    l = m.group(1).strip().rstrip("`")
                    if "<" in l or "…" in l or re.search(r" - [Aa]nnual| - [Tt]hree| - [Yy]ears? ", l): continue
                    sketch.add(l)
            tl = {t.lower() for t in table_labels}
            for l in sorted(sketch):
                if l.lower() not in tl:
                    sketch_only.append(f"{rel}  SKETCH-ONLY  `{l}`")
        laid = laid_labels(text); deps = dependencies(text); refs = cross_refs(text, laid, rel)
        if not refs: continue
        und = {r: n for r, n in refs.items() if not covered(r, deps)}
        total_undeclared += len(und)
        print(f"\n{rel}  — cross-stage references: {len(refs)}, declared rows: {len(deps)}, undeclared: {len(und)}")
        for r, n in sorted(und.items(), key=lambda x: -x[1]):
            print(f"   UNDECLARED  ×{n:<3} <{r}>")
    print(f"\nTOTAL undeclared cross-stage references: {total_undeclared}")
    print(f"TOTAL Lays-when vocabulary problems: {lays_problems}")
    print(f"sketch rows with no row-table entry (report only, drive to zero): {len(sketch_only)}")
    if "--sketch" in sys.argv:
        for l in sketch_only: print("   " + l)
    if strict and (total_undeclared or lays_problems): sys.exit(1)

if __name__ == "__main__":
    main()
