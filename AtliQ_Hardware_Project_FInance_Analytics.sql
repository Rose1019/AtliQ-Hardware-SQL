## Transaction report for the Customer Reliance Digital  for the FY=2021 and Q4  
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
where customer_code='90002002'
AND
get_fiscal_year(date) = 2021
AND
get_fiscal_quarter(date) ="Q4"
limit 1000000;
``` 
