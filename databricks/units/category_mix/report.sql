-- BI report: category mix as published.
-- Redshift defaults: DESC sorts NULLs first, ASC sorts NULLs last.
SELECT category, units_sold, revenue, revenue_share
FROM   gold.category_mix
ORDER  BY revenue DESC NULLS FIRST, category ASC NULLS LAST;
