/*
Query Name: Signups by Month
Purpose: Count the number of subscription signups in each month of 2025.
Business Question: How many new subscriptions were started each month?
Tables Used:
  - subscriptions
Key Columns Used:
  - started_date
Assumptions:
  - A signup is counted in the month the subscription started.
Output:
  - month_number: Numeric month of subscription start
  - month_name: Calendar month name
  - total_signups: Number of subscriptions started in that month
*/

SELECT
    EXTRACT(MONTH FROM started_date) AS month_number,
    TRIM(TO_CHAR(started_date, 'Month')) AS month_name,
    COUNT(*) AS total_signups
FROM subscriptions
GROUP BY
    EXTRACT(MONTH FROM started_date),
    TRIM(TO_CHAR(started_date, 'Month'))
ORDER BY month_number;