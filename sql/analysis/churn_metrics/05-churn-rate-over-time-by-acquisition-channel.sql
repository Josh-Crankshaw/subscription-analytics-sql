-- Find how many supscriptions churned each month grouped by acquisition channel
-- Outputs: month_start, acquisition_channel, subscriptions active at month start, subscriptions churned
-- during the month, and churn rate grouped by month and acquisition channel
WITH months AS (
	SELECT generate_series(
		'2025-01-01'::TIMESTAMPTZ,
		'2025-12-01'::TIMESTAMPTZ,
		INTERVAL '1 month'
	) AS month_start
),
monthly_base AS (
	SELECT
		months.month_start,
		acquisition_channel,
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
	INNER JOIN customers
	ON customers.customer_id = subscriptions.customer_id
	GROUP BY months.month_start, acquisition_channel	
)

SELECT 
	month_start::DATE AS month_start,
	acquisition_channel,
	active_at_month_start,
	churned_in_month,
	ROUND(
		churned_in_month::NUMERIC / NULLIF(active_at_month_start, 0),
		4
	) AS churn_rate
FROM monthly_base
ORDER BY month_start, acquisition_channel