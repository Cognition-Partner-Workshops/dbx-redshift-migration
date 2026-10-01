-- rfm_segments: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: row_count');
SELECT assert_true((SELECT SUM(customer_id) FROM gold.rfm_segments) = 1125750, 'rfm_segments.rfm_segments: sum(customer_id)');
SELECT assert_true((SELECT COUNT(customer_id) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: non_null(customer_id)');
SELECT assert_true((SELECT SUM(recency_days) FROM gold.rfm_segments) = 33522, 'rfm_segments.rfm_segments: sum(recency_days)');
SELECT assert_true((SELECT COUNT(recency_days) FROM gold.rfm_segments) = 1354, 'rfm_segments.rfm_segments: non_null(recency_days)');
SELECT assert_true((SELECT SUM(frequency) FROM gold.rfm_segments) = 20000, 'rfm_segments.rfm_segments: sum(frequency)');
SELECT assert_true((SELECT COUNT(frequency) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: non_null(frequency)');
SELECT assert_true((SELECT SUM(monetary) FROM gold.rfm_segments) = 10543825.25, 'rfm_segments.rfm_segments: sum(monetary)');
SELECT assert_true((SELECT COUNT(monetary) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: non_null(monetary)');
SELECT assert_true((SELECT SUM(r_tile) FROM gold.rfm_segments) = 4500, 'rfm_segments.rfm_segments: sum(r_tile)');
SELECT assert_true((SELECT COUNT(r_tile) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: non_null(r_tile)');
SELECT assert_true((SELECT SUM(f_tile) FROM gold.rfm_segments) = 4500, 'rfm_segments.rfm_segments: sum(f_tile)');
SELECT assert_true((SELECT COUNT(f_tile) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: non_null(f_tile)');
SELECT assert_true((SELECT SUM(m_tile) FROM gold.rfm_segments) = 4500, 'rfm_segments.rfm_segments: sum(m_tile)');
SELECT assert_true((SELECT COUNT(m_tile) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: non_null(m_tile)');
SELECT assert_true((SELECT COUNT(DISTINCT rfm_segment) FROM gold.rfm_segments) = 103, 'rfm_segments.rfm_segments: count_distinct(rfm_segment)');
SELECT assert_true((SELECT COUNT(rfm_segment) FROM gold.rfm_segments) = 1500, 'rfm_segments.rfm_segments: non_null(rfm_segment)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 103, 'rfm_segments.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT rfm_segment) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 103, 'rfm_segments.report: count_distinct(rfm_segment)');
SELECT assert_true((SELECT COUNT(rfm_segment) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 103, 'rfm_segments.report: non_null(rfm_segment)');
SELECT assert_true((SELECT SUM(customers) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 1500, 'rfm_segments.report: sum(customers)');
SELECT assert_true((SELECT COUNT(customers) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 103, 'rfm_segments.report: non_null(customers)');
SELECT assert_true((SELECT SUM(total_monetary) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 10543825.25, 'rfm_segments.report: sum(total_monetary)');
SELECT assert_true((SELECT COUNT(total_monetary) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 103, 'rfm_segments.report: non_null(total_monetary)');
SELECT assert_true((SELECT SUM(avg_frequency) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 1404, 'rfm_segments.report: sum(avg_frequency)');
SELECT assert_true((SELECT COUNT(avg_frequency) FROM (-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST)) = 103, 'rfm_segments.report: non_null(avg_frequency)');
