create database Monday_coffee;
use Monday_coffee;


# MONDAY COFFEE DATA ANALYSIS

select * from city;
select * from products;
select * from customers;
select * from sales;

# ADD CONSTRAINTS
alter table city add constraint city_id primary key(city_id);
alter table customers add constraint customer_id primary key(customer_id);
alter table customers add constraint fk_city foreign key(city_id) references city(city_id);
alter table products add constraint product_id primary key(product_id);
alter table sales add constraint sale_id primary key (sale_id);
alter table sales add constraint fk_products foreign key(product_id) references products(product_id);
alter table sales add constraint fk_coustomers foreign key(customer_id) references customers(customer_id);


# Reports & Data Analysis

# 1)Coffee Consumers Count

#  How many peoples in each city are estimated to consume coffee,given that 25% of the population dose?

select
         city_name,
		 round((population*0.25/1000000),2) as coffee_comsume_peoples_in_millions 
from city 
order by 2 desc;


# 2) Total Revenue from Coffee Sales
# What is the total revenue generated from coffee sales across all cities in the last quarter of 2023

select 
       city_name,
       sum(total) as total_revenue  
from sales s join customers c  using(customer_id) 
join city ci using(city_id) 
where month(sale_date) in (10,11,12) and year(sale_date)=2023 
group by 1
order by 2 desc;


# 3) Sales Count for each Product
# How many units of each coffee product have been sold?
 select 
       product_name,
       count(sale_id) as total_orders
from products p left join sales s using(product_id)
group by 1 
order by 2 desc;


# 4) Average Sales Amount per City
# What is the average sales amount per customer in each city?
 select
       city_name,
       round(sum(total)/count(distinct s.customer_id),2) as avg_sales_per_cust 
from customers c join city ci using(city_id)
 join sales s using(customer_id)
 group by 1 
 order by 2 desc;
 
 
 # 5) City Population and Coffee Consumers
 # provied a list of cities along with their populations and estimated coffee consumers
with city_tab as
(select 
      city_name,
      round((population*0.25/1000000),2) as coffee_consumers_in_millions
from city),
customer_tab as 
(select 
       city_name,
       count(distinct customer_id) as unique_cust
from sales s join customers c using(customer_id) 
join city ct using (city_id)
 group by 1)
select 
      ct.city_name,
      ct.coffee_consumers_in_millions,
      cu.unique_cust 
from city_tab ct join customer_tab cu
on ct.city_name=cu.city_name 
order by coffee_consumers_in_millions  desc;
 
 
 # 6) Top Selling product By City
 # What is the top 3 selling product in each city based on sales volumne?
 
select * from
(select 
       p.product_name,
       ct.city_name,
       count(s.sale_id) as sales_volumn,
       dense_rank() over(partition by ct.city_name order by count(s.sale_id) desc) as rnk
 from city ct join customers cu using(city_id)
 join sales s using(customer_id) 
 join products p using(product_id) 
 group by 1,2)
temp1 where rnk<=3 ;
  
  # 7) Customer Segmentation by City
  # How many unique customers are there in each city who have purchase coffee products
  select  
        city_name,
        count(distinct customer_id) as unique_customer_count 
  from customers cu
  join city ct using (city_id)
  join sales s using (customer_id)
  join products p using(product_id)
  where p.product_id <=14
  group by city_name
  order by 2 desc;

# 8) Averege Sales Vs Rent
# Find each city and their average sale per customer and avg rent per customer
with city_tab as
(select 
       ci.city_name,
       sum(s.total) as total_revenue, 
       count(distinct s.customer_id) as total_cust,
       round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_cust
from sales s join customers c using(customer_id)
join city ci using(city_id)
group by 1 
order by 2 desc ),
city_rent as
(select 
       city_name,
       estimated_rent 
from city)
select 
      cr.city_name,
      cr.estimated_rent,
      ct.total_cust,
      ct.avg_sale_per_cust,
	  round(cr.estimated_rent/ct.total_cust,2) as avg_rent_per_cust
from city_rent as cr join city_tab ct
on cr.city_name=ct.city_name
order by 4 desc;

# 9) Monthly Sales Growth
# Sales growth rate: Calculate the percentage growth(or decline) in sales over different time periods(months)
 with monthly_sales as
(select 
      ci.city_name,
      month(s.sale_date) as month,
      year(sale_date) as year,
      sum(s.total) as total_sale
from sales s join customers c using(customer_id)
join city ci using(city_id)
group by ci.city_name,
month,year
order by 1,3,2),
growth_ratio as
(select
	   city_name,
       month,
       year,
       total_sale as current_month_sale,
       lag(total_sale,1) over(partition by city_name order by year,month) as last_month_sales
 from monthly_sales)
 select  
       city_name,
       month,
       year,
       current_month_sale,
       last_month_sales,
	   round( ((current_month_sale-last_month_sales)/last_month_sales)*100,2) as growth_ratio
from growth_ratio
where last_month_sales is not null;

# 10) market Potential Analysis
# Idendify top 3 city based on highest sales,return city name,total sales,totel rent,total customers,estimated coffee consumers

with city_tab as
(select 
       ci.city_name,
       sum(s.total) as total_revenue, 
       count(distinct s.customer_id) as total_cust,
        round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_cust
from sales s join products p using(product_id)
join customers c using(customer_id)
join city ci using(city_id)

group by 1
order by 2 desc ),
city_rent as
(select
       city_name,
       estimated_rent,
       round((population*0.25)/1000000,2) as estimated_coffee_comsumer_in_million 
from city)
select 
      cr.city_name,
      total_revenue,
      cr.estimated_rent as total_rent,
      ct.total_cust, 
      estimated_coffee_comsumer_in_million,
      ct.avg_sale_per_cust,
       round(cr.estimated_rent/ct.total_cust,2) as avg_rent_per_cust
from city_rent as cr join city_tab ct
on cr.city_name=ct.city_name
order by 2 desc;







# Recommendations:
# City 1 --- Pune
# i)  Avg rent per customer is very less
# ii) Highest total revenue
# iii) Avg_sales per customer is also high

# City 2:--- Delhi
# i) Highest estimated coffee consumer which is 7.7M
# ii) Highest total customer which is 68
# ii) Avg_rent per customer 330 under(500)

# City 3:--- Jaipur
# i) Highest customer number which is 69
# ii) Avg_rent per customer is very very less 156
# iii) Avg sales per customer is better which is 11.6k









