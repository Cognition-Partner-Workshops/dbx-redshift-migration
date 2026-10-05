# Construct coverage

Redshift construct → *expected* Lakebridge outcome (hypothesis, not fact) →
observed (filled by migration sessions) → fix pattern. "review feedback
updates the playbook": when a session hits a mismatch, it records the observed
outcome and the fix that made `make validate` pass.

| unit | construct | expected | observed | fix pattern |
| --- | --- | --- | --- | --- |
| foundation | DISTKEY/SORTKEY/DISTSTYLE/ENCODE, IDENTITY, SUPER | clean | mismatch: BladeBridge draft not runnable — kept core.* names, emitted ZORDER BY inside CREATE TABLE, left SUPER, mangled UDF bodies ($1 → STRING, Redshift AS $$ syntax, truncated) and no CSV load; seed CSV region is unpadded; 10/10 outputs PASS | bronze = read_files(:path) via EXECUTE IMMEDIATE ... USING on a current_catalog() volume path (RTAS, as-is); silver = explicit typed DDL (VARCHAR(n), CHAR(4), DECIMAL(12,2), TIMESTAMP_NTZ) + INSERT with rpad(region, 4, ' ') (CAST AS CHAR does not pad); CLUSTER BY Redshift dist/sort keys; SUPER → STRING JSON text (VARIANT re-sorts object keys); UDFs as LANGUAGE SQL DETERMINISTIC RETURN, INT `/` → DIV, legacy +9 fiscal formula kept |
| daily_revenue | DATE_TRUNC/TRUNC, SUM GROUP BY | clean | | |
| customer_ltv | CHAR(4) padding carried into output, AVG on NUMERIC(12,2) scale | mismatch | mismatch: Lakebridge (BladeBridge) reported 0 errors, but the draft is not deployable — `ZORDER BY` emitted inside a CTAS (invalid DDL), `core.`/`mart.` schemas kept, unqualified `f_clean_phone`, native `AVG` (Databricks scale 6, CAST rounds half-up vs Redshift NUMERIC(38,2) truncated toward zero); CTAS would also widen CHAR(4) to VARCHAR; 2/2 outputs PASS at default tolerances | explicit DDL `region CHAR(4)`, `ltv`/`aov DECIMAL(38,2)`, `CLUSTER BY (customer_id)` + `INSERT ... SELECT` (no ORDER BY); AVG as `CAST((SUM*100) DIV NULLIF(COUNT,0) AS DECIMAL(36,0)) * 0.01` (exact truncation) in etl and report; `silver.f_clean_phone`; report `ORDER BY region ASC NULLS LAST`; G3 `validation.sql` assert_true gate |
| geo_rollup | GROUPING SETS, GROUPING() id column | clean | | |
| churn_flags | plpgsql procedure, FOR loop, temp table, CALL | rejected | | |
| product_perf | LISTAGG(...) WITHIN GROUP (ORDER BY ...), ::casts | mismatch | | |
| store_weekly | DATE_TRUNC('week'), DATEADD, DATEDIFF(week) | clean | | |
| category_mix | RATIO_TO_REPORT | clean | | |
| basket_affinity | self-join pairs, HAVING support >= threshold | clean | | |
| sessionization | LAG, 30-min gap, running SUM session id | clean | | |
| shipping_sla | DATEDIFF(hour) boundary counting, CONVERT_TIMEZONE | mismatch | | |
| rfm_segments | NTILE(5), NULL ordering on NULL metrics | mismatch | | |
| promo_lift | MEDIAN, PERCENTILE_CONT WITHIN GROUP | mismatch | | |
| payment_mix | DECODE, NVL, NVL2 | mismatch | | |
| returns_rate | integer division on INTs, :: casts | mismatch | | |
| attribution | SUPER / PartiQL unnesting (t, t.payload.touches tc) | rejected | | |
| inventory_snapshot | plpgsql upsert: staging + DELETE/INSERT | rejected | | |
| finance_export | UNLOAD TO s3 IAM_ROLE (export skipped at capture) | rejected | | |
| cohort_retention | TEMP TABLE steps, DATEDIFF(month) matrix | rejected | | |
| orchestration | cross-mart joins, refresh_schedule.yaml → Lakeflow job | clean | mismatch (numeric only): draft kept `mart.*` names, `CURRENT_DATE '2025-12-31'` and Databricks AVG/decimal division (scale 6/19, half-up) vs Redshift truncation; exec_summary + report PASS (1/1 rows exact) | `mart.`→`gold.`, literal `DATE '2025-12-31'`, `CREATE OR REPLACE TABLE` (atomic); avg_customer_ltv = `CAST((SUM(ltv)*100) DIV NULLIF(COUNT(ltv),0) AS DECIMAL(36,0))*0.01` (same as customer_ltv); NUMERIC(14,4)/NUMERIC(14,4) via DIV + remainder DIV at scale 15; SUM/SUM avg hours via DIV + remainder at scale 4; Lakeflow job left to orchestrator |
