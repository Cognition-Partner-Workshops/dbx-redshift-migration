-- Catalog view of the same relations, including Redshift distribution style.
SELECT n.nspname AS schema_name,
       c.relname AS table_name,
       c.relkind,
       c.reldiststyle,
       c.reltuples
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('core', 'mart')
  AND c.relkind IN ('r', 'v')
ORDER BY n.nspname, c.relname
