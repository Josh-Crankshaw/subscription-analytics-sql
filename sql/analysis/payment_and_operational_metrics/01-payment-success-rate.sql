/*
Query Name: Payment Success Rate
Purpose: Calculate the overall proportion of payment attempts that were successful.
Business Question: What percentage of payment attempts were completed successfully?
Tables Used:
  - payments
Key Columns Used:
  - payment_status
Assumptions:
  - Each row represents one payment attempt
  - Payment statuses of interest are 'successful' and 'failed'
  - Success rate = successful payments / total payments
Output:
  - total_payments
  - successful_payments
  - failed_payments
  - success_rate
*/

SELECT
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (WHERE payment_status = 'successful') AS successful_payments,
    COUNT(*) FILTER (WHERE payment_status = 'failed') AS failed_payments,
    ROUND(
        COUNT(*) FILTER (WHERE payment_status = 'successful')::NUMERIC
        / NULLIF(COUNT(*), 0),
        4
    ) AS success_rate
FROM payments;