---
title: "dbt × DuckDBで営業KPIダッシュボードを作ってみた【Looker Studio連携】"
emoji: "📊"
type: "tech"
topics: ["dbt", "duckdb", "looker studio", "SQL", "CRM"]
published: true
---

## この記事でやること

dbt × DuckDBで営業KPIダッシュボードを作り、Looker Studioで可視化するまでの手順をまとめます。

**完成したダッシュボード**
https://lookerstudio.google.com/reporting/2472b7dc-1d2f-49db-be56-a3fa9279db57

**GitHubリポジトリ**
https://github.com/oranegewimps/shimo-data

---

## 作ったもの

### データの流れ
```
raw_deals.csv（商談データ30件）
raw_sales_reps.csv（担当者マスタ）
    ↓ dbt seed
    ↓ stg_deals.sql（staging層：整形）
    ↓ mart_crm_pipeline.sql（フェーズ別集計）
    ↓ mart_sales_rep_kpi.sql（担当者別KPI）
    ↓ DuckDB → CSV出力
    ↓ Google Sheets → Looker Studio
```

### ダッシュボードの中身

- 担当者別KPIテーブル（受注金額・勝率・目標達成率・平均商談日数）
- 担当者別受注金額の棒グラフ
- フェーズ別パイプラインの円グラフ
- 受注金額・受注率のスコアカード

---

## staging層：生データの整形
```sql
-- models/staging/stg_deals.sql
with source as (
    select * from {{ ref('raw_deals') }}
),

cleaned as (
    select
        deal_id,
        customer_name,
        sales_rep_id,
        phase,
        cast(amount as integer)      as amount,
        cast(probability as integer) as probability,
        created_date,
        closed_date,
        case
            when result is null then null
            else result
        end                          as result
    from source
)

select
    *,
    case
        when result = '受注' then 1
        else 0
    end                              as is_won,
    case
        when closed_date is not null then
            datediff('day', created_date, closed_date)
        else null
    end                              as lead_time_days
from cleaned
```

**ポイント：** `is_won`（受注フラグ）と `lead_time_days`（商談リードタイム）をstagingで計算しておくことで、mart層がシンプルになります。

---

## mart層①：フェーズ別パイプライン
```sql
-- models/mart/mart_crm_pipeline.sql
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
```

**`weighted_amount`（加重平均金額）とは：** 確度×金額で計算した「実際に取れそうな売上予測」です。パイプライン管理で必須の指標です。

---

## mart層②：担当者別KPI
```sql
-- models/mart/mart_sales_rep_kpi.sql
select
    r.sales_rep_name,
    r.target_amount,
    count(d.deal_id)                                                    as total_deals,
    sum(d.is_won)                                                       as won_deals,
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
group by 1, 2
order by won_amount desc
```

**出力結果：**
```
田中太郎 | 受注金額2,470,000 | 勝率45.5% | 目標達成率82.3% | 平均37.4日
佐藤次郎 | 受注金額1,900,000 | 勝率44.4% | 目標達成率67.9% | 平均36.8日
鈴木花子 | 受注金額1,640,000 | 勝率30.0% | 目標達成率65.6% | 平均33.3日
```

---

## ハマったポイント：空文字と日付型

CSVの空欄が `NULL` ではなく `''`（空文字）としてDuckDBに入り、日付型変換でエラーになりました。

**解決策：** `dbt_project.yml` でカラム型を明示指定
```yaml
seeds:
  dbt_project:
    raw_deals:
      +column_types:
        closed_date: varchar
        created_date: varchar
```

---

## DuckDB → Looker Studioの接続方法

DuckDBはLooker Studioと直接繋げないため、CSVを経由します。
```bash
# DuckDBからCSVを出力
.\duckdb.exe mydb.duckdb -c "COPY mart_sales_rep_kpi TO 'mart_sales_rep_kpi.csv' (HEADER, DELIMITER ',');"
```

その後 Google Sheets にインポートして Looker Studio と接続します。

---

## まとめ

- dbtのstaging/mart層でKPI設計からSQL実装まで一気通貫でできる
- `weighted_amount`・`win_rate_pct`・`target_achievement_pct` など現場で使える指標を実装
- DuckDBはローカルで手軽に試せるが、本番はBigQueryへの移行が必要

次はBigQueryに移行してより本格的なデータ基盤を構築します。

GitHubでポートフォリオ公開中です→ https://github.com/oranegewimps/shimo-data