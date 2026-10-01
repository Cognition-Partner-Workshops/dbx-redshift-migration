-- category_mix: revenue share per product category via RATIO_TO_REPORT.
DROP TABLE IF EXISTS mart.category_mix;

CREATE
    TABLE mart.category_mix AS
    SELECT category, units_sold, revenue, revenue / SUM(revenue) OVER () AS revenue_share
    FROM
(
            SELECT
                p.category, SUM(oi.quantity) AS units_sold, SUM(oi.quantity * (oi.unit_price - oi.discount)) AS revenue
            FROM core.order_items AS oi JOIN core.products AS p ON p.product_id = oi.product_id GROUP BY p.category
        ) AS x
    ORDER BY category NULLS LAST;