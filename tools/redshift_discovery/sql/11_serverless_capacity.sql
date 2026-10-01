-- Copied from Lakebridge 0.15.2 resources/assessments/redshift/sql/3_rs_nodes_serverless.sql
WITH cte AS (
    SELECT compute_capacity AS rs_nodes_type,
           SUM(compute_seconds)::DOUBLE PRECISION AS compute_seconds
    FROM sys_serverless_usage
    WHERE compute_capacity > 0
    GROUP BY 1
)
SELECT 'rs_nodes' AS set_name,
       CONCAT(rs_nodes_type, ' RPUs') AS rs_nodes_type,
       0 AS rs_number_of_nodes,
       compute_seconds
FROM cte
