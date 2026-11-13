-- attribution: SUPER/PartiQL navigation over campaign_touches payloads.
-- silver.campaign_touches.payload is the SUPER JSON text; PartiQL `FROM t, t.payload.touches tc`
-- is an inner unnest -> from_json + LATERAL VIEW explode (rows with no touches drop out).
CREATE OR REPLACE TABLE gold.attribution AS
SELECT CAST(tc.campaign_id AS STRING)  AS campaign_id,
       CAST(tc.channel AS STRING)      AS touch_channel,
       COUNT(*)                        AS touches,
       COUNT(DISTINCT t.customer_id)   AS customers_reached
FROM   silver.campaign_touches AS t
       LATERAL VIEW explode(
         from_json(t.payload:touches, 'ARRAY<STRUCT<campaign_id: STRING, channel: STRING>>')
       ) AS tc
GROUP  BY CAST(tc.campaign_id AS STRING), CAST(tc.channel AS STRING);
