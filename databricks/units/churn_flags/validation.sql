-- churn_flags: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.churn_flags) = 1500, 'churn_flags.churn_flags: row_count');
SELECT assert_true((SELECT SUM(customer_id) FROM gold.churn_flags) = 1125750, 'churn_flags.churn_flags: sum(customer_id)');
SELECT assert_true((SELECT COUNT(customer_id) FROM gold.churn_flags) = 1500, 'churn_flags.churn_flags: non_null(customer_id)');
SELECT assert_true((SELECT COUNT(DISTINCT last_order_date) FROM gold.churn_flags) = 114, 'churn_flags.churn_flags: count_distinct(last_order_date)');
SELECT assert_true((SELECT COUNT(last_order_date) FROM gold.churn_flags) = 1354, 'churn_flags.churn_flags: non_null(last_order_date)');
SELECT assert_true((SELECT SUM(days_since_order) FROM gold.churn_flags) = 33522, 'churn_flags.churn_flags: sum(days_since_order)');
SELECT assert_true((SELECT COUNT(days_since_order) FROM gold.churn_flags) = 1354, 'churn_flags.churn_flags: non_null(days_since_order)');
SELECT assert_true((SELECT COUNT(DISTINCT churn_flag) FROM gold.churn_flags) = 4, 'churn_flags.churn_flags: count_distinct(churn_flag)');
SELECT assert_true((SELECT COUNT(churn_flag) FROM gold.churn_flags) = 1500, 'churn_flags.churn_flags: non_null(churn_flag)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST)) = 4, 'churn_flags.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT churn_flag) FROM (-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST)) = 4, 'churn_flags.report: count_distinct(churn_flag)');
SELECT assert_true((SELECT COUNT(churn_flag) FROM (-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST)) = 4, 'churn_flags.report: non_null(churn_flag)');
SELECT assert_true((SELECT SUM(customers) FROM (-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST)) = 1500, 'churn_flags.report: sum(customers)');
SELECT assert_true((SELECT COUNT(customers) FROM (-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST)) = 4, 'churn_flags.report: non_null(customers)');
SELECT assert_true((SELECT SUM(avg_days_since_order) FROM (-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST)) = 340, 'churn_flags.report: sum(avg_days_since_order)');
SELECT assert_true((SELECT COUNT(avg_days_since_order) FROM (-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST)) = 3, 'churn_flags.report: non_null(avg_days_since_order)');
