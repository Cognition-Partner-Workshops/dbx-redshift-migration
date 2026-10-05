-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED from databricks/semantic/customer_ltv_metrics_validation.sql by tools/sync_job_sql.py — edit the source, then
-- regenerate. The job binds :catalog via the sql_task parameters map;
-- IDENTIFIER() keeps the catalog substitution safe.
USE CATALOG IDENTIFIER(:catalog);

-- In-job assertion: the metric view, grouped by region, must return exactly
-- the legacy report computed directly over gold.customer_ltv.
WITH via_metrics AS (
    SELECT region,
           MEASURE(customers) AS customers,
           MEASURE(orders)    AS orders,
           MEASURE(total_ltv) AS total_ltv,
           MEASURE(avg_ltv)   AS avg_ltv
    FROM semantic.customer_ltv_metrics
    GROUP BY region
),
direct AS (
    SELECT region,
           COUNT(*) AS customers,
           SUM(order_count) AS orders,
           CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
           CAST(CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
                AS DECIMAL(38,2)) AS avg_ltv
    FROM gold.customer_ltv
    GROUP BY region
),
diff AS (
    (SELECT * FROM via_metrics EXCEPT ALL SELECT * FROM direct)
    UNION ALL
    (SELECT * FROM direct EXCEPT ALL SELECT * FROM via_metrics)
)
SELECT CASE
         WHEN (SELECT COUNT(*) FROM direct) = 0
           THEN raise_error('semantic.customer_ltv_metrics: gold.customer_ltv is empty')
         WHEN (SELECT COUNT(*) FROM diff) > 0
           THEN raise_error('semantic.customer_ltv_metrics differs from the customer_ltv report')
         ELSE 'PASS'
       END AS customer_ltv_metrics_check;
