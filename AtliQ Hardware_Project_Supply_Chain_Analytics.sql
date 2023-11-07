								/*SUPPLY CHAIN ANALYTICS*/
/*Forecast Accuracy Report for all customers for a given FY*/
/*As a product owner,i need a n aggregate forecast accuracy report for all the customers for a given
  fiscal year so that i can track the accuracy of the forecats we make for these customer.*/

/*The whole calculation is based on the Total_sold_Qty and the total_forecast_Qty (Table:fact_forecast_monthly*/
/*Both fact_sales table and fact_forecast table are same except one column in forecate table named forecast_qty*/

/*We can create a new table whihc will include both the columns and that can be done by JOINS.*/
/*Making both the columns in one table will make the SQL Query very simpler*/

/*Want to check the Maximum date in forecast monthly table*/
select max(date)
from fact_forecast_monthly; /*2022-08-01*/

/*Want to check the Maximum date in fact sales monthly table*/
select max(date)
from fact_sales_monthly; /*2021-12-01*/

/*which shows the number of rows are differenct in both the tables*/
select count(*)
from fact_forecast_monthly; /*1885941*/

select count(*) 
from fact_sales_monthly; /*1425706*/

/*Performing INNER JOIN*/
select a.*,
	   f.forecast_quantity
from fact_sales_monthly a 
join fact_forecast_monthly f 
using (date,product_code,customer_code);

/*To know how many common rows are there in both the table in INNER JOIN*/
select count(*)
from fact_sales_monthly a 
join fact_forecast_monthly f 
using (date,product_code,customer_code); /*1390837 ~ 1.3 Million common rows*/


/*sales table count of rows :1425706
inner join : 1390837
diff: 34869 extra rows in sales table*/

/*forecast table count of rows :1885941
inner join : 1390837
diff: 495104 extra rows in forecast table*/


/*we will share this with bz. manager about the extra columns on both the right and left table
they will ask us to fill those extra column values with 0*/

/*So if you do left join and if you dont have a record on a right table , it will show those values as NULL*/
select a.*,
	   f.forecast_quantity
from fact_sales_monthly a 
left join fact_forecast_monthly f 
using (date,product_code,customer_code)
where f.forecast_quantity IS NULL;

/*So if you do right join and if you dont have a record on a left table , it will show those values as NULL*/
select a.*,
	   f.forecast_quantity
from fact_sales_monthly a 
right join fact_forecast_monthly f 
using (date,product_code,customer_code)
where a.sold_quantity IS NULL
limit 1000000;

/*Now we will do a FULL OUTER JOIN and fill those extra columns with 0*/

select a.date as Date,
	   a.fiscal_year as Fiscal_Year,
	   a.product_code as Product_Code,
       a.customer_Code as Customer_Code,
       a.sold_quantity as Sold_Quantity,
	   f.forecast_quantity as Forecast_Quantity
from fact_sales_monthly a 
left join fact_forecast_monthly f 
using (date,product_code,customer_code)

UNION

/*Need to write another query on left join on fact_sales monthly table and also use UNION to have full outer join*/
/*Once the new table is created, we want to check the table details and do the following:*/
/*1->Uncheck Unsiughed option for the column sold_qty*/
/*2->delete the fiscal_year column and apply it.And copy the formula for fiscal_year from fact_sales_monthly table and
     use in the new table*/


/*1.9 MILLION record*/
select f.date as Date,
	   f.fiscal_year as Fiscal_Year,
	   f.product_code as Product_Code,
       f.customer_Code as Customer_Code,
       a.sold_quantity as Sold_Quantity,
	   f.forecast_quantity as Forecast_Quantity
from fact_forecast_monthly f 
left join fact_sales_monthly a  
using (date,product_code,customer_code);


/*Now create a new table*/

