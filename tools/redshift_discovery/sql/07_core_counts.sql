-- Exact row counts for the 10 foundation tables (02_core_tables.sql).
SELECT 'core.campaign_touches' AS table_name, COUNT(*) AS row_count FROM core.campaign_touches
UNION ALL SELECT 'core.customers', COUNT(*) FROM core.customers
UNION ALL SELECT 'core.order_items', COUNT(*) FROM core.order_items
UNION ALL SELECT 'core.orders', COUNT(*) FROM core.orders
UNION ALL SELECT 'core.payments', COUNT(*) FROM core.payments
UNION ALL SELECT 'core.products', COUNT(*) FROM core.products
UNION ALL SELECT 'core.returns', COUNT(*) FROM core.returns
UNION ALL SELECT 'core.shipments', COUNT(*) FROM core.shipments
UNION ALL SELECT 'core.stores', COUNT(*) FROM core.stores
UNION ALL SELECT 'core.web_events', COUNT(*) FROM core.web_events
ORDER BY 1
