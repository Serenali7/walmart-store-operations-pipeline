-- 03_core_model.sql
-- Purpose: Build the core source-of-truth dimensional model.
-- Layer: walmart_core
--
-- Core tables:
-- 1. dim_store
-- 2. dim_department
-- 3. dim_calendar
-- 4. fact_weekly_sales
-- 5. fact_store_weekly_features

CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_store` AS
SELECT
  store_id,
  store_type,
  store_size_sqft,
  CASE
    WHEN store_size_sqft >= 150000 THEN 'Large'
    WHEN store_size_sqft >= 100000 THEN 'Medium'
    ELSE 'Small'
  END AS store_size_tier
FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_stores`;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_department` AS
SELECT DISTINCT
  dept_id,
  CONCAT('Department ', CAST(dept_id AS STRING)) AS dept_name
FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`
WHERE dept_id IS NOT NULL;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_calendar` AS
WITH all_dates AS (
  SELECT DISTINCT week_date
  FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`

  UNION DISTINCT

  SELECT DISTINCT week_date
  FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`
)

SELECT
  week_date AS date_id,
  EXTRACT(YEAR FROM week_date) AS year,
  EXTRACT(MONTH FROM week_date) AS month,
  EXTRACT(QUARTER FROM week_date) AS quarter,
  EXTRACT(WEEK FROM week_date) AS week_of_year,
  FORMAT_DATE('%Y-%m', week_date) AS year_month,

  CASE
    WHEN week_date IN (
      DATE '2010-02-12', DATE '2011-02-11', DATE '2012-02-10', DATE '2013-02-08'
    ) THEN 'Super Bowl'

    WHEN week_date IN (
      DATE '2010-09-10', DATE '2011-09-09', DATE '2012-09-07', DATE '2013-09-06'
    ) THEN 'Labor Day'

    WHEN week_date IN (
      DATE '2010-11-26', DATE '2011-11-25', DATE '2012-11-23', DATE '2013-11-29'
    ) THEN 'Thanksgiving'

    WHEN week_date IN (
      DATE '2010-12-31', DATE '2011-12-30', DATE '2012-12-28', DATE '2013-12-27'
    ) THEN 'Christmas'

    ELSE 'Non-Holiday'
  END AS holiday_name,

  CASE
    WHEN week_date IN (
      DATE '2010-02-12', DATE '2011-02-11', DATE '2012-02-10', DATE '2013-02-08',
      DATE '2010-09-10', DATE '2011-09-09', DATE '2012-09-07', DATE '2013-09-06',
      DATE '2010-11-26', DATE '2011-11-25', DATE '2012-11-23', DATE '2013-11-29',
      DATE '2010-12-31', DATE '2011-12-30', DATE '2012-12-28', DATE '2013-12-27'
    ) THEN TRUE
    ELSE FALSE
  END AS is_major_holiday

FROM all_dates
WHERE week_date IS NOT NULL;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales` AS
SELECT
  store_id,
  dept_id,
  week_date AS date_id,
  weekly_sales,
  is_holiday
FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`
WHERE store_id IS NOT NULL
  AND dept_id IS NOT NULL
  AND week_date IS NOT NULL;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_store_weekly_features` AS
SELECT
  store_id,
  week_date AS date_id,
  temperature,
  fuel_price,
  markdown_1,
  markdown_2,
  markdown_3,
  markdown_4,
  markdown_5,
  cpi,
  unemployment,
  is_holiday
FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`
WHERE store_id IS NOT NULL
  AND week_date IS NOT NULL;

