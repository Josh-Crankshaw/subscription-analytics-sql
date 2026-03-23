-- Calculates the churn rate of each month
-- Outputs: Month start, number of active subscriptions at month start, number of churned subscriptions
-- within the month, and the correlating churn rate of the month
WITH months AS (
    SELECT generate_series(
        '2025-01-01'::timestamptz,
        '2025-12-01'::timestamptz,
        INTERVAL '1 month'
    ) AS month_start
),
monthly_base AS (
    SELECT
        months.month_start,
        COUNT(*) FILTER (
            WHERE started_date < months.month_start
            AND (ended_date IS NULL OR ended_date >= months.month_start)
        ) AS active_at_start,
        COUNT(*) FILTER (
            WHERE started_date < months.month_start
            AND ended_date IS NOT NULL 
            AND ended_date >= months.month_start
            AND ended_date < months.month_start + INTERVAL '1 month' 
        ) AS churned_in_month
    FROM months
    CROSS JOIN subscriptions
    GROUP BY months.month_start
)
SELECT
    month_start::DATE AS month_start,
    active_at_start,
    churned_in_month,
    ROUND(
        churned_in_month::NUMERIC / NULLIF(active_at_start, 0),
        4
    ) AS churn_rate
FROM monthly_base
ORDER BY month_start;