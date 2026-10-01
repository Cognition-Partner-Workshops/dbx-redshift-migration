-- daily_revenue: revenue and order count per day x channel.
DROP TABLE IF EXISTS mart.daily_revenue;

CREATE
    TABLE mart.daily_revenue AS
    SELECT
        CAST(CAST(o.order_ts AS DATE) AS DATE) AS order_date,
        o.sales_channel AS sales_channel,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * (oi.unit_price - oi.discount)) AS revenue
    FROM core.orders AS o JOIN core.order_items AS oi ON oi.order_id = o.order_id GROUP BY 1, 2
    ORDER BY 1 NULLS LAST, 2 NULLS LAST;