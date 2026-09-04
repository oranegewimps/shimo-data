-- ①現状把握: 商品カテゴリ(英語名)別のGMV・注文件数・構成比。
with items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

translation as (

    select * from {{ ref('stg_product_category_translation') }}

),

joined as (

    select
        i.order_id,
        i.order_item_id,
        i.price,
        coalesce(
            t.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) as category

    from items i
    left join products p on i.product_id = p.product_id
    left join translation t on p.product_category_name = t.product_category_name

),

total as (

    select sum(price) as total_gmv from joined

)

select
    j.category,
    count(distinct j.order_id) as order_count,
    round(sum(j.price), 2) as gmv,
    round(safe_divide(sum(j.price), t.total_gmv), 4) as pct_of_total_gmv

from joined j
cross join total t
group by j.category, t.total_gmv
order by gmv desc
