-- BI report: low stock as of the snapshot.
SELECT product_id, snapshot_date, units_sold, on_hand FROM mart.inventory_snapshot
ORDER BY on_hand ASC NULLS LAST, product_id NULLS LAST
LIMIT 50;