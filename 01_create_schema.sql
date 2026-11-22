CREATE DATABASE IF NOT EXISTS zomato_analytics CHARACTER SET utf8mb4;
USE zomato_analytics;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(12) PRIMARY KEY,
    customer_name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    signup_time DATE NOT NULL,
    acquisition_channel VARCHAR(100) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS restaurants (
    restaurant_id VARCHAR(12) PRIMARY KEY,
    restaurant_name VARCHAR(150) NOT NULL,
    cuisine VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    avg_rating DECIMAL(3,2) NOT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(12) PRIMARY KEY,
    customer_id VARCHAR(12) NOT NULL,
    restaurant_id VARCHAR(12) NOT NULL,
    order_timestamp DATE NOT NULL,
    order_amount DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL,
    delivery_fee DECIMAL(12,2) NOT NULL,
    payment_mode VARCHAR(40) NOT NULL,
    order_status VARCHAR(40) NOT NULL,
    INDEX idx_orders_customer_date (customer_id, order_timestamp),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants (restaurant_id)
) ENGINE = InnoDB;
-- A customer FK is omitted because 10 source orders reference an absent customer.
