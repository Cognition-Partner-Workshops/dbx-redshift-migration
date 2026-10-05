# Decision log

| id | date | decision | by | status |
| --- | --- | --- | --- | --- |
| D-001 | 2026-09-30 | Recon oracle = golden snapshot captured from Redshift `mig_redshift_src`; tolerances per `validation/tolerances.yaml` | lead | proposed |
| D-002 | 2026-10-05 | customer_ltv PRD D-1: accept golden snapshot as recon oracle (would move D-001 → approved) | migration lead | proposed |
| D-003 | 2026-10-05 | customer_ltv PRD D-2: explicit DDL + INSERT (exact CHAR(4) / DECIMAL(38,2) schema) instead of single CTAS | data platform | proposed |
| D-004 | 2026-10-05 | customer_ltv PRD D-3: preserve Redshift AVG truncation for `aov` / `avg_ltv` / `exec_summary.avg_customer_ltv` via `(SUM*100) DIV COUNT * 0.01`; no tolerance change | business owner (Finance/CRM) | proposed |
| D-005 | 2026-10-05 | customer_ltv PRD D-4: 5-business-day parallel run; BI repoints to `mart.customer_ltv` compatibility view first | BI owner | proposed |
| D-006 | 2026-10-05 | customer_ltv PRD D-5: prod (`mig_redshift`) promotion only after G1–G5 PASS on dev and human-approved merge | migration lead | proposed |
