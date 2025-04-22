create database bankcrm;

use bankcrm;

//------// OBJECTIVE QUESTION //------//


-- Question 1. What is the distribution of account balance across different regions?

-- Calculate the total overall balance
WITH total_balance_cte AS (
    SELECT SUM(balance) AS total_balance
    FROM bank_churn
),

-- Calculate balance for each region
region_balance_cte AS (
    SELECT 
        g.GeographyLocation, 
        SUM(b.balance) AS region_balance
    FROM geography g
    INNER JOIN customerinfo ci ON ci.GeographyID = g.GeographyID
    INNER JOIN bank_churn b ON b.CustomerId = ci.CustomerId
    GROUP BY g.GeographyLocation
)

-- Calculate balance distribution across regions
SELECT 
    rb.GeographyLocation, 
    rb.region_balance, 
    ROUND((rb.region_balance / tb.total_balance) * 100, 2) AS Balance_Percentage
FROM region_balance_cte rb
CROSS JOIN total_balance_cte tb;

-- Question 2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
With CTE as 
(
select CustomerId, MAX(EstimatedSalary) as Highest_Estimated_Salary,substr(BankDOJ,7,4) as Year from customerinfo
WHERE BankDOJ BETWEEN DATE_FORMAT(NOW(),'01-10-%y') AND DATE_FORMAT(NOW(),'31-12-%y')
group by CustomerId,substr(BankDOJ,7,4)
),

CTE2 as (
select CustomerId, Highest_Estimated_Salary, Year, 
dense_rank() over (partition by Year order by  Highest_Estimated_Salary desc) as Rank_year from CTE
)

select CustomerId, Highest_Estimated_Salary
from CTE2
where Rank_year between 1 and 5
order by year
Limit 5;

-- Question 3. Calculate the average number of products used by customers who have a credit card. (SQL)
Select avg(NumOfProducts) as average_number_of_products
from bank_churn
where HasCrCard = 1;

-- Question 4. Determine the churn rate by gender for the most recent year in the dataset.

Select g.GenderCategory,count(Case when b.Exited = 1 then 1 end) as ChurnedCount,
 -- count for those customers who left or churned -- 
count(*) as TotalCount,
Round((count(Case when b.Exited = 1 then 1 end) / count(*)) * 100, 2) as ChurnRatePercentage
from CustomerInfo ci
join Gender g on ci.GenderID = g.GenderID
join Bank_Churn b on ci.CustomerId = b.CustomerId
where year(ci.BankDOJ) = (Select MAX(year(BankDOJ)) from CustomerInfo)  
-- select most recent year from dataset -- 
group by g.GenderCategory;

-- Question 5. Compare the average credit score of customers who have exited and those who remain. (SQL)

Select 
Round(avg(Case when Exited = 1 then CreditScore end),2)as exitcust_credit_score,
Round(avg(Case when Exited = 0 then CreditScore end),2) as remainingcust_credit_score
from bank_churn;

-- Question 6. Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)

with GenderSalary as (Select g.GenderCategory,avg(ci.EstimatedSalary) as Avg_Estimated_Salary
from customerinfo ci
join gender g on ci.GenderID= g.GenderID
group by g.GenderCategory),
GenderActiveAccounts as (Select g.GenderCategory,
count(Case when b.IsActiveMember = 1 then 1 end) as Active_Count
from CustomerInfo ci
join Gender g on ci.GenderID = g.GenderID
join bank_churn b on ci.CustomerId = b.CustomerId
group by g.GenderCategory)

Select gs.GenderCategory,Round(gs.Avg_Estimated_Salary,2) as Avg_est_salary,gaa.Active_Count
from GenderSalary gs
join GenderActiveAccounts gaa on gs.GenderCategory = gaa.GenderCategory
order by Avg_est_salary desc;

-- Question 7. Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)

