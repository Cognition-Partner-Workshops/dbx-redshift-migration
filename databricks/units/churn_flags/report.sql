-- BI report: churn flag distribution.
-- Redshift AVG over an INT column returns a BIGINT truncated toward zero;
-- SUM DIV COUNT keeps that integer result (NULL when every value is NULL).
SELECT churn_flag,
       COUNT(*)                                                 AS customers,
       CAST(SUM(days_since_order) DIV COUNT(days_since_order) AS BIGINT) AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST;
