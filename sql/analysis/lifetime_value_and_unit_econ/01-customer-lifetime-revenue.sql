-- Calculates the total amount each customer has spent by summing the value of all successful payment made
SELECT subscriptions.subscription_id, SUM(amount::decimal(10,1)) FROM payments
JOIN subscriptions
ON subscriptions.subscription_id = payments.subscription_id
WHERE payment_status = 'successful'
GROUP BY subscriptions.subscription_id
ORDER BY subscriptions.subscription_id