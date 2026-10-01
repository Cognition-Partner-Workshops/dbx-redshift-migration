-- customer_ltv: lifetime revenue per customer (source: legacy/redshift/units/customer_ltv/etl.sql).
-- Explicit DDL keeps region as CHAR(4) with the padding written by foundation
-- (CTAS would widen it to VARCHAR). DISTKEY/SORTKEY map to liquid clustering.
-- Redshift AVG over NUMERIC(p,2) returns NUMERIC(38,2) truncated toward zero, so
-- aov is computed exactly as (SUM * 100) DIV COUNT, then rescaled to two places.
CREATE OR REPLACE TABLE gold.customer_ltv (
    customer_id BIGINT,
    region      CHAR(4),
    clean_phone STRING,
    order_count BIGINT,
    ltv         DECIMAL(38,2),
    aov         DECIMAL(38,2)
)
USING DELTA
CLUSTER BY (customer_id);

INSERT INTO gold.customer_ltv
SELECT c.customer_id,
       c.region,
       silver.f_clean_phone(c.phone)                                    AS clean_phone,
       COUNT(DISTINCT o.order_id)                                       AS order_count,
       COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0)    AS ltv,
       CAST((SUM(oi.unit_price - oi.discount) * 100)
            DIV NULLIF(COUNT(oi.unit_price - oi.discount), 0) AS DECIMAL(36,0)) * 0.01 AS aov
FROM   silver.customers c
LEFT JOIN silver.orders      o  ON o.customer_id = c.customer_id
LEFT JOIN silver.order_items oi ON oi.order_id   = o.order_id
GROUP  BY c.customer_id, c.region, c.phone;
