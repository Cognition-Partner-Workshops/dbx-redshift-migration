-- shipping_sla: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT carrier) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: count_distinct(carrier)');
SELECT assert_true((SELECT COUNT(carrier) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(carrier)');
SELECT assert_true((SELECT SUM(shipments) FROM gold.shipping_sla) = 12817, 'shipping_sla.shipping_sla: sum(shipments)');
SELECT assert_true((SELECT COUNT(shipments) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(shipments)');
SELECT assert_true((SELECT SUM(delivered) FROM gold.shipping_sla) = 11830, 'shipping_sla.shipping_sla: sum(delivered)');
SELECT assert_true((SELECT COUNT(delivered) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(delivered)');
SELECT assert_true((SELECT SUM(in_flight) FROM gold.shipping_sla) = 987, 'shipping_sla.shipping_sla: sum(in_flight)');
SELECT assert_true((SELECT COUNT(in_flight) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(in_flight)');
SELECT assert_true((SELECT SUM(avg_hours_to_deliver) FROM gold.shipping_sla) = 285.00, 'shipping_sla.shipping_sla: sum(avg_hours_to_deliver)');
SELECT assert_true((SELECT COUNT(avg_hours_to_deliver) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(avg_hours_to_deliver)');
SELECT assert_true((SELECT SUM(max_hours_to_deliver) FROM gold.shipping_sla) = 556, 'shipping_sla.shipping_sla: sum(max_hours_to_deliver)');
SELECT assert_true((SELECT COUNT(max_hours_to_deliver) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(max_hours_to_deliver)');
SELECT assert_true((SELECT SUM(on_time_96h) FROM gold.shipping_sla) = 8104, 'shipping_sla.shipping_sla: sum(on_time_96h)');
SELECT assert_true((SELECT COUNT(on_time_96h) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(on_time_96h)');
SELECT assert_true((SELECT SUM(earliest_local_delivery_hour) FROM gold.shipping_sla) = 0, 'shipping_sla.shipping_sla: sum(earliest_local_delivery_hour)');
SELECT assert_true((SELECT COUNT(earliest_local_delivery_hour) FROM gold.shipping_sla) = 4, 'shipping_sla.shipping_sla: non_null(earliest_local_delivery_hour)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT carrier) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: count_distinct(carrier)');
SELECT assert_true((SELECT COUNT(carrier) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: non_null(carrier)');
SELECT assert_true((SELECT SUM(shipments) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 12817, 'shipping_sla.report: sum(shipments)');
SELECT assert_true((SELECT COUNT(shipments) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: non_null(shipments)');
SELECT assert_true((SELECT SUM(delivered) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 11830, 'shipping_sla.report: sum(delivered)');
SELECT assert_true((SELECT COUNT(delivered) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: non_null(delivered)');
SELECT assert_true((SELECT SUM(in_flight) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 987, 'shipping_sla.report: sum(in_flight)');
SELECT assert_true((SELECT COUNT(in_flight) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: non_null(in_flight)');
SELECT assert_true((SELECT SUM(avg_hours_to_deliver) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 285.00, 'shipping_sla.report: sum(avg_hours_to_deliver)');
SELECT assert_true((SELECT COUNT(avg_hours_to_deliver) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: non_null(avg_hours_to_deliver)');
SELECT assert_true((SELECT SUM(max_hours_to_deliver) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 556, 'shipping_sla.report: sum(max_hours_to_deliver)');
SELECT assert_true((SELECT COUNT(max_hours_to_deliver) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: non_null(max_hours_to_deliver)');
SELECT assert_true((SELECT SUM(on_time_96h) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 8104, 'shipping_sla.report: sum(on_time_96h)');
SELECT assert_true((SELECT COUNT(on_time_96h) FROM (-- BI report: carrier SLA as published.
SELECT carrier, shipments, delivered, in_flight,
       avg_hours_to_deliver, max_hours_to_deliver, on_time_96h
FROM   gold.shipping_sla
ORDER  BY carrier NULLS LAST)) = 4, 'shipping_sla.report: non_null(on_time_96h)');
