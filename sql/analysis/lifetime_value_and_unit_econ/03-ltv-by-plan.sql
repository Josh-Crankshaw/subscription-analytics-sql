/*
Query Name: Lifetime Value by Plan Type
Purpose: Calculate the average lifetime revenue per subscription for each plan type.
Business Question: Which subscription plans generate the highest lifetime value?
Tables Used:
  - subscriptions
  - payments
Key Columns Used:
  - subscription_id
  - plan_type
  - amount
  - payment_status
Assumptions:
  - Only successful payments contribute to revenue
  - Revenue is calculated on a cash basis
  - Each subscription belongs to a single plan type
Output:
  - plan_type
  - total_revenue
  - total_subscriptions
  - avg_ltv_per_subscription
*/

WITH subscription_lifetime_revenue AS (
    SELECT
        subscriptions.subscription_id,
        subscriptions.plan_type,
        SUM(payments.amount::NUMERIC) AS lifetime_revenue
    FROM subscriptions
    JOIN payments
        ON subscriptions.subscription_id = payments.subscription_id
    WHERE payments.payment_status = 'successful'
    GROUP BY
        subscriptions.subscription_id,
        subscriptions.plan_type
)

SELECT
    plan_type,
    ROUND(SUM(lifetime_revenue), 1) AS total_revenue,
    COUNT(*) AS total_subscriptions,
    ROUND(
        SUM(lifetime_revenue) / NULLIF(COUNT(*), 0),
        2
    ) AS avg_ltv_per_subscription
FROM subscription_lifetime_revenue
GROUP BY plan_type
ORDER BY avg_ltv_per_subscription DESC;