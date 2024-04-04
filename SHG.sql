-- View data 
SELECT * FROM SHG

--Check structure of table
SP_HELP SHG;

--Dropping unwanted Columns
ALTER TABLE SHG
DROP COLUMN f18;

--Checking unique values in each column
SELECT DISTINCT [Hotel]
FROM SHG
--Resort, City

SELECT DISTINCT [Distribution Channel]
FROM SHG
--Online Travel Agent, Corporate, Offline Travel Agent, Direct, Undefined

SELECT DISTINCT [Customer Type]
FROM SHG
--Group, Contract, Transient, Transient-Party

SELECT DISTINCT [Country]
FROM SHG
--There are null values in Country

UPDATE SHG
SET Country = 'Unknown'
WHERE Country IS NULL
--488 rows affected


SELECT DISTINCT [Deposit Type]
FROM SHG
-- No Deposit, Refundable, Non Refundable

SELECT DISTINCT [Status]
FROM SHG
--Check-Out, No-Show, Canceled

--Convert Booking Date, Arrival Date & Status Update to Date Format
ALTER TABLE SHG
ALTER COLUMN [Booking Date] DATE

ALTER TABLE SHG
ALTER COLUMN [Arrival Date] DATE

ALTER TABLE SHG 
ALTER COLUMN [Status Update] DATE

--Combine Revenue and Revenue Loss Column
UPDATE SHG
SET Revenue = [Revenue Loss]
WHERE [Revenue Loss] != 0

--Drop Revenue Loss column
ALTER TABLE SHG
DROP COLUMN [Revenue Loss]

--Check for NULL values
SELECT *
FROM SHG
WHERE [Booking ID] is NULL
	  OR [Lead Time] is NULL
	  OR [Nights] is NULL
	  OR [Guests] is NULL
	  OR [Avg Daily Rate] is NULL
	  OR [Cancelled (0/1)] is NULL

--Rename column
EXEC SP_RENAME 'SHG.Cancelled (0/1)', 'Cancelled'
-- Rename Rows
UPDATE SHG
SET Status = 'Cancelled'
WHERE Status = 'Canceled'

--Confirm Revenue was only lost when customers cancelled
Select DISTINCT Status
FROM SHG
WHERE Revenue < 0
--Some checked-out booking still led to revenue loss showing an error in revenue

--Check for the error
SELECT * 
FROM SHG
WHERE [Lead Time] < 0
	  OR Nights < 0
	  OR Guests < 0 
	  OR [Avg Daily Rate] < 0
	  OR Cancelled < 0
	  AND Revenue < 0
--There's an error in Avg Daily Rate for Booking ID 14970

--Correct error for Booking ID 14970
UPDATE SHG
SET Revenue = Revenue * -1, [Avg Daily Rate] = [Avg Daily Rate] * -1
WHERE [Lead Time] < 0
	  OR Nights < 0
	  OR Guests < 0 
	  OR [Avg Daily Rate] < 0
	  OR Cancelled < 0
	  AND Revenue < 0
-- Error corrected

--Reconfirm Revenue was only lost when customers cancelled
SELECT DISTINCT Status
FROM SHG
WHERE Revenue < 0
-- Fixed

--Check for Duplicates
SELECT [Booking ID], COUNT([Booking ID])
FROM SHG
GROUP BY [Booking ID]
HAVING COUNT([Booking ID]) > 1
--No duplicates



--QUESTIONS
--1. What is the trend in booking patterns over time, and are there specific seasons or months with increased booking activity?

SELECT
	YEAR(CONVERT(DATETIME, [Booking Date])) AS [Booking Year], 
	MONTH(CONVERT(DATETIME, [Booking Date])) AS [Booking_Month],
	COUNT(*) AS [Booking Count]
FROM SHG
GROUP BY YEAR(CONVERT(DATETIME, [Booking Date])), MONTH(CONVERT(DATETIME, [Booking Date]))
ORDER BY YEAR(CONVERT(DATETIME, [Booking Date])), MONTH(CONVERT(DATETIME, [Booking Date]))

/*Answer: -Bookings genrally increased in 2015 and significantly dropped late 2017
          -There was a significant increase in bookings in Janury 2016 & 2017
		  -2017 recorded thehighest number of bookings in a month*/



--2. How does lead time vary across different booking channels, 
--and is there a correlation between lead time and customer type?
SELECT [Distribution Channel], CAST(ROUND(AVG([Lead Time]), 0) AS INT) AS Lead_Time
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY AVG([Lead Time]);
/*Answer: Cooperate channel have the least lead time of 45 days. 
          Offline Travel agents had the longest lead time with 136 days*/

SELECT [Customer Type], CAST(ROUND(AVG([Lead Time]), 0) AS INT) AS Lead_Time
FROM SHG
GROUP BY [Customer Type]
ORDER BY AVG([Lead Time]);
/*Answer: Group customers have the least average lead time of 55 days. 
		  Contract customers have the longest average lead time of 143 days.*/



