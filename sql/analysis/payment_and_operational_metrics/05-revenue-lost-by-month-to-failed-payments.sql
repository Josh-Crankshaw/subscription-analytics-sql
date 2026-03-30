/*
Query Name: Monthly Revenue Lost to Failed Payments
Purpose: Calculate the total value of failed payments in each month.
Business Question: How much potential revenue is being lost over time due to failed payment attempts?
Tables Used:
  - payments
Key Columns Used:
  - payment_at
  - amount
  - payment_status
Assumptions:
  - Failed payments represent unrealised revenue
  - Revenue is calculated on a cash basis (attempted payment value)
Output:
  - month_start
  - month_name
  - revenue_lost
*/

SELECT
    DATE_TRUNC('month', payments.payment_at) AS month_start,
    TRIM(TO_CHAR(DATE_TRUNC('month', payments.payment_at), 'Month')) AS month_name,
    ROUND(SUM(payments.amount::NUMERIC), 1) AS revenue_lost
FROM payments
WHERE payments.payment_status = 'failed'
GROUP BY DATE_TRUNC('month', payments.payment_at)
ORDER BY month_start;