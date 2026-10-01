-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/attribution/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- attribution: SUPER/PartiQL unnesting of campaign_touches payloads, as VARIANT.
-- PartiQL `FROM t, t.payload.touches tc` (lax mode) → typed explode of the
-- touches array; non-array touches yield no rows. SUPER `::VARCHAR(16)` keeps
-- only string scalars (other types → NULL) and truncates to 16 characters.
CREATE OR REPLACE TABLE gold.attribution AS
WITH touches AS (
    SELECT t.customer_id,
           tc.touch
    FROM   silver.campaign_touches AS t
    LATERAL VIEW explode(
        try_variant_get(parse_json(t.payload), '$.touches', 'ARRAY<VARIANT>')
    ) tc AS touch
),
typed AS (
    SELECT customer_id,
           CASE WHEN schema_of_variant(variant_get(touch, '$.campaign_id')) = 'STRING'
                THEN left(variant_get(touch, '$.campaign_id', 'STRING'), 16)
           END AS campaign_id,
           CASE WHEN schema_of_variant(variant_get(touch, '$.channel')) = 'STRING'
                THEN left(variant_get(touch, '$.channel', 'STRING'), 16)
           END AS touch_channel
    FROM   touches
)
SELECT campaign_id,
       touch_channel,
       COUNT(*)                    AS touches,
       COUNT(DISTINCT customer_id) AS customers_reached
FROM   typed
GROUP  BY campaign_id, touch_channel
ORDER  BY campaign_id NULLS LAST, touch_channel NULLS LAST;
