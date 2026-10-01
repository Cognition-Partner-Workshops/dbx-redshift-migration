-- returns_rate: returns per category. return_rate_int is INTEGER division
-- (INT/INT); return_pct uses an explicit :: cast.
DROP TABLE IF EXISTS mart.returns_rate;

CREATE
    TABLE mart.returns_rate AS
    SELECT
        p.category,
        CAST(SUM(oi.quantity) AS BIGINT) AS sold_qty,
        CAST(COALESCE(SUM(r.quantity), 0) AS BIGINT) AS returned_qty,
        COALESCE(SUM(r.quantity), 0) / SUM(oi.quantity) AS return_rate_int,
        (CAST(COALESCE(SUM(r.quantity), 0) AS DECIMAL(14, 4)) / CAST(SUM(oi.quantity) AS DECIMAL(14, 4))) * 100 AS return_pct
    FROM
        core.order_items AS oi JOIN core.products AS p ON p.product_id = oi.product_id LEFT JOIN
        core.returns AS r
        ON r.order_item_id = oi.order_item_id
        GROUP BY p.category
    ORDER BY p.category NULLS LAST;