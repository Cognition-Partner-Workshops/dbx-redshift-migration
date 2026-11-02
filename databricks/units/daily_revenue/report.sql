SELECT CAST(date_trunc('MONTH', order_date) AS DATE) AS order_month,
       sales_channel,
       SUM(order_count)                               AS order_count,
       SUM(revenue)                                   AS revenue
FROM   gold.daily_revenue
GROUP  BY 1, 2
ORDER  BY 1 NULLS LAST, 2 NULLS LAST;
