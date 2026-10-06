# Retail Sales Analysis with PostgreSQL

A portfolio project using SQL to explore category sales, transaction timing and customer spending across **2022–2023**. The analysis covers **1,987 complete transactions** from a 2,000-row source file and answers ten business questions.

## Results at a glance

| Measure | Result |
|---|---:|
| Raw records | 2,000 |
| Records analysed | 1,987 |
| Incomplete records excluded | 13 |
| Distinct customer IDs analysed | 155 |
| Total recorded sales | 908,230 |
| Date range | 1 January 2022–31 December 2023 |

Amounts are in **source monetary units**: the CSV does not specify a currency. The source publisher and licence are not documented in the supplied files; this is a portfolio dataset, not a claim about a named retailer.

## Representative queries and findings

### 1. Which category generates the most sales?

```sql
SELECT category, SUM(total_sale) AS total_sales, COUNT(*) AS total_orders
FROM retail_sales_clean
GROUP BY category
ORDER BY total_sales DESC;
```

| Category | Total sales | Transactions |
|---|---:|---:|
| Electronics | 311,445 | 678 |
| Clothing | 309,995 | 698 |
| Beauty | 286,790 | 611 |

**Takeaway:** Electronics leads sales value, while Clothing has the most transactions. Sales value and transaction volume answer different questions; both are useful when reviewing category performance. These totals do not establish profitability.

### 2. Which month has the highest average transaction value in each year?

```sql
WITH monthly_sales AS (
    SELECT EXTRACT(YEAR FROM sale_date)::INTEGER AS year,
           EXTRACT(MONTH FROM sale_date)::INTEGER AS month,
           AVG(total_sale) AS average_sale
    FROM retail_sales_clean
    GROUP BY 1, 2
), ranked_months AS (
    SELECT *, RANK() OVER (
        PARTITION BY year ORDER BY average_sale DESC
    ) AS position
    FROM monthly_sales
)
SELECT year, month, ROUND(average_sale, 2) AS average_sale
FROM ranked_months
WHERE position = 1
ORDER BY year, month;
```

| Year | Month | Average transaction value |
|---|---|---:|
| 2022 | July | 541.34 |
| 2023 | February | 535.53 |

**Takeaway:** These months have the highest average basket values within their respective years. This is **not a ranking of total monthly revenue**, and two years of data alone do not establish a reliable seasonal pattern. Ties are retained by `RANK()`.

### 3. Which customer IDs have the highest aggregate sales?

```sql
SELECT customer_id, SUM(total_sale) AS total_sales
FROM retail_sales_clean
GROUP BY customer_id
ORDER BY total_sales DESC, customer_id
LIMIT 5;
```

| Customer ID | Total sales |
|---|---:|
| 3 | 38,440 |
| 1 | 30,750 |
| 5 | 30,405 |
| 2 | 25,295 |
| 4 | 23,580 |

**Takeaway:** These IDs are candidates for a closer review of purchase frequency and category mix. Historical sales alone do not measure customer lifetime value or future retention.

### 4. When are transactions recorded?

```sql
WITH shifts AS (
    SELECT CASE
        WHEN sale_time < TIME '12:00' THEN 'Morning'
        WHEN sale_time < TIME '18:00' THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift
    FROM retail_sales_clean
)
SELECT shift, COUNT(*) AS total_orders
FROM shifts
GROUP BY shift
ORDER BY CASE shift
    WHEN 'Morning' THEN 1 WHEN 'Afternoon' THEN 2 ELSE 3 END;
```

| Time band | Definition | Transactions |
|---|---|---:|
| Morning | Before 12:00 | 548 |
| Afternoon | 12:00–17:59 | 377 |
| Evening | 18:00 onwards | 1,062 |

**Takeaway:** Evening accounts for the most transactions in this dataset. This could inform a staffing review, but trading hours, hourly rates and workload would be needed before changing staffing levels. The time bands have different lengths; the CSV does not specify a timezone.

## All ten questions

1. Retrieve sales on 5 November 2022.
2. Find Clothing transactions with **4 or more** units in November 2022.
3. Calculate sales and transaction counts by category.
4. Calculate the transaction-weighted average age for Beauty purchases.
5. List transactions above 1,000 source monetary units.
6. Count transactions by category and gender.
7. Rank months by average transaction value within each year.
8. Find the top five customer IDs by total sales.
9. Count distinct customer IDs within each category.
10. Count transactions by morning, afternoon and evening bands.

Full SQL: [sql_query_project.sql](sql_query_project.sql).

## Data preparation and quality

- The raw CSV contains **2,000 unique transaction IDs**. Its `quantiy` header is a spelling error; map it to the database column `quantity`.
- Ten rows have missing ages. Three other rows have missing quantity, price, COGS and sale amounts. There are **13 incomplete rows in total**, not 22: several missing fields occur on the same rows.
- `retail_sales_clean` excludes rows with a missing value in any of the 11 fields. Every analysis query uses this view. The raw table remains intact.
- Complete-case exclusion is a transparent project choice, not the only valid approach. It also removes rows whose age is missing from sales-only analyses, which affects totals.
- Monetary columns use `NUMERIC(12,2)` rather than floating-point storage.
- Customer results refer to recorded IDs. Demographic consistency across transactions is not established, and average age is transaction-weighted.

## Run in PostgreSQL / pgAdmin

1. Create a database named `p1_retail_db` in pgAdmin and connect to it.
2. Execute [setup.sql](setup.sql) to create `retail_sales` and the cleaned view.
3. Import `SQL - Retail Sales Analysis_utf .csv` into `retail_sales` using CSV format, UTF-8 encoding, comma delimiter and **Header = Yes**. Import all 11 fields in table order; CSV column 8 (`quantiy`) maps to `quantity`. Empty values should import as NULL.
4. Import once into an empty table. The primary key rejects duplicate transaction IDs if the file is imported again.
5. Execute [sql_query_project.sql](sql_query_project.sql). Its first result should show **2,000 raw / 1,987 analysed / 13 excluded**.

The scripts do not create or switch databases automatically and do not delete source records.

## Reproduce the published results independently

```bash
python -m pip install pandas
python verify_results.py
```

[verify_results.py](verify_results.py) recomputes the README tables directly from the CSV and writes [results/](results/). The revised SQL was parsed with PostgreSQL's grammar via `pglast`; results were independently calculated with Python. A live PostgreSQL execution was not performed during this revision.

## Repository files

| File | Purpose |
|---|---|
| `setup.sql` | Table schema and complete-case view |
| `sql_query_project.sql` | Quality baseline and ten analytical queries |
| `SQL - Retail Sales Analysis_utf .csv` | Original source data |
| `verify_results.py` | Independent result reproduction |
| `results/` | CSV output tables and quality summary |

## Skills demonstrated

PostgreSQL · Data quality checks · Aggregation · CTEs · Window functions · Date filtering · `CASE` · Business interpretation

**Vaibhav Panchal**
