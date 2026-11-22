USE zomato_analytics;

CREATE OR REPLACE VIEW v_order_metrics AS
SELECT o.*, r.city AS restaurant_city, r.cuisine,
       o.order_amount - o.discount_amount + o.delivery_fee AS net_order_value,
       CASE WHEN o.discount_amount > 0 THEN 1 ELSE 0 END AS discounted
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id;

CREATE OR REPLACE VIEW v_customer_activity AS
SELECT c.customer_id, c.city, c.acquisition_channel,
       COUNT(*) AS delivered_orders, SUM(o.net_order_value) AS delivered_value,
       MAX(o.order_timestamp) AS last_delivered_date
FROM customers c
JOIN v_order_metrics o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.city, c.acquisition_channel;

CREATE OR REPLACE VIEW v_customer_churn AS
SELECT a.*, d.as_of_date,
       DATEDIFF(d.as_of_date, a.last_delivered_date) AS days_inactive,
       CASE WHEN DATEDIFF(d.as_of_date, a.last_delivered_date) >= 90 THEN 1 ELSE 0 END AS churned
FROM v_customer_activity a
CROSS JOIN (SELECT MAX(order_timestamp) AS as_of_date FROM orders) d;

CREATE OR REPLACE VIEW v_restaurant_performance AS
SELECT r.restaurant_id, r.restaurant_name, r.city, r.avg_rating,
       COUNT(o.order_id) AS order_count,
       SUM(CASE WHEN o.order_status = 'Delivered' THEN o.net_order_value ELSE 0 END) AS delivered_value,
       SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders
FROM restaurants r
LEFT JOIN v_order_metrics o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_name, r.city, r.avg_rating;

-- Revenue
-- R1. Total delivered order value
SELECT SUM(net_order_value) AS total_revenue
FROM v_order_metrics WHERE order_status = 'Delivered';

-- R2. Monthly revenue
SELECT SUBSTRING(order_timestamp, 1, 7) AS order_month,
       SUM(CASE WHEN order_status = 'Delivered' THEN net_order_value ELSE 0 END) AS revenue
FROM v_order_metrics GROUP BY order_month ORDER BY order_month;

-- R3. Revenue by restaurant city
SELECT restaurant_city, SUM(net_order_value) AS revenue
FROM v_order_metrics WHERE order_status = 'Delivered'
GROUP BY restaurant_city ORDER BY revenue DESC, restaurant_city;

-- R4. Revenue by payment mode
SELECT payment_mode, SUM(net_order_value) AS revenue
FROM v_order_metrics WHERE order_status = 'Delivered'
GROUP BY payment_mode ORDER BY revenue DESC, payment_mode;

-- R5. Average order value
SELECT ROUND(AVG(net_order_value), 2) AS average_order_value
FROM v_order_metrics WHERE order_status = 'Delivered';

-- Customers
-- C1. Top 20 customers by revenue
SELECT customer_id, city, delivered_orders, delivered_value
FROM v_customer_activity ORDER BY delivered_value DESC, customer_id LIMIT 20;

-- C2. Top 20 share of overall delivered value
WITH top_customers AS (
    SELECT delivered_value FROM v_customer_activity
    ORDER BY delivered_value DESC, customer_id LIMIT 20
)
SELECT ROUND(100.0 * SUM(delivered_value) / NULLIF((
    SELECT SUM(net_order_value) FROM v_order_metrics WHERE order_status = 'Delivered'
), 0), 2) AS top_20_revenue_share_pct
FROM top_customers;

-- C3. Acquisition channel value per purchasing customer
SELECT acquisition_channel, COUNT(*) AS purchasing_customers,
       SUM(delivered_value) AS total_revenue,
       ROUND(AVG(delivered_value), 2) AS revenue_per_customer
FROM v_customer_activity
GROUP BY acquisition_channel ORDER BY revenue_per_customer DESC, acquisition_channel;

-- C4. Repeat customers
SELECT COUNT(*) AS repeat_customers FROM v_customer_activity WHERE delivered_orders >= 2;

-- Restaurants
-- P1. Highest restaurant revenue
SELECT restaurant_id, restaurant_name, city, delivered_value
FROM v_restaurant_performance ORDER BY delivered_value DESC, restaurant_id LIMIT 10;

-- P2. Restaurants with the most recorded orders
SELECT restaurant_id, restaurant_name, city, order_count
FROM v_restaurant_performance ORDER BY order_count DESC, restaurant_id LIMIT 10;

-- P3. Cuisine popularity by recorded orders
SELECT cuisine, COUNT(*) AS order_count FROM v_order_metrics
GROUP BY cuisine ORDER BY order_count DESC, cuisine;

-- P4. Average revenue per restaurant by rating band
SELECT CASE WHEN avg_rating >= 4 THEN '4.0 and above' ELSE 'Below 4.0' END AS rating_band,
       COUNT(*) AS restaurants, ROUND(AVG(delivered_value), 2) AS revenue_per_restaurant
FROM v_restaurant_performance GROUP BY rating_band ORDER BY rating_band;

