/*
Query Name: Monthly Revenue by Acquisition Channel
Purpose: Calculate monthly revenue segmented by acquisition channel.
Business Question: How does revenue contribution from each acquisition channel change over time?
Tables Used:
  - customers
  - subscriptions
  - payments
Key Columns Used:
  - acquisition_channel
  - payment_at
  - amount
  - payment_status
Assumptions:
  - Only successful payments contribute to revenue
  - Revenue is calculated on a cash basis (payment date)
  - Acquisition channel is assigned at the customer level
Output:
  - month_start
  - acquisition_channel
  - total_revenue
*/

SELECT
    DATE_TRUNC('month', payments.payment_at) AS month_start,
    customers.acquisition_channel,
    ROUND(SUM(payments.amount::NUMERIC), 1) AS total_revenue
FROM customers
JOIN subscriptions
    ON customers.customer_id = subscriptions.customer_id
JOIN payments
    ON subscriptions.subscription_id = payments.subscription_id
WHERE payments.payment_status = 'successful'
GROUP BY
    DATE_TRUNC('month', payments.payment_at),
    customers.acquisition_channel
ORDER BY
    month_start,
    customers.acquisition_channel;