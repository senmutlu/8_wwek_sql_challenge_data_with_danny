--C. Ingredient Optimisation

--1 What are the standard ingredients for each pizza?

WITH pizza_recip_tab AS (SELECT pizza_id,ROW_NUMBER() OVER ( PARTITION BY pizza_id),toppings
FROM (SELECT pizza_id,REGEXP_SPLIT_TO_TABLE(toppings,',')::integer AS toppings FROM pizza_recipes) AS string_to_table)
SELECT topping_name,COUNT(DISTINCT pizza_id) FROM pizza_recip_tab
INNER JOIN pizza_toppings AS pt ON pt.topping_id=pizza_recip_tab.toppings
GROUP BY 1
HAVING COUNT(DISTINCT pizza_id)=2 
;

--2 What was the most commonly added extra?

WITH most_add_ex AS (SELECT extras_new,COUNT(pizza_id) AS amount,RANK()OVER(ORDER BY COUNT(pizza_id) DESC) FROM customer_order
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(extras,',') AS extras_new ON TRUE
WHERE extras_new!=''
GROUP BY extras_new)
SELECT topping_name,amount FROM most_add_ex
INNER JOIN pizza_toppings AS pt ON pt.topping_id=most_add_ex.extras_new::integer
WHERE rank=1
;


--3 What was the most common exclusion?

WITH most_com_exc AS (SELECT exc_new,amount_exc,RANK() OVER (ORDER BY amount_exc DESC) FROM (SELECT REGEXP_SPLIT_TO_TABLE(exclusions,',')AS exc_new,COUNT(pizza_id) amount_exc FROM customer_order
GROUP BY 1) AS most_add
WHERE exc_new!='')
SELECT topping_name,amount_exc FROM most_com_exc
INNER JOIN pizza_toppings AS pt ON pt.topping_id=most_com_exc.exc_new::integer
WHERE RANK=1;



--4 Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers


 
WITH order_full_table AS (WITH exclude_item AS (SELECT 	
	c.order_id,
	c.pizza_id,
	c.exclusions,				  
	STRING_AGG(pt.topping_name,',') AS excluded
FROM customer_orders AS c
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(exclusions,',') AS exclusions_new ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=exclusions_new::integer
WHERE exclusions_new!=''
GROUP BY c.pizza_id,c.order_id,c.exclusions)
, added_item AS (SELECT 	
	c.order_id,
	c.pizza_id,
	c.extras,			 
	STRING_AGG(pt.topping_name,',') AS extras_added
FROM customer_orders AS c
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(extras,',') AS extras_new ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=extras_new::integer
WHERE extras_new!=''
GROUP BY c.pizza_id,c.order_id,c.extras)
SELECT 
	co.order_id,
	'--' || pn.pizza_name AS pizza_name,
	CASE
	WHEN exc.excluded='Cheese,Cheese' THEN ' - Exclude Cheese' --That line added beacuse of order_id=4,pizza_id=1,exclusions=4 was ordered two time. Check customer_orders table out to see.
	WHEN exc.excluded IS NULL THEN ''
	ELSE CONCAT(' - Exclude',' ',exc.excluded)
	END AS excluded,
	CASE
	WHEN ex.extras_added IS NULL THEN ''
	ELSE CONCAT(' - Extra',' ',ex.extras_added)
	END AS extras_added
FROM customer_orders AS co
LEFT JOIN exclude_item AS exc ON exc.order_id=co.order_id AND exc.pizza_id=co.pizza_id AND exc.exclusions=co.exclusions
LEFT JOIN added_item AS ex ON ex.order_id=co.order_id AND ex.pizza_id=co.pizza_id AND ex.extras=co.extras
INNER JOIN pizza_names AS pn ON pn.pizza_id=co.pizza_id)
SELECT order_id,pizza_name || excluded || extras_added AS order_details FROM order_full_table
;



