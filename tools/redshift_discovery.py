"""SELECT-only live discovery against the legacy Redshift Serverless warehouse.

Runs tools/redshift_discovery/pipeline_config.yml either through Lakebridge's
native profiler (redshift_connector over TCP 5439) or through the Redshift
Data API, and writes each step's result set as JSON evidence under
.migration/lakebridge/live/<engine>_<auth>/.

    # Lakebridge venv python (has databricks-labs-lakebridge + redshift_connector)
    PY=~/.databricks/labs/lakebridge/state/venv/bin/python
    $PY tools/redshift_discovery.py --engine profiler --auth secret --secret-id '<name-or-arn>'
    $PY tools/redshift_discovery.py --engine data-api --auth iam

Safety:
- every step must be type `sql` and its text a single SELECT / WITH statement;
  anything else aborts before connecting (no source_ddl, no grants, no writes);
- secret values are read in-process from AWS Secrets Manager into environment
  variables that the Lakebridge env-vault credential file references by name;
  the credential file on disk holds variable names only, never values;
- it never runs tools/legacy_redshift.py.
"""
import argparse
import datetime
import decimal
import json
import os
import pathlib
import re
import sys
import time

import yaml

try:  # available in the Lakebridge venv, not in the repo test environment
    import boto3
    import duckdb
    from databricks.labs.lakebridge.assessments.profiler import Profiler
    from databricks.labs.lakebridge.assessments.profiler_config import PipelineConfig, Step
except ImportError:  # pragma: no cover
    boto3 = duckdb = Profiler = PipelineConfig = Step = None

ROOT = pathlib.Path(__file__).resolve().parents[1]
MANIFEST = ROOT / ".migration" / "units.yaml"
PIPELINE = ROOT / "tools" / "redshift_discovery" / "pipeline_config.yml"
EVIDENCE = ROOT / ".migration" / "lakebridge" / "live"
WORKDIR = pathlib.Path.home() / "ws1_lakebridge" / "profiler"

REGION = "us-east-1"
WORKGROUP = "demo-wg"
HOST = "demo-wg.599083837640.us-east-1.redshift-serverless.amazonaws.com"
PORT = 5439
DATABASE = "mig_redshift_src"

FORBIDDEN = re.compile(
    r"\b(INSERT|UPDATE|DELETE|MERGE|CREATE|DROP|ALTER|TRUNCATE|GRANT|REVOKE|CALL|UNLOAD|COPY|VACUUM|ANALYZE|SET)\b",
    re.IGNORECASE,
)


def stripComments(sql):
    return "\n".join(line.split("--", 1)[0] for line in sql.splitlines()).strip()


def assertSelectOnly(name, sql):
    body = stripComments(sql).rstrip(";").strip()
    if not re.match(r"^(SELECT|WITH)\b", body, re.IGNORECASE):
        raise SystemExit(f"step {name}: not a SELECT/WITH statement")
    if ";" in body:
        raise SystemExit(f"step {name}: multiple statements")
    hit = FORBIDDEN.search(body)
    if hit:
        raise SystemExit(f"step {name}: forbidden keyword {hit.group(0)}")
    return body


def loadSteps():
    config = yaml.safe_load(PIPELINE.read_text())
    steps = []
    for step in config["steps"]:
        if step["type"] != "sql":
            raise SystemExit(f"step {step['name']}: type {step['type']} is not allowed")
        sql = (ROOT / step["extract_source"]).read_text()
        steps.append({**step, "sql": assertSelectOnly(step["name"], sql)})
    return config, steps


def jsonable(value):
    if isinstance(value, decimal.Decimal):
        return str(value)
    if isinstance(value, (datetime.date, datetime.datetime)):
        return value.isoformat()
    if isinstance(value, bytes):
        value = value.decode("utf-8", "replace")
    if isinstance(value, str):
        return value.replace("\x00", "")
    return value


