-- Calculate the net subscriber change each month (subscribers_gained - subscribers_lost)
WITH months AS (
	SELECT generate_series(
		DATE '2025-01-01',
		DATE '2025-12-01',
		INTERVAL '1 month'
	) AS month_start
)

SELECT 
	months.month_start,
	COUNT(CASE
		WHEN started_date >= months.month_start 
		AND started_date < months.month_start + INTERVAL '1 month'
		THEN 1
	END) AS subscribers_gained,
	COUNT(CASE
		WHEN ended_date IS NOT NULL
		AND ended_date >= months.month_start
		AND ended_date < months.month_start + INTERVAL '1 month'
		THEN 1
	END) AS subscribers_lost,
	COUNT(CASE
		WHEN started_date >= months.month_start 
		AND started_date < months.month_start + INTERVAL '1 month'
		THEN 1
	END) - COUNT(CASE
		WHEN ended_date IS NOT NULL
		AND ended_date >= months.month_start
		AND ended_date < months.month_start + INTERVAL '1 month'
		THEN 1
	END) AS net_subscribers_change
FROM months
CROSS JOIN subscriptions
GROUP BY months.month_start
ORDER BY months.month_start;
	