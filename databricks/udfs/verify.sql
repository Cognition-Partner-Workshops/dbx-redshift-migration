SELECT month, expected,
       silver.f_fiscal_qtr(make_date(2025, month, 1)) AS actual,
       assert_true(silver.f_fiscal_qtr(make_date(2025, month, 1)) <=> expected) AS checked
FROM VALUES
    (1, 'Q4'), (2, 'Q4'), (3, 'Q1'), (4, 'Q1'),
    (5, 'Q1'), (6, 'Q2'), (7, 'Q2'), (8, 'Q2'),
    (9, 'Q3'), (10, 'Q3'), (11, 'Q3'), (12, 'Q4')
AS cases(month, expected)
ORDER BY month;

SELECT input, expected, silver.f_clean_phone(input) AS actual,
       assert_true(silver.f_clean_phone(input) <=> expected) AS checked
FROM VALUES
    (CAST(NULL AS STRING), CAST(NULL AS STRING)),
    ('', ''),
    ('abc - ()', ''),
    ('+1 (212) 555-0199', '12125550199'),
    ('001.020-003 x4', '0010200034'),
    ('1234567890', '1234567890')
AS cases(input, expected);

SELECT assert_true(silver.f_fiscal_qtr(CAST(NULL AS DATE)) IS NULL) AS fiscal_null_checked;
