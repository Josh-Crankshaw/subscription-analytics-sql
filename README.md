# Subscription Analytics Project

## Project Summary

This project simulates a subscription-based business and analyses key performance metrics including revenue, churn, retention, and growth using SQL and Power BI.

The sample data used to develop this project consists of 1,000 simulated customers, along with their subscription and payment details. A new sample of 1,000 customers can be generated using the `data_generator.py` file in the `python` folder of this repository.

The goal of this project was to build an end-to-end analytics workflow covering:
- data generation
- SQL-based metric development
- dashboard design
- business insight generation

## Key Metrics Analysed

- Monthly Recurring Revenue (MRR)
- Active Subscribers by Month
- Monthly Churn Rate
- 3-Month Rolling Churn Rate
- Payment Success Rate
- Plan-level performance
- Acquisition channel performance
- Cohort retention

## Tools Used

- SQL (PostgreSQL)
- pgAdmin
- Power BI Desktop
- Python
- Git Bash
- GitHub

---

# How to Run This Project

These instructions assume you already have the following installed:

- PostgreSQL (version 13 or later recommended)
- pgAdmin
- Power BI Desktop (Windows only)
- Python (optional, only required if generating a new dataset)

---

## 1. Clone the Repository

Open **Git Bash** and navigate to the folder where you want to store the projectand in bash type:
cd E:/your-folder-here


> Use forward slashes `/` in file paths (e.g. `E:/Projects`)

Then in bash run:
git clone https://github.com/Josh-Crankshaw/subscription-analytics-sql.git
cd subscription-analytics-sql


---

## 2. Generate Dataset (Optional)

If you want to generate a new dataset, in bash run:
python python/data_generator.py --seed 42 --outdir data


- Replace `42` with any integer between `0` and `4294967295`
- Using the same seed will always generate identical data
- The default dataset in this project was generated using seed `42`

---

## 3. Set Up PostgreSQL Database

### Step 1: Create the Database

Open **pgAdmin**:

1. Right click **Databases**
2. Click **Create → Database**
3. Name the database:
subscription_analysis


4. Click **Save**

---

### Step 2: Run Schema Script

1. Right click your new database
2. Select **Query Tool**
3. Press `Ctrl + O`
4. Open:
sql/schema.sql

5. Click **Execute**

This will create the required tables.

---

### Step 3: Load Data into Tables

After running the schema, paste the following into the Query Tool:
COPY customers FROM 'FULL_PATH/data/customers.csv' DELIMITER ',' CSV HEADER;
COPY subscriptions FROM 'FULL_PATH/data/subscriptions.csv' DELIMITER ',' CSV HEADER;
COPY payments FROM 'FULL_PATH/data/payments.csv' DELIMITER ',' CSV HEADER;

Replace `FULL_PATH` with your actual path.

Example:
COPY customers FROM 'E:/Projects/subscription-analytics-sql/data/customers.csv' DELIMITER ',' CSV HEADER;


> Important:
> - You must use the full absolute path
> - Use forward slashes `/`, not backslashes `\`

---

## 4. Run Analysis Queries

All SQL analysis queries are located in:
sql/analysis

They are grouped by topic.

Suggested order:

1. `growth_and_revenue`
2. `subscriber_metrics`
3. `churn_metrics`
4. `retention_and_cohort_analysis`
5. `lifetime_value_and_unit_econ`
6. `payment_and_operational_metrics`

---

## 5. Open Dashboard in Power BI

Navigate to:
Dashboard/Subscription-analytics-project.pbix


Open this file in **Power BI Desktop**.

---

## 6. Connect Power BI to PostgreSQL

If the dashboard is not already connected:

1. Go to **Home → Transform Data**
2. Click **New Source → More**
3. Select **PostgreSQL database**

Enter:

- **Server**: `localhost`
- **Database**: `subscription_analysis`

Then enter your PostgreSQL username and password.

---

## 7. Replace Existing Data Sources

After loading the tables:

You may see both old and new tables:

- `customers`, `subscriptions`, `payments` (old)
- `public customers`, `public subscriptions`, `public payments` (new)

### Step 1: Delete old tables

Delete:
customers
subscriptions
payments

---

### Step 2: Rename new tables

Rename:
public customers → customers
public subscriptions → subscriptions
public payments → payments


---

## 8. Rename Columns

To match the existing dashboard model, rename the following columns:

### Subscriptions

- `plan_type` → Plan Type  
- `billing_cycle` → Billing Cycle  
- `started_date` → Started Date  
- `ended_date` → Ended Date  
- `sub_status` → Subscription Status  

### Payments

- `payment_at` → Payment Date  
- `payment_status` → Payment Status  
- `amount` → Amount  

---

## 9. Apply Changes

Click "Close & Apply" and then refresh

---

## Updating the Dashboard

To use new data:

1. Regenerate dataset (Step 2)
2. Reload CSVs into PostgreSQL (Step 3)
3. Click **Refresh** in Power BI

The dashboard will update automatically.