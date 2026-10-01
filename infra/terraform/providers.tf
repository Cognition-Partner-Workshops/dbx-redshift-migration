terraform {
  required_version = ">= 1.10.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.95.0"
    }
  }
}

# Auth is read from the environment only: DATABRICKS_HOST plus either
# DATABRICKS_TOKEN or DATABRICKS_CLIENT_ID / DATABRICKS_CLIENT_SECRET.
provider "databricks" {
  host = var.databricks_host
}
