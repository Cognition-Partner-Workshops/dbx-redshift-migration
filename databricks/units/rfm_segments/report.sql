-- Redshift AVG(BIGINT) returns a truncated BIGINT.
SELECT rfm_segment,
       COUNT(*)                          AS customers,
       SUM(monetary)                     AS total_monetary,
       CAST(AVG(frequency) AS BIGINT)    AS avg_frequency
FROM   gold.rfm_segments
GROUP  BY rfm_segment
ORDER  BY rfm_segment NULLS LAST;
