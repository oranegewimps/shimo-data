-- 予実比較
-- CSVファイルを直接読み込んでJOINする

WITH budget AS (
  SELECT *
  FROM read_csv_auto('C:\shimo-data\portfolio\01_budget_dashboard\data\budget.csv')
),
actual AS (
  SELECT *
  FROM read_csv_auto('C:\shimo-data\portfolio\01_budget_dashboard\data\actual.csv')
)
SELECT
  b.year_month,
  b.dept,
  b.budget,
  a.actual
FROM budget AS b
LEFT JOIN actual AS a
  ON b.year_month = a.year_month
  AND b.dept = a.dept
ORDER BY b.year_month, b.dept;