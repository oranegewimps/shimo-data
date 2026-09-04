-- レビュー情報。
-- 生データには同一order_idに対して複数レビューが存在するケースがあるため、
-- review_answer_timestampが最も新しい1件のみを残す(= 最終的な評価とみなす)。
with source as (

    select * from {{ source('olist_raw', 'order_reviews') }}

),

deduped as (

    select
        *,
        row_number() over (
            partition by order_id
            order by review_answer_timestamp desc
        ) as rn

    from source

)

select
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp

from deduped
where rn = 1
