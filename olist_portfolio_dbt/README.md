# Olist Portfolio dbt Project

Kaggle「[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)」
を題材に、GCP(Cloud Storage / BigQuery)+ dbt + Looker Studio で構築したデータ分析基盤です。

## 全体構成

```
[Kaggle CSV] → [Cloud Storage] → [BigQuery: raw] → [dbt] → [BigQuery: staging/intermediate/marts] → [Looker Studio]
```

生CSVを直接BIツールに接続せず、dbtで raw → staging → intermediate → marts の4層に分けて変換しています。

| 層 | 役割 |
|---|---|
| `raw` | Kaggle CSVをそのままBigQueryにロードしたもの(bq load、スキーマ自動検出) |
| `staging` | カラム名の整理・型変換・重複除去のみ。生データ1テーブル=1モデル |
| `intermediate` | 注文(`order_id`)を軸に、顧客・金額・配送遅延・レビューを結合した中核ファクトテーブル |
| `marts` | Looker Studioの各チャートに対応する最終集計テーブル |

## なぜdbtでレイヤーを分けているか

生CSVをそのままLooker Studioに繋ぐことは可能ですが、それだと「SQLが書ける人」止まりの証明にしかなりません。
このプロジェクトでは、

- **staging**: 生データの癖(欠損・重複)をここで吸収し、`schema.yml`の`tests`で明示する
- **intermediate**: 「なぜこの中間テーブルを作ったか」を1テーブルに集約して説明できるようにする
- **marts**: BIツール側にはロジックを持たせず、集計済みの薄いテーブルだけを見せる

という役割分担にすることで、変換ロジックをGitで管理された「コード」として提示できるようにしています。

## 主要な設計判断

- **`stg_order_reviews`**: 生データは`order_id`に対して複数レビューが存在するケースがあるため、
  `review_answer_timestamp`が最新の1件のみを残すdedupe処理を実施
- **`stg_geolocation`**: 同一郵便番号(`zip_code_prefix`)に複数の緯度経度レコードが存在するため、
  郵便番号単位で平均集約し1行1zipに正規化
- **`int_orders_enriched.is_late_delivery`**: `order_status = 'delivered'`の場合のみ配送遅延を判定し、
  未完了の注文は`null`として明示的に区別(falseにしない)
- **リピート分析**: `customer_id`は注文ごとに新規発行されるIDのため、必ず`customer_unique_id`を使用する

## セットアップ

### 1. 生データをBigQueryにロード

```bash
# scripts/load_raw_to_bigquery.sh 内の PROJECT_ID / BUCKET_NAME を書き換えてから実行
bash scripts/load_raw_to_bigquery.sh
```

### 2. dbtプロファイルを設定

`profiles.yml.example` を参考に `~/.dbt/profiles.yml` を作成してください。
`method: oauth` を使う場合は事前に以下を実行しておきます。

```bash
gcloud auth application-default login
```

### 3. dbt実行

```bash
dbt deps      # パッケージ利用時のみ
dbt run
dbt test
dbt docs generate && dbt docs serve
```

### 4. Looker Studio

BigQuery上の `olist_marts` データセット配下の各テーブル(`mart_monthly_sales`, `mart_delivery_by_state`,
`mart_review_score_distribution`, `mart_category_sales`)にLooker Studioから直接接続します。

> 補足: 既存のCRM/予実管理案件(`autonext-kpi-dev-0001`プロジェクト、`shimo_datamart`データセット)とは
> 完全に別のGCPプロジェクト(`olist-ecommerce-shimodata`)を新規作成して運用している。
> 案件ごとにプロジェクトを分けることで、無料枠の消費や誤操作のリスクを分離している。

## モデル一覧

| モデル | 説明 |
|---|---|
| `stg_orders` / `stg_order_items` / `stg_order_payments` / `stg_order_reviews` / `stg_customers` / `stg_products` / `stg_sellers` / `stg_geolocation` / `stg_product_category_translation` | 生データ1テーブルにつき1モデル |
| `int_order_items_agg` | 注文明細を注文単位に集計 |
| `int_orders_enriched` | 注文を軸にした中核ファクトテーブル |
| `mart_monthly_sales` | 月次GMV・注文件数・AOV |
| `mart_delivery_by_state` | 州別配送遅延率・レビュースコア |
| `mart_review_score_distribution` | レビュースコア分布 |
| `mart_category_sales` | カテゴリ別売上構成 |
