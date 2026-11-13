-- customer_ltv: lifetime revenue per customer.
-- Converted from legacy/redshift/units/customer_ltv/etl.sql (Lakebridge draft as base).
-- region stays CHAR(4) (blank-padded, as in Redshift). Redshift AVG on
-- NUMERIC(12,2) returns the input scale (2) truncated toward zero, while
-- Databricks AVG widens the scale, so aov is truncated back to 2 decimals.
-- DISTKEY/SORTKEY -> CLUSTER BY.
CREATE OR REPLACE TABLE gold.customer_ltv
CLUSTER BY (customer_id)
AS
WITH agg AS (
    SELECT
        c.customer_id,
        c.region,
        silver.f_clean_phone(c.phone)                                  AS clean_phone,
        COUNT(DISTINCT o.order_id)                                     AS order_count,
        COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0)  AS ltv,
        AVG(oi.unit_price - oi.discount)                               AS aov_raw
    FROM silver.customers AS c
    LEFT JOIN silver.orders AS o ON o.customer_id = c.customer_id
    LEFT JOIN silver.order_items AS oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, c.region, c.phone
)
SELECT
    customer_id,
    region,
    clean_phone,
    order_count,
    ltv,
    CAST(CASE WHEN aov_raw < 0 THEN CEIL(aov_raw, 2) ELSE FLOOR(aov_raw, 2) END AS DECIMAL(38, 2)) AS aov
FROM agg;
