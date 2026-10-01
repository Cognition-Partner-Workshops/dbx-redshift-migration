# Lakebridge inventory — Redshift estate (workstream 1)

Base: `origin/migration-run-1` @ `3a20265` ("Capture Lakebridge Redshift analysis and per-unit transpilation drafts").
Tooling: Databricks CLI 1.19.0, Lakebridge v0.15.2 (preinstalled, not upgraded), Morpheus 0.10.0 transpiler config
`~/.databricks/labs/remorph-transpilers/databricks-morph-plugin/lib/config.yml`, profile `DEFAULT`
(`https://dbc-c22a0245-3975.cloud.databricks.com`).

This document is evidence, not a migration. Nothing under `legacy/`, `golden/`, `data/seed/`, `validation/` or
`tolerances.yaml` was changed, `tools/legacy_redshift.py` was read but never run, and no Databricks object was created.
Ranking and effort live in [`difficulty-matrix.md`](difficulty-matrix.md).

## 1. Evidence layout

| Path | What it is |
|---|---|
| `.migration/lakebridge/analyze.json`, `analyze.xlsx`, `transpiled/<unit>/`, `errors/` | Original run (commit `3a20265`), kept untouched for comparison |
| `.migration/lakebridge/rerun/staging_manifest.json` | 43 staged files: source path, staged name, unit, wave, SHA-256, lines, statements, constructs |
| `.migration/lakebridge/rerun/analyze.{json,xlsx,log}` | Re-run of `lakebridge analyze` on the flat staging dir |
| `.migration/lakebridge/rerun/transpiled/` | Re-run of `lakebridge transpile` on the flat staging dir (42 drafts) |
| `.migration/lakebridge/rerun/transpile.log`, `transpile_errors.log` | Transpile console output and the error file |
| `.migration/lakebridge/rerun/draft_summary.json` | Per-file source-vs-draft construct diff (`tools/lakebridge_inventory.py summarize`) |
| `.migration/lakebridge/live/profiler_secret/` | Live SELECT-only discovery via Lakebridge's native profiler (redshift_connector, `demoadmin`) |
| `.migration/lakebridge/live/data-api_iam/` | Live SELECT-only discovery via Redshift Data API as `IAM:Devin-Databricks-Demo` (blocked steps recorded) |
| `.migration/lakebridge/live/data-api_secret_rejected.txt` | Data API + Secrets Manager attempt, rejected by the API |
| `tools/lakebridge_inventory.py` | Stage / analyze / summarize helper (local, read-only on the repo) |
| `tools/redshift_discovery.py`, `tools/redshift_discovery/` | SELECT-only discovery pipeline + runner + golden comparison |

## 2. Why the original analyze had only 7 inventory entries

The original run pointed `lakebridge analyze` at `legacy/redshift/` directly. Its inventory keys files by basename, so
the 18 `units/*/etl.sql`, 19 `report.sql` files (18 units + exec summary) and the exec-summary `etl.sql` collapsed into
one `etl.sql` and one `report.sql` entry (the log says the name is "already added"). The original `analyze.json`
inventory therefore lists exactly: `01_schemas.sql`, `02_core_tables.sql`, `03_udfs.sql`, `etl.sql`, `report.sql`,
`refresh_schedule.yaml`, `export.sql`. Object lineage was not affected (36 entries in both runs, same target set) because
lineage is keyed on SQL objects, not file names.

### Fix

`tools/lakebridge_inventory.py stage` copies every file under `legacy/redshift/` (`rglob("*")`, sorted, files only) into
`~/ws1_lakebridge/staging/` with the source-relative path joined by `__`:

```
legacy/redshift/units/daily_revenue/etl.sql            -> units__daily_revenue__etl.sql
legacy/redshift/99_orchestration/exec_summary/report.sql -> 99_orchestration__exec_summary__report.sql
legacy/redshift/99_orchestration/refresh_schedule.yaml   -> 99_orchestration__refresh_schedule.yaml
```

The mapping is reversible (no source path segment contains `__`) and every staged copy carries the SHA-256 of the
original in `staging_manifest.json`, so provenance back to the committed legacy file is checkable.

Commands actually run (exit codes recorded in the logs):

```bash
python tools/lakebridge_inventory.py stage           # 43 files
python tools/lakebridge_inventory.py analyze         # = the command below
DATABRICKS_CONFIG_PROFILE=DEFAULT databricks labs lakebridge analyze \
  --source-directory ~/ws1_lakebridge/staging \
  --report-file .migration/lakebridge/rerun/analyze.xlsx \
  --source-tech Redshift --generate-json true          # exit 0
DATABRICKS_CONFIG_PROFILE=DEFAULT databricks labs lakebridge transpile \
  --transpiler-config-path ~/.databricks/labs/remorph-transpilers/databricks-morph-plugin/lib/config.yml \
  --source-dialect redshift --input-source ~/ws1_lakebridge/staging \
  --output-folder .migration/lakebridge/rerun/transpiled \
  --error-file-path .migration/lakebridge/rerun/transpile_errors.log \
  --skip-validation true --catalog-name mig_redshift_dev --schema-name silver   # exit 0
python tools/lakebridge_inventory.py summarize       # draft_summary.json
```

`--catalog-name/--schema-name` only parameterise the (skipped) validation; nothing is written to any catalog.

## 3. Re-run results (actual counts)

| Metric | Original (`3a20265`) | Re-run (flat staging) |
|---|---|---|
| Files under `legacy/redshift/` | 43 | 43 staged |
| `analyze` inventory entries | **7** | **43** |
| `analyze` object-lineage entries | 36 | 36 (identical target set) |
| `analyze` complexity | all LOW | 42 LOW, 1 MEDIUM (`churn_flags/etl.sql`) |
| `analyze` `runInfo.sourceTechnology` | `SQL` | `SQL` (despite `--source-tech Redshift`) |
| `transpile` files processed / SQL queries | 18 unit dirs, 37 files | 43 files, 42 SQL (YAML not transpiled) |
| `transpile` exit code | 0 | 0 |
| `transpile` summary error counters (analysis/parsing/validation/generation) | - | all 0, while the error file holds 1 entry |
| `transpile` errors/warnings | 1 (`finance_export/export.sql`) | 1 (`units__finance_export__export.sql`) |
| Re-run drafts byte-identical to the original 37 unit drafts | - | 37 / 37 |
| New drafts (not in original) | - | 5: foundation `01_schemas`, `02_core_tables`, `03_udfs`, exec summary `etl`, `report` |

