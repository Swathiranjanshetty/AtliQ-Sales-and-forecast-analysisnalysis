select 
s.date, 
s.product_code, 
s.customer_code,
s.sold_quantity,
p.product,
p.variant, 
g.gross_price, 
round((g.gross_price*s.sold_quantity),2) as gross_price_total, 
pre_invoice_discount_pct
from fact_sales_monthly s join dim_product p on s.product_code = p.product_code 
join fact_gross_price g on g.product_code = s.product_code and g.fiscal_year = s.Fiscal_year
join fact_pre_invoice_deductions pre on pre.customer_code = s.customer_code
and pre.fiscal_year = s.Fiscal_year where s.Fiscal_year=2021;


SELECT *, round((gross_price_total-pre_invoice_discount_pct*gross_price_total),2) as net_invoice_sales
	FROM sales_pre_invoice_discount
	LIMIT 1500000;
    
select * from fact_sales_monthly where customer_code = 90002002 and 
GET_FISCAL_YEAR(date)=2021 and
 fisal_quarter(date) = "Q4" ORDER BY date ASC;
 
 select get_fiscal_year(date) as fiscal_year,
	sum(round(sold_quantity*g.gross_price,2)) as yearly_sales
	from fact_sales_monthly s
	join fact_gross_price g
	on 
	    g.fiscal_year=get_fiscal_year(s.date) and
	    g.product_code=s.product_code
	where
	    customer_code=90002002
	group by get_fiscal_year(date)
	order by fiscal_year;
    
     select round(sum(net_sales)/1000000,2) as net_sales_mln 
    from net_sales 
    where get_fiscal_year(net_sales.date) = 2021 
    group by market order by net_sales_mln desc limit 5;
    
with cte1 as ( select market, 
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales 
where fiscal_year ="2021"
group by market
order by net_sales_mln desc
)
select *,net_sales_mln *100/sum(net_sales_mln) over() as pct from cte1;

WITH CTE1 as (SELECT n.customer,c.region ,round(sum(net_sales)/1000000,2) as net_sales_mln 
from net_sales n join dim_customer c on c.customer_code = n.customer_code
where fiscal_year = 2021
group by n.customer, c.region) 
select *, net_sales_mln*100/sum(net_sales_mln) over() as pct from cte1
order by net_sales_mln desc;

select *, net_sales_mln*100/sum(net_sales) from cte1;

with cte1 as (select c.customer,c.region, round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales s
join dim_customer c
on s.customer_code=c.customer_code
where s.fiscal_year =2021
group by c.customer,c.region)
select *, net_sales_mln*100/sum(net_sales_mln) over ( partition by  region )
as pct_share
from cte1
order by region, net_sales_mln desc;

WITH cte1 AS (
    SELECT p.division, p.product, SUM(s.sold_quantity) AS total_qty
    FROM fact_sales_monthly s
    JOIN dim_product p 
    ON p.product_code = s.product_code
    WHERE fiscal_year = 2021
    GROUP BY p.division, p.product
),
cte2 AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY division ORDER BY total_qty DESC) AS drnk
    FROM cte1
)
SELECT *
FROM cte2
WHERE drnk <= 3;

set @out_badge = '0';
call gdb0041.get_market_badge('India', 2020, @out_badge);
select @out_badge;

select customer, 
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales 
group by customer
order by net_sales_mln desc
limit 5;

select product, 
round(sum(net_sales)/1000000,2) as net_sales_mln
from net_sales 
group by product
order by net_sales_mln desc
limit 5;

call gdb0041.get_top_n_customer_by_net_sales('india', 2018, 2);
call gdb0041.get_top_n_markets_by_net_sales(2020, 2);

WITH cte1 AS (
    SELECT p.division, p.product, SUM(sold_quantity) AS total_qty 
    FROM net_sales s
    JOIN dim_product p 
    ON p.product_code = s.product_code
    WHERE fiscal_year = 2021
    GROUP BY p.division, p.product
),
cte2 AS (SELECT *, 
           DENSE_RANK() OVER (PARTITION BY division ORDER BY total_qty DESC) AS drnk
    FROM cte1)
SELECT * 
FROM cte2 
WHERE drnk <= 3;

CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `gross sales` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`Fiscal_year` AS `fiscal_year`,
        `s`.`customer_code` AS `customer_code`,
        `c`.`customer` AS `customer`,
        `c`.`market` AS `market`,
        `s`.`product_code` AS `product_code`,
        `p`.`product` AS `product`,
        `p`.`variant` AS `variant`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `g`.`gross_price` AS `gross_price_per_item`,
        ROUND((`s`.`sold_quantity` * `g`.`gross_price`),
                2) AS `gross_price_total`
    FROM
        (((`fact_sales_monthly` `s`
        JOIN `dim_product` `p` ON ((`s`.`product_code` = `p`.`product_code`)))
        JOIN `dim_customer` `c` ON ((`s`.`customer_code` = `c`.`customer_code`)))
        JOIN `fact_gross_price` `g` ON (((`g`.`fiscal_year` = `s`.`Fiscal_year`)
            AND (`g`.`product_code` = `s`.`product_code`))))
            
	CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `net_sales` AS
    SELECT 
        `sales_postinv_discount`.`date` AS `date`,
        `sales_postinv_discount`.`customer_code` AS `customer_code`,
        `sales_postinv_discount`.`fiscal_year` AS `fiscal_year`,
        `sales_postinv_discount`.`market` AS `market`,
        `sales_postinv_discount`.`customer` AS `customer`,
        `sales_postinv_discount`.`product_code` AS `product_code`,
        `sales_postinv_discount`.`product` AS `product`,
        `sales_postinv_discount`.`variant` AS `variant`,
        `sales_postinv_discount`.`sold_quantity` AS `sold_quantity`,
        `sales_postinv_discount`.`gross_price_total` AS `gross_price_total`,
        `sales_postinv_discount`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`,
        `sales_postinv_discount`.`net_invoice_sales` AS `net_invoice_sales`,
        `sales_postinv_discount`.`post_invoice_discount_pct` AS `post_invoice_discount_pct`,
        ROUND((`sales_postinv_discount`.`net_invoice_sales` - (`sales_postinv_discount`.`net_invoice_sales` * `sales_postinv_discount`.`post_invoice_discount_pct`)),
                2) AS `net_sales`
    FROM
        `sales_postinv_discount`
        
	CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `sales_postinv_discount` AS
    SELECT 
        `s`.`date` AS `date`,
        `s`.`fiscal_year` AS `fiscal_year`,
        `s`.`market` AS `market`,
        `s`.`customer` AS `customer`,
        `s`.`customer_code` AS `customer_code`,
        `s`.`product_code` AS `product_code`,
        `s`.`product` AS `product`,
        `s`.`variant` AS `variant`,
        `s`.`sold_quantity` AS `sold_quantity`,
        `s`.`gross_price_total` AS `gross_price_total`,
        `s`.`pre_invoice_discount_pct` AS `pre_invoice_discount_pct`,
        (`s`.`gross_price_total` - (`s`.`gross_price_total` * `s`.`pre_invoice_discount_pct`)) AS `net_invoice_sales`,
        (`po`.`discounts_pct` + `po`.`other_deductions_pct`) AS `post_invoice_discount_pct`
    FROM
        (`sales_preinv_discount` `s`
        JOIN `fact_post_invoice_deductions` `po` ON (((`s`.`date` = `po`.`date`)
            AND (`s`.`product_code` = `po`.`product_code`))))
            
	CREATE DEFINER=`root`@`localhost` PROCEDURE `get_forecast_accuracy`(
in_fiscal_year int)
BEGIN
  WITH forecast_err_table AS (
        SELECT 
            s.customer_code AS customer_code, 
            d.customer AS customer_name, 
            d.market AS market, 
            SUM(CAST(c.sold_quantity AS SIGNED)) AS total_sold_qty,  -- Corrected CAST inside SUM
            SUM(CAST(s.forecast_quantity AS SIGNED)) AS total_forecast_qty,  -- Corrected CAST inside SUM
            SUM(CAST(s.forecast_quantity AS SIGNED) - CAST(c.sold_quantity AS SIGNED)) AS net_error,  -- Corrected CAST inside SUM
            CAST(ROUND(SUM(CAST(s.forecast_quantity AS SIGNED) - CAST(c.sold_quantity AS SIGNED)) * 100 / SUM(CAST(s.forecast_quantity AS SIGNED)), 1) AS DECIMAL(10, 1)) AS net_error_pct, 
            SUM(ABS(CAST(s.forecast_quantity AS SIGNED) - CAST(c.sold_quantity AS SIGNED))) AS abs_error,  -- Corrected CAST inside SUM
            ROUND(SUM(ABS(CAST(s.forecast_quantity AS SIGNED) - CAST(c.sold_quantity AS SIGNED))) * 100 / SUM(CAST(s.forecast_quantity AS SIGNED)), 2) AS abs_error_pct
        FROM
            fact_forecast_monthly s
            JOIN fact_sales_monthly c ON s.customer_code = c.customer_code AND s.product_code = c.product_code
            JOIN dim_customer d ON d.customer_code = c.customer_code
        WHERE 
            s.fiscal_year = in_fiscal_year 
        GROUP BY 
            customer_code
    ) 
    SELECT 
        *, 
        IF(abs_error_pct > 100, 0, 100.0 - abs_error_pct) AS forecast_accuracy 
    FROM 
        forecast_err_table 
    ORDER BY 
        forecast_accuracy DESC;




