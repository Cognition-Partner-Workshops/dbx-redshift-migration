-- Exact row counts for the 19 mart outputs written by units.yaml (18 units + exec_summary).
SELECT 'mart.attribution' AS table_name, COUNT(*) AS row_count FROM mart.attribution
UNION ALL SELECT 'mart.basket_affinity', COUNT(*) FROM mart.basket_affinity
UNION ALL SELECT 'mart.category_mix', COUNT(*) FROM mart.category_mix
UNION ALL SELECT 'mart.churn_flags', COUNT(*) FROM mart.churn_flags
UNION ALL SELECT 'mart.cohort_retention', COUNT(*) FROM mart.cohort_retention
UNION ALL SELECT 'mart.customer_ltv', COUNT(*) FROM mart.customer_ltv
UNION ALL SELECT 'mart.daily_revenue', COUNT(*) FROM mart.daily_revenue
UNION ALL SELECT 'mart.exec_summary', COUNT(*) FROM mart.exec_summary
UNION ALL SELECT 'mart.finance_monthly', COUNT(*) FROM mart.finance_monthly
UNION ALL SELECT 'mart.geo_rollup', COUNT(*) FROM mart.geo_rollup
UNION ALL SELECT 'mart.inventory_snapshot', COUNT(*) FROM mart.inventory_snapshot
UNION ALL SELECT 'mart.payment_mix', COUNT(*) FROM mart.payment_mix
UNION ALL SELECT 'mart.product_perf', COUNT(*) FROM mart.product_perf
UNION ALL SELECT 'mart.promo_lift', COUNT(*) FROM mart.promo_lift
UNION ALL SELECT 'mart.returns_rate', COUNT(*) FROM mart.returns_rate
UNION ALL SELECT 'mart.rfm_segments', COUNT(*) FROM mart.rfm_segments
UNION ALL SELECT 'mart.shipping_sla', COUNT(*) FROM mart.shipping_sla
UNION ALL SELECT 'mart.store_weekly', COUNT(*) FROM mart.store_weekly
UNION ALL SELECT 'mart.web_sessions', COUNT(*) FROM mart.web_sessions
ORDER BY 1
