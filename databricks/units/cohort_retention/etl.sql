-- cohort_retention: customer cohorts by first order month x month offset retention matrix.
-- Converted from legacy/redshift/units/cohort_retention/etl.sql.
-- Redshift TEMP TABLE steps (tmp_cohorts, tmp_activity) become CTEs; SORTKEY becomes CLUSTER BY.
CREATE OR REPLACE TABLE gold.cohort_retention (
    cohort_month   DATE,
    month_offset   INT,
    cohort_size    BIGINT,
    active_buyers  BIGINT
) CLUSTER BY (cohort_month, month_offset);

INSERT INTO gold.cohort_retention
WITH tmp_cohorts AS (
    SELECT customer_id,
           CAST(DATE_TRUNC('MONTH', MIN(order_ts)) AS DATE) AS cohort_month
    FROM   silver.orders
    GROUP  BY customer_id
),
tmp_activity AS (
    SELECT c.cohort_month,
           CAST(DATEDIFF(MONTH, c.cohort_month, CAST(DATE_TRUNC('MONTH', o.order_ts) AS DATE)) AS INT) AS month_offset,
           COUNT(DISTINCT c.customer_id) AS active_buyers
    FROM   silver.orders o
    JOIN   tmp_cohorts c ON c.customer_id = o.customer_id
    GROUP  BY c.cohort_month,
              CAST(DATEDIFF(MONTH, c.cohort_month, CAST(DATE_TRUNC('MONTH', o.order_ts) AS DATE)) AS INT)
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM   tmp_cohorts
    GROUP  BY cohort_month
)
SELECT s.cohort_month,
       s.month_offset,
       sz.cohort_size,
       s.active_buyers
FROM   tmp_activity s
JOIN   cohort_sizes sz ON sz.cohort_month = s.cohort_month;
