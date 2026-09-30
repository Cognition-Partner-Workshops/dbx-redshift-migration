"""Idempotent dev-catalog setup for migration runs (Databricks SDK).

    python tools/databricks_setup.py            # create catalog/schemas/volume + seed upload
    python tools/databricks_setup.py --reset    # drop + recreate core and mart only

Creates catalog $MIG_CATALOG (default mig_redshift_dev) with the demo tags,
schemas landing/core/mart, managed volume landing.raw, and uploads
data/seed/csv/*.csv to /Volumes/<catalog>/landing/raw/.

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


def setup(reset=False):
    w = WorkspaceClient()
    catalog = catalogName()

    if reset:
        runSql(w, f"DROP SCHEMA IF EXISTS {catalog}.core CASCADE")
        runSql(w, f"DROP SCHEMA IF EXISTS {catalog}.mart CASCADE")
        runSql(w, f"CREATE SCHEMA IF NOT EXISTS {catalog}.core")
        runSql(w, f"CREATE SCHEMA IF NOT EXISTS {catalog}.mart")
        print(f"reset {catalog}.core and {catalog}.mart")
        return

    tagSql = " ".join(f"'{k}' = '{v}'," for k, v in TAGS.items()).rstrip(",")
    runSql(w, f"CREATE CATALOG IF NOT EXISTS {catalog} "
              f"COMMENT 'Redshift migration demo dev catalog'")
    runSql(w, f"ALTER CATALOG {catalog} SET TAGS ({tagSql})")

    for schema in ("landing", "core", "mart"):
        runSql(w, f"CREATE SCHEMA IF NOT EXISTS {catalog}.{schema}")
    runSql(w, f"CREATE VOLUME IF NOT EXISTS {catalog}.landing.raw")

    volumePath = f"/Volumes/{catalog}/landing/raw"
    for csvPath in sorted(SEED_DIR.glob("*.csv")):
        target = f"{volumePath}/{csvPath.name}"
        print(f"upload {csvPath.name} -> {target}")
        with open(csvPath, "rb") as f:
            w.files.upload(target, f, overwrite=True)
    print(f"catalog {catalog} ready")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reset", action="store_true",
                        help="drop and recreate core and mart only")
    args = parser.parse_args()
    setup(reset=args.reset)


if __name__ == "__main__":
    main()
