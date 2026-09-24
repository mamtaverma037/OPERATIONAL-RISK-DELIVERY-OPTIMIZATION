-- SQL business question 
--1. what is the total number of order
select   count( distinct order_id) as total_order
from dbo.supply_chain

--2. what is the total sales and total profit 
select round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit
from dbo.supply_chain

--3. what is the overall profit margin
select round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
round(sum(order_profit_per_order)*100/nullif(sum(sales),0),2) as profit_margin
from dbo.supply_chain

--4.what is the average order value
select round(sum(sales)/count( distinct order_id),2) as avg_order_value
from dbo.supply_chain

--5.how has monthly sales, profit,and order volume change over time
select order_month_name,
round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
round(count(distinct order_id),2)as total_order
from dbo.supply_chain
group by order_month_name,order_month
order by order_month

--2. DELIVERY & SLA
--6. what is the avg scheduled shipping time
select avg([days_for_shipment_(scheduled)]) as avg_scheduled_shipping_time
from dbo.supply_chain

--7.AVERAGE actual shipping time
select avg([days_for_shipping_(real)])as actual_shipping_time
from dbo.supply_chain

--8. no.of late orders
select count(distinct order_id) as late_order
from dbo.supply_chain
where [days_for_shipping_(real)] > [days_for_shipment_(scheduled)];

--9. overal late delivery percentage
select count(distinct 
case when[days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_delivery_percentage
from dbo.supply_chain

--10. late delivery rate by shipping mode
select shipping_mode,
count(distinct order_id) as total_order,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)as late_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by shipping_mode
order by late_rate desc;

--11. late delivery by market and region
select market,
count(distinct order_id) as total_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)as late_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by market
order by late_rate desc;

--12. late delivery py product category
select category_name,
count(distinct order_id) as total_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)as late_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by category_name
order by late_rate desc;

--13. monthly late_delivery trend
select order_year,
order_month,
count(distinct order_id) as total_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)as late_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by order_year,order_month
order by order_year,order_month

--14. region +shipping mode with highest delay rate
select shipping_mode,
order_region,
count(distinct order_id) as total_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)as late_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by shipping_mode , order_region
order by late_rate desc;

--#3 profitability and operations 
--15 . do late deliveries have lower profit
with delivery_status as(
select
order_id,
sales,
order_profit_per_order,
case when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then 'Late'
      else 'on-time'
      end as delivery_status
      from dbo.supply_chain
)
select 
count(distinct order_id) as total_sales,
sum(sales) as total_sales,
round(sum(order_profit_per_order)*100/nullif(sum(sales),0),2) as profit_margin,
delivery_status
from delivery_status
group by delivery_status

-- 16. market with high revenue but low profit margin
select market,
round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
round(sum(order_profit_per_order)*100/sum(sales),2) as profit_margin
from dbo.supply_chain
group by market
order by total_sales desc

--high revenue but low_profit categories
select category_name,
round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
round(sum(order_profit_per_order)*100/sum(sales),2) as profit_margin
from dbo.supply_chain
group by category_name
order by total_sales desc

--region with high delays but low profitability
select order_region,
count(distinct order_id) as total_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)as late_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate,
round(sum(order_profit_per_order)*100/nullif(sum(sales),0),2) as profit_margin,
round(sum(sales),2)as total_sales,
round(sum(order_profit_per_order),2) as total_profit
from dbo.supply_chain 
group by order_region
order by late_rate desc

--shipping mode performance
select shipping_mode,
count(distinct order_id) as total_orders,
round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
round(sum(order_profit_per_order)*100/nullif(sum(sales),0),2) as profit_margin,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by shipping_mode
order by total_profit desc

--#4.ROOT CAUSE ANALYSIS
--20 . factor associated with late delivery
select shipping_mode
market,
order_region,
category_name,
customer_segment,
count(distinct order_id) as total_orders,
round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
avg(case when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then 1.0
        else 0.0 end)*100 as late_rate
from dbo.supply_chain
group by shipping_mode,
market,
order_region,
category_name,
customer_segment
order by late_rate

--22.area contributing most late orders
select order_region,
count(distinct order_id) as total_orders,
count(distinct case when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then order_id end) as late_order
from dbo.supply_chain
group by order_region
order by late_order desc

--23. high-volume and high delay areas
select order_region,
count(distinct order_id) as total_orders,
round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
round(sum(order_profit_per_order)*100/nullif(sum(sales),0),2) as profit_margin,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by order_region
order by total_orders desc,
 late_rate desc

 --operational and financial impact 
 select order_region,
count(distinct order_id) as total_orders,
round(sum(sales),2) as total_sales,
round(sum(order_profit_per_order),2) as total_profit,
round(sum(order_profit_per_order)*100/nullif(sum(sales),0),2) as profit_margin,
count(distinct case when  [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then order_id end) as late_orders,
count(distinct case  when [days_for_shipping_(real)] > [days_for_shipment_(scheduled)] then [order_id] end)
*100/count(distinct order_id) as late_rate
from dbo.supply_chain
group by order_region
order by late_orders desc,
total_profit asc


-- Advanced analysis
--25 . rank product within each category by revenue 
with productsales as (
select category_name,
product_name,
round(sum(sales),2)as total_revenue
from dbo.supply_chain
group by category_name,
product_name
)
select*,
rank() over(partition by category_name order by total_revenue desc) as product_rank
from productsales;

--26. rank region within each market by profit

with regionprofit as (
select order_region,
market,
round(sum(order_profit_per_order),2)as total_profit
from dbo.supply_chain
group by order_region,
market
)
select*,
rank() over(partition by market order by total_profit desc) as region_rank
from regionprofit;

--27 . M-O-M revenue and profit
with monthlydata as (
select 
order_month,
sum(sales) as revenue,
sum(order_profit_per_order) as total_profit
from dbo.supply_chain
group by order_month
)
select 
order_month,
revenue,
total_profit,
round(lag(revenue) over(order by order_month),2) as previous_month_revenue,
round(lag(total_profit) over (order by order_month),2) as previous_month_profit
from monthlydata
order by order_month

--cumulative revenue 
with monthlydata as(
select order_month,
round(sum(sales),2) as revenue
from dbo.supply_chain
group by order_month
)
select order_month,
revenue,
sum(revenue) over(order by order_month) as cumulative_revenue
from monthlydata
order by order_month

--29. top 3 categories in each market
with categoryrank as(
 select market,
category_name,
sum(order_profit_per_order) as profit
from dbo.supply_chain
group by market,
category_name
),
ranked as(
select*,
DENSE_RANK() over (partition by market order by profit desc) as category_rank
from categoryrank
)
select*
from ranked 
where category_rank < =3 
order by market ,category_rank 

--30 . operatinal performance summary 
with operations as (
select 
order_region , 
count(distinct order_id) as total_orders,
sum(sales) as total_sales,
sum(order_profit_per_order)as total_profit,
avg([days_for_shipping_(real)]) as avg_actual_days,
avg([days_for_shipment_(scheduled)]) as avg_scheduled_days,
count(distinct case when [days_for_shipping_(real)] >[days_for_shipment_(scheduled)] then order_id end) as late_orders
from dbo.supply_chain 
group by order_region
)
select*,
late_orders * 100/nullif(total_orders ,0) as late_rate,
total_profit*100/nullif(total_sales ,0) as profit_margin
from operations 
order by late_rate desc



