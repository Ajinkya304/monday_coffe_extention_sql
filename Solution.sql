--Monday Coffee -- Data Analysis
	select * from city;
	select * from products;
	select * from customers;
	select * from sales ;

-- reports And Data Analysis
--Q.1 coffee customers count
--how many people in each city are astimated to consume ccoffee. given that 25% of the population dose?
	select city_name ,
		round((population*0.25)/1000000,2) as coffe_consumer_milions ,city_rank 
	from city
	order by  coffe_consumer_milions desc;

--Total Revenue from Coffee Sales
--Q.2 What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
	select c1.city_name ,
		sum(total)as total_revenue 
	from sales  as s
	join customers as c on s.customer_id =c.customer_id
	join city as c1
		on c.city_id = c1.city_id
	where extract(year from s.sale_date)=2023
	 and  extract(quarter from s.sale_date)=4
	group by city_name
	order by total_revenue desc;

--Sales Count for Each Product
--Q.3How many units of each coffee product have been sold?
	select p.product_name, count(s.sale_id) as total_sales from sales	as s
	join products as p
		on s.product_id = p.product_id
	GROUP by product_name
	order by total_sales DESC;

--Average Sales Amount per City
--Q.4 What is the average sales amount per customer in each city?

	select c1.city_name ,
		sum(total)as total_revenue ,
		count(distinct s.customer_id)as total_cx,
		sum(total)/count(distinct s.customer_id) as avg_sales_per_customer
	from sales  as s
		join customers as c on s.customer_id =c.customer_id
		join city as c1
		on c.city_id = c1.city_id
		group by city_name
	order by total_revenue desc;
--Q5
--City Population and Coffee Consumers(25%)
--Provide a list of cities along with their populations and estimated coffee consumers.
--return city_name,total current cx, estimated coffee consumers (25%)
	WITH city_table AS (
    	SELECT 
        	city_name, 
        	ROUND((population * 0.25) / 1000000, 2) AS coffee_consumer_millions 
    	FROM city
	),
	customer_table AS (
    	SELECT 
        	c1.city_name,
        	COUNT(DISTINCT c.customer_id) AS unique_customers
    	FROM sales s
    	JOIN customers c ON s.customer_id = c.customer_id
    	JOIN city c1 ON c.city_id = c1.city_id
    	GROUP BY c1.city_name
	)
	SELECT 
    	ct.city_name,
    	ct.coffee_consumer_millions,
    	COALESCE(cte.unique_customers, 0) AS unique_customers
	FROM city_table ct
	LEFT JOIN customer_table cte ON ct.city_name = cte.city_name
	ORDER BY ct.city_name;

--Q6 Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?
	select * from (
           		SELECT  
					c.city_name,
					p.product_name,
					count(s.sale_id)as total_orders,
					Dense_rank() over(partition by city_name order by count(s.sale_id) DESC) as rank
					from sales as s
						join products as p on p.product_id = s.product_id
						join customers as c1 on c1.customer_id = s.customer_id
						join city as c on c.city_id = c1.city_id
					group by 1,2
					order by 1,3 DESC) as t1
	where rank <=3;
--Q.7
--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?
	select 
		c1.city_name,
		count(distinct c.customer_id)as unique_cx
	from city as c1
	left join 
		customers as c 
	ON c.city_id = c1.city_id
	join sales as s 
		ON s.customer_id = c.customer_id
	WHERE 
    	 s.product_id in(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
	GROUP by 1;
;
--Q.8
--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer
with city_table as(
select c1.city_name ,
		sum(total)as total_revenue ,
		count(distinct s.customer_id)as total_cx,
		sum(total)/count(distinct s.customer_id) as avg_sales_per_customer
	from sales  as s
		join customers as c on s.customer_id =c.customer_id
		join city as c1
		on c.city_id = c1.city_id
		group by city_name
	order by total_revenue desc
	),
city_rent as (
SELECT city_name,
estimated_rent
from city
	)
select  cr.city_name,
		ct.avg_sales_per_customer,
		cr.estimated_rent,
		ct.total_cx,
		cr.estimated_rent/ct.total_cx as avg_rent_Per_cx
		from city_rent as cr join city_table as ct 
		on cr.city_name=ct.city_name
		order by 2 DESC
		
--Q.9		
--Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) 
--in sales over different time periods (monthly).
--by each city
with city_table as
	(
	select 
		ci.city_name,
		extract(month from s.sale_date)as month,
		extract(year from s.sale_date)as year,
		sum(total)as total_sales
		from sales as s join customers  as c
		on c.customer_id = s.customer_id
		join city as ci on c.city_id = ci.city_id		
	    GROUP by 1,2,3
	    order by 1,3,2	
    ),
growth_ratio as(
	select city_name,
		month,
		year,
		total_sales as cx_monthly_sales,
		lag(total_sales,1)over(partition by city_name)as last_month_sales
		from city_table
  )
    select city_name,
			month,
			year,
			cx_monthly_sales,
			last_month_sales,
			round((cx_monthly_sales-last_month_sales)::numeric/last_month_sales::numeric*100,2) as growth_ratio
			from growth_ratio
			
--Q.10
--Market Potential Analysis
--Identify top 3 city based on highest sales, return city name,
--total sale, total rent, total customers, estimated coffee consumer
with city_table as(
select c1.city_name ,
		sum(total)as total_revenue ,
		count(distinct s.customer_id)as total_cx,
		sum(total)/count(distinct s.customer_id) as avg_sales_per_customer
	from sales  as s
		join customers as c on s.customer_id =c.customer_id
		join city as c1
		on c.city_id = c1.city_id
		group by city_name
	order by total_revenue desc
	),
city_rent as (
SELECT city_name,
estimated_rent,
population*0.25 as estimated_coffee_cunsumer
from city
	)
select  cr.city_name,
		ct.total_revenue ,
		cr.estimated_rent as total_rent,
		ct.total_cx,
		cr.estimated_coffee_cunsumer,
		cr.estimated_rent/ct.total_cx as avg_rent_Per_cx
		from city_rent as cr join city_table as ct 
		on cr.city_name=ct.city_name
		order by 2 DESC
/*
--recomendation
City1: Pune 
      1.avg rent per customer is less,
	  2.has heighest total revenue,
	  3.avg_sales per customer is high
	  
city2: Delhi
	  1.highest estimated coffee consumer is 7.7M
	  2. heighest total customer
	  3.avg rent per customer is 330
City3: Jipur
	  1.heighest customer number
	  2.avg rent per customer is 156
	  3.avg sales per customer is better which at 11.6K*/
	  
		