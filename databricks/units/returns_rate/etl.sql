-- returns_rate: return_rate_int keeps Redshift integer division (DIV);
-- return_pct is NUMERIC(14,4)/NUMERIC(14,4), which Redshift truncates to scale 15.
CREATE OR REPLACE TABLE gold.returns_rate AS
SELECT p.category,
       CAST(SUM(oi.quantity) AS BIGINT)                        AS sold_qty,
       CAST(COALESCE(SUM(r.quantity), 0) AS BIGINT)            AS returned_qty,
       COALESCE(SUM(r.quantity), 0) DIV SUM(oi.quantity)       AS return_rate_int,
       CAST(floor(CAST(COALESCE(SUM(r.quantity), 0) AS DECIMAL(14,4))
                  / CAST(SUM(oi.quantity) AS DECIMAL(14,4)), 15) AS DECIMAL(38,15)) * 100 AS return_pct
FROM   silver.order_items oi
JOIN   silver.products p   ON p.product_id     = oi.product_id
LEFT JOIN silver.returns r ON r.order_item_id  = oi.order_item_id
GROUP  BY p.category;
