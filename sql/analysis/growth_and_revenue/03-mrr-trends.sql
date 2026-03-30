/*
Query Name: Monthly Recurring Revenue (MRR)
Purpose: Calculate month-end recurring revenue based on active subscriptions.
Business Question: What was the recurring revenue run-rate at the end of each month?
Tables Used:
  - subscriptions
Key Columns Used:
  - started_date
  - ended_date
  - monthly_price
  - billing_cycle
Assumptions:
  - Monthly plans contribute full monthly_price
  - Yearly plans are normalized to monthly revenue
  - MRR is measured at the end of each month
Output:
  - month_start
  - month_name
  - mrr
*/

WITH months AS (
    SELECT generate_series(
        DATE '2025-01-01',
        DATE '2025-12-01',
        INTERVAL '1 month'
    ) AS month_start
),

month_end_dates AS (
    SELECT
        month_start,
        (month_start + INTERVAL '1 month' - INTERVAL '1 day')::date AS month_end
    FROM months
)

SELECT
    month_start,
    TRIM(TO_CHAR(month_start, 'Month')) AS month_name,
    COALESCE(
        SUM(
            CASE
                WHEN billing_cycle = 'monthly' THEN monthly_price::NUMERIC
                WHEN billing_cycle = 'yearly' THEN monthly_price::NUMERIC / 12
                ELSE 0
            END
        ),
        0
    )::DECIMAL(10,2) AS mrr
FROM month_end_dates 
LEFT JOIN subscriptions 
    ON started_date::date <= month_end
   AND (ended_date IS NULL OR ended_date::date > month_end)
GROUP BY
    month_start
ORDER BY
    month_start;