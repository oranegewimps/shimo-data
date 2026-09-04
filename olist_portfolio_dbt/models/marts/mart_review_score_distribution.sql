-- ①現状把握: レビュースコア(1〜5)の件数・構成比。J字型分布の可視化に使用。
with reviews as (

    select review_score
    from {{ ref('stg_order_reviews') }}
    where review_score is not null

),

total as (

    select count(*) as total_count from reviews

)

select
    r.review_score,
    count(*) as review_count,
    round(safe_divide(count(*), t.total_count), 4) as pct_of_total

from reviews r
cross join total t
group by r.review_score, t.total_count
order by r.review_score