The re-run was repeated into a scratch folder with exactly the command above and produced byte-identical drafts.

The single transpile error, kept verbatim in `rerun/transpile_errors.log`:

```
TranspileError(code=None, kind=INTERNAL, severity=WARNING,
  path='~/ws1_lakebridge/staging/units__finance_export__export.sql',
  message='REDSHIFT: Databricks SQL has no equivalent to the UNLOAD command, and it cannot be translated')
```

Exit 0 is **not** a readiness signal: the CLI returns 0 with this error, and (section 5) several drafts that raise no
error at all are semantically wrong. Lakebridge emits no readiness score; none is reported here. The analyzer
complexity column is copied verbatim; it rates 42/43 files LOW, including the SUPER/PartiQL unit, the second PL/pgSQL
procedure (`inventory_snapshot`) and the `UNLOAD` export, so it must not be used for ranking.

### Analyzer and tool limitations observed

- **Basename de-duplication** (section 2): silent loss of 36 of 43 files in the inventory without the flat staging.
- **YAML classified as SQL**: `99_orchestration__refresh_schedule.yaml` is inventoried as `scriptType=SQL`,
  category `UNKNOWN`, 1 statement. The scheduler semantics (two parallel waves, dependencies) are invisible to
  Lakebridge; section 6 documents them by hand.
- **Lineage gaps**: lineage has 17 `mart.*` targets. Missing: `mart.churn_flags` (written only inside the procedure
  body) and `mart.exec_summary` (and its 4 `mart.*` reads). Lineage also lists CTE / temp names as objects
  (`agg`, `flagged`, `metrics`, `order_totals`, `stg_inventory`, `tmp_*`) and the PartiQL path `t.payload.touches`.
- **Procedure statement counts**: the analyzer counts `churn_flags/etl.sql` as 11 statements and
  `inventory_snapshot/etl.sql` as 10 (it descends into `$$` bodies); top-level count is 4 each (`staging_manifest.json`).
- **Summary counters**: the transpile summary prints `analysis/parsing/validation/generation_error_count = 0` while
  logging `units__finance_export__export.sql: 1 found` and writing one entry to the error file.
- **`sourceTechnology=SQL`** in `runInfo` even though `--source-tech Redshift` was passed.

## 4. Staged file inventory (43 files, provenance)

`Stmts` = top-level statements outside `$$` bodies / quotes / comments (helper count). Analyzer columns are verbatim.

