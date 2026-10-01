-- cohort_retention: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.cohort_retention) = 65, 'cohort_retention.cohort_retention: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT cohort_month) FROM gold.cohort_retention) = 8, 'cohort_retention.cohort_retention: count_distinct(cohort_month)');
SELECT assert_true((SELECT COUNT(cohort_month) FROM gold.cohort_retention) = 65, 'cohort_retention.cohort_retention: non_null(cohort_month)');
SELECT assert_true((SELECT SUM(month_offset) FROM gold.cohort_retention) = 266, 'cohort_retention.cohort_retention: sum(month_offset)');
SELECT assert_true((SELECT COUNT(month_offset) FROM gold.cohort_retention) = 65, 'cohort_retention.cohort_retention: non_null(month_offset)');
SELECT assert_true((SELECT SUM(cohort_size) FROM gold.cohort_retention) = 15668, 'cohort_retention.cohort_retention: sum(cohort_size)');
SELECT assert_true((SELECT COUNT(cohort_size) FROM gold.cohort_retention) = 65, 'cohort_retention.cohort_retention: non_null(cohort_size)');
SELECT assert_true((SELECT SUM(active_buyers) FROM gold.cohort_retention) = 11499, 'cohort_retention.cohort_retention: sum(active_buyers)');
SELECT assert_true((SELECT COUNT(active_buyers) FROM gold.cohort_retention) = 65, 'cohort_retention.cohort_retention: non_null(active_buyers)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 65, 'cohort_retention.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT cohort_month) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 8, 'cohort_retention.report: count_distinct(cohort_month)');
SELECT assert_true((SELECT COUNT(cohort_month) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 65, 'cohort_retention.report: non_null(cohort_month)');
SELECT assert_true((SELECT SUM(month_offset) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 266, 'cohort_retention.report: sum(month_offset)');
SELECT assert_true((SELECT COUNT(month_offset) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 65, 'cohort_retention.report: non_null(month_offset)');
SELECT assert_true((SELECT SUM(cohort_size) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 15668, 'cohort_retention.report: sum(cohort_size)');
SELECT assert_true((SELECT COUNT(cohort_size) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 65, 'cohort_retention.report: non_null(cohort_size)');
SELECT assert_true((SELECT SUM(active_buyers) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 11499, 'cohort_retention.report: sum(active_buyers)');
SELECT assert_true((SELECT COUNT(active_buyers) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 65, 'cohort_retention.report: non_null(active_buyers)');
SELECT assert_true((SELECT SUM(retention_pct) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 5154.70, 'cohort_retention.report: sum(retention_pct)');
SELECT assert_true((SELECT COUNT(retention_pct) FROM (-- BI report: retention share per cohort x month offset.
SELECT cohort_month,
       month_offset,
       cohort_size,
       active_buyers,
       ROUND(100.0 * active_buyers / cohort_size, 2) AS retention_pct
FROM   gold.cohort_retention
ORDER  BY cohort_month NULLS LAST, month_offset NULLS LAST)) = 65, 'cohort_retention.report: non_null(retention_pct)');
