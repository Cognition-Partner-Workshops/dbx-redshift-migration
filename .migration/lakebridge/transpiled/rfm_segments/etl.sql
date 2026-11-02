-- rfm_segments: NTILE(5) over recency/frequency/monetary as of '2025-12-31',
-- including customers with NULL metrics (NULL ordering matters).
DROP TABLE IF EXISTS mart.rfm_segments;

CREATE
    TABLE mart.rfm_segments AS
    WITH
        metrics AS
        (
            SELECT
                c.customer_id,
                DATEDIFF(day, CAST(MAX(o.order_ts) AS DATE), CAST('2025-12-31' AS DATE)) AS recency_days,
                COUNT(DISTINCT o.order_id) AS frequency,
                COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0) AS monetary
            FROM
                core.customers AS c LEFT JOIN core.orders AS o ON o.customer_id = c.customer_id LEFT JOIN
                core.order_items AS oi
                ON oi.order_id = o.order_id
                GROUP BY c.customer_id
        ),
        tiles AS
        (
            SELECT
                customer_id,
                recency_days,
                frequency,
                monetary,
                NTILE(5) OVER (ORDER BY recency_days ASC NULLS LAST, customer_id NULLS LAST) AS r_tile,
                NTILE(5) OVER (ORDER BY frequency DESC NULLS FIRST, customer_id NULLS LAST) AS f_tile,
                NTILE(5) OVER (ORDER BY monetary DESC NULLS FIRST, customer_id NULLS LAST) AS m_tile
            FROM metrics
        )
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        r_tile,
        f_tile,
        m_tile,
        CAST((CAST(r_tile AS STRING) || CAST(f_tile AS STRING) || CAST(m_tile AS STRING)) AS STRING) AS rfm_segment
    FROM tiles
    ORDER BY customer_id NULLS LAST;