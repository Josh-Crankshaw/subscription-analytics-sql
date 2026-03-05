--Calculates the retention of each subscriber cohort every month until the end of the year
WITH 
	cohort AS (
		SELECT
			subscription_id,
			DATE_TRUNC('month', started_date) AS cohort_month,
			started_date,
			ended_date
		FROM subscriptions
	),
	months AS (
		SELECT generate_series(
			DATE '2025-01-01',
			DATE '2025-12-01',
			INTERVAL '1 month'
		)::date AS month_start
	),
	cohort_sizes AS (
		SELECT 
			cohort_month,
			COUNT(*) AS cohort_size
		FROM cohort
		GROUP BY cohort_month
	),
	activity AS (
		SELECT
			cohort_month,
        	month_start,
        	((DATE_PART('year', month_start) - DATE_PART('year', cohort_month)) * 12
        	 + (DATE_PART('month', month_start) - DATE_PART('month', cohort_month))
        	)::int AS months_since,
        	COUNT(*) AS retained_subscriptions
		FROM cohort
		JOIN months
      	ON month_start >= cohort_month
     		AND started_date < (month_start + INTERVAL '1 month')
     		AND (ended_date IS NULL OR ended_date >= month_start)
    	GROUP BY cohort_month, month_start
	)
SELECT
    cohort_month,
    months_since,
    cohort_size,
    retained_subscriptions,
    ROUND(retained_subscriptions::numeric / cohort_size, 4) AS retention_rate
FROM activity 
JOIN cohort_sizes USING (cohort_month)
WHERE months_since BETWEEN 0 AND 11
ORDER BY cohort_month, months_since;