create database ecommerce_practice;
use ecommerce_practice;

drop database ecommerce_practice; 
CREATE TABLE customers (
 customer_id INTEGER PRIMARY KEY, customer_name VARCHAR(100), city VARCHAR(50), signup_date DATE
);
alter table customers rename column city to region;
CREATE TABLE products (
 product_id INTEGER PRIMARY KEY, product_name VARCHAR(100), category VARCHAR(50),
 unit_price DECIMAL(10,2), unit_cost DECIMAL(10,2)
);
CREATE TABLE orders (
 order_id INTEGER PRIMARY KEY, customer_id INTEGER, order_date DATE, status VARCHAR(20), sales_channel VARCHAR(20),
 FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);
alter table orders 
rename column  status to order_status;
alter table orders
add column payment_method varchar(20);
CREATE TABLE order_items (
 order_id INTEGER, product_id INTEGER, quantity INTEGER,
 FOREIGN KEY(order_id) REFERENCES orders(order_id), FOREIGN KEY(product_id) REFERENCES products(product_id)
);
alter table  order_items
add column discount_pct decimal(5,2) default 0;

ALTER TABLE order_items
ADD COLUMN order_item_id INT AUTO_INCREMENT PRIMARY KEY;
DESC orders;
desc order_items;
desc customers;
desc products;

UPDATE orders
SET payment_method = 'UPI'
WHERE order_id in (1002, 1004, 1006, 1008, 1010, 1012, 1014, 1016);

UPDATE orders
SET payment_method = 'Card'
WHERE order_id IN (1001, 1003, 1005, 1007, 1009, 1011, 1013, 1015,1040,1037,1029,1024);

update order_items 
set discount_pct = 5
where order_id in (1001,1004,1007,1009,1013,1016);

update order_items
set discount_pct = 10
where order_id in (1002,1010,1015);

update order_items
set discount_pct = 15
where order_id = 1006;


SELECT * FROM  customers;
SELECT * FROM  products;
SELECT * FROM  orders;
SELECT * FROM  order_items;

select 'customers' as table_name, count(*) as total_rows
from customers
union all
select 'Products' ,count(*) from products
union all
select 'orders',count(*) from orders
union all
select 'order_items',count(*) from order_items;


-- find total revenue for each product category
-- Join orders with order_items. Join order_items with products.Filter orders.status = 'Delivered'.Calculate revenue as quantity * unit_price.
-- Group the results by category.Sort by revenue from highest to lowest.
 select p.category,sum(quantity * unit_price) as  revenue from orders  o
 join order_items  i
 on o.order_id = i.order_id
 join products p
 on i.product_id = p.product_id
 where o.status = 'Delivered'
 group by p.category
 order by revenue;
 
 -- Top 5 customer by revenue
 select 
 c.customer_id,c.customer_name, sum(quantity * unit_price) as revenue
 from products p
 join order_items i
 on p.product_id = i.product_id
 join orders o
 on o.order_id = i.order_id
 join customers c
 on c.customer_id = o.customer_id
 where o.status = 'Delivered'
 group by c.customer_id, c.customer_name
 order by revenue desc
 limit 5;
 
 select *
 from customers c
 left join orders o
 on c.customer_id = o.customer_id
 where o.customer_id is null;
 
--  Find products priced above the average price of their own category.
 select product_id,product_name ,unit_price
 from products p
 where unit_price > (select avg(unit_price) from products p2
 where p.category = p2.category);
 
 -- Find monthly revenue by cte
 WITH monthly_data AS (
    SELECT
        o.order_date,oi.quantity,p.unit_price
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
)
SELECT
    DATE_FORMAT(order_date, '%Y-%m') as 'Month',sum(quantity * unit_price) as revenue
FROM monthly_data
group by DATE_FORMAT(order_date, '%Y-%m');

-- Rank customers by total revenue within each city.
 with total_revenue as (
 select c.customer_id,c.customer_name,city,sum(quantity * unit_price) as revenue
 from products p
 join order_items i
 on p.product_id = i.product_id
 join orders o
 on o.order_id = i.order_id
 join customers c
 on c.customer_id = o.customer_id
 where o.status = 'Delivered'
 group by c.customer_id,c.customer_name,city)
 
 select 
 customer_id,customer_name,city,revenue,
 DENSE_RANK() OVER (
    PARTITION BY city
    ORDER BY revenue DESC
) as 'Rank' from
 total_revenue;
 
