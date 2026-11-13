-- promo_lift: order-value distribution per channel (MEDIAN + PERCENTILE_CONT).
-- Redshift returns NUMERIC(scale 2) truncated toward zero; Databricks returns DOUBLE,
-- so snap to 6 dp (removes float noise) then truncate to 2 dp.
CREATE OR REPLACE TABLE gold.promo_lift AS
WITH order_totals AS (
    SELECT o.order_id,
           o.sales_channel,
           SUM(oi.quantity * (oi.unit_price - oi.discount)) AS order_total
    FROM   silver.orders o
    JOIN   silver.order_items oi ON oi.order_id = o.order_id
    GROUP  BY o.order_id, o.sales_channel
),
dist AS (
    SELECT sales_channel,
           COUNT(*)                                                                    AS order_count,
           CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_total) AS DECIMAL(38,6)) AS median_raw,
           CAST(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY order_total) AS DECIMAL(38,6)) AS p90_raw
    FROM   order_totals
    GROUP  BY sales_channel
)
SELECT sales_channel,
       order_count,
       CAST(CASE WHEN median_raw < 0 THEN CEIL(median_raw, 2) ELSE FLOOR(median_raw, 2) END AS DECIMAL(38,2)) AS median_order_value,
       CAST(CASE WHEN p90_raw < 0 THEN CEIL(p90_raw, 2) ELSE FLOOR(p90_raw, 2) END AS DECIMAL(38,2))       AS p90_order_value
FROM   dist
ORDER  BY sales_channel;
