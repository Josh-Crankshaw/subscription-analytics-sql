SELECT 
	DATE_TRUNC('month', payment_at) AS payment_month,
	SUM(CAST(amount AS DECIMAL(10, 2)))
FROM payments
WHERE payment_status = 'successful'

GROUP BY payment_month
ORDER BY payment_month