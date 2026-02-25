SELECT 
	acquisition_channel, 
	(SUM(amount::decimal(10,4)))::decimal(10,1) AS total_revenue
FROM customers
JOIN subscriptions
ON customers.customer_id = subscriptions.customer_id
JOIN payments
ON subscriptions.subscription_id = payments.subscription_id

WHERE payment_status = 'successful'
GROUP BY acquisition_channel
ORDER BY total_revenue DESC