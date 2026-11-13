-- payment_mix: payment method mix using DECODE, NVL and NVL2.
-- Redshift NUMERIC division yields scale 4 truncated toward zero; reproduce with FLOOR/CEIL.
DROP TABLE IF EXISTS gold.payment_mix;

CREATE TABLE gold.payment_mix AS
SELECT
    COALESCE(p.method, 'unknown') AS method,
    DECODE(
        COALESCE(p.method, 'unknown'),
        'card', 'CARD',
        'cash', 'CASH',
        'wallet', 'DIGITAL',
        'gift_card', 'DIGITAL',
        'OTHER'
    ) AS method_family,
    NVL2(p.method, 'captured', 'missing') AS method_status,
    COUNT(*) AS payment_count,
    SUM(p.amount) AS amount_total,
    CAST(
        CASE
            WHEN SUM(p.amount) / SUM(SUM(p.amount)) OVER () < 0
                THEN CEIL(SUM(p.amount) / SUM(SUM(p.amount)) OVER (), 4)
            ELSE FLOOR(SUM(p.amount) / SUM(SUM(p.amount)) OVER (), 4)
        END AS DECIMAL(38, 4)
    ) AS amount_share
FROM silver.payments AS p
GROUP BY p.method;
