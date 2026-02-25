SELECT 
	payment_status, 
	SUM(amount::decimal(10,4)) AS lost_income
FROM payments

WHERE payment_status = 'failed'
GROUP BY payment_status