create table fact_actuals_forecast_table
( 
select a.date as Date,
	   a.fiscal_year as Fiscal_Year,
	   a.product_code as Product_Code,
       a.customer_Code as Customer_Code,
       a.sold_quantity as Sold_Quantity,
	   f.forecast_quantity as Forecast_Quantity
from fact_sales_monthly a 
left join fact_forecast_monthly f 
using (date,product_code,customer_code)

UNION

select f.date as Date,
	   f.fiscal_year as Fiscal_Year,
	   f.product_code as Product_Code,
       f.customer_Code as Customer_Code,
       a.sold_quantity as Sold_Quantity,
	   f.forecast_quantity as Forecast_Quantity
from fact_forecast_monthly f 
left join fact_sales_monthly a  
using (date,product_code,customer_code)
);


/*Update the column sold_qty and forecast_qty null values to 0*/
update fact_actuals_forecast_table
set Sold_Quantity =0
where Sold_Quantity IS NULL;

update fact_actuals_forecast_table
set Forecast_Quantity =0
where Forecast_Quantity IS NULL;


/*Triggers and events are not necessary for Data analyst*/
/*Temporary tables and Forecast Accuracy Report*/

/*Forecast Accusracy report*/
/*Calculate Net Error*/

With forecast_accuracy_report AS
(
select Customer_Code,
       sum(Forecast_Quantity-Sold_Quantity) as Net_Error,
       round(sum(Forecast_Quantity-Sold_Quantity)*100/sum(Forecast_Quantity),1) as Net_Error_Pct,
       sum(abs(Forecast_Quantity-Sold_Quantity)) as abs_error,
       round(sum(abs(Forecast_Quantity-Sold_Quantity))*100/sum(Forecast_Quantity),2) as abs_error_pct
       
from fact_actuals_forecast_table af
where af.Fiscal_year=2021
group by Customer_Code    
)

SELECT *,
		(100-abs_error_pct) as Forecast_Accuracy /*(1-abs_error_pct): doing this we will get negative values, and it is because*/
                                               /*(abs_error_pct) this is percenatge value so, shoud subtract with 100*/
FROM forecast_accuracy_report
order by Forecast_Accuracy asc;


/*We can see some negative values in Forecast_accuracy, it is bz whenever the abs_error_pct is more than 100, then we get the negtaive 
value which we dont want. That means, our forecast accuracy is ZERO.*/
/*SO whenever, the forecast accuracy percentage is 100 or more than 100, our forecast acuuracy si 0*/
/*And to avoid that, we use IF()*/

With forecast_accuracy_report AS
(
select af.Customer_Code,
	   sum(af.Sold_Quantity) as Total_Sold_Quantity,
	   sum(af.Forecast_Quantity) as	Total_Forecast_Quantity,
       sum(Forecast_Quantity-Sold_Quantity) as Net_Error,
       round(sum(Forecast_Quantity-Sold_Quantity)*100/sum(Forecast_Quantity),1) as Net_Error_Pct,
       sum(abs(Forecast_Quantity-Sold_Quantity)) as abs_error,
       round(sum(abs(Forecast_Quantity-Sold_Quantity))*100/sum(Forecast_Quantity),2) as abs_error_pct
       
from fact_actuals_forecast_table af
where af.Fiscal_year=2021
group by Customer_Code    
)

SELECT af.Customer_Code,
	   c.customer as Customer_Name,
	   c.market,
       af.Total_Forecast_Quantity,
       af.Total_Sold_Quantity,
       af.Net_Error,
       af.abs_error,
		if(abs_error_pct>100,0,100-abs_error_pct) as Forecast_Accuracy 
FROM forecast_accuracy_report af
join dim_customer c
on af.customer_code = c.Customer_Code
order by Forecast_Accuracy desc;

