# Migration context

## Source → target contract

- Source: Amazon Redshift Serverless, database `mig_redshift_src`, schemas
  `core` (10 seeded tables) and `mart` (18 unit marts + `exec_summary`).
- Target dev catalog: `mig_redshift_dev` (env `MIG_CATALOG`), schemas
  `landing` (managed volume `raw` = historical extract), `core`, `mart`.
- Target prod catalog: `mig_redshift`, deployed only from merged PRs
  (DAB target `prod`).
- Converted SQL references unqualified `core.x` / `mart.x`; the validation
  harness sets the catalog via the Statement Execution API `catalog` field.

## Recon mode: golden snapshot

Each unit's expected outputs were captured once from Redshift into `golden/`
(CSV + `.meta.json` with column families, row count, sha256). Validation on a
migration VM compares the Databricks result to those files — there is no live
federation into Redshift.

Why: child sessions run in parallel on their own VMs; a live Redshift
dependency would make validation non-hermetic, couple every session to shared
source credentials, and break as soon as the demo source is torn down. The
golden snapshot is the deterministic oracle, and `golden/PROVENANCE.json`
records the Redshift version and source commit it came from. Row-level recon
against a live target remains possible by re-running capture.

## Determinism

Seed data is `random.Random(42)` anchored to END_DATE = 2025-12-31; all logic
uses the literal `2025-12-31` or `MAX(...)` — never `GETDATE()`/`SYSDATE`.
Goldens sort by declared output keys.

## Branch topology

`main` = pristine estate. `migration-run-N` = run integration branch.
`unit/<name>` = one child session's branch, PR'd into the run branch.
