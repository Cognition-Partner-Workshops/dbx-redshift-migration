# Difficulty matrix — 18 Wave 1 ETL units

Inputs: `.migration/units.yaml` (manifest), legacy SQL, Lakebridge re-run drafts and analyzer output, golden snapshot
metadata, and live SELECT-only discovery. Evidence and methodology are in
[`lakebridge-inventory.md`](lakebridge-inventory.md).

**Lakebridge emits no readiness or difficulty score.** Its analyzer rates 17 of these 18 ETLs `LOW` (only
`churn_flags` is `MEDIUM`), which contradicts the manifest and the draft inspection. Everything below is a **derived**
score defined here, not a tool output.

## Derived score (formula)

```
score = 3 * P + 2 * S + 1 * D
```

| Term | Counts one per ... | Examples |
|---|---|---|
| `P` structural rewrite | construct the draft keeps that must be restructured for the Databricks target or is not valid there | PL/pgSQL procedure + `CALL`, row loop, temp-table pipeline, DELETE/INSERT upsert, SUPER/PartiQL unnest, `UNLOAD`, dependency on a UDF whose draft is wrong |
| `S` silent semantic drift | construct the draft keeps that runs but changes values or types vs golden (no Lakebridge warning) | integer `/`, `DATEDIFF` boundary counting, `AVG`/`MEDIAN` result scale, decimal-vs-DOUBLE share, `DATE - DATE` |
| `D` verify-only | construct that is probably right but needs a golden check | generated `LISTAGG` replacement, explicit NULL ordering, `CONVERT_TIMEZONE`, `DECODE`/`NVL2`, `GROUPING SETS`, CHAR padding passthrough, UDF dependency whose draft is correct |

The `core->silver` / `mart->gold` remap and dropping `DISTKEY`/`SORTKEY`/`ENCODE` apply to every unit equally and are
not scored. Bands: `0-2` low, `3-5` medium, `6-8` high, `>= 9` very high.

**Effort** is wall-clock Devin session time for one child migration session (`migrate-unit` → `validate-unit` against
golden in `mig_redshift_dev`), including one or two fix-and-revalidate loops: low ≈ 0.25 session, medium ≈ 0.5,
high ≈ 0.75, very high ≈ 1.0-1.25. Estimates assume foundation (silver tables, CHAR(4) columns, `VARIANT` payload, both
UDFs) is already landed; waiting on foundation or warehouse capacity is external time and not included.

## Ranking (hardest first)

