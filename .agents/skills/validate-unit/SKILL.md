---
name: validate-unit
description: Run the golden-snapshot validation for one migrated unit on this VM.
---

# Validate a unit

```bash
export DATABRICKS_HOST DATABRICKS_TOKEN DATABRICKS_WAREHOUSE_ID   # MIG_CATALOG optional
make validate UNIT=<name>
```

`validation/validate_unit.py` reads `.migration/units.yaml`, runs the unit's
`databricks/units/<name>/etl.sql` on the dev catalog (`--skip-build` to skip),
fetches each declared output (a `gold.*` table or the converted `report.sql`),
and compares it row-by-row on keys against `golden/<unit>/<output>.csv` using
`validation/tolerances.yaml`. Evidence lands in
`.migration/evidence/<name>.json`; exit code is non-zero on FAIL.

`make validate-all` loops over every manifest unit that already has an
`etl.sql` and fails if any unit fails.
