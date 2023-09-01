--B. Runner and Customer Experience

--1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

-- If using the date_part function without plus 4, 
--it turns the 2022-01-01 53.weeks because the last week of 2020-12-28 until 2021-01-03.
--That's why 2021-01-08 turns out the first week.

WITH runner_signed AS (SELECT 
    runner_id, 
    registration_date, 
    DATE_PART('week',registration_date+4)  AS start_of_week 
  FROM 
    runners)
SELECT start_of_week,COUNT(runner_id) FROM runner_signed
GROUP BY 1
ORDER BY 1
;


--2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT DISTINCT r.runner_id,AVG(r.pickup_time-c.order_time) AS avg_pickup_min FROM runner_orders AS r
INNER JOIN customer_orders AS c ON c.order_id=r.order_id
WHERE pickup_time IS NOT NULL
GROUP BY r.runner_id
ORDER BY r.runner_id;

--Alternate solution
SELECT DISTINCT r.runner_id,AVG(DATE_PART('minutes',r.pickup_time-c.order_time))::integer AS avg_pickup_min FROM runner_orders AS r
INNER JOIN customer_orders AS c ON c.order_id=r.order_id
WHERE pickup_time IS NOT NULL
GROUP BY r.runner_id
ORDER BY r.runner_id;


--3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH CTE AS (SELECT r.order_id,COUNT(c.pizza_id) AS number_of_pizzas,DATE_PART('minutes',r.pickup_time-c.order_time) AS prepare_time FROM runner_orders AS r
INNER JOIN customer_orders AS c ON c.order_id=r.order_id
WHERE pickup_time IS NOT NULL
GROUP BY r.order_id,prepare_time
ORDER BY number_of_pizzas DESC)
SELECT number_of_pizzas,AVG(prepare_time) FROM cte
GROUP BY number_of_pizzas;

--4 What was the average distance travelled for each customer?

SELECT DISTINCT c.customer_id AS customer_id,ROUND(AVG(r.distance),2) FROM runner_orders AS r
INNER JOIN customer_orders AS c ON c.order_id=r.order_id
GROUP BY customer_id;

--5 What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration)-MIN(duration) long_and_short_difference FROM runner_orders
WHERE pickup_time IS NOT NULL;

--6 What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT order_id,runner_id,ROUND(AVG(distance/duration),2)*100 AS speed_km_s FROM runner_orders
WHERE pickup_time IS NOT NULL
GROUP BY order_id,runner_id;

--7 What is the successful delivery percentage for each runner?

SELECT runner_id, 
  round(count(pickup_time)::numeric/ count(order_id)*100) AS delivery_percentage
FROM runner_orders
GROUP BY runner_id;
