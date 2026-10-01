-- orchestration: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT snapshot_label) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: count_distinct(snapshot_label)');
SELECT assert_true((SELECT COUNT(snapshot_label) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: non_null(snapshot_label)');
SELECT assert_true((SELECT COUNT(DISTINCT as_of_date) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: count_distinct(as_of_date)');
SELECT assert_true((SELECT COUNT(as_of_date) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: non_null(as_of_date)');
SELECT assert_true((SELECT SUM(total_revenue) FROM gold.exec_summary) = 10543825.25, 'orchestration.exec_summary: sum(total_revenue)');
SELECT assert_true((SELECT COUNT(total_revenue) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: non_null(total_revenue)');
SELECT assert_true((SELECT SUM(total_orders) FROM gold.exec_summary) = 20000, 'orchestration.exec_summary: sum(total_orders)');
SELECT assert_true((SELECT COUNT(total_orders) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: non_null(total_orders)');
SELECT assert_true((SELECT SUM(avg_customer_ltv) FROM gold.exec_summary) = 7029.21, 'orchestration.exec_summary: sum(avg_customer_ltv)');
SELECT assert_true((SELECT COUNT(avg_customer_ltv) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: non_null(avg_customer_ltv)');
SELECT assert_true((SELECT SUM(overall_return_pct) FROM gold.exec_summary) = 5.013772053897100, 'orchestration.exec_summary: sum(overall_return_pct)');
SELECT assert_true((SELECT COUNT(overall_return_pct) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: non_null(overall_return_pct)');
SELECT assert_true((SELECT SUM(avg_ship_hours) FROM gold.exec_summary) = 71.2551, 'orchestration.exec_summary: sum(avg_ship_hours)');
SELECT assert_true((SELECT COUNT(avg_ship_hours) FROM gold.exec_summary) = 1, 'orchestration.exec_summary: non_null(avg_ship_hours)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT snapshot_label) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: count_distinct(snapshot_label)');
SELECT assert_true((SELECT COUNT(snapshot_label) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: non_null(snapshot_label)');
SELECT assert_true((SELECT COUNT(DISTINCT as_of_date) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: count_distinct(as_of_date)');
SELECT assert_true((SELECT COUNT(as_of_date) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: non_null(as_of_date)');
SELECT assert_true((SELECT SUM(total_revenue) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 10543825.25, 'orchestration.report: sum(total_revenue)');
SELECT assert_true((SELECT COUNT(total_revenue) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: non_null(total_revenue)');
SELECT assert_true((SELECT SUM(total_orders) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 20000, 'orchestration.report: sum(total_orders)');
SELECT assert_true((SELECT COUNT(total_orders) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: non_null(total_orders)');
SELECT assert_true((SELECT SUM(avg_customer_ltv) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 7029.21, 'orchestration.report: sum(avg_customer_ltv)');
SELECT assert_true((SELECT COUNT(avg_customer_ltv) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: non_null(avg_customer_ltv)');
SELECT assert_true((SELECT SUM(overall_return_pct) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 5.013772053897100, 'orchestration.report: sum(overall_return_pct)');
SELECT assert_true((SELECT COUNT(overall_return_pct) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: non_null(overall_return_pct)');
SELECT assert_true((SELECT SUM(avg_ship_hours) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 71.2551, 'orchestration.report: sum(avg_ship_hours)');
SELECT assert_true((SELECT COUNT(avg_ship_hours) FROM (-- BI report: the exec summary as published.
-- Converted from legacy/redshift/99_orchestration/exec_summary/report.sql.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM   gold.exec_summary
ORDER  BY snapshot_label NULLS LAST)) = 1, 'orchestration.report: non_null(avg_ship_hours)');
