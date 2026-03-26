with deals as (
    select * from {{ ref('stg_deals') }}
),

reps as (
    select * from {{ ref('raw_sales_reps') }}
)

select
    r.sales_rep_id,
    r.sales_rep_name,
    r.team,
    r.target_amount,
    count(d.deal_id)                                                    as total_deals,
    sum(d.is_won)                                                       as won_deals,
    sum(case when d.result = cast('失注' as varchar) then 1 else 0 end) as lost_deals,
    sum(case when d.result is null then 1 else 0 end)                   as active_deals,
    sum(case when d.is_won = 1 then d.amount else 0 end)                as won_amount,
    round(avg(case when d.is_won = 1 then d.lead_time_days end), 1)     as avg_lead_time_days,
    round(sum(d.is_won) * 100.0 / count(d.deal_id), 1)                 as win_rate_pct,
    round(
        sum(case when d.is_won = 1 then d.amount else 0 end) * 100.0
        / r.target_amount
    , 1)                                                                as target_achievement_pct
from reps r
left join deals d
    on r.sales_rep_id = d.sales_rep_id
group by 1, 2, 3, 4
order by won_amount desc