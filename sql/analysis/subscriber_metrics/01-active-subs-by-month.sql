/*
Query Name: Active Subscriptions by Month
Purpose: Count the number of subscriptions active in each month of 2025.
Business Question: How many active subscriptions were there in each month?
Tables Used:
  - subscriptions
Key Columns Used:
  - subscription_id
  - started_date
  - ended_date
Assumptions:
  - A subscription is counted as active in a month if it was active at any point during that month
  - A subscription is active if:
      started_date < first day of next month
      AND (ended_date IS NULL OR ended_date >= first day of the month)
Output:
  - month_start
  - active_subscriptions
*/

WITH months AS (
    SELECT
        generate_series(
            '2025-01-01'::TIMESTAMPTZ,
            '2025-12-01'::TIMESTAMPTZ,
            INTERVAL '1 month'
        ) AS month_start
)

SELECT
    months.month_start::DATE AS month_start,
    COUNT(subscriptions.subscription_id) AS active_subscriptions
FROM months
LEFT JOIN subscriptions
    ON subscriptions.started_date < months.month_start + INTERVAL '1 month'
   AND (
        subscriptions.ended_date IS NULL
        OR subscriptions.ended_date >= months.month_start
   )
GROUP BY months.month_start
ORDER BY months.month_start;