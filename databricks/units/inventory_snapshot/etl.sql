-- inventory_snapshot: the Redshift plpgsql procedure (staging temp table +
-- DELETE/INSERT into a freshly recreated table, CALLed with 2025-12-31) is
-- equivalent to one full rebuild; expressed as a single CTAS.
CREATE OR REPLACE TABLE gold.inventory_snapshot (
    product_id    INT,
    snapshot_date DATE,
    units_sold    BIGINT,
    on_hand       INT
);

INSERT INTO gold.inventory_snapshot
WITH stg_inventory AS (
    SELECT product_id, CAST(SUM(quantity) AS BIGINT) AS units_sold
    FROM   silver.order_items
    GROUP  BY product_id
)
SELECT p.product_id,
       DATE'2025-12-31' AS snapshot_date,
       COALESCE(s.units_sold, 0) AS units_sold,
       CAST(GREATEST(500 - COALESCE(s.units_sold, 0), 0) AS INT) AS on_hand
FROM   silver.products p
LEFT JOIN stg_inventory s ON s.product_id = p.product_id;
