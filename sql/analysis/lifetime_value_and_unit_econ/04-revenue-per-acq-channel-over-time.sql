--Calculates the revenue earned in each month through customers based on the channel they were acquired through
SELECT
	DATE_TRUNC('month', payment_at) AS month,
	acquisition_channel,
	SUM(amount::decimal(10, 1)) as total_revenue
FROM customers
JOIN subscriptions
ON customers.customer_id = subscriptions.customer_id
Join payments 
ON subscriptions.subscription_id = payments.subscription_id
WHERE payment_status = 'successful'
GROUP BY 
	month,
	acquisition_channel
ORDER BY 
	month,
	acquisition_channel