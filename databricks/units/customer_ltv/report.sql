-- BI report: LTV summary per region (region is CHAR(4) — padding matters).
-- Redshift AVG on a scale-2 numeric keeps scale 2 (truncated toward zero).
SELECT
    region,
    COUNT(*)         AS customers,
    SUM(order_count) AS orders,
    SUM(ltv)         AS total_ltv,
    CAST(CASE WHEN AVG(ltv) < 0 THEN CEIL(AVG(ltv), 2) ELSE FLOOR(AVG(ltv), 2) END AS DECIMAL(38, 2)) AS avg_ltv
FROM gold.customer_ltv
GROUP BY region
ORDER BY region NULLS LAST;
