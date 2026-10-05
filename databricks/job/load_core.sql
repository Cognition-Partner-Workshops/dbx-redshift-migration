-- Databricks notebook source
-- GENERATED from databricks/foundation/etl.sql by tools/sync_job_sql.py — edit the source, then
-- regenerate. The job binds the :catalog widget via base_parameters.
USE CATALOG IDENTIFIER(:catalog);

-- COMMAND ----------

-- foundation: seed CSV -> bronze (as-is) -> silver (typed, clustered) + UDFs.
-- Runs as one SQL scripting block under the caller's catalog.
BEGIN
DECLARE raw_dir STRING DEFAULT concat('/Volumes/', current_catalog(), '/bronze/raw/');

SELECT assert_true(current_catalog() IN ('mig_redshift_dev', 'mig_redshift'), 'Foundation requires an allowed migration catalog');

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.customers AS
SELECT customer_id, email, first_name, last_name, phone, region, preferred_store_id, signup_date, is_business
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'customer_id BIGINT, email STRING, first_name STRING, last_name STRING, phone STRING, region STRING, preferred_store_id INT, signup_date DATE, is_business BOOLEAN')"
USING (raw_dir || 'customers.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.stores AS
SELECT store_id, region, store_name, city, state
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'store_id INT, region STRING, store_name STRING, city STRING, state STRING')"
USING (raw_dir || 'stores.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.products AS
SELECT product_id, sku, product_name, category, subcategory, unit_price, cost, active
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'product_id INT, sku STRING, product_name STRING, category STRING, subcategory STRING, unit_price DECIMAL(12,2), cost DECIMAL(12,2), active BOOLEAN')"
USING (raw_dir || 'products.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.orders AS
SELECT order_id, customer_id, store_id, order_ts, sales_channel, status
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'order_id BIGINT, customer_id BIGINT, store_id INT, order_ts TIMESTAMP_NTZ, sales_channel STRING, status STRING')"
USING (raw_dir || 'orders.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.order_items AS
SELECT order_item_id, order_id, product_id, quantity, unit_price, discount
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'order_item_id BIGINT, order_id BIGINT, product_id INT, quantity INT, unit_price DECIMAL(12,2), discount DECIMAL(12,2)')"
USING (raw_dir || 'order_items.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.payments AS
SELECT payment_id, order_id, method, amount, paid_ts
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'payment_id BIGINT, order_id BIGINT, method STRING, amount DECIMAL(12,2), paid_ts TIMESTAMP_NTZ')"
USING (raw_dir || 'payments.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.returns AS
SELECT return_id, order_item_id, quantity, reason, returned_ts
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'return_id BIGINT, order_item_id BIGINT, quantity INT, reason STRING, returned_ts TIMESTAMP_NTZ')"
USING (raw_dir || 'returns.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.shipments AS
SELECT shipment_id, order_id, carrier, ship_ts, delivered_ts
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'shipment_id BIGINT, order_id BIGINT, carrier STRING, ship_ts TIMESTAMP_NTZ, delivered_ts TIMESTAMP_NTZ')"
USING (raw_dir || 'shipments.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.web_events AS
SELECT event_id, customer_id, event_ts, event_type, page_url
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'event_id BIGINT, customer_id BIGINT, event_ts TIMESTAMP_NTZ, event_type STRING, page_url STRING')"
USING (raw_dir || 'web_events.csv') AS path;

EXECUTE IMMEDIATE "CREATE OR REPLACE TABLE bronze.campaign_touches AS
SELECT touch_id, customer_id, payload
FROM read_files(:path, format => 'csv', header => true, sep => ',', quote => '\"', escape => '\"',
  nullValue => r'\\N', ignoreLeadingWhiteSpace => false, ignoreTrailingWhiteSpace => false,
  dateFormat => 'yyyy-MM-dd', timestampNTZFormat => 'yyyy-MM-dd HH:mm:ss',
  mode => 'FAILFAST', schemaEvolutionMode => 'none',
  schema => 'touch_id BIGINT, customer_id BIGINT, payload STRING')"
