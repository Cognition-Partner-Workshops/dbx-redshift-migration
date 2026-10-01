"""Idempotent dev-catalog setup for migration runs (Databricks SDK).

    python tools/databricks_setup.py            # create catalog/schemas/volume + seed upload
    python tools/databricks_setup.py --reset    # drop all schemas, then run the full setup

Creates catalog $MIG_CATALOG (default mig_redshift_dev) with the demo tags,
medallion schemas bronze/silver/gold, managed volume bronze.raw, and uploads
data/seed/csv/*.csv to /Volumes/<catalog>/bronze/raw/.

Auth: standard DATABRICKS_HOST + DATABRICKS_TOKEN or DATABRICKS_CONFIG_PROFILE.
Warehouse: DATABRICKS_WAREHOUSE_ID. Never hardcodes host/warehouse/token.
"""
import argparse
import os
import pathlib
import time

from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

ROOT = pathlib.Path(__file__).resolve().parents[1]
SEED_DIR = ROOT / "data" / "seed" / "csv"
DEFAULT_CATALOG = "mig_redshift_dev"
TAGS = {"demo_type": "redshift", "source_repo": "dbx-redshift-migration"}
SCHEMA_COMMENTS = {
    "bronze": "Raw seed data loaded as-is",
    "silver": "Cleaned, typed tables mirroring the Redshift core layer",
    "gold": "Business marts migrated from Redshift",
}
_pendingStates = {StatementState.PENDING, StatementState.RUNNING}


def warehouseId():
    value = os.environ.get("DATABRICKS_WAREHOUSE_ID")
    if not value:
        raise SystemExit("DATABRICKS_WAREHOUSE_ID is not set")
    return value


def catalogName():
    return os.environ.get("MIG_CATALOG", DEFAULT_CATALOG)


def runSql(w, sql):
    """Run one statement and wait for a terminal state; raise on failure.

    No catalog context is passed — the catalog may not exist yet.
    """
    resp = w.statement_execution.execute_statement(
        statement=sql,
        warehouse_id=warehouseId(),
        wait_timeout="50s",
    )
    while resp.status.state in _pendingStates:
        time.sleep(2)
        resp = w.statement_execution.get_statement(resp.statement_id)
    if resp.status.state != StatementState.SUCCEEDED:
        error = resp.status.error.message if resp.status.error else resp.status.state
        raise RuntimeError(f"Databricks SQL failed: {error}\n{sql[:400]}")


def createSchemas(w, catalog):
    for schema, comment in SCHEMA_COMMENTS.items():
        runSql(w, f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema} "
                  f"COMMENT '{comment}'")
    runSql(w, f"CREATE VOLUME IF NOT EXISTS {catalog}.bronze.raw")


def uploadSeed(w, catalog):
    volumePath = f"/Volumes/{catalog}/bronze/raw"
    for csvPath in sorted(SEED_DIR.glob("*.csv")):
        target = f"{volumePath}/{csvPath.name}"
        print(f"upload {csvPath.name} -> {target}")
        with open(csvPath, "rb") as f:
            w.files.upload(target, f, overwrite=True)


def setup(reset=False):
    w = WorkspaceClient()
    catalog = catalogName()

    if reset:
        for schema in ("gold", "silver", "bronze"):
            runSql(w, f"DROP SCHEMA IF EXISTS {catalog}.{schema} CASCADE")
        print(f"dropped {catalog}.gold, .silver, .bronze — running full setup")

    tagSql = " ".join(f"'{k}' = '{v}'," for k, v in TAGS.items()).rstrip(",")
    runSql(w, f"CREATE CATALOG IF NOT EXISTS {catalog} "
              f"COMMENT 'Redshift migration demo dev catalog'")
    runSql(w, f"ALTER CATALOG {catalog} SET TAGS ({tagSql})")

    createSchemas(w, catalog)
    uploadSeed(w, catalog)
    print(f"catalog {catalog} ready")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reset", action="store_true",
                        help="drop gold/silver/bronze, then run the full setup")
    args = parser.parse_args()
    setup(reset=args.reset)


if __name__ == "__main__":
    main()
