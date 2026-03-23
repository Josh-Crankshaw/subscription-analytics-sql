-- Calculate and output the overall cancellation rate by plan type
-- Outputs: Plan types, total subscriptions in each plan, number of active users with each subscription,
-- the number of cancelled subscriptions with each plan type, and the correlating cancellation rates
SELECT
	plan_type,
	COUNT(*) AS total_in_plan,
	COUNT(*) FILTER (WHERE sub_status = 'active') AS active_subs,
	COUNT(*) FILTER (WHERE sub_status = 'cancelled') AS cancelled_subs,
	((COUNT(*) FILTER (WHERE sub_status = 'cancelled'))::NUMERIC / COUNT(*))::DECIMAL(10,4) AS cancellation_rate
FROM subscriptions
GROUP BY plan_type