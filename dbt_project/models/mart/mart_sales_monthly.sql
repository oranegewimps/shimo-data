with stg as (
    select * from {{ ref('stg_sales') }}
)

select
    format_date('%Y-%m', order_date)  as year_month,
    product,
    count(order_id)                   as order_count,
    sum(amount)                       as total_amount,
    sum(cost)                         as total_cost,
    sum(gross_profit)                 as total_gross_profit
from stg
group by 1, 2
order by 1, 2