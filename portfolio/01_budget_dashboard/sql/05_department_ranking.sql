-- 部門別ランキング

WITH actual AS (
  SELECT *
  FROM read_csv_auto('C:\shimo-data\portfolio\01_budget_dashboard\data\actual.csv')
),
budget AS (
  SELECT *
  FROM read_csv_auto('C:\shimo-data\portfolio\01_budget_dashboard\data\budget.csv')
),
joined AS (
  SELECT
    b.year_month,
    b.dept,
    b.budget,
    a.actual,
    ROUND(a.actual * 100.0 / b.budget, 1) AS achievement_rate
  FROM budget AS b
  LEFT JOIN actual AS a
    ON b.year_month = a.year_month
    AND b.dept = a.dept
),
dept_summary AS (
  SELECT
    dept,
    SUM(budget) AS total_budget,
    SUM(actual) AS total_actual,
    ROUND(SUM(actual) * 100.0 / SUM(budget), 1) AS overall_achievement_rate
  FROM joined
  GROUP BY dept
)
SELECT
  dept,
  total_budget,
  total_actual,
  overall_achievement_rate,
  RANK() OVER (ORDER BY overall_achievement_rate DESC) AS ranking
FROM dept_summary
ORDER BY ranking;