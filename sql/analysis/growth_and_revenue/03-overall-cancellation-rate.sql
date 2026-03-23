SELECT 
	COUNT(*) as total_subs,
	COUNT(*) FILTER (WHERE sub_status = 'active') AS active_subs,
	COUNT(*) FILTER (WHERE sub_status = 'cancelled') AS cancelled_subs,
	((COUNT(*) FILTER (WHERE sub_status = 'cancelled'))::decimal(10,3) / COUNT(*))::decimal(10,3) AS cancellation_rate
FROM subscriptions