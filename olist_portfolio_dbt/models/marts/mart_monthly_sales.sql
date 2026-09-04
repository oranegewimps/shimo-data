-- ①現状把握: 月次のGMV・注文件数・AOV・購入顧客数の推移。
-- キャンセル等を除いた「配送完了(delivered)」注文のみを対象とする。
with orders as (

    select * from {{ ref('int_orders_enriched') }}
    where order_status = 'delivered'

)

select
    date_trunc(date(order_purchase_ts), month) as order_month,
    count(distinct order_id) as order_count,
    count(distinct customer_unique_id) as customer_count,
    round(sum(gmv), 2) as gmv,
    round(safe_divide(sum(gmv), count(distinct order_id)), 2) as aov

from orders
group by order_month
order by order_month
