-- Client Questions

/*------------------------------------------------------------------------------
Product & Channel Profitability
		• Identify the top 5 and Bottom 5 SKUs by
			o Gross Margin
			o Gross Margin %
		• How many SKUs have more than 50% gross margin % in Sales channel 6 but less
		than 20% in sales channel 4? List the SKU Names as well.
		• Which sales channels are most/least profitable?
			o By Gross Margin
			o Gross Margin %
*/--------------------------------------------------------------------------------

-- Top 5 SKU based on Gross Margin
SELECT TOP 5 SKU, SUM(Gross_Margin) AS Total_Gross_Margin
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY SKU
ORDER BY Total_Gross_Margin DESC;

-- Bottom 5 SKU based on Gross Margin
SELECT TOP 5 SKU, SUM(Gross_Margin) AS Total_Gross_Margin
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY SKU
ORDER BY Total_Gross_Margin Asc;


-- Top 5 SKU based on Gross Margin percent
SELECT TOP 5 SKU,
SUM(Gross_Margin) AS Total_Gross_Margin,
SUM(Gross_Sales) AS Total_Gross_Sales,
ROUND((SUM(Gross_Margin) * 100.0)/ NULLIF(SUM(Gross_Sales),0),2) AS Gross_Margin_Percentage
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY SKU
ORDER BY Gross_Margin_Percentage DESC;

-- Bottom 5 SKU based on Gross Margin percent
SELECT TOP 5 SKU,
SUM(Gross_Margin) AS Total_Gross_Margin,
SUM(Gross_Sales) AS Total_Gross_Sales,
ROUND((SUM(Gross_Margin) * 100.0)/ NULLIF(SUM(Gross_Sales),0),2) AS Gross_Margin_Percentage
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY SKU
ORDER BY Gross_Margin_Percentage Asc;

-- ----How many SKUs have more than 50% gross margin % in Sales channel 6 but less
-- than 20% in sales channel 4? List the SKU Names as well.

WITH SKU_Margins AS
(SELECT SKU, Sales_Channel,
ROUND((SUM(Gross_Margin) * 100.0) / NULLIF(SUM(Gross_Sales),0),2) AS Gross_Margin_Percentage
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY SKU, Sales_Channel)
SELECT COUNT(*) OVER() AS SKU_Count, A.SKU,
A.Gross_Margin_Percentage AS Channel6_Margin,
B.Gross_Margin_Percentage AS Channel4_Margin
FROM SKU_Margins A JOIN SKU_Margins B
ON A.SKU = B.SKU
WHERE A.Sales_Channel = 'Sales Channel 6'
AND B.Sales_Channel = 'Sales Channel 4'
AND A.Gross_Margin_Percentage > 50
AND B.Gross_Margin_Percentage < 20;

-- sales channels which are most profitable (Gross Margin)
SELECT TOP 5 [Sales_Channel], SUM(Gross_Margin) AS Total_Gross_Margin
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY [Sales_Channel]
ORDER BY Total_Gross_Margin DESC;

-- sales channels which are least profitable (Gross Margin)
SELECT TOP 5 [Sales_Channel], SUM(Gross_Margin) AS Total_Gross_Margin
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY [Sales_Channel]
ORDER BY Total_Gross_Margin asc;

-- Top 5 Sales_Channel based on Gross Margin percent
SELECT TOP 5 [Sales_Channel],
SUM(Gross_Margin) AS Total_Gross_Margin,
SUM(Gross_Sales) AS Total_Gross_Sales,
ROUND((SUM(Gross_Margin) * 100.0)/ NULLIF(SUM(Gross_Sales),0),2) AS Gross_Margin_Percentage
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY [Sales_Channel]
ORDER BY Gross_Margin_Percentage DESC;

-- Bottom 5 Sales_Channel based on Gross Margin percent
SELECT TOP 5 [Sales_Channel],
SUM(Gross_Margin) AS Total_Gross_Margin,
SUM(Gross_Sales) AS Total_Gross_Sales,
ROUND((SUM(Gross_Margin) * 100.0)/ NULLIF(SUM(Gross_Sales),0),2) AS Gross_Margin_Percentage
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY [Sales_Channel]
ORDER BY Gross_Margin_Percentage asc;

/*  Discounting Impact
Sales Channel 6 has shown inconsistent discounting patterns — two similar customers
often receive very different discounts for similar purchases. This leads to:
• Revenue and margin leakage
• Internal pricing inefficiencies
• Customer dissatisfaction due to perceived unfairness
Without doing any calculations, suggest how discounting should be done in future by
outlining a step-by-step methodology to derive a “fair discount range” for future
transactions, using the historical data.
*/

