-- Find the number of subscribers by plan type
SELECT 
	plan_type,
	COUNT(plan_type) AS number_of_subscrbers,
	(COUNT(plan_type)::DECIMAL(10,3) / 1000)::DECIMAL(10,3) AS ratio
FROM subscriptions
GROUP BY plan_type