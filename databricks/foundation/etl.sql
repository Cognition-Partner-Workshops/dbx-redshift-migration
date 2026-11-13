-- Foundation (wave 0): bronze raw tables, typed silver tables, SQL UDFs.
-- Converted from legacy/redshift/00_foundation/{01_schemas,02_core_tables,03_udfs}.sql.
-- The catalog comes from the session (validation harness / job); schemas
-- bronze, silver, gold and volume bronze.raw are created by `make db-setup`.
-- Redshift physical design (DISTKEY/DISTSTYLE/SORTKEY/ENCODE) is dropped;
-- silver tables use liquid clustering on the former sort keys instead.

-- Bronze: seed CSVs from /Volumes/<catalog>/bronze/raw loaded as-is (all
-- STRING, NULL kept as the literal \N token).
BEGIN
  DECLARE raw_dir STRING;
  IF current_catalog() NOT IN ('mig_redshift_dev', 'mig_redshift') THEN
    SIGNAL SQLSTATE '22023' SET MESSAGE_TEXT = 'foundation may only write to mig_redshift_dev or mig_redshift';
  END IF;
  SET raw_dir = '/Volumes/' || current_catalog() || '/bronze/raw/';
  FOR t AS (SELECT explode(array('customers', 'stores', 'products', 'orders', 'order_items', 'payments',
                                 'returns', 'shipments', 'web_events', 'campaign_touches')) AS name) DO
    EXECUTE IMMEDIATE format_string(
      'CREATE OR REPLACE TABLE bronze.%s AS SELECT * EXCEPT (_rescued_data) FROM read_files(\'%s%s.csv\', '
      || 'format => \'csv\', header => true, inferSchema => false, escape => \'"\', multiLine => false)',
      t.name, raw_dir, t.name);
  END FOR;
END;

-- Silver: typed tables mirroring the Redshift core DDL.
-- VARCHAR(n) -> STRING, CHAR(4) -> CHAR(4) (blank-padded like Redshift bpchar),
-- NUMERIC(12,2) -> DECIMAL(12,2), TIMESTAMP -> TIMESTAMP_NTZ (Redshift TIMESTAMP
-- has no time zone), SUPER -> STRING holding the JSON text (query it with
-- payload:path; VARIANT would re-serialize with sorted keys).

CREATE OR REPLACE TABLE silver.customers (
    customer_id         BIGINT NOT NULL,
    email               STRING,
    first_name          STRING,
    last_name           STRING,
    phone               STRING,
    region              CHAR(4),
    preferred_store_id  INT,
    signup_date         DATE,
    is_business         BOOLEAN
) CLUSTER BY (customer_id);

INSERT INTO silver.customers
SELECT
    CAST(customer_id AS BIGINT),
    NULLIF(email, '\\N'),
    NULLIF(first_name, '\\N'),
    NULLIF(last_name, '\\N'),
    NULLIF(phone, '\\N'),
    RPAD(NULLIF(region, '\\N'), 4, ' '),
    CAST(NULLIF(preferred_store_id, '\\N') AS INT),
    CAST(NULLIF(signup_date, '\\N') AS DATE),
    CAST(NULLIF(is_business, '\\N') AS BOOLEAN)
FROM bronze.customers;

CREATE OR REPLACE TABLE silver.stores (
    store_id    INT NOT NULL,
    region      CHAR(4),
    store_name  STRING,
    city        STRING,
    state       STRING
) CLUSTER BY (store_id);

INSERT INTO silver.stores
SELECT
    CAST(store_id AS INT),
    RPAD(NULLIF(region, '\\N'), 4, ' '),
    NULLIF(store_name, '\\N'),
    NULLIF(city, '\\N'),
    NULLIF(state, '\\N')
FROM bronze.stores;

CREATE OR REPLACE TABLE silver.products (
    product_id    INT NOT NULL,
    sku           STRING,
    product_name  STRING,
    category      STRING,
    subcategory   STRING,
    unit_price    DECIMAL(12,2),
    cost          DECIMAL(12,2),
    active        BOOLEAN
) CLUSTER BY (product_id);

INSERT INTO silver.products
SELECT
    CAST(product_id AS INT),
    NULLIF(sku, '\\N'),
    NULLIF(product_name, '\\N'),
    NULLIF(category, '\\N'),
    NULLIF(subcategory, '\\N'),
    CAST(NULLIF(unit_price, '\\N') AS DECIMAL(12,2)),
    CAST(NULLIF(cost, '\\N') AS DECIMAL(12,2)),
    CAST(NULLIF(active, '\\N') AS BOOLEAN)
FROM bronze.products;

CREATE OR REPLACE TABLE silver.orders (
    order_id       BIGINT NOT NULL,
    customer_id    BIGINT,
    store_id       INT,
    order_ts       TIMESTAMP_NTZ,
    sales_channel  STRING,
    status         STRING
) CLUSTER BY (order_ts);

