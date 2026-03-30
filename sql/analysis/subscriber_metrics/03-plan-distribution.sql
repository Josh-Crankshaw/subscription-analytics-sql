/*
Query Name: Subscription Distribution by Plan Type
Purpose: Calculate the number and proportion of subscriptions for each plan type.
Business Question: How are subscriptions distributed across different plan tiers?
Tables Used:
  - subscriptions
Key Columns Used:
  - plan_type
Assumptions:
  - Each row represents one subscription
  - Plan type is assigned per subscription
Output:
  - plan_type
  - total_subscriptions
  - subscription_share
*/

SELECT
    subscriptions.plan_type,
    COUNT(*) AS total_subscriptions,
    ROUND(
        COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0),
        4
    ) AS subscription_share
FROM subscriptions
GROUP BY subscriptions.plan_type
ORDER BY total_subscriptions DESC;