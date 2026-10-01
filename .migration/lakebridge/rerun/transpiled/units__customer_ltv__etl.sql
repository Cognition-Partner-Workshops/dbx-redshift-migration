-- customer_ltv: lifetime revenue per customer. CHAR(4) region padding is
-- carried into the output on purpose; AVG on NUMERIC(12,2) exercises
-- Redshift's numeric result scale.
DROP TABLE IF EXISTS mart.customer_ltv;

CREATE
    TABLE mart.customer_ltv AS
    SELECT
        c.customer_id,
        c.region,
        F_CLEAN_PHONE(c.phone) AS clean_phone,
        COUNT(DISTINCT o.order_id) AS order_count,
        COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0) AS ltv,
        AVG(oi.unit_price - oi.discount) AS aov
    FROM
        core.customers AS c LEFT JOIN core.orders AS o ON o.customer_id = c.customer_id LEFT JOIN
        core.order_items AS oi
        ON oi.order_id = o.order_id
        GROUP BY c.customer_id, c.region, c.phone
    ORDER BY c.customer_id NULLS LAST;