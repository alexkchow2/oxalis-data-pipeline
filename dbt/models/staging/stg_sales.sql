SELECT
    raw_row_id,
    transaction_id,
    transaction_date,
    store_id,
    region,
    product_name,
    quantity,
    unit_price,
    discount,
    payment_method,
    customer_type,
    source_file,
    loaded_at
FROM {{ source('raw', 'raw_sales') }}