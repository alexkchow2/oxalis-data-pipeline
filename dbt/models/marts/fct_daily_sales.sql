SELECT
    transaction_date,
    store_id,
    COUNT(*) AS transaction_count,
    SUM(quantity) AS units_sold,
    SUM(net_revenue) AS net_revenue

FROM {{ ref('int_sales_validated') }}

WHERE is_valid = TRUE

GROUP BY
    transaction_date,
    store_id