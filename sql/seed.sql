COPY customers FROM 'full/path/to/subscription-analytics-sql/data/customers.csv' DELIMITER ',' CSV HEADER;
COPY subscriptions FROM 'full/path/to/subscription-analytics-sql/data/subscriptions.csv' DELIMITER ',' CSV HEADER;
COPY payments FROM 'full/path/to/subscription-analytics-sql/data/payments.csv' DELIMITER ',' CSV HEADER;