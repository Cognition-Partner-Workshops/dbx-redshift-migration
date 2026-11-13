# Lakebridge drafts — migration-run-2

Drafts only; `make validate` is the merge gate.

- Staging: every file under `legacy/redshift/` copied to `~/mig_run2/staging/` (outside the repo) as the
  source-relative path joined with `__` (`units/daily_revenue/etl.sql` -> `units__daily_revenue__etl.sql`),
  because analyze keys its inventory by basename. Mapping + SHA-256 per file: `staging_manifest.json`.
- `databricks labs lakebridge analyze --source-directory ~/mig_run2/staging --source-tech Redshift
  --report-file .migration/lakebridge/analyze.xlsx --generate-json true` (exit 0) -> `analyze.json`
  (43 inventory entries, 36 object-lineage entries), `analyze.xlsx`, `analyze.log`.
- Per unit in `units.yaml` (its staged legacy files only): `databricks labs lakebridge transpile
  --transpiler-config-path ~/.databricks/labs/remorph-transpilers/databricks-morph-plugin/lib/config.yml
  --source-dialect redshift --input-source <staged unit dir> --output-folder <tmp>
  --error-file-path .migration/lakebridge/errors/<unit>.log --skip-validation false
  --catalog-name mig_redshift_dev --schema-name gold` (exit 0 for all 20 units). Drafts are mapped back to
  their original basenames in `transpiled/<unit>/`; console logs in `logs/`, counters in `transpile_summary.json`.
- Validation errors are EXPLAIN failures on multi-statement files / not-yet-existing objects; the drafts still
  reference Redshift `core.*`/`mart.*` and must be rewritten to `silver.*`/`gold.*`.
- `refresh_schedule.yaml` is not SQL and produced no draft.
- With `--skip-validation false`, a statement that fails validation is written inside an `Exception Start` comment block;
  the converted SQL is the text after `== SQL ==` (minus the leading `EXPLAIN`).