--  Find each month's revenue and the previous month's revenue.
 SELECT
    month,
    revenue,
    LAG(revenue, 1) OVER (
        ORDER BY month
    ) AS previous_month_revenue
FROM (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * p.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
) AS monthly_data
ORDER BY month;

-- Find customers who placed delivered orders in at least 3 different months.
select c.customer_id,c.customer_name,count(distinct date_format(order_date,'%Y-%m')) as month
from customers c
join orders o
on c.customer_id = o.customer_id
where o.status = 'Delivered'
group by c.customer_id,c.customer_name
having count(distinct date_format(order_date,'%Y-%m')) >= 3;

-- Find each customer's first and most recent delivered order using window functions.
select c.customer_id, c.customer_name,
first_value(o.order_date) over(partition by c.customer_id order by o.order_date) as first_order_date,
last_value(o.order_date) over(partition by c.customer_id order by o.order_date  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_order_date
from customers c
join orders o
on c.customer_id = o.customer_id
where o.status = 'Delivered'; 

-- Find the total quantity sold and total revenue for each product, considering only delivered orders. Display the product ID, product name, total quantity sold, and total revenue. 
-- Show only products with total revenue greater than ₹5,000. Sort the results by total revenue in descending order.
select p.product_id,p.product_name,count(quantity),sum(quantity * unit_price) as revenue
from products p
join order_items i
on p.product_id = i.product_id
join orders o
on o.order_id = i.order_id
where o.status = 'Delivered'
group by product_id,product_name
having revenue > 5000
order by revenue desc;

-- Find each customer's name and total number of orders. Include only customers who have placed at least one order.
select c.customer_id, c.customer_name,count(*) as total_order
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items i
on o.order_id = i.order_id
where o.status = 'Delivered'
group by c.customer_id, c.customer_name;

-- Find the total revenue generated by each product category from delivered orders. 
-- Display the category and total revenue, sorted from highest to lowest revenue.
select p.category,sum(quantity * unit_price) as revenue
from products p
join order_items i
on p.product_id = i.product_id
join orders o
on o.order_id = i.order_id
where o.status = 'Delivered'
group by category
order by revenue desc;

-- Find products that have never appeared in any order item. Display their product ID and product name.
select p.product_id,p.product_name 
from products p
left join order_items i
on p.product_id = i.product_id
where i.product_id is null;

/* Find the total number of delivered orders and total revenue for each month. 
Display the month, number of orders, and revenue. Sort by month in ascending order. */
select distinct date_format(order_date,'%Y-%m') as month,
count(*) as total_order,sum(quantity * unit_price) as revenue
from products p
join order_items i
on p.product_id = i.product_id
join orders o
on o.order_id = i.order_id
where o.status = 'Delivered'
group by date_format(order_date,'%Y-%m')
order by date_format(order_date,'%Y-%m');

-- Find customers whose total spending on delivered orders is greater than the average spending of all customers who have at least one delivered order. 
-- Display customer ID, customer name, and total spending.
select c.customer_id,c.customer_name,sum(quantity* unit_price) as revenue
from products p
 join order_items i
 on p.product_id = i.product_id
 join orders o
 on o.order_id = i.order_id
 join customers c
 on c.customer_id = o.customer_id
 where o.status = 'Delivered'
 group by c.customer_id,c.customer_name
 having  sum(quantity* unit_price) > (select avg(quantity * unit_price) from products p1 join order_items i1 on p1.product_id = i1.product_id);
 
 /* Find the product with the highest total quantity sold in each category, considering only delivered orders. 
 Display category, product name, and total quantity sold. */
 
WITH total_quantity_category AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(i.quantity) AS total_quantity
    FROM products p
    JOIN order_items i
        ON p.product_id = i.product_id
    JOIN orders o
        ON o.order_id = i.order_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category, p.product_id, p.product_name
),
ranked_products AS (
    SELECT
        category,
        product_name,
        total_quantity,
        RANK() OVER (
            PARTITION BY category
            ORDER BY total_quantity DESC
        ) AS product_rank
    FROM total_quantity_category
)
SELECT category, product_name, total_quantity
FROM ranked_products
WHERE product_rank = 1;

