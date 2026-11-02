CREATE OR REPLACE TABLE gold.geo_rollup AS
SELECT CASE
         WHEN GROUPING(s.region) = 0 AND GROUPING(s.state) = 1 THEN 1
         WHEN GROUPING(s.region) = 1 AND GROUPING(s.state) = 0 THEN 2
         ELSE 3
       END                                                            AS grouping_id,
       s.region,
       s.state,
       COUNT(DISTINCT o.order_id)                                     AS order_count,
       COALESCE(SUM(oi.quantity * (oi.unit_price - oi.discount)), 0)  AS revenue
FROM   silver.stores s
LEFT JOIN silver.orders      o  ON o.store_id = s.store_id
LEFT JOIN silver.order_items oi ON oi.order_id = o.order_id
GROUP  BY GROUPING SETS ((s.region), (s.state), ());
