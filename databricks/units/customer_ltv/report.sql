-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output and the grouping key.
-- Redshift AVG over NUMERIC(38,2) truncates toward zero at scale 2 (Databricks
-- AVG would return scale 6 and CAST rounds half-up), and Redshift sorts NULLs
-- last ascending.
SELECT region,
       COUNT(*)                        AS customers,
       SUM(order_count)                AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2))           AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST;
