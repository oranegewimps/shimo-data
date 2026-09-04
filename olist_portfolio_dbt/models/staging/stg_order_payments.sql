-- 決済情報。1注文が複数回の決済に分かれるケースがある(payment_sequential)。
with source as (

    select * from {{ source('olist_raw', 'order_payments') }}

)

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value

from source
