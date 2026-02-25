SELECT 
	COUNT(*) AS total_payments,
	COUNT(*) FILTER (WHERE payment_status = 'successful') AS successful_payments,
	COUNT(*) FILTER (WHERE payment_status = 'failed') AS failed_payments,
	(COUNT(*) FILTER (WHERE payment_status = 'successful')::decimal(10,2) / COUNT(*))::decimal(10,4) AS success_rate
FROM payments