def writeEvidence(runDir, name, columns, rows, status, error=None):
    out = {"step": name, "status": status, "error": error, "columns": columns,
           "row_count": len(rows), "rows": [[jsonable(v) for v in r] for r in rows]}
    (runDir / f"{name}.json").write_text(json.dumps(out, indent=2, default=str) + "\n")


def secretEnv(secretId):
    """Export username/password of a Secrets Manager secret into env vars (values never printed)."""
    client = boto3.client("secretsmanager", region_name=REGION)
    secret = json.loads(client.get_secret_value(SecretId=secretId)["SecretString"])
    if secret.get("dbClusterIdentifier") not in (None, WORKGROUP):
        raise SystemExit("secret does not belong to workgroup " + WORKGROUP)
    os.environ["WS1_REDSHIFT_USER"] = secret["username"]
    os.environ["WS1_REDSHIFT_PASSWORD"] = secret["password"]


def runProfiler(config, steps, auth, runDir):
    WORKDIR.mkdir(parents=True, exist_ok=True)
    creds = {"auth_type": "sql_authentication" if auth == "secret" else "iam",
             "host": HOST, "port": PORT, "database": DATABASE, "ssl": "yes"}
    if auth == "secret":
        creds.update(user="WS1_REDSHIFT_USER", password="WS1_REDSHIFT_PASSWORD")
    else:
        creds.update(region=REGION)
    credFile = WORKDIR / ".credentials.yml"
    credFile.write_text(yaml.safe_dump({"secret_vault_type": "env", "secret_vault_name": None, "redshift": creds}))
    credFile.chmod(0o600)

    pipeline = PipelineConfig(
        name=config["name"], version=config["version"],
        steps=[Step(name=s["name"], type="sql", extract_source=str(ROOT / s["extract_source"]),
                    mode=s["mode"], frequency=s["frequency"], flag=s["flag"], optional=s["optional"])
               for s in steps])
    outDir = WORKDIR / auth
    for old in outDir.glob("*.db"):
        old.unlink()
    error = None
    try:
        Profiler("redshift", pipeline_configs=pipeline).profile(output_folder=outDir, cred_file_path=credFile)
    except RuntimeError as exc:
        error = str(exc)
    dbs = sorted(outDir.glob("*.db"))
    if not dbs:
        return {"error": error, "steps": {}}
    statuses = {}
    with duckdb.connect(str(dbs[-1]), read_only=True) as conn:
        meta = conn.execute("SELECT results FROM profiler_run_metadata").fetchall()
        results = json.loads(meta[-1][0]) if meta else []
        tables = {r[0] for r in conn.execute("SELECT table_name FROM information_schema.tables").fetchall()}
        for r in results:
            name = r["step_name"]
            columns, rows = [], []
            if name in tables:
                cur = conn.execute(f'SELECT * FROM "{name}"')
                columns = [d[0] for d in cur.description]
                rows = cur.fetchall()
            writeEvidence(runDir, name, columns, rows, r["status"], r["error_message"])
            statuses[name] = r["status"]
    return {"error": error, "steps": statuses}


def dataApiValue(field):
    if field.get("isNull"):
        return None
    return next(iter(field.values()))


def runDataApi(steps, auth, secretArn, runDir):
    client = boto3.client("redshift-data", region_name=REGION)
    statuses = {}
    for step in steps:
        kwargs = {"WorkgroupName": WORKGROUP, "Database": DATABASE, "Sql": step["sql"],
                  "StatementName": f"ws1-discovery-{step['name']}"}
        if auth == "secret":
            kwargs["SecretArn"] = secretArn
        stmt = client.execute_statement(**kwargs)
        while True:
            desc = client.describe_statement(Id=stmt["Id"])
            if desc["Status"] in ("FINISHED", "FAILED", "ABORTED"):
                break
            time.sleep(1)
        if desc["Status"] != "FINISHED":
            status = "ABSENT" if step["optional"] else "ERROR"
            writeEvidence(runDir, step["name"], [], [], status, desc.get("Error"))
            statuses[step["name"]] = status
            continue
        columns, rows, token = [], [], None
        if desc.get("HasResultSet"):
            while True:
                page = client.get_statement_result(Id=stmt["Id"], **({"NextToken": token} if token else {}))
                columns = [c["name"] for c in page["ColumnMetadata"]]
                rows.extend([dataApiValue(f) for f in rec] for rec in page["Records"])
                token = page.get("NextToken")
                if not token:
                    break
        writeEvidence(runDir, step["name"], columns, rows, "COMPLETE")
        statuses[step["name"]] = "COMPLETE"
    return {"error": None, "steps": statuses}


