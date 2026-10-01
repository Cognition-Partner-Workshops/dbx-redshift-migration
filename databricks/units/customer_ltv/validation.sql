-- customer_ltv: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.customer_ltv) = 1500, 'customer_ltv.customer_ltv: row_count');
SELECT assert_true((SELECT SUM(customer_id) FROM gold.customer_ltv) = 1125750, 'customer_ltv.customer_ltv: sum(customer_id)');
SELECT assert_true((SELECT COUNT(customer_id) FROM gold.customer_ltv) = 1500, 'customer_ltv.customer_ltv: non_null(customer_id)');
SELECT assert_true((SELECT COUNT(DISTINCT region) FROM gold.customer_ltv) = 6, 'customer_ltv.customer_ltv: count_distinct(region)');
SELECT assert_true((SELECT COUNT(region) FROM gold.customer_ltv) = 1500, 'customer_ltv.customer_ltv: non_null(region)');
SELECT assert_true((SELECT COUNT(DISTINCT clean_phone) FROM gold.customer_ltv) = 1319, 'customer_ltv.customer_ltv: count_distinct(clean_phone)');
SELECT assert_true((SELECT COUNT(clean_phone) FROM gold.customer_ltv) = 1319, 'customer_ltv.customer_ltv: non_null(clean_phone)');
SELECT assert_true((SELECT SUM(order_count) FROM gold.customer_ltv) = 20000, 'customer_ltv.customer_ltv: sum(order_count)');
SELECT assert_true((SELECT COUNT(order_count) FROM gold.customer_ltv) = 1500, 'customer_ltv.customer_ltv: non_null(order_count)');
SELECT assert_true((SELECT SUM(ltv) FROM gold.customer_ltv) = 10543825.25, 'customer_ltv.customer_ltv: sum(ltv)');
SELECT assert_true((SELECT COUNT(ltv) FROM gold.customer_ltv) = 1500, 'customer_ltv.customer_ltv: non_null(ltv)');
SELECT assert_true((SELECT SUM(aov) FROM gold.customer_ltv) = 265557.48, 'customer_ltv.customer_ltv: sum(aov)');
SELECT assert_true((SELECT COUNT(aov) FROM gold.customer_ltv) = 1354, 'customer_ltv.customer_ltv: non_null(aov)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 6, 'customer_ltv.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT region) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 6, 'customer_ltv.report: count_distinct(region)');
SELECT assert_true((SELECT COUNT(region) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 6, 'customer_ltv.report: non_null(region)');
SELECT assert_true((SELECT SUM(customers) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 1500, 'customer_ltv.report: sum(customers)');
SELECT assert_true((SELECT COUNT(customers) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 6, 'customer_ltv.report: non_null(customers)');
SELECT assert_true((SELECT SUM(orders) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 20000, 'customer_ltv.report: sum(orders)');
SELECT assert_true((SELECT COUNT(orders) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 6, 'customer_ltv.report: non_null(orders)');
SELECT assert_true((SELECT SUM(total_ltv) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 10543825.25, 'customer_ltv.report: sum(total_ltv)');
SELECT assert_true((SELECT COUNT(total_ltv) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 6, 'customer_ltv.report: non_null(total_ltv)');
SELECT assert_true((SELECT SUM(avg_ltv) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 42424.29, 'customer_ltv.report: sum(avg_ltv)');
SELECT assert_true((SELECT COUNT(avg_ltv) FROM (-- BI report: LTV summary per region (source: legacy/redshift/units/customer_ltv/report.sql).
-- region is CHAR(4): padding is part of the output. Redshift sorts NULLs last
-- ascending, and AVG over NUMERIC(38,2) truncates to scale 2.
SELECT region,
       COUNT(*)         AS customers,
       SUM(order_count) AS orders,
       CAST(SUM(ltv) AS DECIMAL(38,2)) AS total_ltv,
       CAST(
           CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
           AS DECIMAL(38,2)) AS avg_ltv
FROM   gold.customer_ltv
GROUP  BY region
ORDER  BY region ASC NULLS LAST)) = 6, 'customer_ltv.report: non_null(avg_ltv)');
