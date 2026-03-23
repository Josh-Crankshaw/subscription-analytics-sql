-- Calculate the overall cancellation rate of subscriptions based on their acquisition channel
-- Outputs: acquisition channel, total subscriptions, active subscriptions, cancelled subscriptions,
-- and cancellation rate
SELECT 
	acquisition_channel,
	COUNT(*) AS total_subs,
	COUNT(*) FILTER (
		WHERE sub_status = 'active'
	) AS active_subs,
	COUNT(*) FILTER (
		WHERE sub_status = 'cancelled'
	) AS cancelled_subs,
	(COUNT(*) FILTER (WHERE sub_status = 'cancelled')::NUMERIC / COUNT(*))::DECIMAL(10,3) AS cancellation_rate
FROM customers
INNER JOIN subscriptions
ON customers.customer_id = subscriptions.customer_id
GROUP BY acquisition_channel