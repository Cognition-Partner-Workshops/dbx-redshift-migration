-- BI report: RFM segment sizes and value.
-- Redshift AVG over a BIGINT returns a truncated BIGINT; DIV keeps integer semantics.
SELECT rfm_segment,
       COUNT(*)                            AS customers,
       SUM(monetary)                       AS total_monetary,
       SUM(frequency) DIV COUNT(frequency) AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment ASC NULLS LAST;
