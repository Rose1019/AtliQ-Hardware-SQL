								AtliQ Hardware Supply Chain Analytics

** Report on which customers’ Forecast Accuracy has dropped from 2020 to 2021 **

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
