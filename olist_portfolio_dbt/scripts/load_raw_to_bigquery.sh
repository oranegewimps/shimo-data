#!/usr/bin/env bash
# ============================================================
# Kaggle CSV(ローカル) → Cloud Storage → BigQuery(raw層)
# VSCodeのターミナルから実行する想定
# ============================================================
set -euo pipefail

# ---- 事前に書き換えてください ----
PROJECT_ID="olist-ecommerce-shimodata"
BUCKET_NAME="your-bucket-name"   # ここだけは新規に決めて書き換えてください(世界で一意な名前が必要)
RAW_DATASET="olist_raw"
LOCATION="US"
DATA_DIR="./data"   # Kaggle CSVを置いたローカルディレクトリ
# ----------------------------------

gcloud config set project "$PROJECT_ID"

# 1. Cloud Storageバケット作成(既存ならスキップ)
gsutil mb -l "$LOCATION" "gs://$BUCKET_NAME" 2>/dev/null || echo "bucket already exists, skipping"

# 2. CSVをCloud Storageへアップロード
gsutil -m cp "$DATA_DIR"/*.csv "gs://$BUCKET_NAME/olist/"

# 3. BigQueryにraw用データセットを作成(既存ならスキップ)
bq --location="$LOCATION" mk --dataset "$PROJECT_ID:$RAW_DATASET" 2>/dev/null || echo "dataset already exists, skipping"

# 4. 各CSVをBigQueryにロード(スキーマは自動検出)
#    キー = dbtのsource名 / 値 = CSVファイル名
declare -A TABLES=(
  [customers]="olist_customers_dataset.csv"
  [orders]="olist_orders_dataset.csv"
  [order_items]="olist_order_items_dataset.csv"
  [order_payments]="olist_order_payments_dataset.csv"
  [order_reviews]="olist_order_reviews_dataset.csv"
  [products]="olist_products_dataset.csv"
  [sellers]="olist_sellers_dataset.csv"
  [geolocation]="olist_geolocation_dataset.csv"
  [product_category_name_translation]="product_category_name_translation.csv"
)

for table in "${!TABLES[@]}"; do
  file="${TABLES[$table]}"
  echo "Loading ${table} from ${file} ..."
  bq load \
    --source_format=CSV \
    --skip_leading_rows=1 \
    --autodetect \
    --allow_quoted_newlines \
    --replace \
    "${RAW_DATASET}.${table}" \
    "gs://${BUCKET_NAME}/olist/${file}"
done

echo "Done. Raw tables loaded into ${PROJECT_ID}:${RAW_DATASET}"
