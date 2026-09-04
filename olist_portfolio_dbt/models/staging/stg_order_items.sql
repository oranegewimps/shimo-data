-- 注文明細。1注文に複数商品が含まれる場合は複数行になる。
with source as (

    select * from {{ source('olist_raw', 'order_items') }}

)

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value

from source
