output "catalog_name" {
  description = "Provisioned catalog."
  value       = databricks_catalog.migration.name
}

output "schema_ids" {
  description = "Medallion schema ids keyed by schema name."
  value       = { for name, schema in databricks_schema.medallion : name => schema.id }
}

output "raw_volume_path" {
  description = "Path of the managed volume holding the seed CSVs."
  value       = databricks_volume.raw.volume_path
}

output "warehouse_id" {
  description = "SQL warehouse id supplied via var.warehouse_id (null when unset)."
  value       = var.warehouse_id
}
