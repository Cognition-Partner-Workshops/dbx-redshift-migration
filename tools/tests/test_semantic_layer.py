"""semantic_layer: definitions match the legacy reports and generated files are current."""
import pathlib
import re
import sys

import yaml

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))

from tools import semantic_layer

SUBJECTS = {
    "revenue": {"daily_revenue", "store_weekly", "category_mix", "product_perf", "geo_rollup",
                "payment_mix", "finance_monthly"},
    "customer": {"customer_ltv", "churn_flags", "rfm_segments", "cohort_retention"},
    "marketing": {"attribution", "promo_lift", "web_sessions", "basket_affinity"},
    "operations": {"shipping_sla", "returns_rate", "inventory_snapshot"},
}


def test_definitions_are_valid():
    assert semantic_layer.checkDefinitions(semantic_layer.loadManifest()) == []


def test_generated_files_are_current():
    assert semantic_layer.generate(check=True) == 0


def test_one_view_per_business_subject():
    manifest = semantic_layer.loadManifest()
    found = {}
    for spec in manifest["views"].values():
        group, file = spec["definition"].split("/")
        found.setdefault(group, set()).add(file.removesuffix(".yaml"))
    assert found == SUBJECTS


def test_report_query_uses_measure():
    manifest = semantic_layer.loadManifest()
    sql = semantic_layer.reportQuery(manifest, "daily_revenue_metrics")
    assert sql.startswith("SELECT `order_month`, `sales_channel`, MEASURE(`order_count`) AS `order_count`")
    assert "FROM semantic.daily_revenue_metrics\nGROUP BY ALL" in sql


def test_ddl_is_metric_view():
    manifest = semantic_layer.loadManifest()
    statements = dict(semantic_layer.deployStatements(manifest))
    assert statements[semantic_layer.SCHEMA_TASK].startswith("CREATE SCHEMA IF NOT EXISTS semantic")
    ddl = statements["finance_monthly_metrics"]
    assert ddl.startswith("CREATE OR REPLACE VIEW semantic.finance_monthly_metrics\nWITH METRICS\nLANGUAGE YAML")


def test_no_dynamic_dates():
    for spec in semantic_layer.loadManifest()["views"].values():
        text = "\n".join(line for line in semantic_layer.definitionText(spec).splitlines()
                         if not line.lstrip().startswith("#"))
        banned = re.search(r"\b(CURRENT_DATE|CURRENT_TIMESTAMP|NOW|GETDATE|SYSDATE|RANDOM|RAND)\b", text, re.IGNORECASE)
        assert banned is None, (spec["definition"], banned)


def test_missing_report_measure_is_flagged(tmp_path):
    manifest = semantic_layer.loadManifest()
    manifest["views"]["daily_revenue_metrics"]["report"]["measures"] = ["order_count", "nope"]
    errors = semantic_layer.checkDefinitions(manifest)
    assert any("nope" in e for e in errors)


def test_job_runs_every_view_after_schema():
    job = yaml.safe_load(semantic_layer.JOB_RESOURCE.read_text())["resources"]["jobs"]["semantic_layer"]
    tasks = {t["task_key"]: t for t in job["tasks"]}
    assert set(tasks) == {semantic_layer.SCHEMA_TASK} | set(semantic_layer.loadManifest()["views"])
    for key, task in tasks.items():
        assert task["sql_task"]["parameters"] == {"catalog": "${var.catalog}"}
        if key != semantic_layer.SCHEMA_TASK:
            assert task["depends_on"] == [{"task_key": semantic_layer.SCHEMA_TASK}]
