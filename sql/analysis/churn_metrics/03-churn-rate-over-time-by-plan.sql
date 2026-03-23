-- Calculate and output the monthly churn rate by plan
-- Outputs: month starts, plan types, active subscriptions at month start, churned subscriptions in month, 
-- and correlating churn rates
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
		plan_type,
		COUNT(*) FILTER (
			WHERE started_date < months.month_start
			AND (ended_date IS NULL OR ended_date >= months.month_start)
		) AS active_at_month_start,
		COUNT(*) FILTER (
			WHERE started_date < months.month_start
			AND ended_date IS NOT NULL
			AND ended_date >= months.month_start
			AND ended_date < months.month_start + INTERVAL '1 month'
		) AS churned_in_month
	FROM months
	CROSS JOIN subscriptions
	GROUP BY months.month_start, plan_type
)
SELECT
	month_start::DATE AS month_start,
	plan_type,
	active_at_month_start,
	churned_in_month,
	ROUND(
        churned_in_month::NUMERIC / NULLIF(active_at_month_start, 0),
        4
    ) AS churn_rate
FROM monthly_base
ORDER BY month_start, plan_type;