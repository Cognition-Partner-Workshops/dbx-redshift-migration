"""Reproducible Lakebridge inventory helper (local, read-only over legacy/).

Lakebridge analyze drops files whose basename it has already seen, so the
legacy tree (36 files named etl.sql / report.sql) collapses to 7 entries.
This helper copies every legacy source file (SQL and the schedule YAML) into a flat staging directory under
the user's home with a unique, source-relative filename, records the original
path mapping with sha256 provenance, and summarizes analyze / transpile output.

    python tools/lakebridge_inventory.py stage    [--staging DIR]
    python tools/lakebridge_inventory.py analyze  [--staging DIR]
    python tools/lakebridge_inventory.py summarize

It never connects to Redshift, never runs tools/legacy_redshift.py and never
writes inside legacy/, golden/, data/seed/ or validation/.
"""
import argparse
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parents[1]
LEGACY = ROOT / "legacy" / "redshift"
MANIFEST = ROOT / ".migration" / "units.yaml"
EVIDENCE = ROOT / ".migration" / "lakebridge" / "rerun"
TRANSPILED = ROOT / ".migration" / "lakebridge" / "transpiled"
DEFAULT_STAGING = pathlib.Path.home() / "ws1_lakebridge" / "staging"

# Constructs whose presence in a legacy file / absence in its draft is tracked.
CONSTRUCTS = {
    "CREATE PROCEDURE": r"CREATE\s+(OR\s+REPLACE\s+)?PROCEDURE",
    "PL/pgSQL": r"LANGUAGE\s+plpgsql",
    "FOR loop": r"\bFOR\s+\w+\s+IN\b",
    "CALL": r"^\s*CALL\b",
    "TEMP TABLE": r"\bTEMP(ORARY)?\s+TABLE\b",
    "DELETE": r"\bDELETE\s+FROM\b",
    "UNLOAD": r"\bUNLOAD\s*\(",
    "UDF f_fiscal_qtr": r"\bf_fiscal_qtr\s*\(",
    "UDF f_clean_phone": r"\bf_clean_phone\s*\(",
    "SUPER/PartiQL nav": r"\bt\.payload\.\w+",
    "DISTKEY/SORTKEY": r"\b(DISTKEY|SORTKEY|DISTSTYLE)\b",
    "ENCODE": r"\bENCODE\s+\w+",
    "DECODE": r"\bDECODE\s*\(",
    "NVL": r"\bNVL\s*\(",
    "NVL2": r"\bNVL2\s*\(",
    "LISTAGG": r"\bLISTAGG\s*\(",
    "MEDIAN": r"\bMEDIAN\s*\(",
    "RATIO_TO_REPORT": r"\bRATIO_TO_REPORT\s*\(",
    "CONVERT_TIMEZONE": r"\bCONVERT_TIMEZONE\s*\(",
    "DATEDIFF": r"\bDATEDIFF\s*\(",
    "DATEADD": r"\bDATEADD\s*\(",
    "GETDATE/SYSDATE": r"\b(GETDATE\s*\(|SYSDATE\b)",
    ":: cast": r"::",
    "FIXME/unsupported marker": r"FIXME|cannot be translated|Unsupported",
}


def stagedName(rel):
    """legacy/redshift/units/x/etl.sql -> units__x__etl.sql (unique, reversible)."""
    return "__".join(pathlib.PurePosixPath(rel).parts)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def legacyFiles():
    return sorted(p for p in LEGACY.rglob("*") if p.is_file())


def unitIndex():
    with open(MANIFEST) as f:
        manifest = yaml.safe_load(f)
    owner = {}
    for name, unit in manifest["units"].items():
        for rel in unit["legacy"]:
            owner[rel] = (name, unit["wave"])
    return manifest, owner


def statementCount(text):
    """Top-level ';' count outside $$ bodies, quotes and -- comments."""
    count, inDollar, inQuote, i = 0, False, False, 0
    while i < len(text):
        if not inQuote and text.startswith("$$", i):
            inDollar = not inDollar
            i += 2
            continue
        ch = text[i]
        if not inDollar and not inQuote and text.startswith("--", i):
            nl = text.find("\n", i)
            i = len(text) if nl < 0 else nl
            continue
        if not inDollar and ch == "'":
            inQuote = not inQuote
        elif not inDollar and not inQuote and ch == ";":
            count += 1
        i += 1
    return count


