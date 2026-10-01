-- attribution: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.attribution) = 100, 'attribution.attribution: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT campaign_id) FROM gold.attribution) = 20, 'attribution.attribution: count_distinct(campaign_id)');
SELECT assert_true((SELECT COUNT(campaign_id) FROM gold.attribution) = 100, 'attribution.attribution: non_null(campaign_id)');
SELECT assert_true((SELECT COUNT(DISTINCT touch_channel) FROM gold.attribution) = 5, 'attribution.attribution: count_distinct(touch_channel)');
SELECT assert_true((SELECT COUNT(touch_channel) FROM gold.attribution) = 100, 'attribution.attribution: non_null(touch_channel)');
SELECT assert_true((SELECT SUM(touches) FROM gold.attribution) = 20003, 'attribution.attribution: sum(touches)');
SELECT assert_true((SELECT COUNT(touches) FROM gold.attribution) = 100, 'attribution.attribution: non_null(touches)');
SELECT assert_true((SELECT SUM(customers_reached) FROM gold.attribution) = 18535, 'attribution.attribution: sum(customers_reached)');
SELECT assert_true((SELECT COUNT(customers_reached) FROM gold.attribution) = 100, 'attribution.attribution: non_null(customers_reached)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: campaign reach by channel.
SELECT campaign_id,
       SUM(touches)           AS touches,
       SUM(customers_reached) AS customers_reached
FROM   gold.attribution
GROUP  BY campaign_id
ORDER  BY campaign_id NULLS LAST)) = 20, 'attribution.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT campaign_id) FROM (-- BI report: campaign reach by channel.
SELECT campaign_id,
       SUM(touches)           AS touches,
       SUM(customers_reached) AS customers_reached
FROM   gold.attribution
GROUP  BY campaign_id
ORDER  BY campaign_id NULLS LAST)) = 20, 'attribution.report: count_distinct(campaign_id)');
SELECT assert_true((SELECT COUNT(campaign_id) FROM (-- BI report: campaign reach by channel.
SELECT campaign_id,
       SUM(touches)           AS touches,
       SUM(customers_reached) AS customers_reached
FROM   gold.attribution
GROUP  BY campaign_id
ORDER  BY campaign_id NULLS LAST)) = 20, 'attribution.report: non_null(campaign_id)');
SELECT assert_true((SELECT SUM(touches) FROM (-- BI report: campaign reach by channel.
SELECT campaign_id,
       SUM(touches)           AS touches,
       SUM(customers_reached) AS customers_reached
FROM   gold.attribution
GROUP  BY campaign_id
ORDER  BY campaign_id NULLS LAST)) = 20003, 'attribution.report: sum(touches)');
SELECT assert_true((SELECT COUNT(touches) FROM (-- BI report: campaign reach by channel.
SELECT campaign_id,
       SUM(touches)           AS touches,
       SUM(customers_reached) AS customers_reached
FROM   gold.attribution
GROUP  BY campaign_id
ORDER  BY campaign_id NULLS LAST)) = 20, 'attribution.report: non_null(touches)');
SELECT assert_true((SELECT SUM(customers_reached) FROM (-- BI report: campaign reach by channel.
SELECT campaign_id,
       SUM(touches)           AS touches,
       SUM(customers_reached) AS customers_reached
FROM   gold.attribution
GROUP  BY campaign_id
ORDER  BY campaign_id NULLS LAST)) = 18535, 'attribution.report: sum(customers_reached)');
SELECT assert_true((SELECT COUNT(customers_reached) FROM (-- BI report: campaign reach by channel.
SELECT campaign_id,
       SUM(touches)           AS touches,
       SUM(customers_reached) AS customers_reached
FROM   gold.attribution
GROUP  BY campaign_id
ORDER  BY campaign_id NULLS LAST)) = 20, 'attribution.report: non_null(customers_reached)');
