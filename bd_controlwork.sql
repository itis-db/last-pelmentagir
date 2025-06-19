-- 1. Продажи по категориям
SELECT
  p.category,
  SUM(oi.amount) AS total_sales,
  SUM(oi.amount) / COUNT(DISTINCT oi.order_id) AS avg_per_order,
  ROUND(SUM(oi.amount) * 100.0 / SUM(SUM(oi.amount)) OVER (), 2) AS category_share
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.category;

-- 2. Анализ покупателей
WITH order_totals AS (
  SELECT
    o.id AS order_id,
    o.customer_id,
    o.order_date,
    SUM(oi.amount) AS order_total
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY o.id, o.customer_id, o.order_date
),
customer_stats AS (
  SELECT *,
    SUM(order_total) OVER (PARTITION BY customer_id) AS total_spent,
    AVG(order_total) OVER (PARTITION BY customer_id) AS avg_order_amount
  FROM order_totals
)
SELECT
  customer_id,
  order_id,
  order_date,
  order_total,
  total_spent,
  avg_order_amount,
  order_total - avg_order_amount AS difference_from_avg
FROM customer_stats
ORDER BY customer_id, order_date;

-- 3. Сравнение продаж по месяцам
WITH monthly_sales AS (
  SELECT
    TO_CHAR(o.order_date, 'YYYY-MM') AS year_month,
    DATE_TRUNC('month', o.order_date) AS month_start,
    SUM(oi.amount) AS total_sales
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY 1, 2
),
sales_with_lag AS (
  SELECT *,
    LAG(total_sales) OVER (ORDER BY month_start) AS prev_month_sales,
    LAG(total_sales) OVER (ORDER BY month_start ROWS BETWEEN 12 PRECEDING AND 12 PRECEDING) AS prev_year_sales
  FROM monthly_sales
)
SELECT
  year_month,
  total_sales,
  ROUND(100.0 * (total_sales - prev_month_sales) / NULLIF(prev_month_sales, 0), 2) AS prev_month_diff,
  ROUND(100.0 * (total_sales - prev_year_sales) / NULLIF(prev_year_sales, 0), 2) AS prev_year_diff
FROM sales_with_lag
ORDER BY month_start;