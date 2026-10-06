-- PostgreSQL setup. First create/select p1_retail_db in pgAdmin.
-- Run this file, import the CSV into retail_sales, then run sql_query_project.sql.
-- The CSV header has a typo: quantiy. Map column 8 to quantity.
-- All 11 CSV columns match this table by position.
CREATE TABLE IF NOT EXISTS retail_sales (
    transactions_id INTEGER PRIMARY KEY,
    sale_date DATE,
    sale_time TIME,
    customer_id INTEGER,
    gender VARCHAR(15),
    age INTEGER,
    category VARCHAR(35),
    quantity INTEGER,
    price_per_unit NUMERIC(12,2),
    cogs NUMERIC(12,2),
    total_sale NUMERIC(12,2)
);

-- Preserve the raw import. Use complete records consistently for all questions.
CREATE OR REPLACE VIEW retail_sales_clean AS
SELECT * FROM retail_sales
WHERE transactions_id IS NOT NULL
  AND sale_date IS NOT NULL
  AND sale_time IS NOT NULL
  AND customer_id IS NOT NULL
  AND gender IS NOT NULL
  AND age IS NOT NULL
  AND category IS NOT NULL
  AND quantity IS NOT NULL
  AND price_per_unit IS NOT NULL
  AND cogs IS NOT NULL
  AND total_sale IS NOT NULL;
