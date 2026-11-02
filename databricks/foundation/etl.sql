-- foundation: bronze (seed CSVs from /Volumes/<catalog>/bronze/raw, loaded
-- as-is as strings) -> typed silver tables mirroring Redshift core.*.
-- DISTKEY/SORTKEY/DISTSTYLE/ENCODE dropped; liquid clustering on the old
-- sort/dist keys instead. Seed NULLs are the literal \N. CHAR(4) is
-- stored blank-padded (rpad) so values match Redshift CHAR semantics.
BEGIN
  DECLARE raw_path STRING DEFAULT '/Volumes/' || current_catalog() || '/bronze/raw/';
  DECLARE stmt STRING;
  FOR t AS SELECT explode(array('customers', 'stores', 'products', 'orders', 'order_items',
                                'payments', 'returns', 'shipments', 'web_events',
                                'campaign_touches')) AS name DO
    SET stmt = 'CREATE OR REPLACE TABLE bronze.' || t.name || ' AS SELECT * FROM read_files(\''
               || raw_path || t.name || '.csv\', format => \'csv\', header => true, '
               || 'inferSchema => false, escape => \'"\')';
    EXECUTE IMMEDIATE stmt;
  END FOR;
END;

CREATE OR REPLACE TABLE silver.customers (
    customer_id         BIGINT NOT NULL,
    email               VARCHAR(320),
    first_name          VARCHAR(64),
    last_name           VARCHAR(64),
    phone               VARCHAR(32),
    region              CHAR(4),
    preferred_store_id  INT,
    signup_date         DATE,
    is_business         BOOLEAN
) CLUSTER BY (customer_id);
INSERT INTO silver.customers
SELECT CAST(customer_id AS BIGINT), NULLIF(email, '\\N'), NULLIF(first_name, '\\N'),
       NULLIF(last_name, '\\N'), NULLIF(phone, '\\N'), rpad(NULLIF(region, '\\N'), 4, ' '),
       CAST(NULLIF(preferred_store_id, '\\N') AS INT), CAST(NULLIF(signup_date, '\\N') AS DATE),
       CAST(NULLIF(is_business, '\\N') AS BOOLEAN)
FROM bronze.customers;

CREATE OR REPLACE TABLE silver.stores (
    store_id    INT NOT NULL,
    region      CHAR(4),
    store_name  VARCHAR(64),
    city        VARCHAR(64),
    state       VARCHAR(2)
) CLUSTER BY (store_id);
INSERT INTO silver.stores
SELECT CAST(store_id AS INT), rpad(NULLIF(region, '\\N'), 4, ' '), NULLIF(store_name, '\\N'),
       NULLIF(city, '\\N'), NULLIF(state, '\\N')
FROM bronze.stores;

CREATE OR REPLACE TABLE silver.products (
    product_id      INT NOT NULL,
    sku             VARCHAR(16),
    product_name    VARCHAR(128),
    category        VARCHAR(32),
    subcategory     VARCHAR(32),
    unit_price      DECIMAL(12,2),
    cost            DECIMAL(12,2),
    active          BOOLEAN
) CLUSTER BY (product_id);
INSERT INTO silver.products
SELECT CAST(product_id AS INT), NULLIF(sku, '\\N'), NULLIF(product_name, '\\N'),
       NULLIF(category, '\\N'), NULLIF(subcategory, '\\N'),
       CAST(NULLIF(unit_price, '\\N') AS DECIMAL(12,2)), CAST(NULLIF(cost, '\\N') AS DECIMAL(12,2)),
       CAST(NULLIF(active, '\\N') AS BOOLEAN)
FROM bronze.products;

CREATE OR REPLACE TABLE silver.orders (
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT,
    store_id        INT,
    order_ts        TIMESTAMP_NTZ,
    sales_channel   VARCHAR(16),
    status          VARCHAR(16)
) CLUSTER BY (order_ts);
INSERT INTO silver.orders
SELECT CAST(order_id AS BIGINT), CAST(NULLIF(customer_id, '\\N') AS BIGINT),
       CAST(NULLIF(store_id, '\\N') AS INT), CAST(NULLIF(order_ts, '\\N') AS TIMESTAMP_NTZ),
       NULLIF(sales_channel, '\\N'), NULLIF(status, '\\N')
FROM bronze.orders;

