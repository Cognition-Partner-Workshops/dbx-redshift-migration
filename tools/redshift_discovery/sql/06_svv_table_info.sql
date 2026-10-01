-- Size (1 MB blocks), row estimates, distribution / sort and health per table.
SELECT "schema" AS schema_name,
       "table" AS table_name,
       diststyle,
       sortkey1,
       sortkey_num,
       encoded,
       size AS size_mb,
       tbl_rows,
       estimated_visible_rows,
       skew_rows,
       unsorted,
       stats_off,
       pct_used
FROM svv_table_info
WHERE "schema" IN ('core', 'mart')
ORDER BY "schema", "table"
