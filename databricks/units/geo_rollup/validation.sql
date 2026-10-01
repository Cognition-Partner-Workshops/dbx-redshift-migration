-- geo_rollup: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.geo_rollup) = 21, 'geo_rollup.geo_rollup: row_count');
SELECT assert_true((SELECT SUM(grouping_id) FROM gold.geo_rollup) = 37, 'geo_rollup.geo_rollup: sum(grouping_id)');
SELECT assert_true((SELECT COUNT(grouping_id) FROM gold.geo_rollup) = 21, 'geo_rollup.geo_rollup: non_null(grouping_id)');
SELECT assert_true((SELECT COUNT(DISTINCT region) FROM gold.geo_rollup) = 6, 'geo_rollup.geo_rollup: count_distinct(region)');
SELECT assert_true((SELECT COUNT(region) FROM gold.geo_rollup) = 6, 'geo_rollup.geo_rollup: non_null(region)');
SELECT assert_true((SELECT COUNT(DISTINCT state) FROM gold.geo_rollup) = 14, 'geo_rollup.geo_rollup: count_distinct(state)');
SELECT assert_true((SELECT COUNT(state) FROM gold.geo_rollup) = 14, 'geo_rollup.geo_rollup: non_null(state)');
SELECT assert_true((SELECT SUM(order_count) FROM gold.geo_rollup) = 60000, 'geo_rollup.geo_rollup: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM gold.geo_rollup) = 21, 'geo_rollup.geo_rollup: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM gold.geo_rollup) = 31631475.75, 'geo_rollup.geo_rollup: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM gold.geo_rollup) = 21, 'geo_rollup.geo_rollup: non_null(revenue)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 21, 'geo_rollup.report: row_count');
SELECT assert_true((SELECT SUM(grouping_id) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 37, 'geo_rollup.report: sum(grouping_id)');
SELECT assert_true((SELECT COUNT(grouping_id) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 21, 'geo_rollup.report: non_null(grouping_id)');
SELECT assert_true((SELECT COUNT(DISTINCT region) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 6, 'geo_rollup.report: count_distinct(region)');
SELECT assert_true((SELECT COUNT(region) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 6, 'geo_rollup.report: non_null(region)');
SELECT assert_true((SELECT COUNT(DISTINCT state) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 14, 'geo_rollup.report: count_distinct(state)');
SELECT assert_true((SELECT COUNT(state) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 14, 'geo_rollup.report: non_null(state)');
SELECT assert_true((SELECT SUM(order_count) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 60000, 'geo_rollup.report: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 21, 'geo_rollup.report: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 31631475.75, 'geo_rollup.report: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM (-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST)) = 21, 'geo_rollup.report: non_null(revenue)');
