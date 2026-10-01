"""Aggregate validation harness: target aggregates vs committed Redshift goldens.

The row-level oracle is unchanged: `make validate` / `make validate-all`
(validation/validate_unit.py). This harness adds the coarse gate each unit's
`databricks/**/validation.sql` encodes — row counts, per-column sums for
numeric families, COUNT(DISTINCT) for value families, non-null counts —
computed from the same goldens and applied to the actual output tables and
the converted report/manifest queries, foundation silver outputs, and the
orchestration exec_summary.

Modes:
  offline (default)  Re-renders the expected validation.sql content from the
                     committed goldens and reports any file that drifted —
                     catches stale hand-edited expected values with no
                     credentials needed.
  --live             Executes each aggregate query against the SQL warehouse
                     (SELECT-only) and compares the result to the golden-
                     derived expected values. Requires the same env as
                     `make validate`: DATABRICKS_CONFIG_PROFILE (or
                     DATABRICKS_HOST+auth), DATABRICKS_WAREHOUSE_ID and
                     MIG_CATALOG (default mig_redshift_dev). Live mode is
                     opt-in; nothing writes.
"""
import argparse
import csv
import json
import pathlib
import sys
from decimal import Decimal

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from validation.dbsql import DbSql

MANIFEST = ROOT / ".migration" / "units.yaml"
NULL_TOKEN = "\\N"
NUMERIC = {"int", "decimal"}
FLOAT_REL = Decimal("1e-9")
FLOAT_ABS = Decimal("1e-9")
DECIMAL_ABS = Decimal("0.000001")

HEADER = [
    "-- {unit}: aggregate checks vs committed goldens (assert_true).",
    "-- Coarse count/sum gate; the row-level oracle remains `make validate`.",
    "-- Expected values generated from the committed golden CSVs.",
    "-- Run under the caller's catalog context.",
]


def goldenAggregates(goldenPath):
    """Return {'row_count': int, 'cols': {name: agg}} from golden csv + meta."""
    meta = json.loads(goldenPath.with_suffix(".meta.json").read_text())
    fams = [c["family"] for c in meta["columns"]]
    names = [c["name"] for c in meta["columns"]]
    with open(goldenPath, newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))[1:]
    aggs = {"row_count": len(rows), "cols": {}}
    for i, (name, fam) in enumerate(zip(names, fams)):
        nonnull = [r[i] for r in rows if r[i] != NULL_TOKEN]
        agg = {"non_null": len(nonnull)}
        if fam in NUMERIC:
            agg["kind"] = "num"
            agg["sum"] = sum(Decimal(v) for v in nonnull) if nonnull else None
        elif fam == "float":
            agg["kind"] = "float"
            agg["sum"] = sum(float(v) for v in nonnull) if nonnull else None
        else:
            agg["kind"] = "set"
            agg["distinct"] = len(set(nonnull))
        aggs["cols"][name] = agg
    return aggs


def outputSubject(out):
    """Relation or parenthesized SQL the aggregates run over."""
    if "table" in out:
        return out["table"]
    return "(" + (ROOT / out["target_sql"]).read_text().rstrip().rstrip(";") + ")"


def renderValidation(unitName, unit):
    """Expected validation.sql content for one unit."""
    lines = [h.format(unit=unitName) for h in HEADER]
    for out in unit["outputs"]:
        label = f"{unitName}.{out['name']}"
        subject = outputSubject(out)
        aggs = goldenAggregates(ROOT / out["golden"])

        def q(expr, subject=subject):
            return f"SELECT {expr} FROM {subject}"

        lines.append(f"SELECT assert_true(({q('COUNT(*)')}) = {aggs['row_count']}, '{label}: row_count');")
        for col, agg in aggs["cols"].items():
            qc = col
            if agg["kind"] == "num" and agg["sum"] is not None:
                lines.append(
                    f"SELECT assert_true(({q('SUM(' + qc + ')')}) = {agg['sum']}, '{label}: sum({col})');"
                )
            elif agg["kind"] == "float" and agg["sum"] is not None:
                tol = abs(agg["sum"]) * 1e-9 + 1e-9
                lines.append(
                    f"SELECT assert_true(ABS(({q('SUM(' + qc + ')')}) - {agg['sum']!r}) <= {tol!r}, '{label}: sum({col})');"
                )
            elif agg["kind"] == "set":
                lines.append(
                    f"SELECT assert_true(({q('COUNT(DISTINCT ' + qc + ')')}) = {agg['distinct']}, '{label}: count_distinct({col})');"
                )
            lines.append(
                f"SELECT assert_true(({q('COUNT(' + qc + ')')}) = {agg['non_null']}, '{label}: non_null({col})');"
            )
    return "\n".join(lines) + "\n"


