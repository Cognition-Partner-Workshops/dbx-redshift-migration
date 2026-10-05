-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED from databricks/compat/mart_views.sql by tools/sync_job_sql.py — edit the source, then
-- regenerate. The job binds :catalog via the sql_task parameters map;
-- IDENTIFIER() keeps the catalog substitution safe.
USE CATALOG IDENTIFIER(:catalog);

-- Compatibility views: BI tools addressed the Redshift outputs as mart.<name>.
-- gold.* is canonical; these views let dashboards repoint with zero query
-- changes during cutover. Unqualified names resolve in the caller's catalog.
CREATE SCHEMA IF NOT EXISTS mart
COMMENT 'Compatibility views resolving legacy Redshift mart.* names to gold.* tables';

CREATE OR REPLACE VIEW mart.customer_ltv AS SELECT * FROM gold.customer_ltv;
CREATE OR REPLACE VIEW mart.exec_summary AS SELECT * FROM gold.exec_summary;
