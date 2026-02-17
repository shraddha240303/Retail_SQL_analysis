-- use the database
use retails;
-- no. of tables 
show tables;
-- get the info of particular table
select * from retail_sales_dataset;
-- rename the table name
rename table retail_sales_dataset to sales_data;
-- check the data type of all attributes
describe sales_data;
-- change the data type of date from text to date
alter table sales_data modify column Date Date; 

-- Exploratory Data Analysis

select * from sales_data;

-- gender categorization
select 
(select count(*) from sales_data where Gender='Male') as male,
(select count(*) from sales_data where Gender='Female') as female;

-- median age of female and male
with cte1 as (
select *, row_number() over(order by age) as rnk,
count(*) over() as total_cnt from sales_data where Gender='Male'
),
cte2 as (
select *, row_number() over(order by age) as rnk,
count(*) over() as total_cnt from sales_data where Gender='Female'
)
select
(select avg(age) from cte1 where rnk in ((total_cnt+1)/2, (total_cnt+2)/2)) as male_median,
(select avg(age) from cte2 where rnk in ((total_cnt+1)/2, (total_cnt+2)/2)) as female_median;

-- last 6 month sales
select sum(`Total Amount`) as total_revenue from sales_data where `Date` >= current_date - interval 6 month;

-- sales in the month of october
select sum(`Total Amount`) as total_revenue from sales_data where month(`Date`) = 10;

-- total revenue in each product category
select `Product Category`, sum(`Total Amount`) as total from sales_data group by `Product Category`;

-- cummulative of total amount while arranging the data in ascending order
with cte as (
select *, 
sum(`Total Amount`) over(order by `Total Amount` rows between unbounded preceding and current row)/sum(`Total Amount`) over() as cummulative from sales_data
)
select * from cte order by `Date`; 

-- categorization of revenue on the basis of gender and product category
select `Gender`, `Product Category`, sum(`Total Amount`) as revenue from sales_data group by 1, 2 order by 1;

-- total quantity by product category
select `Product Category`, sum(Quantity) as total_unit from sales_data group by 1;

-- week day analysis

-- week day product selling
select `Product Category`, dayname(`Date`) as week_name, count(*) as cnt from sales_data group by 1, 2, weekday(`Date`) order by 1, weekday(`Date`);

-- week day revenue
select dayname(`Date`) as week_name, count(*) as cnt from sales_data group by 1, weekday(`Date`) order by weekday(`Date`);

-- ABC analysis

with product_cate as (
select `Product Category`, sum(`Total Amount`) as revenue from sales_data group by 1
),
abc_cmmu as (
select *, 
sum(revenue) over(order by revenue rows between unbounded preceding and current row) as cummulative,
sum(revenue) over() as total_revenue
from product_cate
)
select `Product Category`, revenue,
cummulative/total_revenue as ratio,
case 
when cummulative/total_revenue <= 0.8 then 'A'
when cummulative/total_revenue <= 0.95 then 'B'
else 'C'
end as abc_class
from abc_cmmu order by revenue desc;

-- MOM sales analysis

with monthly_sales as (
	select 
		date_format(`Date`, '%Y-%m-01') as month,
        sum(`Total Amount`) as total_sales
	from sales_data
    group by date_format(`Date`, '%Y-%m-01')
)
select 
	month,
    total_sales,
    lag(total_sales) over(order by month) as previous_month_sales,
    (total_sales - lag(total_sales) over(order by month)) as monthly_growth,
    round((total_sales - lag(total_sales) over(order by month))*100/lag(total_sales) over(order by month), 2) as monthly_growth_percentage
    from monthly_sales
    order by month;