--   Customer Behavior Analysis:
--3. Which distribution channels contribute the most to bookings, 
--  and how does the average daily rate (ADR) differ across these channels?
SELECT [Distribution Channel], COUNT([Booking ID]) AS Bookings
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY COUNT([Booking ID]) DESC;
--Online Travel Agent contributes the most to the booking with 74,072
SELECT [Distribution Channel], ROUND(SUM(Revenue)/SUM(Nights),2) AS ADR
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY SUM(Revenue)/SUM(Nights) DESC;
/* Answer: Direct Channel has the most average daily rate of $72.67
           Online Travel channel has the least average daily rate of $25.64 */


--4. Can we identify any patterns in the distribution of guests based on their country of origin, 
--   and how does this impact revenue?
SELECT [Country], SUM([Guests]) Total_Guests, SUM(Revenue) Revenue
FROM SHG
WHERE [Revenue] > 0
GROUP BY [country]
ORDER BY SUM(Guests) DESC;
/*Top three countries with most guests are Portugal, United Kingdom and France and contribute more to the revenue.*/

--What customer type are common in top three countries?
SELECT [Customer Type], COUNT([Customer Type]) AS [Customer Number], Country
From SHG
WHERE Country IN ('Portugal', 'United Kingdom', 'France')
GROUP BY Country, [Customer Type]
ORDER BY Country, [Customer Number] DESC;
--Transient and Transient-Party Customer type are the most customers in these Countries. Group customers are the lowest.


--Cancellation Analysis:
--●	What factors are most strongly correlated with cancellations, and can we predict potential cancellations based on certain variables?
SELECT [Distribution Channel],[Customer Type], Country, COUNT(*)  AS Occurence
FROM SHG
WHERE Cancelled = 1
GROUP BY [Distribution Channel], [Customer Type], Country
ORDER BY Occurence DESC;
-- Portugal has the highest rate of cancellation with all types of customer or distribution channel.

--●	How does the revenue loss from cancellations compare across different customer segments and distribution channels?
SELECT [Customer Type], SUM(Revenue) [Total Loss]
FROM SHG
WHERE Cancelled = 1
GROUP BY [Customer Type]
ORDER BY [Total Loss] ASC;
-- Total loss for transient customers is -$8,138,113.10
-- Total loss for Transient-Party customers is -$1,149,508.15
-- Total loss for Contract customers is -$213,616.62
-- Total loss for Group customers is -$17,325.19

SELECT [Distribution Channel], SUM(Revenue) [Total Loss]
FROM SHG
WHERE Cancelled = 1
GROUP BY[Distribution Channel]
ORDER BY [Total Loss] ASC;
-- Total loss for Online Travel Agent is -$8,744,453.83
-- Total loss for Direct is -$925,702.50
-- Total loss for Corporate is	-$104,988.84
-- Offline Travel Agent made no loss but made a profit of $257,189.61 because deposit type was non-refundable 

--Revenue Optimization:
--●	What is the overall revenue trend, and are there specific customer segments or countries contributing significantly to revenue?
SELECT 
	SUM(CASE WHEN Revenue > 0 THEN Revenue ELSE 0 END) Revenue,
	SUM(CASE WHEN Revenue < 0 THEN Revenue ELSE 0 END) Loss,
	SUM(Revenue) Total_Profit
FROM SHG;
-- Total Revenue is $29,600,725.04	
-- Total Revenue Loss is -$13,122,900.09	
-- Total Profit within that period is $16,477,824.95


SELECT [Customer Type], SUM(Revenue) Revenue
FROM SHG
GROUP BY [Customer Type]
ORDER BY Revenue DESC;
-- Transient customers contributes most to the revenue with a total of $11,194,523.85
SELECT Country, SUM(Revenue) Revenue
FROM SHG
GROUP BY Country
ORDER BY Revenue DESC;
--Portugal, United Kingdom and France contributes the most to revenue.


--Geographical Analysis:
--●	How does the distribution of guests vary across different countries, and are there specific countries that should be targeted for marketing efforts?
SELECT SUM(Guests) Guests, Country
FROM SHG
GROUP BY Country
ORDER BY Guests DESC;
--Portugal has the most guests of 90,036, with United Kingdom and France following.

--●	Is there a correlation between the country of origin and the likelihood of cancellations or extended stays?
SELECT Country, COUNT(*) Cancellations
FROM SHG
WHERE Status = 'Cancelled' 
GROUP BY Country
ORDER BY  Cancellations DESC
--Portugal has the most likelihood of cancellations
SELECT Country, SUM(Nights) Nights
FROM SHG
WHERE Status = 'Check-Out'
GROUP BY Country
ORDER BY  Nights DESC
--Portugal, United Kingdom and France have more extended stays than other countries.

--Operational Efficiency:
--●	What is the average length of stay for guests, and how does it differ based on booking channels or customer types?
SELECT ROUND(AVG(Nights), 0), [Distribution Channel]
FROM SHG
WHERE Status = 'Check-Out'
GROUP BY [Distribution Channel];
--Offline Travel Agents had the highest average length of stay with 4 nights while Corporate had the lowest.
SELECT ROUND(AVG(Nights), 0), [Customer Type]
FROM SHG
WHERE Status = 'Check-Out'
GROUP BY [Customer Type];
--Contract Customers have the highest average length of stay with 6 nights.


