-- store_weekly: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.store_weekly) = 2120, 'store_weekly.store_weekly: row_count');
SELECT assert_true((SELECT SUM(store_id) FROM gold.store_weekly) = 43460, 'store_weekly.store_weekly: sum(store_id)');
SELECT assert_true((SELECT COUNT(store_id) FROM gold.store_weekly) = 2120, 'store_weekly.store_weekly: non_null(store_id)');
SELECT assert_true((SELECT COUNT(DISTINCT week_start) FROM gold.store_weekly) = 53, 'store_weekly.store_weekly: count_distinct(week_start)');
SELECT assert_true((SELECT COUNT(week_start) FROM gold.store_weekly) = 2120, 'store_weekly.store_weekly: non_null(week_start)');
SELECT assert_true((SELECT COUNT(DISTINCT week_end) FROM gold.store_weekly) = 53, 'store_weekly.store_weekly: count_distinct(week_end)');
SELECT assert_true((SELECT COUNT(week_end) FROM gold.store_weekly) = 2120, 'store_weekly.store_weekly: non_null(week_end)');
SELECT assert_true((SELECT SUM(week_number) FROM gold.store_weekly) = 55120, 'store_weekly.store_weekly: sum(week_number)');
SELECT assert_true((SELECT COUNT(week_number) FROM gold.store_weekly) = 2120, 'store_weekly.store_weekly: non_null(week_number)');
SELECT assert_true((SELECT SUM(order_count) FROM gold.store_weekly) = 20000, 'store_weekly.store_weekly: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM gold.store_weekly) = 2120, 'store_weekly.store_weekly: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM gold.store_weekly) = 10543825.25, 'store_weekly.store_weekly: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM gold.store_weekly) = 2120, 'store_weekly.store_weekly: non_null(revenue)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 40, 'store_weekly.report: row_count');
SELECT assert_true((SELECT SUM(store_id) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 820, 'store_weekly.report: sum(store_id)');
SELECT assert_true((SELECT COUNT(store_id) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 40, 'store_weekly.report: non_null(store_id)');
SELECT assert_true((SELECT COUNT(DISTINCT region) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 6, 'store_weekly.report: count_distinct(region)');
SELECT assert_true((SELECT COUNT(region) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 40, 'store_weekly.report: non_null(region)');
SELECT assert_true((SELECT SUM(active_weeks) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 2120, 'store_weekly.report: sum(active_weeks)');
SELECT assert_true((SELECT COUNT(active_weeks) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 40, 'store_weekly.report: non_null(active_weeks)');
SELECT assert_true((SELECT SUM(order_count) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 20000, 'store_weekly.report: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 40, 'store_weekly.report: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 10543825.25, 'store_weekly.report: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM (-- BI report: store weekly totals and span.
-- week_start is Monday-aligned, so Redshift DATEDIFF(week) boundary counting
-- equals the day difference DIV 7.
SELECT s.store_id,
       s.region,
       CAST(DATEDIFF(DAY, MIN(w.week_start), MAX(w.week_start)) DIV 7 + 1 AS BIGINT) AS active_weeks,
       SUM(w.order_count)                                                           AS order_count,
       SUM(w.revenue)                                                               AS revenue
FROM   gold.store_weekly w
JOIN   silver.stores s ON s.store_id = w.store_id
GROUP  BY s.store_id, s.region
ORDER  BY s.store_id)) = 40, 'store_weekly.report: non_null(revenue)');
