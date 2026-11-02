-- churn_flags: plpgsql procedure (temp table + row-by-row FOR loop + CALL)
-- collapsed into one set-based CTAS; the temp table becomes a CTE.
-- DATE - DATE (days) -> datediff(end, start).
CREATE OR REPLACE TABLE gold.churn_flags (
    customer_id      BIGINT,
    last_order_date  DATE,
    days_since_order INT,
    churn_flag       STRING
) CLUSTER BY (customer_id);

INSERT INTO gold.churn_flags
WITH last_orders AS (
    SELECT c.customer_id,
           CAST(MAX(o.order_ts) AS DATE) AS last_order_date
    FROM   silver.customers c
    LEFT JOIN silver.orders o ON o.customer_id = c.customer_id
    GROUP  BY c.customer_id
)
SELECT customer_id,
       last_order_date,
       datediff(DATE '2025-12-31', last_order_date) AS days_since_order,
       CASE
           WHEN last_order_date IS NULL                              THEN 'never_ordered'
           WHEN datediff(DATE '2025-12-31', last_order_date) > 180   THEN 'churned'
           WHEN datediff(DATE '2025-12-31', last_order_date) > 90    THEN 'at_risk'
           ELSE 'active'
       END AS churn_flag
FROM   last_orders;
