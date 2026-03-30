/*
Query Name: Monthly Net Subscriber Growth
Purpose: Calculate the number of subscribers gained, lost, and the net change each month.
Business Question: Is the subscription base growing or shrinking over time?
Tables Used:
  - subscriptions
Key Columns Used:
  - started_date
  - ended_date
Assumptions:
  - A subscriber is counted as gained in the month their subscription starts
  - A subscriber is counted as lost in the month their subscription ends
Output:
  - month_start
  - subscribers_gained
  - subscribers_lost
  - net_subscriber_change
*/

WITH months AS (
    SELECT
        generate_series(
            DATE '2025-01-01',
            DATE '2025-12-01',
            INTERVAL '1 month'
        ) AS month_start
),

monthly_gains AS (
    SELECT
        months.month_start,
        COUNT(*) AS subscribers_gained
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.started_date >= months.month_start
       AND subscriptions.started_date < months.month_start + INTERVAL '1 month'
    GROUP BY months.month_start
),

monthly_losses AS (
    SELECT
        months.month_start,
        COUNT(*) AS subscribers_lost
    FROM months
    LEFT JOIN subscriptions
        ON subscriptions.ended_date IS NOT NULL
       AND subscriptions.ended_date >= months.month_start
       AND subscriptions.ended_date < months.month_start + INTERVAL '1 month'
    GROUP BY months.month_start
)

SELECT
    monthly_gains.month_start,
    monthly_gains.subscribers_gained,
    monthly_losses.subscribers_lost,
    monthly_gains.subscribers_gained - monthly_losses.subscribers_lost AS net_subscriber_change
FROM monthly_gains
JOIN monthly_losses
    ON monthly_gains.month_start = monthly_losses.month_start
ORDER BY monthly_gains.month_start;
	