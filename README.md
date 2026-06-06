# Walmart Store Operations Analytics Pipeline

## Overview
This project builds a store operations reporting pipeline in BigQuery using Walmart weekly sales data.

The data starts as raw CSV files, gets uploaded to Google Cloud Storage, and is then loaded into BigQuery for cleaning, modeling, reporting, and validation. The goal is to turn raw store, department, sales, holiday, markdown, and regional feature data into clean reporting tables that can support store performance dashboards.

This is not a forecasting project. The focus is on data ingestion, cleaning, dimensional modeling, KPI mart creation, and data quality checks.

---

## Data Source
Dataset: Walmart Recruiting - Store Sales Forecasting

Files used:

* `train.csv`: weekly sales by store, department, and week
* `stores.csv`: store type and store size
* `features.csv`: temperature, fuel price, markdowns, CPI, unemployment, and holiday flags

Files not used:

* `test.csv`
* `sampleSubmission.csv`

---

## Pipeline Architecture
```text
Kaggle CSV
   ↓
Google Cloud Storage
   ↓
BigQuery raw layer
   ↓
BigQuery staging layer
   ↓
BigQuery core layer
   ↓
BigQuery mart layer
   ↓
BigQuery audit layer
```

| Layer             | Purpose                                                             |
| ----------------- | ------------------------------------------------------------------- |
| `walmart_raw`     | Keeps the original CSV structure from GCS                           |
| `walmart_staging` | Cleans field names, converts data types, and handles missing values |
| `walmart_core`    | Builds reusable fact and dimension tables                           |
| `walmart_mart`    | Creates dashboard-ready KPI tables                                  |
| `walmart_audit`   | Stores SQL-based data quality check results                         |

---

## What the Pipeline Builds

### Raw Layer
Raw CSV files are loaded from Google Cloud Storage into BigQuery:

* `raw_train_sales`
* `raw_stores`
* `raw_features`

### Staging Layer
The staging layer standardizes the raw data:

* Renames columns into `snake_case`
* Converts IDs into `INT64`
* Converts dates into `DATE`
* Converts sales and feature fields into `FLOAT64`
* Converts holiday flags into `BOOL`
* Converts markdown `"NA"` values into `NULL`

### Core Layer
The core layer creates the source-of-truth data model:

* `dim_store`
* `dim_department`
* `dim_calendar`
* `fact_weekly_sales`
* `fact_store_weekly_features`

### Mart Layer
The mart layer prepares reporting-ready tables:

* `mart_store_weekly_kpis`
* `mart_department_ranking`
* `mart_holiday_impact`
* `mart_store_risk_flags`

These tables support metrics such as weekly sales, week-over-week growth, sales per square foot, department ranking, holiday lift, markdown activity, and store risk flags.

---

## Data Quality Checks
The audit layer validates the pipeline before the data is used for reporting.

Checks include:
* Raw-to-staging row count reconciliation
* Null key checks
* Duplicate key checks
* Fact-to-dimension matching
* Mart-level uniqueness checks
* Negative weekly sales review

Audit result:
| Status | Severity | Count |
| ------ | -------: | ----: |
| PASS   |    ERROR |    11 |
| REVIEW |  WARNING |     1 |

The warning is for negative weekly sales. These records were flagged for review instead of treated as pipeline failures because they may represent returns, refunds, or business adjustments.

---

## SQL Files
| File                         | Purpose                                      |
| ---------------------------- | -------------------------------------------- |
| `00_create_datasets.sql`     | Creates BigQuery datasets                    |
| `01_load_raw_from_gcs.sql`   | Loads GCS CSV files into BigQuery raw tables |
| `02_staging_cleaning.sql`    | Cleans and standardizes raw tables           |
| `03_core_model.sql`          | Builds core fact and dimension tables        |
| `04_mart_tables.sql`         | Builds reporting mart tables                 |
| `05_data_quality_checks.sql` | Creates audit validation table               |
| `06_validation_queries.sql`  | Runs row count and QA checks                 |

---

## Evidence
Project evidence screenshots are available in the `screenshots/` folder:

| Evidence                                            | File                                 |
| --------------------------------------------------- | ------------------------------------ |
| Raw files uploaded to Google Cloud Storage          | `screenshots/01_gcs_raw_files.png`   |
| BigQuery raw / staging / core / mart / audit layers | `screenshots/02_bigquery_layers.png` |
| Raw layer row count validation                      | `screenshots/03_raw_row_counts.png`  |
| Core layer row count validation                     | `screenshots/04_core_row_counts.png` |
| Mart layer row count validation                     | `screenshots/05_mart_row_counts.png` |
| Data quality audit summary                          | `screenshots/06_audit_summary.png`   |

---

## Tech Stack
* Google Cloud Storage
* BigQuery
* SQL
* VS Code
* GitHub
---

## Project Summary
This project uses Walmart weekly sales data to build a store operations reporting pipeline in BigQuery. It organizes the data into raw, staging, core, mart, and audit layers so that raw files can be cleaned, modeled, validated, and turned into reporting-ready tables.

The final mart layer supports store performance analysis, department ranking, holiday impact analysis, markdown tracking, and store-level risk monitoring.


