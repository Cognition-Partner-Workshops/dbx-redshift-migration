-- Column types, DISTKEY / SORTKEY ordinals and encodings for core and mart tables.
SELECT n.nspname AS schema_name,
       c.relname AS table_name,
       a.attnum AS ordinal_position,
       a.attname AS column_name,
       format_type(a.atttypid, a.atttypmod) AS data_type,
       a.attisdistkey AS is_distkey,
       a.attsortkeyord AS sortkey_ordinal,
       format_encoding(a.attencodingtype::INTEGER) AS encoding
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('core', 'mart')
  AND c.relkind = 'r'
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY n.nspname, c.relname, a.attnum
