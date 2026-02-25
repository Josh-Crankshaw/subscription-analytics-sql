SELECT 
	plan_type,
	(SUM(amount::decimal(10,4)))::decimal(10,1) AS total_revenue
FROM subscriptions
JOIN payments
ON subscriptions.subscription_id = payments.subscription_id
WHERE payment_status = 'successful'
GROUP BY plan_type