-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50;