| # | Source path | Staged name | Unit | Wave | SHA-256 (12) | Lines | Stmts | Analyzer complexity | Analyzer categories |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `legacy/redshift/00_foundation/01_schemas.sql` | `00_foundation__01_schemas.sql` | foundation | 0 | `193f84793a54` | 4 | 2 | LOW | UNKNOWN |
| 2 | `legacy/redshift/00_foundation/02_core_tables.sql` | `00_foundation__02_core_tables.sql` | foundation | 0 | `68ddc1918d12` | 107 | 10 | LOW | TABLE_DDL |
| 3 | `legacy/redshift/00_foundation/03_udfs.sql` | `00_foundation__03_udfs.sql` | foundation | 0 | `5aa33e6c8bd8` | 17 | 2 | LOW | PROGRAM_DECLARATION |
| 4 | `legacy/redshift/99_orchestration/exec_summary/etl.sql` | `99_orchestration__exec_summary__etl.sql` | orchestration | 2 | `8e591b9e5f51` | 18 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 5 | `legacy/redshift/99_orchestration/exec_summary/report.sql` | `99_orchestration__exec_summary__report.sql` | orchestration | 2 | `503d760bd876` | 5 | 1 | LOW | READ_DML |
| 6 | `legacy/redshift/99_orchestration/refresh_schedule.yaml` | `99_orchestration__refresh_schedule.yaml` | orchestration | 2 | `7fd4c71414c1` | 39 | 1 | LOW | UNKNOWN |
| 7 | `legacy/redshift/units/attribution/etl.sql` | `units__attribution__etl.sql` | attribution | 1b | `3edd3a9e0c8d` | 10 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 8 | `legacy/redshift/units/attribution/report.sql` | `units__attribution__report.sql` | attribution | 1b | `7015ba01d946` | 7 | 1 | LOW | READ_DML |
| 9 | `legacy/redshift/units/basket_affinity/etl.sql` | `units__basket_affinity__etl.sql` | basket_affinity | 1b | `e4feec01cd9f` | 12 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 10 | `legacy/redshift/units/basket_affinity/report.sql` | `units__basket_affinity__report.sql` | basket_affinity | 1b | `d0187b89a210` | 10 | 1 | LOW | READ_DML |
| 11 | `legacy/redshift/units/category_mix/etl.sql` | `units__category_mix__etl.sql` | category_mix | 1b | `ecbc34208b32` | 16 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 12 | `legacy/redshift/units/category_mix/report.sql` | `units__category_mix__report.sql` | category_mix | 1b | `b77f5f1a8278` | 4 | 1 | LOW | READ_DML |
| 13 | `legacy/redshift/units/churn_flags/etl.sql` | `units__churn_flags__etl.sql` | churn_flags | 1a | `c2264bd6253b` | 53 | 4 | MEDIUM | CALL, CREATE_PROCEDURE, END_LOOP, INSERT_INTO, SELECT_INTO_REAL_TABLE, TABLE_DDL, TABLE_DROP, UNKNOWN |
| 14 | `legacy/redshift/units/churn_flags/report.sql` | `units__churn_flags__report.sql` | churn_flags | 1a | `6cce3da438bb` | 7 | 1 | LOW | READ_DML |
| 15 | `legacy/redshift/units/cohort_retention/etl.sql` | `units__cohort_retention__etl.sql` | cohort_retention | 1b | `479028c33d38` | 40 | 9 | LOW | INSERT_INTO, TABLE_DDL, TABLE_DDL_AS_SELECT, TABLE_DROP |
| 16 | `legacy/redshift/units/cohort_retention/report.sql` | `units__cohort_retention__report.sql` | cohort_retention | 1b | `d2699a301ce6` | 8 | 1 | LOW | READ_DML |
| 17 | `legacy/redshift/units/customer_ltv/etl.sql` | `units__customer_ltv__etl.sql` | customer_ltv | 1a | `a16e001290eb` | 19 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 18 | `legacy/redshift/units/customer_ltv/report.sql` | `units__customer_ltv__report.sql` | customer_ltv | 1a | `4d248888d49a` | 9 | 1 | LOW | READ_DML |
| 19 | `legacy/redshift/units/daily_revenue/etl.sql` | `units__daily_revenue__etl.sql` | daily_revenue | 1a | `aafbe9cd21c2` | 14 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 20 | `legacy/redshift/units/daily_revenue/report.sql` | `units__daily_revenue__report.sql` | daily_revenue | 1a | `2693ba30d4bd` | 8 | 1 | LOW | READ_DML |
| 21 | `legacy/redshift/units/finance_export/etl.sql` | `units__finance_export__etl.sql` | finance_export | 1b | `58ca7bd6934a` | 16 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 22 | `legacy/redshift/units/finance_export/export.sql` | `units__finance_export__export.sql` | finance_export | 1b | `1005e292f35f` | 8 | 1 | LOW | UNKNOWN |
| 23 | `legacy/redshift/units/finance_export/report.sql` | `units__finance_export__report.sql` | finance_export | 1b | `484efed45891` | 7 | 1 | LOW | READ_DML |
| 24 | `legacy/redshift/units/geo_rollup/etl.sql` | `units__geo_rollup__etl.sql` | geo_rollup | 1a | `cdbbc0cb2e16` | 18 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 25 | `legacy/redshift/units/geo_rollup/report.sql` | `units__geo_rollup__report.sql` | geo_rollup | 1a | `ac0a6cb480c6` | 4 | 1 | LOW | READ_DML |
| 26 | `legacy/redshift/units/inventory_snapshot/etl.sql` | `units__inventory_snapshot__etl.sql` | inventory_snapshot | 1b | `45f645a4d5c0` | 41 | 4 | LOW | CALL, CREATE_PROCEDURE, DELETE, INSERT_INTO, TABLE_DDL, TABLE_DROP, UNKNOWN |
| 27 | `legacy/redshift/units/inventory_snapshot/report.sql` | `units__inventory_snapshot__report.sql` | inventory_snapshot | 1b | `ba99820570e2` | 5 | 1 | LOW | READ_DML |
| 28 | `legacy/redshift/units/payment_mix/etl.sql` | `units__payment_mix__etl.sql` | payment_mix | 1b | `cd2041d304e8` | 17 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 29 | `legacy/redshift/units/payment_mix/report.sql` | `units__payment_mix__report.sql` | payment_mix | 1b | `35a1b5ba1094` | 7 | 1 | LOW | READ_DML |
| 30 | `legacy/redshift/units/product_perf/etl.sql` | `units__product_perf__etl.sql` | product_perf | 1a | `1ed1a5409e23` | 43 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 31 | `legacy/redshift/units/product_perf/report.sql` | `units__product_perf__report.sql` | product_perf | 1a | `ee34baefbebe` | 8 | 1 | LOW | READ_DML |
| 32 | `legacy/redshift/units/promo_lift/etl.sql` | `units__promo_lift__etl.sql` | promo_lift | 1b | `f93eec6fb755` | 18 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 33 | `legacy/redshift/units/promo_lift/report.sql` | `units__promo_lift__report.sql` | promo_lift | 1b | `da604b9ede06` | 4 | 1 | LOW | READ_DML |
| 34 | `legacy/redshift/units/returns_rate/etl.sql` | `units__returns_rate__etl.sql` | returns_rate | 1b | `b6bccd75e250` | 15 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 35 | `legacy/redshift/units/returns_rate/report.sql` | `units__returns_rate__report.sql` | returns_rate | 1b | `39d3474a65fe` | 4 | 1 | LOW | READ_DML |
| 36 | `legacy/redshift/units/rfm_segments/etl.sql` | `units__rfm_segments__etl.sql` | rfm_segments | 1b | `f45735bda11e` | 37 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 37 | `legacy/redshift/units/rfm_segments/report.sql` | `units__rfm_segments__report.sql` | rfm_segments | 1b | `973880a67fd6` | 8 | 1 | LOW | READ_DML |
| 38 | `legacy/redshift/units/sessionization/etl.sql` | `units__sessionization__etl.sql` | sessionization | 1b | `f5766aca8358` | 42 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 39 | `legacy/redshift/units/sessionization/report.sql` | `units__sessionization__report.sql` | sessionization | 1b | `f2f5bfbf4291` | 8 | 1 | LOW | READ_DML |
| 40 | `legacy/redshift/units/shipping_sla/etl.sql` | `units__shipping_sla__etl.sql` | shipping_sla | 1b | `6a54699a1749` | 17 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 41 | `legacy/redshift/units/shipping_sla/report.sql` | `units__shipping_sla__report.sql` | shipping_sla | 1b | `3fe2b9c97460` | 5 | 1 | LOW | READ_DML |
| 42 | `legacy/redshift/units/store_weekly/etl.sql` | `units__store_weekly__etl.sql` | store_weekly | 1b | `437fbe6a31b9` | 17 | 2 | LOW | TABLE_DDL_AS_SELECT, TABLE_DROP |
| 43 | `legacy/redshift/units/store_weekly/report.sql` | `units__store_weekly__report.sql` | store_weekly | 1b | `fdd6e8a8d3c2` | 10 | 1 | LOW | READ_DML |

## 5. Draft inspection: what the transpiler did and did not do

Every one of the 42 drafts was read against its source. Findings fall into three classes. "Silent" means no
Lakebridge error, warning or `FIXME` was emitted.

### 5.1 Unsupported (flagged by the tool)

| File | Draft | Note |
|---|---|---|
| `units/finance_export/export.sql` | `-- FIXME: REDSHIFT: Databricks SQL has no equivalent to the UNLOAD command, and it cannot be translated` + the original `UNLOAD` as a comment | 0 executable statements. The source is a placeholder (`s3://<bucket>`, `IAM_ROLE '<role-arn>'`) that `capture_skip` excludes, so there is no golden output for it. |

### 5.2 Procedural / structural constructs translated mechanically (silent, need manual rewrite)

