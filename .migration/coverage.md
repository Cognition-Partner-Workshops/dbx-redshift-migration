# Construct coverage

Redshift construct → *expected* Lakebridge outcome (hypothesis, not fact) →
observed (filled by migration sessions) → fix pattern. "review feedback
updates the playbook": when a session hits a mismatch, it records the observed
outcome and the fix that made `make validate` pass.

| unit | construct | expected | observed | fix pattern |
| --- | --- | --- | --- | --- |
| foundation | DISTKEY/SORTKEY/DISTSTYLE/ENCODE, IDENTITY, SUPER | clean | mismatch: run-2 draft comments out DISTKEY/SORTKEY/ENCODE and keeps CHAR(4), but maps SUPER -> VARIANT (re-serializes JSON with sorted keys, so payload text no longer matches) and ports f_fiscal_qtr with `/` (DOUBLE, e.g. 'Q4.33'); transpile validation reported 3 EXPLAIN errors on the multi-statement files | bronze = read_files of /Volumes/<catalog>/bronze/raw as STRING; silver typed CTAS with NULLIF('\\N'), CHAR(4)+RPAD, TIMESTAMP_NTZ, SUPER -> STRING JSON text, CLUSTER BY former sort key; UDFs in silver with integer `DIV` |
| daily_revenue | DATE_TRUNC/TRUNC, SUM GROUP BY | clean | | |
| customer_ltv | CHAR(4) padding carried into output, AVG on NUMERIC(12,2) scale | mismatch | | |
| geo_rollup | GROUPING SETS, GROUPING() id column | clean | | |
| churn_flags | plpgsql procedure, FOR loop, temp table, CALL | rejected | | |
| product_perf | LISTAGG(...) WITHIN GROUP (ORDER BY ...), ::casts | mismatch | | |
| store_weekly | DATE_TRUNC('week'), DATEADD, DATEDIFF(week) | clean | | |
| category_mix | RATIO_TO_REPORT | clean | | |
| basket_affinity | self-join pairs, HAVING support >= threshold | clean | | |
| sessionization | LAG, 30-min gap, running SUM session id | clean | | |
| shipping_sla | DATEDIFF(hour) boundary counting, CONVERT_TIMEZONE | mismatch | | |
| rfm_segments | NTILE(5), NULL ordering on NULL metrics | mismatch | clean (semantics): run-2 draft emits Redshift NULL ordering explicitly (ASC NULLS LAST, DESC NULLS FIRST) and keeps DATEDIFF(day, ...); draft sits in an Exception block only because EXPLAIN of the multi-statement file (DROP; CREATE) fails to parse; still references core.*/mart.*; report AVG(frequency) not truncated | single CREATE OR REPLACE TABLE gold.x AS, core/mart -> silver/gold, keep explicit NULLS LAST/FIRST in NTILE ORDER BY, DATEDIFF(end, start), CAST(AVG(int) AS BIGINT) in report |
| promo_lift | MEDIAN, PERCENTILE_CONT WITHIN GROUP | mismatch | | |
| payment_mix | DECODE, NVL, NVL2 | mismatch | | |
| returns_rate | integer division on INTs, :: casts | mismatch | | |
| attribution | SUPER / PartiQL unnesting (t, t.payload.touches tc) | rejected | | |
| inventory_snapshot | plpgsql upsert: staging + DELETE/INSERT | rejected | | |
| finance_export | UNLOAD TO s3 IAM_ROLE (export skipped at capture) | rejected | | |
| cohort_retention | TEMP TABLE steps, DATEDIFF(month) matrix | rejected | | |
| orchestration | cross-mart joins, refresh_schedule.yaml → Lakeflow job | clean | | |
