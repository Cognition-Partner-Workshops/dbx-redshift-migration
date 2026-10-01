"""Validate the semantic layer metric views against the committed golden reports.

    python tools/validate_semantic.py                    # deploy views, validate all
    python tools/validate_semantic.py --skip-deploy      # validate already-deployed views
    python tools/validate_semantic.py --view daily_revenue_metrics

For every metric view in databricks/semantic/manifest.yaml: query it through
the SQL warehouse (DATABRICKS_WAREHOUSE_ID, catalog MIG_CATALOG) selecting the
report dimensions and MEASURE() of the report measures with GROUP BY ALL (plus
the legacy ORDER BY / LIMIT), then compare with golden/<unit>/report.csv using
the validation harness comparator, keys and tolerances (validation/tolerances.yaml)
of that unit's report output. Writes .migration/evidence/semantic/<view>.json
and exits non-zero on any FAIL. Requires the gold.* marts to be built.
"""
import argparse
import datetime as dt
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from tools import semantic_layer
from validation.compare import compareOutput, loadGolden
from validation.dbsql import DbSql
from validation.validate_unit import TOLERANCES, gitCommit, loadYaml, printSummary, toleranceLookup

EVIDENCE_DIR = ROOT / ".migration" / "evidence" / "semantic"


def validateView(db, manifest, name, units, tolerances):
    spec = manifest["views"][name]
    output = semantic_layer.reportOutput(spec["unit"], units)
    tolFor, overrides = toleranceLookup(tolerances, spec["unit"], output["name"])
    query = semantic_layer.reportQuery(manifest, name)
    record = {"output": f"{manifest['schema']}.{name}", "golden": output["golden"],
              "target": query, "tolerance_overrides": overrides}
    try:
        goldenCsv = ROOT / output["golden"]
        goldenColumns, goldenRows = loadGolden(goldenCsv, goldenCsv.with_suffix(".meta.json"))
        targetColumns, targetRows = db.run(query)
        record.update(compareOutput(goldenColumns, goldenRows, targetColumns, targetRows,
                                    output["keys"], tolFor))
    except (RuntimeError, ValueError) as exc:
        record.update({"status": "FAIL", "checks": [], "error": str(exc)[:2000]})
    return record


def validateSemantic(views=None, skipDeploy=False, db=None):
    manifest = semantic_layer.loadManifest()
    errors = semantic_layer.checkDefinitions(manifest)
    if errors:
        raise SystemExit("invalid semantic layer definitions:\n" + "\n".join(errors))
    names = views or list(manifest["views"])
    unknown = set(names) - set(manifest["views"])
    if unknown:
        raise SystemExit(f"unknown metric views: {sorted(unknown)}")
    db = db or DbSql()
    semantic_layer.approvedCatalog(db.catalog)
    units = loadYaml(semantic_layer.UNITS_MANIFEST)["units"]
    tolerances = loadYaml(TOLERANCES)

    deployRecord = {"status": "SKIPPED"}
    if not skipDeploy:
        try:
            semantic_layer.deploy(db, views=names, manifest=manifest)
            deployRecord = {"status": "PASS"}
        except RuntimeError as exc:
            deployRecord = {"status": "FAIL", "detail": str(exc)[:2000]}

    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    results = []
    for name in names:
        started = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
        outputs = []
        if deployRecord["status"] != "FAIL":
            outputs.append(validateView(db, manifest, name, units, tolerances))
        statuses = [deployRecord["status"]] + [o["status"] for o in outputs]
        evidence = {
            "unit": f"{manifest['schema']}.{name}",
            "legacy_unit": manifest["views"][name]["unit"],
            "definition": f"databricks/semantic/{manifest['views'][name]['definition']}",
            "engine": "databricks_sql_metric_view",
            "catalog": db.catalog,
            "warehouse_id": db.warehouse,
            "git_commit": gitCommit(),
            "started_at": started,
            "build": deployRecord,
            "outputs": outputs,
            "status": "FAIL" if "FAIL" in statuses else "PASS",
            "finished_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        }
        (EVIDENCE_DIR / f"{name}.json").write_text(json.dumps(evidence, indent=2) + "\n")
        results.append(evidence)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--view", action="append", help="validate one metric view (repeatable)")
    parser.add_argument("--skip-deploy", action="store_true", help="query the views without re-running the DDL")
    args = parser.parse_args()
    results = validateSemantic(views=args.view, skipDeploy=args.skip_deploy)
    for evidence in results:
        printSummary(evidence)
    failed = [e["unit"] for e in results if e["status"] != "PASS"]
    print(f"semantic layer: {len(results) - len(failed)}/{len(results)} metric views PASS")
    if failed:
        print("FAILED: " + " ".join(failed))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
