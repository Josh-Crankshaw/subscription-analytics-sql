/*
Query Name: Monthly Churn Rate
Purpose: Calculate the monthly churn rate for subscriptions during 2025.
Business Question: What percentage of active subscriptions churned each month?
Tables Used:
  - subscriptions
Key Columns Used:
  - started_date
  - ended_date
Assumptions:
  - A subscription is included in the churn base if it was active at the start of the month
  - A subscription is counted as churned if it ended during that month
  - Date comparisons are performed at the DATE level to avoid timezone boundary issues
  - Monthly churn rate = churned subscriptions / active subscriptions at month start
Output:
  - month_start
  - active_at_start
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
        COUNT(subscriptions.subscription_id) AS active_at_start
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.started_date::DATE < months.month_start
       AND (
            subscriptions.ended_date IS NULL
            OR subscriptions.ended_date::DATE >= months.month_start
       )
    GROUP BY months.month_start
),

monthly_churn AS (
    SELECT
        months.month_start,
        COUNT(subscriptions.subscription_id) AS churned_in_month
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.started_date::DATE < months.month_start
       AND subscriptions.ended_date IS NOT NULL
       AND subscriptions.ended_date::DATE >= months.month_start
       AND subscriptions.ended_date::DATE < months.month_start + INTERVAL '1 month'
    GROUP BY months.month_start
)

SELECT
    active_base.month_start,
    active_base.active_at_start,
    monthly_churn.churned_in_month,
    ROUND(
        monthly_churn.churned_in_month::NUMERIC / NULLIF(active_base.active_at_start, 0),
        4
    ) AS churn_rate
FROM active_base
JOIN monthly_churn
    ON active_base.month_start = monthly_churn.month_start
ORDER BY active_base.month_start;