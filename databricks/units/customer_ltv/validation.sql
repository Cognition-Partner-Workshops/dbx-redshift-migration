-- customer_ltv: G3 in-job aggregate assertions (assert_true) vs committed goldens
-- golden/customer_ltv/{customer_ltv,report}.csv. Coarse count/sum gate; the
-- row-level oracle remains `make validate`. Unqualified names: runs under the
-- caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.customer_ltv) = 1500, 'customer_ltv: row_count');
SELECT assert_true((SELECT SUM(order_count) FROM gold.customer_ltv) = 20000, 'customer_ltv: sum(order_count)');
SELECT assert_true((SELECT SUM(ltv) FROM gold.customer_ltv) = 10543825.25, 'customer_ltv: sum(ltv)');
SELECT assert_true((SELECT SUM(aov) FROM gold.customer_ltv) = 265557.48, 'customer_ltv: sum(aov)');
SELECT assert_true((SELECT COUNT(aov) FROM gold.customer_ltv) = 1354, 'customer_ltv: non_null(aov)');
SELECT assert_true((SELECT COUNT(clean_phone) FROM gold.customer_ltv) = 1319, 'customer_ltv: non_null(clean_phone)');
SELECT assert_true((SELECT COUNT(*) FROM gold.customer_ltv
                    WHERE octet_length(region) = 4 AND length(rtrim(region)) < 4) = 331,
                   'customer_ltv: CHAR(4) trailing-space padded regions');
SELECT assert_true((SELECT COUNT(*) FROM (SELECT region FROM gold.customer_ltv GROUP BY region)) = 6,
                   'customer_ltv.report: row_count');
SELECT assert_true((SELECT SUM(avg_ltv) FROM (
                        SELECT CAST(CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01
                                    AS DECIMAL(38,2)) AS avg_ltv
                        FROM gold.customer_ltv
                        GROUP BY region)) = 42424.29,
                   'customer_ltv.report: sum(avg_ltv)');
