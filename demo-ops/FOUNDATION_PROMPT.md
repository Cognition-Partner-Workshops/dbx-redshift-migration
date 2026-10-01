# Foundation prompt

Run this as its own session before the orchestrator.

> Set up the Databricks foundation for the Redshift migration in `dbx-redshift-migration`. Start a `migration-run-1` branch off `main`. Take the Redshift table definitions in `legacy/redshift/00_foundation` and rebuild them the Databricks way in `databricks/foundation/`. First, load the raw seed files from `/Volumes/mig_redshift_dev/bronze/raw` into bronze Delta tables as-is. Then build clean, typed silver tables that mirror the Redshift core tables. Drop the Redshift-only tuning like DISTKEY and SORTKEY, and use liquid clustering where it helps. Check the silver tables match the Redshift goldens with `make validate UNIT=foundation`, then open a PR into `migration-run-1`. Stay inside the `mig_redshift_dev` catalog and follow `AGENTS.md`.