| File | Source | Draft | Why it still needs manual work |
|---|---|---|---|
| `units/churn_flags/etl.sql` | `CREATE PROCEDURE ... LANGUAGE plpgsql` with `DECLARE rec RECORD`, `CREATE TEMP TABLE`, `FOR rec IN ... LOOP INSERT ... END LOOP`, `CALL` | `CREATE PROCEDURE ... LANGUAGE SQL SQL SECURITY INVOKER`, `CREATE TEMPORARY TABLE`, `FOR rec AS ... DO ... END FOR`, `CALL` | `DECLARE rec RECORD` is dropped (fine for a SQL-scripting `FOR`), but the row-by-row insert loop is preserved. `'2025-12-31'::DATE - rec.last_order_date` becomes `CAST(... AS DATE) - rec.last_order_date`, which is an `INTERVAL DAY` in Databricks, not an INT: it cannot be inserted into `days_since_order INT` or compared with `> 180`. Writes `mart.*`, not `gold.*`. A set-based CTAS with `DATEDIFF(DAY, ...)` removes procedure, temp table and loop. |
| `units/inventory_snapshot/etl.sql` | PL/pgSQL `sp_upsert_inventory(p_snapshot DATE)`: temp staging table, `DELETE ... WHERE product_id IN (staging)` + `INSERT`, then `CALL sp_upsert_inventory('2025-12-31')` | Same shape as Databricks SQL procedure with `CREATE TEMPORARY TABLE`, `DELETE`, `INSERT`, `CALL` | DELETE+INSERT upsert should be a `MERGE` (or CTAS, since the table is recreated just before); procedure + temp table + `CALL` with argument all need a decision for the Databricks target. Analyzer rates it LOW. |
| `units/cohort_retention/etl.sql` | `CREATE TEMP TABLE tmp_cohorts / tmp_activity` + `INSERT`, explicit `DROP`s | `CREATE TEMPORARY TABLE ... AS`, `DROP TABLE IF EXISTS`, `INSERT` | Temp tables are kept as session temp tables; refactor to CTEs in one CTAS. `SORTKEY(...)` left as a comment. |
| `units/attribution/etl.sql` | `FROM core.campaign_touches t, t.payload.touches tc` (PartiQL SUPER unnest) + `tc.campaign_id::VARCHAR` etc. | `core.campaign_touches AS t CROSS JOIN t.payload.touches AS tc`; the `::` casts become `CAST(tc.x AS ...)` | Not valid Databricks SQL: navigation into an array needs `LATERAL VARIANT_EXPLODE(t.payload:touches)` / `explode(from_json(...))`, and field access needs `:`-paths. Depends on how foundation lands `payload` (draft DDL: `VARIANT`). No warning emitted. |
| `00_foundation/03_udfs.sql` | `f_fiscal_qtr(d DATE) RETURNS VARCHAR(8)` with integer `/ 3`; `f_clean_phone` | `RETURN 'Q' \|\| CAST(((((CAST(EXTRACT(month FROM d) AS INT) + 9) % 12) / 3) + 1) AS STRING)` | In Databricks `/` on INT returns DOUBLE: March gives `'Q1.0'`, February `'Q4.666...'` instead of `Q1`/`Q4`. Needs `DIV`. `f_clean_phone` translates correctly. |
| `units/finance_export/etl.sql` | `f_fiscal_qtr(o.order_ts::DATE)` | `F_FISCAL_QTR(CAST(CAST(o.order_ts AS DATE) AS DATE))` | The call is kept; it inherits the UDF bug above and needs the UDF to exist in the target schema. |
| `units/customer_ltv/etl.sql` | `f_clean_phone(c.phone)` | `F_CLEAN_PHONE(c.phone)` | Same UDF dependency (foundation owns it). |
| All unit ETLs | `core.*` / `mart.*`; `DISTKEY`, `SORTKEY`, `DISTSTYLE`, `ENCODE` | Names unchanged; distribution / sort / encoding moved into `/* ... */` comments | Schema remap `core->silver`, `mart->gold` is manual for every unit; physical-design clauses are dropped (correct, but liquid clustering is not proposed). |

### 5.3 Dialect semantics that change silently (executes, fails golden)

Tolerances: `decimal_abs 1e-6`, `float_rel/abs 1e-9`, `string_rstrip false` (`validation/tolerances.yaml`); decimal
comparison is by value, so scale only matters when it changes the value.

| Unit | Source construct | Draft | Golden evidence | Effect |
|---|---|---|---|---|
| returns_rate | `COALESCE(SUM(r.quantity),0) / SUM(oi.quantity)` (BIGINT / BIGINT) | unchanged | `return_rate_int` = `0` (int family) | Databricks `/` returns DOUBLE (~0.05): wrong value and type. Needs `DIV`. |
| store_weekly | `DATEDIFF(week, '2025-01-01', week_start)` | unchanged | week `2025-01-06` → `week_number 1`; week `2024-12-30` → `0` | Redshift counts week boundaries; Databricks `DATEDIFF(WEEK, ...)` counts complete 7-day periods (`2025-01-01 → 2025-01-06` = 0). Manifest says `clean`. |
| shipping_sla | `DATEDIFF(hour, ship_ts, delivered_ts)`; `AVG(<int>)::NUMERIC(10,2)` | unchanged | `avg_hours_to_deliver 71.00` | Boundary vs elapsed hours, and Redshift `AVG` of an integer returns a truncated integer (71 → `71.00`) whereas Databricks returns a fractional DOUBLE. `CONVERT_TIMEZONE` is kept (exists in Databricks; verify). |
| customer_ltv | `AVG(oi.unit_price - oi.discount)` on NUMERIC(12,2); `region CHAR(4)` | unchanged | `aov 193.25`; `region` padded (`NRTH`, `WEST`) | Redshift returns `AVG` at input scale 2; Databricks `avg(decimal(13,2))` returns scale 6 with more significant digits (> 1e-6 off). CHAR padding must survive foundation's type choice. |
| category_mix | `RATIO_TO_REPORT(revenue) OVER ()` | `revenue / SUM(revenue) OVER ()` | `revenue_share` float family, 17 digits | Rewrite is DECIMAL division (scale ~6 in Databricks) vs Redshift DOUBLE: ~2e-6 relative error > `float_rel 1e-9`. Needs `CAST(... AS DOUBLE)`. Manifest says `clean`. |
| payment_mix | `SUM(amount) / SUM(SUM(amount)) OVER ()`; `DECODE`, `NVL`, `NVL2` | `NVL` → `IFNULL`; `DECODE`, `NVL2` kept | `amount_share 0.4276` (decimal, scale 4) | Databricks decimal division keeps more digits (> 1e-6 off); needs an explicit cast to Redshift's result scale. `DECODE` / `NVL2` exist in Databricks. |
| promo_lift | `MEDIAN(order_total)`, `PERCENTILE_CONT(0.9) WITHIN GROUP (...)` | unchanged | `390.21`, `1093.96` (decimal) | Redshift returns DECIMAL at input scale; Databricks `median` / `percentile_cont` likely return DOUBLE with interpolation past 2 decimals (inference, verify on the warehouse). Cast to match golden. |
| product_perf | `LISTAGG(region, ',') WITHIN GROUP (ORDER BY units DESC, region)` | `ARRAY_JOIN(TRANSFORM(ARRAY_SORT(ARRAY_AGG(NAMED_STRUCT(...)), <lambda>), s -> s.value), ',')` | `top_stores "SOTH,WEST,EAST"` | Generated, hard-to-review lambda comparator; tie / NULL ordering must be checked against golden. |
| rfm_segments | `NTILE(5) OVER (ORDER BY recency_days ASC, ...)`, `... DESC` with Redshift default NULL ordering | `ASC NULLS LAST`, `DESC NULLS FIRST` added | - | Correctly preserves Redshift defaults (Databricks default is NULLS FIRST for ASC). Customers with no orders (`LEFT JOIN`) make NULL `recency_days` real here. |
| sessionization | `DATEDIFF(second, LAG(event_ts) ..., event_ts)` | unchanged | seed `event_ts` whole seconds | Boundary vs elapsed seconds coincide for whole-second timestamps; low risk. |
| cohort_retention | `DATEDIFF(month, cohort_month, DATE_TRUNC('month', ...))` | unchanged | - | Both arguments are month-truncated, so boundary = elapsed; low risk. |
| daily_revenue, geo_rollup, basket_affinity | `TRUNC`, `::DATE`, `GROUPING SETS`, `GROUPING`, self-join | standard Databricks SQL | - | No semantic findings beyond the schema remap. |

