-- promo_lift: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.promo_lift) = 4, 'promo_lift.promo_lift: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT sales_channel) FROM gold.promo_lift) = 4, 'promo_lift.promo_lift: count_distinct(sales_channel)');
SELECT assert_true((SELECT COUNT(sales_channel) FROM gold.promo_lift) = 4, 'promo_lift.promo_lift: non_null(sales_channel)');
SELECT assert_true((SELECT SUM(order_count) FROM gold.promo_lift) = 20000, 'promo_lift.promo_lift: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM gold.promo_lift) = 4, 'promo_lift.promo_lift: non_null(order_count)');
SELECT assert_true((SELECT SUM(median_order_value) FROM gold.promo_lift) = 1597.99, 'promo_lift.promo_lift: sum(median_order_value)');
SELECT assert_true((SELECT COUNT(median_order_value) FROM gold.promo_lift) = 4, 'promo_lift.promo_lift: non_null(median_order_value)');
SELECT assert_true((SELECT SUM(p90_order_value) FROM gold.promo_lift) = 4406.80, 'promo_lift.promo_lift: sum(p90_order_value)');
SELECT assert_true((SELECT COUNT(p90_order_value) FROM gold.promo_lift) = 4, 'promo_lift.promo_lift: non_null(p90_order_value)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 4, 'promo_lift.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT sales_channel) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 4, 'promo_lift.report: count_distinct(sales_channel)');
SELECT assert_true((SELECT COUNT(sales_channel) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 4, 'promo_lift.report: non_null(sales_channel)');
SELECT assert_true((SELECT SUM(order_count) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 20000, 'promo_lift.report: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 4, 'promo_lift.report: non_null(order_count)');
SELECT assert_true((SELECT SUM(median_order_value) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 1597.99, 'promo_lift.report: sum(median_order_value)');
SELECT assert_true((SELECT COUNT(median_order_value) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 4, 'promo_lift.report: non_null(median_order_value)');
SELECT assert_true((SELECT SUM(p90_order_value) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 4406.80, 'promo_lift.report: sum(p90_order_value)');
SELECT assert_true((SELECT COUNT(p90_order_value) FROM (-- BI report: channel order-value distribution as published.
SELECT sales_channel, order_count, median_order_value, p90_order_value
FROM   gold.promo_lift
ORDER  BY sales_channel ASC NULLS LAST)) = 4, 'promo_lift.report: non_null(p90_order_value)');
