-- Retail sales analysis | PostgreSQL | database: p1_retail_db
-- Prerequisites: run setup.sql and import the CSV into retail_sales.
-- All ten questions use the same complete-case view; the raw table is retained.

-- Data-quality baseline: show how many rows are excluded, rather than deleting them.
SELECT (SELECT COUNT(*) FROM retail_sales) AS raw_rows,
       (SELECT COUNT(*) FROM retail_sales_clean) AS analysed_rows,
       (SELECT COUNT(*) FROM retail_sales) -
       (SELECT COUNT(*) FROM retail_sales_clean) AS excluded_rows;

SELECT COUNT(DISTINCT customer_id) AS unique_customers FROM retail_sales_clean;
SELECT DISTINCT category FROM retail_sales_clean ORDER BY category;

-- 1. Sales on 5 November 2022.
SELECT * FROM retail_sales_clean WHERE sale_date = DATE '2022-11-05';

-- 2. Clothing transactions with 4 or more units in November 2022.
SELECT * FROM retail_sales_clean
WHERE category = 'Clothing'
  AND sale_date >= DATE '2022-11-01'
  AND sale_date < DATE '2022-12-01'
  AND quantity >= 4;

-- 3. Total sales and transaction count by category.
SELECT category, SUM(total_sale) AS total_sales, COUNT(*) AS total_orders
FROM retail_sales_clean
GROUP BY category
ORDER BY total_sales DESC;

-- 4. Transaction-weighted average customer age for Beauty purchases.
-- Repeat customers contribute once per qualifying transaction, not once per person.
SELECT ROUND(AVG(age), 2) AS average_age
FROM retail_sales_clean WHERE category = 'Beauty';

-- 5. Transactions with a recorded sale amount above 1,000 source monetary units.
SELECT * FROM retail_sales_clean WHERE total_sale > 1000;

-- 6. Transaction counts by category and gender.
SELECT category, gender, COUNT(*) AS total_transactions
FROM retail_sales_clean
GROUP BY category, gender
ORDER BY category, gender;

-- 7. Month with the highest average transaction value in each year (ties retained).
WITH monthly_sales AS (
    SELECT EXTRACT(YEAR FROM sale_date)::INTEGER AS year,
           EXTRACT(MONTH FROM sale_date)::INTEGER AS month,
           AVG(total_sale) AS average_sale
    FROM retail_sales_clean
    GROUP BY 1, 2
), ranked_months AS (
    SELECT *, RANK() OVER (PARTITION BY year ORDER BY average_sale DESC) AS position
    FROM monthly_sales
)
SELECT year, month, ROUND(average_sale, 2) AS average_sale
FROM ranked_months WHERE position = 1 ORDER BY year, month;

-- 8. Top five customer IDs by aggregate sales; stable ordering breaks ties.
SELECT customer_id, SUM(total_sale) AS total_sales
FROM retail_sales_clean
GROUP BY customer_id
ORDER BY total_sales DESC, customer_id
LIMIT 5;

-- 9. Distinct customer IDs within each category (counts overlap across categories).
SELECT category, COUNT(DISTINCT customer_id) AS unique_customers
FROM retail_sales_clean GROUP BY category ORDER BY category;

-- 10. Transaction counts by time band.
-- Morning: before 12:00; Afternoon: 12:00–17:59; Evening: 18:00 onwards.
WITH shifts AS (
    SELECT CASE WHEN sale_time < TIME '12:00' THEN 'Morning'
                WHEN sale_time < TIME '18:00' THEN 'Afternoon'
                ELSE 'Evening' END AS shift
    FROM retail_sales_clean
)
SELECT shift, COUNT(*) AS total_orders
FROM shifts GROUP BY shift
ORDER BY CASE shift WHEN 'Morning' THEN 1 WHEN 'Afternoon' THEN 2 ELSE 3 END;