Every draft also keeps `core.*` reads and `mart.*` writes.

## 6. Manually derived context (not visible to Lakebridge)

### UDF bodies (`legacy/redshift/00_foundation/03_udfs.sql`, confirmed live in `pg_proc_info`)

```sql
CREATE OR REPLACE FUNCTION f_fiscal_qtr(d DATE)
RETURNS VARCHAR(8)
IMMUTABLE
AS $$
    SELECT 'Q' || ((((EXTRACT(MONTH FROM $1)::INT + 9) % 12) / 3) + 1)::VARCHAR
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION f_clean_phone(p VARCHAR)
RETURNS VARCHAR(32)
IMMUTABLE
AS $$
    SELECT REGEXP_REPLACE($1, '[^0-9]', '')
$$ LANGUAGE SQL;
```

The source comment says "Feb-Apr = Q1" but the body maps Mar-May to Q1 and February to Q4; golden
`finance_monthly.csv` confirms the body (`2025-02-01, 2025, Q4`; `2025-03-01, 2025, Q1`), while `fiscal_year` rolls over
in February. The body, not the comment, is the contract to preserve.

### Schedule (`99_orchestration/refresh_schedule.yaml`)

`nightly_mart_refresh`, cron `0 2 * * *` UTC:

```
load_core      runs: tools/legacy_redshift.py setup --ddl-only     depends_on: []
wave_1a  (5)   daily_revenue, customer_ltv, geo_rollup, churn_flags, product_perf          depends_on: [load_core]
wave_1b  (13)  store_weekly, category_mix, basket_affinity, sessionization, shipping_sla,
               rfm_segments, promo_lift, payment_mix, returns_rate, attribution,
               inventory_snapshot, finance_export, cohort_retention                         depends_on: [load_core]
exec_summary   99_orchestration/exec_summary/etl.sql               depends_on: [wave_1a, wave_1b]
finance_export units/finance_export/export.sql                     depends_on: [wave_1b]
```

Wave 1a and wave 1b both depend only on `load_core`, so they are **two parallel waves**, not sequential; the 18 units
have no inter-unit dependencies. `exec_summary` joins both waves; the export runs after wave 1b only. Lakebridge did not
parse any of this (section 3).

### Loader (`tools/legacy_redshift.py`, read only)

- CLI accepts exactly one argument in `setup | build | capture | all`; anything else exits with usage.
  **The scheduled `setup --ddl-only` is not implemented** and would fail the `load_core` step as written.
- `setup` runs `DROP SCHEMA IF EXISTS core CASCADE` and `DROP SCHEMA IF EXISTS mart CASCADE`, re-runs the foundation
  DDL and UDFs, then loads every CSV under `data/seed/csv/` into `core.*`. It is destructive, which is why it was not run.
- `build` walks units in manifest wave order and executes only `etl.sql` files, skipping anything in `capture_skip` or
  not ending in `.sql`. `capture` iterates manifest `outputs` (mart tables and `report.sql` queries) and writes
  `golden/`. Hence `finance_export/export.sql` (the `UNLOAD` placeholder) is never executed and has no golden output,
  and the YAML is never executed. The scheduler's wave split is not reproduced by `build` either (it is sequential).

### Exec summary scope

`99_orchestration/exec_summary/etl.sql` reads **four** marts, not all 18: `mart.daily_revenue` (`SUM(revenue)`,
`SUM(order_count)`), `mart.customer_ltv` (`AVG(ltv)`), `mart.returns_rate` (`SUM(returned_qty)::NUMERIC(14,4) /
SUM(sold_qty)::NUMERIC(14,4) * 100`) and `mart.shipping_sla` (delivered-weighted `avg_hours_to_deliver`). Its golden row
therefore inherits the `customer_ltv` and `shipping_sla` scale semantics above.

## 7. Deterministic unit enumeration (`.migration/units.yaml`, manifest order)

Waves: `0` foundation (1) → `1a` (5) ‖ `1b` (13) → `2` orchestration (1). Target names are as declared in the
manifest (`silver.*` = legacy `core.*`, `gold.*` = legacy `mart.*`).

