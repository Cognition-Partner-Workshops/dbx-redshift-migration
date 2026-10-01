-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/returns_rate/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- returns_rate: returns per category (Redshift mart.returns_rate -> gold.returns_rate).
-- return_rate_int keeps Redshift INT/INT integer division via DIV.
-- return_pct keeps Redshift NUMERIC(14,4) / NUMERIC(14,4) semantics: quotient
-- truncated toward zero at scale 15, then * 100, returned as DECIMAL(38,15).
CREATE OR REPLACE TABLE gold.returns_rate AS
WITH category_qty AS (
    SELECT p.category,
           SUM(oi.quantity)              AS sold_sum,
           COALESCE(SUM(r.quantity), 0)  AS returned_sum
    FROM   silver.order_items oi
    JOIN   silver.products p   ON p.product_id    = oi.product_id
    LEFT JOIN silver.returns r ON r.order_item_id = oi.order_item_id
    GROUP  BY p.category
),
numeric_qty AS (
    SELECT category,
           sold_sum,
           returned_sum,
           CAST(returned_sum AS DECIMAL(14,4)) AS returned_num,
           CAST(sold_sum AS DECIMAL(14,4))     AS sold_num
    FROM   category_qty
)
SELECT category,
       CAST(sold_sum AS BIGINT)               AS sold_qty,
       CAST(returned_sum AS BIGINT)           AS returned_qty,
       CAST(returned_sum DIV sold_sum AS BIGINT) AS return_rate_int,
       CAST(
           (CAST(returned_num DIV sold_num AS DECIMAL(15,0))
            + CAST((CAST(returned_num % sold_num AS DECIMAL(14,4)) * CAST(1000000000000000 AS DECIMAL(16,0)))
                   DIV sold_num AS DECIMAL(15,0)) * 0.000000000000001)
           * 100
       AS DECIMAL(38,15))                     AS return_pct
FROM   numeric_qty
ORDER  BY category;
