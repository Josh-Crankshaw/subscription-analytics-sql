/*
Query Name: Overall Cancellation Rate
Purpose: Calculate the proportion of subscriptions that have been cancelled.
Business Question: What percentage of all subscriptions resulted in cancellation?
Tables Used:
  - subscriptions
Key Columns Used:
  - sub_status
Assumptions:
  - Each row represents a unique subscription
  - 'cancelled' status indicates a completed cancellation
  - Cancellation rate = cancelled subscriptions / total subscriptions
Output:
  - total_subscriptions
  - active_subscriptions
  - cancelled_subscriptions
  - cancellation_rate
*/

SELECT
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (WHERE sub_status = 'active') AS active_subscriptions,
    COUNT(*) FILTER (WHERE sub_status = 'cancelled') AS cancelled_subscriptions,
    ROUND(
        COUNT(*) FILTER (WHERE sub_status = 'cancelled')::NUMERIC
        / NULLIF(COUNT(*), 0),
        3
    ) AS cancellation_rate
FROM subscriptions;