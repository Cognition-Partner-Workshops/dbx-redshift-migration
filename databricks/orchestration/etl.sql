-- exec_summary: executive summary mart joining four earlier-wave marts.
-- Runs last in the nightly schedule (see legacy/redshift/99_orchestration/
-- refresh_schedule.yaml); converted from
-- legacy/redshift/99_orchestration/exec_summary/etl.sql.
-- Decimal semantics preserved from Redshift:
--   * AVG(NUMERIC(38,2)) truncates toward zero at scale 2 -> (SUM*100) DIV COUNT.
--   * NUMERIC(14,4) / NUMERIC(14,4) quotient truncates toward zero at scale 15,
--     then * 100 -> DECIMAL(38,15) (same pattern as returns_rate).
--   * SUM(avg_hours * delivered) / SUM(delivered) truncates toward zero at
--     scale 4 -> DECIMAL(38,4).
CREATE OR REPLACE TABLE gold.exec_summary AS
SELECT CAST('as_of_2025-12-31' AS VARCHAR(32))                 AS snapshot_label,
       DATE '2025-12-31'                                     AS as_of_date,
       dr.total_revenue,
       dr.total_orders,
       ltv.avg_ltv                                           AS avg_customer_ltv,
       rr.return_pct                                         AS overall_return_pct,
       sla.avg_hours_to_deliver                              AS avg_ship_hours
FROM (SELECT CAST(SUM(revenue) AS DECIMAL(38,2)) AS total_revenue,
             CAST(SUM(order_count) AS BIGINT)   AS total_orders
      FROM gold.daily_revenue) dr
CROSS JOIN (SELECT CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
                   AS avg_ltv
            FROM gold.customer_ltv) ltv
CROSS JOIN (SELECT CAST(
                   (CAST(ret_num DIV sold_num AS DECIMAL(15,0))
                    + CAST((CAST(ret_num % sold_num AS DECIMAL(14,4))
                            * CAST(1000000000000000 AS DECIMAL(16,0)))
                           DIV sold_num AS DECIMAL(15,0)) * 0.000000000000001)
                   * 100 AS DECIMAL(38,15))                   AS return_pct
            FROM (SELECT CAST(SUM(returned_qty) AS DECIMAL(14,4)) AS ret_num,
                         CAST(SUM(sold_qty)     AS DECIMAL(14,4)) AS sold_num
                  FROM gold.returns_rate) q) rr
CROSS JOIN (SELECT CAST(
                   CAST(total DIV deliv AS DECIMAL(30,0))
                   + CAST((CAST(total % deliv AS DECIMAL(38,2))
                           * CAST(10000 AS DECIMAL(5,0)))
                          DIV deliv AS DECIMAL(15,0)) * 0.0001
                   AS DECIMAL(38,4))                          AS avg_hours_to_deliver
            FROM (SELECT CAST(SUM(avg_hours_to_deliver * delivered) AS DECIMAL(38,2)) AS total,
                         CAST(SUM(delivered) AS DECIMAL(38,0))                        AS deliv
                  FROM gold.shipping_sla) q) sla;
