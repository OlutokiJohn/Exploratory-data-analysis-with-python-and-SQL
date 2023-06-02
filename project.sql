/* 
         ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         + Guided Project: Customers and Products Analysis Using SQL +
         ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 Introduction:

 As part of this project we will be analysing the scale care model datbase using SQL to answer following questions

 Question 1: Which products should we order more of or less of?
 Question 2: How should we tailor marketing and communication strategies to customer behaviors?
 Question 3: How much can we spend on acquiring new customers?

Database Summary:

Customers: customer data
Employees: all employee information
Offices: sales office information
Orders: customers' sales orders
OrderDetails: sales order line for each sales order
Payments: customers' payment records
Products: a list of scale model cars
ProductLines: a list of product line categories 
*/
-- Exploring the dataset 
SELECT 'Customers' AS table_name, 
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers
  
UNION ALL

SELECT 'Products' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name, 
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name, 
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;
  
/* QUESTION 1: Which products should we order more of or less of?

This inquiry pertains to inventory analysis, encompassing low stock levels and product performance.
 The aim is to enhance supply and user satisfaction by averting stockouts of popular items.

To address this, we should approach the solution through the following steps:

** STEP 1: Identify products with low stock by calculating the ratio of quantity sold to quantity in stock.

We can focus on the ten lowest ratios, which indicate the top ten products that are nearly depleted.

** STEP 2: Evaluate product performance by aggregating total sales for each product.

** STEP 3: Prioritize restocking for products that demonstrate high product performance and are at risk of running out of stock. */
-- Step 1 Low stock
SELECT productCode,ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
														FROM products p
														WHERE o.productCode = p.productCode), 2) AS low_stock
FROM orderdetails AS o
GROUP BY productCode
ORDER BY low_stock
LIMIT 10;

-- Step 2 Product performance 
SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS product_performance
  FROM orderdetails 
 GROUP BY productCode 
 ORDER BY product_performance DESC
 LIMIT 10;
 
 -- Step 3 Priority products we need to restock
 
WITH low_stock AS(
SELECT productCode,ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
														FROM products p
														WHERE o.productCode = p.productCode), 2) AS low_stock
FROM orderdetails AS o
GROUP BY productCode
ORDER BY low_stock
LIMIT 10)

SELECT 	p.productName,p.productLine,o.productCode, SUM(o.quantityOrdered  * o.priceEach) AS Product_Performance
FROM orderdetails o
JOIN products AS p
ON p.productCode = o.productCode
WHERE o.productCode IN (SELECT productCode
						FROM low_stock)
GROUP BY o.productCode
ORDER BY Product_Performance DESC;

/* Question 2: How should we tailor marketing and communication strategies to customer behaviors?

This task entails segmenting customers based on their engagement levels, specifically identifying VIP 
(very important person) customers as well as those who are less engaged.

VIP customers contribute significantly to the store's profitability, while less-engaged customers generate comparatively lower profits.

To illustrate, we can plan targeted events to foster loyalty among VIP customers and initiate a campaign specifically tailored to engage
 the less-engaged customer segment.
*/
-- Let's calculate the profit generated by each individual customer.
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
 ORDER BY profit DESC;
 
-- Identifying the VIPs and the countries they come from
WITH customer_orders AS(
 SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
 ORDER BY profit DESC
 LIMIT 5)
 
 SELECT customerName, customerNumber,contactFirstName,contactLastName, country
 FROM customers
 WHERE customerNumber IN(
 SELECT customerNumber
 FROM customer_orders);

-- Customers with the least engagement

WITH leastcustomers AS(

SELECT o.customerNumber as customerNumber ,SUM(od.quantityOrdered * (od.priceEach - p.buyPrice)) AS revenue
FROM products as p
JOIN orderdetails as od
ON p.productCode = od.productCode
JOIN orders as o
ON o.orderNumber = od.orderNumber
GROUP BY customerNumber
ORDER BY revenue ASC
LIMIT 5)

SELECT c.customerName,c.contactFirstName,c.contactLastName,c.country,l.revenue as new_rev
FROM customers AS c
JOIN leastcustomers  AS l
ON  l.customerNumber = c.customerNumber
WHERE c.customerNumber IN(SELECT customerNumber
						FROM leastcustomers)
GROUP BY c.contactFirstName
ORDER BY new_rev;
-- Question 3: How much can we spend on acquiring new customers?
/* we must compute the Lifetime Value (LTV) of our customers. This metric quantifies the average profit generated by a 
customer over their entire relationship with our store, enabling us to make predictions about future profitability. 
To accomplish this, we execute the following query. */
--Finally Lets calculate the customers Life time Value

-- Customer LTV
WITH 

money_in_by_customer AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)

SELECT AVG(mc.revenue) AS ltv
  FROM money_in_by_customer mc;
-- Inferences from the Analysis
/* 
1. It is essential for the company to replenish its stock of Classic Cars as they are the top-performing products and are nearing depletion.
2. The VIPs customers includes:
1. Australian Collectors, Co. from Australia

2. La Rochelle Gifts from France

3. Mini Gifts Distributor Ltd. from USA

4. Euro + Shopping Channel from Spain

5. Muscle Machine Inc. from USA

while our Least Performing Customers includes:

1. Boards and Toys Co. from USA

2. Auto Moto Classics Inc. from USA

3. Frau da Collezione from Italy

4. Atelier graphique from France

5. Double Decker Gift Stores Ltd, from UK

3. Based on our calculated Customer LTV of 390,395, we gain insights into the average profit generated by a customer over their lifetime with our store. 
This information allows us to make predictions about our future profitability. For instance, if we acquire ten new customers next month, 
we can anticipate earning 390,395 dollars. Using this prediction, we can determine the appropriate budget allocation for customer acquisition efforts. 
*/