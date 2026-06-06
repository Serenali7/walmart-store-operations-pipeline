# Walmart Store Operations Analytics Pipeline

## Project Overview

This project builds a BigQuery-based store operations analytics pipeline using the Walmart Recruiting Store Sales Forecasting dataset. The goal is to simulate a field operations reporting environment where multi-location sales, department performance, holiday impact, promotional markdowns, and external regional factors need to be transformed into reliable dashboard-ready metrics.

Instead of treating the dataset as a pure forecasting problem, I reframed it as an operations analytics and data warehousing project. The pipeline loads raw CSV files into Google Cloud Storage, ingests them into BigQuery, creates raw, staging, core, mart, and audit layers, and validates the final reporting tables through SQL-based data quality checks.

---

## Business Context

The dataset contains historical weekly sales data for 45 Walmart stores across different regions. Each store has multiple departments, and sales are affected by holiday weeks, promotional markdowns, temperature, fuel price, CPI, and unemployment.

This structure is similar to field operations analytics, where teams need to monitor performance across locations, departments, time periods, and external operating conditions.

Key business questions:

* How are stores performing week over week?
* Which departments drive the most sales within each store?
* How do major holidays impact store performance?
* Which stores show potential operational risk signals?
* Is the reporting layer reliable enough for dashboard consumption?

---

## Data Source

Dataset: Walmart Recruiting - Store Sales Forecasting

Files used:

* `train.csv`: historical weekly sales by store, department, and week
* `stores.csv`: store type and size
* `features.csv`: external store-week factors including temperature, fuel price, markdowns, CPI, unemployment, and holiday flag

Files not used:

* `test.csv`
* `sampleSubmission.csv`

This project focuses on data modeling, validation, and reporting rather than Kaggle competition forecasting.

---

## Architecture

```text
Kaggle CSV
   ↓
Google Cloud Storage
   ↓
BigQuery walmart_raw
   ↓
BigQuery walmart_staging
   ↓
BigQuery walmart_core
   ↓
BigQuery walmart_mart
   ↓
BigQuery walmart_audit
```

### BigQuery Layers

| Layer             | Purpose                                                               |
| ----------------- | --------------------------------------------------------------------- |
| `walmart_raw`     | Preserve original CSV structure from GCS                              |
| `walmart_staging` | Clean data, rename columns, convert data types, handle missing values |
| `walmart_core`    | Build reusable source-of-truth fact and dimension tables              |
| `walmart_mart`    | Create dashboard-ready KPI tables                                     |
| `walmart_audit`   | Store data quality validation results                                 |

---

## BigQuery Tables

### Raw Layer

| Table             | Description                                   |
| ----------------- | --------------------------------------------- |
| `raw_train_sales` | Raw weekly sales data from `train.csv`        |
| `raw_stores`      | Raw store metadata from `stores.csv`          |
| `raw_features`    | Raw external feature data from `features.csv` |

### Staging Layer

| Table          | Description                   |
| -------------- | ----------------------------- |
| `stg_sales`    | Cleaned weekly sales data     |
| `stg_stores`   | Cleaned store metadata        |
| `stg_features` | Cleaned external feature data |

Key staging transformations:

* Renamed fields into `snake_case`
* Converted IDs into `INT64`
* Converted dates into `DATE`
* Converted sales and external indicators into `FLOAT64`
* Converted holiday flags into `BOOL`
* Converted markdown `"NA"` values into `NULL`

### Core Layer

| Table                        | Description                                          |
| ---------------------------- | ---------------------------------------------------- |
| `dim_store`                  | Store dimension with store type, size, and size tier |
| `dim_department`             | Department dimension                                 |
| `dim_calendar`               | Calendar dimension with holiday classification       |
| `fact_weekly_sales`          | Store-department-week sales fact table               |
| `fact_store_weekly_features` | Store-week external feature fact table               |

### Mart Layer

| Table                     | Description                                                              |
| ------------------------- | ------------------------------------------------------------------------ |
| `mart_store_weekly_kpis`  | Store-week KPI table with sales, growth, markdowns, and external factors |
| `mart_department_ranking` | Department ranking within each store                                     |
| `mart_holiday_impact`     | Holiday sales lift compared with non-holiday baseline                    |
| `mart_store_risk_flags`   | Store-week operational risk flags                                        |

