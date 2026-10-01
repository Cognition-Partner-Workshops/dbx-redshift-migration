-- BI report: top affinities with product names.
-- Null ordering is explicit to match Redshift defaults (ASC NULLS LAST, DESC NULLS FIRST);
-- || propagates NULL as in Redshift.
SELECT b.product_id_a,
       b.product_id_b,
       pa.product_name || ' + ' || pb.product_name AS pair,
       b.pair_orders
FROM   gold.basket_affinity AS b
JOIN   silver.products AS pa ON pa.product_id = b.product_id_a
JOIN   silver.products AS pb ON pb.product_id = b.product_id_b
ORDER  BY b.pair_orders DESC NULLS FIRST, b.product_id_a ASC NULLS LAST, b.product_id_b ASC NULLS LAST
LIMIT  50;
