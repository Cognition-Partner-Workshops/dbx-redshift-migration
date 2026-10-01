-- daily_revenue: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.daily_revenue) = 1460, 'daily_revenue.daily_revenue: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT order_date) FROM gold.daily_revenue) = 365, 'daily_revenue.daily_revenue: count_distinct(order_date)');
SELECT assert_true((SELECT COUNT(order_date) FROM gold.daily_revenue) = 1460, 'daily_revenue.daily_revenue: non_null(order_date)');
SELECT assert_true((SELECT COUNT(DISTINCT sales_channel) FROM gold.daily_revenue) = 4, 'daily_revenue.daily_revenue: count_distinct(sales_channel)');
SELECT assert_true((SELECT COUNT(sales_channel) FROM gold.daily_revenue) = 1460, 'daily_revenue.daily_revenue: non_null(sales_channel)');
SELECT assert_true((SELECT SUM(order_count) FROM gold.daily_revenue) = 20000, 'daily_revenue.daily_revenue: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM gold.daily_revenue) = 1460, 'daily_revenue.daily_revenue: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM gold.daily_revenue) = 10543825.25, 'daily_revenue.daily_revenue: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM gold.daily_revenue) = 1460, 'daily_revenue.daily_revenue: non_null(revenue)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 48, 'daily_revenue.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT order_month) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 12, 'daily_revenue.report: count_distinct(order_month)');
SELECT assert_true((SELECT COUNT(order_month) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 48, 'daily_revenue.report: non_null(order_month)');
SELECT assert_true((SELECT COUNT(DISTINCT sales_channel) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 4, 'daily_revenue.report: count_distinct(sales_channel)');
SELECT assert_true((SELECT COUNT(sales_channel) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 48, 'daily_revenue.report: non_null(sales_channel)');
SELECT assert_true((SELECT SUM(order_count) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 20000, 'daily_revenue.report: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 48, 'daily_revenue.report: non_null(order_count)');
SELECT assert_true((SELECT SUM(revenue) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 10543825.25, 'daily_revenue.report: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM (-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST)) = 48, 'daily_revenue.report: non_null(revenue)');
