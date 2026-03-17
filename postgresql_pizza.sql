--for cleaning order_date
CREATE TABLE pizza_sales_raw (
  pizza_id int,
  order_id int,
  pizza_name_id text,
  quantity int,
  order_date text,
  order_time text,
  unit_price numeric,
  total_price numeric,
  pizza_size text,
  pizza_category text,
  pizza_ingredients text,
  pizza_name text
);

CREATE TABLE pizza_sales AS
SELECT
  pizza_id,
  order_id,
  pizza_name_id,
  quantity,
  to_date(order_date, 'DD/MM/YYYY')::date AS order_date,
  order_time::time,
  unit_price,
  total_price,
  pizza_size,
  pizza_category,
  pizza_ingredients,
  pizza_name
FROM pizza_sales_raw;

-- table preview
select * from pizza_sales
--KPI
--1.total revenue
SELECT SUM(total_price) AS Total_Revenue FROM pizza_sales;
--2.average order value
SELECT (SUM(total_price) / COUNT(DISTINCT order_id)) AS Avg_order_Value FROM pizza_sales 
--3.Total Pizzas Sold
SELECT SUM(quantity) AS Total_pizza_sold FROM pizza_sales
--4. total order
SELECT count(distinct(order_id)) from pizza_sales;
--Identify the highest-priced pizza.
SELECT distinct pizza_category, pizza_name_id, unit_price
FROM pizza_sales   -- or your menu/pizza table
WHERE unit_price = (SELECT MAX(unit_price) FROM pizza_sales);
--Identify the most common pizza size ordered.
SELECT pizza_size, SUM(quantity) AS total_quantity
FROM pizza_sales
GROUP BY pizza_size
ORDER BY total_quantity DESC
LIMIT 1;
--List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pizza_name_id,
    SUM(quantity) AS total_quantity
FROM pizza_sales
GROUP BY pizza_name_id
ORDER BY total_quantity DESC
LIMIT 5;


--Determine the distribution of orders by hour of the day.
SELECT 
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(*) AS order_count
FROM pizza_sales
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY order_hour;

--Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT 
    order_date,
    SUM(quantity) AS pizzas_that_day,
    AVG(SUM(quantity)) OVER () AS avg_pizzas_per_day
FROM pizza_sales
GROUP BY order_date
ORDER BY order_date;
--Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pizza_name_id,
    SUM(quantity * unit_price) AS revenue
FROM pizza_sales
GROUP BY pizza_name_id
ORDER BY revenue DESC
LIMIT 3;

--5. Average Pizzas Per Order
SELECT CAST(CAST(SUM(quantity) AS DECIMAL(10,2)) / 
CAST(COUNT(DISTINCT order_id) AS DECIMAL(10,2)) AS DECIMAL(10,2))
AS Avg_Pizzas_per_order
FROM pizza_sales;

--B. Daily Trend for Total Orders

SELECT
  to_char(order_date, 'Day') AS order_day,  -- or 'Dy' for Mon/Tue, 'DAY' for uppercase
  COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY to_char(order_date, 'Day');


--C.Monthly trend for orders

SELECT
    TRIM(TO_CHAR(order_date, 'Month')) AS month_name,
    COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales
GROUP BY
    EXTRACT(MONTH FROM order_date),
    TO_CHAR(order_date, 'Month')
ORDER BY
    EXTRACT(MONTH FROM order_date);

--Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
    pizza_category,
	SUM(total_price) AS type_revenue,
    ROUND(100.0 * SUM(total_price) / SUM(SUM(total_price)) OVER (), 2) AS revenue_pct
FROM pizza_sales
GROUP BY pizza_category
ORDER BY type_revenue DESC;

--Analyze the cumulative revenue generated over time.

SELECT 
    order_date,   -- or your date column
    SUM(total_price) AS daily_revenue,
    SUM(SUM(total_price)) OVER (ORDER BY order_date) AS cumulative_revenue
FROM pizza_sales
GROUP BY order_date
ORDER BY order_date;
--Determine the top 3 most ordered pizza types based on revenue for each pizza category.
	WITH ranked AS (
    SELECT 
        pizza_category,
        pizza_name_id,
        SUM(total_price) AS type_revenue,
        RANK() OVER (PARTITION BY pizza_category ORDER BY SUM(total_price) DESC) AS rn
    FROM pizza_sales
    GROUP BY pizza_category, pizza_name_id
)
SELECT pizza_category, pizza_name_id, type_revenue, rn AS rank
FROM ranked
WHERE rn <= 3
ORDER BY pizza_category, rn;