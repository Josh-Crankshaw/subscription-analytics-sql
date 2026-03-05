--  Calculates the total revenue brought in through each plan type
SELECT plan_type, SUM(amount::decimal(10,1)) FROM customers
JOIN subscriptions
ON customers.customer_id = subscriptions.customer_id
JOIN payments
ON subscriptions.subscription_id = payments.subscription_id
WHERE payment_status = 'successful'
GROUP BY plan_type
ORDER BY SUM(amount::decimal(10,1)) desc