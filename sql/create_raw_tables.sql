CREATE TABLE IF NOT EXISTS raw_sales (
    raw_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id TEXT,
    transaction_date TEXT,
    store_id TEXT,
    region TEXT,
    product_name TEXT,
    quantity TEXT,
    unit_price TEXT,
    discount TEXT,
    payment_method TEXT,
    customer_type TEXT,
    source_file TEXT,
    loaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);