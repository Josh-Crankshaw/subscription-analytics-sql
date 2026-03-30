/*
Query Name: Average Revenue Per Subscription
Purpose: Calculate the average total revenue generated per subscription.
Business Question: On average, how much revenue does each subscription generate?
Tables Used:
  - payments
Key Columns Used:
  - subscription_id
  - amount
  - payment_status
Assumptions:
  - Only successful payments contribute to revenue
  - Each subscription_id represents a unique subscription
  - Metric represents total lifetime revenue per subscription (not time-normalised)
Output:
  - total_subscriptions
  - total_revenue
  - avg_revenue_per_subscription
*/

WITH revenue_per_subscription AS (
    SELECT
        subscription_id,
        SUM(amount::NUMERIC) AS total_revenue_per_subscription
    FROM payments
    WHERE payment_status = 'successful'
    GROUP BY subscription_id
)

SELECT
    COUNT(*) AS total_subscriptions,
    ROUND(SUM(total_revenue_per_subscription), 1) AS total_revenue,
    ROUND(
        SUM(total_revenue_per_subscription)
        / NULLIF(COUNT(*), 0),
        4
    )::DECIMAL(10,2) AS avg_revenue_per_subscription
FROM revenue_per_subscription;