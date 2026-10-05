-- Governed LTV KPIs over gold.customer_ltv. Measures mirror
-- legacy/redshift/units/customer_ltv/report.sql, including Redshift's AVG over
-- NUMERIC(38,2) truncating toward zero at scale 2 (same rule as the unit).
CREATE SCHEMA IF NOT EXISTS semantic
COMMENT 'Governed Unity Catalog metric views over the migrated gold.* marts';

CREATE OR REPLACE VIEW semantic.customer_ltv_metrics
WITH METRICS
LANGUAGE YAML
AS $$
version: 1.1
comment: Customer lifetime value (gold.customer_ltv, one row per customer).
source: gold.customer_ltv
dimensions:
  - name: customer_id
    expr: customer_id
  - name: region
    expr: region
measures:
  - name: customers
    expr: COUNT(1)
  - name: orders
    expr: SUM(order_count)
  - name: total_ltv
    expr: CAST(SUM(ltv) AS DECIMAL(38,2))
  - name: avg_ltv
    expr: CAST(CAST((SUM(ltv) * 100) DIV NULLIF(COUNT(ltv), 0) AS DECIMAL(36,0)) * 0.01 AS DECIMAL(38,2))
    comment: Redshift AVG over NUMERIC(38,2) truncates (does not round) to scale 2.
$$;
