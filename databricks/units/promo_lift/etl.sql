-- promo_lift: order-value distribution per channel (MEDIAN + PERCENTILE_CONT).
-- Redshift MEDIAN / PERCENTILE_CONT over NUMERIC(38,2) interpolate exactly and
-- return NUMERIC at the input scale, truncating extra digits. Databricks
-- median / percentile_cont return DOUBLE, so the continuous percentile is
-- computed here in exact DECIMAL arithmetic:
--   pos = 1 + p * (n - 1) over non-NULL values ordered ascending
--   value = v[floor(pos)] + (pos - floor(pos)) * (v[ceil(pos)] - v[floor(pos)])
-- truncated toward zero to scale 2.
CREATE OR REPLACE TABLE gold.promo_lift AS
WITH order_totals AS (
    SELECT o.order_id,
           o.sales_channel,
           CAST(SUM(oi.quantity * (oi.unit_price - oi.discount)) AS DECIMAL(38,2)) AS order_total
    FROM   silver.orders o
    JOIN   silver.order_items oi ON oi.order_id = o.order_id
    GROUP  BY o.order_id, o.sales_channel
),
ranked AS (
    SELECT sales_channel,
           order_total,
           ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY order_total ASC NULLS LAST, order_id) AS rn,
           COUNT(order_total) OVER (PARTITION BY sales_channel) AS value_count
    FROM   order_totals
),
positions AS (
    SELECT sales_channel,
           COUNT(*)                                   AS order_count,
           MAX(value_count)                           AS value_count,
           1 + CAST(0.5 AS DECIMAL(2,1)) * (MAX(value_count) - 1) AS median_pos,
           1 + CAST(0.9 AS DECIMAL(2,1)) * (MAX(value_count) - 1) AS p90_pos
    FROM   ranked
    GROUP  BY sales_channel
),
bounds AS (
    SELECT p.sales_channel,
           p.order_count,
           p.median_pos - FLOOR(p.median_pos) AS median_frac,
           p.p90_pos - FLOOR(p.p90_pos)       AS p90_frac,
           MAX(CASE WHEN r.rn = FLOOR(p.median_pos) THEN r.order_total END) AS median_lo,
           MAX(CASE WHEN r.rn = CEIL(p.median_pos)  THEN r.order_total END) AS median_hi,
           MAX(CASE WHEN r.rn = FLOOR(p.p90_pos)    THEN r.order_total END) AS p90_lo,
           MAX(CASE WHEN r.rn = CEIL(p.p90_pos)     THEN r.order_total END) AS p90_hi
    FROM   positions p
    JOIN   ranked r
      ON   r.sales_channel <=> p.sales_channel
     AND   r.rn <= p.value_count
    GROUP  BY p.sales_channel, p.order_count, p.median_pos, p.p90_pos
),
interpolated AS (
    SELECT b.sales_channel,
           b.order_count,
           b.median_lo + b.median_frac * (b.median_hi - b.median_lo) AS median_exact,
           b.p90_lo + b.p90_frac * (b.p90_hi - b.p90_lo)             AS p90_exact
    FROM   bounds b
)
SELECT p.sales_channel,
       p.order_count,
       CAST(CASE WHEN i.median_exact < 0 THEN CEIL(i.median_exact, 2) ELSE FLOOR(i.median_exact, 2) END
            AS DECIMAL(38,2)) AS median_order_value,
       CAST(CASE WHEN i.p90_exact < 0 THEN CEIL(i.p90_exact, 2) ELSE FLOOR(i.p90_exact, 2) END
            AS DECIMAL(38,2)) AS p90_order_value
FROM   positions p
LEFT   JOIN interpolated i ON i.sales_channel <=> p.sales_channel
ORDER  BY p.sales_channel;
