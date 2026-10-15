SELECT
    raw_row_id,
    transaction_id,
    net_revenue

FROM {{ ref('int_sales_validated') }}

WHERE is_valid IS NOT TRUE
    AND net_revenue IS NOT NULL