| # | Unit | Wave | Legacy files | Reads (target) | Writes (target) | Outputs: golden path (keys) | Manifest expected | Manifest constructs | capture_skip |
|---|---|---|---|---|---|---|---|---|---|
| 1 | daily_revenue | 1a | etl.sql, report.sql | silver.orders, silver.order_items | gold.daily_revenue | `golden/daily_revenue/daily_revenue.csv` (order_date, sales_channel)<br>`golden/daily_revenue/report.csv` (order_month, sales_channel) | clean | DATE_TRUNC; TRUNC; SUM; COUNT DISTINCT | - |
| 2 | customer_ltv | 1a | etl.sql, report.sql | silver.customers, silver.orders, silver.order_items | gold.customer_ltv | `golden/customer_ltv/customer_ltv.csv` (customer_id)<br>`golden/customer_ltv/report.csv` (region) | mismatch | CHAR(4) padding; AVG on NUMERIC(12,2); LEFT JOIN; COALESCE | - |
| 3 | geo_rollup | 1a | etl.sql, report.sql | silver.stores, silver.orders, silver.order_items | gold.geo_rollup | `golden/geo_rollup/geo_rollup.csv` (grouping_id, region, state)<br>`golden/geo_rollup/report.csv` (grouping_id, region, state) | clean | GROUPING SETS; GROUPING; COUNT DISTINCT | - |
| 4 | churn_flags | 1a | etl.sql, report.sql | silver.customers, silver.orders | gold.churn_flags | `golden/churn_flags/churn_flags.csv` (customer_id)<br>`golden/churn_flags/report.csv` (churn_flag) | rejected | plpgsql procedure; FOR loop; temp table; CALL; date arithmetic | - |
| 5 | product_perf | 1a | etl.sql, report.sql | silver.products, silver.order_items, silver.orders, silver.stores | gold.product_perf | `golden/product_perf/product_perf.csv` (product_id)<br>`golden/product_perf/report.csv` (category) | mismatch | LISTAGG WITHIN GROUP; ROW_NUMBER; ::casts | - |
| 6 | store_weekly | 1b | etl.sql, report.sql | silver.orders, silver.order_items, silver.stores | gold.store_weekly | `golden/store_weekly/store_weekly.csv` (store_id, week_start)<br>`golden/store_weekly/report.csv` (store_id) | clean | DATE_TRUNC('week'); DATEADD; DATEDIFF(week) | - |
| 7 | category_mix | 1b | etl.sql, report.sql | silver.products, silver.order_items | gold.category_mix | `golden/category_mix/category_mix.csv` (category)<br>`golden/category_mix/report.csv` (category) | clean | RATIO_TO_REPORT; window function over aggregate | - |
| 8 | basket_affinity | 1b | etl.sql, report.sql | silver.order_items, silver.products | gold.basket_affinity | `golden/basket_affinity/basket_affinity.csv` (product_id_a, product_id_b)<br>`golden/basket_affinity/report.csv` (product_id_a, product_id_b) | clean | self-join pairs; HAVING threshold; COUNT DISTINCT | - |
| 9 | sessionization | 1b | etl.sql, report.sql | silver.web_events | gold.web_sessions | `golden/sessionization/web_sessions.csv` (customer_id, session_id)<br>`golden/sessionization/report.csv` (customer_id) | clean | LAG; DATEDIFF(second) gap; running SUM session id | - |
| 10 | shipping_sla | 1b | etl.sql, report.sql | silver.shipments | gold.shipping_sla | `golden/shipping_sla/shipping_sla.csv` (carrier)<br>`golden/shipping_sla/report.csv` (carrier) | mismatch | DATEDIFF(hour) boundary counting; CONVERT_TIMEZONE; EXTRACT(HOUR) | - |
| 11 | rfm_segments | 1b | etl.sql, report.sql | silver.customers, silver.orders, silver.order_items | gold.rfm_segments | `golden/rfm_segments/rfm_segments.csv` (customer_id)<br>`golden/rfm_segments/report.csv` (rfm_segment) | mismatch | NTILE(5); implicit NULL ordering (no NULLS LAST); DATEDIFF(day) | - |
| 12 | promo_lift | 1b | etl.sql, report.sql | silver.orders, silver.order_items | gold.promo_lift | `golden/promo_lift/promo_lift.csv` (sales_channel)<br>`golden/promo_lift/report.csv` (sales_channel) | mismatch | MEDIAN; PERCENTILE_CONT WITHIN GROUP | - |
| 13 | payment_mix | 1b | etl.sql, report.sql | silver.payments | gold.payment_mix | `golden/payment_mix/payment_mix.csv` (method)<br>`golden/payment_mix/report.csv` (method_family) | mismatch | DECODE; NVL; NVL2; window share | - |
| 14 | returns_rate | 1b | etl.sql, report.sql | silver.order_items, silver.products, silver.returns | gold.returns_rate | `golden/returns_rate/returns_rate.csv` (category)<br>`golden/returns_rate/report.csv` (category) | mismatch | integer division; ::NUMERIC casts | - |
| 15 | attribution | 1b | etl.sql, report.sql | silver.campaign_touches | gold.attribution | `golden/attribution/attribution.csv` (campaign_id, touch_channel)<br>`golden/attribution/report.csv` (campaign_id) | rejected | SUPER; PartiQL unnesting (t, t.payload.touches tc); SUPER ::casts | - |
| 16 | inventory_snapshot | 1b | etl.sql, report.sql | silver.products, silver.order_items | gold.inventory_snapshot | `golden/inventory_snapshot/inventory_snapshot.csv` (product_id)<br>`golden/inventory_snapshot/report.csv` (product_id) | rejected | plpgsql procedure; staging temp table; DELETE/INSERT upsert; CALL with arg | - |
| 17 | finance_export | 1b | etl.sql, report.sql, export.sql | silver.orders, silver.order_items | gold.finance_monthly | `golden/finance_export/finance_monthly.csv` (month)<br>`golden/finance_export/report.csv` (fiscal_year, fiscal_qtr) | rejected | f_fiscal_qtr UDF; UNLOAD TO s3 IAM_ROLE (never executed at capture) | `legacy/redshift/units/finance_export/export.sql` |
| 18 | cohort_retention | 1b | etl.sql, report.sql | silver.orders | gold.cohort_retention | `golden/cohort_retention/cohort_retention.csv` (cohort_month, month_offset)<br>`golden/cohort_retention/report.csv` (cohort_month, month_offset) | rejected | CREATE TEMP TABLE steps; DATEDIFF(month) retention matrix | - |

## 8. Live Redshift discovery (SELECT-only)

### Method and deviations

- Lakebridge's shipped Redshift profiler pipeline starts with two `source_ddl` steps (`0_drop_query_view.sql`,
  `0_query_view.sql`) that drop/create a view in the source. It was **not** run. Instead
  `tools/redshift_discovery/pipeline_config.yml` defines 11 `sql` steps (no `ddl`/`source_ddl`), and
  `tools/redshift_discovery.py` refuses any step that is not a single `SELECT`/`WITH` or contains a write/DDL/grant
  keyword before connecting.
- **Native connector (primary)**: the same pipeline is executed through Lakebridge's own `Profiler("redshift")`
  (redshift_connector over TCP 5439, SSL) with an env-vault credential file whose user/password entries are
  environment-variable *names*; the values are read in-process from the `sqlworkbench!...` Secrets Manager secret
  (`dbClusterIdentifier=demo-wg`, `engine=redshift`, user `demoadmin`). Values were never printed or written.
