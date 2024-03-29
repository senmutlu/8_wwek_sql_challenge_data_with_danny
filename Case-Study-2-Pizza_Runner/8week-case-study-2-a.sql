--A. Pizza Metrics

--1 How many pizzas were ordered?


SELECT COUNT(pizza_id) AS ordered_pizza_count FROM customer_orders;

--2 How many unique customer orders were made?

SELECT COUNT(DISTINCT customer_id) AS unique_customer_count FROM customer_orders;

--3 How many successful orders were delivered by each runner?

SELECT COUNT(order_id) AS sucsessful_delivered_count FROM runner_orders
WHERE pickup_time IS NOT NULL;

--4 How many of each type of pizza was delivered?

SELECT p.pizza_name,COUNT(c.pizza_id) AS each_pizza_delivered_count FROM runner_orders AS r
LEFT JOIN customer_orders AS c ON c.order_id=r.order_id
INNER JOIN pizza_names AS p ON p.pizza_id=c.pizza_id
WHERE pickup_time IS NOT NULL
GROUP BY p.pizza_name;


--5 How many Vegetarian and Meatlovers were ordered by each customer?

SELECT
c.customer_id,
p.pizza_name,
COUNT(order_id) AS pizza_count
FROM customer_orders AS c
INNER JOIN pizza_names AS p ON p.pizza_id=c.pizza_id
GROUP BY c.customer_id,p.pizza_name
ORDER BY c.customer_id ASC;

--6 What was the maximum number of pizzas delivered in a single order?

SELECT c.order_id,COUNT(c.pizza_id) AS count_delivered_pizza FROM customer_orders AS c
INNER JOIN runner_orders AS r ON r.order_id=c.order_id
WHERE pickup_time IS NOT NULL
GROUP BY c.order_id
ORDER BY count_delivered_pizza DESC
LIMIT 1;

-- alternative solution, 
--'That solution is more efficient and dynamic to find maximum, second, third, etc. Just change the rank column value is enough'

WITH CTE AS (SELECT 
	c.order_id,
	COUNT(c.pizza_id) AS pizza_count,
	DENSE_RANK () OVER (ORDER BY COUNT(c.pizza_id) DESC )  AS rank 
FROM customer_orders AS C
INNER JOIN runner_orders AS R ON r.order_id=c.order_id
WHERE pickup_time IS NOT NULL 
GROUP BY c.order_id)
SELECT order_id,pizza_count FROM CTE
WHERE rank=1;






--7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT c.customer_id,COUNT(c.pizza_id) FROM customer_orders AS c
INNER JOIN runner_orders AS r ON r.order_id=c.order_id
WHERE r.pickup_time IS NOT NULL AND c.exclusions!='' OR c.extras!=''
GROUP BY c.customer_id;

--8 How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(c.pizza_id) had_both_changes_count FROM customer_orders AS c
INNER JOIN runner_orders AS r ON r.order_id=c.order_id
WHERE r.pickup_time IS NOT NULL AND c.exclusions!='' AND c.extras!='';

--9 What was the total volume of pizzas ordered for each hour of the day?

SELECT
	DATE_PART('hour',order_time) AS hour_of_day,
	COUNT(c.pizza_id) AS ordered_pizza_volume
FROM customer_orders AS c
GROUP BY hour_of_day;

--10 What was the volume of orders for each day of the week?


SELECT TO_CHAR(order_time,'DAY') AS day_of_week,
COUNT(c.pizza_id) AS ordered_pizza_volume
FROM customer_orders AS c
GROUP BY day_of_week;





