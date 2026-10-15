SELECT
    transaction_date,
    store_id,
    COUNT(*) AS occurrences

FROM {{ ref('fct_daily_sales') }}

GROUP BY
    transaction_date,
    store_id

HAVING COUNT(*) > 1