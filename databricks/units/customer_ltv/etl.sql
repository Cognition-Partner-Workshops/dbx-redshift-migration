-- customer_ltv: region stays CHAR(4) (blank-padded, e.g. 'NE  ') as in Redshift;
-- Redshift AVG(NUMERIC(_,2)) truncates to scale 2; Databricks widens the scale,
-- so floor(x, 2) (values are non-negative) then cast back.
CREATE OR REPLACE TABLE gold.customer_ltv
CLUSTER BY (customer_id)
AS
SELECT c.customer_id,
       rpad(c.region, 4, ' ')                                          AS region,
       silver.f_clean_phone(c.phone)                                   AS clean_phone,
       COUNT(DISTINCT o.order_id)                                      AS order_count,
       COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0)   AS ltv,
       CAST(floor(AVG(oi.unit_price - oi.discount), 2) AS DECIMAL(38,2)) AS aov
FROM   silver.customers c
LEFT JOIN silver.orders      o  ON o.customer_id = c.customer_id
LEFT JOIN silver.order_items oi ON oi.order_id   = o.order_id
GROUP  BY c.customer_id, c.region, c.phone;
