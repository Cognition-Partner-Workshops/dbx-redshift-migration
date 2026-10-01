-- BI report: monthly revenue by channel.
-- Source: legacy/redshift/units/daily_revenue/report.sql. Redshift sorts NULLs last in ASC order.
SELECT CAST(DATE_TRUNC('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                              AS order_count,
       CAST(SUM(revenue) AS DECIMAL(38,2))           AS revenue
FROM   gold.daily_revenue
GROUP  BY CAST(DATE_TRUNC('MONTH', order_date) AS DATE), sales_channel
ORDER  BY order_month ASC NULLS LAST, sales_channel ASC NULLS LAST;
