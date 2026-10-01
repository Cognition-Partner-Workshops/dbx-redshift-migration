-- Copied from Lakebridge 0.15.2 resources/assessments/redshift/sql/2_rs_managed_storage_gb_serverless.sql
SELECT 'rs_managed_storage_gb' AS set_name,
       ROUND(AVG(data_storage) / 1024.0, 2)::DOUBLE PRECISION AS rs_managed_storage_gb
FROM sys_serverless_usage
