/*To create a report for TOP Markets,TOP Customers,TOP Products by NET SALES for a give Financial year*/
/*BY NET SALES -> Gross price - Pre invoice deduction= Net invoice sales
                  Net Invoice sales - Post invoice deduction = Net sales (Revenue)*/

/* To fetch Pre-invoice_pct deduction from fact_pre_invoice_deduction table for the CUSTOMER:CROMA and the fiscal Year:2021*/
select s.date,s.product_code,
		p.product,p.variant,s.sold_quantity,
        g.gross_price as gross_price_per_item,
        round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total,
        pre.pre_invoice_discount_pct as Pre_Invoice_Discnt_Pct
from fact_sales_monthly s
join dim_product p 
using(product_code)
join fact_gross_price g 
on g.product_code=s.product_code AND
   g.fiscal_year=get_fiscal_year (s.date)
join fact_pre_invoice_deductions Pre 
on pre.customer_code=s.customer_code   AND
pre.fiscal_year=get_fiscal_year(s.date)
where s.customer_code='90002002'
AND
get_fiscal_year(date) = 2021
limit 1000000;

/*To fetch Pre-invoice_pct deduction from fact_pre_invoice_deduction table for the ALL CUSTOMER and the fiscal Year:2021*/
EXPLAIN ANALYZE
select s.date,s.product_code,
		p.product,p.variant,s.sold_quantity,
        g.gross_price as gross_price_per_item,
        round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total,
        pre.pre_invoice_discount_pct as Pre_Invoice_Discnt_Pct
from fact_sales_monthly s
join dim_product p 
using(product_code)
join fact_gross_price g 
on g.product_code=s.product_code AND
   g.fiscal_year=get_fiscal_year (s.date)
join fact_pre_invoice_deductions Pre 
on pre.customer_code=s.customer_code   AND
pre.fiscal_year=get_fiscal_year(s.date)
where get_fiscal_year(date) = 2021
limit 1000000;


											/*PERFORMANCE ANALYZE*/
/*FIRST WAY :To optimize the performance, we can add a new table named dim_date and then join the table */

/*Join dim_date table*/ 

select s.date,s.product_code,
		p.product,p.variant,s.sold_quantity,
        g.gross_price as gross_price_per_item,
        round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total,
        pre.pre_invoice_discount_pct as Pre_Invoice_Discnt_Pct
from fact_sales_monthly s
join dim_product p 
using(product_code)
join dim_date dt
on dt.calendar_date=s.date ## benefit of joining dim_date table instead of using the UDF
join fact_gross_price g 
on g.product_code=s.product_code AND
   g.fiscal_year=dt.fiscal_year
join fact_pre_invoice_deductions Pre 
on pre.customer_code=s.customer_code   AND
pre.fiscal_year=dt.fiscal_year
where dt.fiscal_year= 2021
limit 1000000;
                                           
/*SECOND WAY : is to add fiscal_year column , a new column to fact_sales_monthly table*/


select s.date,s.product_code,
		p.product,p.variant,s.sold_quantity,
        g.gross_price as gross_price_per_item,
        round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total,
        pre.pre_invoice_discount_pct as Pre_Invoice_Discnt_Pct
        
from fact_sales_monthly s
join dim_product p 
using(product_code)
/*join dim_date dt
on dt.calendar_date=s.date */ ## Remove the xtra join dim_date table, fact_sales_monthly table itself having fiscal_year
join fact_gross_price g 
on g.product_code=s.product_code AND
   g.fiscal_year=s.fiscal_year
   
join fact_pre_invoice_deductions Pre 
on pre.customer_code=s.customer_code   AND
pre.fiscal_year=s.fiscal_year

where s.fiscal_year= 2021
limit 1000000;                                            


											/*DATABASE VIEWS*/

/*in CTE*/
WITH cte1 as
(
						select s.date,s.product_code,
						p.product,p.variant,s.sold_quantity,
						g.gross_price as gross_price_per_item,
						round((s.sold_quantity*g.gross_price),2) as Gross_Price_Total,
						pre.pre_invoice_discount_pct as Pre_Invoice_Discnt_Pct
						
				from fact_sales_monthly s
				join dim_product p 
				using(product_code)
				join fact_gross_price g 
				on g.product_code=s.product_code AND
				   g.fiscal_year=s.fiscal_year
				   
				join fact_pre_invoice_deductions Pre 
				on pre.customer_code=s.customer_code   AND
				pre.fiscal_year=s.fiscal_year

				where s.fiscal_year= 2021
				limit 1000000
)

