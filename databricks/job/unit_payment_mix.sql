-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/units/payment_mix/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

-- payment_mix: payment method mix (Redshift DECODE / NVL / NVL2, window share).
-- Grouping stays on the raw method so a NULL method forms its own 'unknown' row.
-- Redshift returns SUM(NUMERIC(12,2)) / SUM(NUMERIC(12,2)) at scale 4, truncated
-- toward zero; Databricks division keeps more digits, so truncate explicitly.
CREATE OR REPLACE TABLE gold.payment_mix AS
WITH by_method AS (
    SELECT p.method                                         AS raw_method,
           COUNT(*)                                         AS payment_count,
           SUM(p.amount)                                    AS amount_total,
           SUM(p.amount) / SUM(SUM(p.amount)) OVER ()       AS amount_share_raw
    FROM   silver.payments p
    GROUP  BY p.method
)
SELECT NVL(raw_method, 'unknown')                           AS method,
       DECODE(NVL(raw_method, 'unknown'),
              'card',      'CARD',
              'cash',      'CASH',
              'wallet',    'DIGITAL',
              'gift_card', 'DIGITAL',
              'OTHER')                                      AS method_family,
       NVL2(raw_method, 'captured', 'missing')              AS method_status,
       payment_count,
       amount_total,
       CAST(CASE WHEN amount_share_raw >= 0 THEN FLOOR(amount_share_raw, 4)
                 ELSE CEIL(amount_share_raw, 4)
            END AS DECIMAL(38, 4))                          AS amount_share
FROM   by_method;
