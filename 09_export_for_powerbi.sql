-- =====================================================================
-- QuickCart IQ — Export ALL 8 clean tables for Power BI
-- Run each SELECT ONE AT A TIME, then click the Export button
-- (same method you used for the Python CSVs — much faster than the wizard)
-- IMPORTANT: set "Limit to 1000 rows" dropdown to "Don't Limit" first!
-- =====================================================================

USE quickcart;

-- 1. customers.csv (already done via wizard — skip unless you want to redo it)
-- NOTE: use this version instead if you already loaded the old one with "NULL" text in it
SELECT customer_id, customer_name, COALESCE(phone,'') AS phone, COALESCE(email,'') AS email,
       city, home_zone, signup_date, bad_experience_count
FROM customers;

-- 2. dark_stores.csv
SELECT * FROM dark_stores;

-- 3. products.csv
SELECT * FROM products;

-- 4. delivery_partners.csv
SELECT * FROM delivery_partners;

-- 5. orders.csv (fixed: store_id NULLs become blank, not the word "NULL")
SELECT order_id, customer_id, COALESCE(store_id,'') AS store_id, order_date, order_datetime,
       zone, promised_delivery_min, order_status, total_amount, had_stockout_item
FROM orders;

-- 6. order_items.csv
SELECT * FROM order_items;

-- 7. delivery_events.csv (fixed: partner_id NULLs become blank, not the word "NULL")
SELECT order_id, COALESCE(partner_id,'') AS partner_id, order_placed_time, store_ready_time,
       rider_assigned_time, pickup_time, delivered_time, actual_delivery_min, sla_breached
FROM delivery_events;

-- 8. inventory_snapshots.csv
SELECT * FROM inventory_snapshots;