-- P5. Bottom five by delivered revenue
SELECT restaurant_id, restaurant_name, city, delivered_value
FROM v_restaurant_performance ORDER BY delivered_value, restaurant_id LIMIT 5;

-- Coupons (positive discount proxy)
-- D1. Discounted share of all recorded orders
SELECT SUM(discounted) AS discounted_orders, COUNT(*) AS total_orders,
       ROUND(100.0 * AVG(discounted), 2) AS discounted_order_pct
FROM v_order_metrics;

-- D2. Average historical spend for customers with and without a discounted delivery
WITH customer_discount AS (
    SELECT c.customer_id, MAX(o.discounted) AS used_discount
    FROM customers c JOIN v_order_metrics o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'Delivered' GROUP BY c.customer_id
)
SELECT d.used_discount, COUNT(*) AS purchasing_customers,
       ROUND(AVG(a.delivered_value), 2) AS average_customer_spend
FROM customer_discount d JOIN v_customer_activity a ON d.customer_id = a.customer_id
GROUP BY d.used_discount ORDER BY d.used_discount;

-- D3. Discounted orders by restaurant city
SELECT restaurant_city, SUM(discounted) AS discounted_orders
FROM v_order_metrics GROUP BY restaurant_city ORDER BY discounted_orders DESC, restaurant_city;

-- D4. Repeat purchase 1–90 days after first observed delivered order
WITH ranked_deliveries AS (
    SELECT o.customer_id, o.order_timestamp, o.discounted,
           ROW_NUMBER() OVER (
               PARTITION BY o.customer_id ORDER BY o.order_timestamp, o.order_id
           ) AS delivery_rank
    FROM v_order_metrics o JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Delivered'
), cohorts AS (
    SELECT f.customer_id, f.discounted,
           CASE WHEN EXISTS (
               SELECT 1 FROM ranked_deliveries d
               WHERE d.customer_id = f.customer_id
                 AND DATEDIFF(d.order_timestamp, f.order_timestamp) BETWEEN 1 AND 90
           ) THEN 1 ELSE 0 END AS repeated
    FROM ranked_deliveries f
    WHERE f.delivery_rank = 1
      AND DATEDIFF((SELECT MAX(order_timestamp) FROM orders), f.order_timestamp) >= 90
)
SELECT discounted AS first_delivery_discounted, COUNT(*) AS eligible_customers,
       SUM(repeated) AS repeat_customers, ROUND(100.0 * AVG(repeated), 2) AS repeat_rate_pct
FROM cohorts GROUP BY discounted ORDER BY discounted;

-- Cancellations and refunds
-- O1. Cancellation rate
SELECT SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
       ROUND(100.0 * AVG(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END), 2) AS cancellation_rate_pct
FROM orders;

-- O2. Refund rate
SELECT SUM(CASE WHEN order_status = 'Refunded' THEN 1 ELSE 0 END) AS refunded_orders,
       ROUND(100.0 * AVG(CASE WHEN order_status = 'Refunded' THEN 1 ELSE 0 END), 2) AS refund_rate_pct
FROM orders;

-- O3. Estimated foregone order value from cancellations
SELECT SUM(net_order_value) AS cancelled_order_value
FROM v_order_metrics WHERE order_status = 'Cancelled';

-- O4. Restaurant cancellation rates and denominators
SELECT restaurant_id, restaurant_name, city, order_count, cancelled_orders,
       ROUND(100.0 * cancelled_orders / NULLIF(order_count, 0), 2) AS cancellation_rate_pct
FROM v_restaurant_performance
WHERE order_count > 0
ORDER BY cancellation_rate_pct DESC, order_count DESC, restaurant_id;

-- Churn
-- H1. Churned customers
SELECT COUNT(*) AS churned_customers FROM v_customer_churn WHERE churned = 1;

-- H2. Churn rate among matched customers with a delivered order
SELECT MAX(as_of_date) AS as_of_date, COUNT(*) AS purchasing_customers,
       ROUND(100.0 * AVG(churned), 2) AS churn_rate_pct
FROM v_customer_churn;

-- H3. Churn by customer city
SELECT city, COUNT(*) AS purchasing_customers, SUM(churned) AS churned_customers,
       ROUND(100.0 * AVG(churned), 2) AS churn_rate_pct
FROM v_customer_churn GROUP BY city ORDER BY churn_rate_pct DESC, churned_customers DESC, city;

-- H4. Historical delivered value associated with churned customers
SELECT SUM(delivered_value) AS historical_value_of_churned_customers
FROM v_customer_churn WHERE churned = 1;

-- H5. Churned customers in the highest-spending quintile of all purchasing customers
WITH ranked_customers AS (
    SELECT a.*, NTILE(5) OVER (ORDER BY delivered_value DESC, customer_id) AS revenue_quintile
    FROM v_customer_churn a
)
SELECT customer_id, city, delivered_value, last_delivered_date, days_inactive
FROM ranked_customers WHERE churned = 1 AND revenue_quintile = 1
ORDER BY delivered_value DESC, customer_id;