CREATE OR REPLACE TABLE silver.order_items (
    order_item_id   BIGINT NOT NULL,
    order_id        BIGINT,
    product_id      INT,
    quantity        INT,
    unit_price      DECIMAL(12,2),
    discount        DECIMAL(12,2)
) CLUSTER BY (order_id);
INSERT INTO silver.order_items
SELECT CAST(order_item_id AS BIGINT), CAST(NULLIF(order_id, '\\N') AS BIGINT),
       CAST(NULLIF(product_id, '\\N') AS INT), CAST(NULLIF(quantity, '\\N') AS INT),
       CAST(NULLIF(unit_price, '\\N') AS DECIMAL(12,2)), CAST(NULLIF(discount, '\\N') AS DECIMAL(12,2))
FROM bronze.order_items;

CREATE OR REPLACE TABLE silver.payments (
    payment_id  BIGINT NOT NULL,
    order_id    BIGINT,
    method      VARCHAR(16),
    amount      DECIMAL(12,2),
    paid_ts     TIMESTAMP_NTZ
) CLUSTER BY (order_id);
INSERT INTO silver.payments
SELECT CAST(payment_id AS BIGINT), CAST(NULLIF(order_id, '\\N') AS BIGINT), NULLIF(method, '\\N'),
       CAST(NULLIF(amount, '\\N') AS DECIMAL(12,2)), CAST(NULLIF(paid_ts, '\\N') AS TIMESTAMP_NTZ)
FROM bronze.payments;

CREATE OR REPLACE TABLE silver.returns (
    return_id       BIGINT NOT NULL,
    order_item_id   BIGINT,
    quantity        INT,
    reason          VARCHAR(64),
    returned_ts     TIMESTAMP_NTZ
) CLUSTER BY (returned_ts);
INSERT INTO silver.returns
SELECT CAST(return_id AS BIGINT), CAST(NULLIF(order_item_id, '\\N') AS BIGINT),
       CAST(NULLIF(quantity, '\\N') AS INT), NULLIF(reason, '\\N'),
       CAST(NULLIF(returned_ts, '\\N') AS TIMESTAMP_NTZ)
FROM bronze.returns;

CREATE OR REPLACE TABLE silver.shipments (
    shipment_id     BIGINT NOT NULL,
    order_id        BIGINT,
    carrier         VARCHAR(16),
    ship_ts         TIMESTAMP_NTZ,
    delivered_ts    TIMESTAMP_NTZ
) CLUSTER BY (ship_ts);
INSERT INTO silver.shipments
SELECT CAST(shipment_id AS BIGINT), CAST(NULLIF(order_id, '\\N') AS BIGINT), NULLIF(carrier, '\\N'),
       CAST(NULLIF(ship_ts, '\\N') AS TIMESTAMP_NTZ), CAST(NULLIF(delivered_ts, '\\N') AS TIMESTAMP_NTZ)
FROM bronze.shipments;

CREATE OR REPLACE TABLE silver.web_events (
    event_id     BIGINT NOT NULL,
    customer_id  BIGINT,
    event_ts     TIMESTAMP_NTZ,
    event_type   VARCHAR(16),
    page_url     VARCHAR(256)
) CLUSTER BY (customer_id, event_ts);
INSERT INTO silver.web_events
SELECT CAST(event_id AS BIGINT), CAST(NULLIF(customer_id, '\\N') AS BIGINT),
       CAST(NULLIF(event_ts, '\\N') AS TIMESTAMP_NTZ), NULLIF(event_type, '\\N'), NULLIF(page_url, '\\N')
FROM bronze.web_events;

-- SUPER payload kept as its JSON text; units parse it with parse_json (VARIANT).
CREATE OR REPLACE TABLE silver.campaign_touches (
    touch_id     BIGINT NOT NULL,
    customer_id  BIGINT,
    payload      STRING
) CLUSTER BY (touch_id);
INSERT INTO silver.campaign_touches
SELECT CAST(touch_id AS BIGINT), CAST(NULLIF(customer_id, '\\N') AS BIGINT), NULLIF(payload, '\\N')
FROM bronze.campaign_touches;

-- Redshift SQL UDFs -> Unity Catalog SQL UDFs.
-- Fiscal year starts Feb 1: Feb-Apr = Q1, May-Jul = Q2, Aug-Oct = Q3, Nov-Jan = Q4.
CREATE OR REPLACE FUNCTION silver.f_fiscal_qtr(d DATE)
RETURNS STRING
DETERMINISTIC
RETURN 'Q' || CAST((((month(d) + 9) % 12) DIV 3) + 1 AS STRING);

CREATE OR REPLACE FUNCTION silver.f_clean_phone(p STRING)
RETURNS STRING
DETERMINISTIC
RETURN regexp_replace(p, '[^0-9]', '');
