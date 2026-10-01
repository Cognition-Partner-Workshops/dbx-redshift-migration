-- Job task file for the Lakeflow nightly_mart_refresh job.
-- GENERATED: `USE CATALOG IDENTIFIER(:catalog)` prefix plus the full body of
-- databricks/foundation/etl.sql — keep this file in sync with that source.
-- The job binds :catalog via the sql_task parameters map; IDENTIFIER() keeps
-- the catalog substitution safe (no string interpolation into SQL).
USE CATALOG IDENTIFIER(:catalog);

BEGIN
DECLARE csv_sql STRING;
DECLARE customers_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/customers.csv');
DECLARE stores_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/stores.csv');
DECLARE products_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/products.csv');
DECLARE orders_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/orders.csv');
DECLARE order_items_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/order_items.csv');
DECLARE payments_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/payments.csv');
DECLARE returns_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/returns.csv');
DECLARE shipments_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/shipments.csv');
DECLARE web_events_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/web_events.csv');
DECLARE campaign_touches_csv STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/campaign_touches.csv');

SELECT assert_true(current_catalog() IN ('mig_redshift_dev', 'mig_redshift'), 'Foundation requires an allowed migration catalog');

CREATE OR REPLACE TABLE bronze.customers (
    customer_id BIGINT NOT NULL,
    email VARCHAR(320),
    first_name VARCHAR(64),
    last_name VARCHAR(64),
    phone VARCHAR(32),
    region CHAR(4),
    preferred_store_id INT,
    signup_date DATE,
    is_business BOOLEAN
) USING DELTA;

