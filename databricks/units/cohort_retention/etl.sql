-- cohort_retention: Redshift TEMP TABLE steps folded into CTEs; DATEDIFF(month)
-- retention matrix computed as calendar-month boundary count.
CREATE OR REPLACE TABLE gold.cohort_retention (
    cohort_month   DATE,
    month_offset   INT,
    cohort_size    BIGINT,
    active_buyers  BIGINT
)
CLUSTER BY (cohort_month, month_offset);

INSERT OVERWRITE gold.cohort_retention
WITH cohorts AS (
    SELECT customer_id,
           CAST(DATE_TRUNC('MONTH', MIN(order_ts)) AS DATE) AS cohort_month
    FROM   silver.orders
    GROUP  BY customer_id
),
activity AS (
    SELECT c.cohort_month,
           CAST((YEAR(om.order_month) - YEAR(c.cohort_month)) * 12
                + (MONTH(om.order_month) - MONTH(c.cohort_month)) AS INT) AS month_offset,
           COUNT(DISTINCT c.customer_id)                                  AS active_buyers
    FROM   (SELECT customer_id,
                   CAST(DATE_TRUNC('MONTH', order_ts) AS DATE) AS order_month
            FROM   silver.orders) om
    JOIN   cohorts c ON c.customer_id = om.customer_id
    GROUP  BY c.cohort_month,
              CAST((YEAR(om.order_month) - YEAR(c.cohort_month)) * 12
                   + (MONTH(om.order_month) - MONTH(c.cohort_month)) AS INT)
),
sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM   cohorts
    GROUP  BY cohort_month
)
SELECT s.cohort_month,
       s.month_offset,
       sz.cohort_size,
       s.active_buyers
FROM   activity s
JOIN   sizes sz ON sz.cohort_month = s.cohort_month;
