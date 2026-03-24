with source as (
    select * from {{ ref('raw_sales') }}
)

select
    order_id,
    cast(order_date as date)  as order_date,
    customer_id,
    product,
    amount,
    cost,
    amount - cost             as gross_profit
from source