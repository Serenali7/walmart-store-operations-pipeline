-- 06_validation_queries.sql
-- Purpose: Validate row counts, table creation, mart outputs, and audit check results.
-- These queries are used for manual QA and screenshots for the GitHub README.

-- 1. Raw layer row count validation
SELECT 'raw_train_sales' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_train_sales`

UNION ALL

SELECT 'raw_stores' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_stores`

UNION ALL

SELECT 'raw_features' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_features`;


-- 2. Staging layer row count validation
SELECT 'stg_sales' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`

UNION ALL

SELECT 'stg_stores' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_stores`

UNION ALL

SELECT 'stg_features' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`;


-- 3. Core layer row count validation
SELECT 'dim_store' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_store`

UNION ALL

SELECT 'dim_department' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_department`

UNION ALL

SELECT 'dim_calendar' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_calendar`

UNION ALL

SELECT 'fact_weekly_sales' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`

UNION ALL

SELECT 'fact_store_weekly_features' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_store_weekly_features`;


-- 4. Mart layer row count validation
SELECT 'mart_store_weekly_kpis' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_weekly_kpis`

UNION ALL

SELECT 'mart_department_ranking' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_department_ranking`

UNION ALL

SELECT 'mart_holiday_impact' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_holiday_impact`

UNION ALL

SELECT 'mart_store_risk_flags' AS table_name, COUNT(*) AS row_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_risk_flags`;


-- 5. Audit summary
SELECT
  check_status,
  severity,
  COUNT(*) AS check_count
FROM `project-2e312d70-4df2-4b6f-a60.walmart_audit.data_quality_results`
GROUP BY check_status, severity
ORDER BY check_status, severity;


-- 6. Full audit result details
SELECT
  check_name,
  check_category,
  severity,
  failed_row_count,
  total_row_count,
  ROUND(failure_rate * 100, 4) AS failure_rate_pct,
  check_status
FROM `project-2e312d70-4df2-4b6f-a60.walmart_audit.data_quality_results`
ORDER BY
  CASE check_status
    WHEN 'FAIL' THEN 1
    WHEN 'REVIEW' THEN 2
    WHEN 'PASS' THEN 3
  END,
  failed_row_count DESC;


-- 7. Review non-pass checks
SELECT
  check_name,
  check_category,
  severity,
  failed_row_count,
  total_row_count,
  ROUND(failure_rate * 100, 4) AS failure_rate_pct,
  check_status
FROM `project-2e312d70-4df2-4b6f-a60.walmart_audit.data_quality_results`
WHERE check_status != 'PASS'
ORDER BY failed_row_count DESC;


-- 8. Sample store weekly KPI output
SELECT
  store_id,
  store_type,
  store_size_tier,
  date_id,
  holiday_name,
  weekly_sales_total,
  previous_week_sales,
  wow_sales_growth_pct,
  sales_per_sqft,
  total_markdown,
  unemployment,
  fuel_price
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_weekly_kpis`
ORDER BY store_id, date_id
LIMIT 100;


-- 9. Sample department ranking output
SELECT
  store_id,
  dept_id,
  total_dept_sales,
  avg_weekly_dept_sales,
  dept_sales_share_within_store,
  dept_rank_within_store
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_department_ranking`
ORDER BY store_id, dept_rank_within_store
LIMIT 100;


-- 10. Sample holiday impact output
SELECT
  store_id,
  store_type,
  store_size_tier,
  holiday_name,
  holiday_week_count,
  avg_holiday_week_sales,
  avg_non_holiday_sales,
  holiday_lift_pct
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_holiday_impact`
ORDER BY store_id, holiday_name
LIMIT 100;


-- 11. Sample risk flag output
SELECT
  store_id,
  store_type,
  store_size_tier,
  date_id,
  holiday_name,
  weekly_sales_total,
  wow_sales_growth_pct,
  flag_sales_drop_20pct,
  flag_holiday_without_markdown,
  flag_high_unemployment,
  flag_high_fuel_price
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_risk_flags`
WHERE flag_sales_drop_20pct = TRUE
   OR flag_holiday_without_markdown = TRUE
   OR flag_high_unemployment = TRUE
   OR flag_high_fuel_price = TRUE
ORDER BY date_id, store_id
LIMIT 100;
