-- 累計

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
    a.actual
  FROM budget AS b
  LEFT JOIN actual AS a
    ON b.year_month = a.year_month
    AND b.dept = a.dept
)
SELECT
  year_month,
  dept,
  actual,
  SUM(actual) OVER (
    PARTITION BY dept
    ORDER BY year_month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_actual,
  SUM(budget) OVER (
    PARTITION BY dept
    ORDER BY year_month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_budget
FROM joined
ORDER BY dept, year_month;