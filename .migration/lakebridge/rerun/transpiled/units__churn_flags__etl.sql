-- churn_flags: plpgsql procedure with a FOR loop over customers and a temp
-- table, then CALL. Flags are computed as of the fixed literal '2025-12-31'.
DROP TABLE IF EXISTS mart.churn_flags;

CREATE
    /* DISTKEY(customer_id) SORTKEY(customer_id) */
    TABLE mart.churn_flags (customer_id BIGINT, last_order_date DATE, days_since_order INT, churn_flag STRING);

CREATE OR REPLACE
    PROCEDURE sp_build_churn_flags()
    LANGUAGE SQL
    SQL SECURITY INVOKER
    AS
        BEGIN
            CREATE TEMPORARY TABLE tmp_last_orders (customer_id BIGINT, last_order_date DATE);
            INSERT INTO tmp_last_orders
            SELECT c.customer_id, CAST(MAX(o.order_ts) AS DATE)
            FROM core.customers AS c LEFT JOIN core.orders AS o ON o.customer_id = c.customer_id GROUP BY c.customer_id;
            FOR rec AS SELECT customer_id, last_order_date FROM tmp_last_orders ORDER BY customer_id NULLS LAST
            DO
                INSERT INTO mart.churn_flags
                VALUES
(
                        rec.customer_id,
                        rec.last_order_date,
                        CASE
                            WHEN rec.last_order_date IS NULL THEN NULL
                            ELSE CAST('2025-12-31' AS DATE) - rec.last_order_date
                        END,
                        CASE
                            WHEN rec.last_order_date IS NULL THEN 'never_ordered'
                            WHEN CAST('2025-12-31' AS DATE) - rec.last_order_date > 180 THEN
                                'churned'
                            WHEN CAST('2025-12-31' AS DATE) - rec.last_order_date > 90 THEN
                                'at_risk'
                            ELSE 'active'
                        END
                    );
            END FOR;
            DROP TABLE tmp_last_orders;
        END;

CALL sp_build_churn_flags();