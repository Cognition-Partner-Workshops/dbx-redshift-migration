-- category_mix: revenue share per product category (Redshift RATIO_TO_REPORT -> x / SUM(x) OVER ()).
DROP TABLE IF EXISTS gold.category_mix;

CREATE TABLE gold.category_mix AS
SELECT category,
       units_sold,
       revenue,
       CAST(revenue AS DOUBLE) / SUM(CAST(revenue AS DOUBLE)) OVER () AS revenue_share
FROM (
    SELECT p.category,
           SUM(oi.quantity)                                 AS units_sold,
           SUM(oi.quantity * (oi.unit_price - oi.discount)) AS revenue
    FROM   silver.order_items AS oi
    JOIN   silver.products AS p ON p.product_id = oi.product_id
    GROUP  BY p.category
) AS x
ORDER BY category NULLS LAST;
