-- customer_ltv: lifetime revenue per customer (source: legacy/redshift/units/customer_ltv/etl.sql).
-- silver.customers.region is CHAR(4) and stores Redshift's padded values ("NE  "),
-- so the padding carries through unchanged. DISTKEY/SORTKEY and the CTAS ORDER BY
-- are dropped: Delta has no row-order guarantee and goldens are keyed by customer_id.
-- f_clean_phone is registered in silver by the foundation (databricks/udfs/).
CREATE OR REPLACE TABLE gold.customer_ltv AS
SELECT c.customer_id,
       c.region,
       silver.f_clean_phone(c.phone)                                    AS clean_phone,
       COUNT(DISTINCT o.order_id)                                       AS order_count,
       COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0)    AS ltv,
       AVG(oi.unit_price - oi.discount)                                 AS aov
FROM   silver.customers c
LEFT JOIN silver.orders      o  ON o.customer_id = c.customer_id
LEFT JOIN silver.order_items oi ON oi.order_id   = o.order_id
GROUP  BY c.customer_id, c.region, c.phone;
