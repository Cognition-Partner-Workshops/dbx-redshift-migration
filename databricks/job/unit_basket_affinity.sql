-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/basket_affinity/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- basket_affinity: product pairs bought in the same order, support >= 5.
-- Source: legacy/redshift/units/basket_affinity/etl.sql (core.x -> silver.x, mart.x -> gold.x).
-- Unordered pairs via b.product_id > a.product_id; NULL product_ids drop out of the
-- inequality join exactly as in Redshift. product_id stays INT, pair_orders is BIGINT.
CREATE OR REPLACE TABLE gold.basket_affinity AS
SELECT a.product_id               AS product_id_a,
       b.product_id               AS product_id_b,
       COUNT(DISTINCT a.order_id) AS pair_orders
FROM   silver.order_items AS a
JOIN   silver.order_items AS b
       ON b.order_id = a.order_id AND b.product_id > a.product_id
GROUP  BY a.product_id, b.product_id
HAVING COUNT(DISTINCT a.order_id) >= 5
ORDER  BY product_id_a ASC NULLS LAST, product_id_b ASC NULLS LAST;
