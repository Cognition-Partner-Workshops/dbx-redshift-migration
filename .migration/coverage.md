# Construct coverage

Redshift construct → *expected* Lakebridge outcome (hypothesis, not fact) →
observed (filled by migration sessions) → fix pattern. "review feedback
updates the playbook": when a session hits a mismatch, it records the observed
outcome and the fix that made `make validate` pass.

| unit | construct | expected | observed | fix pattern |
| --- | --- | --- | --- | --- |
| foundation | DISTKEY/SORTKEY/DISTSTYLE/ENCODE, IDENTITY, SUPER | clean | clean (DDL) — not harness-run; DDL-only draft has no seed load | Physical clauses dropped, liquid clustering added; `read_files` CSV load from `bronze/raw` via SQL scripting; `rpad(region, 4, ' ')` for CHAR(4); UDFs as UC SQL functions |
| daily_revenue | DATE_TRUNC/TRUNC, SUM GROUP BY | clean | clean | Draft passed golden as-is |
| customer_ltv | CHAR(4) padding carried into output, AVG on NUMERIC(12,2) scale | mismatch | mismatch: `aov` 1308/1500 rows, report `avg_ltv` 6/6 (`193.253556` vs `193.25`) | Redshift AVG on NUMERIC(_,2) truncates to scale 2 → `CAST(floor(AVG(x), 2) AS DECIMAL(38,2))`; CHAR(4) padding kept from silver |
| geo_rollup | GROUPING SETS, GROUPING() id column | clean | clean | Draft passed golden as-is |
| churn_flags | plpgsql procedure, FOR loop, temp table, CALL | rejected | rejected: build fails — `DATE - DATE > 180` DATATYPE_MISMATCH in transpiled plpgsql FOR loop | Procedure + temp table + CALL collapsed to one set-based INSERT … SELECT with `datediff(DATE '2025-12-31', d)` |
| product_perf | LISTAGG(...) WITHIN GROUP (ORDER BY ...), ::casts | mismatch | mismatch: `top_stores` 5/300 rows (`NE  ` trailing pad kept) | Redshift LISTAGG drops CHAR(4) trailing blanks → `listagg(rtrim(region), ',') WITHIN GROUP (ORDER BY … NULLS …)` |
| store_weekly | DATE_TRUNC('week'), DATEADD, DATEDIFF(week) | clean | mismatch: `week_number` 2080/2120 rows off by one | DATEDIFF(week) counts Monday boundaries → `datediff(date_trunc('WEEK', a), date_trunc('WEEK', b)) DIV 7` (whole weeks between Monday starts) |
| category_mix | RATIO_TO_REPORT | clean | mismatch: `revenue_share` 6/6 rounded to 6 dp (`0.154113` vs `0.15411330152688182`) | RATIO_TO_REPORT returns FLOAT8 → `CAST(x AS DOUBLE) / SUM(CAST(x AS DOUBLE)) OVER ()` with no decimal cast |
| basket_affinity | self-join pairs, HAVING support >= threshold | clean | clean | Draft passed golden as-is |
| sessionization | LAG, 30-min gap, running SUM session id | clean | clean | Draft passed golden as-is |
| shipping_sla | DATEDIFF(hour) boundary counting, CONVERT_TIMEZONE | mismatch | mismatch: `avg_hours_to_deliver` 4/4 (`72.00` vs `71.00`), exec_summary `avg_ship_hours` | DATEDIFF(hour) boundary counting → `timestampdiff(HOUR, date_trunc('HOUR', a), date_trunc('HOUR', b))`; CONVERT_TIMEZONE → `convert_timezone` |
| rfm_segments | NTILE(5), NULL ordering on NULL metrics | mismatch | mismatch: report `avg_frequency` 83/103 (`21.298…` vs `21`) | AVG(INT) is integer in Redshift → `CAST(AVG(x) AS BIGINT)` truncation; explicit NULLS LAST/FIRST on NTILE windows |
| promo_lift | MEDIAN, PERCENTILE_CONT WITHIN GROUP | mismatch | mismatch: median/p90 4/4 (`390.21500000000003` vs `390.21`) | MEDIAN/PERCENTILE_CONT truncate to input scale → `CAST(floor(round(percentile_cont(p) WITHIN GROUP (…), 6), 2) AS DECIMAL(38,2))` |
| payment_mix | DECODE, NVL, NVL2 | mismatch | mismatch: `amount_share` 5/5 (`0.4276037…` vs `0.4276`) | DECODE→CASE, NVL→coalesce, NVL2→if; RATIO share → `CAST(floor(x / SUM(x) OVER (), 4) AS DECIMAL(38,4))` |
| returns_rate | integer division on INTs, :: casts | mismatch | mismatch: `return_rate_int` 6/6 (`0.0511…` vs `0`) | INT/INT is integer division in Redshift → `a DIV b` for `_int`; explicit DECIMAL casts + `floor(…, 15)` for fractional pct |
| attribution | SUPER / PartiQL unnesting (t, t.payload.touches tc) | rejected | rejected: build fails — `t.payload.touches` resolved as a table (PartiQL unnest not translated) | SUPER → `LATERAL variant_explode(parse_json(payload):touches)` with `value:campaign_id` casts |
| inventory_snapshot | plpgsql upsert: staging + DELETE/INSERT | rejected | rejected: build fails — TEMP_TABLE_DROP_PERMANENT_NAME_CONFLICT on `stg_inventory` | Procedure staging + DELETE/INSERT → single `MERGE INTO gold.inventory_snapshot` with CTE source |
| finance_export | UNLOAD TO s3 IAM_ROLE (export skipped at capture) | rejected | rejected: `export.sql` UNLOAD not transpiled (see `lakebridge/errors/finance_export.log`); `etl.sql` draft clean | UNLOAD → `databricks/units/finance_export/export.py` (job task `finance_export_unload`) writes CSV to managed volume `/Volumes/<catalog>/gold/finance_export/monthly` (no S3 external location/IAM role) |
| cohort_retention | TEMP TABLE steps, DATEDIFF(month) matrix | rejected | rejected: build fails — `tmp_cohorts` TEMP TABLE not found across statements | TEMP TABLE steps → CTEs; DATEDIFF(month) month-boundary count → `(year(b)*12 + month(b)) - (year(a)*12 + month(a))` |
| orchestration | cross-mart joins, refresh_schedule.yaml → Lakeflow job | clean | mismatch: `avg_customer_ltv`, `avg_ship_hours` (inherited from customer_ltv/shipping_sla drafts) | Same truncation fixes; `refresh_schedule.yaml` → DAB job `resources/nightly_mart_refresh.job.yml` (paused, 02:00 UTC) |

Observed outcomes are from migration-run-4: each raw Lakebridge draft
(`.migration/lakebridge/transpiled/`) was executed against `mig_redshift_dev`
and reconciled with the golden harness; per-unit details are in
`.migration/lakebridge/draft_validation.json`. Final converted SQL passes
`make validate` for every unit (`.migration/evidence/<unit>.json`).
