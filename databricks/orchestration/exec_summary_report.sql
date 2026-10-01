-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST;
