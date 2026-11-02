-- Redshift AVG(NUMERIC(_,2)) truncates to scale 2.
SELECT region,
       COUNT(*)                            AS customers,
       SUM(order_count)                    AS orders,
       SUM(ltv)                            AS total_ltv,
       CAST(floor(AVG(ltv), 2) AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region NULLS LAST;
