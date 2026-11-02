-- BI report: store weekly totals and span.
SELECT
    s.store_id,
    s.region,
    DATEDIFF(week, MIN(w.week_start), MAX(w.week_start)) + 1 AS active_weeks,
    SUM(w.order_count) AS order_count,
    SUM(w.revenue) AS revenue
FROM mart.store_weekly AS w JOIN core.stores AS s ON s.store_id = w.store_id GROUP BY s.store_id, s.region
ORDER BY s.store_id NULLS LAST;