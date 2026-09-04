-- 郵便番号別緯度経度の生データをそのまま通すステージング。
-- 同一 zip_code_prefix に複数レコードが存在するが、粒度はここでは維持する。
-- 集約(zip_code_prefix単位への正規化)は int_geolocation で行う。
with source as (

    select * from {{ source('olist_raw', 'geolocation') }}

)

select
    geolocation_zip_code_prefix as zip_code_prefix,
    geolocation_lat             as lat,
    geolocation_lng             as lng,
    geolocation_city            as city,
    geolocation_state           as state

from source
