/*
Query Name: Cancellation Rate by Plan Type
Purpose: Calculate the proportion of subscriptions that have been cancelled for each plan type.
Business Question: Which subscription plans experience higher cancellation rates?
Tables Used:
  - subscriptions
Key Columns Used:
  - plan_type
  - sub_status
Assumptions:
  - Each row represents one subscription
  - 'cancelled' indicates a completed cancellation
  - Cancellation rate = cancelled subscriptions / total subscriptions
Output:
  - plan_type
  - total_subscriptions
  - active_subscriptions
  - cancelled_subscriptions
  - cancellation_rate
*/

SELECT
    subscriptions.plan_type,
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (WHERE subscriptions.sub_status = 'active') AS active_subscriptions,
    COUNT(*) FILTER (WHERE subscriptions.sub_status = 'cancelled') AS cancelled_subscriptions,
    ROUND(
        COUNT(*) FILTER (WHERE subscriptions.sub_status = 'cancelled')::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS cancellation_rate
FROM subscriptions
GROUP BY subscriptions.plan_type
ORDER BY cancellation_rate DESC;