/* Calculate each product category's percentage contribution to the total revenue from delivered orders. 
Display category, category revenue, and revenue percentage, sorted from highest to lowest percentage. */
with cte_category_revenue as
(select category,sum(quantity * unit_price) as category_revenue
from products p
join order_items i
on p.product_id = i.product_id
 JOIN orders o
        ON o.order_id = i.order_id
    WHERE o.status = 'Delivered'
group by category),
cte_total_revenue as
(select sum(quantity * unit_price) as total_revenue
from products p
join order_items i
on p.product_id = i.product_id
 JOIN orders o
        ON o.order_id = i.order_id
    WHERE o.status = 'Delivered')

select category,category_revenue,
((category_revenue  / total_revenue) * 100) as percentage_contribution
from cte_category_revenue
cross join cte_total_revenue
order by percentage_contribution desc;

/* Rank customers by their total spending on delivered orders within each city, from highest to lowest. 
Display city, customer name, total spending, and rank. Include only customers who have at least one delivered order.*/
with cte_revenue_per_city as 
(select c.customer_id,customer_name, city,sum(quantity * unit_price) as revenue
from products p
 join order_items i
 on p.product_id = i.product_id
 join orders o
 on o.order_id = i.order_id
 join customers c
 on c.customer_id = o.customer_id
 where o.status = 'Delivered'
 group by customer_id,customer_name,city)
 
 select customer_id,customer_name,city,revenue,
 dense_rank() over(partition by city order by revenue desc) as customer_rank
 from cte_revenue_per_city 
 order by city,customer_rank;
 
 select customer_name,region,count(*) as duplicate_count 
 from customers
 group by customer_name,region
 having count(*) > 1;
 
 select product_name,category,count(*) as duplicate_count 
 from products
 group by product_name,category
 having count(*) > 1;
 
 SELECT customer_id, order_date, COUNT(*) AS duplicate_count
FROM orders
GROUP BY customer_id, order_date
HAVING COUNT(*) > 1;

select product_name,count(*) as duplicate_count
from products
group by product_name
having count(*) > 1;

select region from customers
where region is null;

select * from orders
where customer_id is null 
or order_date is null
or order_status is null
or payment_method is null;

update orders 
set payment_method = 'UPI'
where order_id in (1039,1036,1034,1032,1030,1028,1026,1024,1022,1020,1018);

update orders 
set payment_method = 'UPI'
where order_id in (1017,1019,1021,1023,1025,1027,1031,1033,1035,1038);

select * from order_items
where order_id is null
or product_id is null
or quantity is null 
or discount_pct is null;

select * from Order_items
where discount_pct < 0 
or discount_pct >= 100
or quantity <= 0;

-- customers,customer_name, city, region, signup_date.
--  products: product_name, category, unit_price, unit_cost.
-- orders:customer_id, order_date, order_status, payment_method and order_items :order_id, product_id, quantity, discount_pct
-- Total Orders: Count the total number of orders.
select  count(*) from orders;

-- Total Customers: Count unique customers who placed orders.
select count(distinct(customer_id)) from orders;
-- Total Products: Count the number of products.
select count(product_name) from products;
-- Total Quantity Sold: Calculate the total quantity sold.
select sum(quantity) from order_items;
-- Total Revenue: Calculate revenue using quantity × unit_price.
with revenue_calculate as (
select oi.order_id,oi.product_id,oi.quantity,p.unit_price,
oi.quantity * p.unit_price as revenue
from order_items oi
join products p
on oi.product_id = p.product_id
join orders o
on o.order_id = oi.order_id
where o.order_status = 'Delivered')
select sum(revenue) as total_revenue from revenue_calculate;