### Audit Layer

| Table                  | Description                                              |
| ---------------------- | -------------------------------------------------------- |
| `data_quality_results` | SQL-based validation results for pipeline quality checks |

---

## Data Quality Checks

The audit layer validates the pipeline through checks including:

* Raw-to-staging row count reconciliation
* Null business key checks
* Duplicate store-department-week checks
* Duplicate store-week checks
* Referential integrity between fact and dimension tables
* Mart-level duplicate key checks
* Negative weekly sales review

Audit summary:

| Check Status | Severity | Count |
| ------------ | -------: | ----: |
| PASS         |    ERROR |    11 |
| REVIEW       |  WARNING |     1 |

The warning-level check identifies negative weekly sales values. These were classified as `REVIEW` rather than `FAIL` because they may represent returns, refunds, or business adjustments.

---

## Key Metrics Created

The mart layer supports metrics such as:

* Weekly store sales
* Week-over-week sales growth
* Sales per square foot
* Active department count
* Department sales share within store
* Department rank within store
* Holiday lift percentage
* Total promotional markdown amount
* High unemployment flag
* High fuel price flag
* Sales drop flag
* Holiday week without markdown flag

---

## SQL Files

| File                         | Purpose                                              |
| ---------------------------- | ---------------------------------------------------- |
| `00_create_datasets.sql`     | Create BigQuery datasets                             |
| `01_load_raw_from_gcs.sql`   | Load CSV files from GCS into BigQuery raw tables     |
| `02_staging_cleaning.sql`    | Clean and standardize raw tables                     |
| `03_core_model.sql`          | Build source-of-truth dimension and fact tables      |
| `04_mart_tables.sql`         | Build dashboard-ready mart tables                    |
| `05_data_quality_checks.sql` | Create audit validation table                        |
| `06_validation_queries.sql`  | Validate row counts, mart outputs, and audit results |

---

## Project Results

Completed pipeline components:

* Loaded 3 raw Walmart CSV files into Google Cloud Storage
* Created 5 BigQuery datasets for raw, staging, core, mart, and audit layers
* Loaded 421,570 weekly sales records into BigQuery
* Built a core dimensional model with store, department, calendar, sales fact, and feature fact tables
* Created dashboard-ready mart tables for store performance, department ranking, holiday impact, and risk flags
* Implemented SQL-based audit checks to validate row counts, keys, duplicates, referential integrity, and business anomalies

---

## Evidence

Project evidence screenshots are available in the `screenshots/` folder:

| Evidence | File |
|---|---|
| Raw files uploaded to Google Cloud Storage | `screenshots/01_gcs_raw_files.png` |
| BigQuery raw / staging / core / mart / audit layers | `screenshots/02_bigquery_layers.png` |
| Raw layer row count validation | `screenshots/03_raw_row_counts.png` |
| Core layer row count validation | `screenshots/04_core_row_counts.png` |
| Mart layer row count validation | `screenshots/05_mart_row_counts.png` |
| Data quality audit summary | `screenshots/06_audit_summary.png` |

---

## Tools Used

* Google Cloud Storage
* BigQuery
* SQL
* VS Code
* GitHub
* Looker Studio or Power BI for dashboarding

---

## Summary

This project uses Walmart weekly sales data to build a store operations reporting pipeline in BigQuery. The data starts as raw CSV files, gets uploaded to Google Cloud Storage, and is then loaded into BigQuery for cleaning, modeling, reporting, and validation.

The project is organized into five layers: raw, staging, core, mart, and audit. The raw layer keeps the original source data. The staging layer cleans field names, converts data types, and handles missing values. The core layer turns the cleaned data into reusable store, department, calendar, sales, and feature tables. The mart layer prepares business-ready metrics for reporting, such as weekly store sales, department rankings, holiday lift, markdown activity, and store risk flags.

The audit layer checks whether the pipeline is reliable before the data is used for reporting. It includes row count checks, null key checks, duplicate checks, fact-to-dimension matching, and review flags for unusual values like negative weekly sales.

