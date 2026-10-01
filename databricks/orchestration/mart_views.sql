-- Mart compatibility views: the Redshift estate addressed the 18 unit outputs
-- plus exec_summary as mart.<name>. Gold is the canonical medallion layer;
-- these views let the requested mart.* names resolve against the same data.
-- Runs under the caller's catalog context (harness sets catalog; the job task
-- file issues USE CATALOG IDENTIFIER(:catalog) first).
CREATE SCHEMA IF NOT EXISTS mart
COMMENT 'Compatibility views resolving legacy Redshift mart.* names to gold.* tables';

CREATE OR REPLACE VIEW mart.daily_revenue       AS SELECT * FROM gold.daily_revenue;
CREATE OR REPLACE VIEW mart.customer_ltv        AS SELECT * FROM gold.customer_ltv;
CREATE OR REPLACE VIEW mart.geo_rollup          AS SELECT * FROM gold.geo_rollup;
CREATE OR REPLACE VIEW mart.churn_flags         AS SELECT * FROM gold.churn_flags;
CREATE OR REPLACE VIEW mart.product_perf        AS SELECT * FROM gold.product_perf;
CREATE OR REPLACE VIEW mart.store_weekly        AS SELECT * FROM gold.store_weekly;
CREATE OR REPLACE VIEW mart.category_mix        AS SELECT * FROM gold.category_mix;
CREATE OR REPLACE VIEW mart.basket_affinity     AS SELECT * FROM gold.basket_affinity;
CREATE OR REPLACE VIEW mart.web_sessions        AS SELECT * FROM gold.web_sessions;
CREATE OR REPLACE VIEW mart.shipping_sla        AS SELECT * FROM gold.shipping_sla;
CREATE OR REPLACE VIEW mart.rfm_segments        AS SELECT * FROM gold.rfm_segments;
CREATE OR REPLACE VIEW mart.promo_lift          AS SELECT * FROM gold.promo_lift;
CREATE OR REPLACE VIEW mart.payment_mix         AS SELECT * FROM gold.payment_mix;
CREATE OR REPLACE VIEW mart.returns_rate        AS SELECT * FROM gold.returns_rate;
CREATE OR REPLACE VIEW mart.attribution         AS SELECT * FROM gold.attribution;
CREATE OR REPLACE VIEW mart.inventory_snapshot  AS SELECT * FROM gold.inventory_snapshot;
CREATE OR REPLACE VIEW mart.finance_monthly     AS SELECT * FROM gold.finance_monthly;
CREATE OR REPLACE VIEW mart.cohort_retention    AS SELECT * FROM gold.cohort_retention;
CREATE OR REPLACE VIEW mart.exec_summary        AS SELECT * FROM gold.exec_summary;
