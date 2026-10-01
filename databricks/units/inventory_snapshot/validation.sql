-- inventory_snapshot: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.inventory_snapshot) = 300, 'inventory_snapshot.inventory_snapshot: row_count');
SELECT assert_true((SELECT SUM(product_id) FROM gold.inventory_snapshot) = 45150, 'inventory_snapshot.inventory_snapshot: sum(product_id)');
SELECT assert_true((SELECT COUNT(product_id) FROM gold.inventory_snapshot) = 300, 'inventory_snapshot.inventory_snapshot: non_null(product_id)');
SELECT assert_true((SELECT COUNT(DISTINCT snapshot_date) FROM gold.inventory_snapshot) = 1, 'inventory_snapshot.inventory_snapshot: count_distinct(snapshot_date)');
SELECT assert_true((SELECT COUNT(snapshot_date) FROM gold.inventory_snapshot) = 300, 'inventory_snapshot.inventory_snapshot: non_null(snapshot_date)');
SELECT assert_true((SELECT SUM(units_sold) FROM gold.inventory_snapshot) = 53732, 'inventory_snapshot.inventory_snapshot: sum(units_sold)');
SELECT assert_true((SELECT COUNT(units_sold) FROM gold.inventory_snapshot) = 300, 'inventory_snapshot.inventory_snapshot: non_null(units_sold)');
SELECT assert_true((SELECT SUM(on_hand) FROM gold.inventory_snapshot) = 96268, 'inventory_snapshot.inventory_snapshot: sum(on_hand)');
SELECT assert_true((SELECT COUNT(on_hand) FROM gold.inventory_snapshot) = 300, 'inventory_snapshot.inventory_snapshot: non_null(on_hand)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 50, 'inventory_snapshot.report: row_count');
SELECT assert_true((SELECT SUM(product_id) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 7179, 'inventory_snapshot.report: sum(product_id)');
SELECT assert_true((SELECT COUNT(product_id) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 50, 'inventory_snapshot.report: non_null(product_id)');
SELECT assert_true((SELECT COUNT(DISTINCT snapshot_date) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 1, 'inventory_snapshot.report: count_distinct(snapshot_date)');
SELECT assert_true((SELECT COUNT(snapshot_date) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 50, 'inventory_snapshot.report: non_null(snapshot_date)');
SELECT assert_true((SELECT SUM(units_sold) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 10280, 'inventory_snapshot.report: sum(units_sold)');
SELECT assert_true((SELECT COUNT(units_sold) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 50, 'inventory_snapshot.report: non_null(units_sold)');
SELECT assert_true((SELECT SUM(on_hand) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 14720, 'inventory_snapshot.report: sum(on_hand)');
SELECT assert_true((SELECT COUNT(on_hand) FROM (-- BI report: low stock as of the snapshot.
-- Redshift sorts NULLs last for ASC; Databricks defaults to NULLS FIRST.
SELECT product_id, snapshot_date, units_sold, on_hand
FROM   gold.inventory_snapshot
ORDER  BY on_hand ASC NULLS LAST, product_id ASC NULLS LAST
LIMIT  50)) = 50, 'inventory_snapshot.report: non_null(on_hand)');
