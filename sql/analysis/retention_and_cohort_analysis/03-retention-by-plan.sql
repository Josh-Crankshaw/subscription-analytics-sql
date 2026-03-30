/*
Query Name: Cohort Retention by Plan Type
Purpose: Measure monthly retention for each subscription cohort segmented by plan type.
Business Question: How does retention vary across different subscription plans over time?
Tables Used:
  - subscriptions
Key Columns Used:
  - subscription_id
  - plan_type
  - started_date
  - ended_date
Assumptions:
  - A cohort is defined by the month the subscription started
  - Each subscription belongs to a single plan type
  - A subscription is counted as retained if it was active at any point during the month
  - Retention rate = retained subscriptions / cohort size
Output:
  - cohort_month
  - plan_type
  - months_since
  - cohort_size
  - retained_subscriptions
  - retention_rate
*/

WITH subscription_cohorts AS (
    SELECT
        subscriptions.subscription_id,
        subscriptions.plan_type,
        DATE_TRUNC('month', subscriptions.started_date) AS cohort_month,
        subscriptions.started_date,
        subscriptions.ended_date
    FROM subscriptions
),

months AS (
    SELECT
        generate_series(
            '2025-01-01'::TIMESTAMPTZ,
            '2025-12-01'::TIMESTAMPTZ,
            INTERVAL '1 month'
        )::TIMESTAMPTZ AS month_start
),

cohort_sizes AS (
    SELECT
        subscription_cohorts.cohort_month,
        subscription_cohorts.plan_type,
        COUNT(*) AS cohort_size
    FROM subscription_cohorts
    GROUP BY
        subscription_cohorts.cohort_month,
        subscription_cohorts.plan_type
),

cohort_retention AS (
    SELECT
        subscription_cohorts.cohort_month,
        subscription_cohorts.plan_type,
        months.month_start,
        (
            (DATE_PART('year', months.month_start) - DATE_PART('year', subscription_cohorts.cohort_month)) * 12
            + (DATE_PART('month', months.month_start) - DATE_PART('month', subscription_cohorts.cohort_month))
        )::INT AS months_since,
        COUNT(*) AS retained_subscriptions
    FROM subscription_cohorts
    JOIN months
        ON months.month_start >= subscription_cohorts.cohort_month
       AND subscription_cohorts.started_date < months.month_start + INTERVAL '1 month'
       AND (
            subscription_cohorts.ended_date IS NULL
            OR subscription_cohorts.ended_date >= months.month_start
       )
    GROUP BY
        subscription_cohorts.cohort_month,
        subscription_cohorts.plan_type,
        months.month_start
)

SELECT
    cohort_retention.cohort_month,
    cohort_retention.plan_type,
    cohort_retention.months_since,
    cohort_sizes.cohort_size,
    cohort_retention.retained_subscriptions,
    ROUND(
        cohort_retention.retained_subscriptions::NUMERIC / cohort_sizes.cohort_size,
        4
    ) AS retention_rate
FROM cohort_retention
JOIN cohort_sizes
    ON cohort_retention.cohort_month = cohort_sizes.cohort_month
   AND cohort_retention.plan_type = cohort_sizes.plan_type
WHERE cohort_retention.months_since BETWEEN 0 AND 11
ORDER BY
    cohort_retention.cohort_month,
    cohort_retention.plan_type,
    cohort_retention.months_since;