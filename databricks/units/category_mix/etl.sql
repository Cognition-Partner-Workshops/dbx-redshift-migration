-- category_mix: RATIO_TO_REPORT (FLOAT8) -> x / SUM(x) OVER () in DOUBLE.
CREATE OR REPLACE TABLE gold.category_mix AS
SELECT category,
       units_sold,
       revenue,
       CAST(revenue AS DOUBLE) / SUM(CAST(revenue AS DOUBLE)) OVER () AS revenue_share
FROM (
    SELECT p.category,
           SUM(oi.quantity)                                  AS units_sold,
           SUM(oi.quantity * (oi.unit_price - oi.discount))  AS revenue
    FROM   silver.order_items oi
    JOIN   silver.products p ON p.product_id = oi.product_id
    GROUP  BY p.category
) x;
