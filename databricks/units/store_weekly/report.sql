-- BI report: store weekly totals and span.
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
ORDER  BY s.store_id;
