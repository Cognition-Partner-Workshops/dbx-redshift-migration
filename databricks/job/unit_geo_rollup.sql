-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/geo_rollup/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- geo_rollup: GROUPING SETS over region / store state. grouping_id keeps the
-- key unique across NULL grouping columns (1 = region, 2 = state, 3 = total).
-- region is CHAR(4) in silver (padded), so padding carries into the mart.
-- revenue keeps Redshift's SUM(NUMERIC) result type NUMERIC(38,2).
CREATE OR REPLACE TABLE gold.geo_rollup AS
SELECT CAST(CASE
              WHEN GROUPING(s.region) = 0 AND GROUPING(s.state) = 1 THEN 1
              WHEN GROUPING(s.region) = 1 AND GROUPING(s.state) = 0 THEN 2
              ELSE 3
            END AS INT)                      AS grouping_id,
       s.region,
       s.state,
       COUNT(DISTINCT o.order_id)            AS order_count,
       CAST(COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0) AS DECIMAL(38,2)) AS revenue
FROM   silver.stores s
LEFT JOIN silver.orders      o  ON o.store_id = s.store_id
LEFT JOIN silver.order_items oi ON oi.order_id = o.order_id
GROUP  BY GROUPING SETS ((s.region), (s.state), ())
ORDER  BY grouping_id ASC NULLS LAST, s.region ASC NULLS LAST, s.state ASC NULLS LAST;