USING (raw_dir || 'campaign_touches.csv') AS path;

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
) USING DELTA
CLUSTER BY (customer_id);

INSERT INTO silver.customers
SELECT customer_id, email, first_name, last_name, phone, rpad(region, 4, ' '),
       preferred_store_id, signup_date, is_business
FROM bronze.customers;

CREATE OR REPLACE TABLE silver.stores (
    store_id INT NOT NULL,
    region CHAR(4),
    store_name VARCHAR(64),
    city VARCHAR(64),
    state VARCHAR(2)
) USING DELTA
CLUSTER BY (store_id);

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
) USING DELTA
CLUSTER BY (product_id);

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
) USING DELTA
CLUSTER BY (customer_id, order_ts);

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
) USING DELTA
CLUSTER BY (order_id);

INSERT INTO silver.order_items
SELECT order_item_id, order_id, product_id, quantity, unit_price, discount
FROM bronze.order_items;

CREATE OR REPLACE TABLE silver.payments (
    payment_id BIGINT NOT NULL,
    order_id BIGINT,
    method VARCHAR(16),
    amount DECIMAL(12,2),
    paid_ts TIMESTAMP_NTZ
) USING DELTA
CLUSTER BY (order_id);

INSERT INTO silver.payments
SELECT payment_id, order_id, method, amount, paid_ts
FROM bronze.payments;

CREATE OR REPLACE TABLE silver.returns (
    return_id BIGINT NOT NULL,
    order_item_id BIGINT,
    quantity INT,
    reason VARCHAR(64),
    returned_ts TIMESTAMP_NTZ
) USING DELTA
CLUSTER BY (order_item_id, returned_ts);

INSERT INTO silver.returns
SELECT return_id, order_item_id, quantity, reason, returned_ts
FROM bronze.returns;

CREATE OR REPLACE TABLE silver.shipments (
    shipment_id BIGINT NOT NULL,
    order_id BIGINT,
    carrier VARCHAR(16),
    ship_ts TIMESTAMP_NTZ,
    delivered_ts TIMESTAMP_NTZ
) USING DELTA
CLUSTER BY (order_id, ship_ts);

INSERT INTO silver.shipments
SELECT shipment_id, order_id, carrier, ship_ts, delivered_ts
FROM bronze.shipments;

CREATE OR REPLACE TABLE silver.web_events (
    event_id BIGINT NOT NULL,
    customer_id BIGINT,
    event_ts TIMESTAMP_NTZ,
    event_type VARCHAR(16),
    page_url VARCHAR(256)
) USING DELTA
CLUSTER BY (customer_id, event_ts);

INSERT INTO silver.web_events
SELECT event_id, customer_id, event_ts, event_type, page_url
FROM bronze.web_events;

CREATE OR REPLACE TABLE silver.campaign_touches (
    touch_id BIGINT NOT NULL,
    customer_id BIGINT,
    payload STRING
) USING DELTA
CLUSTER BY (customer_id, touch_id);

INSERT INTO silver.campaign_touches
SELECT touch_id, customer_id, payload
FROM bronze.campaign_touches;

-- Strip a phone string down to its digits.
CREATE OR REPLACE FUNCTION silver.f_clean_phone(p STRING) RETURNS STRING LANGUAGE SQL DETERMINISTIC
RETURN regexp_replace(p, '[^0-9]', '');

-- Fiscal year starts Feb 1: Feb-Apr = Q1, May-Jul = Q2, Aug-Oct = Q3, Nov-Jan = Q4.
CREATE OR REPLACE FUNCTION silver.f_fiscal_qtr(d DATE) RETURNS STRING LANGUAGE SQL DETERMINISTIC
RETURN concat('Q', CAST((((month(d) + 9) % 12) DIV 3) + 1 AS STRING));
END;
