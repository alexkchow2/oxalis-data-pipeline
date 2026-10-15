WITH intermediate_totals AS (
    SELECT
        SUM(net_revenue) AS total_revenue
    FROM {{ ref('int_sales_validated') }}
    WHERE is_valid = TRUE
),

mart_totals AS (
    SELECT
        SUM(net_revenue) AS total_revenue
    FROM {{ ref('fct_daily_sales') }}
)

SELECT
    i.total_revenue AS intermediate_revenue,
    m.total_revenue AS mart_revenue

FROM intermediate_totals i
CROSS JOIN mart_totals m

WHERE i.total_revenue IS DISTINCT FROM m.total_revenue