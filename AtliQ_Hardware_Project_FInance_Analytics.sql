										/*FUNCTIONS*/

/*Report for 2021 and Quarter 4*/
/* Month -DONE
Product name-DONE
variant-DONE
Sold Qty-DONE
Gross Per item-DONE
Grice Price total*/

/*Get the Customer code for Croma*/
 
select *
from dim_customer
where customer like "%Croma%";
/*Customer code for Croma :90002002*/

/*To get the transactions of the cutsomer code:90002002*/
select *
from fact_sales_monthly
where customer_code=90002002;

/*Converting Calendar Year Date to Fiscal Year*/

select *
from fact_forecast_monthly
where customer_code=90002002
AND
year(date) = '2021'
order by date;

select year(date_add('2020-10-01', interval 4 month));

select *
from fact_sales_monthly
where customer_code=90002002
AND
year(date_add(date,interval 4 Month))='2021';


/*Creating a user defined function named:get_fiscal_year function*/

/*CREATE FUNCTION `get_fiscal_year`(
	calendar_date date
) RETURNS int
DETERMINISTIC
BEGIN
Declare fiscal_year int;
SET fiscal_year = Year(date_add(calendar_date,Interval 4 month));
RETURN fiscal_year;
END*/

/*Now we need to implement this User defined function to our Query*/
select *
from fact_sales_monthly
where customer_code='90002002'
AND
get_fiscal_year(date) = 2021;

											/*EXERCISE*/
/*Report for 2021 and Quarter 4*/

select month('2019-09-01');

/*Creating a user defined function named:get_fiscal_quarter function*/

/*CREATE FUNCTION `get_quarter_year`(
	calendar_date date
) RETURNS char(2)
DETERMINISTIC
BEGIN
Declare fiscal_quarter int;
Declare qtr char(2);
SET fiscal_quarter = Month(calendar_date);
CASE
    when fiscal_quarter IN (9,10,11) then
				set qtr = 'Q1';
    when fiscal_quarter IN(12,1,2) then
				set qtr = 'Q2';
    when fiscal_quarter IN(3,4,5) then
				set qtr = 'Q3';
    when fiscal_quarter IN(6,7,8) then
                 set qtr = 'Q4';
END CASE;                 
                 
RETURN qtr;
END*/

/*Now we need to implement this User defined function:get_quarter_year to our Query
Report for 2021 and Quarter 4*/

select *
from fact_sales_monthly
where customer_code='90002002'
AND
get_fiscal_year(date) = 2021
AND
get_fiscal_quarter(date) ="Q4";

/*to get the product name and the product variant, we need to join the 2 table dim_product*/

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
where customer_code='90002002'
AND
get_fiscal_year(date) = 2021
AND
get_fiscal_quarter(date) ="Q4"
limit 1000000;



						/*GROSS SALES REPORT: TOTAL SALES AMOUNT*/
                        
/*As a product owner, i need an aggregate monthly Gross sales report for CROMA INDIA customer so that 
i can track how much sales this particular customer is generating for AtliQ and 
manage our relations accordingly*/
/*The report should have 2 columns: Month, Total gross sales amount to CROMA INDIA in this month*/

select s.date,
		round(sum(g.gross_price*s.sold_quantity),2) as total_gross_Monthly_sales_amount
from fact_sales_monthly s 
join fact_gross_price g
on s.product_code=g.product_code
AND
g.fiscal_year=get_fiscal_year(s.date)
where customer_code=90002002
group by s.date
order by s.date ASC;

/*EXERCISE:Generate a yearly report for Croma India where there are two columns
1. Fiscal Year
2. Total Gross Sales amount In that year from Croma*/

select get_fiscal_year(date) as fiscal_year,
	   round(sum(s.sold_quantity*g.gross_price),2) as Yearly_Total_Gross_Sales_amount
from fact_sales_monthly s 
join fact_gross_price g 
on g.product_code=s.product_code AND
g.fiscal_year=get_fiscal_year(s.date)
where customer_code=90002002
group by get_fiscal_year(s.date)
order by fiscal_year asc;


											/*STORED PROCEDURES*/

/*Montly Gross sales report for any customer.Automated with the help of Stored procedure*/
/*Stored procedure*/


/*CREATE PROCEDURE `get_monthly_gross_Sales_for_customer` (
c_code int)
BEGIN
select s.date,
       sum(round(s.sold_quantity*g.gross_price,2)) as monthly_gross_sales_amount
from fact_sales_monthly s 
join fact_gross_price g 
on g.product_code=s.product_code AND 
g.fiscal_year= get_fiscal_year(s.date)
where customer_code = c_code
group by s.date 
order by s.date asc;
END
*/

