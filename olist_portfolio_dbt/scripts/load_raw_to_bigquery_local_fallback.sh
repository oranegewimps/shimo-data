#!/bin/bash
set -e

PROJECT="olist-ecommerce-shimodata"
DATASET="olist_raw"
DATA_DIR="/c/shimo-data/olist_portfolio_dbt/data"

echo "=== BigQuery直接ロード開始（Cloud Storage経由なし） ==="

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.customers \
  "${DATA_DIR}/olist_customers_dataset.csv"
echo "✓ customers"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.geolocation \
  "${DATA_DIR}/olist_geolocation_dataset.csv"
echo "✓ geolocation"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.order_items \
  "${DATA_DIR}/olist_order_items_dataset.csv"
echo "✓ order_items"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.order_payments \
  "${DATA_DIR}/olist_order_payments_dataset.csv"
echo "✓ order_payments"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.order_reviews \
  "${DATA_DIR}/olist_order_reviews_dataset.csv"
echo "✓ order_reviews"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.orders \
  "${DATA_DIR}/olist_orders_dataset.csv"
echo "✓ orders"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.products \
  "${DATA_DIR}/olist_products_dataset.csv"
echo "✓ products"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.sellers \
  "${DATA_DIR}/olist_sellers_dataset.csv"
echo "✓ sellers"

bq load --project_id=$PROJECT \
  --source_format=CSV --autodetect \
  --allow_quoted_newlines --skip_leading_rows=1 --replace \
  ${DATASET}.product_category_name_translation \
  "${DATA_DIR}/product_category_name_translation.csv"
echo "✓ product_category_name_translation"

echo ""
echo "=== 全9テーブルのロード完了 ==="
