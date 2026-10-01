-- customer_ltv: lifetime revenue per customer (source: legacy/redshift/units/customer_ltv/etl.sql).
-- silver.customers.region is CHAR(4) holding Redshift's padded values ("NE  "),
-- so the padding carries through unchanged. DISTKEY/SORTKEY and the CTAS
-- ORDER BY are dropped: Delta has no row-order guarantee and goldens are keyed
-- by customer_id. f_clean_phone is registered in silver by the foundation.
-- Redshift AVG over NUMERIC(12,2) returns NUMERIC(38,2) truncated toward zero
-- (Databricks AVG keeps scale 6 and casting rounds), so aov is computed exactly
-- as (SUM * 100) DIV COUNT, rescaled to two places.
CREATE OR REPLACE TABLE gold.customer_ltv AS
SELECT c.customer_id,
       c.region,
       silver.f_clean_phone(c.phone)                                    AS clean_phone,
       COUNT(DISTINCT o.order_id)                                       AS order_count,
       COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0)    AS ltv,
       CAST(
           CAST((SUM(oi.unit_price - oi.discount) * 100)
                DIV NULLIF(COUNT(oi.unit_price - oi.discount), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2))                                            AS aov
FROM   silver.customers c
LEFT JOIN silver.orders      o  ON o.customer_id = c.customer_id
LEFT JOIN silver.order_items oi ON oi.order_id   = o.order_id
GROUP  BY c.customer_id, c.region, c.phone;
