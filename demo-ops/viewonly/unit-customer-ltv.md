# Live customer_ltv conversion session

The Databricks persona starts this session in the Partner Demo - ViewOnly org while the audience watches. The session converts one unit from its Lakebridge draft, hits the `aov` failure at the default tolerance and fixes the converted SQL until the unit matches the golden.

## Session settings

| Setting | Value |
| --- | --- |
| Repository | Cognition-Partner-Workshops/dbx-redshift-migration |
| Branch | `unit/run-2/customer_ltv`, cut from `migration-run-2` after the orchestrator commits the Lakebridge drafts and the foundation |
| Environment variables | `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_WAREHOUSE_ID`, and `MIG_CATALOG` if the catalog differs from `mig_redshift_dev` |
| Writable paths | `databricks/units/customer_ltv/etl.sql`, `databricks/units/customer_ltv/report.sql`, `.migration/evidence/customer_ltv.json`, the `customer_ltv` row of `.migration/coverage.md` |
| Read-only paths | `legacy/`, `golden/`, `data/seed/`, `validation/` (including `validation/tolerances.yaml`), `.migration/units.yaml`, `.migration/06_decisions.md` |

## Prompt

```
Convert the customer_ltv unit of Cognition-Partner-Workshops/dbx-redshift-migration for migration run migration-run-2. Create branch unit/run-2/customer_ltv from migration-run-2 and read AGENTS.md and the customer_ltv entry in .migration/units.yaml first.

Use the environment variables DATABRICKS_HOST, DATABRICKS_TOKEN and DATABRICKS_WAREHOUSE_ID, and MIG_CATALOG if it is set. Refer to them by name only and never print a token.

You may write only databricks/units/customer_ltv/etl.sql, databricks/units/customer_ltv/report.sql, .migration/evidence/customer_ltv.json and the customer_ltv row of .migration/coverage.md. Do not edit legacy/, golden/, data/seed/, validation/, validation/tolerances.yaml, .migration/units.yaml or .migration/06_decisions.md, and do not copy SQL from migration-run-1 or from any unit/customer_ltv branch.

Step 1. Copy the Lakebridge draft from .migration/lakebridge/transpiled/customer_ltv/ into databricks/units/customer_ltv/ and change only what is needed for it to run on Databricks: core. becomes silver., mart. becomes gold., and f_clean_phone becomes silver.f_clean_phone. Keep the native AVG for aov exactly as Lakebridge wrote it.

Step 2. Run make validate UNIT=customer_ltv. Post the result in this session as a table of output, check, status, matched rows and mismatched rows, and quote the mismatches_by_column entry and three sample mismatches for aov (golden value against Databricks value). The tolerance is decimal_abs 0.000001 with string_rstrip false, so a difference in the third decimal place is a FAIL.

Step 3. Explain the aov mismatch from the samples before changing anything. Compare the golden values with the Databricks AVG result rounded half up, rounded half even and truncated toward zero, count how many of the 1,500 rows each rule matches, and post that table. Then fix the converted SQL so it reproduces the Redshift result exactly. If the region column fails because CREATE TABLE AS widened CHAR(4), declare the table with explicit DDL and region CHAR(4).

Step 4. Rerun make validate UNIT=customer_ltv until both outputs PASS, at most three full attempts. Post the second table, which should show 1,500 of 1,500 rows for customer_ltv and 6 of 6 rows for report, and run git diff --stat migration-run-2 -- validation/ golden/ legacy/ data/seed/ to show that output is empty.

Step 5. Commit the two SQL files and .migration/evidence/customer_ltv.json, fill the customer_ltv row of .migration/coverage.md with the observed outcome and the fix pattern, and open a pull request into migration-run-2 with both validation tables and the rounding comparison in the body. Do not merge it.
```

## Expected story and source of each fact

In the legacy SQL, `aov` averages `unit_price - discount`, and `unit_price` is `NUMERIC(12,2)` in the core tables. Run 1 measured the behaviour in PR #25 and PR #15 on `migration-run-1`, and run 2 has to measure it again. PR #25 kept the native `AVG` and failed with 1,308 mismatched `aov` rows and 6 mismatched `report.avg_ltv` rows, because Databricks returns six decimal places (golden `193.25` against `193.253556`). PR #15 compared rounding rules against the golden and found 669 mismatches with half up, 662 with half even and 0 with truncation toward zero, so Redshift truncated the average to two places. The fix that passed in run 1 was `CAST((SUM(x) * 100) DIV NULLIF(COUNT(x), 0) AS DECIMAL(36,0)) * 0.01` with explicit DDL and `region CHAR(4)`.

PR #25 also recorded that the `region` column passed with `CREATE TABLE AS`, because `silver.customers.region` was already `CHAR(4)` with padding. The CHAR widening the demo record describes may not appear on run 2, and the presenter should only point at it if the first validation shows it.
