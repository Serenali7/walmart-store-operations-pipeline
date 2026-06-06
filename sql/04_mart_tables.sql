-- 04_mart_tables.sql
-- Purpose: Create dashboard-ready mart tables for store operations reporting.
-- Layer: walmart_mart
--
-- Mart tables:
-- 1. mart_store_weekly_kpis
-- 2. mart_department_ranking
-- 3. mart_holiday_impact
-- 4. mart_store_risk_flags

CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_weekly_kpis` AS
WITH store_weekly_sales AS (
  SELECT
    store_id,
    date_id,
    SUM(weekly_sales) AS weekly_sales_total,
    COUNT(DISTINCT dept_id) AS active_dept_count,
    AVG(weekly_sales) AS avg_dept_weekly_sales
  FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`
  GROUP BY store_id, date_id
),

store_weekly_enriched AS (
  SELECT
    s.store_id,
    ds.store_type,
    ds.store_size_sqft,
    ds.store_size_tier,
    s.date_id,
    dc.year,
    dc.month,
    dc.quarter,
    dc.week_of_year,
    dc.holiday_name,
    dc.is_major_holiday,
    s.weekly_sales_total,
    s.active_dept_count,
    s.avg_dept_weekly_sales,
    SAFE_DIVIDE(s.weekly_sales_total, ds.store_size_sqft) AS sales_per_sqft,
    f.temperature,
    f.fuel_price,
    f.cpi,
    f.unemployment,
    COALESCE(f.markdown_1, 0)
      + COALESCE(f.markdown_2, 0)
      + COALESCE(f.markdown_3, 0)
      + COALESCE(f.markdown_4, 0)
      + COALESCE(f.markdown_5, 0) AS total_markdown
  FROM store_weekly_sales s
  LEFT JOIN `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_store` ds
    ON s.store_id = ds.store_id
  LEFT JOIN `project-2e312d70-4df2-4b6f-a60.walmart_core.dim_calendar` dc
    ON s.date_id = dc.date_id
  LEFT JOIN `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_store_weekly_features` f
    ON s.store_id = f.store_id
   AND s.date_id = f.date_id
)

SELECT
  *,
  LAG(weekly_sales_total) OVER (
    PARTITION BY store_id
    ORDER BY date_id
  ) AS previous_week_sales,
  SAFE_DIVIDE(
    weekly_sales_total - LAG(weekly_sales_total) OVER (
      PARTITION BY store_id
      ORDER BY date_id
    ),
    LAG(weekly_sales_total) OVER (
      PARTITION BY store_id
      ORDER BY date_id
    )
  ) AS wow_sales_growth_pct
FROM store_weekly_enriched;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_department_ranking` AS
WITH dept_sales AS (
  SELECT
    store_id,
    dept_id,
    SUM(weekly_sales) AS total_dept_sales,
    AVG(weekly_sales) AS avg_weekly_dept_sales,
    COUNT(DISTINCT date_id) AS active_weeks
  FROM `project-2e312d70-4df2-4b6f-a60.walmart_core.fact_weekly_sales`
  GROUP BY store_id, dept_id
)

SELECT
  store_id,
  dept_id,
  total_dept_sales,
  avg_weekly_dept_sales,
  active_weeks,
  SAFE_DIVIDE(
    total_dept_sales,
    SUM(total_dept_sales) OVER (PARTITION BY store_id)
  ) AS dept_sales_share_within_store,
  RANK() OVER (
    PARTITION BY store_id
    ORDER BY total_dept_sales DESC
  ) AS dept_rank_within_store
FROM dept_sales;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_holiday_impact` AS
WITH store_weekly AS (
  SELECT
    store_id,
    store_type,
    store_size_tier,
    date_id,
    holiday_name,
    is_major_holiday,
    weekly_sales_total
  FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_weekly_kpis`
),

baseline AS (
  SELECT
    store_id,
    AVG(weekly_sales_total) AS avg_non_holiday_sales
  FROM store_weekly
  WHERE is_major_holiday = FALSE
  GROUP BY store_id
)

SELECT
  sw.store_id,
  sw.store_type,
  sw.store_size_tier,
  sw.holiday_name,
  COUNT(*) AS holiday_week_count,
  AVG(sw.weekly_sales_total) AS avg_holiday_week_sales,
  b.avg_non_holiday_sales,
  SAFE_DIVIDE(
    AVG(sw.weekly_sales_total) - b.avg_non_holiday_sales,
    b.avg_non_holiday_sales
  ) AS holiday_lift_pct
FROM store_weekly sw
LEFT JOIN baseline b
  ON sw.store_id = b.store_id
WHERE sw.is_major_holiday = TRUE
GROUP BY
  sw.store_id,
  sw.store_type,
  sw.store_size_tier,
  sw.holiday_name,
  b.avg_non_holiday_sales;


CREATE OR REPLACE TABLE `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_risk_flags` AS
SELECT
  store_id,
  store_type,
  store_size_tier,
  date_id,
  holiday_name,
  is_major_holiday,
  weekly_sales_total,
  previous_week_sales,
  wow_sales_growth_pct,
  fuel_price,
  unemployment,
  total_markdown,
  CASE
    WHEN wow_sales_growth_pct <= -0.20 THEN TRUE
    ELSE FALSE
  END AS flag_sales_drop_20pct,
  CASE
    WHEN is_major_holiday = TRUE AND total_markdown = 0 THEN TRUE
    ELSE FALSE
  END AS flag_holiday_without_markdown,
  CASE
    WHEN unemployment >= 8 THEN TRUE
    ELSE FALSE
  END AS flag_high_unemployment,
  CASE
    WHEN fuel_price >= 3.5 THEN TRUE
    ELSE FALSE
  END AS flag_high_fuel_price
FROM `project-2e312d70-4df2-4b6f-a60.walmart_mart.mart_store_weekly_kpis`;
