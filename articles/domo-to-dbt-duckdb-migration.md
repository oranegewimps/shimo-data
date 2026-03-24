---
title: "DOMO使いがdbtに移行したら「やってること同じじゃん」ってなった話"
emoji: "🔄"
type: "tech"
topics: ["dbt", "duckdb", "looker studio", "DOMO", "BI"]
published: true
---

## 自己紹介

前職で会計・戦略部門に2年在籍し、BIツール「DOMO」を使ったダッシュボード構築・CRM設計を担当していました。現在はフリーランスのBIコンサルとして独立準備中で、ポートフォリオをGitHub・Zennで公開しています。

---

## きっかけ：「dbtって何が嬉しいの？」

独立に向けてdbtを学び始めたとき、正直ピンときませんでした。

「SQLをファイルで管理する？今までDOMOで普通にやってたけど？」

でも手を動かしてみたら気づきました。**DOMOでやってたことと構造が全く同じ**だと。

---

## DOMOとdbtは「同じこと」をしている

| DOMOでやってたこと | dbtでの対応 |
|---|---|
| ExcelをDOMOにアップロード | `dbt seed`でCSV→テーブル化 |
| コネクタで他ソフトからデータ取得 | BigQuery・Redshiftに接続 |
| DOMO内でデータ整形・集計 | staging層・mart層でSQL管理 |
| ダッシュボード作成 | Looker Studioに接続 |

ツールが違うだけで、**やっていることの本質は同じ**でした。

---

## 実際にやったこと

### 環境

- OS: Windows 11
- DuckDB（ローカルDB）
- dbt-core 1.11.7 / dbt-duckdb 1.10.1
- VSCode

### フォルダ構成
```
dbt_project/
  models/
    staging/
      stg_sales.sql      # 生データ整形
    mart/
      mart_sales_monthly.sql  # 月別集計
  seeds/
    raw_sales.csv        # 元データ
```

### ① dbt seedでCSVをテーブル化

DOMOでExcelをアップロードしていた作業が、dbtでは`dbt seed`コマンド1つになります。
```bash
dbt seed
# CSV → DuckDBのテーブルに変換される
```

### ② staging層：生データを整形する

DOMOのETL処理に相当します。型変換・カラム整理・粗利計算をここでやります。
```sql
-- models/staging/stg_sales.sql
with source as (
    select * from {{ ref('raw_sales') }}
)

select
    order_id,
    cast(order_date as date)  as order_date,
    customer_id,
    product,
    amount,
    cost,
    amount - cost             as gross_profit
from source
```

**`{{ ref('raw_sales') }}` とは？**
他のテーブル・modelを参照するdbt独自の書き方です。これを使うことでdbtが依存関係を把握し、正しい順番で自動実行してくれます。

### ③ mart層：ダッシュボード用に集計する

DOMOのCard・Beast Modeに相当します。月別×商品別の売上・粗利を集計します。
```sql
-- models/mart/mart_sales_monthly.sql
with stg as (
    select * from {{ ref('stg_sales') }}
)

select
    strftime(order_date, '%Y-%m')   as year_month,
    product,
    count(order_id)                 as order_count,
    sum(amount)                     as total_amount,
    sum(cost)                       as total_cost,
    sum(gross_profit)               as total_gross_profit
from stg
group by 1, 2
order by 1, 2
```

### ④ dbt runで全部実行
```bash
dbt run
# staging → mart の順番で自動実行される
```

実行結果：
```
1 of 2 OK created sql view model main.stg_sales
2 of 2 OK created sql table model main.mart_sales_monthly
```

---

## DOMOユーザーがdbtを学ぶメリット

**概念がすでに頭に入っている**のが最大の強みです。

「データを整形して・集計して・可視化する」という流れはDOMOで体得済み。あとはツールを覚えるだけです。

さらにdbtはBigQuery・Snowflakeなど大規模DBとの相性が抜群で、**より大きな案件に対応できる**ようになります。

---

## 次にやること

- BigQueryへの移行
- CRM・営業KPIダッシュボード（ポートフォリオ2本目）
- Looker Studioとの接続

GitHubでポートフォリオ公開中です→ https://github.com/oranegewimps/shimo-data