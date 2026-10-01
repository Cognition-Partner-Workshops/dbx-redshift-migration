output "catalog_name" {
  description = "Provisioned catalog (MIG_CATALOG for the validation harness)."
  value       = databricks_catalog.migration.name
}

output "schemas" {
  description = "Fully qualified medallion schema names keyed by layer."
  value       = { for layer, schema in databricks_schema.medallion : layer => "${schema.catalog_name}.${schema.name}" }
}

output "warehouse_id" {
  description = "SQL warehouse id (DATABRICKS_WAREHOUSE_ID / BUNDLE_VAR_warehouse_id)."
  value       = databricks_sql_endpoint.validation.id
}

output "warehouse_jdbc_url" {
  description = "JDBC URL of the validation warehouse."
  value       = databricks_sql_endpoint.validation.jdbc_url
}
