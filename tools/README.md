# tools/ — repository dev tooling (not part of the plugin bundle)

Nothing here ships: `install.sh` bundles only `skills/`. These are checks run on the
repository before a commit or release.

- `dependency_audit.py` — for every operating-model stage file, lists each reference to a
  row laid by another stage and checks it against that file's `## Dependencies` table
  (`skills/operating-model/SKILL.md`, Step 4.2). Heuristic by design; an undeclared
  cross-stage reference is a defect in the referencing file. `make lint` runs it in strict
  mode.
