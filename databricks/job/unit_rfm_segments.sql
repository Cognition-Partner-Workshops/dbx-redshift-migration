-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/rfm_segments/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- rfm_segments: NTILE(5) over recency/frequency/monetary as of '2025-12-31',
-- including customers with NULL metrics (NULL ordering matters).
-- Redshift sorts NULL as the largest value (ASC -> NULLS LAST, DESC -> NULLS FIRST);
-- Databricks defaults are the opposite, so null ordering is explicit here.
-- DISTKEY/SORTKEY(customer_id) -> liquid clustering on customer_id.
CREATE OR REPLACE TABLE gold.rfm_segments
CLUSTER BY (customer_id)
AS
WITH metrics AS (
    SELECT c.customer_id,
           DATEDIFF(DAY, CAST(MAX(o.order_ts) AS DATE), DATE '2025-12-31')                         AS recency_days,
           COUNT(DISTINCT o.order_id)                                                              AS frequency,
           CAST(COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0) AS DECIMAL(38, 2))  AS monetary
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
           CAST(NTILE(5) OVER (ORDER BY recency_days ASC  NULLS LAST,  customer_id ASC NULLS LAST) AS BIGINT) AS r_tile,
           CAST(NTILE(5) OVER (ORDER BY frequency    DESC NULLS FIRST, customer_id ASC NULLS LAST) AS BIGINT) AS f_tile,
           CAST(NTILE(5) OVER (ORDER BY monetary     DESC NULLS FIRST, customer_id ASC NULLS LAST) AS BIGINT) AS m_tile
    FROM   metrics
)
SELECT customer_id,
       recency_days,
       frequency,
       monetary,
       r_tile,
       f_tile,
       m_tile,
       CAST(CAST(r_tile AS STRING) || CAST(f_tile AS STRING) || CAST(m_tile AS STRING) AS VARCHAR(3)) AS rfm_segment
FROM   tiles
ORDER  BY customer_id;
