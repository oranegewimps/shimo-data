-- 郵便番号(zip_code_prefix)単位で緯度経度を平均集約し、1行1zipに正規化する。
-- stg_geolocation は生データの粒度を保つ層のため、集約処理はここで行う。
with source as (

    select * from {{ ref('stg_geolocation') }}

)

select
    zip_code_prefix,
    avg(lat)         as lat,
    avg(lng)         as lng,
    any_value(city)  as city,
    any_value(state) as state

from source
group by zip_code_prefix
