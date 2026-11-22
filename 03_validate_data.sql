USE zomato_analytics;

SELECT 'customers' AS table_name, COUNT(*) AS row_count,
       COUNT(DISTINCT customer_id) AS distinct_ids, 4999 AS expected_rows
FROM customers
UNION ALL
SELECT 'restaurants', COUNT(*), COUNT(DISTINCT restaurant_id), 200 FROM restaurants
UNION ALL
SELECT 'orders', COUNT(*), COUNT(DISTINCT order_id), 50000 FROM orders;

-- Expected 2024-01-01 through 2026-04-30.
SELECT MIN(order_timestamp) AS first_order_date, MAX(order_timestamp) AS last_order_date
FROM orders;

-- Expected Cancelled 10095, Delivered 29837, Refunded 10068.
SELECT order_status, COUNT(*) AS order_count FROM orders GROUP BY order_status;

SELECT
    SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END) AS unmatched_customer_orders,
    SUM(CASE WHEN r.restaurant_id IS NULL THEN 1 ELSE 0 END) AS unmatched_restaurant_orders,
    SUM(CASE WHEN o.order_timestamp < c.signup_time THEN 1 ELSE 0 END) AS orders_before_signup,
    SUM(CASE WHEN o.discount_amount > 0 THEN 1 ELSE 0 END) AS positive_discount_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id;
-- Expected 10, 0, 20428, 20128.

-- NOT NULL constraints cover missing values. This check also catches blank text and invalid amounts.
SELECT 'customers' AS table_name, COUNT(*) AS suspect_rows
FROM customers
WHERE TRIM(customer_id) = '' OR TRIM(customer_name) = ''
   OR TRIM(city) = '' OR TRIM(acquisition_channel) = ''
UNION ALL
SELECT 'restaurants', COUNT(*) FROM restaurants
WHERE TRIM(restaurant_id) = '' OR TRIM(restaurant_name) = ''
   OR TRIM(city) = '' OR TRIM(cuisine) = '' OR avg_rating NOT BETWEEN 0 AND 5
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
WHERE TRIM(order_id) = '' OR TRIM(customer_id) = '' OR TRIM(restaurant_id) = ''
   OR TRIM(payment_mode) = '' OR order_amount < 0 OR discount_amount < 0
   OR delivery_fee < 0 OR discount_amount > order_amount
   OR order_status NOT IN ('Delivered', 'Cancelled', 'Refunded');
