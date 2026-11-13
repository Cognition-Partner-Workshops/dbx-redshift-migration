-- daily_revenue: revenue and order count per day x channel.
CREATE OR REPLACE TABLE gold.daily_revenue
CLUSTER BY (order_date, sales_channel)
AS
SELECT
    CAST(o.order_ts AS DATE) AS order_date,
    o.sales_channel AS sales_channel,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity * (oi.unit_price - oi.discount)) AS revenue
FROM silver.orders AS o
JOIN silver.order_items AS oi ON oi.order_id = o.order_id
GROUP BY 1, 2;
