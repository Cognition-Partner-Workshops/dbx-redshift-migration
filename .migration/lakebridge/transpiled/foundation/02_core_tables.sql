-- core.* landing tables: append-only raw extract, Redshift-flavored DDL.
CREATE
    /* DISTKEY(customer_id) SORTKEY(customer_id) */
    TABLE core.customers
    (
        customer_id BIGINT NOT NULL,
        email STRING /** ENCODE lzo **/,
        first_name STRING,
        last_name STRING,
        phone STRING,
        region CHAR(4) /** ENCODE lzo **/,
        preferred_store_id INT,
        signup_date DATE,
        is_business BOOLEAN
    );

CREATE
    /* DISTSTYLE ALL
SORTKEY(store_id) */
    TABLE core.stores
    (store_id INT NOT NULL, region CHAR(4) /** ENCODE lzo **/, store_name STRING, city STRING, state STRING);

CREATE
    /* DISTSTYLE ALL
SORTKEY(product_id) */
    TABLE core.products
    (
        product_id INT NOT NULL,
        sku STRING,
        product_name STRING,
        category STRING /** ENCODE lzo **/,
        subcategory STRING,
        unit_price DECIMAL(12, 2),
        cost DECIMAL(12, 2),
        active BOOLEAN
    );

CREATE
    /* DISTKEY(customer_id) SORTKEY(order_ts) */
    TABLE core.orders
    (
        order_id BIGINT NOT NULL,
        customer_id BIGINT,
        store_id INT,
        order_ts TIMESTAMP /** ENCODE lzo **/,
        sales_channel STRING /** ENCODE lzo **/,
        status STRING
    );

CREATE
    /* DISTKEY(order_id) SORTKEY(order_id) */
    TABLE core.order_items
    (
        order_item_id BIGINT NOT NULL,
        order_id BIGINT,
        product_id INT,
        quantity INT,
        unit_price DECIMAL(12, 2),
        discount DECIMAL(12, 2)
    );

CREATE
    /* DISTKEY(order_id) SORTKEY(order_id) */
    TABLE core.payments
    (payment_id BIGINT NOT NULL, order_id BIGINT, method STRING, amount DECIMAL(12, 2), paid_ts TIMESTAMP);

CREATE
    /* DISTKEY(order_item_id) SORTKEY(returned_ts) */
    TABLE core.returns
    (return_id BIGINT NOT NULL, order_item_id BIGINT, quantity INT, reason STRING, returned_ts TIMESTAMP);

CREATE
    /* DISTKEY(order_id) SORTKEY(ship_ts) */
    TABLE core.shipments
    (
        shipment_id BIGINT NOT NULL,
        order_id BIGINT,
        carrier STRING /** ENCODE lzo **/,
        ship_ts TIMESTAMP,
        delivered_ts TIMESTAMP
    );

CREATE
    /* DISTKEY(customer_id) SORTKEY(event_ts) */
    TABLE core.web_events
    (
        event_id BIGINT NOT NULL,
        customer_id BIGINT,
        event_ts TIMESTAMP,
        event_type STRING /** ENCODE lzo **/,
        page_url STRING
    );

CREATE
    /* DISTKEY(customer_id) SORTKEY(touch_id) */
    TABLE core.campaign_touches (touch_id BIGINT NOT NULL, customer_id BIGINT, payload VARIANT);