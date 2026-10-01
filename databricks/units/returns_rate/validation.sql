-- returns_rate: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.returns_rate) = 6, 'returns_rate.returns_rate: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT category) FROM gold.returns_rate) = 6, 'returns_rate.returns_rate: count_distinct(category)');
SELECT assert_true((SELECT COUNT(category) FROM gold.returns_rate) = 6, 'returns_rate.returns_rate: non_null(category)');
SELECT assert_true((SELECT SUM(sold_qty) FROM gold.returns_rate) = 53732, 'returns_rate.returns_rate: sum(sold_qty)');
SELECT assert_true((SELECT COUNT(sold_qty) FROM gold.returns_rate) = 6, 'returns_rate.returns_rate: non_null(sold_qty)');
SELECT assert_true((SELECT SUM(returned_qty) FROM gold.returns_rate) = 2694, 'returns_rate.returns_rate: sum(returned_qty)');
SELECT assert_true((SELECT COUNT(returned_qty) FROM gold.returns_rate) = 6, 'returns_rate.returns_rate: non_null(returned_qty)');
SELECT assert_true((SELECT SUM(return_rate_int) FROM gold.returns_rate) = 0, 'returns_rate.returns_rate: sum(return_rate_int)');
SELECT assert_true((SELECT COUNT(return_rate_int) FROM gold.returns_rate) = 6, 'returns_rate.returns_rate: non_null(return_rate_int)');
SELECT assert_true((SELECT SUM(return_pct) FROM gold.returns_rate) = 30.087923647717000, 'returns_rate.returns_rate: sum(return_pct)');
SELECT assert_true((SELECT COUNT(return_pct) FROM gold.returns_rate) = 6, 'returns_rate.returns_rate: non_null(return_pct)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'returns_rate.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT category) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'returns_rate.report: count_distinct(category)');
SELECT assert_true((SELECT COUNT(category) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'returns_rate.report: non_null(category)');
SELECT assert_true((SELECT SUM(sold_qty) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 53732, 'returns_rate.report: sum(sold_qty)');
SELECT assert_true((SELECT COUNT(sold_qty) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'returns_rate.report: non_null(sold_qty)');
SELECT assert_true((SELECT SUM(returned_qty) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 2694, 'returns_rate.report: sum(returned_qty)');
SELECT assert_true((SELECT COUNT(returned_qty) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'returns_rate.report: non_null(returned_qty)');
SELECT assert_true((SELECT SUM(return_rate_int) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 0, 'returns_rate.report: sum(return_rate_int)');
SELECT assert_true((SELECT COUNT(return_rate_int) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'returns_rate.report: non_null(return_rate_int)');
SELECT assert_true((SELECT SUM(return_pct) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 30.087923647717000, 'returns_rate.report: sum(return_pct)');
SELECT assert_true((SELECT COUNT(return_pct) FROM (-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'returns_rate.report: non_null(return_pct)');
