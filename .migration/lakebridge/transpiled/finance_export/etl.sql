-- finance_export: monthly finance rollup on the fiscal calendar
-- (fiscal year starts Feb 1) via f_fiscal_qtr.
DROP TABLE IF EXISTS mart.finance_monthly;

CREATE
    TABLE mart.finance_monthly AS
    SELECT
        CAST(DATE_TRUNC('MONTH', o.order_ts) AS DATE) AS month,
        CASE
            WHEN EXTRACT(month FROM o.order_ts) >= 2 THEN CAST(EXTRACT(year FROM o.order_ts) AS INT)
            ELSE CAST(EXTRACT(year FROM o.order_ts) AS INT) - 1
        END AS fiscal_year,
        F_FISCAL_QTR(CAST(CAST(o.order_ts AS DATE) AS DATE)) AS fiscal_qtr,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * (oi.unit_price - oi.discount)) AS revenue
    FROM core.orders AS o JOIN core.order_items AS oi ON oi.order_id = o.order_id GROUP BY 1, 2, 3
    ORDER BY month NULLS LAST;