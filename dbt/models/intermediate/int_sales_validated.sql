WITH validated AS (

    SELECT
        raw_row_id,
        transaction_id,
        transaction_date,
        store_id,
        product_name,
        region,
        customer_type,
        payment_method,
        quantity,
        unit_price,
        discount,

        (
            NULLIF(TRIM(transaction_id), '') IS NOT NULL
            AND transaction_date IS NOT NULL
            AND date_is_ambiguous IS FALSE
            AND quantity > 0
            AND unit_price > 0
            AND discount BETWEEN 0 AND 1
        ) IS TRUE AS is_valid

    FROM {{ ref('stg_sales') }}

)

SELECT
    *,
    CASE
        WHEN is_valid
        THEN ROUND(quantity * unit_price * (1 - discount), 2)
        ELSE NULL
    END AS net_revenue

FROM validated