SELECT assert_true(current_catalog() = 'mig_redshift_dev', 'UDF deployment requires mig_redshift_dev');

CREATE OR REPLACE FUNCTION silver.f_clean_phone(p STRING)
RETURNS STRING
LANGUAGE SQL
DETERMINISTIC
RETURN regexp_replace(p, '[^0-9]', '');
