-- =====================================================================
-- QuickCart IQ — Export queries for Python (run each ONE AT A TIME,
-- then use the Export button on the results grid to save as CSV)
-- =====================================================================

USE quickcart;

-- EXPORT 1: product_stockout_summary.csv
SELECT
  p.product_id, p.product_name, p.category, p.is_high_demand,
  COUNT(*) AS total_demand_events,
  SUM(oi.item_status='Stockout_Removed') AS stockout_events,
  ROUND(100*SUM(oi.item_status='Stockout_Removed')/COUNT(*),2) AS stockout_rate_pct,
  ROUND(SUM(CASE WHEN oi.item_status='Fulfilled' THEN oi.quantity*oi.unit_price ELSE 0 END),2) AS actual_revenue,
  ROUND(SUM(CASE WHEN oi.item_status='Stockout_Removed' THEN oi.quantity*oi.unit_price ELSE 0 END),2) AS estimated_lost_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.is_high_demand;

-- EXPORT 2: zone_sla_summary.csv
SELECT dp.zone, dp.riders, ord.total_orders,
  ROUND(ord.total_orders/dp.riders,1) AS orders_per_rider,
  sla.sla_breach_rate_pct
FROM (SELECT zone, COUNT(*) AS riders FROM delivery_partners GROUP BY zone) dp
JOIN (SELECT zone, COUNT(*) AS total_orders FROM orders WHERE order_status='Delivered' GROUP BY zone) ord ON dp.zone=ord.zone
JOIN (
  SELECT o.zone, ROUND(100*SUM(de.sla_breached)/COUNT(*),2) AS sla_breach_rate_pct
  FROM delivery_events de JOIN orders o ON de.order_id=o.order_id GROUP BY o.zone
) sla ON dp.zone = sla.zone;

-- EXPORT 3: customer_rfm.csv
SELECT c.customer_id, c.home_zone, c.signup_date, c.bad_experience_count,
  COUNT(o.order_id) AS frequency,
  COALESCE(SUM(o.total_amount),0) AS monetary,
  DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(o.order_date)) AS recency_days
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status='Delivered'
GROUP BY c.customer_id, c.home_zone, c.signup_date, c.bad_experience_count;

-- EXPORT 4: demand_by_hour.csv
SELECT HOUR(order_datetime) AS hour_of_day, COUNT(*) AS total_orders,
  ROUND(SUM(total_amount),2) AS total_revenue
FROM orders WHERE order_status = 'Delivered'
GROUP BY hour_of_day ORDER BY hour_of_day;

-- EXPORT 5: stockout_rate_by_hour.csv
SELECT HOUR(o.order_datetime) AS hour_of_day,
  ROUND(100*SUM(oi.item_status='Stockout_Removed')/COUNT(*),2) AS stockout_rate_pct
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
GROUP BY hour_of_day ORDER BY hour_of_day;
