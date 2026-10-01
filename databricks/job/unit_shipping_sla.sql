-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/shipping_sla/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- shipping_sla: carrier SLA. Redshift DATEDIFF(hour) counts hour boundaries
-- crossed, so both timestamps are truncated to the hour before differencing.
-- Redshift AVG over BIGINT returns a truncated BIGINT before the NUMERIC(10,2)
-- cast, reproduced with integer DIV. CONVERT_TIMEZONE maps to an explicit
-- convert_timezone on TIMESTAMP_NTZ, independent of the session time zone.
CREATE OR REPLACE TABLE gold.shipping_sla AS
WITH shipment_hours AS (
    SELECT s.carrier,
           s.delivered_ts,
           TIMESTAMPDIFF(HOUR, date_trunc('HOUR', s.ship_ts),
                         date_trunc('HOUR', s.delivered_ts))                 AS hours_to_deliver,
           HOUR(convert_timezone('UTC', 'America/Los_Angeles', s.delivered_ts)) AS local_delivery_hour
    FROM   silver.shipments s
)
SELECT carrier,
       COUNT(*)                                                             AS shipments,
       COUNT(delivered_ts)                                                  AS delivered,
       COUNT(*) - COUNT(delivered_ts)                                       AS in_flight,
       CAST(SUM(hours_to_deliver) DIV NULLIF(COUNT(hours_to_deliver), 0)
            AS DECIMAL(10, 2))                                              AS avg_hours_to_deliver,
       MAX(hours_to_deliver)                                                AS max_hours_to_deliver,
       SUM(CASE WHEN hours_to_deliver <= 96 THEN 1 ELSE 0 END)              AS on_time_96h,
       CAST(MIN(local_delivery_hour) AS INT)                                AS earliest_local_delivery_hour
FROM   shipment_hours
GROUP  BY carrier
ORDER  BY carrier NULLS LAST;
