-- Phase 4: Intervention Analysis (Promos + Holidays)
-- Purpose:
--   Measure how promos and holidays create deviations from baseline sales,
--   and separate promo impact from seasonality via controls and residualization.

-- ============================================================
-- 4.0 Build weekly store-level table (VIEW)
-- ============================================================

DROP VIEW IF EXISTS store_week;

CREATE VIEW store_week AS
SELECT
  store,
  YEARWEEK(`Date`, 3) AS year_week,

  -- Week of year (use MIN(Date) inside the week to avoid ambiguity)
  WEEK(MIN(`Date`), 3) AS week_of_year,

  SUM(Sales) AS weekly_sales,

  MAX(Promo) AS promo_week,
  AVG(Promo) AS promo_share,

  MAX(CASE WHEN StateHoliday <> '0' THEN 1 ELSE 0 END) AS holiday_week,
  MAX(CASE
        WHEN StateHoliday = 'c' THEN 3
        WHEN StateHoliday = 'b' THEN 2
        WHEN StateHoliday = 'a' THEN 1
        ELSE 0
      END) AS state_holiday_strength,
  MAX(CASE
        WHEN StateHoliday IN ('a','b','c') THEN StateHoliday
        ELSE NULL
      END) AS state_holiday_type,

  MAX(SchoolHoliday) AS school_holiday_week
FROM sales
GROUP BY store, YEARWEEK(`Date`, 3);

-- Sanity peek
SELECT * FROM store_week LIMIT 10;

-- ============================================================
-- 4.1 Promo vs Non-Promo (naive, no seasonality control)
-- ============================================================

WITH promo_sales AS (
  SELECT
    store,
    AVG(CASE WHEN promo_week = 1 THEN weekly_sales END) AS promo_avg_weekly_sales,
    AVG(CASE WHEN promo_week = 0 THEN weekly_sales END) AS nonpromo_avg_weekly_sales,
    SUM(CASE WHEN promo_week = 1 THEN 1 ELSE 0 END) AS promo_weeks,
    SUM(CASE WHEN promo_week = 0 THEN 1 ELSE 0 END) AS nonpromo_weeks
  FROM store_week
  GROUP BY store
),
filtered AS (
  SELECT *
  FROM promo_sales
  WHERE promo_weeks >= 5 AND nonpromo_weeks >= 5
)
SELECT
  store,
  promo_weeks,
  nonpromo_weeks,
  promo_avg_weekly_sales,
  nonpromo_avg_weekly_sales,
  (promo_avg_weekly_sales - nonpromo_avg_weekly_sales) AS promo_lift
FROM filtered
ORDER BY promo_lift DESC
LIMIT 20;

WITH promo_sales AS (
  SELECT
    store,
    AVG(CASE WHEN promo_week = 1 THEN weekly_sales END) AS promo_avg_weekly_sales,
    AVG(CASE WHEN promo_week = 0 THEN weekly_sales END) AS nonpromo_avg_weekly_sales,
    SUM(CASE WHEN promo_week = 1 THEN 1 ELSE 0 END) AS promo_weeks,
    SUM(CASE WHEN promo_week = 0 THEN 1 ELSE 0 END) AS nonpromo_weeks
  FROM store_week
  GROUP BY store
),
filtered AS (
  SELECT *
  FROM promo_sales
  WHERE promo_weeks >= 5 AND nonpromo_weeks >= 5
)
SELECT
  COUNT(*) AS stores_considered,
  SUM(promo_avg_weekly_sales > nonpromo_avg_weekly_sales) AS stores_where_promo_gt_nonpromo,
  ROUND(100 * SUM(promo_avg_weekly_sales > nonpromo_avg_weekly_sales) / COUNT(*), 2) AS pct_stores_promo_gt_nonpromo
FROM filtered;

-- ============================================================
-- 4.2 Promo effect controlling for seasonality (store + week_of_year)
-- ============================================================

