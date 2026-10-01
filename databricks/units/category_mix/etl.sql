-- category_mix: revenue share per product category.
-- Redshift RATIO_TO_REPORT(revenue) OVER () returns FLOAT8; reproduce as the
-- exact NUMERIC row value divided by the exact NUMERIC grand total, in DOUBLE.
CREATE OR REPLACE TABLE gold.category_mix AS
SELECT category,
       units_sold,
       revenue,
       CAST(revenue AS DOUBLE) / CAST(SUM(revenue) OVER () AS DOUBLE) AS revenue_share
FROM (
    SELECT p.category,
           CAST(SUM(oi.quantity) AS BIGINT)                                         AS units_sold,
           CAST(SUM(oi.quantity * (oi.unit_price - oi.discount)) AS DECIMAL(38,2))  AS revenue
    FROM   silver.order_items oi
    JOIN   silver.products p ON p.product_id = oi.product_id
    GROUP  BY p.category
) x;