with Segments as (Select ci.CustomerId,b.CreditScore,
Case when b.CreditScore between 300 and 579 then 'Poor'
when b.CreditScore between 580 and 669 then 'Fair'
when b.CreditScore between 670 and 739 then 'Good'
when b.CreditScore between 740 and 799 then 'VeryGood'
when b.CreditScore between 800 and 850 then 'Excellent'
end as CreditScoreSegment,b.Exited
from Bank_Churn b
join CustomerInfo ci on b.CustomerId = ci.CustomerId)

Select CreditScoreSegment,
count(Case when Exited = 1 then 1 end) as ChurnedCount,
count(*) as TotalCount,
Round((count(Case when Exited = 1 then 1 end) * 1.0 / count(*)) * 100, 2) as ExitRatePercentage
from Segments
group by CreditScoreSegment
order by ExitRatePercentage desc
Limit 1;

-- Question 8. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
Select g.GeographyLocation, count(ci.CustomerId) as active_customers
from geography g
join customerinfo ci on g.GeographyID= ci.GeographyID
join bank_churn b on ci.CustomerId = b.CustomerID
where b.IsActiveMember = 1 and b.tenure > 5
group by g.GeographyLocation
order by active_customers desc;

-- Question 9. What is the impact of having a credit card on customer churn, based on the available data?
with CreditCardImpact as (Select b.HasCrCard,
count(Case when b.Exited = 1 then 1 end) as ChurnedCount,
count(*) as TotalCount,
ROUND((count(Case when b.Exited = 1 then 1 end) / count(*)) * 100, 2) as ChurnRatePercentage
from Bank_Churn b
group by b.HasCrCard)

Select Case when HasCrCard = 1 then 'Has Credit Card'
when HasCrCard = 0 then 'No Credit Card'
end as CreditCardStatus,ChurnedCount,TotalCount,ChurnRatePercentage
from CreditCardImpact;

-- Question 10. For customers who have exited, what is the most common number of products they had used?
Select NumOfProducts,COUNT(*) as ExitedCount
from Bank_Churn 
where Exited = 1
group by NumOfProducts
order by ExitedCount desc
Limit 1;

-- Question 11. Examine the trend of customer joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
Select Substr(BankDOJ,1,4) as Year, count(*) as No_of_Cust 
from customerinfo
group by Substr(BankDOJ,1,4);

-- Question 12. Analyze the relationship between the number of products and the account balance for customers who have exited.
Select NumOfProducts, Round(sum(Balance),2) as AccountBalance,count(*) as ExitedCustomerCount
from Bank_Churn bc
where Exited = 1
group by NumOfProducts
order by NumOfProducts;

-- Question 15. Using SQL, write a query to find out the gender wise average income of male and female in each geography id. Also rank the gender according to the average value. (SQL)
Select GeographyID,	GenderCategory, avg(EstimatedSalary) as AverageIncome,						
Rank() over (partition by GeographyID order by avg(EstimatedSalary) desc) as GenderRank
from customerinfo ci								
join gender g on ci.GenderID = g.GenderID				
group by GeographyID, GenderCategory;

-- Question 16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
with AgeSegment as (Select Case when ci.Age between 18 and 30 then '18-30'
when ci.Age between 31 and 50 then '31-50'
when ci.Age > 50 then '50+'
end as Age_Bracket, b.Tenure
from customerinfo ci
join bank_churn b on ci.CustomerId = b.CustomerID
where b.Exited = 1
order by Age_Bracket)

Select Age_Bracket, Round(avg(Tenure),2) as AverageTenure
from AgeSegment
group by Age_Bracket
order by Age_Bracket;

-- Question 17. Is there any direct correlation between salary and balance of the customers? And is it different for people who have exited or not?

--  Calculate average balance and salary for exited and non-exited customers --
SELECT b.Exited,AVG(ci.EstimatedSalary) AS AvgSalary,AVG(b.Balance) AS AvgBalance,
STDDEV(ci.EstimatedSalary) AS SalaryStdDev,STDDEV(b.Balance) AS BalanceStdDev
FROM customerinfo ci
JOIN bank_churn b ON ci.CustomerId = b.CustomerId
GROUP BY b.Exited;

