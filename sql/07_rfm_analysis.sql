-- =====================================================================
-- QuickCart IQ — Business Question Queries, Part 4: Customer Retention (RFM)
-- =====================================================================

USE quickcart;

-- Q1: Customer segments based on Recency & Frequency
SELECT
  CASE
    WHEN frequency = 0 THEN 'Inactive / Never Ordered'
    WHEN recency_days >= 10 THEN 'At-Risk (going quiet)'
    WHEN frequency >= 60 THEN 'Loyal'
    WHEN frequency >= 15 THEN 'Repeat'
    ELSE 'New'
  END AS segment,
  COUNT(*) AS num_customers,
  ROUND(AVG(frequency),1) AS avg_orders,
  ROUND(AVG(monetary),0) AS avg_spend
FROM (
  SELECT c.customer_id,
    COUNT(o.order_id) AS frequency,
    COALESCE(SUM(o.total_amount),0) AS monetary,
    DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(o.order_date)) AS recency_days
  FROM customers c
  LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'Delivered'
  GROUP BY c.customer_id
) rfm
GROUP BY segment
ORDER BY num_customers DESC;

-- Q2: THE key insight — bad-experience RATE (not raw count) vs. recency
-- NTILE(4) splits customers into 4 equal-sized groups by their bad-experience rate
SELECT
  bad_rate_bucket,
  COUNT(*) AS num_customers,
  ROUND(AVG(recency_days),2) AS avg_recency_days
FROM (
  SELECT c.customer_id,
    c.bad_experience_count / NULLIF(COUNT(o.order_id),0) AS bad_rate,
    DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(o.order_date)) AS recency_days,
    NTILE(4) OVER (ORDER BY c.bad_experience_count / NULLIF(COUNT(o.order_id),0)) AS bad_rate_bucket
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'Delivered'
  GROUP BY c.customer_id, c.bad_experience_count
) x
GROUP BY bad_rate_bucket
ORDER BY bad_rate_bucket;