def iterOutputs(manifest):
    for unitName, unit in manifest["units"].items():
        for out in unit["outputs"]:
            yield unitName, out


def offline(manifest):
    failed = []
    for unitName, unit in manifest["units"].items():
        path = ROOT / unit["target_dir"] / "validation.sql"
        expected = renderValidation(unitName, unit)
        if not path.exists():
            failed.append(f"{unitName}: missing {path.relative_to(ROOT)}")
        elif path.read_text() != expected:
            failed.append(f"{unitName}: {path.relative_to(ROOT)} drifted from golden-derived expectations")
    return failed


def live(manifest):
    db = DbSql()
    failed = []
    checked = 0
    for unitName, out in iterOutputs(manifest):
        label = f"{unitName}.{out['name']}"
        subject = outputSubject(out)
        aggs = goldenAggregates(ROOT / out["golden"])
        meta_cols = [c["name"] for c in json.loads(
            (ROOT / out["golden"]).with_suffix(".meta.json").read_text()
        )["columns"]]
        # column-order consistency: SELECT with the golden column order.
        select_cols = ", ".join(meta_cols)
        sql = f"SELECT {select_cols} FROM {subject} LIMIT 0"
        columns, _ = db.run(sql)
        if [c[0] for c in columns] != meta_cols:
            failed.append(f"{label}: column order {[c[0] for c in columns]} != golden {meta_cols}")
        row = db.run(
            "SELECT " + ", ".join(
                ['COUNT(*)'] +
                [f'SUM({c})' if a["kind"] in ("num", "float") else f'COUNT(DISTINCT {c})'
                 for c, a in aggs["cols"].items()] +
                [f'COUNT({c})' for c in aggs["cols"]]
            ) + f" FROM {subject}"
        )[1][0]
        vals = [Decimal(v) if v is not None else None for v in row]
        checked += 1
        actual_count, rest = vals[0], vals[1:]
        if actual_count != aggs["row_count"]:
            failed.append(f"{label}: row_count {actual_count} != {aggs['row_count']}")
        col_names = list(aggs["cols"])
        for i, c in enumerate(col_names):
            agg = aggs["cols"][c]
            got, exp = rest[i], agg["sum"] if agg["kind"] in ("num", "float") else agg["distinct"]
            if got is None and exp is None:
                continue
            if agg["kind"] == "float":
                ok = got is not None and abs(got - Decimal(str(exp))) <= max(
                    abs(Decimal(str(exp))) * FLOAT_REL, FLOAT_ABS)
            elif agg["kind"] == "num":
                ok = got is not None and abs(got - exp) <= DECIMAL_ABS
            else:
                ok = got == exp
            if not ok:
                failed.append(f"{label}: aggregate({c}) {got} != {exp}")
        for i, c in enumerate(col_names):
            got = rest[len(col_names) + i]
            if got != aggs["cols"][c]["non_null"]:
                failed.append(f"{label}: non_null({c}) {got} != {aggs['cols'][c]['non_null']}")
    return failed, checked


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--live", action="store_true",
                        help="also run SELECT-only aggregate queries on the warehouse")
    args = parser.parse_args()
    manifest = yaml.safe_load(MANIFEST.read_text())

    failures = offline(manifest)
    if failures:
        print("OFFLINE FAIL:")
        for f in failures:
            print(" ", f)
        return 1
    print(f"OFFLINE PASS: validation.sql files match goldens for {len(manifest['units'])} units")

    if not args.live:
        return 0
    failures, checked = live(manifest)
    if failures:
        print("LIVE FAIL:")
        for f in failures:
            print(" ", f)
        return 1
    print(f"LIVE PASS: {checked} outputs match golden aggregates")
    return 0


if __name__ == "__main__":
    sys.exit(main())
