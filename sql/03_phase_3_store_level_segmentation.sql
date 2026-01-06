-- Phase 3: Store-Level Segmentation (Trend + Seasonality Heterogeneity)
-- Purpose:
--   1) Check whether the aggregate upward trend is broad-based across stores
--   2) Measure seasonality strength per store (how strongly sales vary by week-of-year)

-- ============================================================
-- 3.1 Trend segmentation across stores (early vs late)
-- ============================================================

WITH week_sales AS (
  SELECT
    store,
    YEARWEEK(`Date`, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY store, YEARWEEK(`Date`, 3)
),
with_period AS (
  SELECT
    *,
    CASE
      WHEN year_week BETWEEN 201301 AND 201310 THEN 'early'
      WHEN year_week BETWEEN 201521 AND 201531 THEN 'late'
      ELSE 'in_between'
    END AS period
  FROM week_sales
),
ind_store AS (
  SELECT
    store,
    AVG(IF(period = 'early', weekly_sales, NULL)) AS avg_early_weekly_sales,
    AVG(IF(period = 'late',  weekly_sales, NULL)) AS avg_late_weekly_sales
  FROM with_period
  GROUP BY store
)
SELECT
  SUM(avg_early_weekly_sales < avg_late_weekly_sales) AS trend_count,
  SUM(avg_late_weekly_sales > 1.05 * avg_early_weekly_sales) AS up_stores,
  SUM(
    avg_late_weekly_sales <= 1.05 * avg_early_weekly_sales
    AND avg_late_weekly_sales >= 0.95 * avg_early_weekly_sales
  ) AS flat_stores,
  SUM(avg_late_weekly_sales < 0.95 * avg_early_weekly_sales) AS down_stores,
  COUNT(store) AS overall_count
FROM ind_store;

-- Notes:
-- - "up_stores" are stores with meaningful growth (>5%) from early to late period.
-- - "flat_stores" are within ±5% tolerance.
-- - "down_stores" declined by more than 5%.

-- ============================================================
-- 3.2 Seasonality strength per store (week-of-year profile)
-- ============================================================

WITH store_week AS (
  SELECT
    store,
    YEARWEEK(`Date`, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY store, YEARWEEK(`Date`, 3)
),
store_week_woy AS (
  SELECT
    store,
    year_week,
    (year_week % 100) AS week_of_year,
    weekly_sales
  FROM store_week
),
store_woy_profile AS (
  SELECT
    store,
    week_of_year,
    AVG(weekly_sales) AS avg_weekly_sales_woy
  FROM store_week_woy
  GROUP BY store, week_of_year
),
seasonality_strength AS (
  SELECT
    store,
    AVG(avg_weekly_sales_woy) AS avg_woy_level,
    STDDEV_SAMP(avg_weekly_sales_woy) AS woy_stddev,
    STDDEV_SAMP(avg_weekly_sales_woy) / NULLIF(AVG(avg_weekly_sales_woy), 0) AS seasonality_cv
  FROM store_woy_profile
  GROUP BY store
)
SELECT
  store,
  avg_woy_level,
  woy_stddev,
  seasonality_cv
FROM seasonality_strength
ORDER BY seasonality_cv DESC;

-- Interpretation:
-- - seasonality_cv measures how strongly a store's sales vary across weeks of the year.
-- - Higher seasonality_cv => stronger seasonality; lower => flatter behavior.
