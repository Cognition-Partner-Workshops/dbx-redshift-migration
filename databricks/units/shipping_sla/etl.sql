-- shipping_sla: carrier SLA. Redshift DATEDIFF(hour) counts hour boundaries,
-- so both timestamps are truncated to the hour before TIMESTAMPDIFF.
-- Redshift AVG over an integer truncates to an integer before the NUMERIC cast.
CREATE OR REPLACE TABLE gold.shipping_sla AS
WITH s AS (
    SELECT carrier,
           delivered_ts,
           TIMESTAMPDIFF(HOUR, DATE_TRUNC('HOUR', ship_ts), DATE_TRUNC('HOUR', delivered_ts)) AS hours_to_deliver
    FROM   silver.shipments
)
SELECT carrier,
       COUNT(*)                                                         AS shipments,
       COUNT(delivered_ts)                                              AS delivered,
       COUNT(*) - COUNT(delivered_ts)                                   AS in_flight,
       CAST(CAST(AVG(hours_to_deliver) AS BIGINT) AS DECIMAL(10, 2))    AS avg_hours_to_deliver,
       CAST(MAX(hours_to_deliver) AS BIGINT)                            AS max_hours_to_deliver,
       CAST(SUM(CASE WHEN hours_to_deliver <= 96 THEN 1 ELSE 0 END) AS BIGINT) AS on_time_96h,
       CAST(MIN(EXTRACT(HOUR FROM CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', delivered_ts))) AS INT)
                                                                        AS earliest_local_delivery_hour
FROM   s
GROUP  BY carrier;
