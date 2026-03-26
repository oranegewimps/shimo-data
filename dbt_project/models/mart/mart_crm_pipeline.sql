with deals as (
    select * from {{ ref('stg_deals') }}
),

reps as (
    select * from {{ ref('raw_sales_reps') }}
)

select
    d.phase,
    d.sales_rep_id,
    r.sales_rep_name,
    r.team,
    count(d.deal_id)                    as deal_count,
    sum(d.amount)                       as total_amount,
    sum(d.amount * d.probability / 100) as weighted_amount
from deals d
left join reps r
    on d.sales_rep_id = r.sales_rep_id
group by 1, 2, 3, 4
order by 1, 2