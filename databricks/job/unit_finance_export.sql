-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/finance_export/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- finance_export: monthly finance rollup on the fiscal calendar
-- (fiscal year starts Feb 1) via silver.f_fiscal_qtr.
-- Converted from legacy/redshift/units/finance_export/etl.sql.
-- The legacy UNLOAD (export.sql) is not part of this unit's ETL.
CREATE OR REPLACE TABLE gold.finance_monthly AS
SELECT CAST(date_trunc('MONTH', o.order_ts) AS DATE)            AS month,
       CASE WHEN extract(MONTH FROM o.order_ts) >= 2
            THEN CAST(extract(YEAR FROM o.order_ts) AS INT)
            ELSE CAST(extract(YEAR FROM o.order_ts) AS INT) - 1
       END                                                      AS fiscal_year,
       silver.f_fiscal_qtr(CAST(o.order_ts AS DATE))            AS fiscal_qtr,
       COUNT(DISTINCT o.order_id)                               AS order_count,
       SUM(oi.quantity * (oi.unit_price - oi.discount))         AS revenue
FROM   silver.orders o
JOIN   silver.order_items oi ON oi.order_id = o.order_id
GROUP  BY 1, 2, 3;