--5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
--and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH exclude_item AS (SELECT 	
	c.order_id,
	c.pizza_id,
	c.exclusions,
	pt.topping_id,
	pt.topping_name AS topping_name
FROM customer_orders AS c
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(exclusions,',') AS exclusions_new ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=exclusions_new::integer
WHERE exclusions_new!=''
)
, added_item AS (SELECT 	
	c.order_id,
	c.pizza_id,
	c.extras,
	pt.topping_id,
	pt.topping_name AS topping_name
FROM customer_orders AS c
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(extras,',') AS extras_new ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=extras_new::integer
WHERE extras_new!=''), 
ORDERS AS (
SELECT
	DISTINCT
	co.order_id,
	co.pizza_id,
	toppings_2::integer AS topping_id,
	pt.topping_name
FROM customer_orders AS co
INNER JOIN pizza_recipes AS pr ON pr.pizza_id=co.pizza_id
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(toppings,',') AS toppings_2 ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=toppings_2::integer	
),

full_table_ext_exc AS (
SELECT
	O.order_id,
    O.pizza_id,
    O.topping_id,
	O.topping_name
FROM orders AS o
LEFT JOIN exclude_item AS EXC ON EXC.order_id=O.order_id AND EXC.pizza_id=O.pizza_id AND EXC.topping_id=O.topping_id

UNION ALL
	
SELECT 
  	order_id,
    pizza_id,
    topping_id,
    topping_name
FROM added_item),
TOPPING_COUNT AS(
SELECT
	order_id,
	pizza_id,
	topping_name,
	COUNT(topping_name) as n
FROM full_table_ext_exc
GROUP BY 
	order_id,
	pizza_id,
	topping_name)
SELECT
order_id,
pizza_id,
STRING_AGG(
CASE
    WHEN n>1 THEN n || 'x' || topping_name
    ELSE topping_name
END,', ') as ingredient
FROM topping_count
GROUP BY 1,2
ORDER BY 3;


	

6--What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


WITH exclude_item AS (SELECT 	
	c.order_id,
	c.pizza_id,
	c.exclusions,
	pt.topping_id,
	pt.topping_name AS topping_name
FROM customer_orders AS c
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(exclusions,',') AS exclusions_new ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=exclusions_new::integer
WHERE exclusions_new!=''
)
, added_item AS (SELECT 	
	c.order_id,
	c.pizza_id,
	c.extras,
	pt.topping_id,
	pt.topping_name AS topping_name
FROM customer_orders AS c
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(extras,',') AS extras_new ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=extras_new::integer
WHERE extras_new!=''), 
ORDERS AS (
SELECT
	DISTINCT
	co.order_id,
	co.pizza_id,
	toppings_2::integer AS topping_id,
	pt.topping_name
FROM customer_orders AS co
INNER JOIN pizza_recipes AS pr ON pr.pizza_id=co.pizza_id
LEFT JOIN LATERAL REGEXP_SPLIT_TO_TABLE(toppings,',') AS toppings_2 ON TRUE
INNER JOIN pizza_toppingS AS pt ON pt.topping_id=toppings_2::integer	
),

full_table_ext_exc AS (
SELECT
	O.order_id,
    O.pizza_id,
    O.topping_id,
	O.topping_name
FROM orders AS o
LEFT JOIN exclude_item AS EXC ON EXC.order_id=O.order_id AND EXC.pizza_id=O.pizza_id AND EXC.topping_id=O.topping_id

UNION ALL
	
SELECT 
  	order_id,
    pizza_id,
    topping_id,
    topping_name
FROM added_item),
TOPPING_COUNT AS(
SELECT
	order_id,
	pizza_id,
	topping_name,
	COUNT(topping_name) as n
FROM full_table_ext_exc
GROUP BY 
	order_id,
	pizza_id,
	topping_name)
SELECT
tc.pizza_id,
tc.topping_name,
COUNT(tc.topping_name)AS ingredient_count
FROM topping_count AS tc
INNER JOIN runner_orders AS r ON r.order_id=tc.order_id
WHERE pickup_time IS NOT NULL
GROUP BY pizza_id,topping_name
ORDER BY ingredient_count DESC;
