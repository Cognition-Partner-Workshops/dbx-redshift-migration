-- BI report: fiscal-year revenue summary.
-- Redshift sorts NULLs last on ascending ORDER BY; made explicit here.
SELECT fiscal_year, fiscal_qtr,
       SUM(order_count) AS order_count,
       SUM(revenue)     AS revenue
FROM   gold.finance_monthly
GROUP  BY fiscal_year, fiscal_qtr
ORDER  BY fiscal_year NULLS LAST, fiscal_qtr NULLS LAST;