-- Total Cost: Calculate cost using quantity × unit_cost.
with cte_cost as (
select oi.order_id,p.product_id,oi.quantity,p.unit_cost,
(oi.quantity * p.unit_cost) as cost
from order_items oi
join products p
on oi.product_id = p.product_id
join orders o
on o.order_id = oi.order_id

where order_status = 'Delivered')
select sum(cost) from cte_cost;

-- Total Profit: Calculate revenue minus cost.
with cte_profit as (
select oi.order_id,p.product_id,oi.quantity,p.unit_cost,
(oi.quantity * p.unit_cost) as cost,
(oi.quantity * p.unit_price) as price
from order_items oi
join products p
on oi.product_id = p.product_id
join orders o
on o.order_id = oi.order_id
where order_status = 'Delivered')
select (sum(price) - sum(cost)) as profit  from cte_profit;

-- Profit Margin: Calculate profit as a percentage of revenue.
WITH cte_profit AS (
    SELECT
        SUM(oi.quantity * p.unit_price) AS revenue,
        SUM(oi.quantity * p.unit_cost) AS cost
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
)
SELECT
    revenue,
    cost,
    revenue - cost AS profit,
    ROUND(((revenue - cost) / revenue) * 100, 2) AS profit_margin
FROM cte_profit;

