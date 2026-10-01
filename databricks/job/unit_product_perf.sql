-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/product_perf/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- product_perf: per-product sales with the top-3 store regions by units.
-- Redshift LISTAGG(region, ',') WITHIN GROUP (ORDER BY units DESC, region)
-- becomes a collected array sorted on the same ROW_NUMBER rank, so duplicates
-- and NULL skipping match LISTAGG. CHAR(4) region values are emitted without
-- trailing blanks (Redshift CHAR -> VARCHAR semantics) and ::VARCHAR(64)
-- truncates to 64 characters.
CREATE OR REPLACE TABLE gold.product_perf AS
WITH per_store AS (
    SELECT oi.product_id,
           s.region,
           SUM(oi.quantity) AS units
    FROM   silver.order_items oi
    JOIN   silver.orders o ON o.order_id = oi.order_id
    JOIN   silver.stores s ON s.store_id = o.store_id
    GROUP  BY oi.product_id, s.region
),
ranked AS (
    SELECT product_id, region, units,
           ROW_NUMBER() OVER (PARTITION BY product_id
                              ORDER BY units DESC NULLS FIRST, region ASC NULLS LAST) AS rn
    FROM   per_store
),
top_stores AS (
    SELECT product_id,
           CASE WHEN COUNT(region) > 0 THEN
               LEFT(
                   ARRAY_JOIN(
                       TRANSFORM(
                           ARRAY_SORT(COLLECT_LIST(NAMED_STRUCT('rn', rn, 'region', RTRIM(region)))),
                           x -> x.region),
                       ','),
                   64)
           END AS codes
    FROM   ranked
    WHERE  rn <= 3
    GROUP  BY product_id
),
agg AS (
    SELECT product_id,
           CAST(SUM(quantity) AS BIGINT)                                  AS units_sold,
           CAST(SUM(quantity * (unit_price - discount)) AS DECIMAL(18, 2)) AS revenue
    FROM   silver.order_items
    GROUP  BY product_id
)
SELECT p.product_id,
       p.category,
       COALESCE(a.units_sold, CAST(0 AS BIGINT))         AS units_sold,
       COALESCE(a.revenue, CAST(0 AS DECIMAL(18, 2)))    AS revenue,
       ts.codes                                          AS top_stores
FROM   silver.products p
LEFT JOIN agg        a  ON a.product_id = p.product_id
LEFT JOIN top_stores ts ON ts.product_id = p.product_id;
