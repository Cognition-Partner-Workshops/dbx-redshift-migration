-- sessionization: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.web_sessions) = 21280, 'sessionization.web_sessions: row_count');
SELECT assert_true((SELECT SUM(customer_id) FROM gold.web_sessions) = 15976651, 'sessionization.web_sessions: sum(customer_id)');
SELECT assert_true((SELECT COUNT(customer_id) FROM gold.web_sessions) = 21280, 'sessionization.web_sessions: non_null(customer_id)');
SELECT assert_true((SELECT SUM(session_id) FROM gold.web_sessions) = 172924, 'sessionization.web_sessions: sum(session_id)');
SELECT assert_true((SELECT COUNT(session_id) FROM gold.web_sessions) = 21280, 'sessionization.web_sessions: non_null(session_id)');
SELECT assert_true((SELECT COUNT(DISTINCT session_start_ts) FROM gold.web_sessions) = 21273, 'sessionization.web_sessions: count_distinct(session_start_ts)');
SELECT assert_true((SELECT COUNT(session_start_ts) FROM gold.web_sessions) = 21280, 'sessionization.web_sessions: non_null(session_start_ts)');
SELECT assert_true((SELECT COUNT(DISTINCT session_end_ts) FROM gold.web_sessions) = 21273, 'sessionization.web_sessions: count_distinct(session_end_ts)');
SELECT assert_true((SELECT COUNT(session_end_ts) FROM gold.web_sessions) = 21280, 'sessionization.web_sessions: non_null(session_end_ts)');
SELECT assert_true((SELECT SUM(event_count) FROM gold.web_sessions) = 21293, 'sessionization.web_sessions: sum(event_count)');
SELECT assert_true((SELECT COUNT(event_count) FROM gold.web_sessions) = 21280, 'sessionization.web_sessions: non_null(event_count)');
SELECT assert_true((SELECT SUM(checkout_events) FROM gold.web_sessions) = 3089, 'sessionization.web_sessions: sum(checkout_events)');
SELECT assert_true((SELECT COUNT(checkout_events) FROM gold.web_sessions) = 21280, 'sessionization.web_sessions: non_null(checkout_events)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 1500, 'sessionization.report: row_count');
SELECT assert_true((SELECT SUM(customer_id) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 1125750, 'sessionization.report: sum(customer_id)');
SELECT assert_true((SELECT COUNT(customer_id) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 1500, 'sessionization.report: non_null(customer_id)');
SELECT assert_true((SELECT SUM(sessions) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 21280, 'sessionization.report: sum(sessions)');
SELECT assert_true((SELECT COUNT(sessions) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 1500, 'sessionization.report: non_null(sessions)');
SELECT assert_true((SELECT SUM(events) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 21293, 'sessionization.report: sum(events)');
SELECT assert_true((SELECT COUNT(events) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 1500, 'sessionization.report: non_null(events)');
SELECT assert_true((SELECT SUM(checkout_sessions) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 3089, 'sessionization.report: sum(checkout_sessions)');
SELECT assert_true((SELECT COUNT(checkout_sessions) FROM (-- BI report: sessions per customer.
SELECT customer_id,
       COUNT(*)              AS sessions,
       SUM(event_count)      AS events,
       SUM(checkout_events)  AS checkout_sessions
FROM   gold.web_sessions
GROUP  BY customer_id
ORDER  BY customer_id ASC NULLS LAST)) = 1500, 'sessionization.report: non_null(checkout_sessions)');
