with source as (
    select * from {{ ref('raw_deals') }}
),

cleaned as (
    select
        deal_id,
        customer_name,
        sales_rep_id,
        phase,
        cast(amount as integer)                     as amount,
        cast(probability as integer)                as probability,
        created_date,
        closed_date,
        case
            when result is null then null
            else result
        end                                         as result
    from source
)

select
    deal_id,
    customer_name,
    sales_rep_id,
    phase,
    amount,
    probability,
    created_date,
    closed_date,
    result,
    case
        when result = '受注' then 1
        else 0
    end                                             as is_won,
    case
        when closed_date is not null then
            date_diff(cast(closed_date as date), cast(created_date as date), DAY)
        else null
    end                                             as lead_time_days
from cleaned