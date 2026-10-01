-- daily_revenue: revenue and order count per day x channel.
-- Source: legacy/redshift/units/daily_revenue/etl.sql (mart.daily_revenue -> gold.daily_revenue).
-- TRUNC(ts)::DATE -> CAST(ts AS DATE); DISTSTYLE ALL dropped; SORTKEY -> liquid clustering.
-- Redshift SUM over NUMERIC(p,2) yields NUMERIC(38,2); cast keeps scale 2 and precision 38.
CREATE OR REPLACE TABLE gold.daily_revenue
USING DELTA
CLUSTER BY (order_date, sales_channel)
AS
SELECT CAST(o.order_ts AS DATE)                                          AS order_date,
       o.sales_channel                                                   AS sales_channel,
       COUNT(DISTINCT o.order_id)                                        AS order_count,
       CAST(SUM(oi.quantity * (oi.unit_price - oi.discount)) AS DECIMAL(38,2)) AS revenue
FROM   silver.orders o
JOIN   silver.order_items oi ON oi.order_id = o.order_id
GROUP  BY CAST(o.order_ts AS DATE), o.sales_channel;
