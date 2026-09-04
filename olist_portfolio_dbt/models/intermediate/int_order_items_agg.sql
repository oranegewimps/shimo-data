-- 注文明細(order_items)を注文単位(order_id)に集計する。
-- 1注文に複数商品が含まれるケースがあるため、金額系のKPIはすべてこの粒度から作る。
with order_items as (

    select * from {{ ref('stg_order_items') }}

)

select
    order_id,
    count(distinct order_item_id) as item_count,
    sum(price) as gmv,
    sum(freight_value) as freight_total

from order_items
group by order_id
