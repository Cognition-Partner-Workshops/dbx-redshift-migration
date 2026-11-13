-- BI report: the rollup as published (NULL grouping columns included).
SELECT grouping_id, region, state, order_count, revenue
FROM gold.geo_rollup
ORDER BY grouping_id NULLS LAST, region NULLS LAST, state NULLS LAST;
