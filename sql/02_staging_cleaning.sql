-- 02_staging_cleaning.sql
-- Purpose: Clean raw Walmart tables and create typed staging tables.
-- Layer: walmart_staging
--
-- Key transformations:
-- 1. Rename columns into snake_case
-- 2. Convert raw string fields into correct data types
-- 3. Parse Date into DATE
-- 4. Convert IsHoliday into BOOL
-- 5. Convert MarkDown "NA" values into NULL before casting to FLOAT64

CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales` AS
SELECT
  SAFE_CAST(Store AS INT64) AS store_id,
  SAFE_CAST(Dept AS INT64) AS dept_id,
  SAFE_CAST(Date AS DATE) AS week_date,
  SAFE_CAST(Weekly_Sales AS FLOAT64) AS weekly_sales,
  SAFE_CAST(IsHoliday AS BOOL) AS is_holiday
FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_train_sales`;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_stores` AS
SELECT
  SAFE_CAST(Store AS INT64) AS store_id,
  Type AS store_type,
  SAFE_CAST(Size AS INT64) AS store_size_sqft
FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_stores`;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features` AS
SELECT
  SAFE_CAST(Store AS INT64) AS store_id,
  SAFE_CAST(Date AS DATE) AS week_date,
  SAFE_CAST(Temperature AS FLOAT64) AS temperature,
  SAFE_CAST(Fuel_Price AS FLOAT64) AS fuel_price,

  SAFE_CAST(NULLIF(MarkDown1, 'NA') AS FLOAT64) AS markdown_1,
  SAFE_CAST(NULLIF(MarkDown2, 'NA') AS FLOAT64) AS markdown_2,
  SAFE_CAST(NULLIF(MarkDown3, 'NA') AS FLOAT64) AS markdown_3,
  SAFE_CAST(NULLIF(MarkDown4, 'NA') AS FLOAT64) AS markdown_4,
  SAFE_CAST(NULLIF(MarkDown5, 'NA') AS FLOAT64) AS markdown_5,

  SAFE_CAST(NULLIF(CPI, 'NA') AS FLOAT64) AS cpi,
  SAFE_CAST(NULLIF(Unemployment, 'NA') AS FLOAT64) AS unemployment,
  SAFE_CAST(IsHoliday AS BOOL) AS is_holiday
FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_features`;
