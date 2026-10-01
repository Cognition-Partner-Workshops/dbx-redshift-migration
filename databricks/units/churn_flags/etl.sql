-- churn_flags: set-based Databricks SQL replacement for the Redshift plpgsql
-- procedure sp_build_churn_flags (FOR loop over a temp table + CALL).
-- One INSERT ... SELECT computes every customer's flag as of the fixed
-- literal DATE '2025-12-31'. Redshift `date - date` yields an INT day count,
-- matched here by DATEDIFF(end, start).
CREATE OR REPLACE TABLE gold.churn_flags (
    customer_id      BIGINT,
    last_order_date  DATE,
    days_since_order INT,
    churn_flag       STRING
)
CLUSTER BY (customer_id);

INSERT INTO gold.churn_flags
WITH last_orders AS (
    SELECT c.customer_id,
           CAST(MAX(o.order_ts) AS DATE) AS last_order_date
    FROM   silver.customers c
    LEFT JOIN silver.orders o ON o.customer_id = c.customer_id
    GROUP  BY c.customer_id
),
aged AS (
    SELECT customer_id,
           last_order_date,
           DATEDIFF(DATE '2025-12-31', last_order_date) AS days_since_order
    FROM   last_orders
)
SELECT customer_id,
       last_order_date,
       CAST(days_since_order AS INT) AS days_since_order,
       CASE
           WHEN last_order_date IS NULL THEN 'never_ordered'
           WHEN days_since_order > 180  THEN 'churned'
           WHEN days_since_order > 90   THEN 'at_risk'
           ELSE 'active'
       END AS churn_flag
FROM   aged;