/*We will use the below query in STORED PROCEDURE*/
select s.date,
		round(sum(g.gross_price*s.sold_quantity),2) as total_gross_Monthly_sales_amount
from fact_sales_monthly s 
join fact_gross_price g
on s.product_code=g.product_code
AND
g.fiscal_year=get_fiscal_year(s.date)
where customer_code=90002002
group by s.date
order by s.date ASC;


/*Yearly*/

select get_fiscal_year(s.date) as fiscal_year,
       round(sum(s.sold_quantity*g.gross_price),2) as Yearly_Gross_Sales_Amount
from fact_sales_monthly s
join fact_gross_price g
on g.product_code=s.product_code AND
g.fiscal_year=get_fiscal_year(s.date)
where customer_code=90002002
group by get_fiscal_year(s.date)
order by fiscal_year asc;


/*2 customer codes for the same customer name*/
select *
from dim_customer
where customer like "%amazon%" and market ='india'; /*90002008,90002016*/
/*In normal cases, we can use IN operator*/
select s.date,
		round(sum(g.gross_price*s.sold_quantity),2) as total_gross_Monthly_sales_amount
from fact_sales_monthly s 
join fact_gross_price g
on s.product_code=g.product_code
AND
g.fiscal_year=get_fiscal_year(s.date)
where customer_code in(90002008,90002016)
group by s.date
/*order by s.date*/;

/*how to use the above code in STORED PROCEDURE*/

/*CREATE PROCEDURE `get_monthly_gross_Sales_for_customer`(
in_customer_code text) -- we need to give comma seperated customer id as an input, for that we need to have a TEXT data type--
BEGIN
select s.date,
       sum(round(s.sold_quantity*g.gross_price,2)) as monthly_gross_sales_amount
from fact_sales_monthly s 
join fact_gross_price g 
on g.product_code=s.product_code AND 
g.fiscal_year= get_fiscal_year(s.date)
where find_in_set(s.customer_code,in_customer_code)>0 --Need to check here, if this customer code is TEXT or not, 
													--for that we will use a function called FIND_IN_SET().Is s.customer_code is
                                                    -- present in in_customer_code
group by s.date
order by s.date asc;
END*/

/*TEST the function find_in_set()*/
select find_in_set(90002001,"90002002,90002008");



/*Create a STORED PROCEDURE that can determine the market badge based on the following logic:
      if total sold quantity >5 million then that market ='Golden'
       Else market='Silver'*/
/* Input:Market and FY
INPUT -> India, 2021 -->output: Gold*/

/* FOR ALL THE MARKETS*/
select c.market,sum(s.sold_quantity) as Total_Quantity
from fact_sales_monthly s 
join dim_customer c 
using(customer_code)
where 
get_fiscal_year(s.date)=2021
group by c.market;


/*FOR the Market=INDIA*/
select c.market,sum(s.sold_quantity) as Total_Quantity
from fact_sales_monthly s 
join dim_customer c 
using(customer_code)
where 
get_fiscal_year(s.date)=2021 and c.market ='India'
group by c.market;


/*Now we can create a STORED PROCEDURE*/
 /* Create procedure get_market_badge(
	-- We will always Prefix INPUT variable by IN to indicate the variables are input parameter--
    IN	in_market varchar(45),
	IN	in_fiscal_year year,
    -- Want to store Output in a different variable,using with OUT variable
    OUT out_badge varchar(45)
    )
BEGIN
		-- To capture the Total Qty into a variable.There is a thing called 'into' and 
        -- can declare variables in our functions jst like in user defined functions.
		
        -- decalre is used to declare a new variable named 'qty' with data typr int and default value 0
        
        declare qty int default 0;
        
        -- [LAST]  set defalut market to be India,as when we input no value for market the default value is 
        -- silver as per the If,else condition
        -- So we set the default the market value as India as, the company's HO is in India
        
        if in_market="" then
           SET in_market='India';
         end if ;  
        
        -- Retrieve Total Quantity for a given Market+Fiscal_Year
        select 
				sum(s.sold_quantity) into qty
		from fact_sales_monthly s 
		join dim_customer c 
		using(customer_code)
		where 
		get_fiscal_year(s.date)=in_fiscal_year 
        and 
        c.market =in_market
		group by c.market;
        
      -- Determine the Market badge
      if qty>5000000 then 
         SET out_badge="Gold";
      else 
         SET out_badge="Silver";
	  end if;
 END*/

       