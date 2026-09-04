-- 顧客情報。
-- customer_id は「注文ごとに発行されるID」であり、customer_unique_id が
-- 「同一人物を横断して識別するID」。リピート分析には必ず customer_unique_id を使うこと。
with source as (

    select * from {{ source('olist_raw', 'customers') }}

)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state

from source
