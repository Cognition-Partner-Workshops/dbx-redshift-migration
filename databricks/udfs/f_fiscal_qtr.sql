SELECT assert_true(current_catalog() = 'mig_redshift_dev', 'UDF deployment requires mig_redshift_dev');

CREATE OR REPLACE FUNCTION silver.f_fiscal_qtr(d DATE)
RETURNS STRING
LANGUAGE SQL
DETERMINISTIC
RETURN 'Q' || CAST(((((CAST(extract(MONTH FROM d) AS INT) + 9) % 12) DIV 3) + 1) AS STRING);
