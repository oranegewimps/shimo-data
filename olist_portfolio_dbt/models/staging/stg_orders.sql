-- 注文の基本情報。生データのカラム名を整理するのみで、加工・結合は行わない。
with source as (

    select * from {{ source('olist_raw', 'orders') }}

)

select
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp as order_purchase_ts,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date

from source
