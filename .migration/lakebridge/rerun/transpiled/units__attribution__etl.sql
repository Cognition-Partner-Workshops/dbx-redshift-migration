-- attribution: SUPER/PartiQL navigation over campaign_touches payloads.
DROP TABLE IF EXISTS mart.attribution;

CREATE
    TABLE mart.attribution AS
    SELECT
        CAST(tc.campaign_id AS STRING) AS campaign_id,
        CAST(tc.channel AS STRING) AS touch_channel,
        COUNT(*) AS touches,
        COUNT(DISTINCT t.customer_id) AS customers_reached
    FROM
        core.campaign_touches AS t CROSS JOIN t.payload.touches AS tc
        GROUP BY CAST(tc.campaign_id AS STRING), CAST(tc.channel AS STRING)
    ORDER BY campaign_id NULLS LAST, touch_channel NULLS LAST;