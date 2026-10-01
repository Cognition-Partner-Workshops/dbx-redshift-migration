-- One-row cross-mart aggregate; compared against golden/orchestration/exec_summary.csv.
SELECT snapshot_label, as_of_date, total_revenue, total_orders,
       avg_customer_ltv, overall_return_pct, avg_ship_hours
FROM mart.exec_summary
ORDER BY snapshot_label
