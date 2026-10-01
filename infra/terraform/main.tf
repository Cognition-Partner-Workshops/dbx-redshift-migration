# Terraform equivalent of tools/databricks_setup.py: dev catalog with demo tags,
# medallion schemas, managed volume bronze.raw and the seed CSV upload.
#
# Auth comes from the environment only (DATABRICKS_HOST + DATABRICKS_TOKEN, or a
# DATABRICKS_CONFIG_PROFILE); nothing is hardcoded here.

terraform {
  required_version = ">= 1.5"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.90"
    }
  }

  # Local state is used for the demo. For shared or CI use, configure a remote
  # backend so state survives between runs, e.g.:
  #
  #   backend "s3" {
  #     bucket         = "<state-bucket>"
  #     key            = "dbx-redshift-migration/terraform.tfstate"
  #     region         = "us-east-1"
  #     dynamodb_table = "<lock-table>"
  #     encrypt        = true
  #   }
  #
  # or a Terraform Cloud `cloud {}` block.
}

provider "databricks" {}

locals {
  tags = {
    demo_type   = "redshift"
    source_repo = "dbx-redshift-migration"
  }

  # Mirrors SCHEMA_COMMENTS in tools/databricks_setup.py.
  schema_comments = {
    bronze = "Raw seed data loaded as-is"
    silver = "Cleaned, typed tables mirroring the Redshift core layer"
    gold   = "Business marts migrated from Redshift"
  }

  seed_dir   = "${path.module}/../../data/seed/csv"
  seed_files = fileset(local.seed_dir, "*.csv")
}

resource "databricks_catalog" "migration" {
  name       = var.catalog
  comment    = "Redshift migration demo dev catalog"
  properties = local.tags
}

resource "databricks_entity_tag_assignment" "catalog" {
  for_each = local.tags

  entity_type = "catalogs"
  entity_name = databricks_catalog.migration.name
  tag_key     = each.key
  tag_value   = each.value
}

resource "databricks_grant" "catalog_account_users" {
  catalog    = databricks_catalog.migration.name
  principal  = "account users"
  privileges = ["ALL_PRIVILEGES"]
}

resource "databricks_schema" "medallion" {
  for_each = local.schema_comments

  catalog_name = databricks_catalog.migration.name
  name         = each.key
  comment      = each.value
}

resource "databricks_volume" "raw" {
  catalog_name = databricks_catalog.migration.name
  schema_name  = databricks_schema.medallion["bronze"].name
  name         = "raw"
  volume_type  = "MANAGED"
  comment      = "Seed CSVs (historical extract) loaded into bronze"
}

resource "databricks_file" "seed" {
  for_each = local.seed_files

  source = "${local.seed_dir}/${each.value}"
  path   = "${databricks_volume.raw.volume_path}/${each.value}"
}
