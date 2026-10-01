-- BI report: the rollup as published (NULL grouping columns included).
-- Redshift sorts NULLs last for ASC; made explicit for Databricks.
SELECT grouping_id, region, state, order_count, revenue
FROM   gold.geo_rollup
ORDER  BY grouping_id ASC NULLS LAST, region ASC NULLS LAST, state ASC NULLS LAST;
