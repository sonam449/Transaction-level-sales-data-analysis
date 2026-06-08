
/* 
Meaning of different type of comments based on signs
1 .------abc----- --> Heading
2. -- <<<<<abc>>>> --> Data quality issue or some decision/assumption is made
3. -- abc (context of query)
query
*/


--------------------------------- Creating database-----------------------------------
Create database [CaseStudy];
Use [CaseStudy]

----------------------------------- Data Import --------------------------------------
-- importing the flat file via Database → Tasks → Import Flat file
SELECT top 10 *
FROM [CaseStudy].[dbo].[Sample Data];

--------------------------- choosing primary key--------------------------------------------
select COUNT(*), COUNT(distinct [Order_Number]) from [CaseStudy].[dbo].[Sample Data];
select COUNT(*), COUNT(distinct [Order_Line_Id]) from [CaseStudy].[dbo].[Sample Data];

-- double checking for duplicates in Order_Line_Id column
SELECT Order_Line_Id, COUNT(*) AS Duplicate_Count
FROM [CaseStudy].[dbo].[Sample Data]
GROUP BY Order_Line_Id
HAVING COUNT(*) > 1;

/* -----<<<<<<<<<<< As total rows count is not equal to distinct order_number row count, but is equal for 
Order_Line_Id, so choosing it as primary key>>>>>>>>>>>>>>>--------------------------------*/


---------------------------------- Checking data stats --------------------------------------

-- Total rows
SELECT COUNT(*) AS Total_Rows
FROM [CaseStudy].[dbo].[Sample Data];

-- Total distinct Sales channel (total channels are 10)
select count(distinct([Sales_Channel])) from [CaseStudy].[dbo].[Sample Data];

-- Total distinct Product category 
select count(distinct([Item_Cat_New])) from [CaseStudy].[dbo].[Sample Data];

-- Transaction distribution over item_category
SELECT Item_Cat_New,
COUNT(*) AS Total_Transactions
FROM [CaseStudy].[dbo].[Sample Data]
GROUP BY Item_Cat_New
ORDER BY Total_Transactions DESC;

-- Availability of data (min and max of dates of transaction)
SELECT
    MIN(CREATION_DATE) AS Earliest_Date,
    MAX(CREATION_DATE) AS Latest_Date
FROM [CaseStudy].[dbo].[Sample Data];

-- Checking for Null values
SELECT COUNT(*) AS Total_Rows,SUM(CASE WHEN Gross_Margin IS NULL THEN 1 ELSE 0 END) AS Null_Gross_Margin,
SUM(CASE WHEN Gross_Sales IS NULL THEN 1 ELSE 0 END) AS Null_Gross_Sales,
SUM(CASE WHEN Cost_of_Goods_Sold IS NULL THEN 1 ELSE 0 END) AS Null_COGS,
SUM(CASE WHEN Other_Cost_of_Goods_Sold IS NULL THEN 1 ELSE 0 END) AS Null_OCOGS,
SUM(CASE WHEN Total_Discount IS NULL THEN 1 ELSE 0 END) AS Null_Total_Discount,
SUM(CASE WHEN Total_Units_sold IS NULL THEN 1 ELSE 0 END) AS Null_Total_Units_Sold
FROM [CaseStudy].[dbo].[Sample Data];


/*-----------------<<<Since Cost_of_Good_sold and other_cost_of_Good_Sold columns are showing null 
values, further investigating on it whether they are coming from same source of different>>>--------------------*/
SELECT Sales_Channel, SKU, MIN(Creation_Date) AS Min_Date, MAX(Creation_Date) AS Max_Date, COUNT(*) AS Null_Rows
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NULL and Other_Cost_of_Goods_Sold is null
GROUP BY Sales_Channel, SKU
ORDER BY Null_Rows DESC;

/*------- <<<<They are coming from Sales Channel 1 and 7, further I want to know the exact number of rows present 
for these sales_channels and sku>>>>>>-------*/
SELECT Sales_Channel, SKU, COUNT(*) AS Total_Rows
FROM [CaseStudy].[dbo].[Sample Data]
WHERE (Sales_Channel = 'Sales Channel 7' AND SKU = 'SKU2333')
   OR (Sales_Channel = 'Sales Channel 7' AND SKU = 'SKU340')
   OR (Sales_Channel = 'Sales Channel 7' AND SKU = 'SKU1219')
   OR (Sales_Channel = 'Sales Channel 7' AND SKU = 'SKU516')
   OR (Sales_Channel = 'Sales Channel 7' AND SKU = 'SKU2789')
   OR (Sales_Channel = 'Sales Channel 1' AND SKU = 'SKU340')
   OR (Sales_Channel = 'Sales Channel 1' AND SKU = 'SKU2333')
GROUP BY Sales_Channel, SKU
ORDER BY Total_Rows DESC;
--
/* ---<<< As the number of total rows and null value in Cost_of_Goods_Sold and Other_Cost_of_Goods_Sold
rows are equal, it can be interpretated that The issue is concentrated in a few SKU 
and Sales_Channel combinations where all transactions lack cost information, indicating systemic data capture 
error resulting in Null values of product cost for these transactions.

further we want to check if these columns can we trusted to profitabily analysis
that's why checking the general formula of profit if it fits in this dataset as well
(specially null value rows )
Gross_Margin Formula = Gross_Sales + Cost_of_Goods_Sold + Other_Cost_of_Goods_Sold >>>>---------*/