--Impact of Deposit Types:
--●	How does the presence or absence of a deposit impact the likelihood of cancellations and revenue generation?
SELECT  [Deposit Type],
		SUM(CASE WHEN Cancelled = 0 THEN Revenue END) No_Cancellations,
		SUM(CASE WHEN Cancelled = 1 THEN Revenue END) Cancellations,
		COUNT(*) Bookings
FROM SHG
GROUP BY [Deposit Type]
--For Non-deposit bookings, cancellations resulted to -$13,102,901.92 loss in revenue and $25,950,290.93 profit.
--Non refundable bookings made no losses for both cancellations and non cancellations.
SELECT  [Deposit Type],
		SUM(CASE WHEN Cancelled = 0 THEN 1 END) No_Cancellations,
		SUM(CASE WHEN Cancelled = 1 THEN 1 END) Cancellations,
		COUNT(*) Bookings
FROM SHG
GROUP BY [Deposit Type]
-- For No deposit bookings  no cancellations were higher by over 40,000.
-- Cancellations were higher in Non-refundable bookings.


--●	Can we identify any patterns in the use of deposit types across different customer segments?
SELECT DISTINCT [Deposit Type], [Customer Type], COUNT(*) Bookings
FROM SHG
GROUP BY [Deposit Type], [Customer Type]
ORDER BY Bookings DESC
--Transient Guests who did not deposit have the highest number of guests with 76,684.


--Analysis of Corporate Bookings:
--●	What is the proportion of corporate bookings, and how does their Average Daily Rate (ADR) compare to other customer types?
SELECT  [Distribution Channel], SUM([Avg Daily Rate]) ADR, 
		CAST(ROUND((SUM([Avg Daily Rate]) * 100.0) / SUM(SUM([Avg Daily Rate])) OVER(), 1) AS DECIMAL(10, 1)) ADR_Percent,
		COUNT(*)
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY ADR;
-- Coperate bookings have the least Average Daily Rate comparing 3.8% of the others and also the least total number of booking.

--●	Are there specific trends or patterns related to corporate bookings that can inform business strategies?
SELECT Country, COUNT(*) Bookings
FROM SHG
WHERE [Distribution Channel] = 'corporate'
GROUP BY Country
ORDER BY Bookings DESC;
-- Portugal is the country with highest corporate channel for booking with 4,526.

SELECT [Customer Type], COUNT(*) Bookings
FROM SHG
WHERE [Distribution Channel] = 'corporate'
GROUP BY [Customer Type]
ORDER BY Bookings DESC
-- Transient customers used corporate channel the most 4,157 times. 


--Time-to-Event Analysis:
--●	How does the time between booking and arrival date (lead time) affect revenue and the likelihood of cancellations?
SELECT
    SUM(Revenue) AS TotalRevenue,
    COUNT(*) AS NumberOfBookings,
    CASE
        WHEN [Lead Time] BETWEEN 0 AND 499 THEN '0-499 days'
        WHEN [Lead Time] BETWEEN 500 AND 999 THEN '500-999 days'
        WHEN [Lead Time] BETWEEN 1000 AND 2000 THEN '1000-2000 days'
        ELSE 'Other'
    END AS LeadTimeRange,
	SUM(CASE WHEN Cancelled = 0 THEN 1 END) No_Cancellations,
	SUM(CASE WHEN Cancelled = 1 THEN 1 END) Cancellations
FROM SHG 
--WHERE Status = 'Cancelled'
GROUP BY  CASE
        WHEN [Lead Time] BETWEEN 0 AND 499 THEN '0-499 days'
        WHEN [Lead Time] BETWEEN 500 AND 999 THEN '500-999 days'
        WHEN [Lead Time] BETWEEN 1000 AND 2000 THEN '1000-2000 days'
        ELSE 'Other'
    END
ORDER BY LeadTimeRange 
-- Lead Time Range below 500 days seemed to have more boookings and contributed more to the revenue with $16,401,565.72 and had lesser cancellations compared to lead time below 500

--●	Are there specific lead time ranges that are associated with higher customer satisfaction or revenue?
-- Yes Lead times below 500 days contributed more to the revenue with more booking days

--Comparison of Online and Offline Travel Agents:
--●	What is the revenue contribution of online travel agents compared to offline travel agents?
SELECT SUM(Revenue), [Distribution Channel]
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY [Distribution Channel] DESC
--Online Travel Agent contributed more to the revenue with $6,472,252.69 and offline agent with $5,883,053.

--●	How do cancellation rates and revenue vary between bookings made through online and offline travel agents?
SELECT 
	SUM(CASE WHEN Cancelled = 0 THEN 1 END) No_Cancellations,
	SUM(CASE WHEN Cancelled = 1 THEN 1 END) Cancellations,
	[Distribution Channel]
FROM SHG
GROUP BY [Distribution Channel]
ORDER BY No_Cancellations DESC
--Online Travel Agents have thrice more cancellations than Offline Travel Agents.  