-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output key. Redshift sorts NULLs last ascending.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       SUM(ltv)         AS total_ltv,
       AVG(ltv)         AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST;
