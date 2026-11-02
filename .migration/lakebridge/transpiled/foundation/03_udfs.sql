-- SQL UDFs only (Redshift no longer allows Python UDFs).
-- Fiscal year starts Feb 1: Feb-Apr = Q1, May-Jul = Q2, Aug-Oct = Q3, Nov-Jan = Q4.
CREATE OR REPLACE
    FUNCTION f_fiscal_qtr(d DATE)
    RETURNS STRING
    RETURN 'Q' || CAST(((((CAST(EXTRACT(month FROM d) AS INT) + 9) % 12) / 3) + 1) AS STRING);

-- Strip a phone string down to its digits.
CREATE OR REPLACE FUNCTION f_clean_phone(p STRING) RETURNS STRING RETURN REGEXP_REPLACE(p, '[^0-9]', '');