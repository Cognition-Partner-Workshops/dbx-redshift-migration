# Construct coverage

Redshift construct → *expected* Lakebridge outcome (hypothesis, not fact) →
observed (filled by migration sessions) → fix pattern. "review feedback
updates the playbook": when a session hits a mismatch, it records the observed
outcome and the fix that made `make validate` pass.

| unit | construct | expected | observed | fix pattern |
| --- | --- | --- | --- | --- |
| foundation | DISTKEY/SORTKEY/DISTSTYLE/ENCODE, IDENTITY, SUPER | clean | mismatch: CHAR padding and SUPER representation; 10/10 outputs PASS | typed Delta bronze/silver; liquid clustering; explicit RPAD for CHAR(4); parse_json VARIANT in bronze, source JSON text in silver; fiscal UDF uses DIV and source +9 |
| daily_revenue | DATE_TRUNC/TRUNC, SUM GROUP BY | clean | | |
| customer_ltv | CHAR(4) padding carried into output, AVG on NUMERIC(12,2) scale | mismatch | | |
| geo_rollup | GROUPING SETS, GROUPING() id column | clean | | |
| churn_flags | plpgsql procedure, FOR loop, temp table, CALL | rejected | | |
| product_perf | LISTAGG(...) WITHIN GROUP (ORDER BY ...), ::casts | mismatch | | |
| store_weekly | DATE_TRUNC('week'), DATEADD, DATEDIFF(week) | clean | | |
| category_mix | RATIO_TO_REPORT | clean | | |
| basket_affinity | self-join pairs, HAVING support >= threshold | clean | | |
| sessionization | LAG, 30-min gap, running SUM session id | clean | | |
| shipping_sla | DATEDIFF(hour) boundary counting, CONVERT_TIMEZONE | mismatch | mismatch: Lakebridge kept Redshift DATEDIFF(hour) (Databricks counts elapsed hours) and float AVG (Redshift AVG(BIGINT) truncates; naive AVG gives 72.00 vs golden 71.00); 2/2 outputs PASS | TIMESTAMPDIFF(HOUR) over date_trunc('HOUR') of both NTZ timestamps; SUM DIV NULLIF(COUNT,0) cast to DECIMAL(10,2); explicit convert_timezone('UTC','America/Los_Angeles') on TIMESTAMP_NTZ; ORDER BY NULLS LAST |
| rfm_segments | NTILE(5), NULL ordering on NULL metrics | mismatch | | |
| promo_lift | MEDIAN, PERCENTILE_CONT WITHIN GROUP | mismatch | | |
| payment_mix | DECODE, NVL, NVL2 | mismatch | | |
| returns_rate | integer division on INTs, :: casts | mismatch | | |
| attribution | SUPER / PartiQL unnesting (t, t.payload.touches tc) | rejected | | |
| inventory_snapshot | plpgsql upsert: staging + DELETE/INSERT | rejected | | |
| finance_export | UNLOAD TO s3 IAM_ROLE (export skipped at capture) | rejected | | |
| cohort_retention | TEMP TABLE steps, DATEDIFF(month) matrix | rejected | | |
| orchestration | cross-mart joins, refresh_schedule.yaml → Lakeflow job | clean | | |
