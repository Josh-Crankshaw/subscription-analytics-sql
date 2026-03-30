/*
Query Name: Monthly Payment Failure Rate
Purpose: Calculate the proportion of payment attempts that failed in each month.
Business Question: How does payment failure rate change over time?
Tables Used:
  - payments
Key Columns Used:
  - payment_at
  - payment_status
Assumptions:
  - Each row represents one payment attempt
  - Payment statuses include 'successful' and 'failed'
  - Failure rate = failed payments / total payment attempts
Output:
  - month_start
  - month_name
  - total_payments
  - successful_payments
  - failed_payments
  - failure_rate
*/

SELECT
    DATE_TRUNC('month', payments.payment_at) AS month_start,
    TRIM(TO_CHAR(DATE_TRUNC('month', payments.payment_at), 'Month')) AS month_name,
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (WHERE payments.payment_status = 'successful') AS successful_payments,
    COUNT(*) FILTER (WHERE payments.payment_status = 'failed') AS failed_payments,
    ROUND(
        COUNT(*) FILTER (WHERE payments.payment_status = 'failed')::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS failure_rate
FROM payments
GROUP BY DATE_TRUNC('month', payments.payment_at)
ORDER BY month_start;