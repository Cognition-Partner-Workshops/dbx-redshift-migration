-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns an integer (truncated); match it.
SELECT churn_flag,
       COUNT(*)                                AS customers,
       CAST(AVG(days_since_order) AS BIGINT)   AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST;
