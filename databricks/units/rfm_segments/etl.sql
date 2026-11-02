-- rfm_segments: Redshift sorts NULLs high (ASC -> NULLS LAST, DESC -> NULLS
-- FIRST); Databricks defaults to the opposite, so every NTILE ORDER BY is explicit.
-- DATEDIFF(day, a, b) on DATEs -> datediff(b, a).
CREATE OR REPLACE TABLE gold.rfm_segments
CLUSTER BY (customer_id)
AS
WITH metrics AS (
    SELECT c.customer_id,
           datediff(DATE '2025-12-31', CAST(MAX(o.order_ts) AS DATE))     AS recency_days,
           COUNT(DISTINCT o.order_id)                                    AS frequency,
           COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0) AS monetary
    FROM   silver.customers c
    LEFT JOIN silver.orders      o  ON o.customer_id = c.customer_id
    LEFT JOIN silver.order_items oi ON oi.order_id   = o.order_id
    GROUP  BY c.customer_id
),
tiles AS (
    SELECT customer_id,
           recency_days,
           frequency,
           monetary,
           NTILE(5) OVER (ORDER BY recency_days ASC NULLS LAST, customer_id ASC NULLS LAST) AS r_tile,
           NTILE(5) OVER (ORDER BY frequency DESC NULLS FIRST,  customer_id ASC NULLS LAST) AS f_tile,
           NTILE(5) OVER (ORDER BY monetary  DESC NULLS FIRST,  customer_id ASC NULLS LAST) AS m_tile
    FROM   metrics
)
SELECT customer_id,
       recency_days,
       frequency,
       monetary,
       r_tile,
       f_tile,
       m_tile,
       CAST(r_tile AS STRING) || CAST(f_tile AS STRING) || CAST(m_tile AS STRING) AS rfm_segment
FROM   tiles;
