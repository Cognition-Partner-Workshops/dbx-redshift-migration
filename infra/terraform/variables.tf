variable "environment" {
  description = "Deployment environment: dev (migration runs / validation) or prod (merged, accepted marts)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "databricks_host" {
  description = "Workspace URL. Null falls back to the DATABRICKS_HOST environment variable."
  type        = string
  default     = null
}

variable "catalog_name" {
  description = "Unity Catalog catalog. Null selects the per-environment default (dev: mig_redshift_dev, prod: mig_redshift)."
  type        = string
  default     = null

  validation {
    condition     = var.catalog_name == null ? true : contains(["mig_redshift_dev", "mig_redshift"], var.catalog_name)
    error_message = "catalog_name must be listed in .migration/allowed_targets.json (mig_redshift_dev, mig_redshift)."
  }
}

variable "warehouse_name" {
  description = "SQL warehouse name. Null selects mig-redshift-<environment>."
  type        = string
  default     = null
}

variable "warehouse_size" {
  description = "SQL warehouse cluster size."
  type        = string
  default     = "2X-Small"
}

variable "warehouse_auto_stop_mins" {
  description = "Minutes of inactivity before the warehouse stops."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to the catalog and SQL warehouse."
  type        = map(string)
  default = {
    demo_type   = "redshift"
    source_repo = "dbx-redshift-migration"
  }
}
