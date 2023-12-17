select * from credit_card_transcations

--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends ?

with cte as(
select city, sum(amount) as tspend,(select sum(cast (amount as bigint )) from credit_card_transcations) total
from credit_card_transcations
group by city)
select top 5 city, tspend , cast((tspend*1.0 / total * 100) as decimal(5,2)) as percentage_t
from cte 
order by tspend desc;

--2- write a query to print each card type has the highest spend in which month ?

with cte as (
select card_type,DATEPART(year,transaction_date) as yo,DATENAME(month,transaction_date) as mo
, sum(amount) as monthly_expense
from credit_card_transcations
group by card_type,DATEPART(year,transaction_date),DATENAME(month,transaction_date))
select * from ( 
select *
, rank() over(partition by card_type order by monthly_expense desc) as rn
from cte) A
where rn=1;

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type) ?

with cte as(
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) cum_sum
from credit_card_transcations)
,ctf as(
select * 
from cte 
where cum_sum >= 1000000)
,ctg as( 
select *,rank() over(partition by card_type order by cum_sum) rn
from ctf)
select * 
from ctg 
where rn = 1;

--4- write a query to find city which had lowest percentage spend for gold card type ?

with cte as(
select city,sum(amount)t_spend,sum(case when card_type = 'Gold' then amount else 0 end)g_spend
from credit_card_transcations
group by city )
select *, (g_spend * 1.0 / t_spend * 100) as gold_contribution
from cte 
where (g_spend * 1.0 / t_spend * 100) > 0
order by gold_contribution;

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel) ?

with cte as(
select city,exp_type,sum(amount) tspend
from credit_card_transcations
group by city,exp_type)
,ctf as(
select *
,rank() over(partition by city order by tspend desc) as max_rn
,rank() over(partition by city order by tspend asc) as min_rn
from cte)
select city
,max(case when max_rn = 1 then exp_type end) as highest_expense_type
,max(case when min_rn = 1 then exp_type end) as lowest_expense_type
from ctf
where max_rn =1 or min_rn =1
group by city;

--6- write a query to find percentage contribution of spends by females for each expense type ?

with cte as(
select exp_type, gender,sum(amount)spend
from credit_card_transcations
group by exp_type, gender)
,ctf as(
select * ,sum(spend) over(partition by exp_type) as total_spend
from cte)
select *,cast(spend*1.0 / total_spend *100 as decimal (5,2)) as t_percent 
from ctf
where gender = 'F'
order by t_percent ;

--7- which card and expense type combination saw highest month over month growth in Jan-2014 ?

with cte as(
select card_type,exp_type,FORMAT(transaction_date,'yyyyMM')yrmo,sum(amount) as tspend
from credit_card_transcations
where FORMAT(transaction_date,'yyyyMM') in (201401 , 201312)
group by card_type,exp_type,FORMAT(transaction_date,'yyyyMM'))
,ctf as(
select *,lag(tspend) over(partition by card_type, exp_type order by yrmo) mom
from cte)
select top 1 *,tspend-mom as mom_growth
from ctf
where yrmo =201401
order by mom_growth desc;

--8- during weekends which city has highest total spend to total no of transcations ratio ?

select city, sum(amount)*1.0/count(*) as ratio
from credit_card_transcations
where datename(WEEKDAY,transaction_date) in ('saturday','sunday')
group by city
order by ratio desc;

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city ?

with cte as(
select *,row_number() over(partition by city order by transaction_date,transaction_id) as rnk
from credit_card_transcations)
select city,min(transaction_date) first_date, max(transaction_date)last_date
,DATEDIFF(day,min(transaction_date),max(transaction_date)) days_to_500
from cte 
where rnk in (1,500)
group by city
having count(*) = 2
order by days_to_500 desc;