select *,
		round((Gross_price_Total-Gross_price_Total*Pre_Invoice_Discnt_Pct),2) as Net_Invoice_Sales
from cte1;



/*Creating a view*/
/* Create View sales_PreInvoice_deduction AS
(
						select s.date,s.product_code,c.customer,s.market
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
				*/
                

/*to use the above VIEW in the query*/
/*instead of cte we will call the virtual table named:sales_preinvoice_deduction*/
select *,
		round(Gross_Price_Total*(1-Pre_Invoice_Discnt_Pct),2) as Net_Invoice_Sales
from sales_preinvoice_deduction;


/*We need to calculate Post invoice deduction pct*/
select *,
		round(Gross_Price_Total*(1-Pre_Invoice_Discnt_Pct),2) as Net_Invoice_Sales,
        (post.discounts_pct+post.other_deductions_pct) as Post_Invoice_Discnt_Pct
from sales_preinvoice_deduction s

join fact_post_invoice_deductions post
on post.date=s.date AND
post.customer_code=s.customer_code AND
post.product_code=s.product_code;

/*To create view for sales_post_invoice_deductions*/

/* create view sales_postinv_deduction AS
select s.date,s.fiscal_year,
s.customer_code,s.market,
s.product_code,s.product,s.variant,
s.sold_quantity,s.gross_price_total,
s.Pre_Invoice_Discnt_Pct,
        ROUND((s.Gross_Price_Total * (1 - s.Pre_Invoice_Discnt_Pct)),
                2) AS Net_Invoice_Sales,
        (po.discounts_pct + po.other_deductions_pct) AS Post_Invoice_Discnt_Pct
from sales_preinvoice_deduction s 
join fact_post_invoice_deductions po
on po.customer_code=s.customer_code AND
po.product_code=s.customer_code AND
po.date=s.date; */

/*To implement the above VIEW in the query and calculate Net sales*/        

select *,
		round((Net_Invoice_Sales - Net_Invoice_Sales*Post_Invoice_Discnt_Pct),2) as Net_Sales
from sales_postinvoice_deduction;

/*To create view for Net sales*/

/* Create view net_sales AS
select *,
		round((Net_Invoice_Sales - Net_Invoice_Sales*Post_Invoice_Discnt_Pct),2) as Net_Sales
from sales_postinvoice_deduction;
*/


									/*EXERCISE:Create view on Gross Sales*/
                                    
select s.date,s.fiscal_year,s.customer_code,c.customer,c.market,s.product_code,
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

/*Creat a view on GROSS SALES*/

/*
create view new_gross_sales AS
select s.date,s.fiscal_year,s.customer_code,c.customer,c.market,s.product_code,
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

*/


/*Requirement is to get TOP MARKETS,TOP CUSTOMERS,TOP PRODUCTS on NET SALES for a given fiscal year*/
/*We will probably write a STORED PROCEDURE for this as we will need this report going forward  as well*/                   
						
                        /*TOP MARKETS*/                   
                   
select market,round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales
where fiscal_year=2021
group by market
order by Net_Sales_Million DESC
limit 5;				

											/*TOP CUSTOMERS*/
select N.market,c.customer,round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales N
join dim_customer c
using(customer_code)
where N.fiscal_year=2021 AND
N.market='India'
group by c.customer,N.market
order by Net_Sales_Million DESC
limit 5;                                        


/*Create a Store Procedure for TOP N MARKETS*/
/*
create procedure top_n_markets_by_net_sales AS(
               in_fiscal_year int,
               in_top_n int
 )              
BEGIN
select market,round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales
where fiscal_year=in_fiscal_year
group by market
order by Net_Sales_Million DESC
limit in_top_n;
 END
	*/			
    
/*Create a Store Procedure for TOP N CUSTOMERS*/

/*
 create procedure get_top_n_customers_by _net_sales(
		in_fiscal_year int,
        in_top_n int
)

BEGIN
select c.customer,round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales NSV
join dim_customer c
using(customer_code)
where NSV.fiscal_year=in_fiscal_year
group by c.customer
order by Net_Sales_Million DESC
limit in_top_n;          
END
*/

											/*TOP N PRODUCT*/
