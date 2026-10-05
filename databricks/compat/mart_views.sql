-- Compatibility views: BI tools addressed the Redshift outputs as mart.<name>.
-- gold.* is canonical; these views let dashboards repoint with zero query
-- changes during cutover. Unqualified names resolve in the caller's catalog.
CREATE SCHEMA IF NOT EXISTS mart
COMMENT 'Compatibility views resolving legacy Redshift mart.* names to gold.* tables';

CREATE OR REPLACE VIEW mart.customer_ltv AS SELECT * FROM gold.customer_ltv;
CREATE OR REPLACE VIEW mart.exec_summary AS SELECT * FROM gold.exec_summary;
