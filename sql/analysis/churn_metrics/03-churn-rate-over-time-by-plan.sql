/*
Query Name: Monthly Churn Rate by Plan Type
Purpose: Calculate monthly churn rates segmented by subscription plan.
Business Question: How does churn vary across plan types over time?
Tables Used:
  - subscriptions
Key Columns Used:
  - plan_type
  - started_date
  - ended_date
Assumptions:
  - A subscription is included in the churn base if active at the start of the month
  - A subscription is counted as churned if it ends during the month
  - Date comparisons are performed at the DATE level to avoid timezone issues
  - Churn rate = churned subscriptions / active subscriptions at month start
Output:
  - month_start
  - plan_type
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
        subscriptions.plan_type,
        COUNT(subscriptions.subscription_id) AS active_at_month_start
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.started_date::DATE < months.month_start
       AND (
            subscriptions.ended_date IS NULL
            OR subscriptions.ended_date::DATE >= months.month_start
       )
    GROUP BY
        months.month_start,
        subscriptions.plan_type
),

monthly_churn AS (
    SELECT
        months.month_start,
        subscriptions.plan_type,
        COUNT(subscriptions.subscription_id) AS churned_in_month
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.started_date::DATE < months.month_start
       AND subscriptions.ended_date IS NOT NULL
       AND subscriptions.ended_date::DATE >= months.month_start
       AND subscriptions.ended_date::DATE < months.month_start + INTERVAL '1 month'
    GROUP BY
        months.month_start,
        subscriptions.plan_type
)

SELECT
    active_base.month_start,
    active_base.plan_type,
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
   AND active_base.plan_type = monthly_churn.plan_type
ORDER BY
    active_base.month_start,
    active_base.plan_type;