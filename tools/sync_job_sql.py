"""Regenerate catalog-parameterized job SQL; --check detects source drift."""
import argparse
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
HEADER = """-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- {source} — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    manifest = yaml.safe_load((ROOT / ".migration/units.yaml").read_text())
    sources = {
        "load_core": "databricks/foundation/etl.sql",
        "exec_summary": "databricks/orchestration/etl.sql",
        "mart_views": "databricks/orchestration/mart_views.sql",
    }
    for name, unit in manifest["units"].items():
        if name not in {"foundation", "orchestration"}:
            sources[f"unit_{name}"] = f"{unit['target_dir']}/etl.sql"
    stale = []
    for name, source in sorted(sources.items()):
        target = ROOT / "databricks/job" / f"{name}.sql"
        expected = HEADER.format(source=source) + (ROOT / source).read_text()
        if args.check:
            if not target.exists() or target.read_text() != expected:
                stale.append(str(target.relative_to(ROOT)))
        else:
            target.write_text(expected)
    if stale:
        print("Job SQL is stale; run python tools/sync_job_sql.py:")
        print("\n".join(stale))
        return 1
    print(f"Job SQL {'checked' if args.check else 'generated'}: {len(sources)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
