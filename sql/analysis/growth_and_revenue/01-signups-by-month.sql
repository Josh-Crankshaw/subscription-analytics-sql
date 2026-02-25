SELECT EXTRACT(MONTH FROM started_date) AS month, count(*) FROM subscriptions
GROUP BY month
ORDER BY month