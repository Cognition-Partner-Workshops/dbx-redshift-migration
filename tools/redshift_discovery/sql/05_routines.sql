-- User-defined SQL UDFs and stored procedures (prokind f = function, p = procedure).
SELECT n.nspname AS schema_name,
       p.proname AS routine_name,
       p.prokind,
       p.pronargs,
       l.lanname AS language,
       p.prosrc AS body
FROM pg_proc_info p
JOIN pg_namespace n ON n.oid = p.pronamespace
JOIN pg_language l ON l.oid = p.prolang
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND l.lanname IN ('sql', 'plpgsql', 'plpythonu')
ORDER BY n.nspname, p.proname