-- Question 18. Is there any correlation between salary and Credit score of customers?

Select ci.EstimatedSalary, bc.CreditScore
from customerinfo ci
join  bank_churn bc on ci.CustomerId = bc.CustomerId;

-- Question 19. Rank each bucket of credit score as per the number of customers who have churned the bank.

-- Step 1: Segment customers into credit score buckets
with Segments as (Select CreditScore,
Case when CreditScore between 300 and 579 then 'Poor'
when CreditScore between 580 and 669 then 'Fair'
when CreditScore between 670 and 739 then 'Good'
when CreditScore between 740 and 799 then 'VeryGood'
when CreditScore between 800 and 850 then 'Excellent'
end as CreditScoreSegment,Exited
from Bank_Churn),

-- Step 2: Count churned customers in each credit score bucket
ChurnedCustomers as (Select CreditScoreSegment,COUNT(*) AS ChurnedCount
from Segments
where Exited = 1 -- Only include churned customers
group by CreditScoreSegment
)

-- Step 3: Rank buckets by number of churned customers
Select CreditScoreSegment,ChurnedCount,
Rank() over (order by ChurnedCount desc) as 'Rank'
from ChurnedCustomers;

-- Question 20. According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets who have lesser than average number of credit cards per bucket.

-- Step 1: Segment customers into age buckets
With AgeBuckets as (Select Case when ci.Age between 18 and 30 then '18-30'
when ci.Age between 31 and 50 then'31-50'
when ci.Age > 50 then '50+'
end as AgeBucket,
count(*) as CreditCardCount
from customerinfo ci
join bank_churn bc on ci.CustomerId = bc.CustomerId
where bc.HasCrCard = 1 -- Only include customers who have a credit card
group by  AgeBucket),

-- Step 2: Calculate the average number of credit cards across all buckets
AverageCreditCardCount as (Select Round(avg(CreditCardCount),2) as AvgCreditCardCount
from AgeBuckets)

-- Step 3: Retrieve buckets with fewer than average credit cards
Select ab.AgeBucket,ab.CreditCardCount,ac.AvgCreditCardCount
from AgeBuckets ab
cross join AverageCreditCardCount ac
where ab.CreditCardCount < ac.AvgCreditCardCount;

-- Question 21. Rank the Locations as per the number of people who have churned the bank and average balance of the learners.

With Locations as (Select g.GeographyLocation,count(Case when bc.Exited = 1 then 1 end) as ChurnedCount,
avg(bc.Balance) as AvgBalance
from bank_churn bc
join customerinfo ci on bc.CustomerId = ci.CustomerId
join geography g on ci.GeographyID = g.GeographyID
group by g.GeographyLocation)

Select GeographyLocation,ChurnedCount,AvgBalance,
Rank() over (order by  ChurnedCount desc, AvgBalance desc) as 'Rank'
from Locations;

-- Question 22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.
	Select CONCAT(ci.CustomerID, '_', ci.Surname) AS CustomerID_Surname	
    from CustomerInfo ci	
    join bank_churn bc ON ci.CustomerID = bc.CustomerID;
    
-- Question 23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.

Select b.*,												
(Select ExitCategory 
from ExitCustomer ec 
where ec.ExitID= b.Exited) as ExitCategory						
from bank_churn b;

-- Question 24. Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them?

-- Question 25. Write the query to get the customer ids, their last name and whether they are active or not for the customers whose surname  ends with “on”.
Select ci.CustomerID,ci.Surname,
Case when ac.ActiveID = 1 then 'Active'	else 'Inactive'	
end as "IsActive"							
from CustomerInfo ci								
left join ActiveCustomer ac on ci.CustomerID = ac.ActiveID			
where ci.Surname LIKE '%on';

-- Question 26. Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns. One more point to consider is that the data in the Exited Column is absolutely correct and accurate.

-- Find records where IsActiveMember is 1 but Exited is 1

Select CustomerId, Exited, IsActiveMember
from bank_churn
where Exited = 1 and IsActiveMember = 1;

