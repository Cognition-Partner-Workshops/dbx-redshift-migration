# Remote state in S3 (the estate and Databricks workspace run on AWS) with
# native S3 lockfiles. Partial configuration: bucket, key and region are passed
# at init time so dev and prod keep separate state files, e.g.
#
#   terraform init \
#     -backend-config="bucket=$TF_STATE_BUCKET" \
#     -backend-config="key=dbx-redshift-migration/dev/terraform.tfstate" \
#     -backend-config="region=$TF_STATE_REGION"
#
# Use `terraform init -backend=false` for offline fmt/validate.
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
