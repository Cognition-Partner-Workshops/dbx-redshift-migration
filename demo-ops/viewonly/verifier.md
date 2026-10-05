# Verifier session for migration-run-2

The Databricks persona starts this session in the Partner Demo - ViewOnly org after the wave 1a, wave 1b and wave 2 pull requests are merged into `migration-run-2`. The verifier reruns every unit against the goldens, then deploys and runs the Lakeflow job in the dev target, and changes no code.

## Session settings

| Setting | Value |
| --- | --- |
| Repository | Cognition-Partner-Workshops/dbx-redshift-migration |
| Branch | `migration-run-2`, read only for this session |
| Environment variables | `DATABRICKS_HOST`, `DATABRICKS_TOKEN`, `DATABRICKS_WAREHOUSE_ID`, and `MIG_CATALOG` if the catalog differs from `mig_redshift_dev` |
| Read-only paths | the whole repository; the session commits nothing and opens no pull request |
| Workspace scope | the dev bundle target and the catalogs in `.migration/allowed_targets.json`; the prod target is validated and never deployed |

## Prompt

```
Act as the independent verifier for migration run migration-run-2 of Cognition-Partner-Workshops/dbx-redshift-migration, following demo-ops/VERIFIER_PROMPT.md. Check out migration-run-2 and read AGENTS.md and .migration/units.yaml.

Use the environment variables DATABRICKS_HOST, DATABRICKS_TOKEN and DATABRICKS_WAREHOUSE_ID, and MIG_CATALOG if it is set. Refer to them by name only and never print a token.

Change no code and commit nothing. Do not edit any file under legacy/, golden/, data/seed/, validation/, databricks/ or .migration/. When a unit fails, record the failure exactly as reported and move on.

Step 1. Run make validate-all and keep the full output. Post a summary table with one row per unit that has a target directory: unit, wave, build status, PASS or FAIL for each output with matched and total rows, and the evidence file path. Close the table with units PASS per wave and outputs PASS in total, counted from the evidence files under .migration/evidence/, and quote the last line of make validate-all.

Step 2. Run the Lakeflow job built from legacy/redshift/99_orchestration/refresh_schedule.yaml in the dev target only:
  databricks bundle validate -t dev --var warehouse_id=$DATABRICKS_WAREHOUSE_ID
  databricks bundle deploy -t dev --var warehouse_id=$DATABRICKS_WAREHOUSE_ID
  databricks bundle run nightly_mart_refresh -t dev --no-wait
Poll databricks jobs get-run <run_id> until the run terminates, because the CLI token can expire during a long wait. Post a table of task key and result state, and the count of tasks with SUCCESS out of the total. Run databricks bundle validate -t prod --var warehouse_id=$DATABRICKS_WAREHOUSE_ID and report the exit code, and do not deploy prod.

Step 3. Post two screenshots in this session: Catalog Explorer on the run catalog showing the bronze, silver and gold schemas with the gold tables listed, and the job run page for nightly_mart_refresh showing the task graph and its final state. Crop or blur the workspace hostname and the warehouse id in both. If the browser cannot sign in to the workspace, post the output of databricks schemas list <catalog> and databricks tables list <catalog> gold instead, and say that the screenshots are missing.
```

## Done state

The verifier is done when `make validate-all` ends with "all validated units PASS" or the summary table lists each FAIL as reported, the job run has terminated with its task table posted, and both screenshots (or the CLI listings that replace them) are in the session.
