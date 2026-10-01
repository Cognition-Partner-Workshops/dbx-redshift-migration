-- payment_mix: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT method) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: count_distinct(method)');
SELECT assert_true((SELECT COUNT(method) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: non_null(method)');
SELECT assert_true((SELECT COUNT(DISTINCT method_family) FROM gold.payment_mix) = 4, 'payment_mix.payment_mix: count_distinct(method_family)');
SELECT assert_true((SELECT COUNT(method_family) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: non_null(method_family)');
SELECT assert_true((SELECT COUNT(DISTINCT method_status) FROM gold.payment_mix) = 2, 'payment_mix.payment_mix: count_distinct(method_status)');
SELECT assert_true((SELECT COUNT(method_status) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: non_null(method_status)');
SELECT assert_true((SELECT SUM(payment_count) FROM gold.payment_mix) = 20000, 'payment_mix.payment_mix: sum(payment_count)');
SELECT assert_true((SELECT COUNT(payment_count) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: non_null(payment_count)');
SELECT assert_true((SELECT SUM(amount_total) FROM gold.payment_mix) = 10543825.25, 'payment_mix.payment_mix: sum(amount_total)');
SELECT assert_true((SELECT COUNT(amount_total) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: non_null(amount_total)');
SELECT assert_true((SELECT SUM(amount_share) FROM gold.payment_mix) = 0.9998, 'payment_mix.payment_mix: sum(amount_share)');
SELECT assert_true((SELECT COUNT(amount_share) FROM gold.payment_mix) = 5, 'payment_mix.payment_mix: non_null(amount_share)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: payment family mix. Redshift sorts NULLs last for ASC.
SELECT method_family,
       SUM(payment_count) AS payment_count,
       SUM(amount_total)  AS amount_total
FROM   gold.payment_mix
GROUP  BY method_family
ORDER  BY method_family ASC NULLS LAST)) = 4, 'payment_mix.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT method_family) FROM (-- BI report: payment family mix. Redshift sorts NULLs last for ASC.
SELECT method_family,
       SUM(payment_count) AS payment_count,
       SUM(amount_total)  AS amount_total
FROM   gold.payment_mix
GROUP  BY method_family
ORDER  BY method_family ASC NULLS LAST)) = 4, 'payment_mix.report: count_distinct(method_family)');
SELECT assert_true((SELECT COUNT(method_family) FROM (-- BI report: payment family mix. Redshift sorts NULLs last for ASC.
SELECT method_family,
       SUM(payment_count) AS payment_count,
       SUM(amount_total)  AS amount_total
FROM   gold.payment_mix
GROUP  BY method_family
ORDER  BY method_family ASC NULLS LAST)) = 4, 'payment_mix.report: non_null(method_family)');
SELECT assert_true((SELECT SUM(payment_count) FROM (-- BI report: payment family mix. Redshift sorts NULLs last for ASC.
SELECT method_family,
       SUM(payment_count) AS payment_count,
       SUM(amount_total)  AS amount_total
FROM   gold.payment_mix
GROUP  BY method_family
ORDER  BY method_family ASC NULLS LAST)) = 20000, 'payment_mix.report: sum(payment_count)');
SELECT assert_true((SELECT COUNT(payment_count) FROM (-- BI report: payment family mix. Redshift sorts NULLs last for ASC.
SELECT method_family,
       SUM(payment_count) AS payment_count,
       SUM(amount_total)  AS amount_total
FROM   gold.payment_mix
GROUP  BY method_family
ORDER  BY method_family ASC NULLS LAST)) = 4, 'payment_mix.report: non_null(payment_count)');
SELECT assert_true((SELECT SUM(amount_total) FROM (-- BI report: payment family mix. Redshift sorts NULLs last for ASC.
SELECT method_family,
       SUM(payment_count) AS payment_count,
       SUM(amount_total)  AS amount_total
FROM   gold.payment_mix
GROUP  BY method_family
ORDER  BY method_family ASC NULLS LAST)) = 10543825.25, 'payment_mix.report: sum(amount_total)');
SELECT assert_true((SELECT COUNT(amount_total) FROM (-- BI report: payment family mix. Redshift sorts NULLs last for ASC.
SELECT method_family,
       SUM(payment_count) AS payment_count,
       SUM(amount_total)  AS amount_total
FROM   gold.payment_mix
GROUP  BY method_family
ORDER  BY method_family ASC NULLS LAST)) = 4, 'payment_mix.report: non_null(amount_total)');
