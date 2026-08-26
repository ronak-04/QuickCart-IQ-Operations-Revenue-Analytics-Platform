-- =====================================================================
-- QuickCart IQ — Business Question Queries, Part 2: Stockout & Lost Revenue
-- =====================================================================

USE quickcart;

-- One-time fix: a few product categories loaded as empty string, not NULL
SET SQL_SAFE_UPDATES = 0;
UPDATE products SET category = 'Uncategorized' WHERE category IS NULL OR category = '';

-- Q1: Overall stockout rate
SELECT
  ROUND(100 * SUM(item_status='Stockout_Removed') / COUNT(*), 2) AS pct_items_stockout,
  SUM(item_status='Stockout_Removed') AS total_stockout_events
FROM order_items;

-- Q2: Stockout rate by hour of day
SELECT HOUR(o.order_datetime) AS hour_of_day,
  ROUND(100*SUM(oi.item_status='Stockout_Removed')/COUNT(*),2) AS stockout_rate_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
GROUP BY hour_of_day ORDER BY hour_of_day;

-- Q3: Total estimated lost revenue
SELECT ROUND(SUM(quantity * unit_price),2) AS estimated_lost_revenue
FROM order_items WHERE item_status = 'Stockout_Removed';

-- Q4: Priority replenishment list — worst offenders first
SELECT
  p.product_name, p.category,
  COUNT(*) AS total_demand_events,
  SUM(oi.item_status='Stockout_Removed') AS stockout_events,
  ROUND(100*SUM(oi.item_status='Stockout_Removed')/COUNT(*),2) AS stockout_rate_pct,
  ROUND(SUM(CASE WHEN oi.item_status='Stockout_Removed' THEN oi.quantity*oi.unit_price ELSE 0 END),2) AS estimated_lost_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY estimated_lost_revenue DESC
LIMIT 15;