WITH promo_non_promo AS (
  SELECT
    store,
    week_of_year,
    AVG(CASE WHEN promo_week = 1 THEN weekly_sales END) AS promo_sales,
    AVG(CASE WHEN promo_week = 0 THEN weekly_sales END) AS non_promo_sales,
    AVG(weekly_sales) AS avg_sales,
    SUM(promo_week = 1) AS promo_weeks,
    SUM(promo_week = 0) AS nonpromo_weeks
  FROM store_week
  GROUP BY store, week_of_year
),
filtered AS (
  SELECT *
  FROM promo_non_promo
  WHERE promo_sales IS NOT NULL
    AND non_promo_sales IS NOT NULL
    AND promo_weeks >= 2
    AND nonpromo_weeks >= 2
)
SELECT
  COUNT(*) AS store_woy_cells_considered,
  SUM(promo_sales > non_promo_sales) AS cells_where_promo_gt_nonpromo,
  ROUND(100 * SUM(promo_sales > non_promo_sales) / COUNT(*), 2) AS pct_cells_promo_gt_nonpromo
FROM filtered;

-- ============================================================
-- 4.3 Baseline neutralization (residual lift)
-- Baseline = avg sales for each store + week_of_year using "clean" weeks
-- ============================================================

WITH baseline AS (
  SELECT
    store,
    week_of_year,
    AVG(weekly_sales) AS expected_sales
  FROM store_week
  WHERE promo_week = 0
    AND holiday_week = 0
  GROUP BY store, week_of_year
),
with_residuals AS (
  SELECT
    sw.store,
    sw.year_week,
    sw.week_of_year,
    sw.weekly_sales,
    sw.promo_week,
    sw.holiday_week,
    sw.state_holiday_type,
    sw.school_holiday_week,
    b.expected_sales,
    (sw.weekly_sales - b.expected_sales) AS residual_sales
  FROM store_week sw
  JOIN baseline b
    ON sw.store = b.store
   AND sw.week_of_year = b.week_of_year
),
promo_residual_compare AS (
  SELECT
    store,
    SUM(promo_week = 1) AS promo_weeks,
    SUM(promo_week = 0) AS nonpromo_weeks,
    AVG(CASE WHEN promo_week = 1 THEN residual_sales END) AS avg_residual_promo,
    AVG(CASE WHEN promo_week = 0 THEN residual_sales END) AS avg_residual_nonpromo,
    AVG(CASE WHEN promo_week = 1 THEN residual_sales END)
      - AVG(CASE WHEN promo_week = 0 THEN residual_sales END) AS residual_lift
  FROM with_residuals
  GROUP BY store
),
filtered AS (
  SELECT *
  FROM promo_residual_compare
  WHERE promo_weeks >= 5
    AND nonpromo_weeks >= 5
)
SELECT
  COUNT(*) AS stores_considered,
  AVG(avg_residual_promo) AS mean_residual_promo,
  AVG(avg_residual_nonpromo) AS mean_residual_nonpromo,
  AVG(residual_lift) AS mean_residual_lift,
  SUM(residual_lift > 0) AS stores_positive_lift,
  ROUND(100 * SUM(residual_lift > 0) / COUNT(*), 2) AS pct_stores_positive_lift
FROM filtered;

SELECT
  MIN(residual_lift) AS min_lift,
  MAX(residual_lift) AS max_lift,
  AVG(residual_lift) AS avg_lift,
  COUNT(*) AS stores
FROM (
  WITH baseline AS (
    SELECT store, week_of_year, AVG(weekly_sales) AS expected_sales
    FROM store_week
    WHERE promo_week = 0 AND holiday_week = 0
    GROUP BY store, week_of_year
  ),
  with_residuals AS (
    SELECT
      sw.store,
      sw.week_of_year,
      sw.promo_week,
      (sw.weekly_sales - b.expected_sales) AS residual_sales
    FROM store_week sw
    JOIN baseline b
      ON sw.store = b.store AND sw.week_of_year = b.week_of_year
  ),
  promo_residual_compare AS (
    SELECT
      store,
      SUM(promo_week = 1) AS promo_weeks,
      SUM(promo_week = 0) AS nonpromo_weeks,
      AVG(CASE WHEN promo_week = 1 THEN residual_sales END)
        - AVG(CASE WHEN promo_week = 0 THEN residual_sales END) AS residual_lift
    FROM with_residuals
    GROUP BY store
  )
  SELECT *
  FROM promo_residual_compare
  WHERE promo_weeks >= 5 AND nonpromo_weeks >= 5
) x;

