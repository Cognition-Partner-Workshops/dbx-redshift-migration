variable "catalog" {
  description = "Unity Catalog catalog to provision (see .migration/allowed_targets.json)."
  type        = string
  default     = "mig_redshift_dev"

  validation {
    condition     = contains(["mig_redshift_dev", "mig_redshift"], var.catalog)
    error_message = "catalog must be one of the allowed targets: mig_redshift_dev, mig_redshift."
  }
}

variable "warehouse_id" {
  description = "Optional SQL warehouse id, passed through to outputs for the DAB / validation harness (DATABRICKS_WAREHOUSE_ID)."
  type        = string
  default     = null
}
