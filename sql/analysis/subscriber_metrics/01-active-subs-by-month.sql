WITH months AS (
    SELECT generate_series(
        '2025-01-01'::TIMESTAMPTZ,
        '2026-01-01'::TIMESTAMPTZ,
        INTERVAL '1 month'
    ) AS month_start
)
SELECT 
	month_start::DATE AS month,
	COUNT(subscriptions.subscription_id) AS active_subs
FROM months
LEFT JOIN subscriptions
ON 
	subscriptions.started_date < months.month_start + INTERVAL '1 month'
	AND (subscriptions.ended_date IS NULL OR subscriptions.ended_date >= months.month_start)

GROUP BY months.month_start
ORDER BY months.month_start