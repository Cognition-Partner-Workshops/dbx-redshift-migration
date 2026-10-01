-- inventory_snapshot: Redshift plpgsql sp_upsert_inventory (staging temp table +
-- DELETE/INSERT) as one idempotent Delta MERGE over a staging CTE.
-- The procedure argument p_snapshot is the fixed as-of date 2025-12-31.
-- The legacy script drops and recreates the mart before CALL, so the final
-- state holds exactly one row per silver.products row; WHEN NOT MATCHED BY
-- SOURCE THEN DELETE keeps reruns equivalent without dropping the table.
CREATE TABLE IF NOT EXISTS gold.inventory_snapshot (
    product_id    INT,
    snapshot_date DATE,
    units_sold    BIGINT,
    on_hand       INT
)
USING DELTA
CLUSTER BY (product_id);

MERGE INTO gold.inventory_snapshot AS t
USING (
    WITH stg_inventory AS (
        SELECT product_id, CAST(SUM(quantity) AS BIGINT) AS units_sold
        FROM   silver.order_items
        GROUP  BY product_id
    )
    SELECT p.product_id,
           DATE '2025-12-31'                                    AS snapshot_date,
           COALESCE(s.units_sold, 0)                            AS units_sold,
           CAST(GREATEST(500 - COALESCE(s.units_sold, 0), 0) AS INT) AS on_hand
    FROM   silver.products p
    LEFT JOIN stg_inventory s ON s.product_id = p.product_id
) AS src
ON t.product_id = src.product_id
WHEN MATCHED THEN UPDATE SET
    t.snapshot_date = src.snapshot_date,
    t.units_sold    = src.units_sold,
    t.on_hand       = src.on_hand
WHEN NOT MATCHED THEN INSERT (product_id, snapshot_date, units_sold, on_hand)
    VALUES (src.product_id, src.snapshot_date, src.units_sold, src.on_hand)
WHEN NOT MATCHED BY SOURCE THEN DELETE;