def constructsIn(text):
    return sorted(k for k, rx in CONSTRUCTS.items() if re.search(rx, text, re.IGNORECASE | re.MULTILINE))


def cmdStage(staging):
    if staging.exists():
        shutil.rmtree(staging)
    staging.mkdir(parents=True)
    _, owner = unitIndex()
    rows = []
    for src in legacyFiles():
        rel = src.relative_to(LEGACY).as_posix()
        repoRel = src.relative_to(ROOT).as_posix()
        dst = staging / stagedName(rel)
        if dst.exists():
            raise SystemExit(f"staged name collision: {dst.name}")
        shutil.copyfile(src, dst)
        text = src.read_text()
        unit, wave = owner.get(repoRel, (None, None))
        rows.append({
            "staged_name": dst.name,
            "source_path": repoRel,
            "unit": unit,
            "wave": wave,
            "sha256": sha256(src),
            "lines": len(text.splitlines()),
            "statements": statementCount(text),
            "constructs": constructsIn(text),
        })
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    out = {"staging_dir": "~/" + staging.relative_to(pathlib.Path.home()).as_posix(), "files": rows}
    (EVIDENCE / "staging_manifest.json").write_text(json.dumps(out, indent=2) + "\n")
    print(f"staged {len(rows)} files -> {staging}")


def cmdAnalyze(staging):
    if not staging.exists():
        cmdStage(staging)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    report = EVIDENCE / "analyze.xlsx"
    cmd = ["databricks", "labs", "lakebridge", "analyze",
           "--source-directory", str(staging), "--report-file", str(report),
           "--source-tech", "Redshift", "--generate-json", "true"]
    env = dict(os.environ, DATABRICKS_CONFIG_PROFILE="DEFAULT")
    proc = subprocess.run(cmd, capture_output=True, text=True, env=env, check=False)
    log = f"$ {' '.join(cmd)}\nexit={proc.returncode}\n--- stdout ---\n{proc.stdout}\n--- stderr ---\n{proc.stderr}"
    (EVIDENCE / "analyze.log").write_text(log.replace(str(pathlib.Path.home()), "~"))
    print(f"analyze exit={proc.returncode}")
    return proc.returncode


def draftFor(sourcePath):
    p = pathlib.PurePosixPath(sourcePath)
    if p.parts[2] != "units":
        return None
    draft = TRANSPILED / p.parts[3] / p.name
    return draft if draft.exists() else None


def cmdSummarize():
    staged = json.loads((EVIDENCE / "staging_manifest.json").read_text())
    analyzeJson = EVIDENCE / "analyze.json"
    inventory = []
    if analyzeJson.exists():
        inventory = json.loads(analyzeJson.read_text()).get("inventory", [])
    rows = []
    for f in staged["files"]:
        draft = draftFor(f["source_path"])
        draftText = draft.read_text() if draft else ""
        draftConstructs = constructsIn(draftText) if draft else []
        rows.append({
            "source_path": f["source_path"],
            "unit": f["unit"],
            "draft": draft.relative_to(ROOT).as_posix() if draft else None,
            "source_statements": f["statements"],
            "draft_statements": statementCount(draftText) if draft else None,
            "source_constructs": f["constructs"],
            "draft_constructs": draftConstructs,
            "dropped_constructs": sorted(set(f["constructs"]) - set(draftConstructs)) if draft else None,
        })
    summary = {
        "staged_files": len(staged["files"]),
        "analyze_inventory_entries": len(inventory),
        "drafts_found": sum(1 for r in rows if r["draft"]),
        "files": rows,
    }
    (EVIDENCE / "draft_summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({k: v for k, v in summary.items() if k != "files"}))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["stage", "analyze", "summarize"])
    parser.add_argument("--staging", type=pathlib.Path, default=DEFAULT_STAGING)
    args = parser.parse_args(argv)
    if args.command == "stage":
        cmdStage(args.staging)
    elif args.command == "analyze":
        return cmdAnalyze(args.staging)
    else:
        cmdSummarize()
    return 0


if __name__ == "__main__":
    sys.exit(main())
