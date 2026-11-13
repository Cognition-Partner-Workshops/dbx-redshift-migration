-- returns_rate: returns per category. return_rate_int is Redshift INT/INT
-- integer division (DIV in Databricks); return_pct is a DECIMAL division.
DROP TABLE IF EXISTS gold.returns_rate;
CREATE TABLE gold.returns_rate AS
SELECT p.category,
       CAST(SUM(oi.quantity) AS BIGINT)                                  AS sold_qty,
       CAST(COALESCE(SUM(r.quantity), 0) AS BIGINT)                      AS returned_qty,
       COALESCE(SUM(r.quantity), 0) DIV SUM(oi.quantity)                 AS return_rate_int,
       (CAST(COALESCE(SUM(r.quantity), 0) AS DECIMAL(14, 4))
           / CAST(SUM(oi.quantity) AS DECIMAL(14, 4))) * 100             AS return_pct
FROM   silver.order_items oi
JOIN   silver.products p    ON p.product_id    = oi.product_id
LEFT JOIN silver.returns r  ON r.order_item_id = oi.order_item_id
GROUP  BY p.category;
