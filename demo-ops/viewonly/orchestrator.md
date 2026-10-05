# Orchestrator session for migration-run-2

The Databricks persona starts this session in the Partner Demo - ViewOnly org. The session plans the run, produces the Lakebridge drafts, validates the foundation and fans waves 1a and 1b out to child sessions. Paste the prompt below as written.

## Session settings

| Setting | Value |
| --- | --- |
| Repository | Cognition-Partner-Workshops/dbx-redshift-migration |
| Branch | `migration-run-2`, already cut from `main` and pushed with no commits of its own |
| Environment variables | `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_WAREHOUSE_ID`, and `MIG_CATALOG` if the catalog differs from `mig_redshift_dev` |
| Read-only paths | `legacy/`, `golden/`, `data/seed/`, `validation/`, `.migration/units.yaml`, `.migration/06_decisions.md` |
| Catalogs | only the ones listed in `.migration/allowed_targets.json` |

## Prompt

```
You are the orchestrator for migration run migration-run-2 of Cognition-Partner-Workshops/dbx-redshift-migration. Check out the existing branch migration-run-2 and read AGENTS.md, .migration/00_context.md, .migration/units.yaml, .migration/allowed_targets.json and demo-ops/ORCHESTRATOR_PROMPT.md before you run anything.

Use the environment variables DATABRICKS_HOST, DATABRICKS_TOKEN and DATABRICKS_WAREHOUSE_ID, and MIG_CATALOG if it is set (the default is mig_redshift_dev). Refer to them by name only and never print a token. Start with databricks current-user me and stop and report the exit code if it fails.

Do not edit legacy/, golden/, data/seed/, validation/, .migration/units.yaml or .migration/06_decisions.md, never merge to main, and write only to the catalogs in .migration/allowed_targets.json. Do not copy any file under databricks/ or .migration/evidence/ from migration-run-1; this run converts every unit from its own Lakebridge draft.

Step 1. Run make db-setup.

Step 2. Run Lakebridge analyze and per-unit transpile as demo-ops/ORCHESTRATOR_PROMPT.md step 2 describes, with --source-tech exactly Redshift. Stage the legacy files under unique names first, because the analyzer keys files by basename: copy every file under legacy/redshift/ into a staging directory outside the repository, joining the source-relative path with two underscores (units/daily_revenue/etl.sql becomes units__daily_revenue__etl.sql). You may read docs/migration/lakebridge-inventory.md on migration-run-1 with git show for the approach. Record the analyze inventory entry count, map the drafts back to .migration/lakebridge/transpiled/<unit>/, and commit .migration/lakebridge/ to migration-run-2.

Step 3. Build wave 0 (foundation) in databricks/foundation/ on migration-run-2: bronze Delta tables from /Volumes/<catalog>/bronze/raw, then typed silver tables that mirror the Redshift core DDL, plus the two UDFs. Run make validate UNIT=foundation until all 10 outputs PASS, at most three full attempts, and commit the evidence file.

Step 4. Launch wave 1a and then wave 1b as parallel child sessions in Fusion mode, one child per unit, exactly as .migration/units.yaml lists them: 5 units in wave 1a (daily_revenue, customer_ltv, geo_rollup, churn_flags, product_perf) and 13 in wave 1b (store_weekly, category_mix, basket_affinity, sessionization, shipping_sla, rfm_segments, promo_lift, payment_mix, returns_rate, attribution, inventory_snapshot, finance_export, cohort_retention). Never run more children at once than the wave width. If I tell you customer_ltv is converted live, launch the other four wave 1a children and wait for the live session's pull request instead of starting a fifth.

Give each child the text of demo-ops/CHILD_UNIT_PROMPT.md with these changes: the run branch is migration-run-2, the child branch is unit/run-2/<unit> because the unit/<unit> names already hold run 1 work, and the child writes only databricks/units/<unit>/etl.sql and report.sql, .migration/evidence/<unit>.json and its own row in .migration/coverage.md. Each child runs make validate UNIT=<unit> until PASS, at most three full attempts, and opens a pull request into migration-run-2. Pass the same environment variable names to every child.

Step 5. Merge nothing yourself. When a wave's pull requests are merged by a human, build wave 2 (orchestration): exec_summary in databricks/orchestration/ and the Lakeflow job nightly_mart_refresh in the bundle under databricks/, converted from legacy/redshift/99_orchestration/refresh_schedule.yaml with the schedule paused in the dev target. Run databricks bundle validate -t dev --var warehouse_id=$DATABRICKS_WAREHOUSE_ID and make validate UNIT=orchestration.

Post a report in this session after each wave: a table of unit, wave, child session link, pull request link, PASS or FAIL per output, and the evidence file path, followed by the Lakebridge inventory entry count and the list of coverage.md rows where the observed outcome differs from the expected one. Every number in the report comes from an evidence file or a command you ran in this session.
```

## Done state

The run is done when 18 `unit/run-2/<unit>` pull requests target `migration-run-2`, each with an evidence file and one coverage row, and the session holds the per-wave report. The fallback for a stalled wave is `migration-run-1` with PR #24 and the open run 1 unit pull requests.
