SELECT 
	plan_type, 
	COUNT(*) AS total_payments,
	COUNT(*) FILTER (WHERE payment_status = 'successful') AS total_successful,
	COUNT(*) FILTER (WHERE payment_status = 'failed') AS total_failed,
	(COUNT(*) FILTER (WHERE payment_status = 'successful')::decimal(10,4) / COUNT(*))::decimal(10,4)
FROM subscriptions
JOIN payments
ON subscriptions.subscription_id = payments.subscription_id

GROUP BY plan_type