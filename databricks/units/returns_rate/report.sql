-- BI report: returns rate as published (Redshift sorts NULLs as largest).
SELECT category, sold_qty, returned_qty, return_rate_int, return_pct
FROM   gold.returns_rate
ORDER  BY return_pct DESC NULLS FIRST, category ASC NULLS LAST;
