-- Q1: What is our overall churn rate?
-- Counts total customers, how many churned, and the resulting rate.
-- CTE computes the raw counts once so the rate stays readable.
with counts as 
(select count(*) as total_customers , 
sum(case when Churn = 'Yes' then 1 else 0 end) as churned
from telco_churn)
select total_customers , churned , round(churned * 100 /total_customers  , 1) as percentage
from counts;

-- Q2: Does churn differ by contract type?
-- Same conditional-aggregation pattern as Q1, grouped by contract.
-- Sorted by churn rate so the highest-risk segment appears first.
with counts as(
select contract , count(*) as total_customers , 
sum(case when Churn='Yes' then 1 else 0 end) as churned
from telco_churn 
group by contract)
select contract , total_customers , churned , round(churned * 100 / total_customers , 1) as churn_rate 
from counts 
order by churn_rate desc;

-- Q3: Does churn vary with how long someone has been a customer?
-- Result: 0-12 months 47.4% | 13-24 28.7% | 25-48 20.4% | 49+ 9.5%
-- Churn falls steadily with tenure — the first year is the critical window.
with counts as (
select case when tenure <= 12 then '0-12 months'
     when tenure <= 24 then '13-24 months'
     when tenure <= 48 then '25-48 months'
     else '49+ months'
end as tenure_group, count(*) as  total_customers , 
sum(case when Churn='Yes' then 1 else 0 end) as churned
from telco_churn
group by tenure_group)
select tenure_group , total_customers , churned , round(churned *100 / total_customers , 1 ) as churn_rate
from counts;

-- Q4: Is contract type an independent driver, or just a proxy for tenure?
-- Groups by both dimensions to compare contracts within each tenure band.
-- Result: month-to-month churns 3-5x higher in every tenure band
--   (0-12m: 51.4% vs 10.5% vs 0.0%). Contract effect holds independently.
-- Note: two-year cells in early tenure have small samples (68, 90 customers).
with counts as (
select case when tenure <= 12 then '0-12 months'
     when tenure <= 24 then '13-24 months'
     when tenure <= 48 then '25-48 months'
     else '49+ months'
end as tenure_group, contract , count(*) as  total_customers , 
sum(case when Churn='Yes' then 1 else 0 end) as churned
from telco_churn
group by tenure_group , Contract)
select tenure_group , total_customers , contract ,  churned , round(churned *100 / total_customers , 1 ) as churn_rate
from counts
order by tenure_group  , contract;

-- Q5: What is the revenue impact of churn?
-- Result: $139,131 of $456,117 monthly revenue (30.5%) came from churned customers.
-- Revenue churn (30.5%) exceeds customer churn (26.5%) — leavers pay ~15% above
--   the average customer ($74.4 vs $64.8/month).
with revenue as (
    select round(sum(MonthlyCharges),1) as total_monthly_revenue ,
           round(sum(case when Churn = 'Yes' then MonthlyCharges else 0 end),1) as lost_monthly_revenue
    from telco_churn
)
select total_monthly_revenue ,
       lost_monthly_revenue ,
       round( lost_monthly_revenue * 100.0 / total_monthly_revenue , 1 ) as revenue_lost_pct
from revenue;

