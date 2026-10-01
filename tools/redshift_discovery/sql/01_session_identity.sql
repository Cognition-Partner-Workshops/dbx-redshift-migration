-- Who the discovery session runs as; no objects are read.
SELECT current_user AS db_user,
       current_database() AS database_name,
       version() AS redshift_version