-- Find total revenue generated by each product.
select p.product_id,product_name,sum(quantity*unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by p.product_id,product_name;

-- Find total quantity sold for each product.
select p.product_id,product_name,sum(quantity) as total_quantity
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by p.product_id,product_name;


-- Find the top 5 products by revenue.
select product_name,
dense_rank() over( order by sum(quantity*unit_price) desc) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered' 
group by p.product_id,product_name
limit  5;
-- Find the product with the highest profit.
select p.product_id,product_name,sum(quantity*unit_price)- sum(quantity * unit_cost) as profit
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by p.product_id,product_name
order by profit desc;

-- Calculate profit margin for each product.
select p.product_id,product_name,
round(((sum(quantity*unit_price)- sum(quantity * unit_cost))/sum(quantity*unit_price)) * 100,2) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by p.product_id,product_name;


-- Find products that have never been sold.
select p.product_id,product_name,quantity,unit_price 
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered' and quantity = 0
group by p.product_id,product_name;

-- Calculate total revenue for each product category.
select category,sum(quantity*unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by category;



-- Find the most profitable category.
select category,sum(quantity*unit_price)-sum(quantity* unit_cost) as profit
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by category
order by profit desc;
-- Calculate each category's percentage contribution to total revenue.
with cte_category_revenue as (
select category, sum(quantity * unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by category)
select category,sum(revenue) over() as total_revenue,
round((revenue/sum(revenue) over()) * 100,2) as percentage_contribution
from cte_category_revenue;

-- Find the average selling revenue per product in each category.
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.quantity * p.unit_price) AS total_revenue
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    JOIN products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.category, p.product_id, p.product_name
)
SELECT
    category,
    ROUND(AVG(total_revenue), 2) AS avg_product_revenue
FROM product_revenue
GROUP BY category;


-- Rank categories based on total profit using DENSE_RANK().
with cte_profit as (
select category,sum(quantity*unit_price)-sum(quantity* unit_cost) as profit
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by category) 

select category,profit,
dense_rank()over(order by profit desc) as profit_rank
from cte_profit;


-- Find categories where total revenue is above the average category revenue.
with cte_total_revenue as (
select category,sum(quantity*unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by category)

select category,revenue,avg_revenue
from (select category,revenue, avg(revenue) over() as avg_revenue from cte_total_revenue)sub 
where revenue > avg_revenue; 

-- Calculate total spending by each customer.
select c.customer_id,customer_name,sum(quantity* unit_price) as total_spend
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name;

-- Find the top 5 customers by total spending.
with cte as (
select c.customer_id,customer_name,
sum(quantity* unit_price) as total_spend
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name),
cte_rank as (
select customer_id,customer_name,total_spend, dense_rank() over(order by total_spend desc) as customer_rank
from cte)
select customer_id,customer_name,total_spend,customer_rank
from cte_rank
where customer_rank <= 5;

-- Count the number of Delivered orders placed by each customer.
select c.customer_id,customer_name,count(distinct(o.order_id)) as total_order
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name;
-- Find customers who have placed more than one Delivered order.
select c.customer_id,customer_name,count(distinct(o.order_id)) as total_order
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name
having count(*) > 1;

-- Calculate average order value (AOV) for each customer.

select c.customer_id,customer_name,
round(SUM(quantity * unit_price) / COUNT(DISTINCT o.order_id),2) AS average_order_value

from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name;


-- Rank customers by total spending using DENSE_RANK().
with cte as (
select c.customer_id,customer_name,
sum(quantity* unit_price) as total_spend
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name),
cte_rank as (
select customer_id,customer_name, dense_rank() over(order by total_spend desc) as customer_rank
from cte)
select customer_id,customer_name,customer_rank
from cte_rank
;

-- Find customers who have never placed a Delivered order.
select c.customer_id,customer_name
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status != 'Delivered'
group by c.customer_id,customer_name;


-- Identify the highest-spending customer in each region.
with cte_total_spend as (
select c.customer_id,customer_name,region,sum(quantity* unit_price) as total_spend
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name,region),
cte_region as (
select region,customer_id,customer_name,total_spend,
row_number() over(partition by region order by total_spend desc) as rank_by_region
from cte_total_spend)
select region,customer_id,customer_name,total_spend,rank_by_region
from cte_region
where rank_by_region = 1;

-- Calculate total revenue for each month.
select DATE_FORMAT(order_date, '%Y-%m')as Monthh,sum(quantity * unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m');

-- Find the month with the highest revenue.
select DATE_FORMAT(order_date, '%Y-%m')as Monthh,sum(quantity * unit_price) as revenue,
dense_rank()over(order by sum(quantity * unit_price) desc) as revenue_rank
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m')
limit 1;



-- Calculate month-over-month (MoM) revenue growth.
with month_revenue as (
select DATE_FORMAT(order_date, '%Y-%m')as Month_of_order,sum(quantity * unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m'))
select Month_of_order, revenue - lag(revenue) over() as MOM
from month_revenue;


-- Calculate month-over-month revenue growth percentage.
with month_revenue as (
select DATE_FORMAT(order_date, '%Y-%m')as Month_of_order,sum(quantity * unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m')),
cte_mom as (
select Month_of_order,revenue, revenue - lag(revenue) over(order by Month_of_order) as MOM
from month_revenue)
select Month_of_order,
round(((MOM/lag(revenue,1) over(order by Month_of_order))*100),2) as mon_percentage
from cte_mom;




-- Calculate cumulative revenue month by month.
with cte_revenue as (
select DATE_FORMAT(order_date, '%Y-%m')as Month_of_order,sum(quantity * unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m'))
select Month_of_order,revenue,
sum(revenue) over(order by Month_of_order rows between unbounded preceding and current row) as cumulative
from cte_revenue;


-- Find the average monthly revenue.

select DATE_FORMAT(order_date, '%Y-%m')as Month_of_Order,avg(quantity * unit_price) as average
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m');



-- Compare each month's revenue with the overall average monthly revenue.
with cte_revenue as (
select DATE_FORMAT(order_date, '%Y-%m')as Month_of_Order,sum(quantity * unit_price) as revenue
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m'))
select Month_of_Order, round(revenue-avg(revenue) over())as diff from cte_revenue;


-- Rank months based on revenue using DENSE_RANK().
select DATE_FORMAT(order_date, '%Y-%m')as Monthh,sum(quantity * unit_price) as revenue,
dense_rank()over(order by sum(quantity * unit_price) desc) as revenue_rank
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by DATE_FORMAT(order_date, '%Y-%m');

-- Find the second-highest revenue-generating product.
select p.product_id,product_name,sum(quantity*unit_price) as total_quantity
from order_items oi
join orders o
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by p.product_id,product_name;



-- Find each customer's latest Delivered order and its revenue.
select c.customer_id,customer_name,order_date,
sum(quantity*unit_price) over(partition by customer_id order by order_date desc) as revenue
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on oi.order_id = o.order_id
join products p
on p.product_id = oi.product_id
where order_status = 'Delivered'
group by c.customer_id,customer_name;


