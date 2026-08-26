-- =====================================================================
-- QuickCart IQ — Business Question Queries, Part 3: Delivery & SLA
-- =====================================================================

USE quickcart;

-- Q1: Overall SLA breach rate
SELECT ROUND(100*SUM(sla_breached)/COUNT(*),2) AS sla_breach_rate_pct, COUNT(*) AS total_deliveries
FROM delivery_events;

-- Q2: SLA breach rate by zone
SELECT o.zone,
  COUNT(*) AS total_deliveries,
  ROUND(100*SUM(de.sla_breached)/COUNT(*),2) AS sla_breach_rate_pct,
  ROUND(AVG(de.actual_delivery_min),1) AS avg_delivery_min
FROM delivery_events de
JOIN orders o ON de.order_id = o.order_id
GROUP BY o.zone ORDER BY sla_breach_rate_pct DESC;

-- Q3: Peak vs off-peak, by zone
SELECT o.zone,
  CASE WHEN HOUR(o.order_datetime) IN (19,20) THEN 'Peak (7-9PM)' ELSE 'Off-Peak' END AS time_period,
  COUNT(*) AS total_deliveries,
  ROUND(100*SUM(de.sla_breached)/COUNT(*),2) AS sla_breach_rate_pct
FROM delivery_events de
JOIN orders o ON de.order_id = o.order_id
GROUP BY o.zone, time_period ORDER BY o.zone, time_period;

-- Q4: Rider capacity strain by zone (the root cause)
SELECT dp.zone, dp.riders, ord.total_orders, ROUND(ord.total_orders/dp.riders,1) AS orders_per_rider
FROM (SELECT zone, COUNT(*) AS riders FROM delivery_partners GROUP BY zone) dp
JOIN (SELECT zone, COUNT(*) AS total_orders FROM orders WHERE order_status='Delivered' GROUP BY zone) ord
ON dp.zone = ord.zone
ORDER BY orders_per_rider DESC;