/*Write a stored procedure to get the top n products by net sales for a given year. Use product name without a variant.*/

/*First write the query to fetch top n products*/
select market,product,
	   round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales NSV
where NSV.fiscal_year=2021 AND
NSV.market ='India'
group by product,market 
order by Net_Sales_Million DESC
limit 5;	

/*Now, write a stored procedure on TOP N PRODUCTS*/
/* create procedure top_n_products_by_net_sales (
					in_market varchar(25),
                    in_fiscal_year int,
                    in_top_n int
)
BEGIN
select market,product,
	   round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales NSV
where NSV.fiscal_year=in_fiscal_year  AND
NSV.market =in_market
group by product,market 
order by Net_Sales_Million DESC
limit in_top_n;	
END
*/


									/*WINDONWS FUNCTION*/
/*Task is to see a BAR CHART report for FY=2021 for TOP N CUSTOMERS by % NET SALES - NET SALES GLOBAL MARKET SHARE%*/

/*Calculating % here will show error as we cannot use any derived columns.So for that we can use CTE*/
select c.customer,
	   round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales N
join dim_customer c
using(customer_code)
where N.fiscal_year=2021
group by c.customer
order by Net_Sales_Million DESC;

/*Creating CTE*/
with Net_Sales_cte AS
(
select customer,
	   round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales N
join dim_customer c
on N.customer_code=c.customer_code
where N.fiscal_year=2021
group by customer

)
/*Need to create a third column which is PERCENTAGE*/
select *,
       round((Net_Sales_Million*100)/sum(Net_Sales_Million) over(),2) as PCT_Net_Sales
from Net_Sales_cte
order by Net_Sales_Million desc
limit 10;


											/*EXERCISE*/
/*As a product owner, i want to see region wise (APAC,EU,LTAM) % NET SALES breakdown in a repsective region*/
/*so that i can perform my regional analysis or financial performance of the company */
/*The end resut shoud be BAR CHART format for FY=2021.*/
/*Build a reusable asset that we can use to conduct this analysis  for any Financial year*/

/*Calculating % here will show error as we cannot use any derived columns.So for that we can use CTE*/
select c.customer,c.region,
	   round(sum(Net_Sales)/1000000,2) as Net_Sales_Million
from net_sales N
join dim_customer c
using(customer_code)
where N.fiscal_year=2021
group by c.region,c.customer
order by Net_Sales_Million DESC;


/*Creating CTE for Region wise Breakdown on Net sales*/

with Net_Sales_Region AS(
select c.customer,c.region,
	   round(sum(Net_Sales/1000000),2) as Net_Sales_Million
from net_sales N
join dim_customer c
using(customer_code)
where N.fiscal_year=2021
group by c.region,c.customer
)		

/*Need to create a third column which is PCT*/
select *,
	round((Net_Sales_Million*100)/sum(Net_Sales_Million) over(partition by region),2) as PCT_Net_Sales_Region
from Net_Sales_Region
order by region,Net_Sales_Million desc
;
		
/*Create STORED PROCEDURE for % NET SALES breakdown in a repsective region for any Financial Year*/

/*create procedure region_pct_Net_sales_FY(
			in_fiscal_year int
)
BEGIN
	with Net_Sales_Region AS(
		select c.customer,c.region,
	   round(sum(Net_Sales/1000000),2) as Net_Sales_Million
	from net_sales N
	join dim_customer c
	using(customer_code)
	where N.fiscal_year=in_fiscal_year
	group by c.region,c.customer
)		
*/

/*Need to create a third column which is PCT*/
/*select *,
	round((Net_Sales_Million*100)/sum(Net_Sales_Million) over(partition by),2) as PCT_Net_Sales_Region
from Net_Sales_Region
order by PCT_Net_Sales_Region desc;
END
*/


											/*EXERCISE*/
/*Retrieve the top 2 markets in every region by their gross sales amount in FY=2021*/     

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
                                       

/*Write a STORED PROCEDURE for getting TOP N products in each division by their SOLD QUANTITY sold*/
/*in a given year , for FY=2021 (Division,Product,Total_Quantity)*/


select 	p.division,
		p.product,
		sum(s.sold_quantity) as Total_quantity
from fact_sales_monthly s 
join dim_product p 
on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.division;











