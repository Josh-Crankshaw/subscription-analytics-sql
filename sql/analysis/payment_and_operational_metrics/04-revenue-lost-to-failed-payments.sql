/*
Query Name: Revenue Lost to Failed Payments
Purpose: Calculate the total value of payments that failed and were not successfully processed.
Business Question: How much potential revenue was lost due to failed payment attempts?
Tables Used:
  - payments
Key Columns Used:
  - amount
  - payment_status
Assumptions:
  - Failed payments represent unrealised revenue
  - Only payments with status 'failed' are included
Output:
  - revenue_lost
*/

SELECT
    ROUND(SUM(payments.amount::NUMERIC), 1) AS revenue_lost
FROM payments
WHERE payments.payment_status = 'failed';