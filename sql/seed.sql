COPY customers FROM 'full/path/to/subscription-analytics-sql/data_generation/data/customers.csv' DELIMITER ',' CSV HEADER;
COPY subscriptions FROM 'full/path/to/subscription-analytics-sql/data_generation/data/subscriptions.csv' DELIMITER ',' CSV HEADER;
COPY payments FROM 'full/path/to/subscription-analytics-sql/data_generation/data/payments.csv' DELIMITER ',' CSV HEADER;