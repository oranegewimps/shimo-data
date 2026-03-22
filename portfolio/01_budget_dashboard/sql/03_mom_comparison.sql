-- 前月比（MoM）

WITH actual AS (
  SELECT *
  FROM read_csv_auto('C:\shimo-data\portfolio\01_budget_dashboard\data\actual.csv')
),
monthly AS (
  SELECT
    year_month,
    dept,
    actual AS monthly_actual
  FROM actual
),
with_lag AS (
  SELECT
    year_month,
    dept,
    monthly_actual,
    LAG(monthly_actual) OVER (
      PARTITION BY dept
      ORDER BY year_month
    ) AS prev_actual
  FROM monthly
)
SELECT
  year_month,
  dept,
  monthly_actual,
  prev_actual,
  CASE
    WHEN prev_actual IS NULL THEN '初月'
    ELSE CAST(ROUND(monthly_actual * 100.0 / prev_actual, 1) AS VARCHAR)
  END AS mom_pct
FROM with_lag
ORDER BY dept, year_month;