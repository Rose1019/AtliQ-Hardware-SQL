							AtliQ Hardware Insights on Top N Products,Markets,Customers

** Retrieve the TOP 2 markets in every region by their Gross Sales Amount in FY=2021 **

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


** To Fetch TOP N products from each Division  by Sold quantity **

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
	
** View on Gross Sales **

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



