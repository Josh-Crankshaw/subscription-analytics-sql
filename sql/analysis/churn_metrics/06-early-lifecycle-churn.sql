/*
Query Name: Early Lifecycle Churn Rate
Purpose: Measure the proportion of subscriptions that churn within 30 days of starting.
Business Question: How many customers cancel shortly after subscribing?
Tables Used:
  - subscriptions
Key Columns Used:
  - started_date
  - ended_date
Assumptions:
  - A subscription is considered early churn if it ends within 30 days of starting (inclusive)
  - Early churn rate = early churned subscriptions / total subscriptions
Output:
  - total_subscriptions
  - early_churned_subscriptions
  - early_churn_rate
*/

SELECT
    COUNT(*) AS total_subscriptions,
    COUNT(*) FILTER (
        WHERE subscriptions.ended_date IS NOT NULL
        AND subscriptions.ended_date <= subscriptions.started_date + INTERVAL '30 days'
    ) AS early_churned_subscriptions,
    ROUND(
        COUNT(*) FILTER (
            WHERE subscriptions.ended_date IS NOT NULL
            AND subscriptions.ended_date <= subscriptions.started_date + INTERVAL '30 days'
        )::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS early_churn_rate
FROM subscriptions;