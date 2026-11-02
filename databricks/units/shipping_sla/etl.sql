-- shipping_sla: Redshift DATEDIFF(hour) counts hour boundaries crossed
-- (timestampdiff counts whole elapsed hours), so truncate both sides to the
-- hour first. AVG over that BIGINT is a truncated BIGINT in Redshift before
-- the NUMERIC(10,2) cast. CONVERT_TIMEZONE(src, tgt, ts) -> convert_timezone.
CREATE OR REPLACE TABLE gold.shipping_sla AS
WITH s AS (
    SELECT carrier,
           delivered_ts,
           timestampdiff(HOUR, date_trunc('HOUR', ship_ts), date_trunc('HOUR', delivered_ts)) AS hours_to_deliver
    FROM   silver.shipments
)
SELECT carrier,
       COUNT(*)                                                       AS shipments,
       COUNT(delivered_ts)                                            AS delivered,
       COUNT(*) - COUNT(delivered_ts)                                 AS in_flight,
       CAST(CAST(AVG(hours_to_deliver) AS BIGINT) AS DECIMAL(10,2))   AS avg_hours_to_deliver,
       MAX(hours_to_deliver)                                          AS max_hours_to_deliver,
       SUM(CASE WHEN hours_to_deliver <= 96 THEN 1 ELSE 0 END)        AS on_time_96h,
       CAST(MIN(hour(convert_timezone('UTC', 'America/Los_Angeles', delivered_ts))) AS INT)
                                                                      AS earliest_local_delivery_hour
FROM   s
GROUP  BY carrier;
