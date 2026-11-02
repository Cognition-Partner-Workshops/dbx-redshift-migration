-- store_weekly: weekly revenue per store.
DROP TABLE IF EXISTS mart.store_weekly;

CREATE
    TABLE mart.store_weekly AS
    SELECT
        o.store_id,
        CAST(DATE_TRUNC('WEEK', o.order_ts) AS DATE) AS week_start,
        CAST(DATE_ADD(day, 6, CAST(DATE_TRUNC('WEEK', o.order_ts) AS TIMESTAMP)) AS DATE) AS week_end,
        DATEDIFF(week, CAST('2025-01-01' AS DATE), CAST(DATE_TRUNC('WEEK', o.order_ts) AS DATE)) AS week_number,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * (oi.unit_price - oi.discount)) AS revenue
    FROM
        core.orders AS o JOIN core.order_items AS oi ON oi.order_id = o.order_id
        GROUP BY o.store_id, DATE_TRUNC('WEEK', o.order_ts)
    ORDER BY o.store_id NULLS LAST, week_start NULLS LAST;