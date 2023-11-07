# AtliQ-Hardware-SQL

### Introduction
Atliq Hardware is a company that sells computer hardware products to big retailers like CROMA, Flipkart, Staples, and Bestbuy, who then sell them to individual consumers.  
They make these products in their own factory, store them in a warehouse, and have distribution centers to send them out when they get orders.  

The problem is, Atliq relies too much on Excel files to keep track of everything, and they want to find a better way to manage their data.  
But they can't completely get rid of Excel because it's essential for analyzing data.  

The Data team from AtliQ,build database using MySQL which is free and robust and then created data informed decision with the help of SQL Queries.

**The AtliQ Hardware dataset contains 1425706 records, which was given by Codebasics learning platform for the purpose of learning.**   

Sharing the link to [CodeBasics](https://codebasics.io/)  

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



