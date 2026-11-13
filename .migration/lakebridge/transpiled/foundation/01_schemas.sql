-------------- Exception Start-------------------
/*

[PARSE_SYNTAX_ERROR] Syntax error at or near 'CREATE': extra input 'CREATE'. SQLSTATE: 42601 (line 5, pos 0)

== SQL ==
EXPLAIN -- Foundation: schemas. setup drops/recreates these; kept here so the estate
-- reads as a complete deployable script.
CREATE SCHEMA IF NOT EXISTS core;

CREATE SCHEMA IF NOT EXISTS mart;
^^^

*/

 ---------------Exception End --------------------
