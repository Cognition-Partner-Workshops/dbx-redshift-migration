-- churn_flags: Lakebridge draft (procedure + FOR loop + temp table + CALL)
-- rewritten as a single set-based CTAS. Flags are computed as of the fixed
-- literal '2025-12-31'.
CREATE OR REPLACE TABLE gold.churn_flags AS
WITH last_orders AS (
    SELECT c.customer_id,
           CAST(MAX(o.order_ts) AS DATE) AS last_order_date
    FROM   silver.customers c
    LEFT JOIN silver.orders o ON o.customer_id = c.customer_id
    GROUP  BY c.customer_id
)
SELECT CAST(customer_id AS BIGINT)                                  AS customer_id,
       last_order_date,
       CAST(DATEDIFF(DATE'2025-12-31', last_order_date) AS INT)     AS days_since_order,
       CAST(CASE
                WHEN last_order_date IS NULL                              THEN 'never_ordered'
                WHEN DATEDIFF(DATE'2025-12-31', last_order_date) > 180    THEN 'churned'
                WHEN DATEDIFF(DATE'2025-12-31', last_order_date) > 90     THEN 'at_risk'
                ELSE 'active'
            END AS STRING)                                          AS churn_flag
FROM   last_orders;
