---
name: migrate-unit
description: Convert one legacy Redshift unit to Databricks SQL as a child migration session.
---

# Migrate one unit

You own exactly one unit (see `.migration/units.yaml`). Branch `unit/<name>`
from `migration-run-N`.

1. Read the unit's entry in `.migration/units.yaml`: legacy files, target_dir,
   reads/writes, outputs and keys, expected_lakebridge, constructs.
2. If a Lakebridge draft exists under `.migration/lakebridge/transpiled/<unit>/`,
   start from it; otherwise hand-convert `legacy/redshift/units/<unit>/etl.sql`
   and `report.sql`.
3. Write only `databricks/units/<name>/etl.sql` and `report.sql`. SQL references
   unqualified `silver.x` / `gold.x`; the harness sets the catalog.
4. Run `make validate UNIT=<name>` until it reports PASS — max 3 full attempts,
   then stop and report.
5. Never edit `legacy/`, `golden/`, `data/seed/`, `validation/` or
   `validation/tolerances.yaml`. Tolerance changes need a human row in
   `.migration/06_decisions.md`.
6. Commit `.migration/evidence/<name>.json`, add a coverage row to
   `.migration/coverage.md`, open a PR into `migration-run-N`.
