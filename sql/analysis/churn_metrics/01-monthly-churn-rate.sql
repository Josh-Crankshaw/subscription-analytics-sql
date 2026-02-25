WITH months AS (
    SELECT generate_series(
        '2025-01-01'::timestamptz,
        '2025-12-01'::timestamptz,
        interval '1 month'
    ) AS month_start
)

SELECT
    months.month_start,
    COUNT(CASE 
		WHEN started_date < months.month_start
		AND (ended_date IS NULL OR ended_date >= months.month_start)
		THEN 1 
	END) AS active_at_start,
    COUNT(CASE 
		WHEN ended_date >= months.month_start
		AND ended_date < months.month_start + interval '1 month' 
		THEN 1 
	END) AS churned_in_month
FROM months
LEFT JOIN subscriptions
    ON (subscriptions.started_date < months.month_start + interval '1 month')
GROUP BY months.month_start
ORDER BY months.month_start;