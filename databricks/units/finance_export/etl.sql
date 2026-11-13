-- finance_export: monthly finance rollup on the fiscal calendar
-- (fiscal year starts Feb 1) via f_fiscal_qtr.
-- The legacy UNLOAD export (export.sql) has no Databricks SQL equivalent and
-- was never executed at capture; it is out of scope for this unit.
CREATE OR REPLACE TABLE gold.finance_monthly AS
SELECT CAST(DATE_TRUNC('MONTH', o.order_ts) AS DATE)                  AS month,
       CASE WHEN EXTRACT(MONTH FROM o.order_ts) >= 2
            THEN CAST(EXTRACT(YEAR FROM o.order_ts) AS INT)
            ELSE CAST(EXTRACT(YEAR FROM o.order_ts) AS INT) - 1
       END                                                       AS fiscal_year,
       silver.f_fiscal_qtr(CAST(o.order_ts AS DATE))             AS fiscal_qtr,
       COUNT(DISTINCT o.order_id)                                AS order_count,
       SUM(oi.quantity * (oi.unit_price - oi.discount))          AS revenue
FROM   silver.orders o
JOIN   silver.order_items oi ON oi.order_id = o.order_id
GROUP  BY 1, 2, 3;
