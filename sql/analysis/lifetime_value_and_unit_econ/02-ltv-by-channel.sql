--  Calculates the total revenue of all customers acquired through each marketing channel
SELECT acquisition_channel, SUM(amount::decimal(10,1)) FROM customers
JOIN subscriptions
ON customers.customer_id = subscriptions.customer_id
JOIN payments
ON subscriptions.subscription_id = payments.subscription_id
WHERE payment_status = 'successful'
GROUP BY acquisition_channel
ORDER BY SUM(amount::decimal(10,1)) desc