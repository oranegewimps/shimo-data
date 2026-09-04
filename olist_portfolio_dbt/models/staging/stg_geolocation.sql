-- 郵便番号(先頭5桁)ごとの緯度経度。
-- 生データは同一 zip_code_prefix に対して複数レコードが存在する(測位のばらつき等)ため、
-- zip_code_prefix 単位で緯度経度を平均集約し、1行1zipに正規化する。
with source as (

    select * from {{ source('olist_raw', 'geolocation') }}

)

select
    geolocation_zip_code_prefix as zip_code_prefix,
    avg(geolocation_lat) as lat,
    avg(geolocation_lng) as lng,
    any_value(geolocation_city) as city,
    any_value(geolocation_state) as state

from source
group by geolocation_zip_code_prefix