- **Data API + IAM**: the same SQL through `redshift-data ExecuteStatement` (`WorkgroupName=demo-wg`,
  `Database=mig_redshift_src`), user `IAM:Devin-Databricks-Demo`. AWS `ExecuteStatement` docs were read first.
- **Data API + secret**: rejected by the API (`Invalid secret for serverless, dbClusterIdentifier should not be
  specified`), see `live/data-api_secret_rejected.txt`. That is why the secret is only used over JDBC/native.
- No grants were changed. `demoadmin` is a superuser (`pg_user.usesuper = true`), so this run's visibility is not a
  least-privilege result; the IAM run is.

### Results by identity

| Step | Profiler / `demoadmin` | Data API / `IAM:Devin-Databricks-Demo` |
|---|---|---|
| session_identity | COMPLETE | COMPLETE |
| information_schema.tables (core, mart) | COMPLETE, 29 | COMPLETE, **0** (privilege-filtered) |
| pg_class relations | COMPLETE, 29 | COMPLETE, 29 |
| columns / dist / sort / encoding | COMPLETE, 155 | COMPLETE, 155 |
| routines (`pg_proc_info`) | COMPLETE, 4 | COMPLETE, 4 |
| svv_table_info | COMPLETE, 29 (first run returned 0 rows; re-run 29; direct probe 29) | ERROR `permission denied for relation svv_table_info` |
| core exact counts | COMPLETE, 10 | ERROR `permission denied for schema core` |
| mart exact counts | COMPLETE, 19 | ERROR `permission denied for schema mart` |
| exec_summary values | COMPLETE, 1 | ERROR `permission denied for schema mart` |
| sys_serverless_usage storage / RPU | COMPLETE | ABSENT `permission denied for relation sys_serverless_usage` |

The IAM run confirms the earlier observation: `information_schema.tables` is empty for `core`/`mart` because it is
privilege-filtered, while `pg_class` shows all 29 tables exist.

### Exact counts vs committed golden snapshot

All 29 legacy tables: live `COUNT(*)` = golden `.meta.json` `row_count` (29 MATCH, 0 MISMATCH, 0 BLOCKED;
`live/profiler_secret/golden_comparison.json`). Live `mart.exec_summary` values equal `golden/orchestration/exec_summary.csv`
exactly (`as_of_2025-12-31, 2025-12-31, 10543825.25, 20000, 7029.21, 5.013772053897100, 71.2551`). This is aggregate
evidence only; the golden CSVs remain the row-level oracle.

| Legacy table | Golden snapshot rows | Live exact COUNT(*) | Status |
|---|---|---|---|
| `core.campaign_touches` | 8000 | 8000 | MATCH |
| `core.customers` | 1500 | 1500 | MATCH |
| `core.order_items` | 40938 | 40938 | MATCH |
| `core.orders` | 20000 | 20000 | MATCH |
| `core.payments` | 20000 | 20000 | MATCH |
| `core.products` | 300 | 300 | MATCH |
| `core.returns` | 2518 | 2518 | MATCH |
| `core.shipments` | 12817 | 12817 | MATCH |
| `core.stores` | 40 | 40 | MATCH |
| `core.web_events` | 25000 | 25000 | MATCH |
| `mart.attribution` | 100 | 100 | MATCH |
| `mart.basket_affinity` | 50 | 50 | MATCH |
| `mart.category_mix` | 6 | 6 | MATCH |
| `mart.churn_flags` | 1500 | 1500 | MATCH |
| `mart.cohort_retention` | 65 | 65 | MATCH |
| `mart.customer_ltv` | 1500 | 1500 | MATCH |
| `mart.daily_revenue` | 1460 | 1460 | MATCH |
| `mart.exec_summary` | 1 | 1 | MATCH |
| `mart.finance_monthly` | 12 | 12 | MATCH |
| `mart.geo_rollup` | 21 | 21 | MATCH |
| `mart.inventory_snapshot` | 300 | 300 | MATCH |
| `mart.payment_mix` | 5 | 5 | MATCH |
| `mart.product_perf` | 300 | 300 | MATCH |
| `mart.promo_lift` | 4 | 4 | MATCH |
| `mart.returns_rate` | 6 | 6 | MATCH |
| `mart.rfm_segments` | 1500 | 1500 | MATCH |
| `mart.shipping_sla` | 4 | 4 | MATCH |
| `mart.store_weekly` | 2120 | 2120 | MATCH |
| `mart.web_sessions` | 21280 | 21280 | MATCH |

### Registered routines (live)

| Schema | Name | Kind | Args | Language |
|---|---|---|---|---|
| public | f_clean_phone | function | 1 | sql |
| public | f_fiscal_qtr | function | 1 | sql |
| public | sp_build_churn_flags | procedure | 0 | plpgsql |
| public | sp_upsert_inventory | procedure | 1 | plpgsql |

Live bodies (`routines.json`) match the legacy SQL.

### Size and physical design (live `svv_table_info`, `size` in 1 MB blocks)

