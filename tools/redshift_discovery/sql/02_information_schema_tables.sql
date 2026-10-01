-- Privilege-filtered: only lists relations the session user can access.
SELECT table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema IN ('core', 'mart')
ORDER BY table_schema, table_name
