-- Redshift AVG(INT) returns a truncated INT.
SELECT churn_flag,
       COUNT(*)                                AS customers,
       CAST(AVG(days_since_order) AS INT)      AS avg_days_since_order
FROM   gold.churn_flags
GROUP  BY churn_flag
ORDER  BY churn_flag NULLS LAST;
