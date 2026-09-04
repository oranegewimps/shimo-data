-- 商品カテゴリ名のポルトガル語→英語 対応表。
with source as (

    select * from {{ source('olist_raw', 'product_category_name_translation') }}

)

select
    product_category_name,
    product_category_name_english

from source
