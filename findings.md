# Zomato case study findings

The dataset records **₹2.70 crore in delivered order value**, with an average delivered order value of **₹903.77**. About **20% of orders were cancelled** and another **20% were refunded**. The biggest operational question is what drives those outcomes, since the workbook gives the status without the reason.

| Business area | Finding | Query outputs |
|---|---|---|
| Revenue | Chennai led at ₹43.87 lakh. UPI generated ₹1.35 crore, about half of delivered value. Monthly value ranged from ₹8.42 lakh in February 2025 to ₹10.46 lakh in December 2025. | R1–R5 |
| Customers | The top 20 customers accounted for 1.03% of delivered value. WhatsApp Campaign ranked first at ₹5,492.89 per purchasing customer, followed by Google Ads at ₹5,460.99. There were 4,914 repeat customers. | C1–C4 |
| Restaurants | KFC in Gurugram (R0159) led delivered value at ₹1.67 lakh. Biryani By Kilo in Bengaluru (R0072) led volume with 288 recorded orders. North Indian led cuisine volume with 9,807 orders. Restaurants rated 4.0 or above averaged ₹1.35 lakh, close to the lower-rated group. | P1–P5 |
| Discounts | 40.26% of orders had a positive discount. Customers with any discounted delivery spent ₹5,590.38 on average across the dataset, versus ₹3,425.36 for customers without one. The 90-day repeat rate was 48.31% for discounted first deliveries and 46.29% for undiscounted first deliveries, a 2.02 percentage point gap. Chennai logged the most discounted orders (3,311). | D1–D4 |
| Cancellations and refunds | The cancellation rate was 20.19% and the refund rate was 20.14%. Cancelled orders carried ₹90.94 lakh of estimated foregone order value. Haldiram’s in Chennai (R0194) had the highest observed cancellation rate at 27.35% across 245 orders. | O1–O4 |
| Churn | As of 30 April 2026, 2,688 of 4,990 purchasing customers were inactive for 90 days or more (53.87%). Bengaluru had the highest city rate (55.83%), while Noida had more churned customers (367 versus 345). Churned customers historically generated ₹1.31 crore in delivered value. Of these customers, 367 were in the highest spending quintile. | H1–H5 |

## Recommended actions

1. **Investigate restaurant cancellations first.** Start with the highest-rate outlets that also have substantial order counts. Collect cancellation and refund reasons so outlet teams can identify whether availability, preparation delays, or another issue explains the pattern.
2. **Test a win-back campaign with the 367 high-value inactive customers.** Randomly assign a holdout group and measure incremental delivered orders and order value. Use city rates to understand local patterns and the underlying counts to size the opportunity.
3. **Test first-order discounts before increasing spend.** The 2.02-point gap is observational. Compare eligible customers assigned to an offer or a holdout and track incremental repeat orders alongside discount cost.
4. **Validate acquisition economics before shifting budget.** WhatsApp Campaign led Google Ads by ₹31.90 in observed value per purchasing customer. Compare acquisition costs and resolve signup date inconsistencies before interpreting that difference as channel performance.

## Interpretation

The case tracks order value and status. It has no settled platform revenue, actual refund amounts, offer codes, or future churn losses. Historical churn exposure measures the value previously associated with the churned cohort. Orders before recorded signup and unmatched customer IDs are documented in the validation script.
