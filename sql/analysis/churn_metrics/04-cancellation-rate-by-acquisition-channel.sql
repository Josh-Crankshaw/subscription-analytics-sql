/*
Query Name: Cancellation Rate by Acquisition Channel
Purpose: Calculate the proportion of subscriptions that have been cancelled for each acquisition channel.
Business Question: Which acquisition channels produce customers with higher cancellation rates?
Tables Used:
  - customers
  - subscriptions
Key Columns Used:
  - customer_id
  - acquisition_channel
  - sub_status
Assumptions:
  - Each row represents one subscription
  - Acquisition channel is assigned at the customer level
  - Cancellation rate = cancelled subscriptions / total subscriptions
Output:
  - acquisition_channel
  - total_subscriptions
  - active_subscriptions
  - cancelled_subscriptions
  - cancellation_rate
*/

SELECT
    customers.acquisition_channel,
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (WHERE subscriptions.sub_status = 'active') AS active_subscriptions,
    COUNT(*) FILTER (WHERE subscriptions.sub_status = 'cancelled') AS cancelled_subscriptions,
    ROUND(
        COUNT(*) FILTER (WHERE subscriptions.sub_status = 'cancelled')::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS cancellation_rate
FROM customers
JOIN subscriptions
    ON customers.customer_id = subscriptions.customer_id
GROUP BY customers.acquisition_channel
ORDER BY cancellation_rate DESC;