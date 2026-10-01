# Databricks notebook source
# finance_export: monthly finance CSV export — replaces the legacy Redshift
# UNLOAD (legacy/redshift/units/finance_export/export.sql, a placeholder never
# executed at capture). Writes gold.finance_monthly to a UC volume as a single
# CSV with a header row, ordered by month, overwriting the previous output so
# reruns are idempotent.
#
# Parameters: catalog, export_path — supplied either as job widgets
# (notebook_task base_parameters) or as sys.argv (spark_python_task
# parameters). Example export_path:
#   /Volumes/mig_redshift_dev/gold/finance_export/monthly

from pyspark.sql import SparkSession

try:
    catalog = dbutils.widgets.get("catalog")
    export_path = dbutils.widgets.get("export_path")
except NameError:
    import sys

    catalog, export_path = sys.argv[1], sys.argv[2]

if not catalog or not export_path:
    raise ValueError("parameters 'catalog' and 'export_path' are required")

spark = SparkSession.builder.getOrCreate()
df = spark.read.table(f"{catalog}.gold.finance_monthly")
(
    df.orderBy("month")
    .coalesce(1)
    .write.mode("overwrite")
    .option("header", "true")
    .csv(export_path)
)
print(f"finance_export: wrote {df.count()} rows to {export_path}")
