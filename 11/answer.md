1) Сделал запрос с оконной функцией
```SELECT
   (e.first_name || ' ' || e.last_name) AS full_name,
   tn.title,
   s.amount AS salary,
   s.from_date AS salary_from,
   COALESCE(LAG(s.amount) OVER (PARTITION BY s.fk_employee ORDER BY s.from_date), 0) AS previous_salary,
   s.amount - COALESCE(LAG(s.amount) OVER (PARTITION BY s.fk_employee ORDER BY s.from_date), 0) AS salary_increase
   FROM salary s
   LEFT JOIN employee e ON e.id = s.fk_employee

         LEFT JOIN LATERAL (
   SELECT *
   FROM title t
   WHERE t.fk_employee = s.fk_employee
   AND t.from_date <= s.from_date
   AND (t.to_date IS NULL OR s.from_date < t.to_date)
   ORDER BY t.from_date DESC
   LIMIT 1
   ) t ON true

         LEFT JOIN title_name tn ON tn.id = t.fk_titlename

ORDER BY full_name, s.from_date;
```
3) | full_name      | title            | salary | salary_from | previous_salary | salary_increase |
   |:---------------|:-----------------|:-------|:------------|:----------------|:----------------| 
   | Eugene Aristov | manager          | 100000 | 2024-01-01  | 0               | 100000          |
   | Eugene Aristov | manager          | 200000 | 2024-02-01  | 100000          | 100000          |
   | Eugene Aristov | vice president   | 300000 | 2024-03-01  | 200000          | 100000          |
   | Ivan Ivanov    | teamlead         | 200000 | 2023-01-01  | 0               | 200000          |
   | Petr Petrov    | python developer | 200000 | 2024-03-01  | 0               | 200000          |