['schema_name', 'table_name', 'diststyle', 'sortkey1', 'sortkey_num', 'encoded', 'size_mb', 'tbl_rows', 'estimated_visible_rows', 'skew_rows', 'unsorted', 'stats_off', 'pct_used']
| Table | diststyle | sortkey1 | encoded | size_mb | tbl_rows | skew_rows | unsorted % |
|---|---|---|---|---|---|---|---|
| `core.campaign_touches` | KEY(customer_id) | touch_id | Y, AUTO(ENCODE) | 1536 | 8000 | 5.90 | 87.50 |
| `core.customers` | KEY(customer_id) | customer_id | Y | 3072 | 1500 | 6.33 | 33.33 |
| `core.order_items` | KEY(order_id) | order_id | Y, AUTO(ENCODE) | 2241 | 40938 | 1.62 | 97.55 |
| `core.orders` | KEY(customer_id) | order_ts | Y | 2304 | 20000 | 4.64 | 95.00 |
| `core.payments` | KEY(order_id) | order_id | Y, AUTO(ENCODE) | 2048 | 20000 | 1.48 | 95.00 |
| `core.products` | ALL | product_id | Y | 44 | 300 | None | 0.00 |
| `core.returns` | KEY(order_item_id) | returned_ts | Y, AUTO(ENCODE) | 2048 | 2518 | 3.20 | 60.28 |
| `core.shipments` | KEY(order_id) | ship_ts | Y | 2048 | 12817 | 1.74 | 92.19 |
| `core.stores` | ALL | store_id | Y | 32 | 40 | None | 0.00 |
| `core.web_events` | KEY(customer_id) | event_ts | Y | 2032 | 25000 | 83.02 | 96.00 |
| `mart.attribution` | AUTO(EVEN) | campaign_id | Y, AUTO(ENCODE) | 14 | 100 | None | 0.00 |
| `mart.basket_affinity` | AUTO(EVEN) | product_id_a | Y, AUTO(ENCODE) | 12 | 50 | None | 0.00 |
| `mart.category_mix` | AUTO(EVEN) | category | Y, AUTO(ENCODE) | 14 | 6 | None | 0.00 |
| `mart.churn_flags` | KEY(customer_id) | customer_id | Y, AUTO(ENCODE) | 903 | 1500 | 6.33 | 99.93 |
| `mart.cohort_retention` | AUTO(EVEN) | cohort_month | Y, AUTO(ENCODE) | 14 | 65 | None | 0.00 |
| `mart.customer_ltv` | KEY(customer_id) | customer_id | Y, AUTO(ENCODE) | 2304 | 1500 | 6.33 | 0.00 |
| `mart.daily_revenue` | ALL | order_date | Y, AUTO(ENCODE) | 28 | 1460 | None | 0.00 |
| `mart.exec_summary` | AUTO(EVEN) | AUTO(SORTKEY) | Y, AUTO(ENCODE) | 10 | 1 | None | None |
| `mart.finance_monthly` | AUTO(EVEN) | month | Y, AUTO(ENCODE) | 16 | 12 | None | 0.00 |
| `mart.geo_rollup` | AUTO(EVEN) | AUTO(SORTKEY) | Y, AUTO(ENCODE) | 8 | 21 | None | None |
| `mart.inventory_snapshot` | KEY(product_id) | product_id | Y, AUTO(ENCODE) | 1582 | 300 | 100.00 | 0.00 |
| `mart.payment_mix` | AUTO(EVEN) | AUTO(SORTKEY) | Y, AUTO(ENCODE) | 9 | 5 | None | None |
| `mart.product_perf` | KEY(product_id) | product_id | Y, AUTO(ENCODE) | 1808 | 300 | 100.00 | 0.00 |
| `mart.promo_lift` | AUTO(KEY(sales_channel)) | sales_channel | Y, AUTO(ENCODE) | 56 | 4 | 100.00 | 0.00 |
| `mart.returns_rate` | AUTO(KEY(category)) | category | Y, AUTO(ENCODE) | 96 | 6 | 100.00 | 0.00 |
| `mart.rfm_segments` | KEY(customer_id) | customer_id | Y, AUTO(ENCODE) | 2816 | 1500 | 6.33 | 0.00 |
| `mart.shipping_sla` | AUTO(KEY(carrier)) | carrier | Y, AUTO(ENCODE) | 88 | 4 | 100.00 | 0.00 |
| `mart.store_weekly` | KEY(store_id) | store_id | Y, AUTO(ENCODE) | 594 | 2120 | 100.00 | 0.00 |
| `mart.web_sessions` | KEY(customer_id) | customer_id | Y, AUTO(ENCODE) | 2304 | 21280 | 6.22 | 0.00 |

Serverless usage: managed storage 22.87 GB (`sys_serverless_usage`, averaged), 8 RPU base capacity, 8,782
compute-seconds in the retained window. The estate is tiny; physical design (`DISTKEY`/`SORTKEY`) has no performance
bearing on the Databricks target beyond optional liquid-clustering hints.

### Minimal grant request (for least-privilege discovery as the IAM user)

Not executed (grants must not be changed by this workstream). For an admin to run if IAM-only discovery is required:

```sql
-- run as a Redshift admin in database mig_redshift_src
GRANT USAGE ON SCHEMA core TO "IAM:Devin-Databricks-Demo";
GRANT USAGE ON SCHEMA mart TO "IAM:Devin-Databricks-Demo";
GRANT SELECT ON ALL TABLES IN SCHEMA core TO "IAM:Devin-Databricks-Demo";
GRANT SELECT ON ALL TABLES IN SCHEMA mart TO "IAM:Devin-Databricks-Demo";
-- optional, only for svv_table_info / sys_serverless_usage size evidence (system role; verify syntax on the cluster):
GRANT ROLE sys:monitor TO "IAM:Devin-Databricks-Demo";
```

`GRANT SELECT ON ALL TABLES` covers existing tables only, and `legacy_redshift.py setup` drops both schemas with
`CASCADE`, so the grants must be re-applied after every reload (or use `ALTER DEFAULT PRIVILEGES` for the loader
user).

Re-run after granting: `python tools/redshift_discovery.py --engine data-api --auth iam`.

## 9. Manual vs tool vs live discrepancies

| # | Topic | Manual reading (source / manifest) | Lakebridge | Live |
|---|---|---|---|---|
| 1 | File inventory | 43 files | 7 (original), 43 (flat re-run) | - |
| 2 | Schedule | 2 parallel waves + exec summary + export | YAML parsed as SQL `UNKNOWN`, not transpiled | - |
| 3 | `setup --ddl-only` | Not accepted by `legacy_redshift.py` | not analysed | - |
| 4 | Procedures | 2 (`sp_build_churn_flags`, `sp_upsert_inventory`) | analyzer: churn MEDIUM, inventory LOW; both transpiled with exit 0 | 2 registered |
| 5 | UDFs | 2; `f_fiscal_qtr` needs integer division | transpiled silently with `/` (DOUBLE) | 2 registered, bodies match |
| 6 | `UNLOAD` export | placeholder, `capture_skip` | 1 error, exit 0 | not executed |
| 7 | SUPER/PartiQL | `attribution` rejected | LOW, invalid draft, no warning | `payload super` (zstd) |
| 8 | Lineage | 19 mart outputs | 17 mart targets (no `churn_flags`, `exec_summary`) | 19 mart tables present |
| 9 | Exec summary | reads 4 marts | no lineage entry | values = golden |
| 10 | store_weekly, category_mix | manifest `clean` | no warning | golden shows boundary-week / float-share semantics the drafts break |
| 11 | Row counts | golden snapshot | - | 29/29 equal |
| 12 | information_schema | - | - | empty for IAM user, 29 for `demoadmin`; `pg_class` shows 29 for both |
| 13 | Readiness score | none defined | none emitted | - |
