"""finance_export UNLOAD replacement: write gold.finance_monthly as one CSV with a
header (UNLOAD ... PARALLEL OFF CSV HEADER) to a Unity Catalog volume.

Redshift: UNLOAD TO 's3://<bucket>/finance_export/monthly/' IAM_ROLE '<role-arn>'.
Databricks: the managed volume <catalog>.gold.finance_export; for an S3 target,
create it as an EXTERNAL volume on a UC external location (storage credential
replaces IAM_ROLE) and keep this script unchanged.
"""
import argparse

from pyspark.sql import SparkSession

parser = argparse.ArgumentParser()
parser.add_argument("--catalog", required=True)
args = parser.parse_args()

spark = SparkSession.builder.getOrCreate()
spark.sql(f"CREATE VOLUME IF NOT EXISTS `{args.catalog}`.gold.finance_export")
path = f"/Volumes/{args.catalog}/gold/finance_export/monthly"
(
    spark.table(f"`{args.catalog}`.gold.finance_monthly")
    .orderBy("month")
    .coalesce(1)
    .write.mode("overwrite")
    .option("header", True)
    .csv(path)
)
print(f"exported gold.finance_monthly to {path}")
