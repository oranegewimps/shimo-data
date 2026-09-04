-- 商品マスタ。product_category_name は約610件欠損している(カテゴリ不明の商品)。
with source as (

    select * from {{ source('olist_raw', 'products') }}

)

select
    product_id,
    product_category_name,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm

from source
