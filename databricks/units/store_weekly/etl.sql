-- store_weekly: weekly revenue per store.
-- Redshift DATEDIFF(week, a, b) counts Monday week boundaries crossed;
-- Databricks DATEDIFF(week, ...) counts whole 7-day spans, so diff the
-- Monday-truncated dates in days and divide by 7.
CREATE OR REPLACE TABLE gold.store_weekly
CLUSTER BY (store_id, week_start)
AS
SELECT o.store_id,
       CAST(DATE_TRUNC('WEEK', o.order_ts) AS DATE)                       AS week_start,
       DATE_ADD(CAST(DATE_TRUNC('WEEK', o.order_ts) AS DATE), 6)          AS week_end,
       CAST(DATEDIFF(CAST(DATE_TRUNC('WEEK', o.order_ts) AS DATE),
                     CAST(DATE_TRUNC('WEEK', DATE '2025-01-01') AS DATE)) DIV 7 AS BIGINT)
                                                                          AS week_number,
       COUNT(DISTINCT o.order_id)                                         AS order_count,
       SUM(oi.quantity * (oi.unit_price - oi.discount))                   AS revenue
FROM   silver.orders o
JOIN   silver.order_items oi ON oi.order_id = o.order_id
GROUP  BY o.store_id, DATE_TRUNC('WEEK', o.order_ts);
