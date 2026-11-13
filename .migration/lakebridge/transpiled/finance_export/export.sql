-------------- Exception Start-------------------
/*

[PARSE_SYNTAX_ERROR] Syntax error at or near end of input. SQLSTATE: 42601 (line 12, pos 64)

== SQL ==
EXPLAIN /*
    UNLOAD ('SELECT * FROM mart.finance_monthly ORDER BY month')
TO 's3://<bucket>/finance_export/monthly/'
IAM_ROLE '<role-arn>'
PARALLEL OFF
CSV
HEADER
*/
-- FIXME: REDSHIFT: Databricks SQL has no equivalent to the UNLOAD command, and it cannot be translated
-- Comments whose exact transformed position could not be retained:
-- Monthly finance export to S3. Placeholders — never executed at capture
-- (listed in the unit's capture_skip in .migration/units.yaml).
----------------------------------------------------------------^^^

*/

 ---------------Exception End --------------------
