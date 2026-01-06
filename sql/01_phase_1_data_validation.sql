-- Phase 1: Data Validation & Baseline Time Structure (Exploratory)
-- Purpose:
--   1) Validate data integrity for time series analysis
--   2) Build a high-level baseline timeline (weekly) and inspect structure (non-confirmatory)

/* ============================================================
   1) DATA INTEGRITY CHECKS
   ============================================================ */

-- 1.1 Row count (sanity)
SELECT COUNT(*) AS total_rows FROM sales;

-- 1.2 Check duplicates: one row per (store, date)
SELECT
  Store,
  Date,
  COUNT(*) AS cnt
FROM sales
GROUP BY Store, Date
HAVING COUNT(*) > 1;

-- 1.3 Check nulls in key columns
SELECT *
FROM sales
WHERE Date IS NULL
   OR Store IS NULL
   OR Sales IS NULL
   OR Customers IS NULL
   OR Open IS NULL
   OR Promo IS NULL;

-- 1.4 Overall time range
SELECT MIN(Date) AS earliest_date, MAX(Date) AS latest_date
FROM sales;

-- 1.5 Global date continuity (distinct dates)
SELECT *
FROM (
  SELECT
    Date,
    LAG(Date) OVER (ORDER BY Date) AS prev_date
  FROM (SELECT DISTINCT Date FROM sales) d
) x
WHERE prev_date IS NOT NULL
  AND prev_date + INTERVAL 1 DAY <> Date
LIMIT 10;

-- 1.6 Zero sales cases (flag)
-- Note: Zero sales can occur even when Open=1 (data/business behavior to be investigated later)
SELECT
  Open,
  COUNT(*) AS rows_cnt,
  SUM(CASE WHEN Sales = 0 THEN 1 ELSE 0 END) AS zero_sales_rows
FROM sales
GROUP BY Open;

SELECT *
FROM sales
WHERE Sales = 0
  AND Open <> 0
LIMIT 50;

/* ============================================================
   2) STORE-LEVEL COMPLETENESS (IMPORTANT ADD)
   ============================================================ */

-- 2.1 Days present per store (quick completeness check)
SELECT
  Store,
  COUNT(*) AS days_present,
  MIN(Date) AS store_start_date,
  MAX(Date) AS store_end_date
FROM sales
GROUP BY Store
ORDER BY days_present ASC
LIMIT 20;

-- 2.2 Missing dates per store (simple gap check at store level)
-- Counts gaps where the next available date is > 1 day after previous date
SELECT
  Store,
  SUM(CASE WHEN prev_date IS NOT NULL AND prev_date + INTERVAL 1 DAY <> Date THEN 1 ELSE 0 END) AS gap_count
FROM (
  SELECT
    Store,
    Date,
    LAG(Date) OVER (PARTITION BY Store ORDER BY Date) AS prev_date
  FROM sales
) s
GROUP BY Store
ORDER BY gap_count DESC
LIMIT 20;

/* ============================================================
   3) BASELINE TIME STRUCTURE (WEEKLY) - EXPLORATORY
   ============================================================ */

-- Rationale:
-- Daily data is noisy; weekly aggregation provides a cleaner baseline.
-- Daily (day-of-week) effects likely exist and will be considered later.

WITH week_sales AS (
  SELECT
    YEARWEEK(Date, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY YEARWEEK(Date, 3)
)
SELECT *
FROM week_sales
ORDER BY year_week;

-- 3.1 Early vs late comparison (exploratory hint, not confirmation)
WITH week_sales AS (
  SELECT
    YEARWEEK(Date, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY YEARWEEK(Date, 3)
),
period_table AS (
  SELECT
    year_week,
    weekly_sales,
    CASE
      WHEN year_week BETWEEN 201301 AND 201310 THEN 'early'
      WHEN year_week BETWEEN 201521 AND 201531 THEN 'late'
      ELSE NULL
    END AS period
  FROM week_sales
)
SELECT
  period,
  AVG(weekly_sales) AS avg_weekly_sales,
  SUM(weekly_sales) AS total_sales
FROM period_table
WHERE period IS NOT NULL
GROUP BY period;

-- 3.2 Rolling sums/averages (structure inspection)
WITH week_sales AS (
  SELECT
    YEARWEEK(Date, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY YEARWEEK(Date, 3)
)
SELECT
  year_week,
  weekly_sales,
  SUM(weekly_sales) OVER (ORDER BY year_week ROWS BETWEEN 10 PRECEDING AND CURRENT ROW) AS rolling_sum_11w,
  AVG(weekly_sales) OVER (ORDER BY year_week ROWS BETWEEN 10 PRECEDING AND CURRENT ROW) AS rolling_avg_11w
FROM week_sales
ORDER BY year_week;

-- 3.3 Candidate seasonality check (week-of-year) - exploratory only
WITH week_sales AS (
  SELECT
    YEARWEEK(Date, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY YEARWEEK(Date, 3)
)
SELECT
  (year_week % 100) AS week_of_year,
  SUM(weekly_sales) AS total_sales,
  AVG(weekly_sales) AS avg_sales
FROM week_sales
GROUP BY (year_week % 100)
ORDER BY total_sales;

-- 3.4 Rolling volatility (structure inspection)
WITH week_sales AS (
  SELECT
    YEARWEEK(Date, 3) AS year_week,
    SUM(Sales) AS weekly_sales
  FROM sales
  GROUP BY YEARWEEK(Date, 3)
)
SELECT
  year_week,
  weekly_sales,
  ROUND(
    STDDEV_SAMP(weekly_sales) OVER (ORDER BY year_week ROWS BETWEEN 10 PRECEDING AND CURRENT ROW),
    2
  ) AS rolling_stddev_11w
FROM week_sales
ORDER BY year_week;