-- checking the health of discount pattern in Sales Channel 6
-- as similar customers receiving different discounts for similar purchases, checking the trend for different Item_category and SKU
SELECT Item_Cat_New,
    COUNT(*) AS Transactions,
    AVG(Total_Discount) AS Avg_Discount,
    MIN(Total_Discount) AS Min_Discount,
    MAX(Total_Discount) AS Max_Discount
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Sales_Channel = 'Sales Channel 6'
GROUP BY Item_Cat_New
ORDER BY AVG(Total_Discount) asc; -- Item Category 8,59, 20, 124, 117 have highest discount

SELECT SKU,
    COUNT(*) AS Transactions,
    AVG(Total_Discount) AS Avg_Discount,
    MIN(Total_Discount) AS Min_Discount,
    MAX(Total_Discount) AS Max_Discount
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Sales_Channel = 'Sales Channel 6'
GROUP BY SKU
ORDER BY AVG(Total_Discount) asc; -- SKU - SKU1966, SKU1083, SKU2523, SKU2008, SKU1137 HAVE HIGHEST DISCOUNT


-------------------------------------------------------------------------------------------------------------
-- Based on account numbers and transcations, analysying percents of avg, min and max for Sales Channel 6
SELECT Account_Number, SKU, Sales_Channel, COUNT(*) AS Transactions,
ROUND(AVG(ABS(Total_Discount) * 100.0/ NULLIF(List_Price,0)),2) AS Avg_Discount_Percentage,
ROUND(MIN(ABS(Total_Discount) * 100.0/ NULLIF(List_Price,0)),2) AS Min_Discount_Percentage,
ROUND(MAX(ABS(Total_Discount) * 100.0/ NULLIF(List_Price,0)),2) AS Max_Discount_Percentage
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Sales_Channel = 'Sales Channel 6'
GROUP BY Account_Number, SKU, Sales_Channel
HAVING COUNT(*) > 5
ORDER BY Avg_Discount_Percentage DESC;


-------------------------------------------------------------------------------------------------------------
/* SKU Rationalization
• Which SKUs generate negative overall margins (sold at a loss) but still contribute
significantly to total revenue or sales? Additionally, which sales channel carries
the highest number of such SKUs?
• Are there customers with negative total margins but more than $300,000 in
sales? How many such customers exist, and who are the five worst-performing
customers?
• What is the median gross margin percentage and the 75th percentile gross
margin percentage across different sales channels?

*/
-- SKUs generating negative overall margins but contributing high revenue
SELECT top 5 SKU, SUM(Gross_Sales) AS Total_Revenue,
SUM(Gross_Margin) AS Total_Gross_Margin
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY SKU
HAVING SUM(Gross_Margin) < 0
ORDER BY Total_Revenue DESC;

-- which sales channels carries the highest number of such SKUs?
select x.[Sales_Channel], COUNT(DISTINCT x.SKU) Num_of_SKU
from (SELECT  SKU, [Sales_Channel], 
SUM(Gross_Sales) AS Total_Revenue,
SUM(Gross_Margin) AS Total_Gross_Margin
FROM [CaseStudy].[dbo].[Sample Data]
WHERE Cost_of_Goods_Sold IS NOT NULL
AND Other_Cost_of_Goods_Sold IS NOT NULL
GROUP BY [Sales_Channel], SKU
HAVING SUM(Gross_Margin) < 0)x
group by x.[Sales_Channel]
ORDER BY Num_of_SKU DESC;

----------------------------------------------------------------------
/* Are there customers with negative total margins but more than $300,000 in sales? How many such customers 
exist, and who are the five worst-performing customers?
*/
-- Total customers with negative margin and more than 300, 000 dollar in sale
SELECT COUNT(*) AS Total_Customers
FROM (SELECT Account_Number
      FROM [CaseStudy].[dbo].[Sample Data]
      GROUP BY Account_Number
      HAVING SUM(Gross_Margin) < 0
      AND SUM(Gross_Sales) > 300000
) x;

-- Detail of worst-performing 5 customers
SELECT top 5 Account_Number, Account_Name, SUM(Gross_Sales) AS Total_Sales, SUM(Gross_Margin) AS Total_Margin
FROM [CaseStudy].[dbo].[Sample Data]
GROUP BY Account_Number, Account_Name
HAVING SUM(Gross_Margin) < 0
AND SUM(Gross_Sales) > 300000
ORDER BY Total_Margin ASC;

-- Detail of best-performing 5 customers
SELECT top 5 Account_Number, Account_Name, SUM(Gross_Sales) AS Total_Sales, SUM(Gross_Margin) AS Total_Margin
FROM [CaseStudy].[dbo].[Sample Data]
GROUP BY Account_Number, Account_Name
ORDER BY Total_Margin desc;


/* What is the median gross margin percentage and the 75th percentile gross
margin percentage across different sales channels? (using window function and percentile)
*/

