-- Calculates the retention of each subscription cohort by plan type every month until the end of the year
-- Outputs: The cohort month, the subscription plan type, the months since cohort was formed, the size of the cohort, the number
-- of subscriptions retained through the month, and the rate of retention through the month.
WITH
cohort AS (
	SELECT
		subscription_id,
		plan_type,
		DATE_TRUNC('month', started_date) AS cohort_month,
		started_date,
		ended_date
	FROM subscriptions
),
months AS (
	SELECT generate_series(
		'2025-01-01'::TIMESTAMPTZ,
		'2025-12-01'::TIMESTAMPTZ,
		INTERVAL '1 month'
	)::TIMESTAMPTZ AS month_start
),
cohort_sizes AS (
	SELECT
		cohort_month,
		plan_type,
		COUNT(*) AS cohort_size
	FROM cohort
	GROUP BY cohort_month, plan_type
),
activity AS (
	SELECT
		cohort_month,
		plan_type,
		month_start,
		((DATE_PART('year', month_start) - DATE_PART('year', cohort_month)) * 12
		+ (DATE_PART('month', month_start) - DATE_PART('month', cohort_month))
		)::INT AS months_since,
		COUNT(*) AS retained_subs	
	FROM cohort
	JOIN months
	ON month_start >= cohort_month
		AND started_date < (month_start + INTERVAL '1 month')
     	AND (ended_date IS NULL OR ended_date >= month_start)
    GROUP BY cohort_month, plan_type, month_start
)
SELECT 
	activity.cohort_month,
	activity.plan_type,
	months_since,
	cohort_size,
	retained_subs,
	ROUND(retained_subs::numeric / cohort_size, 4) AS retention_rate
FROM activity 
JOIN cohort_sizes 
ON activity.cohort_month = cohort_sizes.cohort_month
AND activity.plan_type = cohort_sizes.plan_type
WHERE months_since BETWEEN 0 AND 11
ORDER BY cohort_month, plan_type, months_since;