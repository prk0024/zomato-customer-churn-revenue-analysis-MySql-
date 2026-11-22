# Zomato Customer & Order Analytics

This SQL case study examines what drove delivered order value, where cancellations were concentrated, and which inactive customers were worth prioritizing for a win-back campaign. It covers **50,000 orders, 4,999 customers, and 200 restaurants** from January 2024 to April 2026.

The project answers 27 business questions across revenue, customer behavior, restaurant performance, discounts, cancellations and refunds, and churn.

## Key findings

| Area | Finding |
|---|---|
| Order value | Delivered orders generated **₹2.70 crore** in net order value, with an average of **₹903.77** per delivery. Chennai led by restaurant city at **₹43.87 lakh**. |
| Cancellations and refunds | **20.19%** of orders were cancelled and **20.14%** were marked refunded. Cancelled orders carried **₹90.94 lakh** in estimated foregone order value. |
| Discounts and retention | Customers whose first observed delivery was discounted had a **48.31%** 90-day repeat rate, compared with **46.29%** for those whose first delivery was undiscounted. The difference is observational. |
| Customer churn | **2,688 of 4,990** purchasing customers were inactive for at least 90 days at the end of the dataset. Of these, **367** ranked in the top fifth by historical delivered order value. |

The analysis highlights two priorities: investigate cancellations at outlets with high cancellation rates and substantial order volume, and test a win-back campaign for high-value inactive customers using a holdout group.

## SQL approach

The project uses a relational model with orders linked to customers and restaurants by ID. MySQL 8 queries use joins and aggregations to calculate business metrics, views to reuse those calculations, and CTEs and window functions to rank customers and build repeat-purchase cohorts.

- **Net order value** is order amount minus discount plus delivery fee. The revenue analysis includes delivered orders and measures customer order value. Platform commissions and settlements are outside the dataset.
- **Discount usage** is represented by a positive discount amount. The 90-day repeat comparison gives each eligible customer the same follow-up window after their first observed delivery.
- **Churn** means at least 90 days since the last delivered order as of 30 April 2026. The churn exposure figure measures historical delivered order value for that group.

Validation identified 10 orders with unmatched customer IDs and 20,428 matched orders dated before recorded signup. Overall order metrics include the unmatched orders, while customer-level metrics use matched records. Repeat purchase and churn use observed order dates. The SQL is written for MySQL 8. The included results were verified in SQLite with adapted syntax, and the MySQL import remains untested.

## Repository contents

| Path | Contents |
|---|---|
| [`sql/`](sql/) | Database schema, data import, validation checks, and 27 business queries |
| `data/` | Customer, restaurant, and order source CSVs |
| `results/` | Query output CSVs labeled to match the analysis |
| [`report/findings.md`](report/findings.md) | Detailed findings, recommendations, and interpretation |
