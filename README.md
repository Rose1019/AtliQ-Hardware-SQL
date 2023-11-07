# AtliQ-Hardware-SQL

### Introduction
Atliq Hardware is a company that sells computer hardware products to big retailers like CROMA, Flipkart, Staples, and Bestbuy, who then sell them to individual consumers.  
They make these products in their own factory, store them in a warehouse, and have distribution centers to send them out when they get orders.  

The problem is, Atliq relies too much on Excel files to keep track of everything, and they want to find a better way to manage their data.  
But they can't completely get rid of Excel because it's essential for analyzing data.  

The Data team from AtliQ,build database using MySQL which is free and robust and then created data informed decision with the help of SQL Queries.

**The AtliQ Hardware dataset contains 1425706 records, which was given by Codebasics learning platform for the purpose of learning.**   

Sharing the link to [CodeBasics](https://codebasics.io/)  

-----------------------------------------------------------------------------------------------------------------------------------------
## Table Details

| Table Name | Description | Column Name |
| ---------- | ----------- | ----------- |
| dim_customer | contains customer-related data. | customer_code,customer,platform,channel,market,sub_zone,region. |
| dim_product | contains product-related data. | product_code,division,segment,category,product,variant. |
| fact_forecast_monthly | Contains monthly forecasted sales data for each product. | date,fiscal_year,product_code,customer_code,forecast_quantity |
| fact_freight_cost |Contains monthly freight and other costs. | market,fiscal_year,freight_pct,other_cost_pct |
| fact_gross_price | contains gross price information for each product | product_code,fiscal_year,gross_price |
| fact_manufacturing_cost | contains the cost incurred in the production of each product. | product_code,cost_year,manufacturing_cost. |
| fact_pre_invoice_deductions | contains pre-invoice deductions information for each product |customer_code,fiscal_year,pre_invoice_discount_pct |
| fact_post_invoice_deductions | contains post-invoice deductions information for each product. | Customer_code,product_code,date,discounts_pct,other_deductions_pct. |
| fact_sales_monthly | contains monthly sales data for each product. | date,product_code,customer_code,sold_quantity,fiscal_year |


------------------------------------------------------------------------------------------------------------------------------------------
## Code - On Finance Insights

*Transaction report for the Customer Reliance Digital  for the FY=2021 and Q4*
``` js
select s.date,s.product_code,
		p.product,p.variant,s.sold_quantity,
        g.gross_price,
        round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total
from fact_sales_monthly s
join dim_product p 
using(product_code)
join fact_gross_price g 
on g.product_code=s.product_code AND
   g.fiscal_year=get_fiscal_year (s.date)
where customer_code='90002001'
AND
get_fiscal_year(date) = 2021
AND
get_fiscal_quarter(date) ="Q4"
limit 1000000;
``` 

```
			Output
Fetched the transaction report for the Q4 from the FY 2021-06-01.


                       Concepts Learned
1.Converting Calendar Year to Fiscal Year
2.Sold Quantity * Gross Price = Total Gross Price
3.Creating USER-DEFINED FUNCTION for the Fiscal year and Quarters
4.JOIN
```
-----------------------------------------------------------------------------------------------------

*Yearly Gross Sales report for Customer Reliance Digital*
``` js	
select get_fiscal_year(date) as fiscal_year,
       round(sum(s.sold_quantity*g.gross_price),2) as Yearly_Total_Gross_Sales_amount
from fact_sales_monthly s 
join fact_gross_price g 
on g.product_code=s.product_code AND
g.fiscal_year=get_fiscal_year(s.date)
where customer_code=90002002
group by get_fiscal_year(s.date)
order by fiscal_year asc;
```

```
			Output
In 2018, the total gross sales amounted to $1,346,192, making it the year with the lowest sales figure.
On the other hand, 2020 saw the highest gross sales amount, reaching $5,861,703.
The total gross sales for 2019 were $3,532,768, followed by a significant increase in 2021, where the total gross sales reached $23,024,624.
Finally, in 2022, the total gross sales amounted to an impressive $43,868,353.

Analyzing these numbers, we can see a consistent growth in gross sales over the five-year period,
with 2022 standing out as a year of substantial growth compared to previous years. The sales figures indicate a positive trend,
suggesting that the business is performing well and experiencing significant expansion.


                       Concepts Learned
1.Creating USER-DEFINED FUNCTION for the Fiscal year and Quarters
2.JOIN
```
-----------------------------------------------------------------------------------------------------

*Monthly Gross Sales report for Customer Reliance Digital*
``` js	
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_monthly_gross_Sales_for_customer`(
in_customer_code text)
BEGIN
select s.date,s.customer_code,
       sum(round(s.sold_quantity*g.gross_price,2)) as monthly_gross_sales_amount
from fact_sales_monthly s 
join fact_gross_price g 
on g.product_code=s.product_code AND 
g.fiscal_year= get_fiscal_year(s.date)
where find_in_set(s.customer_code,in_customer_code)>0
group by s.date,s.customer_code
order by s.date asc;
END
```

```
			Output
Fetched the transaction report for the Customer Reliance Digital for any FY.


                       Concepts Learned
1.Stored Procedure
2.FIND_IN_SET()

```
-----------------------------------------------------------------------------------------------------


*To get the pre-invoice-deduction from fact_pre_invoice_deduction table*
``` js	
Create View sales_PreInvoice_deduction AS
(  select s.date,s.product_code,c.customer,s.market
   p.product,p.variant,s.sold_quantity,
   g.gross_price as gross_price_per_item,
   round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total,
   pre.pre_invoice_discount_pct as Pre_Invoice_Discnt_Pct					
	from fact_sales_monthly s
        join dim_customer using(customer_code)
        join dim_product p 
	using(product_code)
                
	join fact_gross_price g 
	on g.product_code=s.product_code AND
	g.fiscal_year=s.fiscal_year
				   
	join fact_pre_invoice_deductions pre 
	on pre.customer_code=s.customer_code   AND
	pre.fiscal_year=s.fiscal_year;
				
select *,
		round(Gross_Price_Total*(1-Pre_Invoice_Discnt_Pct),2) as Net_Invoice_Sales
from sales_preinvoice_deduction;
```

```
			Output
Fetched the Pre_invoice deduction percentage values for each product for any FY.


                       Concepts Learned
1.EXPLAIN ANALYZE used to analyzethe performance.
2.To improve the optimization : Added a new table dim_dateand a new column fiscal_yearto fact_salestable
3.VIEW

```
-----------------------------------------------------------------------------------------------------

## Code - On Top N Products,Markets,Customers

*Retrieve the TOP 2 markets in every region by their Gross Sales Amount in FY=2021*
``` js	
with yearly_gross_sales_amount  AS
(
select g.market,c.region,
	round(sum(Gross_Price_Total)/1000000,2) as Gross_Sales_Million
from new_gross_sales g
join dim_customer c
on c.customer_code=g.customer_code
where g.fiscal_year=2021
group by g.market,c.region
order by Gross_Sales_Million DESC
),
top_n_markets_region AS
(
	select *,
			dense_rank() over(partition by region order by Gross_Sales_Million DESC) as drnk
from yearly_gross_sales_amount
order by region
)
select *
from top_n_markets_region
where drnk<=2;
```

```
			Output
The rankings are determined by the gross sales amounts, which are measured in millions for the fiscal year 2021.
In the APAC region, India secured the top position, followed by South Korea.
Within the EU region, the first and second ranks were claimed by the UK and France, respectively.
In the LATAM region, Mexico secured the first place, with Brazil following closely in second position.
In the North America (NA) region, the USA took the top spot, while Canada secured the second position.

The rankings reflect the performance of each country within their respective regions based on their gross sales,
with India, the UK, France, Mexico, and the USA leading in their respective region.


                       Concepts Learned
1.Gross price -Pre invoice deduction= Net invoice sales
2.Net Invoice sales -Post invoice deduction = Net sales (Revenue)
3.CTE
4.Windows function:Dense_Rank()

```
-----------------------------------------------------------------------------------------------------



*To Fetch TOP N products from each Division  by Sold quantity*
``` js	
CREATE DEFINER=`root`@`localhost` PROCEDURE `top_n_products_division_by_sold_qty`(
     in_fiscal_year int,
     in_top_n int
)
BEGIN
with cte1 AS(
select 	p.division,
	p.product as Product_Name,
	sum(s.sold_quantity) as Total_quantity
from fact_sales_monthly s 
join dim_product p 
on s.product_code=p.product_code
where s.fiscal_year=in_fiscal_year
group by p.division,p.product
),
cte2 AS (
select *,
	dense_rank() over(partition by division order by Total_quantity desc) as dense_rnk
from cte1
)
select *
from cte2
where dense_rnk<=in_top_n  ;
END
```

```
			Output
The rankings are determined by the Total sold Quantity, which are measured in millions for any fiscal year.

                       Concepts Learned
1.CTE in Stored Procedure
2.Dense_Rank()

```
-----------------------------------------------------------------------------------------------------


*View on Gross Sales*
``` js
create view new_gross_sales AS
select s.date,
	s.fiscal_year,
	s.customer_code,
	c.customer,
	c.market,
	s.product_code,
	p.product,p.variant,
        s.sold_quantity,
	g.gross_price as gross_price_per_item,
	round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total
						
	from fact_sales_monthly s
	join dim_product p 
	using(product_code)
                
        join dim_customer c
        on c.customer_code=s.customer_code
                
        join fact_gross_price g 
	on g.product_code=s.product_code AND
	g.fiscal_year=s.fiscal_year;
```

```
			Output
With the help of the concept VIEW, the report on Total Gross sales amount is fetched for any FY.

                       Concepts Learned
1.VIEW
```
-----------------------------------------------------------------------------------------------------

## Code - On Supply Chain

*Report on which customers’ Forecast Accuracy has dropped from 2020 to 2021*
```js
/*Forecast Accuracy report for 2021:TEMPORARY TABLE*/
									
create temporary table forecast_accuracy_report_2021
WITH cte1 AS(
select af.Customer_Code as Customer_Code ,
	c.Customer_Code as Customer_Name,
        c.market as market,
	sum(af.Sold_Quantity) as Total_Sold_Quantity,
	sum(af.Forecast_Quantity) as	Total_Forecast_Quantity,
       sum(Forecast_Quantity-Sold_Quantity) as Net_Error,
       round(sum(Forecast_Quantity-Sold_Quantity)*100/sum(Forecast_Quantity),1) as Net_Error_Pct,
       sum(abs(Forecast_Quantity-Sold_Quantity)) as abs_error,
       round(sum(abs(Forecast_Quantity-Sold_Quantity))*100/sum(Forecast_Quantity),2) as abs_error_pct
       
from fact_actuals_forecast_table af
join dim_customer c
on af.Customer_Code=c.Customer_Code
where af.Fiscal_year=2021
group by Customer_Code
)

SELECT *,
	if(abs_error_pct>100,0,100-abs_error_pct) as Forecast_Accuracy_2021
FROM cte1
order by Forecast_Accuracy_2021 desc;


/*Forecast Accuracy report for 2020:TEMPORARY TABLE*/

create temporary table forecast_accuracy_report_2020
WITH cte2 AS(
select af.Customer_Code as Customer_Code ,
	c.Customer_Code as Customer_Name,
        c.market as market,
	sum(af.Sold_Quantity) as Total_Sold_Quantity,
        sum(af.Forecast_Quantity) as Total_Forecast_Quantity,
       sum(Forecast_Quantity-Sold_Quantity) as Net_Error,
       round(sum(Forecast_Quantity-Sold_Quantity)*100/sum(Forecast_Quantity),1) as Net_Error_Pct,
       sum(abs(Forecast_Quantity-Sold_Quantity)) as abs_error,
       round(sum(abs(Forecast_Quantity-Sold_Quantity))*100/sum(Forecast_Quantity),2) as abs_error_pct
from fact_actuals_forecast_table af
join dim_customer c
on af.Customer_Code=c.Customer_Code
where af.Fiscal_year=2020
group by Customer_Code
)

SELECT *,
	if(abs_error_pct>100,0,100-abs_error_pct) as Forecast_Accuracy_2020
FROM cte2
order by Forecast_Accuracy_2020 desc;

/*Join both tables forecast_accuracy_report_2021 and forecast_accuracy_report_2020 */

select a.Customer_Code,
       a.Customer_Name,
       a.market,
       a.Forecast_Accuracy_2020,
       b.Forecast_Accuracy_2021
       
from  forecast_accuracy_report_2020 a
join forecast_accuracy_report_2021 b
on a.Customer_Code=b.Customer_Code
where a.Forecast_Accuracy_2020>b.Forecast_Accuracy_2021
order by a.Forecast_Accuracy_2020 desc;
```

```
			Output
Retrieving customers whose performance or forecast accuracy in 2021 falls short of their 2020 performance.

                       Concepts Learned
1.Temporary table
2.CTE in Temporary table
3.Created a non-physical table with the help of UNION clause by joining Actuals and Forecast table.
```
-----------------------------------------------------------------------------------------------------