INSERT INTO silver.orders
SELECT
    CAST(order_id AS BIGINT),
    CAST(NULLIF(customer_id, '\\N') AS BIGINT),
    CAST(NULLIF(store_id, '\\N') AS INT),
    CAST(NULLIF(order_ts, '\\N') AS TIMESTAMP_NTZ),
    NULLIF(sales_channel, '\\N'),
    NULLIF(status, '\\N')
FROM bronze.orders;

CREATE OR REPLACE TABLE silver.order_items (
    order_item_id  BIGINT NOT NULL,
    order_id       BIGINT,
    product_id     INT,
    quantity       INT,
    unit_price     DECIMAL(12,2),
    discount       DECIMAL(12,2)
) CLUSTER BY (order_id);

INSERT INTO silver.order_items
SELECT
    CAST(order_item_id AS BIGINT),
    CAST(NULLIF(order_id, '\\N') AS BIGINT),
    CAST(NULLIF(product_id, '\\N') AS INT),
    CAST(NULLIF(quantity, '\\N') AS INT),
    CAST(NULLIF(unit_price, '\\N') AS DECIMAL(12,2)),
    CAST(NULLIF(discount, '\\N') AS DECIMAL(12,2))
FROM bronze.order_items;

CREATE OR REPLACE TABLE silver.payments (
    payment_id  BIGINT NOT NULL,
    order_id    BIGINT,
    method      STRING,
    amount      DECIMAL(12,2),
    paid_ts     TIMESTAMP_NTZ
) CLUSTER BY (order_id);

INSERT INTO silver.payments
SELECT
    CAST(payment_id AS BIGINT),
    CAST(NULLIF(order_id, '\\N') AS BIGINT),
    NULLIF(method, '\\N'),
    CAST(NULLIF(amount, '\\N') AS DECIMAL(12,2)),
    CAST(NULLIF(paid_ts, '\\N') AS TIMESTAMP_NTZ)
FROM bronze.payments;

CREATE OR REPLACE TABLE silver.returns (
    return_id      BIGINT NOT NULL,
    order_item_id  BIGINT,
    quantity       INT,
    reason         STRING,
    returned_ts    TIMESTAMP_NTZ
) CLUSTER BY (returned_ts);

INSERT INTO silver.returns
SELECT
    CAST(return_id AS BIGINT),
    CAST(NULLIF(order_item_id, '\\N') AS BIGINT),
    CAST(NULLIF(quantity, '\\N') AS INT),
    NULLIF(reason, '\\N'),
    CAST(NULLIF(returned_ts, '\\N') AS TIMESTAMP_NTZ)
FROM bronze.returns;

CREATE OR REPLACE TABLE silver.shipments (
    shipment_id   BIGINT NOT NULL,
    order_id      BIGINT,
    carrier       STRING,
    ship_ts       TIMESTAMP_NTZ,
    delivered_ts  TIMESTAMP_NTZ
) CLUSTER BY (ship_ts);

INSERT INTO silver.shipments
SELECT
    CAST(shipment_id AS BIGINT),
    CAST(NULLIF(order_id, '\\N') AS BIGINT),
    NULLIF(carrier, '\\N'),
    CAST(NULLIF(ship_ts, '\\N') AS TIMESTAMP_NTZ),
    CAST(NULLIF(delivered_ts, '\\N') AS TIMESTAMP_NTZ)
FROM bronze.shipments;

CREATE OR REPLACE TABLE silver.web_events (
    event_id     BIGINT NOT NULL,
    customer_id  BIGINT,
    event_ts     TIMESTAMP_NTZ,
    event_type   STRING,
    page_url     STRING
) CLUSTER BY (event_ts);

INSERT INTO silver.web_events
SELECT
    CAST(event_id AS BIGINT),
    CAST(NULLIF(customer_id, '\\N') AS BIGINT),
    CAST(NULLIF(event_ts, '\\N') AS TIMESTAMP_NTZ),
    NULLIF(event_type, '\\N'),
    NULLIF(page_url, '\\N')
FROM bronze.web_events;

CREATE OR REPLACE TABLE silver.campaign_touches (
    touch_id     BIGINT NOT NULL,
    customer_id  BIGINT,
    payload      STRING
) CLUSTER BY (touch_id);

INSERT INTO silver.campaign_touches
SELECT
    CAST(touch_id AS BIGINT),
    CAST(NULLIF(customer_id, '\\N') AS BIGINT),
    NULLIF(payload, '\\N')
FROM bronze.campaign_touches;

-- UDFs (03_udfs.sql). Redshift `/` on INTs is integer division -> DIV.
-- Fiscal year starts Feb 1: Feb-Apr = Q1, May-Jul = Q2, Aug-Oct = Q3, Nov-Jan = Q4.
CREATE OR REPLACE FUNCTION silver.f_fiscal_qtr(d DATE)
RETURNS STRING
DETERMINISTIC
RETURN 'Q' || CAST((((EXTRACT(MONTH FROM d) + 9) % 12) DIV 3) + 1 AS STRING);

-- Strip a phone string down to its digits.
CREATE OR REPLACE FUNCTION silver.f_clean_phone(p STRING)
RETURNS STRING
DETERMINISTIC
RETURN REGEXP_REPLACE(p, '[^0-9]', '');
