-- =====================================================================
-- QuickCart IQ — Data cleaning script (MySQL)
-- Run this AFTER 00_full_setup.sql has loaded all the raw data.
-- Select everything (Ctrl+A) and run it all at once (Ctrl+Enter).
-- =====================================================================

USE quickcart;

-- Workbench blocks UPDATEs that don't filter on a key column by default
-- (a beginner safety net called "Safe Update Mode"). Turn it off for this script.
SET SQL_SAFE_UPDATES = 0;

-- STEP 1: Clean customers — fix city spelling/casing, turn blank contact
-- info into a real database NULL instead of an empty text string
UPDATE customers SET city = 'Bangalore' WHERE UPPER(TRIM(city)) IN ('BANGALORE','BANGLORE','BENGALURU');
UPDATE customers SET phone = NULL WHERE phone = '';
UPDATE customers SET email = NULL WHERE email = '';

-- STEP 2: Clean products — trim stray spaces, label missing category
UPDATE products SET product_name = TRIM(product_name);
UPDATE products SET category = 'Uncategorized' WHERE category IS NULL OR category = '';

-- STEP 3: Clean inventory — a negative stock count is impossible in real life
UPDATE inventory_snapshots SET stock_available = 0 WHERE stock_available < 0;

-- STEP 4: Clean delivery_events — remove duplicate log entries, then finally
-- add the proper PRIMARY KEY we deferred back when this table was still messy
DROP TABLE IF EXISTS delivery_events_clean;
CREATE TABLE delivery_events_clean AS
SELECT order_id, partner_id, order_placed_time, store_ready_time, rider_assigned_time,
       pickup_time, delivered_time, actual_delivery_min, sla_breached
FROM (
    SELECT d.*, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_placed_time) AS rn
    FROM delivery_events d
) ranked
WHERE rn = 1;

DROP TABLE delivery_events;
RENAME TABLE delivery_events_clean TO delivery_events;
ALTER TABLE delivery_events ADD PRIMARY KEY (order_id);
ALTER TABLE delivery_events ADD FOREIGN KEY (partner_id) REFERENCES delivery_partners(partner_id);

-- STEP 5: Clean orders — remove duplicate rows, standardize the status text,
-- and finally add the proper PRIMARY KEY we deferred earlier too
DROP TABLE IF EXISTS orders_clean;
CREATE TABLE orders_clean AS
SELECT
    order_id, customer_id, store_id, order_date, order_datetime, zone,
    promised_delivery_min,
    CASE WHEN UPPER(order_status) = 'DELIVERED' THEN 'Delivered'
         WHEN UPPER(order_status) = 'CANCELLED' THEN 'Cancelled'
         ELSE order_status END AS order_status,
    total_amount, had_stockout_item
FROM (
    SELECT o.*, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_datetime) AS rn
    FROM orders o
) ranked
WHERE rn = 1;

DROP TABLE orders;
RENAME TABLE orders_clean TO orders;
ALTER TABLE orders ADD PRIMARY KEY (order_id);
ALTER TABLE orders ADD FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE orders ADD FOREIGN KEY (store_id) REFERENCES dark_stores(store_id);

-- STEP 6: Now that orders finally has a real, unique key, properly link
-- order_items and delivery_events to it (we couldn't do this before cleaning)
ALTER TABLE order_items ADD FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE delivery_events ADD FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- STEP 7: Final verification — every "should_be_zero" row below should show 0
SELECT 'orders: duplicate order_ids' AS check_item, (COUNT(*) - COUNT(DISTINCT order_id)) AS should_be_zero FROM orders
UNION ALL
SELECT 'orders: status text variants beyond 2', (COUNT(DISTINCT BINARY order_status) - 2) FROM orders
UNION ALL
SELECT 'customers: city text variants beyond 1', (SELECT COUNT(DISTINCT BINARY city) - 1 FROM customers)
UNION ALL
SELECT 'inventory: negative stock rows', (SELECT COUNT(*) FROM inventory_snapshots WHERE stock_available < 0)
UNION ALL
SELECT 'delivery_events: duplicate order_ids', (SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM delivery_events)
UNION ALL
SELECT 'orders: final row count (informational)', (SELECT COUNT(*) FROM orders)
UNION ALL
SELECT 'delivery_events: final row count (informational)', (SELECT COUNT(*) FROM delivery_events);
