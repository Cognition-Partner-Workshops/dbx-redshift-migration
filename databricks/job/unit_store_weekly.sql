-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/store_weekly/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- store_weekly: weekly revenue per store.
-- Weeks start on Monday (Redshift DATE_TRUNC('week')). week_start is derived
-- with timezone-free DATE arithmetic so TIMESTAMP_NTZ order_ts never shifts.
-- Redshift DATEDIFF(week, a, b) counts week boundaries crossed; both sides
-- are Monday-aligned here, so the boundary count is the day difference DIV 7.
CREATE OR REPLACE TABLE gold.store_weekly
CLUSTER BY (store_id, week_start)
AS
WITH order_lines AS (
    SELECT o.store_id,
           o.order_id,
           DATE_SUB(CAST(o.order_ts AS DATE), WEEKDAY(CAST(o.order_ts AS DATE))) AS week_start,
           oi.quantity * (oi.unit_price - oi.discount)                            AS line_revenue
    FROM   silver.orders o
    JOIN   silver.order_items oi ON oi.order_id = o.order_id
)
SELECT store_id,
       week_start,
       DATE_ADD(week_start, 6)                                                   AS week_end,
       CAST(DATEDIFF(DAY,
                     DATE_SUB(DATE '2025-01-01', WEEKDAY(DATE '2025-01-01')),
                     week_start) DIV 7 AS BIGINT)                                AS week_number,
       COUNT(DISTINCT order_id)                                                  AS order_count,
       SUM(line_revenue)                                                         AS revenue
FROM   order_lines
GROUP  BY store_id, week_start
ORDER  BY store_id, week_start;