| Rank | Unit | Wave | Manifest expected | Analyzer | P | S | D | Score | Band | Effort (sessions) | Main drivers |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | churn_flags | 1a | rejected | MEDIUM | 3 | 1 | 0 | 11 | very high | 1.0 | PL/pgSQL procedure + `CALL`; `FOR` row loop inserting one row at a time; temp table; `DATE - DATE` becomes `INTERVAL` (cannot go into INT, cannot compare with 180/90). Rewrite as one set-based CTAS with `DATEDIFF(DAY, ...)`. |
| 2 | inventory_snapshot | 1b | rejected | LOW | 3 | 0 | 0 | 9 | very high | 1.0 | Procedure with `p_snapshot` arg + `CALL`; staging temp table; DELETE+INSERT upsert into a just-recreated table. Rewrite as CTAS (or `MERGE` if upsert semantics are kept) with the snapshot literal `DATE '2025-12-31'`. |
| 3 | finance_export | 1b | rejected | LOW | 2 | 1 | 0 | 8 | high | 0.75 | `f_fiscal_qtr` draft uses `/` (DOUBLE): `'Q1.0'`, `'Q4.666…'`; needs `DIV` (foundation-owned UDF, body maps Mar-May to Q1, Feb to Q4, not the comment). `UNLOAD` placeholder: no Databricks equivalent, excluded from capture, no golden; document as a Lakeflow/volume export decision rather than SQL. |
| 4 | attribution | 1b | rejected | LOW | 1 | 1 | 0 | 5 | medium | 0.75 | `t, t.payload.touches tc` PartiQL unnest kept as `CROSS JOIN t.payload.touches` (invalid). Needs `LATERAL variant_explode(t.payload:touches)` or `explode(from_json(...))` and `:`-path field access; `::VARCHAR(16)` casts of SUPER values need VARIANT cast semantics. Depends on foundation's `payload` type. |
| 5 | shipping_sla | 1b | mismatch | LOW | 0 | 2 | 1 | 5 | medium | 0.5 | `DATEDIFF(hour)` boundary vs elapsed; `AVG(<int>)` truncates in Redshift (`71.00`) but is fractional in Databricks; `CONVERT_TIMEZONE` + `EXTRACT(HOUR)` verify. Feeds `exec_summary.avg_ship_hours`. |
| 6 | cohort_retention | 1b | rejected | LOW | 1 | 0 | 1 | 4 | medium | 0.5 | Two temp tables + `INSERT` into a pre-created table; refactor to CTEs in one CTAS. `DATEDIFF(month)` between month-truncated dates is boundary-safe. |
| 7 | customer_ltv | 1a | mismatch | LOW | 0 | 1 | 2 | 4 | medium | 0.5 | `AVG` on NUMERIC(12,2) keeps scale 2 in Redshift, scale 6 in Databricks (value drift > 1e-6); `region CHAR(4)` padding must survive (`string_rstrip: false`); `f_clean_phone` dependency (draft correct). CHAR padding and the UDF are verify-only. Feeds `exec_summary.avg_customer_ltv`. |
| 8 | product_perf | 1a | mismatch | LOW | 0 | 1 | 1 | 3 | medium | 0.5 | `LISTAGG ... WITHIN GROUP (ORDER BY units DESC, region)` replaced by a generated `ARRAY_SORT` lambda comparator; tie order and `::VARCHAR(64)` truncation need a golden check. |
| 9 | store_weekly | 1b | **clean** | LOW | 0 | 1 | 1 | 3 | medium | 0.5 | `DATEDIFF(week, '2025-01-01', week_start)`: Redshift counts week boundaries (golden week `2025-01-06` = 1), Databricks counts whole weeks (= 0). Manifest `clean` is wrong. `DATE_ADD(day, 6, ...)` verify. |
| 10 | payment_mix | 1b | mismatch | LOW | 0 | 1 | 1 | 3 | medium | 0.5 | `SUM/SUM() OVER ()` decimal share: golden `0.4276` (scale 4), Databricks keeps more digits; `DECODE`, `NVL2` kept (exist in Databricks), `NVL -> IFNULL`. |
| 11 | returns_rate | 1b | mismatch | LOW | 0 | 1 | 0 | 2 | low | 0.25 | `BIGINT / BIGINT` must stay integer (`return_rate_int = 0`): use `DIV`. `return_pct` decimal path is within tolerance. Feeds `exec_summary.overall_return_pct`. |
| 12 | category_mix | 1b | **clean** | LOW | 0 | 1 | 0 | 2 | low | 0.25 | `RATIO_TO_REPORT` rewritten as decimal `revenue / SUM(revenue) OVER ()`; golden is float (17 digits) and `float_rel = 1e-9` needs `CAST(... AS DOUBLE)`. Manifest `clean` is wrong. |
| 13 | rfm_segments | 1b | mismatch | LOW | 0 | 0 | 2 | 2 | low | 0.25 | `NTILE(5)` with Redshift default NULL ordering: the draft already adds `ASC NULLS LAST` / `DESC NULLS FIRST`; verify with never-ordered customers. `DATEDIFF(day)` on DATEs is safe. |
| 14 | promo_lift | 1b | mismatch | LOW | 0 | 1 | 0 | 2 | low | 0.25 | `MEDIAN` / `PERCENTILE_CONT` result type and interpolation vs golden DECIMAL (`390.21`, `1093.96`). |
| 15 | geo_rollup | 1a | clean | LOW | 0 | 0 | 1 | 1 | low | 0.25 | `GROUPING SETS` / `GROUPING()` translate directly; verify `grouping_id` keys. |
| 16 | sessionization | 1b | clean | LOW | 0 | 0 | 1 | 1 | low | 0.25 | `DATEDIFF(second)` over `LAG`; seed timestamps are whole seconds, so boundary = elapsed. |
| 17 | daily_revenue | 1a | clean | LOW | 0 | 0 | 0 | 0 | low | 0.25 | `::DATE`, `DATE_TRUNC`, `TRUNC` translate directly. Feeds `exec_summary.total_revenue/total_orders`. |
| 18 | basket_affinity | 1b | clean | LOW | 0 | 0 | 0 | 0 | low | 0.25 | Self-join pairs + `HAVING` threshold; no dialect findings. |

