SELECT 
	COUNT(*) as total_subs,
	COUNT(*) FILTER (WHERE sub_status = 'active') AS active_subs,
	COUNT(*) FILTER (WHERE sub_status = 'cancelled') AS cancelled_subs,
	((COUNT(*) FILTER (WHERE sub_status = 'cancelled'))::decimal(10,4) / COUNT(*))::decimal(10,4) AS yearly_churn_rate
FROM subscriptions