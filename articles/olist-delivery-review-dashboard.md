---
title: "GCP + dbt + Looker Studioで作る配送・レビュー品質分析ダッシュボード【Olistデータセット】"
emoji: "📦"
type: "tech"
topics: ["BigQuery", "dbt", "LookerStudio", "GCP", "SQL"]
published: true
---

## はじめに

転職ポートフォリオとして、ブラジルのEコマースプラットフォーム **Olist** の公開データセットを使い、**配送遅延とレビュー品質の地理的分布**を分析するダッシュボードを構築しました。

本記事では、データ取り込みからBIダッシュボード公開までの技術的な設計・実装を解説します。

**完成ダッシュボード**: https://datastudio.google.com/s/qw_toxEKwdg

**GitHubリポジトリ**: https://github.com/oranegewimps/shimo-data

---

## 技術スタック

| レイヤー | ツール |
|---------|--------|
| データウェアハウス | BigQuery（GCP） |
| データ変換 | dbt v1.11.7 + dbt-bigquery v1.11.1 |
| BI・可視化 | Looker Studio |
| 認証 | OAuth（dbt ↔ BigQuery） |

---

## データセット概要

[Olist Brazilian E-Commerce Dataset（Kaggle）](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) を使用。

- 約10万件の注文データ（2016〜2018年）
- 注文・商品・顧客・販売者・レビュー・配送情報を含む9テーブル
- ブラジル全27州をカバー

**分析テーマ**: 「配送遅延はどの州で多く、レビュースコアにどう影響するか」

---

## GCP構成

```
プロジェクト: olist-ecommerce-shimodata

データセット:
├── olist_raw                        # 生データ（CSV → bq load）
├── dbt_default_olist_staging        # 型変換・リネーム
├── dbt_default_olist_intermediate   # 集約・結合
└── dbt_default_olist_marts          # BI用マート
```

### データ取り込み

KaggleからダウンロードしたCSVを `bq load` コマンドでBigQueryに直接ロードしました。

```bash
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  olist_raw.orders \
  ./olist_orders_dataset.csv
```

---

## dbtモデル設計

### レイヤー構成

```
raw（BigQuery生テーブル）
 └── staging（型変換・リネームのみ）
      └── intermediate（集約・結合）
           └── marts（BI用マート）
```

### stagingレイヤー

生データの型変換とカラム名の正規化のみを行います。ビジネスロジックは持ちません。

```sql
-- stg_orders.sql
select
    order_id,
    customer_id,
    order_status,
    cast(order_purchase_timestamp as timestamp) as order_purchased_at,
    cast(order_delivered_customer_date as timestamp) as order_delivered_at,
    cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_at
from {{ source('olist_raw', 'orders') }}
```

### intermediateレイヤー

複数テーブルの結合・集約を担当します。

```sql
-- int_orders.sql（抜粋）
select
    o.order_id,
    o.order_status,
    o.order_delivered_at,
    o.order_estimated_delivery_at,
    case
        when o.order_delivered_at > o.order_estimated_delivery_at then 1
        else 0
    end as is_late,
    r.review_score,
    c.customer_state
from {{ ref('stg_orders') }} o
left join {{ ref('stg_order_reviews') }} r using (order_id)
left join {{ ref('stg_customers') }} c using (customer_id)
where o.order_status = 'delivered'
```

### martsレイヤー

Looker Studio用の集計済みテーブルです。

**mart_delivery_by_state**（州別配送分析）

```sql
select
    customer_state                              as state,
    count(order_id)                             as order_count,
    sum(is_late)                                as late_order_count,
    avg(review_score)                           as avg_review_score,
    avg(state_lat)                              as state_lat,
    avg(state_lng)                              as state_lng
from {{ ref('int_orders') }}
left join {{ ref('int_geolocation') }} using (customer_state)
group by customer_state
```

**その他のmart**
- `mart_monthly_orders` : 月次注文数・GMV
- `mart_review_score_distribution` : レビュースコア分布
- `mart_category_sales_top10` : カテゴリ別売上TOP10

### dbt test

```bash
$ dbt test
29 passed, 1 warned
```