Ties are broken by: P count, then whether the unit feeds `exec_summary`, then manifest order.

### Totals

| Band | Units | Effort |
|---|---|---|
| very high | churn_flags, inventory_snapshot | 2.0 |
| high | finance_export | 0.75 |
| medium | attribution, shipping_sla, cohort_retention, customer_ltv, product_perf, store_weekly, payment_mix | 3.75 |
| low | returns_rate, category_mix, rfm_segments, promo_lift, geo_rollup, sessionization, daily_revenue, basket_affinity | 2.0 |
| **Total (18 units)** | | **≈ 8.5 session-units** |

Session-units are serial effort. Run as the manifest's two parallel waves (one child session per unit, wave 1a width 5,
wave 1b width 13), wall-clock is bounded by the slowest unit per wave: wave 1a ≈ 1 session (`churn_flags`), wave 1b
≈ 1 session (`inventory_snapshot`); because the waves have no dependency on each other they can run concurrently, so
≈ 1-1.25 sessions after foundation. Foundation (UDF `DIV` fix, CHAR(4), `VARIANT`) ≈ 0.5 session and orchestration
(Lakeflow job + `exec_summary`) ≈ 0.5 session are outside the 18.

## Expected-outcome discrepancies vs the manifest

| Unit | Manifest | Evidence | Suggested correction (for the manifest owner) |
|---|---|---|---|
| store_weekly | clean | `DATEDIFF(week)` boundary semantics; golden week 1 = `2025-01-06` | mismatch |
| category_mix | clean | `RATIO_TO_REPORT` → decimal division; golden float family | mismatch |
| finance_export | rejected (UDF, UNLOAD) | additionally the transpiled UDF silently returns `'Q4.666…'` | keep rejected; note UDF integer division |
| customer_ltv | mismatch | also depends on `f_clean_phone` | unchanged |
| churn_flags | rejected | also `DATE - DATE` → `INTERVAL` | unchanged |

`units.yaml` is not changed by this workstream.

## Cross-unit dependencies that affect ordering

- **Foundation first**: `f_fiscal_qtr` (finance_export), `f_clean_phone` (customer_ltv), `CHAR(4)` region
  (customer_ltv, geo_rollup, product_perf), `payload VARIANT` (attribution).
- **exec_summary** (wave 2) reads only `daily_revenue`, `customer_ltv`, `returns_rate`, `shipping_sla`; a drift in any of
  those four shows up in the single golden `exec_summary` row (live values currently equal golden exactly).
- No unit reads another unit's output in wave 1, matching the schedule's two parallel waves.

## Final actual results (post-run)

All 18 unit children landed and `make validate-all` passes: foundation 10/10 outputs, 18/18 units (table +
report), orchestration 2/2 outputs. The `exec_summary` golden row reproduces exactly, including the truncated
`AVG(NUMERIC(38,2))` (7029.21), NUMERIC(14,4) quotient at scale 15 (5.013772053897100) and weighted
avg-hours at scale 4 (71.2551). The actual effort matched the ranking: churn_flags and inventory_snapshot were the
structural rewrites (procedure → set-based / Delta MERGE); finance_export's residual was only the `UNLOAD` export
(replaced by a parameterized Spark CSV write in `databricks/units/finance_export/export.py`). Orchestration
(Lakeflow job + exec_summary + mart compat views + per-unit aggregate checks) came in at ≈ 0.5 session as
estimated.
