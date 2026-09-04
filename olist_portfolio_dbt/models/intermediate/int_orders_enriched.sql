-- 注文(order_id)を軸に、顧客・金額(GMV)・配送遅延・レビュースコアを
-- 1行に結合した分析用の中核ファクトテーブル。mart層の全テーブルはここから派生する。
--
-- 配送遅延の定義:
--   order_status = 'delivered' かつ 実配送日 > 予定配送日 の場合に true。
--   'delivered' 以外のステータスは判定不能として null にする(false にはしない)。
with orders as (

    select * from {{ ref('stg_orders') }}

),

items_agg as (

    select * from {{ ref('int_order_items_agg') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

reviews as (

    select * from {{ ref('stg_order_reviews') }}

)

select
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    o.order_purchase_ts,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    date_diff(
        date(o.order_delivered_customer_date),
        date(o.order_estimated_delivery_date),
        day
    ) as delivery_delay_days,

    case
        when o.order_status != 'delivered' then null
        when o.order_delivered_customer_date > o.order_estimated_delivery_date then true
        else false
    end as is_late_delivery,

    coalesce(i.item_count, 0) as item_count,
    coalesce(i.gmv, 0) as gmv,
    coalesce(i.freight_total, 0) as freight_total,
    r.review_score

from orders o
left join items_agg i on o.order_id = i.order_id
left join customers c on o.customer_id = c.customer_id
left join reviews r on o.order_id = r.order_id
