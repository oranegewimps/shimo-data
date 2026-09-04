-- ①現状把握: 州(customer_state)別の配送遅延率・平均レビュースコア・代表緯度経度。
-- 地図表示用の緯度経度は customers → geolocation(zip_code_prefix)経由で州単位に平均。
with orders as (

    select * from {{ ref('int_orders_enriched') }}
    where order_status = 'delivered'

),

state_metrics as (

    select
        customer_state,
        count(distinct order_id) as order_count,
        countif(is_late_delivery) as late_order_count,
        round(safe_divide(countif(is_late_delivery), count(distinct order_id)), 4) as delay_rate,
        round(avg(review_score), 2) as avg_review_score

    from orders
    group by customer_state

),

customers as (

    select * from {{ ref('stg_customers') }}

),

geo as (

    select * from {{ ref('stg_geolocation') }}

),

state_geo as (

    select
        c.customer_state,
        avg(g.lat) as state_lat,
        avg(g.lng) as state_lng

    from customers c
    left join geo g on c.customer_zip_code_prefix = g.zip_code_prefix
    group by c.customer_state

)

select
    m.customer_state as state,
    m.order_count,
    m.late_order_count,
    m.delay_rate,
    m.avg_review_score,
    g.state_lat,
    g.state_lng

from state_metrics m
left join state_geo g on m.customer_state = g.customer_state
order by m.order_count desc
