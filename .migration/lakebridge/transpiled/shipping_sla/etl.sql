-- shipping_sla: carrier SLA using DATEDIFF(hour) (Redshift counts hour
-- boundaries) and CONVERT_TIMEZONE for the local delivery hour.
DROP TABLE IF EXISTS mart.shipping_sla;

CREATE
    TABLE mart.shipping_sla AS
    SELECT
        s.carrier,
        COUNT(*) AS shipments,
        COUNT(s.delivered_ts) AS delivered,
        COUNT(*) - COUNT(s.delivered_ts) AS in_flight,
        CAST(AVG(DATEDIFF(hour, s.ship_ts, s.delivered_ts)) AS DECIMAL(10, 2)) AS avg_hours_to_deliver,
        MAX(DATEDIFF(hour, s.ship_ts, s.delivered_ts)) AS max_hours_to_deliver,
        SUM(CASE WHEN DATEDIFF(hour, s.ship_ts, s.delivered_ts) <= 96 THEN 1 ELSE 0 END) AS on_time_96h,
        CAST(MIN(EXTRACT(hour FROM CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', s.delivered_ts))) AS INT) AS earliest_local_delivery_hour
    FROM core.shipments AS s GROUP BY s.carrier
    ORDER BY s.carrier NULLS LAST;