SELECT 
	COUNT(DISTINCT(subscription_id)) AS customers,
	(SUM(amount::decimal(10,4)))::decimal(10,1) AS total_spent,
	((SUM(amount::decimal(10,4)))::decimal(10,1) / COUNT(DISTINCT(subscription_id)))::decimal(10,4) AS average_spent
FROM payments
WHERE payment_status = 'successful'