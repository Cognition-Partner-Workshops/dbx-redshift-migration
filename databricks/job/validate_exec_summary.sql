-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED from databricks/orchestration/validation.sql by tools/sync_job_sql.py — edit the source, then
-- regenerate. The job binds :catalog via the sql_task parameters map;
-- IDENTIFIER() keeps the catalog substitution safe.
USE CATALOG IDENTIFIER(:catalog);

-- orchestration: assert_true checks on gold.exec_summary vs the committed
-- golden (golden/orchestration/exec_summary.csv). Coarse gate; the row-level
-- oracle remains `make validate UNIT=orchestration`. Unqualified names: run
-- under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: row_count = 1');
SELECT assert_true((SELECT MAX(snapshot_label) FROM gold.exec_summary) = 'as_of_2025-12-31', 'orchestration.exec_summary: snapshot_label');
SELECT assert_true((SELECT MAX(as_of_date) FROM gold.exec_summary) = DATE '2025-12-31', 'orchestration.exec_summary: as_of_date');
SELECT assert_true((SELECT MAX(avg_customer_ltv) FROM gold.exec_summary) = 7029.21, 'orchestration.exec_summary: avg_customer_ltv = 7029.21 (Redshift truncated AVG)');
SELECT assert_true((SELECT MAX(total_revenue) FROM gold.exec_summary) = 10543825.25, 'orchestration.exec_summary: total_revenue');
SELECT assert_true((SELECT MAX(total_orders) FROM gold.exec_summary) = 20000, 'orchestration.exec_summary: total_orders');
SELECT assert_true((SELECT MAX(overall_return_pct) FROM gold.exec_summary) = 5.013772053897100, 'orchestration.exec_summary: overall_return_pct');
SELECT assert_true((SELECT MAX(avg_ship_hours) FROM gold.exec_summary) = 71.2551, 'orchestration.exec_summary: avg_ship_hours');