def goldenCounts():
    """Legacy table name -> (golden path, snapshot row_count) for every manifest output."""
    out = {}
    for unit in yaml.safe_load(MANIFEST.read_text())["units"].values():
        for o in unit.get("outputs", []):
            if not o.get("table", "").startswith(("silver.", "gold.")):
                continue
            legacy = o["table"].replace("silver.", "core.", 1).replace("gold.", "mart.", 1)
            meta = json.loads((ROOT / o["golden"]).with_suffix(".meta.json").read_text())
            out[legacy] = (o["golden"], meta["row_count"])
    return out


def compareGolden(runDir):
    """Write golden_comparison.json: live exact COUNT(*) vs committed golden snapshot row_count."""
    golden = goldenCounts()
    live = {}
    for step in ("core_counts", "mart_counts"):
        path = runDir / f"{step}.json"
        if path.exists():
            data = json.loads(path.read_text())
            live.update({r[0]: int(r[1]) for r in data["rows"]})
    rows = []
    for table in sorted(golden):
        path, snap = golden[table]
        got = live.get(table)
        rows.append({"table": table, "golden": path, "golden_rows": snap, "live_rows": got,
                     "status": "BLOCKED" if got is None else ("MATCH" if got == snap else "MISMATCH")})
    summary = {s: sum(r["status"] == s for r in rows) for s in ("MATCH", "MISMATCH", "BLOCKED")}
    execPath = runDir / "exec_summary.json"
    execMatch = None
    if execPath.exists() and json.loads(execPath.read_text())["rows"]:
        liveRow = [str(v) for v in json.loads(execPath.read_text())["rows"][0]]
        goldenRow = (ROOT / "golden/orchestration/exec_summary.csv").read_text().splitlines()[1].split(",")
        execMatch = {"live": liveRow, "golden": goldenRow, "match": liveRow == goldenRow}
    out = {"summary": summary, "tables": rows, "exec_summary_values": execMatch}
    (runDir / "golden_comparison.json").write_text(json.dumps(out, indent=2) + "\n")
    return summary


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--engine", choices=["profiler", "data-api"], required=True)
    parser.add_argument("--auth", choices=["iam", "secret"], required=True)
    parser.add_argument("--secret-id", help="Secrets Manager name/ARN with username/password for demo-wg")
    parser.add_argument("--compare-only", action="store_true", help="re-derive golden_comparison.json, no queries")
    args = parser.parse_args(argv)
    runDir = EVIDENCE / f"{args.engine}_{args.auth}"
    if args.compare_only:
        print(json.dumps(compareGolden(runDir)))
        return 0
    if boto3 is None:
        raise SystemExit("boto3 / lakebridge are required; run with the Lakebridge venv python")
    config, steps = loadSteps()
    if args.auth == "secret":
        if not args.secret_id:
            raise SystemExit("--secret-id is required with --auth secret")
        secretEnv(args.secret_id)
    runDir.mkdir(parents=True, exist_ok=True)
    started = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
    if args.engine == "profiler":
        result = runProfiler(config, steps, args.auth, runDir)
    else:
        result = runDataApi(steps, args.auth, args.secret_id, runDir)
    run = {"engine": args.engine, "auth": args.auth, "started_utc": started, "workgroup": WORKGROUP,
           "database": DATABASE, "pipeline": PIPELINE.relative_to(ROOT).as_posix(), **result}
    run["golden_comparison"] = compareGolden(runDir)
    (runDir / "run.json").write_text(json.dumps(run, indent=2) + "\n")
    print(json.dumps(run, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