/*To create a STORED PROCEDURE*/
/* Create procedure get_forecast_accuracy_report_fiscal_year(
 in_fiscal_year int
 )
 
 BEGIN
 With forecast_accuracy_report AS
(
select af.Customer_Code,
	   sum(af.Sold_Quantity) as Total_Sold_Quantity,
	   sum(af.Forecast_Quantity) as	Total_Forecast_Quantity,
       sum(Forecast_Quantity-Sold_Quantity) as Net_Error,
       round(sum(Forecast_Quantity-Sold_Quantity)*100/sum(Forecast_Quantity),1) as Net_Error_Pct,
       sum(abs(Forecast_Quantity-Sold_Quantity)) as abs_error,
       round(sum(abs(Forecast_Quantity-Sold_Quantity))*100/sum(Forecast_Quantity),2) as abs_error_pct
       
from fact_actuals_forecast_table af
where af.Fiscal_year=2021
group by Customer_Code    
)

SELECT af.Customer_Code,
	   c.customer as Customer_Name,
	   c.market,
       af.Total_Forecast_Quantity,
       af.Total_Sold_Quantity,
       af.Net_Error,
       af.abs_error,
		if(abs_error_pct>100,0,100-abs_error_pct) as Forecast_Accuracy 
FROM forecast_accuracy_report af
join dim_customer c
on af.customer_code = c.Customer_Code
order by Forecast_Accuracy desc;
END
*/

										/*TEMPORARY TABLE*/
/*Temporary table is short of like CTE.*/        
/*Instead of doing CTE, we can create Temporary table*/      

create temporary table forecast_accuracy_report
select af.Customer_Code,
	   sum(af.Sold_Quantity) as Total_Sold_Quantity,
	   sum(af.Forecast_Quantity) as	Total_Forecast_Quantity,
       sum(Forecast_Quantity-Sold_Quantity) as Net_Error,
       round(sum(Forecast_Quantity-Sold_Quantity)*100/sum(Forecast_Quantity),1) as Net_Error_Pct,
       sum(abs(Forecast_Quantity-Sold_Quantity)) as abs_error,
       round(sum(abs(Forecast_Quantity-Sold_Quantity))*100/sum(Forecast_Quantity),2) as abs_error_pct
from fact_actuals_forecast_table af
where af.Fiscal_year=2021
group by Customer_Code;    

SELECT af.Customer_Code,
	   c.customer as Customer_Name,
	   c.market,
       af.Total_Forecast_Quantity,
       af.Total_Sold_Quantity,
       af.Net_Error,
       af.abs_error,
		if(abs_error_pct>100,0,100-abs_error_pct) as Forecast_Accuracy 
FROM forecast_accuracy_report af
join dim_customer c
on af.customer_code = c.Customer_Code
order by Forecast_Accuracy desc;                    
                                        


												/*EXERCISE*/
/*Write a query for the below scenario.
The supply chain business manager wants to see which customers’ forecast accuracy has dropped from 2020 to 2021. 
Provide a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021
HINT: You can use the query with CTE that was used to generate a forecast accuracy report in the previous chapter first for 2021 
and then for 2020. Then you can use these two tables.
You can temporarily cache these tables in a temporary table or another CTE and then perform the join between the two.*/

DROP TABLE forecast_accuracy_report_2021;
/*Forecast Accuracy report for 2021: TEMPORARY TABLE*/
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
DROP TABLE forecast_accuracy_report_2020;
create temporary table forecast_accuracy_report_2020
WITH cte2 AS(
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
where af.Fiscal_year=2020
group by Customer_Code
)

SELECT *,
		if(abs_error_pct>100,0,100-abs_error_pct) as Forecast_Accuracy_2020
FROM cte2
order by Forecast_Accuracy_2020 desc;

/*Join both tables forecast_accuracy_report_2021 and forecast_accuracy_report_2020 */
/*The supply chain business manager wants to see which customers’ forecast accuracy has dropped from 2020 to 2021. 
Provide a complete report with these columns: customer_code, customer_name, market, forecast_accuracy_2020, forecast_accuracy_2021*/

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
   


