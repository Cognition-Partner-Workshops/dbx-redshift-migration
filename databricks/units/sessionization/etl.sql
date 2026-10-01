-- sessionization: web sessions per customer, 30-minute gap, running SUM id.
-- Redshift DATEDIFF(second, a, b) counts second boundaries crossed, so the gap
-- is the difference of whole epoch seconds (floored), computed on the
-- TIMESTAMP_NTZ wall clock with no session-timezone conversion.
CREATE OR REPLACE TABLE gold.web_sessions
CLUSTER BY (customer_id, session_id)
AS
WITH events AS (
    SELECT customer_id,
           event_id,
           event_ts,
           event_type,
           FLOOR(CAST(timestampdiff(MICROSECOND, TIMESTAMP_NTZ '1970-01-01 00:00:00', event_ts) AS DECIMAL(20, 0))
                 / 1000000) AS event_epoch_second
    FROM   silver.web_events
    WHERE  customer_id IS NOT NULL
),
flagged AS (
    SELECT customer_id,
           event_id,
           event_ts,
           event_type,
           CASE
             WHEN LAG(event_ts) OVER (PARTITION BY customer_id
                                      ORDER BY event_ts ASC NULLS LAST, event_id ASC NULLS LAST) IS NULL THEN 1
             WHEN event_epoch_second
                  - LAG(event_epoch_second) OVER (PARTITION BY customer_id
                                                  ORDER BY event_ts ASC NULLS LAST, event_id ASC NULLS LAST)
                  > 1800 THEN 1
             ELSE 0
           END AS new_session
    FROM   events
),
numbered AS (
    SELECT customer_id,
           event_id,
           event_ts,
           event_type,
           SUM(new_session) OVER (PARTITION BY customer_id
                                  ORDER BY event_ts ASC NULLS LAST, event_id ASC NULLS LAST
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS session_id
    FROM   flagged
)
SELECT customer_id,
       session_id,
       MIN(event_ts)      AS session_start_ts,
       MAX(event_ts)      AS session_end_ts,
       COUNT(*)           AS event_count,
       SUM(CASE WHEN event_type = 'checkout' THEN 1 ELSE 0 END) AS checkout_events
FROM   numbered
GROUP  BY customer_id, session_id;
