-- 達成率・ステータス付与

WITH budget AS (
  SELECT *
  FROM read_csv_auto('C:\shimo-data\portfolio\01_budget_dashboard\data\budget.csv')
),
actual AS (
  SELECT *
  FROM read_csv_auto('C:\shimo-data\portfolio\01_budget_dashboard\data\actual.csv')
),
joined AS (
  SELECT
    b.year_month,
    b.dept,
    b.budget,
    a.actual
  FROM budget AS b
  LEFT JOIN actual AS a
    ON b.year_month = a.year_month
    AND b.dept = a.dept
)
SELECT
  year_month,
  dept,
  budget,
  actual,
  ROUND(actual * 100.0 / budget, 1) AS achievement_rate,
  CASE
    WHEN actual >= budget THEN '達成'
    WHEN actual >= budget * 0.9 THEN '惜しい'
    ELSE '未達'
  END AS status
FROM joined
ORDER BY year_month, dept;