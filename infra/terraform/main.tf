# Scope: catalog, medallion schemas, grants and the validation SQL warehouse.
# Volume bronze.raw and the seed upload stay with `make db-setup`
# (tools/databricks_setup.py, which uses IF NOT EXISTS for catalog/schemas), and
# table contents (silver.*, gold.*) stay with foundation and `make validate`, so
# Terraform never owns objects that the harness drops and recreates.

locals {
  default_catalogs = {
    dev  = "mig_redshift_dev"
    prod = "mig_redshift"
  }
  allowed_catalogs = jsondecode(file("${path.module}/../../.migration/allowed_targets.json")).catalogs

  catalog_name   = coalesce(var.catalog_name, local.default_catalogs[var.environment])
  warehouse_name = coalesce(var.warehouse_name, "mig-redshift-${var.environment}")

  schemas = {
    bronze = "Raw seed data loaded as-is"
    silver = "Cleaned, typed tables mirroring the Redshift core layer"
    gold   = "Business marts migrated from Redshift"
  }
}

resource "terraform_data" "allowed_target_guard" {
  input = local.catalog_name

  lifecycle {
    precondition {
      condition     = contains(local.allowed_catalogs, local.catalog_name)
      error_message = "Catalog ${local.catalog_name} is not in .migration/allowed_targets.json."
    }
  }
}

resource "databricks_catalog" "migration" {
  name       = terraform_data.allowed_target_guard.output
  comment    = "Redshift -> Databricks migration (${var.environment})"
  properties = var.tags
}

resource "databricks_grant" "catalog_account_users" {
  catalog    = databricks_catalog.migration.name
  principal  = "account users"
  privileges = ["ALL_PRIVILEGES"]
}

resource "databricks_schema" "medallion" {
  for_each = local.schemas

  catalog_name = databricks_catalog.migration.name
  name         = each.key
  comment      = each.value
  properties   = var.tags
}

resource "databricks_sql_endpoint" "validation" {
  name                      = local.warehouse_name
  cluster_size              = var.warehouse_size
  min_num_clusters          = 1
  max_num_clusters          = 1
  auto_stop_mins            = var.warehouse_auto_stop_mins
  warehouse_type            = "PRO"
  enable_serverless_compute = true

  tags {
    dynamic "custom_tags" {
      for_each = var.tags
      content {
        key   = custom_tags.key
        value = custom_tags.value
      }
    }
  }
}

resource "databricks_permissions" "warehouse_usage" {
  sql_endpoint_id = databricks_sql_endpoint.validation.id

  access_control {
    group_name       = "users"
    permission_level = "CAN_USE"
  }
}
