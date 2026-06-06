-- 05_data_quality_checks.sql
-- Purpose: Create an audit table to validate the pipeline.
-- Layer: walmart_audit
--
-- Checks included:
-- 1. Row count reconciliation
-- 2. Null business key checks
-- 3. Duplicate key checks
-- 4. Referential integrity checks
-- 5. Business anomaly checks
-- 6. Mart-level duplicate key checks

CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_audit.data_quality_results` AS
WITH checks AS (

  -- 1. Row count reconciliation: raw vs staging
  SELECT
    'raw_to_staging_sales_row_count' AS check_name,
    'row_count_reconciliation' AS check_category,
    'Sales raw row count should match staging row count' AS check_description,
    ABS(
      (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_train_sales`)
      -
      (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`)
    ) AS failed_row_count,
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_train_sales`) AS total_row_count,
    'ERROR' AS severity

  UNION ALL

  SELECT
    'raw_to_staging_stores_row_count',
    'row_count_reconciliation',
    'Stores raw row count should match staging row count',
    ABS(
      (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_stores`)
      -
      (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_stores`)
    ),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_stores`),
    'ERROR'

  UNION ALL

  SELECT
    'raw_to_staging_features_row_count',
    'row_count_reconciliation',
    'Features raw row count should match staging row count',
    ABS(
      (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_features`)
      -
      (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`)
    ),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_raw.raw_features`),
    'ERROR'

  UNION ALL

  -- 2. Null key checks
  SELECT
    'stg_sales_null_business_keys',
    'null_check',
    'Sales staging table should not have null store_id, dept_id, or week_date',
    (SELECT COUNT(*)
     FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`
     WHERE store_id IS NULL
        OR dept_id IS NULL
        OR week_date IS NULL),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`),
    'ERROR'

  UNION ALL

  SELECT
    'stg_features_null_business_keys',
    'null_check',
    'Features staging table should not have null store_id or week_date',
    (SELECT COUNT(*)
     FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`
     WHERE store_id IS NULL
        OR week_date IS NULL),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`),
    'ERROR'

  UNION ALL

  -- 3. Duplicate key checks
  SELECT
    'stg_sales_duplicate_store_dept_week',
    'duplicate_check',
    'Sales should have one row per store_id, dept_id, and week_date',
    (SELECT COUNT(*)
     FROM (
       SELECT store_id, dept_id, week_date, COUNT(*) AS row_count
       FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`
       GROUP BY store_id, dept_id, week_date
       HAVING COUNT(*) > 1
     )),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_sales`),
    'ERROR'

  UNION ALL

  SELECT
    'stg_features_duplicate_store_week',
    'duplicate_check',
    'Features should have one row per store_id and week_date',
    (SELECT COUNT(*)
     FROM (
       SELECT store_id, week_date, COUNT(*) AS row_count
       FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`
       GROUP BY store_id, week_date
       HAVING COUNT(*) > 1
     )),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_staging.stg_features`),
    'ERROR'

  UNION ALL

  -- 4. Referential integrity checks: fact tables should match dimensions
  SELECT
    'fact_sales_unmatched_store_id',
    'referential_integrity',
    'Every store_id in fact_weekly_sales should exist in dim_store',
    (SELECT COUNT(*)
     FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales` f
     LEFT JOIN `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_store` d
       ON f.store_id = d.store_id
     WHERE d.store_id IS NULL),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`),
    'ERROR'

  UNION ALL

  SELECT
    'fact_sales_unmatched_dept_id',
    'referential_integrity',
    'Every dept_id in fact_weekly_sales should exist in dim_department',
    (SELECT COUNT(*)
     FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales` f
     LEFT JOIN `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_department` d
       ON f.dept_id = d.dept_id
     WHERE d.dept_id IS NULL),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`),
    'ERROR'

  UNION ALL

  SELECT
    'fact_sales_unmatched_date_id',
    'referential_integrity',
    'Every date_id in fact_weekly_sales should exist in dim_calendar',
    (SELECT COUNT(*)
     FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales` f
     LEFT JOIN `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_calendar` d
       ON f.date_id = d.date_id
     WHERE d.date_id IS NULL),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`),
    'ERROR'

  UNION ALL

  -- 5. Business anomaly checks
  SELECT
    'sales_negative_values',
    'business_anomaly_check',
    'Negative weekly sales should be reviewed as potential returns or adjustments',
    (SELECT COUNT(*)
     FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`
     WHERE weekly_sales < 0),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`),
    'WARNING'

  UNION ALL

  -- 6. Mart-level duplicate key checks
  SELECT
    'mart_store_weekly_duplicate_key',
    'mart_quality_check',
    'Store weekly KPI mart should have one row per store_id and date_id',
    (SELECT COUNT(*)
     FROM (
       SELECT store_id, date_id, COUNT(*) AS row_count
       FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_weekly_kpis`
       GROUP BY store_id, date_id
       HAVING COUNT(*) > 1
     )),
    (SELECT COUNT(*) FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_weekly_kpis`),
    'ERROR'

)

SELECT
  CURRENT_TIMESTAMP() AS audit_run_timestamp,
  check_name,
  check_category,
  check_description,
  severity,
  failed_row_count,
  total_row_count,
  SAFE_DIVIDE(failed_row_count, total_row_count) AS failure_rate,
  CASE
    WHEN failed_row_count = 0 THEN 'PASS'
    WHEN severity = 'WARNING' THEN 'REVIEW'
    ELSE 'FAIL'
  END AS check_status
FROM checks;
