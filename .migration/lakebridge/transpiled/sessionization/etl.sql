-- sessionization: web sessions per customer, 30-minute gap, running SUM id.
DROP TABLE IF EXISTS mart.web_sessions;

CREATE
    TABLE mart.web_sessions AS
    WITH
        flagged AS
        (
            SELECT
                customer_id,
                event_id,
                event_ts,
                event_type,
                CASE
                    WHEN
                    LAG(event_ts) OVER
                    (PARTITION BY customer_id ORDER BY event_ts NULLS LAST, event_id NULLS LAST) IS NULL THEN
                        1
                    WHEN
                    DATEDIFF(
                        second,
                        LAG(event_ts) OVER (PARTITION BY customer_id ORDER BY event_ts NULLS LAST, event_id NULLS LAST),
                        event_ts
                    ) > 1800 THEN
                        1
                    ELSE 0
                END AS new_session
            FROM core.web_events WHERE customer_id IS NOT NULL
        ),
        numbered AS
        (
            SELECT
                customer_id,
                event_id,
                event_ts,
                event_type,
                SUM(new_session) OVER
                (
                    PARTITION BY customer_id ORDER BY event_ts NULLS LAST, event_id NULLS LAST ROWS UNBOUNDED PRECEDING
                ) AS session_id
            FROM flagged
        )
    SELECT
        customer_id,
        session_id,
        MIN(event_ts) AS session_start_ts,
        MAX(event_ts) AS session_end_ts,
        COUNT(*) AS event_count,
        SUM(CASE WHEN event_type = 'checkout' THEN 1 ELSE 0 END) AS checkout_events
    FROM numbered GROUP BY customer_id, session_id
    ORDER BY customer_id NULLS LAST, session_id NULLS LAST;