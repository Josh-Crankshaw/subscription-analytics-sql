/*
Query Name: Monthly Churn Rate by Acquisition Channel
Purpose: Calculate monthly churn rates segmented by acquisition channel.
Business Question: How does churn vary across acquisition channels over time?
Tables Used:
  - subscriptions
  - customers
Key Columns Used:
  - customer_id
  - acquisition_channel
  - started_date
  - ended_date
Assumptions:
  - A subscription is included in the churn base if active at the start of the month
  - A subscription is counted as churned if it ends during the month
  - Date comparisons are performed at the DATE level to avoid timezone issues
  - Churn rate = churned subscriptions / active subscriptions at month start
Output:
  - month_start
  - acquisition_channel
  - active_at_month_start
  - churned_in_month
  - churn_rate
*/

WITH months AS (
    SELECT
        generate_series(
            DATE '2025-01-01',
            DATE '2025-12-01',
            INTERVAL '1 month'
        )::DATE AS month_start
),

active_base AS (
    SELECT
        months.month_start,
        customers.acquisition_channel,
        COUNT(subscriptions.subscription_id) AS active_at_month_start
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.started_date::DATE < months.month_start
       AND (
            subscriptions.ended_date IS NULL
            OR subscriptions.ended_date::DATE >= months.month_start
       )
    LEFT JOIN customers
        ON subscriptions.customer_id = customers.customer_id
    GROUP BY
        months.month_start,
        customers.acquisition_channel
),

monthly_churn AS (
    SELECT
        months.month_start,
        customers.acquisition_channel,
        COUNT(subscriptions.subscription_id) AS churned_in_month
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.started_date::DATE < months.month_start
       AND subscriptions.ended_date IS NOT NULL
       AND subscriptions.ended_date::DATE >= months.month_start
       AND subscriptions.ended_date::DATE < months.month_start + INTERVAL '1 month'
    LEFT JOIN customers
        ON subscriptions.customer_id = customers.customer_id
    GROUP BY
        months.month_start,
        customers.acquisition_channel
)

SELECT
    active_base.month_start,
    active_base.acquisition_channel,
    active_base.active_at_month_start,
    monthly_churn.churned_in_month,
    ROUND(
        monthly_churn.churned_in_month::NUMERIC
        / NULLIF(active_base.active_at_month_start, 0),
        4
    ) AS churn_rate
FROM active_base
JOIN monthly_churn
    ON active_base.month_start = monthly_churn.month_start
   AND active_base.acquisition_channel = monthly_churn.acquisition_channel
ORDER BY
    active_base.month_start,
    active_base.acquisition_channel;