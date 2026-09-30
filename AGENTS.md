# Migration session guardrails

These rules apply to every Devin session working in this repository.

- `legacy/`, `golden/`, `data/seed/` and `validation/` are **read-only** for
  migration sessions. Reconciliation failures are fixed in converted code only.
- One unit per child session. A child writes only `databricks/units/<unit>/`
  (`etl.sql`, `report.sql`), its evidence file `.migration/evidence/<unit>.json`
  (produced by `make validate`), and one row in `.migration/coverage.md`.
- Never edit goldens, tolerances, or legacy SQL. Tolerance or scope changes
  happen only with a human-approved row recorded in `.migration/06_decisions.md`.
- Write only to catalogs listed in `.migration/allowed_targets.json`
  (`mig_redshift_dev` for dev/validation, `mig_redshift` for merged prod
  deployments). Never create or modify objects in any other catalog.
- Never print, commit or paste tokens or passwords; reference env var names
  only.
- Never merge to `main`. Child PRs target `migration-run-N`; the orchestrator
  owns the run branch. Devin does not approve or merge its own PRs.
- Never run `tools/legacy_redshift.py` — Redshift is the operator-only golden
  oracle, already captured. The migration VMs never touch Redshift.
- All logic must be deterministic: no `GETDATE()`/`CURRENT_DATE`/`SYSDATE`/
  `RANDOM()` in outputs; "as of" is the literal `2025-12-31`.