-- ============================================================
-- 4.4 Heterogeneous promo effects (trend bucket x seasonality bucket)
-- ============================================================

WITH
baseline AS (
  SELECT
    store,
    week_of_year,
    AVG(weekly_sales) AS expected_sales
  FROM store_week
  WHERE promo_week = 0
    AND holiday_week = 0
  GROUP BY store, week_of_year
),
with_residuals AS (
  SELECT
    sw.store,
    sw.year_week,
    sw.week_of_year,
    sw.weekly_sales,
    sw.promo_week,
    (sw.weekly_sales - b.expected_sales) AS residual_sales
  FROM store_week sw
  JOIN baseline b
    ON sw.store = b.store AND sw.week_of_year = b.week_of_year
),
promo_residual_compare AS (
  SELECT
    store,
    SUM(promo_week = 1) AS promo_weeks,
    SUM(promo_week = 0) AS nonpromo_weeks,
    AVG(CASE WHEN promo_week = 1 THEN residual_sales END)
      - AVG(CASE WHEN promo_week = 0 THEN residual_sales END) AS residual_lift
  FROM with_residuals
  GROUP BY store
),
lift_filtered AS (
  SELECT *
  FROM promo_residual_compare
  WHERE promo_weeks >= 5 AND nonpromo_weeks >= 5
),

time_indexed AS (
  SELECT
    store,
    year_week,
    weekly_sales,
    DENSE_RANK() OVER (PARTITION BY store ORDER BY year_week) AS t
  FROM store_week
),
trend_slope AS (
  SELECT
    store,
    (COUNT(*) * SUM(t * weekly_sales) - SUM(t) * SUM(weekly_sales))
      / NULLIF((COUNT(*) * SUM(t * t) - SUM(t) * SUM(t)), 0) AS trend_slope
  FROM time_indexed
  GROUP BY store
),

avg_woy AS (
  SELECT
    store,
    week_of_year,
    AVG(weekly_sales) AS avg_weekly_sales_woy
  FROM store_week
  GROUP BY store, week_of_year
),
seasonality_strength AS (
  SELECT
    store,
    STDDEV_SAMP(avg_weekly_sales_woy) / NULLIF(AVG(avg_weekly_sales_woy), 0) AS seasonality_cv
  FROM avg_woy
  GROUP BY store
),

store_features AS (
  SELECT
    l.store,
    l.residual_lift,
    t.trend_slope,
    s.seasonality_cv
  FROM lift_filtered l
  JOIN trend_slope t ON t.store = l.store
  JOIN seasonality_strength s ON s.store = l.store
),
bucketed AS (
  SELECT
    *,
    NTILE(3) OVER (ORDER BY trend_slope) AS trend_tercile,
    NTILE(3) OVER (ORDER BY seasonality_cv) AS seasonality_tercile
  FROM store_features
)
SELECT
  CASE trend_tercile
    WHEN 1 THEN 'Declining (low slope)'
    WHEN 2 THEN 'Flat (mid slope)'
    WHEN 3 THEN 'Growing (high slope)'
  END AS trend_bucket,
  CASE seasonality_tercile
    WHEN 1 THEN 'Low seasonality'
    WHEN 2 THEN 'Medium seasonality'
    WHEN 3 THEN 'High seasonality'
  END AS seasonality_bucket,
  COUNT(*) AS stores,
  ROUND(AVG(residual_lift), 2) AS avg_residual_lift,
  ROUND(MIN(residual_lift), 2) AS min_residual_lift,
  ROUND(MAX(residual_lift), 2) AS max_residual_lift,
  ROUND(100 * AVG(residual_lift > 0), 2) AS pct_stores_positive_lift
FROM bucketed
GROUP BY trend_tercile, seasonality_tercile
ORDER BY trend_tercile, seasonality_tercile;
