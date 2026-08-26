-- =====================================================================
-- QuickCart IQ — Complete setup script (MySQL)
-- Just select ALL of this (Ctrl+A) and run it (Ctrl+Enter) in one go.
-- Your file path is already filled in: C:/Users/User/Desktop/quickcart_dataset/
-- =====================================================================

SET GLOBAL local_infile = 1;

DROP DATABASE IF EXISTS quickcart;
CREATE DATABASE quickcart;
USE quickcart;

-- ---------- MASTER DATA TABLES ----------

CREATE TABLE customers (
    customer_id            VARCHAR(10) PRIMARY KEY,
    customer_name           VARCHAR(100),
    phone                    VARCHAR(15),
    email                    VARCHAR(100),
    city                     VARCHAR(50),
    home_zone                VARCHAR(50),
    signup_date              DATE,
    bad_experience_count     INT
);

CREATE TABLE dark_stores (
    store_id      VARCHAR(10) PRIMARY KEY,
    store_name     VARCHAR(100),
    zone            VARCHAR(50),
    city            VARCHAR(50)
);

CREATE TABLE products (
    product_id       VARCHAR(10) PRIMARY KEY,
    product_name      VARCHAR(100),
    category           VARCHAR(50),
    unit_price          DECIMAL(10,2),
    is_high_demand      BOOLEAN
);

CREATE TABLE delivery_partners (
    partner_id      VARCHAR(10) PRIMARY KEY,
    partner_name     VARCHAR(100),
    zone              VARCHAR(50),
    join_date          DATE
);

-- ---------- RAW TRANSACTION TABLES ----------

CREATE TABLE orders (
    order_id                  VARCHAR(10),
    customer_id                VARCHAR(10),
    store_id                    VARCHAR(10),
    order_date                   DATE,
    order_datetime                 DATETIME,
    zone                             VARCHAR(50),
    promised_delivery_min             INT,
    order_status                       VARCHAR(20),
    total_amount                         DECIMAL(10,2),
    had_stockout_item                      BOOLEAN,
    INDEX idx_order_id (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES dark_stores(store_id)
);

CREATE TABLE order_items (
    order_id       VARCHAR(10),
    product_id      VARCHAR(10),
    quantity          INT,
    unit_price          DECIMAL(10,2),
    item_status           VARCHAR(20),
    INDEX idx_order_id (order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE delivery_events (
    order_id                VARCHAR(10),
    partner_id                VARCHAR(10),
    order_placed_time           DATETIME,
    store_ready_time              DATETIME,
    rider_assigned_time             DATETIME,
    pickup_time                       DATETIME,
    delivered_time                      DATETIME,
    actual_delivery_min                   DECIMAL(6,1),
    sla_breached                            BOOLEAN,
    INDEX idx_order_id (order_id),
    FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id)
);

CREATE TABLE inventory_snapshots (
    snapshot_date     DATE,
    store_id            VARCHAR(10),
    product_id             VARCHAR(10),
    stock_available           INT,
    FOREIGN KEY (store_id) REFERENCES dark_stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ---------- LOAD ALL DATA ----------

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartcustomers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartdark_stores.csv'
INTO TABLE dark_stores
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartproducts.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, category, unit_price, @is_high_demand)
SET is_high_demand = IF(@is_high_demand = 'True', 1, 0);

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartdelivery_partners.csv'
INTO TABLE delivery_partners
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartorders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, @store_id, order_date, order_datetime, zone,
 promised_delivery_min, order_status, total_amount, @had_stockout_item)
SET store_id = NULLIF(@store_id, ''),
    had_stockout_item = IF(@had_stockout_item = 'True', 1, 0);

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartorder_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartdelivery_events.csv'
INTO TABLE delivery_events
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, @partner_id, order_placed_time, store_ready_time, rider_assigned_time,
 pickup_time, delivered_time, actual_delivery_min, @sla_breached)
SET partner_id = NULLIF(@partner_id, ''),
    sla_breached = IF(@sla_breached = 'True', 1, 0);

LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/quickcart_dataset/QuickCartinventory_snapshots.csv'
INTO TABLE inventory_snapshots
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ---------- FINAL CHECK ----------
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'dark_stores', COUNT(*) FROM dark_stores
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'delivery_partners', COUNT(*) FROM delivery_partners
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'delivery_events', COUNT(*) FROM delivery_events
UNION ALL SELECT 'inventory_snapshots', COUNT(*) FROM inventory_snapshots;
