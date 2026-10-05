"""Regenerate catalog-parameterized job SQL; --check detects source drift."""
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JOB_DIR = ROOT / "databricks/job"
SOURCES = {
    "load_core": "databricks/foundation/etl.sql",
    "validate_load_core": "databricks/foundation/validation.sql",
    "unit_customer_ltv": "databricks/units/customer_ltv/etl.sql",
    "validate_customer_ltv": "databricks/units/customer_ltv/validation.sql",
    "exec_summary": "databricks/orchestration/etl.sql",
    "validate_exec_summary": "databricks/orchestration/validation.sql",
    "mart_views": "databricks/compat/mart_views.sql",
    "semantic_customer_ltv": "databricks/semantic/customer_ltv_metrics.sql",
    "validate_semantic_customer_ltv": "databricks/semantic/customer_ltv_metrics_validation.sql",
}
NOTEBOOKS = {"load_core"}
HEADER = """-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED from {source} by tools/sync_job_sql.py — edit the source, then
-- regenerate. The job binds :catalog via the sql_task parameters map;
-- IDENTIFIER() keeps the catalog substitution safe.
USE CATALOG IDENTIFIER(:catalog);

"""
NOTEBOOK_HEADER = """-- Databricks notebook source
-- GENERATED from {source} by tools/sync_job_sql.py — edit the source, then
-- regenerate. The job binds the :catalog widget via base_parameters.
USE CATALOG IDENTIFIER(:catalog);

-- COMMAND ----------

"""


def render(name):
    source = SOURCES[name]
    header = NOTEBOOK_HEADER if name in NOTEBOOKS else HEADER
    return header.format(source=source) + (ROOT / source).read_text()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    stale = []
    for name in sorted(SOURCES):
        target = JOB_DIR / f"{name}.sql"
        expected = render(name)
        if args.check:
            if not target.exists() or target.read_text() != expected:
                stale.append(str(target.relative_to(ROOT)))
        else:
            JOB_DIR.mkdir(parents=True, exist_ok=True)
            target.write_text(expected)
    if stale:
        print("Job SQL is stale; run python tools/sync_job_sql.py:")
        print("\n".join(stale))
        return 1
    print(f"Job SQL {'checked' if args.check else 'generated'}: {len(SOURCES)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
