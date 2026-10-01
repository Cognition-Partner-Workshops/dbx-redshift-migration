-- finance_export: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.finance_monthly) = 12, 'finance_export.finance_monthly: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT month) FROM gold.finance_monthly) = 12, 'finance_export.finance_monthly: count_distinct(month)');
SELECT assert_true((SELECT COUNT(month) FROM gold.finance_monthly) = 12, 'finance_export.finance_monthly: non_null(month)');
SELECT assert_true((SELECT SUM(fiscal_year) FROM gold.finance_monthly) = 24299, 'finance_export.finance_monthly: sum(fiscal_year)');
SELECT assert_true((SELECT COUNT(fiscal_year) FROM gold.finance_monthly) = 12, 'finance_export.finance_monthly: non_null(fiscal_year)');
SELECT assert_true((SELECT COUNT(DISTINCT fiscal_qtr) FROM gold.finance_monthly) = 4, 'finance_export.finance_monthly: count_distinct(fiscal_qtr)');
SELECT assert_true((SELECT COUNT(fiscal_qtr) FROM gold.finance_monthly) = 12, 'finance_export.finance_monthly: non_null(fiscal_qtr)');
SELECT assert_true((SELECT SUM(order_count) FROM gold.finance_monthly) = 20000, 'finance_export.finance_monthly: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM gold.finance_monthly) = 12, 'finance_export.finance_monthly: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM gold.finance_monthly) = 10543825.25, 'finance_export.finance_monthly: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM gold.finance_monthly) = 12, 'finance_export.finance_monthly: non_null(revenue)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 5, 'finance_export.report: row_count');
SELECT assert_true((SELECT SUM(fiscal_year) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 10124, 'finance_export.report: sum(fiscal_year)');
SELECT assert_true((SELECT COUNT(fiscal_year) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 5, 'finance_export.report: non_null(fiscal_year)');
SELECT assert_true((SELECT COUNT(DISTINCT fiscal_qtr) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 4, 'finance_export.report: count_distinct(fiscal_qtr)');
SELECT assert_true((SELECT COUNT(fiscal_qtr) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 5, 'finance_export.report: non_null(fiscal_qtr)');
SELECT assert_true((SELECT SUM(order_count) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 20000, 'finance_export.report: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 5, 'finance_export.report: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 10543825.25, 'finance_export.report: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM (-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST)) = 5, 'finance_export.report: non_null(revenue)');
