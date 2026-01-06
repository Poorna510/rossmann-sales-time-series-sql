-- Phase 2: Robustness Checks (Aggregate Baseline)
-- Goal:
--   Validate that aggregate weekly patterns are not primarily driven by:
--   1) Store closures (Open=0)
--   2) A few extreme weeks (outliers)
--
-- Output expectation:
--   This phase produces diagnostic tables (not a single final table).
--   We confirm robustness if:
--     - Low-sales weeks correlate with higher closed rates, but not perfectly
--     - Mean and median weekly sales are close
--     - Trimmed mean is close to mean (optional but strong)

SELECT * FROM sales LIMIT 20;

-- ============================================================
-- Step 1: Are low weekly sales caused by store closures?
-- ============================================================

WITH week_stats AS (
  SELECT
    YEARWEEK(`Date`, 3) AS year_week,
    SUM(Sales) AS weekly_sales,
    SUM(Open = 0) AS closed_store_days,
    COUNT(*) AS total_store_days,
    SUM(CASE WHEN Open = 1 THEN Sales ELSE 0 END) AS weekly_sales_open_days
  FROM sales
  GROUP BY YEARWEEK(`Date`, 3)
)
SELECT
  year_week,
  weekly_sales,
  weekly_sales_open_days,
  closed_store_days,
  total_store_days,
  ROUND(closed_store_days / total_store_days, 4) AS closed_rate
FROM week_stats
ORDER BY weekly_sales;

-- Interpretation notes (keep as comments for GitHub):
-- - If lowest weekly_sales weeks also have high closed_rate, closures explain part of the drop.
-- - If not perfectly aligned, other factors beyond closures are influencing low weeks.

-- ============================================================
-- Step 2: Are weekly patterns dominated by a few extreme weeks?
-- Compare mean vs median weekly sales
-- ============================================================

WITH week_sales AS (
  SELECT
    YEARWEEK(`Date`, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY YEARWEEK(`Date`, 3)
),
ranked AS (
  SELECT
    weekly_sales,
    ROW_NUMBER() OVER (ORDER BY weekly_sales) AS rn,
    COUNT(*) OVER () AS n
  FROM week_sales
)
SELECT
  (SELECT ROUND(AVG(weekly_sales), 2) FROM week_sales) AS mean_weekly_sales,
  ROUND(AVG(weekly_sales), 2) AS median_weekly_sales
FROM ranked
WHERE rn IN (FLOOR((n + 1) / 2), FLOOR((n + 2) / 2));

-- Interpretation notes:
-- - If mean ≈ median, distribution is not heavily skewed by extreme weeks.

-- ============================================================
-- Step 3 (Optional but strong): Trim extremes and recompute mean
-- Removes lowest 3 and highest 3 weeks by weekly_sales
-- ============================================================

WITH week_sales AS (
  SELECT
    YEARWEEK(`Date`, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY YEARWEEK(`Date`, 3)
),
ranked_weeks AS (
  SELECT
    year_week,
    weekly_sales,
    ROW_NUMBER() OVER (ORDER BY weekly_sales) AS rn_low,
    ROW_NUMBER() OVER (ORDER BY weekly_sales DESC) AS rn_high
  FROM week_sales
)
SELECT
  'trimmed_excluding_3_low_3_high' AS method,
  ROUND(AVG(weekly_sales), 2) AS trimmed_mean_weekly_sales
FROM ranked_weeks
WHERE rn_low > 3
  AND rn_high > 3;

-- Interpretation notes:
-- - If trimmed_mean is close to mean, extremes do not dominate the overall pattern.

-- ============================================================
-- Phase 2 Summary (write this in README later, after freezing)
-- ============================================================
-- 1) Closures explain some low weeks, but not all (closed_rate correlates with low sales).
-- 2) Mean vs median gap is small, indicating no heavy skew from extreme weeks.
-- 3) Weekly baseline is robust enough to proceed to Phase 3 (Seasonality Confirmation).
