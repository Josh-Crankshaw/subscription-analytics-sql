/*
Query Name: Customer Lifetime Value by Acquisition Channel
Purpose: Calculate the average lifetime revenue per customer for each acquisition channel.
Business Question: Which acquisition channels generate the highest value customers?
Tables Used:
  - customers
  - subscriptions
  - payments
Key Columns Used:
  - customer_id
  - acquisition_channel
  - subscription_id
  - amount
  - payment_status
Assumptions:
  - Only successful payments contribute to revenue
  - Revenue is calculated on a cash basis
  - Each customer may have one or more subscriptions
Output:
  - acquisition_channel
  - total_revenue
  - total_customers
  - avg_ltv_per_customer
*/

WITH customer_lifetime_revenue AS (
    SELECT
        customers.customer_id,
        customers.acquisition_channel,
        SUM(payments.amount::NUMERIC) AS lifetime_revenue
    FROM customers
    JOIN subscriptions
        ON customers.customer_id = subscriptions.customer_id
    JOIN payments
        ON subscriptions.subscription_id = payments.subscription_id
    WHERE payments.payment_status = 'successful'
    GROUP BY
        customers.customer_id,
        customers.acquisition_channel
)

SELECT
    acquisition_channel,
    ROUND(SUM(lifetime_revenue), 1) AS total_revenue,
    COUNT(*) AS total_customers,
    ROUND(
        SUM(lifetime_revenue) / NULLIF(COUNT(*), 0),
        2
    ) AS avg_ltv_per_customer
FROM customer_lifetime_revenue
GROUP BY acquisition_channel
ORDER BY avg_ltv_per_customer DESC;