SELECT Sales_Channel, SKU, COUNT(*) AS Total_Rows,
SUM(CASE WHEN Gross_Margin = 0 THEN 1 ELSE 0 END) AS Zero_Margin_Rows
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NULL
GROUP BY Sales_Channel, SKU;

/* ----<<<<< As number of Total_Rows (missing product cost) and Zero_Margin_Rows are unequal implying If 
product cost is missing, profit does not become zero, that means transcation has happened >>>>>---------*/

-- checking if Gross_Margin = Gross_Sales + Cost_of_Goods_Sold + Other_Cost_of_Goods_Sold is true or not
SELECT TOP 150
Gross_Margin AS Stored_Margin,
Gross_Sales + Cost_of_Goods_Sold + Other_Cost_of_Goods_Sold AS Calculated_Margin,
ABS(Gross_Margin -(Gross_Sales + Cost_of_Goods_Sold + Other_Cost_of_Goods_Sold)) AS Difference
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
AND ABS(
        Gross_Margin -(Gross_Sales + Cost_of_Goods_Sold + Other_Cost_of_Goods_Sold)
    ) > 0.01;

/*---<<<<<<<<<<< Out of the entire dataset, only 97 rows had noticeable differences between stored
Gross_Margin and calculated Gross_Margin, and that too difference is more than 0.01, 
concluding -
Gross_Margin ≈ Gross_Sales + Cost_of_Goods_Sold + Other_Cost_of_Goods_Sold

Therefore, rows containing NULL values in cost-related columns do not
need to be removed from the dataset entirely. However, they should be
excluded from profitability analysis due to incomplete cost information,
while still being retained for revenue and sales-related analysis. >>>>>>>>>>-------*/

-- Checking if total_discount = all 3 sub category discount
SELECT TOP 50
    Total_Discount,
	Discount_Sub_Category_1,
    Discount_Sub_Category_2,
    Discount_Sub_Category_3,
ROUND(Discount_Sub_Category_1 + Discount_Sub_Category_2 + Discount_Sub_Category_3, 3) AS Calculated_Discount
FROM [CaseStudy].[dbo].[Sample Data];

/* ---------------<<<<<<<Discount sub-category values do not consistently sum to Total_Discount,indicating that 
other discounting columns data should be there or some discounts are overlapping on each other >>>>>>>>-------*/

-- Total distinct SKU and Parties
SELECT COUNT(DISTINCT SKU) AS Unique_SKUs, COUNT(DISTINCT Party_Name) AS Unique_Parties
FROM [CaseStudy].[dbo].[Sample Data];


------------------------- Checking quality of data ----------------------------------------

/*--------- Currently data have some data quality issues in some columns like Creation_date, 
to prevent data loss I'm creating 2 different columns for time and date of creation--------- */

alter table [CaseStudy].[dbo].[Sample Data]
add [Creation_Time] time;

-- Updating values in creation time column
UPDATE [CaseStudy].[dbo].[Sample Data]
SET [Creation_Time] = CAST([Creation_Date] AS TIME);

--Similary creating for Date from Creation_Date column
ALTER TABLE [CaseStudy].[dbo].[Sample Data]
ADD Creation_Date_Only DATE;

UPDATE [CaseStudy].[dbo].[Sample Data]
SET [Creation_Date_Only] = CAST([Creation_Date] AS DATE);


/*---------------------- Since Cost_of_Goods_Sold, Other_Cost_of_Goods_Sold, Gross_Sales, Gross_Margin and
Total_Discount are money, changing these to decimals upto 3 digits will  help in calculations ---------------*/

ALTER TABLE [CaseStudy].[dbo].[Sample Data]
ALTER COLUMN [Cost_of_Goods_Sold] DECIMAL(18,3);

ALTER TABLE [CaseStudy].[dbo].[Sample Data]
ALTER COLUMN [Other_Cost_of_Goods_Sold] DECIMAL(18,3);

UPDATE [CaseStudy].[dbo].[Sample Data]
SET Other_Cost_of_Goods_Sold = LTRIM(RTRIM(Other_Cost_of_Goods_Sold)); -- triming the extra space from lft and right

ALTER TABLE [CaseStudy].[dbo].[Sample Data]
ALTER COLUMN [Other_Cost_of_Goods_Sold] DECIMAL(18,3);

ALTER TABLE [CaseStudy].[dbo].[Sample Data]
ALTER COLUMN [Gross_Sales] DECIMAL(18,3);

ALTER TABLE [CaseStudy].[dbo].[Sample Data]
ALTER COLUMN [Gross_Margin] DECIMAL(18,3);

ALTER TABLE [CaseStudy].[dbo].[Sample Data]
ALTER COLUMN [Total_Discount] DECIMAL(18,3);



