#phase 5
/* ============================
   PHASE 5 — Synthesis & Business Narrative (SQL outputs)
   Goal: Produce “final tables” you can paste into README / slides.
   Uses: store_week view (already created)
   ============================ */

WITH
/* ---------- (1) Baseline + residual per store-week (from Phase 4.3) ---------- */
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
    sw.holiday_week,
    sw.school_holiday_week,
    sw.state_holiday_type,
    b.expected_sales,
    (sw.weekly_sales - b.expected_sales) AS residual_sales
  FROM store_week sw
  JOIN baseline b
    ON b.store = sw.store
   AND b.week_of_year = sw.week_of_year
),

/* ---------- (2) Store-level promo lift summary (Phase 4.3 output distilled) ---------- */
store_lift AS (
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
store_lift_filtered AS (
  SELECT *
  FROM store_lift
  WHERE promo_weeks >= 5
    AND nonpromo_weeks >= 5
    AND avg_residual_promo IS NOT NULL
    AND avg_residual_nonpromo IS NOT NULL
),

/* ---------- (3) Overall headline KPIs (for README) ---------- */
headline_kpis AS (
  SELECT
    COUNT(*) AS stores_considered,
    ROUND(AVG(residual_lift), 2) AS avg_weekly_promo_lift,
    ROUND(MIN(residual_lift), 2) AS min_weekly_promo_lift,
    ROUND(MAX(residual_lift), 2) AS max_weekly_promo_lift,
    ROUND(100 * AVG(residual_lift > 0), 2) AS pct_stores_positive_lift
  FROM store_lift_filtered
),

/* ---------- (4) Intervention groups (promo vs holiday) for narrative ---------- */
intervention_groups AS (
  SELECT
    CASE
      WHEN promo_week = 0 AND holiday_week = 0 THEN 'Neither'
      WHEN promo_week = 1 AND holiday_week = 0 THEN 'Promo only'
      WHEN promo_week = 0 AND holiday_week = 1 THEN 'Holiday only'
      WHEN promo_week = 1 AND holiday_week = 1 THEN 'Promo + Holiday'
    END AS group_name,
    residual_sales
  FROM with_residuals
),
group_summary AS (
  SELECT
    group_name,
    COUNT(*) AS store_weeks,
    ROUND(AVG(residual_sales), 2) AS avg_residual
  FROM intervention_groups
  GROUP BY group_name
),

/* ---------- (5) Store rankings (top/bottom) ---------- */
ranked AS (
  SELECT
    store,
    promo_weeks,
    nonpromo_weeks,
    ROUND(residual_lift, 2) AS residual_lift,
    DENSE_RANK() OVER (ORDER BY residual_lift DESC) AS lift_rank_desc,
    DENSE_RANK() OVER (ORDER BY residual_lift ASC)  AS lift_rank_asc
  FROM store_lift_filtered
)

/* ============================
   OUTPUT 1: Headline KPIs
   ============================ */
SELECT * FROM headline_kpis;

-- ============================
-- OUTPUT 2: Promo vs Holiday group summary (Phase 5 narrative table)
-- ============================
SELECT * FROM group_summary
ORDER BY FIELD(group_name, 'Neither', 'Promo only', 'Holiday only', 'Promo + Holiday');

-- ============================
-- OUTPUT 3: Top 20 stores by promo lift (who benefits most)
-- ============================
SELECT
  store, promo_weeks, nonpromo_weeks, residual_lift
FROM ranked
WHERE lift_rank_desc <= 20
ORDER BY residual_lift DESC;

-- ============================
-- OUTPUT 4: Bottom 20 stores by promo lift (who benefits least)
-- ============================
SELECT
  store, promo_weeks, nonpromo_weeks, residual_lift
FROM ranked
WHERE lift_rank_asc <= 20
ORDER BY residual_lift ASC;
