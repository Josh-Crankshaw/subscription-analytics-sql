/*
Query Name: Monthly Revenue
Purpose: Calculate total revenue collected per month from successful payments.
Business Question: How does revenue change over time across the year?
Tables Used:
  - payments
Key Columns Used:
  - payment_at
  - amount
  - payment_status
Assumptions:
  - Only successful payments contribute to revenue
  - Revenue is recognised at the time of payment (cash basis)
  - Amount values are stored as text and cast to numeric
Output:
  - month_start: First day of the month
  - total_revenue: Total revenue collected in that month
*/

SELECT
    DATE_TRUNC('month', payment_at) AS month_start,
    TRIM(TO_CHAR(DATE_TRUNC('month', payment_at), 'Month')) AS month_name,
    SUM(amount::NUMERIC) AS total_revenue
FROM payments
WHERE payment_status = 'successful'
GROUP BY
    DATE_TRUNC('month', payment_at)
ORDER BY month_start;
