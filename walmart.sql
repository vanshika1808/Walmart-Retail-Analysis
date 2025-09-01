create database walmart;
use walmart;
show tables;
select * from walmart;
SET SQL_SAFE_UPDATES = 0;
UPDATE walmart
SET Date = STR_TO_DATE(Date, '%d-%m-%Y');



--  Task 1: Identifying the Top Branch by Sales Growth Rate 
select branch, 
month(date) as month,
sum(total) as monthly_sales
from walmart
group by branch, month(date)
order by branch, month;

with monthly_sales as (
select branch, month(date) as month, sum(total)as monthly_sales
from walmart
group by branch,month(date)
order by branch,month
),
growth_cal as(
select branch, month, monthly_sales,
lag(monthly_sales) over (partition by branch order by month) as prev_month_sales
from monthly_sales
)
select branch, month, monthly_sales, prev_month_sales,
round(((monthly_sales-prev_month_sales)/prev_month_sales)*100,2) as growth_rate
from growth_cal
where prev_month_sales is not null
order by growth_rate desc
limit 1;


-- Task 2: Finding the Most Profitable Product Line for Each Branch
with profitperline as(
select branch , Product_line, sum(gross_income) as totalprofit
from walmart
group by branch, Product_line
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Branch ORDER BY TotalProfit DESC) AS row_num
    FROM ProfitPerLine
) ranked
WHERE row_num = 1;

--  Task 3: Analyzing Customer Segmentation Based on Spending
select customer_id, sum(total) as total_spent
from walmart
group by customer_id
order by customer_id asc;

with customer_spending as(
select customer_id, sum(total) as total_spent
from walmart
group by customer_id
order by customer_id asc
)
select customer_id, total_spent,
case
 when total_spent>=25000 then 'HIGH_spender'
 when total_spent between 20000 and 24999 then 'Medium_spender'
 else 'Low_spender'
 end as spending_category 
 from customer_spending;

-- Task4: Detecting Anomalies in Sales Transactions
with stats as(
select product_line, avg(total) as avg_total,
stddev(total) as std_total
from walmart 
group by product_line
)
SELECT 
  w.Invoice_ID,
  w.product_line,
  w.Total,
  s.avg_total,
  s.std_total,
  CASE 
    WHEN w.Total > s.avg_total + 2 * s.std_total THEN 'High Anomaly'
    WHEN w.Total < s.avg_total - 2 * s.std_total THEN 'Low Anomaly'
    ELSE 'Normal'
  END AS AnomalyFlag
FROM walmart w
JOIN Stats s
  ON w.Product_line = s.Product_line
WHERE 
  w.Total > s.avg_total + 2 * s.std_total 
  OR w.Total < s.avg_total - 2 * s.std_total;
  
  
  -- Task 5: Most Popular Payment Method by City. 
select city, payment, count(*) as paymentcount
from walmart
group by city, payment;

with paymentstats as(
select city, payment, count(*) as payment_count
from walmart
group by city, payment
),
rankedpayment as( 
select * ,
row_number() over (partition by city order by payment_count desc) as row_num
from paymentstats
)
select city,
payment_count,
payment as most_popular_payment
from rankedpayment
where row_num=1; 

--  Task 6: Monthly Sales Distribution by Gender
select gender, month(date) as sales_month, round(sum(total),2) as total_sales
from walmart
group by gender, sales_month
order by gender, total_sales desc;

-- Task 7: Best Product Line by Customer Type
select customer_type, product_line, round(sum(total),2) as total_revenue
from walmart 
group by customer_type, product_line
order by Customer_type, total_revenue desc;

--  Task 8: Identifying Repeat Customers
with purchasedates as (
select customer_id,
date,
lead(date) over (partition by customer_id order by date) as nextpurchasedate
from walmart
),
repeatpurchase as(
select customer_id, date as firstpurchase,
nextpurchasedate,
datediff(nextpurchasedate, date) as daysbetween
from purchasedates
where nextpurchasedate is not null
)
select * from repeatpurchase 
where daysbetween <=30;

--  Task 9: Finding Top 5 Customers by Sales Volume
select customer_id,
round(sum(total),2) as total_spent
from walmart
 group by customer_id
 order by total_spent desc
 limit 5;
 
 --  Task 10: Analyzing Sales Trends by Day of the Week
 select
 dayname(date) as dayofweek,
 round(sum(total),2) as totalsales
 from walmart 
  group by dayofweek
  order by totalsales desc;