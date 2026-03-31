---
title: "dbt × BigQueryで本番データ基盤を構築した話【Looker Studio直接接続】"
emoji: "🏗️"
type: "tech"
topics: ["dbt", "bigquery", "looker studio", "GCP", "SQL"]
published: true
---

## この記事でやること

DuckDBで動かしていたdbtをBigQueryに移行し、Looker Studioと直接接続するまでの手順をまとめます。

**GitHubリポジトリ**
https://github.com/oranegewimps/shimo-data

---

## なぜBigQueryに移行するのか

DuckDBはローカル環境での開発に最適ですが、Looker Studioと直接接続できません。
```
【DuckDB構成】
dbt + DuckDB → CSV出力 → Google Sheets → Looker Studio

【BigQuery構成】
dbt + BigQuery → Looker Studio（直接接続）
```

フリーランス案件で使われるのはほぼ100%クラウドDB。BigQueryが使えると案件の幅が一気に広がります。

---

## 環境構築手順

### ① GCPプロジェクト・BigQueryセットアップ

1. https://console.cloud.google.com にアクセス
2. BigQueryを開く
3. データセットを作成（`shimo_datamart`・東京リージョン）

### ② Google Cloud SDKインストール

https://cloud.google.com/sdk/docs/install からインストール後：
```bash
gcloud auth application-default login
```

### ③ dbt-bigqueryインストール
```bash
pip install dbt-bigquery --break-system-packages
```

### ④ profiles.yml設定
```yaml
dbt_project:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: your-project-id
      dataset: shimo_datamart
      location: asia-northeast1
      threads: 1
```

### ⑤ 接続確認
```bash
dbt debug
# All checks passed! が出ればOK
```

---

## DuckDBからBigQueryへの移行で変わった点

### 関数名の違い

| 処理 | DuckDB | BigQuery |
|---|---|---|
| 日付差 | `datediff('day', a, b)` | `date_diff(b, a, DAY)` |
| 日付フォーマット | `strftime(date, '%Y-%m')` | `format_date('%Y-%m', date)` |
| 文字列型 | `varchar` | `string` |

### seeds設定の変更
```yaml
seeds:
  dbt_project:
    raw_deals:
      +column_types:
        closed_date: string    # varcharではなくstring
        created_date: string
```

---

## dbt run の結果
```
PASS=5 WARN=0 ERROR=0 SKIP=0 TOTAL=5
```

BigQueryに以下のテーブルが作成されました：
```
shimo_datamart/
  raw_deals
  raw_sales
  raw_sales_reps
  stg_deals
  stg_sales
  mart_crm_pipeline
  mart_sales_rep_kpi
  mart_sales_monthly
```

---

## Looker Studio → BigQuery直接接続

1. https://lookerstudio.google.com を開く
2. 「データを追加」→「BigQuery」
3. プロジェクト・データセット・テーブルを選択
4. グラフを配置

CSVを経由せず直接接続できるのがBigQueryの最大の強みです。

---

## まとめ

DuckDBで学んだdbtの知識がそのままBigQueryで使えました。変わったのは関数名と型名だけです。
```
DuckDB（開発・学習）→ BigQuery（本番）
```

この流れでポートフォリオを作ることで、実務に近い構成を再現できました。

GitHubでポートフォリオ公開中です→ https://github.com/oranegewimps/shimo-data

ダッシュボードはこちら→ https://lookerstudio.google.com/reporting/17053184-d0d6-4e43-a2a2-f3464c7577f1