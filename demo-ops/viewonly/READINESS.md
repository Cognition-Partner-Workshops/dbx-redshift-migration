# ViewOnly readiness for migration-run-2

This page records what the repository holds on `main` today and what a human has to provide before the Databricks persona can run the three sessions in this folder. Every number below was measured on 2026-10-05 from `main`.

## Repository state

| Item | Value | How it was measured |
| --- | --- | --- |
| Units in `.migration/units.yaml` | 20 | count of manifest entries |
| Units per wave | wave 0: 1, wave 1a: 5, wave 1b: 13, wave 2: 1 | grouped by the `wave` field |
| Outputs declared | 48 | sum of `outputs` across the manifest |
| Golden outputs | 48 CSV files, each with a `.meta.json`, checksums verified | `python tools/check_manifest.py` printed `manifest OK` |
| `customer_ltv` goldens | `customer_ltv` 1,500 rows, `report` 6 rows | `golden/customer_ltv/*.meta.json` |
| `make check` | exit 0: ruff clean, 23 pytest tests passed, manifest OK | `make check` |
| `migration-run-2` | pushed to origin at the `main` commit, no commits of its own | `git ls-remote origin migration-run-2` |

`migration-run-2` points at the same commit as `main`. The orchestrator makes its first commit, with the Lakebridge drafts and the coverage note the record suggests, so the run history starts with work that run 2 produced.

## Run 1 work on other branches

Run 1 converted all 20 units on `migration-run-1`: `foundation`, the 18 mart units and `orchestration`, plus `databricks/udfs/`, `databricks/job/` and the bundle resources. That branch also holds 21 JSON evidence files (one per unit plus `nightly_job.json`) and the Lakebridge drafts. The prompts in this folder tell every session to convert from the run 2 Lakebridge drafts and to copy nothing from run 1.

The names `unit/<unit>` are taken by run 1 branches for all 18 mart units, and `customer_ltv` has two more (`unit/customer_ltv-ctas` and `unit/customer_ltv-terraform`). Run 2 children therefore use `unit/run-2/<unit>`, and the orchestrator and live unit prompts say so.

## Warehouse and workspace requirements

| Requirement | Where it comes from |
| --- | --- |
| Databricks CLI 0.292.0 or newer | the Databricks skill; this VM has 1.19.0 in `~/.local/bin` |
| A SQL warehouse id in `DATABRICKS_WAREHOUSE_ID` | `validation/dbsql.py` and `tools/databricks_setup.py` read it and stop without it |
| `--var warehouse_id=<id>` on every bundle command, or `BUNDLE_VAR_warehouse_id` | `databricks/databricks.yml` declares `warehouse_id` with no default |
| Permission to create a catalog, schemas and a volume | `make db-setup` runs `CREATE CATALOG IF NOT EXISTS`, then the bronze, silver and gold schemas and the `bronze.raw` volume |
| Catalog `mig_redshift_dev` for dev and validation, and `mig_redshift` for prod, which the demo validates only | `.migration/allowed_targets.json` |
| A browser login to the same workspace | the verifier needs it for the Catalog Explorer and job run screenshots |

The record calls for a 2X-Small serverless warehouse with auto-stop. Nothing in the repository checks the size, so whoever creates the warehouse should set it.

## Authentication test results

These probes ran from this VM with the `DATABRICKS_TOKEN` already in the environment. Each one only read the current user and changed nothing in any workspace.

| Host | Source of the host | Command | Exit code | Error |
| --- | --- | --- | --- | --- |
| Workspace A (`dbc-8bc9474f-…`) | named by the operator | `databricks current-user me` | 1 | `Invalid access token` |
| Workspace B (`dbc-c22a0245-…`) | `nightly_job.json`, `databricks/udfs/README.md` and `docs/migration/lakebridge-inventory.md` on `migration-run-1` | `databricks current-user me` | 1 | `Invalid access token` |
| none | `~/.databrickscfg` | `databricks auth profiles` | 1 | no configuration file found |

The token in this environment works on neither host, so no Lakebridge, setup, validation or bundle command was run. The operator note says run 1 used workspace A, and the run 1 job evidence and docs on `migration-run-1` name workspace B. The human providing the secrets should confirm which workspace run 2 uses.

## Secrets a human must provide

| Name | Value |
| --- | --- |
| `DATABRICKS_HOST` | the workspace URL for run 2, either A or B above |
| `DATABRICKS_TOKEN` | a personal access token valid on that host, for an identity with the catalog permissions above |
| `DATABRICKS_WAREHOUSE_ID` | the id of a running or auto-starting SQL warehouse in that workspace |

`MIG_CATALOG` is optional and defaults to `mig_redshift_dev`. Set all three secrets in the Partner Demo - ViewOnly org so the orchestrator, every child and the verifier inherit them.

## Points where the record and the repository disagree

1. The task describes the `aov` failure as Redshift rounding half away from zero against Databricks rounding half even. Run 1 measured a truncation instead. PR #25 kept the native `AVG` and Databricks returned six decimal places (1,308 mismatched rows), and PR #15 found 0 mismatches only when the average is truncated toward zero, against 669 for half up and 662 for half even. The live unit prompt asks the session to measure the rounding rules again and to name the cause from that table.
2. The record expects `region` to fail when `CREATE TABLE AS` widens `CHAR(4)`. In PR #25 the `region` column passed with `CREATE TABLE AS`, because the silver column was already padded `CHAR(4)`. The presenter should show it only if the first validation reports it.
3. The record assigns the orchestrator to a data persona, the live unit to an analytics engineer and the verifier to a Databricks persona. This task asks for the Databricks persona in all three sessions, and the prompts follow the task.
4. Unit counts and wave widths in the record match the manifest: 5 children in wave 1a and 13 in wave 1b.
