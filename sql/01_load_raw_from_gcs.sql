-- 01_load_raw_from_gcs.sql
-- Purpose: Load raw Walmart CSV files from Google Cloud Storage into BigQuery raw tables.
-- Layer: walmart_raw

LOAD DATA OVERWRITE `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_train_sales`
(
  Store STRING,
  Dept STRING,
  Date STRING,
  Weekly_Sales STRING,
  IsHoliday STRING
)
FROM FILES (
  format = 'CSV',
  uris = ['gs://serena-walmart-ops-raw-a60/raw/train.csv'],
  skip_leading_rows = 1
);

LOAD DATA OVERWRITE `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_stores`
(
  Store STRING,
  Type STRING,
  Size STRING
)
FROM FILES (
  format = 'CSV',
  uris = ['gs://serena-walmart-ops-raw-a60/raw/stores.csv'],
  skip_leading_rows = 1
);

LOAD DATA OVERWRITE `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_features`
(
  Store STRING,
  Date STRING,
  Temperature STRING,
  Fuel_Price STRING,
  MarkDown1 STRING,
  MarkDown2 STRING,
  MarkDown3 STRING,
  MarkDown4 STRING,
  MarkDown5 STRING,
  CPI STRING,
  Unemployment STRING,
  IsHoliday STRING
)
FROM FILES (
  format = 'CSV',
  uris = ['gs://serena-walmart-ops-raw-a60/raw/features.csv'],
  skip_leading_rows = 1
);