not_null・unique・accepted_valuesによる品質チェックを全モデルに設定しています。

---

## Looker Studioダッシュボード設計

### データソース構成（4本）

| DS | テーブル | 主な用途 |
|----|---------|---------|
| DS-01 | mart_delivery_by_state | 地図・州別ランキング |
| DS-02 | mart_monthly_orders | 月次トレンド |
| DS-03 | mart_review_score_distribution | レビュー分布 |
| DS-04 | mart_category_sales_top10 | カテゴリ別売上 |

### 計算フィールド

DS-01に以下の計算フィールドを追加しました。

```
全体遅延率 = SUM(late_order_count) / SUM(order_count)
※ フィールドタイプ: パーセント

加重平均レビュースコア = SUM(avg_review_score * order_count) / SUM(order_count)

location = CONCAT(state_lat, ",", state_lng)
※ フィールドタイプ: 緯度、経度（Googleマップバブルチャート用）
```

### チャート構成

| チャート | データソース | 主な設定 |
|---------|------------|---------|
| KPIスコアカード×4 | DS-01 | 遅延率=赤、レビュースコア=緑で条件付き書式 |
| Googleマップ バブルチャート | DS-01 | バブルサイズ=注文件数、色=遅延率 |
| 州別遅延率ランキング（横棒） | DS-01 | TOP10、最高値を赤でハイライト |
| 月次注文数×GMVトレンド（コンボ） | DS-02 | 棒=注文数（右軸）、折れ線=GMV（左軸） |
| レビュースコア分布（縦棒） | DS-03 | 1〜5を赤→緑のグラデーション |
| カテゴリ別売上TOP10（横棒） | DS-04 | total_sales降順 |

---

## 分析結果・インサイト

### 遅延率の地域差

- **AL州（Alagoas）の遅延率が約24%**と最高。北東部・北部の州に遅延が集中
- サンパウロ（SP）など南東部主要都市は比較的遅延率が低い
- ブラジルの物流インフラが地域によって大きく異なることが可視化できた

### 遅延とレビュースコアの関係

- 加重平均レビュースコアは **4.16**（5点満点）と全体的には高水準
- 遅延率の高い州ほどレビュースコアが低い傾向が確認できる

### 成長トレンド

- 2016年末〜2018年にかけてGMV・注文数ともに右肩上がり
- 2017年11月にピーク（ブラックフライデー効果と推定）

---

## 工夫した点・ハマった点

### 工夫した点

**int_geolocationでのzip_code_prefix単位集約**

生データのgeolocationは同一zip_codeに複数のlat/lngが存在するため、`AVG()` で集約してから州レベルにまとめました。

```sql
-- int_geolocation.sql
select
    zip_code_prefix,
    avg(geolocation_lat) as lat,
    avg(geolocation_lng) as lng
from {{ source('olist_raw', 'geolocation') }}
group by zip_code_prefix
```

**Looker Studioの緯度経度フィールド**

`CONCAT(lat, ",", lng)` で文字列を作成し、フィールドタイプを「緯度、経度」に変更することでGoogleマップが認識します。タイプ変更を忘れるとマップに表示されないので注意。

### ハマった点

**月次グラフの四半期集約問題**

`order_month` を「年四半期」タイプに変更すると、すでに月次集計済みのテーブルと衝突して同一四半期が重複表示される問題が発生。月次データのまま表示し、X軸ラベルを3ヶ月間隔で間引くことで解決しました。

---

## まとめ

| 項目 | 値 |
|------|-----|
| 総注文数 | 約9.6万件 |
| 全体遅延率 | 8.1% |
| 加重平均レビュースコア | 4.16 / 5.0 |
| 対象州数 | 27州 |

GCP + dbt + Looker Studioの組み合わせで、データ取り込みから可視化まで一貫したパイプラインを構築できました。dbtのレイヤー設計（staging → intermediate → marts）により、責務が明確で保守しやすい構成になっています。

---

## 参考

- [Olist Brazilian E-Commerce Dataset - Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- [dbt ドキュメント](https://docs.getdbt.com/)
- [BigQuery ドキュメント](https://cloud.google.com/bigquery/docs)