SET csv_sql = concat('INSERT INTO bronze.customers
SELECT customer_id, email, first_name, last_name, phone, region, preferred_store_id, signup_date, is_business
FROM read_files(
    \'', customers_csv, '\',
    format => \'csv\',
    schema => \'customer_id BIGINT, email STRING, first_name STRING, last_name STRING, phone STRING, region STRING, preferred_store_id INT, signup_date DATE, is_business BOOLEAN\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.stores (
    store_id INT NOT NULL,
    region CHAR(4),
    store_name VARCHAR(64),
    city VARCHAR(64),
    state VARCHAR(2)
) USING DELTA;

SET csv_sql = concat('INSERT INTO bronze.stores
SELECT store_id, region, store_name, city, state
FROM read_files(
    \'', stores_csv, '\',
    format => \'csv\',
    schema => \'store_id INT, region STRING, store_name STRING, city STRING, state STRING\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.products (
    product_id INT NOT NULL,
    sku VARCHAR(16),
    product_name VARCHAR(128),
    category VARCHAR(32),
    subcategory VARCHAR(32),
    unit_price DECIMAL(12,2),
    cost DECIMAL(12,2),
    active BOOLEAN
) USING DELTA;

SET csv_sql = concat('INSERT INTO bronze.products
SELECT product_id, sku, product_name, category, subcategory, unit_price, cost, active
FROM read_files(
    \'', products_csv, '\',
    format => \'csv\',
    schema => \'product_id INT, sku STRING, product_name STRING, category STRING, subcategory STRING, unit_price DECIMAL(12,2), cost DECIMAL(12,2), active BOOLEAN\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.orders (
    order_id BIGINT NOT NULL,
    customer_id BIGINT,
    store_id INT,
    order_ts TIMESTAMP_NTZ,
    sales_channel VARCHAR(16),
    status VARCHAR(16)
) USING DELTA
CLUSTER BY (customer_id);

SET csv_sql = concat('INSERT INTO bronze.orders
SELECT order_id, customer_id, store_id, order_ts, sales_channel, status
FROM read_files(
    \'', orders_csv, '\',
    format => \'csv\',
    schema => \'order_id BIGINT, customer_id BIGINT, store_id INT, order_ts TIMESTAMP_NTZ, sales_channel STRING, status STRING\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.order_items (
    order_item_id BIGINT NOT NULL,
    order_id BIGINT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(12,2),
    discount DECIMAL(12,2)
) USING DELTA
CLUSTER BY (order_id);

SET csv_sql = concat('INSERT INTO bronze.order_items
SELECT order_item_id, order_id, product_id, quantity, unit_price, discount
FROM read_files(
    \'', order_items_csv, '\',
    format => \'csv\',
    schema => \'order_item_id BIGINT, order_id BIGINT, product_id INT, quantity INT, unit_price DECIMAL(12,2), discount DECIMAL(12,2)\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.payments (
    payment_id BIGINT NOT NULL,
    order_id BIGINT,
    method VARCHAR(16),
    amount DECIMAL(12,2),
    paid_ts TIMESTAMP_NTZ
) USING DELTA;

SET csv_sql = concat('INSERT INTO bronze.payments
SELECT payment_id, order_id, method, amount, paid_ts
FROM read_files(
    \'', payments_csv, '\',
    format => \'csv\',
    schema => \'payment_id BIGINT, order_id BIGINT, method STRING, amount DECIMAL(12,2), paid_ts TIMESTAMP_NTZ\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.returns (
    return_id BIGINT NOT NULL,
    order_item_id BIGINT,
    quantity INT,
    reason VARCHAR(64),
    returned_ts TIMESTAMP_NTZ
) USING DELTA;

SET csv_sql = concat('INSERT INTO bronze.returns
SELECT return_id, order_item_id, quantity, reason, returned_ts
FROM read_files(
    \'', returns_csv, '\',
    format => \'csv\',
    schema => \'return_id BIGINT, order_item_id BIGINT, quantity INT, reason STRING, returned_ts TIMESTAMP_NTZ\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.shipments (
    shipment_id BIGINT NOT NULL,
    order_id BIGINT,
    carrier VARCHAR(16),
    ship_ts TIMESTAMP_NTZ,
    delivered_ts TIMESTAMP_NTZ
) USING DELTA;

SET csv_sql = concat('INSERT INTO bronze.shipments
SELECT shipment_id, order_id, carrier, ship_ts, delivered_ts
FROM read_files(
    \'', shipments_csv, '\',
    format => \'csv\',
    schema => \'shipment_id BIGINT, order_id BIGINT, carrier STRING, ship_ts TIMESTAMP_NTZ, delivered_ts TIMESTAMP_NTZ\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.web_events (
    event_id BIGINT NOT NULL,
    customer_id BIGINT,
    event_ts TIMESTAMP_NTZ,
    event_type VARCHAR(16),
    page_url VARCHAR(256)
) USING DELTA
CLUSTER BY (customer_id);

SET csv_sql = concat('INSERT INTO bronze.web_events
SELECT event_id, customer_id, event_ts, event_type, page_url
FROM read_files(
    \'', web_events_csv, '\',
    format => \'csv\',
    schema => \'event_id BIGINT, customer_id BIGINT, event_ts TIMESTAMP_NTZ, event_type STRING, page_url STRING\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE bronze.campaign_touches (
    touch_id BIGINT NOT NULL,
    customer_id BIGINT,
    payload VARIANT
) USING DELTA;

SET csv_sql = concat('INSERT INTO bronze.campaign_touches
SELECT touch_id, customer_id, parse_json(payload) AS payload
FROM read_files(
    \'', campaign_touches_csv, '\',
    format => \'csv\',
    schema => \'touch_id BIGINT, customer_id BIGINT, payload STRING\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE TABLE silver.customers (
    customer_id BIGINT NOT NULL,
    email VARCHAR(320),
    first_name VARCHAR(64),
    last_name VARCHAR(64),
    phone VARCHAR(32),
    region CHAR(4),
    preferred_store_id INT,
    signup_date DATE,
    is_business BOOLEAN
) USING DELTA;

INSERT INTO silver.customers
SELECT customer_id, email, first_name, last_name, phone, rpad(region, 4, ' '), preferred_store_id, signup_date, is_business
FROM bronze.customers;

CREATE OR REPLACE TABLE silver.stores (
    store_id INT NOT NULL,
    region CHAR(4),
    store_name VARCHAR(64),
    city VARCHAR(64),
    state VARCHAR(2)
) USING DELTA;

INSERT INTO silver.stores
SELECT store_id, rpad(region, 4, ' '), store_name, city, state
FROM bronze.stores;

CREATE OR REPLACE TABLE silver.products (
    product_id INT NOT NULL,
    sku VARCHAR(16),
    product_name VARCHAR(128),
    category VARCHAR(32),
    subcategory VARCHAR(32),
    unit_price DECIMAL(12,2),
    cost DECIMAL(12,2),
    active BOOLEAN
) USING DELTA;

INSERT INTO silver.products
SELECT product_id, sku, product_name, category, subcategory, unit_price, cost, active
FROM bronze.products;

CREATE OR REPLACE TABLE silver.orders (
    order_id BIGINT NOT NULL,
    customer_id BIGINT,
    store_id INT,
    order_ts TIMESTAMP_NTZ,
    sales_channel VARCHAR(16),
    status VARCHAR(16)
) USING DELTA;

INSERT INTO silver.orders
SELECT order_id, customer_id, store_id, order_ts, sales_channel, status
FROM bronze.orders;

CREATE OR REPLACE TABLE silver.order_items (
    order_item_id BIGINT NOT NULL,
    order_id BIGINT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(12,2),
    discount DECIMAL(12,2)
) USING DELTA;

INSERT INTO silver.order_items
SELECT order_item_id, order_id, product_id, quantity, unit_price, discount
FROM bronze.order_items;

CREATE OR REPLACE TABLE silver.payments (
    payment_id BIGINT NOT NULL,
    order_id BIGINT,
    method VARCHAR(16),
    amount DECIMAL(12,2),
    paid_ts TIMESTAMP_NTZ
) USING DELTA;

INSERT INTO silver.payments
SELECT payment_id, order_id, method, amount, paid_ts
FROM bronze.payments;

CREATE OR REPLACE TABLE silver.returns (
    return_id BIGINT NOT NULL,
    order_item_id BIGINT,
    quantity INT,
    reason VARCHAR(64),
    returned_ts TIMESTAMP_NTZ
) USING DELTA;

INSERT INTO silver.returns
SELECT return_id, order_item_id, quantity, reason, returned_ts
FROM bronze.returns;

CREATE OR REPLACE TABLE silver.shipments (
    shipment_id BIGINT NOT NULL,
    order_id BIGINT,
    carrier VARCHAR(16),
    ship_ts TIMESTAMP_NTZ,
    delivered_ts TIMESTAMP_NTZ
) USING DELTA;

INSERT INTO silver.shipments
SELECT shipment_id, order_id, carrier, ship_ts, delivered_ts
FROM bronze.shipments;

CREATE OR REPLACE TABLE silver.web_events (
    event_id BIGINT NOT NULL,
    customer_id BIGINT,
    event_ts TIMESTAMP_NTZ,
    event_type VARCHAR(16),
    page_url VARCHAR(256)
) USING DELTA;

INSERT INTO silver.web_events
SELECT event_id, customer_id, event_ts, event_type, page_url
FROM bronze.web_events;

CREATE OR REPLACE TABLE silver.campaign_touches (
    touch_id BIGINT NOT NULL,
    customer_id BIGINT,
    payload STRING
) USING DELTA;

SET csv_sql = concat('INSERT INTO silver.campaign_touches
SELECT touch_id, customer_id, payload
FROM read_files(
    \'', campaign_touches_csv, '\',
    format => \'csv\',
    schema => \'touch_id BIGINT, customer_id BIGINT, payload STRING\',
    header => true,
    sep => \',\',
    quote => \'"\',
    escape => \'"\',
    nullValue => r\'\\N\',
    ignoreLeadingWhiteSpace => false,
    ignoreTrailingWhiteSpace => false,
    dateFormat => \'yyyy-MM-dd\',
    timestampNTZFormat => \'yyyy-MM-dd HH:mm:ss\',
    mode => \'FAILFAST\',
    schemaEvolutionMode => \'none\'
)');
EXECUTE IMMEDIATE csv_sql;

CREATE OR REPLACE FUNCTION silver.f_clean_phone(p STRING)
RETURNS STRING
LANGUAGE SQL
DETERMINISTIC
RETURN regexp_replace(p, '[^0-9]', '');

CREATE OR REPLACE FUNCTION silver.f_fiscal_qtr(d DATE)
RETURNS STRING
LANGUAGE SQL
DETERMINISTIC
RETURN 'Q' || CAST(((((CAST(extract(MONTH FROM d) AS INT) + 9) % 12) DIV 3) + 1) AS STRING);
END;
