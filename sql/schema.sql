CREATE TABLE customers(
    customer_id SERIAL PRIMARY KEY,
    signup_date DATE NOT NULL,
    country VARCHAR(100),
    acquisition_channel VARCHAR(100)
);
CREATE TABLE subscriptions(
    subscription_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    plan_type VARCHAR(50),
    started_date TIMESTAMPTZ,
    ended_date TIMESTAMPTZ,
    billing_cycle VARCHAR(50),
    sub_status VARCHAR(50),
    monthly_price NUMERIC(10,2)
);
CREATE TABLE payments(
    payment_id SERIAL PRIMARY KEY,
    subscription_id INT REFERENCES subscriptions(subscription_id),
    payment_at TIMESTAMPTZ,
    payment_status VARCHAR(50),
    amount NUMERIC(10,2)	
);