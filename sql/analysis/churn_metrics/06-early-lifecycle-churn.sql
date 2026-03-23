-- Determine how many subscriptions were cancelled within 30 days of starting the subscription
-- Outputs: total subscriptions, number of early lifecycle subscription churns, and the rate of early 
-- lifecycle subscription churns
SELECT 
	COUNT(*) AS total_subs,
	COUNT(*) FILTER (
		WHERE ended_date IS NOT NULL
		AND started_date + INTERVAL '30 days' >= ended_date
	) AS early_lifecycle_churned_subs,
	ROUND((COUNT(*) FILTER (
		WHERE ended_date IS NOT NULL
		AND started_date + INTERVAL '30 days' >= ended_date)
	)::NUMERIC / COUNT(*), 3) AS early_lifecycle_sub_churn_rate
FROM subscriptions