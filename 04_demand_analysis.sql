-- =====================================================================
-- QuickCart IQ — Business Question Queries, Part 1: Demand & Sales
-- =====================================================================

USE quickcart;

-- Q1: Which zone generates the most revenue?
SELECT zone, COUNT(*) AS total_orders, ROUND(SUM(total_amount),2) AS total_revenue,
       ROUND(AVG(total_amount),2) AS avg_order_value
FROM orders WHERE order_status = 'Delivered'
GROUP BY zone ORDER BY total_revenue DESC;

-- Q2: What time of day do people order the most?
SELECT HOUR(order_datetime) AS hour_of_day, COUNT(*) AS total_orders
FROM orders WHERE order_status = 'Delivered'
GROUP BY hour_of_day ORDER BY hour_of_day;

-- Q3: Weekday vs weekend ordering patterns
SELECT
  CASE WHEN DAYOFWEEK(order_date) IN (1,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
  COUNT(*) AS total_orders, ROUND(AVG(total_amount),2) AS avg_order_value
FROM orders WHERE order_status = 'Delivered'
GROUP BY day_type;

-- Q4: Top 10 products by revenue
SELECT p.product_name, p.category, SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * oi.unit_price),2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE oi.item_status = 'Fulfilled' AND o.order_status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC LIMIT 10;
