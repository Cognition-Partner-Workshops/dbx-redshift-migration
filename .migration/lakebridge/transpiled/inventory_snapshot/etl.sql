-- inventory_snapshot: plpgsql upsert — staging temp table + DELETE/INSERT
-- into an existing mart table.
DROP TABLE IF EXISTS mart.inventory_snapshot;

CREATE
    /* DISTKEY(product_id) SORTKEY(product_id) */
    TABLE mart.inventory_snapshot (product_id INT, snapshot_date DATE, units_sold BIGINT, on_hand INT);

CREATE OR REPLACE
    PROCEDURE sp_upsert_inventory(IN p_snapshot DATE)
    LANGUAGE SQL
    SQL SECURITY INVOKER
    AS
        BEGIN
            CREATE TEMPORARY TABLE stg_inventory (product_id INT, units_sold BIGINT);
            INSERT INTO stg_inventory
            SELECT product_id, CAST(SUM(quantity) AS BIGINT) FROM core.order_items GROUP BY product_id;
            DELETE FROM mart.inventory_snapshot WHERE product_id IN (SELECT product_id FROM stg_inventory);
            INSERT INTO mart.inventory_snapshot
            SELECT
                p.product_id,
                p_snapshot,
                COALESCE(s.units_sold, 0),
                CAST(GREATEST(500 - COALESCE(s.units_sold, 0), 0) AS INT)
            FROM core.products AS p LEFT JOIN stg_inventory AS s ON s.product_id = p.product_id;
            DROP TABLE stg_inventory;
        END;

CALL sp_upsert_inventory(CAST('2025-12-31' AS DATE));