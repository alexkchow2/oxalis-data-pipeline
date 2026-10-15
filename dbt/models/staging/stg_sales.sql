SELECT
    raw_row_id,
    transaction_id,
        CASE
        -- Year-first: 2023-01-15, 2023/01/17, 2023-1-31
        WHEN trim(transaction_date) ~ '^[0-9]{4}[-/][0-9]{1,2}[-/][0-9]{1,2}$'
        THEN to_date(
            replace(trim(transaction_date), '/', '-'),
            'YYYY-MM-DD'
        )

        -- European dates using dots: 29.01.2023
        WHEN trim(transaction_date) ~ '^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}$'
        THEN to_date(trim(transaction_date), 'DD.MM.YYYY')

        -- Dates with month names: 26-Jan-23
        WHEN trim(transaction_date) ~ '^[0-9]{1,2}-[A-Za-z]{3}-[0-9]{2}$'
        THEN to_date(trim(transaction_date), 'DD-Mon-YY')

        -- Hyphenated numeric dates: 22-01-2023 or 01-18-2023
        WHEN trim(transaction_date) ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$'
        THEN CASE
            WHEN split_part(transaction_date, '-', 1)::INTEGER > 12
                THEN to_date(trim(transaction_date), 'DD-MM-YYYY')
            ELSE CASE
                WHEN split_part(transaction_date, '-', 2)::INTEGER > 12
                    THEN to_date(trim(transaction_date), 'MM-DD-YYYY')
                ELSE to_date(trim(transaction_date), 'DD-MM-YYYY')
            END
        END

        -- Slash-separated dates: 1/16/2023 or 16/02/2023
        WHEN trim(transaction_date) ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}$'
        THEN CASE
            WHEN length(split_part(trim(transaction_date), '/', 3)) = 2
                THEN to_date(trim(transaction_date), 'MM/DD/YY')
            WHEN split_part(transaction_date, '/', 1)::INTEGER > 12
                THEN to_date(trim(transaction_date), 'DD/MM/YYYY')
            WHEN split_part(transaction_date, '/', 2)::INTEGER > 12
                THEN to_date(trim(transaction_date), 'MM/DD/YYYY')
            ELSE to_date(trim(transaction_date), 'MM/DD/YYYY')
        END

        ELSE NULL
    END AS transaction_date,
    CASE
        WHEN TRIM(transaction_date) ~ '^[0-9]{1,2}[-/][0-9]{1,2}[-/][0-9]{2,4}$'
            AND SPLIT_PART(REPLACE(TRIM(transaction_date), '-', '/'), '/', 1)::INTEGER BETWEEN 1 AND 12
            AND SPLIT_PART(REPLACE(TRIM(transaction_date), '-', '/'), '/', 2)::INTEGER BETWEEN 1 AND 12
            AND SPLIT_PART(REPLACE(TRIM(transaction_date), '-', '/'), '/', 1)::INTEGER
                <> SPLIT_PART(REPLACE(TRIM(transaction_date), '-', '/'), '/', 2)::INTEGER
        THEN TRUE
        ELSE FALSE
    END AS date_is_ambiguous,
    CASE
        WHEN regexp_replace(upper(trim(store_id)), '[^0-9]', '', 'g') <> ''
        THEN 'STORE_' || lpad(
            regexp_replace(upper(trim(store_id)), '[^0-9]', '', 'g'),
            3,
            '0'
        )
        ELSE NULL
    END AS store_id,
    INITCAP(NULLIF(TRIM(region), '')) AS region,
    NULLIF(TRIM(product_name), '') AS product_name,
    CASE
        WHEN trim(quantity) ~ '^[0-9]{1,9}$'
        THEN trim(quantity)::INTEGER
        ELSE NULL
    END AS quantity,
    CASE
        WHEN trim(replace(unit_price, '$', '')) ~ '^[0-9]+(\.[0-9]{1,2})?$'
        THEN trim(replace(unit_price, '$', ''))::NUMERIC(12,2)
        ELSE NULL
    END AS unit_price,
        CASE
        WHEN trim(discount) ~ '^[0-9]+(\.[0-9]+)?%$'
            AND replace(trim(discount), '%', '')::NUMERIC BETWEEN 0 AND 100
        THEN (replace(trim(discount), '%', '')::NUMERIC / 100)::NUMERIC(5,4)

        WHEN trim(discount) ~ '^[0-9]+(\.[0-9]+)?$'
            AND trim(discount)::NUMERIC BETWEEN 0 AND 1
        THEN trim(discount)::NUMERIC(5,4)

        WHEN trim(discount) ~ '^[0-9]+(\.[0-9]+)?$'
            AND trim(discount)::NUMERIC > 1
            AND trim(discount)::NUMERIC <= 100
        THEN (trim(discount)::NUMERIC / 100)::NUMERIC(5,4)

        ELSE NULL
    END AS discount,
    CASE
        WHEN nullif(trim(payment_method), '') IS NULL THEN NULL
        WHEN upper(trim(payment_method)) IN ('DEBIT', 'DEBIT CARD')
            THEN 'Debit Card'
        WHEN upper(trim(payment_method)) IN ('CREDIT', 'CREDIT CARD')
            THEN 'Credit Card'
        WHEN upper(trim(payment_method)) = 'CASH'
            THEN 'Cash'
        WHEN upper(trim(payment_method)) = 'APPLE PAY'
            THEN 'Apple Pay'
        ELSE trim(payment_method)
    END AS payment_method,
    CASE
        WHEN nullif(trim(customer_type), '') IS NULL THEN NULL
        WHEN upper(trim(customer_type)) IN ('REGULAR', 'REGULARCUSTOMER')
            THEN 'Regular'
        WHEN upper(trim(customer_type)) = 'PREMIUM'
            THEN 'Premium'
        WHEN upper(trim(customer_type)) = 'PREMIER'
            THEN 'Premier'
        ELSE trim(customer_type)
    END AS customer_type,
    source_file,
    loaded_at
FROM {{ source('raw', 'raw_sales') }}