# Construct coverage

Redshift construct → *expected* Lakebridge outcome (hypothesis, not fact) →
observed (filled by migration sessions) → fix pattern. "review feedback
updates the playbook": when a session hits a mismatch, it records the observed
outcome and the fix that made `make validate` pass.

| unit | construct | expected | observed | fix pattern |
| --- | --- | --- | --- | --- |
| foundation | DISTKEY/SORTKEY/DISTSTYLE/ENCODE, IDENTITY, SUPER | clean | mismatch: CHAR padding and SUPER representation; 10/10 outputs PASS | typed Delta bronze/silver; liquid clustering; explicit RPAD for CHAR(4); parse_json VARIANT in bronze, source JSON text in silver; fiscal UDF uses DIV and source +9 |
| daily_revenue | DATE_TRUNC/TRUNC, SUM GROUP BY | clean | clean: Lakebridge draft correct apart from core/mart naming and redundant double CAST; 2/2 outputs PASS | `TRUNC(ts)::DATE` -> `CAST(ts AS DATE)`; SUM cast to DECIMAL(38,2) to match Redshift NUMERIC(38,2); SORTKEY -> CLUSTER BY; report ORDER BY ... NULLS LAST |
| customer_ltv | CHAR(4) padding carried into output, AVG on NUMERIC(12,2) scale | mismatch | | |
| geo_rollup | GROUPING SETS, GROUPING() id column | clean | clean: draft only needed core/mart to silver/gold; 2/2 outputs PASS | CREATE OR REPLACE for DROP+CTAS; CHAR(4) region padding from silver; CAST revenue DECIMAL(38,2) for Redshift SUM(NUMERIC) scale; explicit ASC NULLS LAST |
| churn_flags | plpgsql procedure, FOR loop, temp table, CALL | rejected | | |
| product_perf | LISTAGG(...) WITHIN GROUP (ORDER BY ...), ::casts | mismatch | mismatch: Lakebridge ARRAY_AGG draft kept CHAR(4) padding ("NE  ") and core/mart names; 2/2 outputs PASS | ARRAY_SORT(COLLECT_LIST(struct(rn, RTRIM(region)))) ordered by the ROW_NUMBER rank (keeps duplicates, skips NULLs, NULL when empty); explicit NULLS FIRST/LAST for Redshift DESC/ASC; ::VARCHAR(64) -> LEFT(...,64); CAST DECIMAL(18,2)/BIGINT; report ORDER BY NULLS LAST |
| store_weekly | DATE_TRUNC('week'), DATEADD, DATEDIFF(week) | clean | | |
| category_mix | RATIO_TO_REPORT | clean | clean (Lakebridge `revenue / SUM(revenue) OVER ()` is DECIMAL; golden is FLOAT8); 2/2 outputs PASS | `CAST(revenue AS DOUBLE) / CAST(SUM(revenue) OVER () AS DOUBLE)`; revenue DECIMAL(38,2), units_sold BIGINT; report keeps Redshift NULL ordering (DESC NULLS FIRST, ASC NULLS LAST) |
| basket_affinity | self-join pairs, HAVING support >= threshold | clean | | |
| sessionization | LAG, 30-min gap, running SUM session id | clean | mismatch risk: Lakebridge kept DATEDIFF(second) (elapsed-second truncation, not Redshift boundary count) and core->silver/mart->gold unmapped; 2/2 outputs PASS | gap = floored NTZ epoch-second difference (timestampdiff MICROSECOND from TIMESTAMP_NTZ epoch, no tz conversion), `> 1800`; ORDER BY event_ts, event_id ASC NULLS LAST for LAG and ROWS UNBOUNDED PRECEDING running SUM; CREATE OR REPLACE gold.web_sessions CLUSTER BY (customer_id, session_id) |
| shipping_sla | DATEDIFF(hour) boundary counting, CONVERT_TIMEZONE | mismatch | | |
| rfm_segments | NTILE(5), NULL ordering on NULL metrics | mismatch | mismatch: Lakebridge kept NULL ordering but report AVG(BIGINT) became DOUBLE (83/103 segments non-integer); Databricks default ASC NULLS FIRST would shift 730/1500 r_tile (146 NULL-recency customers); 2/2 outputs PASS | explicit Redshift null order (ASC NULLS LAST, DESC NULLS FIRST) with customer_id NTILE tiebreak; SUM DIV COUNT for integer AVG; monetary DECIMAL(38,2); CLUSTER BY customer_id |
| promo_lift | MEDIAN, PERCENTILE_CONT WITHIN GROUP | mismatch | | |
| payment_mix | DECODE, NVL, NVL2 | mismatch | mismatch: Lakebridge draft kept unbounded division scale for amount_share; 2/2 outputs PASS | DECODE/NVL/NVL2 native; group on raw method so NULL becomes one unknown row; amount_share truncated toward zero to scale 4 (FLOOR/CEIL, DECIMAL(38,4)) to match Redshift numeric division; report ORDER BY ASC NULLS LAST |
| returns_rate | integer division on INTs, :: casts | mismatch | | |
| attribution | SUPER / PartiQL unnesting (t, t.payload.touches tc) | rejected | mismatch: Lakebridge emitted invalid `CROSS JOIN t.payload.touches` over STRING silver payload and lost VARCHAR(16) cast; 2/2 outputs PASS | parse_json + `try_variant_get($.touches, ARRAY<VARIANT>)` typed explode (non-array → no rows); string-only `variant_get` → NULL otherwise, `left(...,16)` for VARCHAR(16); ORDER BY NULLS LAST |
| inventory_snapshot | plpgsql upsert: staging + DELETE/INSERT | rejected | | |
| finance_export | UNLOAD TO s3 IAM_ROLE (export skipped at capture) | rejected | | |
| cohort_retention | TEMP TABLE steps, DATEDIFF(month) matrix | rejected | | |
| orchestration | cross-mart joins, refresh_schedule.yaml → Lakeflow job | clean | | |
