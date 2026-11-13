-- rfm_segments: NTILE(5) over recency/frequency/monetary as of '2025-12-31',
-- including customers with NULL metrics. Redshift sorts NULLs as the largest
-- value (ASC -> NULLS LAST, DESC -> NULLS FIRST); Databricks defaults to the
-- opposite, so NULL ordering is explicit.
CREATE OR REPLACE TABLE gold.rfm_segments AS
WITH metrics AS (
    SELECT c.customer_id,
           DATEDIFF(DATE '2025-12-31', CAST(MAX(o.order_ts) AS DATE))  AS recency_days,
           COUNT(DISTINCT o.order_id)                                    AS frequency,
           CAST(COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0) AS DECIMAL(38,2)) AS monetary
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
           NTILE(5) OVER (ORDER BY recency_days ASC NULLS LAST,  customer_id ASC) AS r_tile,
           NTILE(5) OVER (ORDER BY frequency    DESC NULLS FIRST, customer_id ASC) AS f_tile,
           NTILE(5) OVER (ORDER BY monetary     DESC NULLS FIRST, customer_id ASC) AS m_tile
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
