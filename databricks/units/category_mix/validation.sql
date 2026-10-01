-- category_mix: aggregate checks vs committed goldens (assert_true).
-- Coarse count/sum gate; the row-level oracle remains `make validate`.
-- Expected values generated from the committed golden CSVs.
-- Run under the caller's catalog context.
SELECT assert_true((SELECT COUNT(*) FROM gold.category_mix) = 6, 'category_mix.category_mix: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT category) FROM gold.category_mix) = 6, 'category_mix.category_mix: count_distinct(category)');
SELECT assert_true((SELECT COUNT(category) FROM gold.category_mix) = 6, 'category_mix.category_mix: non_null(category)');
SELECT assert_true((SELECT SUM(units_sold) FROM gold.category_mix) = 53732, 'category_mix.category_mix: sum(units_sold)');
SELECT assert_true((SELECT COUNT(units_sold) FROM gold.category_mix) = 6, 'category_mix.category_mix: non_null(units_sold)');
SELECT assert_true((SELECT SUM(revenue) FROM gold.category_mix) = 10543825.25, 'category_mix.category_mix: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM gold.category_mix) = 6, 'category_mix.category_mix: non_null(revenue)');
SELECT assert_true(ABS((SELECT SUM(revenue_share) FROM gold.category_mix) - 1.0) <= 2e-09, 'category_mix.category_mix: sum(revenue_share)');
SELECT assert_true((SELECT COUNT(revenue_share) FROM gold.category_mix) = 6, 'category_mix.category_mix: non_null(revenue_share)');
SELECT assert_true((SELECT COUNT(*) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'category_mix.report: row_count');
SELECT assert_true((SELECT COUNT(DISTINCT category) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'category_mix.report: count_distinct(category)');
SELECT assert_true((SELECT COUNT(category) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'category_mix.report: non_null(category)');
SELECT assert_true((SELECT SUM(units_sold) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 53732, 'category_mix.report: sum(units_sold)');
SELECT assert_true((SELECT COUNT(units_sold) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'category_mix.report: non_null(units_sold)');
SELECT assert_true((SELECT SUM(revenue) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 10543825.25, 'category_mix.report: sum(revenue)');
SELECT assert_true((SELECT COUNT(revenue) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'category_mix.report: non_null(revenue)');
SELECT assert_true(ABS((SELECT SUM(revenue_share) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) - 1.0) <= 2e-09, 'category_mix.report: sum(revenue_share)');
SELECT assert_true((SELECT COUNT(revenue_share) FROM (-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST)) = 6, 'category_mix.report: non_null(revenue_share)');
