-- product_perf: per-product sales with a LISTAGG of top store codes.
DROP TABLE IF EXISTS mart.product_perf;

CREATE
    TABLE mart.product_perf AS
    WITH
        per_store AS
        (
            SELECT oi.product_id, s.region, SUM(oi.quantity) AS units
            FROM
                core.order_items AS oi JOIN core.orders AS o ON o.order_id = oi.order_id JOIN
                core.stores AS s
                ON s.store_id = o.store_id
                GROUP BY oi.product_id, s.region
        ),
        top_stores AS
        (
            SELECT
                product_id,
                CAST(ARRAY_JOIN(TRANSFORM(ARRAY_SORT(ARRAY_AGG(NAMED_STRUCT('value', region, 'sort_by_0', units, 'sort_by_1', region)), (left, right) -> CASE WHEN left.sort_by_0 < right.sort_by_0 THEN 1 WHEN left.sort_by_0 > right.sort_by_0 THEN -1 WHEN left.sort_by_1 < right.sort_by_1 THEN -1 WHEN left.sort_by_1 > right.sort_by_1 THEN 1 ELSE 0 END), s -> s.value), ',') AS STRING) AS codes
            FROM
(
                    SELECT
                        product_id,
                        region,
                        units,
                        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY units DESC NULLS FIRST, region NULLS LAST) AS rn
                    FROM per_store
                ) AS ranked
                WHERE rn <= 3
                GROUP BY product_id
        ),
        agg AS
        (
            SELECT
                product_id,
                CAST(SUM(quantity) AS BIGINT) AS units_sold,
                CAST(SUM(quantity * (unit_price - discount)) AS DECIMAL(18, 2)) AS revenue
            FROM core.order_items GROUP BY product_id
        )
    SELECT
        p.product_id,
        p.category,
        COALESCE(a.units_sold, 0) AS units_sold,
        COALESCE(a.revenue, 0) AS revenue,
        ts.codes AS top_stores
    FROM
        core.products AS p LEFT JOIN agg AS a ON a.product_id = p.product_id LEFT JOIN top_stores AS ts
        ON ts.product_id = p.product_id
    ORDER BY p.product_id NULLS LAST;