/*
===============================================================================
Customer Churn Feature Engineering Query
===============================================================================

Purpose:
This query transforms raw subscription and payment data into a customer-level
feature table suitable for predictive analytics and machine learning workflows.

The resulting dataset aggregates customer subscription behaviour, payment
activity, and churn status into a structured format that can be used for
customer churn prediction and exploratory data analysis.

Key Features Generated:
- Total revenue per customer
- Total payment count
- Successful payment count
- Failed payment count
- Subscription duration (days)
- Billing cycle and plan type
- Binary churn target variable

Data Sources:
- customers
- subscriptions
- payments

Techniques Used:
- Table joins
- Aggregations
- FILTER clauses
- CASE statements
- Date/time calculations
- Feature engineering

Machine Learning Context:
The generated output is designed to support downstream Python and scikit-learn
workflows, including classification modelling, churn prediction, and customer
behaviour analysis.

Author: Josh Crankshaw
===============================================================================
*/
SELECT 
	c.customer_id,
	s.plan_type,
	s.billing_cycle,
	SUM(p.amount::NUMERIC) as total_revenue,
	
	COUNT(p.payment_id) AS total_payments,

	COUNT(p.payment_id) FILTER(
		WHERE p.payment_status = 'successful'
		) AS successful_payments,

	COUNT(p.payment_id) FILTER(
		WHERE p.payment_status = 'failed'
		) AS failed_payments,

	started_date,
	ended_date,
	
	EXTRACT(
		DAY FROM (
			COALESCE(s.ended_date, TIMESTAMPTZ '2025-12-31 23:59:59+13') 
			- s.started_date
		)
	) AS subscription_length_days,
	
	CASE 
		WHEN s.sub_status = 'active' THEN 0
		WHEN s.sub_status = 'cancelled' THEN 1
	END AS churned
	
FROM customers c
JOIN subscriptions s
ON s.customer_id = c.customer_id
JOIN payments p
ON p.subscription_id = s.subscription_id

GROUP BY
    c.customer_id,
    s.plan_type,
    s.billing_cycle,
    s.started_date,
    s.ended_date,
	s.sub_status
ORDER BY c.customer_id