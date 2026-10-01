-- basket_affinity: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.basket_affinity) = 50, 'basket_affinity.basket_affinity: row_count');
SELECT assert_true((SELECT SUM(product_id_a) FROM gold.basket_affinity) = 5154, 'basket_affinity.basket_affinity: sum(product_id_a)');
SELECT assert_true((SELECT COUNT(product_id_a) FROM gold.basket_affinity) = 50, 'basket_affinity.basket_affinity: non_null(product_id_a)');
SELECT assert_true((SELECT SUM(product_id_b) FROM gold.basket_affinity) = 10425, 'basket_affinity.basket_affinity: sum(product_id_b)');
SELECT assert_true((SELECT COUNT(product_id_b) FROM gold.basket_affinity) = 50, 'basket_affinity.basket_affinity: non_null(product_id_b)');
SELECT assert_true((SELECT SUM(pair_orders) FROM gold.basket_affinity) = 252, 'basket_affinity.basket_affinity: sum(pair_orders)');
SELECT assert_true((SELECT COUNT(pair_orders) FROM gold.basket_affinity) = 50, 'basket_affinity.basket_affinity: non_null(pair_orders)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 50, 'basket_affinity.report: row_count');
SELECT assert_true((SELECT SUM(product_id_a) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 5154, 'basket_affinity.report: sum(product_id_a)');
SELECT assert_true((SELECT COUNT(product_id_a) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 50, 'basket_affinity.report: non_null(product_id_a)');
SELECT assert_true((SELECT SUM(product_id_b) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 10425, 'basket_affinity.report: sum(product_id_b)');
SELECT assert_true((SELECT COUNT(product_id_b) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 50, 'basket_affinity.report: non_null(product_id_b)');
SELECT assert_true((SELECT COUNT(DISTINCT pair) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 50, 'basket_affinity.report: count_distinct(pair)');
SELECT assert_true((SELECT COUNT(pair) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 50, 'basket_affinity.report: non_null(pair)');
SELECT assert_true((SELECT SUM(pair_orders) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 252, 'basket_affinity.report: sum(pair_orders)');
SELECT assert_true((SELECT COUNT(pair_orders) FROM (-- BI report: top affinities with product names.
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
LIMIT  50)) = 50, 'basket_affinity.report: non_null(pair_orders)');
