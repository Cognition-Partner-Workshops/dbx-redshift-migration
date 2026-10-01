-- product_perf: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.product_perf) = 300, 'product_perf.product_perf: row_count');
SELECT assert_true((SELECT SUM(product_id) FROM gold.product_perf) = 45150, 'product_perf.product_perf: sum(product_id)');
SELECT assert_true((SELECT COUNT(product_id) FROM gold.product_perf) = 300, 'product_perf.product_perf: non_null(product_id)');
SELECT assert_true((SELECT COUNT(DISTINCT category) FROM gold.product_perf) = 6, 'product_perf.product_perf: count_distinct(category)');
SELECT assert_true((SELECT COUNT(category) FROM gold.product_perf) = 300, 'product_perf.product_perf: non_null(category)');
SELECT assert_true((SELECT SUM(units_sold) FROM gold.product_perf) = 53732, 'product_perf.product_perf: sum(units_sold)');
SELECT assert_true((SELECT COUNT(units_sold) FROM gold.product_perf) = 300, 'product_perf.product_perf: non_null(units_sold)');
SELECT assert_true((SELECT SUM(revenue) FROM gold.product_perf) = 10543825.25, 'product_perf.product_perf: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM gold.product_perf) = 300, 'product_perf.product_perf: non_null(revenue)');
SELECT assert_true((SELECT COUNT(DISTINCT top_stores) FROM gold.product_perf) = 29, 'product_perf.product_perf: count_distinct(top_stores)');
SELECT assert_true((SELECT COUNT(top_stores) FROM gold.product_perf) = 300, 'product_perf.product_perf: non_null(top_stores)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 6, 'product_perf.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT category) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 6, 'product_perf.report: count_distinct(category)');
SELECT assert_true((SELECT COUNT(category) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 6, 'product_perf.report: non_null(category)');
SELECT assert_true((SELECT SUM(products) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 300, 'product_perf.report: sum(products)');
SELECT assert_true((SELECT COUNT(products) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 6, 'product_perf.report: non_null(products)');
SELECT assert_true((SELECT SUM(units_sold) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 53732, 'product_perf.report: sum(units_sold)');
SELECT assert_true((SELECT COUNT(units_sold) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 6, 'product_perf.report: non_null(units_sold)');
SELECT assert_true((SELECT SUM(revenue) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 10543825.25, 'product_perf.report: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM (-- BI report: category performance.
SELECT category,
       COUNT(*)        AS products,
       SUM(units_sold) AS units_sold,
       SUM(revenue)    AS revenue
FROM   gold.product_perf
GROUP  BY category
ORDER  BY category ASC NULLS LAST)) = 6, 'product_perf.report: non_null(revenue)');
